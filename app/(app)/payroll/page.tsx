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
type GroupRow = { id: string; client_id: string; language_group: string | null; contract_id: string | null };
type ContractEntityRow = { id: string; legal_entity_id: string };
type LegalEntityRow = { id: string; name: string };
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

// ---- The month, from the URL ----
// ?month=YYYY-MM. It was client state until 202610160001; moving it into
// the URL is what lets Anca send a link to a specific month and what lets
// the page survive a refresh, and it is the precondition for asking the
// database for one month instead of the whole org.
//
// The fallback is explicit and is the current month: a malformed, absent
// or out-of-range value must land somewhere real rather than render an
// empty screen that looks like "nobody is owed anything". Validated by
// reconstruction rather than by regex alone -- "2026-13" matches
// /\d{4}-\d{2}/ and is not a month, so the parsed value has to round-trip
// back to the same string to be accepted.
function currentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function resolveMonth(raw: string | string[] | undefined): string {
  const candidate = Array.isArray(raw) ? raw[0] : raw;
  if (!candidate || !/^\d{4}-\d{2}$/.test(candidate)) return currentMonthKey();
  const [year, month] = candidate.split("-").map(Number);
  if (month < 1 || month > 12) return currentMonthKey();
  // Years outside this range are not a month Anka meant to look at; they
  // are a hand-edited URL, and a date-range query on them is pointless.
  if (year < 2000 || year > 2100) return currentMonthKey();
  return `${year}-${String(month).padStart(2, "0")}`;
}

// [from, toExclusive). The exclusive upper bound is the first day of the
// NEXT month, so nothing here has to know whether a month has 28, 29, 30
// or 31 days -- the single most common way a date-range filter quietly
// loses the last day. Month 12 rolls to January of the next year via the
// Date constructor's own normalisation.
function monthRange(monthKey: string) {
  const [year, month] = monthKey.split("-").map(Number);
  const pad = (n: number) => String(n).padStart(2, "0");
  const nextYear = month === 12 ? year + 1 : year;
  const nextMonth = month === 12 ? 1 : month + 1;
  return {
    from: `${year}-${pad(month)}-01`,
    toExclusive: `${nextYear}-${pad(nextMonth)}-01`,
  };
}

// finance.operations.* OR org.settings.manage -- matches
// closePayrollPeriod's own gate (app/(app)/payroll/actions.ts) exactly,
// so nobody who can act on this page is kept from reaching it, and
// nobody who can reach it is denied by the action underneath.
//
// finance.reporting.* is ABSENT BY DECISION, not by omission (2026-10-20,
// OPEN_ITEMS item 153). Anka asked in July 2026 for Finance Administration
// & Reporting to be added here (feedback rd. 8, one of five screens); the
// answer is no for now, against the Phase 0 finance segregation. Until that
// decision this gate had simply never been asked the question -- the role
// was missing because nobody had added it, which reads identically in code
// and is a different thing entirely.
//
// It costs nothing today: three accounts hold finance.reporting.* without
// this gate and all three are test accounts, while Anka herself also holds
// finance.operations.* and sees this page. Item 153 carries the reopening
// trigger -- the day a real person holds ONLY Finance Admin & Reporting.
export default async function PayrollPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const monthKey = resolveMonth((await searchParams).month);
  const { from, toExclusive } = monthRange(monthKey);
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

  // Month-scoped, since 202610160001. This fetch used to be org-wide
  // because the month picker was client state and the server could not
  // know which month to ask for; now that the month comes from the URL,
  // leaving it unfiltered would just move the growing scan from the
  // plpgsql loop to PostgREST. Same reasoning, same range, as the pay
  // call below -- and the two MUST use the same bounds, or the sums and
  // the confirmation list would describe different sets of workshops.
  //
  // `periods` above stays unscoped on purpose: it is the history of closed
  // months, not a view of one month.
  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, session_date, group_id, trainer_principal_id, trainer_secundar_id, trainer_principal_confirmed_at, trainer_secundar_confirmed_at, duration_minutes, location_tier",
    )
    .eq("organization_id", orgId)
    .gte("session_date", from)
    .lt("session_date", toExclusive)
    .returns<SessionRow[]>();

  const groupIds = [...new Set((sessions ?? []).map((s) => s.group_id))];
  const { data: groups } =
    groupIds.length > 0
      ? await supabase.from("groups").select("id, client_id, language_group, contract_id").in("id", groupIds).returns<GroupRow[]>()
      : { data: [] as GroupRow[] };
  const clientIdByGroupId = new Map((groups ?? []).map((g) => [g.id, g.client_id]));
  const languageByGroupId = new Map((groups ?? []).map((g) => [g.id, g.language_group]));

  // ---- Which entity invoices this workshop ----
  // session -> group -> contract -> legal_entity. It matters because a
  // trainer issues one invoice PER ENTITY, not one per month: WOW LAB bills
  // from three (Brandine Advertising SRL, Experimente Wow SRL, Asociatia
  // STEMplicity), and Anka currently works out by hand which amount goes on
  // which. Verified on the real chain before building: Cătălina's 26
  // workshops resolve to Brandine, Teodora's 6 and Lorina's 6 to
  // Experimente Wow.
  //
  // The chain has exactly ONE break point, and it is deliberate:
  // groups.contract_id is nullable because a group can legitimately exist
  // before its contract is signed (202608290001). contracts.legal_entity_id
  // is NOT NULL, so it never breaks there. A workshop whose group has no
  // contract is therefore PAYABLE BUT UNATTRIBUTABLE -- the amount is known,
  // the invoicing entity is not. That is a third state, not a pay failure,
  // and it gets its own reason rather than being dropped into whichever
  // bucket a join happens to put it in.
  const contractIds = [...new Set((groups ?? []).map((g) => g.contract_id).filter((v): v is string => v !== null))];
  const { data: contractEntities } =
    contractIds.length > 0
      ? await supabase.from("contracts").select("id, legal_entity_id").in("id", contractIds).returns<ContractEntityRow[]>()
      : { data: [] as ContractEntityRow[] };
  const entityIdByContractId = new Map((contractEntities ?? []).map((c) => [c.id, c.legal_entity_id]));

  const entityIds = [...new Set((contractEntities ?? []).map((c) => c.legal_entity_id))];
  const { data: legalEntities } =
    entityIds.length > 0
      ? await supabase.from("legal_entities").select("id, name").in("id", entityIds).returns<LegalEntityRow[]>()
      : { data: [] as LegalEntityRow[] };
  const entityNameById = new Map((legalEntities ?? []).map((e) => [e.id, e.name]));

  // Null entityId is the broken chain. Null entityName with a non-null id
  // would mean RLS hid the entity row, which is a different thing and must
  // not read as "no contract" -- kept distinct for the same reason item 123
  // keeps "unreadable" apart from "absent".
  const entityOfGroup = (groupId: string) => {
    const group = (groups ?? []).find((g) => g.id === groupId);
    if (!group || group.contract_id === null) return { id: null, name: null, unlinked: true };
    const id = entityIdByContractId.get(group.contract_id) ?? null;
    if (id === null) return { id: null, name: null, unlinked: true };
    return { id, name: entityNameById.get(id) ?? null, unlinked: false };
  };

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
  // One call for the displayed month, not one per slot:
  // app.calculate_session_pay raises on sixteen shapes of missing input,
  // and a raise aborts the statement -- so the per-slot catching has to
  // happen inside plpgsql. public.calculate_org_session_pay (202610160001)
  // returns one row per trainer slot in [from, toExclusive) with the
  // amount ALREADY ROUNDED to 2 decimals, or a reason_code naming why
  // there isn't one.
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
      p_from: from,
      p_to_exclusive: toExclusive,
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
        monthKey={monthKey}
        paySumsAvailable={payRows !== null}
        periods={(periods ?? []).map((p) => ({
          id: p.id,
          period: p.period,
          closedByName: p.closed_by ? nameById.get(p.closed_by) ?? "Unknown" : "Unknown",
        }))}
        sessions={(sessions ?? []).map((s) => {
          const clientId = clientIdByGroupId.get(s.group_id);
          const clientName = (clientId ? clientNameById.get(clientId) : undefined) ?? "Unknown";
          const entity = entityOfGroup(s.group_id);
          return {
            id: s.id,
            sessionDate: s.session_date,
            clientName,
            // The invoicing entity, from session -> group -> contract ->
            // legal_entity. A trainer issues one invoice per entity, so this
            // is the outer grouping on the screen. `unlinked` means the
            // group has no contract (contract_id is nullable by design,
            // 202608290001) -- the workshop is PAYABLE BUT UNATTRIBUTABLE,
            // which is neither an amount problem nor a pay failure.
            entityId: entity.id,
            entityName: entity.name,
            entityUnlinked: entity.unlinked,
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
