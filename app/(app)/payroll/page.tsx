import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { displayName } from "@/lib/display-name";
import { PayrollClient } from "./payroll-client";
import { AccessDenied } from "@/components/ui/access-denied";

type MembershipRow = { organization_id: string };
type PeriodRow = { id: string; period: string; closed_by: string | null };
type UserLookupRow = { id: string; full_name: string; first_name: string | null; last_name: string | null };
type SessionRow = {
  id: string;
  session_date: string;
  group_id: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainer_principal_confirmed_at: string | null;
  trainer_secundar_confirmed_at: string | null;
  duration_minutes: number | null;
  location_tier: string | null;
};
type GroupRow = { id: string; client_id: string; language_group: string | null };
type GradeRow = { trainer_id: string; grade_level: number; effective_from: string };
type ClientRow = { id: string; name: string };

// finance.operations.* OR org.settings.manage -- matches
// closePayrollPeriod's own gate (app/(app)/payroll/actions.ts) exactly,
// so nobody who can act on this page is kept from reaching it, and
// nobody who can reach it is denied by the action underneath.
export default async function PayrollPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  let orgId: string | null = null;
  for (const m of memberships ?? []) {
    if (
      (await checkCapability(supabase, "finance.operations.*", m.organization_id)) ||
      (await checkCapability(supabase, "org.settings.manage", m.organization_id))
    ) {
      orgId = m.organization_id;
      break;
    }
  }

  if (!orgId) {
    return <AccessDenied reasonKey="access_denied_no_payroll_capability" />;
  }

  const { data: periods } = await supabase
    .from("payroll_periods")
    .select("id, period, closed_by")
    .eq("organization_id", orgId)
    .order("period", { ascending: false })
    .returns<PeriodRow[]>();

  // Org-wide, not month-scoped: the month picker on the client is plain
  // state (no navigation), so the summary for whichever month Anka has
  // selected is computed there from this one fetch, the same way the
  // create forms elsewhere in this app hold their own client-side state.
  // WOW LAB's session volume makes one unfiltered fetch the simpler
  // choice over wiring a server round-trip to the month picker.
  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, session_date, group_id, trainer_principal_id, trainer_secundar_id, trainer_principal_confirmed_at, trainer_secundar_confirmed_at, duration_minutes, location_tier",
    )
    .eq("organization_id", orgId)
    .returns<SessionRow[]>();

  const groupIds = [...new Set((sessions ?? []).map((s) => s.group_id))];
  const { data: groups } =
    groupIds.length > 0
      ? await supabase.from("groups").select("id, client_id, language_group").in("id", groupIds).returns<GroupRow[]>()
      : { data: [] as GroupRow[] };
  const clientIdByGroupId = new Map((groups ?? []).map((g) => [g.id, g.client_id]));
  const languageByGroupId = new Map((groups ?? []).map((g) => [g.id, g.language_group]));

  const clientIds = [...new Set((groups ?? []).map((g) => g.client_id))];
  const { data: clients } =
    clientIds.length > 0
      ? await supabase.from("clients").select("id, name").in("id", clientIds).returns<ClientRow[]>()
      : { data: [] as ClientRow[] };
  const clientNameById = new Map((clients ?? []).map((c) => [c.id, c.name]));

  // One combined lookup for both closer names and trainer names -- same
  // "one query, not one per row" convention payment-config/page.tsx uses
  // for its five grids' creator names.
  const trainerIds = [
    ...new Set((sessions ?? []).flatMap((s) => [s.trainer_principal_id, s.trainer_secundar_id]).filter((v): v is string => v !== null)),
  ];
  const closerIds = (periods ?? []).map((p) => p.closed_by).filter((v): v is string => v !== null);
  const allUserIds = [...new Set([...closerIds, ...trainerIds])];
  const { data: users } =
    allUserIds.length > 0
      ? await supabase.from("users").select("id, full_name, first_name, last_name").in("id", allUserIds).returns<UserLookupRow[]>()
      : { data: [] as UserLookupRow[] };
  // "Unnamed" (resolved, but no displayable name) vs "Unknown" (id not in
  // the lookup at all -- RLS blocked it, or the row is gone) stay distinct
  // fallbacks, same as the original closer-name logic this replaces.
  const nameById = new Map((users ?? []).map((u) => [u.id, displayName(u) || "Unnamed"]));

  // ---- Which workshops cannot be priced, and why (item 121) ----
  // The five inputs app.calculate_session_pay raises on, read from the same
  // places it reads them: duration_minutes and location_tier from the
  // workshop, language_group from the GROUP, a trainer in the slot, and a
  // trainer_grade_assignments row effective on or before the workshop's date.
  // Nothing here re-implements the arithmetic -- it only asks the same five
  // questions, so the closer sees the sentence the calculation would raise.
  const { data: grades } = await supabase
    .from("trainer_grade_assignments")
    .select("trainer_id, grade_level, effective_from")
    .eq("organization_id", orgId)
    .returns<GradeRow[]>();

  // Grade is only assessable if this viewer can actually read the table.
  // trainer_grade_assignments' SELECT policy admits finance.operations.* /
  // finance.reporting.* / own row / the platform-owner flag -- while
  // /payroll's own gate also admits org.settings.manage alone. For such a
  // viewer the read comes back empty, and reporting "no grade" for every
  // trainer would be a false alarm about other people's data they simply
  // cannot see. Zero rows read = the question goes unasked, not answered no.
  const gradesReadable = (grades ?? []).length > 0;
  const gradeOnDate = (trainerId: string, date: string) =>
    (grades ?? [])
      .filter((g) => g.trainer_id === trainerId && g.effective_from <= date)
      .sort((a, b) => (a.effective_from < b.effective_from ? 1 : -1))[0] ?? null;

  const unpriceable = (sessions ?? []).flatMap((s) => {
    const reasons: { key: string; name?: string }[] = [];
    if (s.duration_minutes === null) reasons.push({ key: "no_duration" });
    if (s.location_tier === null) reasons.push({ key: "no_location" });
    if ((languageByGroupId.get(s.group_id) ?? null) === null) reasons.push({ key: "no_language" });

    const slots = [s.trainer_principal_id, s.trainer_secundar_id].filter(
      (v): v is string => v !== null,
    );
    if (slots.length === 0) {
      reasons.push({ key: "no_trainer" });
    } else if (gradesReadable) {
      for (const trainerId of slots) {
        if (gradeOnDate(trainerId, s.session_date) === null) {
          reasons.push({ key: "no_grade", name: nameById.get(trainerId) ?? "Unknown" });
        }
      }
    }

    if (reasons.length === 0) return [];
    const clientId = clientIdByGroupId.get(s.group_id);
    return [{
      id: s.id,
      sessionDate: s.session_date,
      clientName: (clientId ? clientNameById.get(clientId) : undefined) ?? "Unknown",
      reasons,
    }];
  });

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-6">
      <PayrollClient
        orgId={orgId}
        periods={(periods ?? []).map((p) => ({
          id: p.id,
          period: p.period,
          closedByName: p.closed_by ? nameById.get(p.closed_by) ?? "Unknown" : "Unknown",
        }))}
        sessions={(sessions ?? []).map((s) => {
          const clientId = clientIdByGroupId.get(s.group_id);
          const clientName = (clientId ? clientNameById.get(clientId) : undefined) ?? "Unknown";
          return {
            id: s.id,
            sessionDate: s.session_date,
            clientName,
            principal: s.trainer_principal_id
              ? {
                  name: nameById.get(s.trainer_principal_id) ?? "Unknown",
                  confirmed: s.trainer_principal_confirmed_at !== null,
                }
              : null,
            secundar: s.trainer_secundar_id
              ? {
                  name: nameById.get(s.trainer_secundar_id) ?? "Unknown",
                  confirmed: s.trainer_secundar_confirmed_at !== null,
                }
              : null,
          };
        })}
        unpriceable={unpriceable}
      />
    </div>
  );
}
