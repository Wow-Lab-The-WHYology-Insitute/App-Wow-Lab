import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
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
};
type GroupRow = { id: string; client_id: string };
type ClientRow = { id: string; name: string };

// Same rule as groups/page.tsx's copy: never falls back to a raw email.
function displayName(u: Pick<UserLookupRow, "full_name" | "first_name" | "last_name">) {
  const full = [u.first_name, u.last_name].filter(Boolean).join(" ");
  if (full) return full;
  if (u.full_name && !u.full_name.includes("@")) return u.full_name;
  return "";
}

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
      "id, session_date, group_id, trainer_principal_id, trainer_secundar_id, trainer_principal_confirmed_at, trainer_secundar_confirmed_at",
    )
    .eq("organization_id", orgId)
    .returns<SessionRow[]>();

  const groupIds = [...new Set((sessions ?? []).map((s) => s.group_id))];
  const { data: groups } =
    groupIds.length > 0
      ? await supabase.from("groups").select("id, client_id").in("id", groupIds).returns<GroupRow[]>()
      : { data: [] as GroupRow[] };
  const clientIdByGroupId = new Map((groups ?? []).map((g) => [g.id, g.client_id]));

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
      />
    </div>
  );
}
