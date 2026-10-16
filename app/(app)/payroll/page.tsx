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
// One row per trainer slot per workshop, from
// public.calculate_org_session_pay (202610150003). `amount` is already
// rounded to 2 decimals in numeric and is null exactly when reason_code is
// set; error_text carries the raw raised message, kept for the 'unknown'
// case so no failure can render as silence.
type PayRow = {
  session_id: string;
  trainer_id: string;
  slot: "principal" | "secundar";
  amount: number | string | null;
  reason_code: string | null;
  error_text: string | null;
};

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
          // The name, or no name -- never "Unknown". A slot is a plain FK to
          // users with no role requirement, and `users`' own SELECT policy
          // only admits TRAINER names to finance/ops viewers (202609160001),
          // so a non-trainer allocated to a workshop resolves to nothing here.
          // Printed as "Unknown has no grade effective on this date" that
          // sentence is worse than naming the column: it names nobody and
          // tells the closer nothing. Item 66's rule, applied to a message
          // rather than to a header: when the name is not readable, say what
          // IS known and stop. Measured, not hypothetical -- this is what the
          // first run of the verification script rendered.
          const name = nameById.get(trainerId);
          reasons.push(name ? { key: "no_grade", name } : { key: "no_grade_unnamed" });
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

  // ---- What each trainer is owed (the money this screen never showed) ----
  // One call for the whole org, not one per slot: app.calculate_session_pay
  // raises on fourteen shapes of missing input, and a raise aborts the
  // statement -- so the per-slot catching has to happen inside plpgsql.
  // public.calculate_org_session_pay (202610150003) returns one row per
  // trainer slot with the amount ALREADY ROUNDED to 2 decimals, or a
  // reason_code naming why there isn't one. Org-wide for the same reason
  // the sessions fetch above is: the month picker is client state.
  //
  // Gated on being able to read the grids at all, not on /payroll's own
  // gate, because the two differ. The rate tables admit SELECT to
  // finance.operations.* / finance.reporting.* / platform owner
  // (202608310002), while this page also admits org.settings.manage. For a
  // viewer holding only the latter, every single row would come back as a
  // raise -- and rendering that as "nothing can be calculated" would be
  // item 123's mistake exactly: an absence under RLS read as evidence.
  // No live role actually lands there (org.settings.manage is granted only
  // to Organization Owner and Platform Owner, both of which also carry
  // finance.operations.*), so this is a guard against a role change, not
  // against today's data -- which is why it asks the capability rather
  // than counting rows: a capable viewer of an org with no grid seeded
  // yet must read as "no grid", never as "not for your eyes".
  const canReadPayGrids =
    (await checkCapability(supabase, "finance.operations.*", orgId)) ||
    (await checkCapability(supabase, "finance.reporting.*", orgId));

  let payRows: PayRow[] | null = null;
  if (canReadPayGrids) {
    const { data, error } = await supabase.rpc("calculate_org_session_pay", {
      p_organization_id: orgId,
    });
    if (error) {
      // Loudly, and into Vercel's function logs, same as resolve_landing_flags'
      // own failure path. Then render the screen WITHOUT sums rather than with
      // zeroes: a zero beside a trainer's name is a wrong number, and this is
      // the one screen where a wrong number becomes a payment.
      console.error(
        "calculate_org_session_pay RPC failed — /payroll renders confirmations and the pre-close check, without sums:",
        error,
      );
    } else {
      payRows = (data ?? []) as PayRow[];
    }
  }

  const payBySlot = new Map<string, PayRow>();
  for (const r of payRows ?? []) {
    payBySlot.set(`${r.session_id}:${r.slot}`, r);
  }

  // Integer bani, never a float. Every amount arrives already rounded to 2
  // decimals (rounded in numeric, inside the function -- see its migration
  // header for why the language doing the rounding decides the answer), and
  // the totals are sums of those rounded rows. Summing 2-decimal floats
  // drifts (276.23 + 276.23 is 552.4599999999999 in float64), so the sums
  // are done on integers and divided once, at render.
  const baniOf = (r: PayRow | undefined) =>
    r && r.amount !== null ? Math.round(Number(r.amount) * 100) : null;

  const slotPay = (sessionId: string, slot: "principal" | "secundar") => {
    const r = payBySlot.get(`${sessionId}:${slot}`);
    return {
      bani: baniOf(r),
      reasonCode: r?.reason_code ?? null,
      errorText: r?.error_text ?? null,
    };
  };

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-6">
      <PayrollClient
        orgId={orgId}
        paySumsAvailable={payRows !== null}
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
                  // Grouped by id on the client, displayed by name: two people
                  // can share a display name, and a sum is the last place to
                  // merge two of them. The "Unknown" fallback stays for the
                  // existing confirmation list, which item 122 already records
                  // as owed a fix; the sums block renders the unnamed case
                  // through its own key instead of printing this word.
                  id: s.trainer_principal_id,
                  name: nameById.get(s.trainer_principal_id) ?? "Unknown",
                  named: nameById.has(s.trainer_principal_id),
                  confirmed: s.trainer_principal_confirmed_at !== null,
                  ...slotPay(s.id, "principal"),
                }
              : null,
            secundar: s.trainer_secundar_id
              ? {
                  id: s.trainer_secundar_id,
                  name: nameById.get(s.trainer_secundar_id) ?? "Unknown",
                  named: nameById.has(s.trainer_secundar_id),
                  confirmed: s.trainer_secundar_confirmed_at !== null,
                  ...slotPay(s.id, "secundar"),
                }
              : null,
          };
        })}
        unpriceable={unpriceable}
      />
    </div>
  );
}
