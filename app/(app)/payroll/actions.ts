"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { PAYROLL_PERIOD_ALREADY_CLOSED_ERROR } from "./close-error";

export type ActionResult = { ok: true; id: string } | { ok: false; error: string };

type BonusRow = { trainer_id: string; bonus_date: string; client_id: string; amount: number | string };
type SessionRow = {
  id: string;
  group_id: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainer_principal_approved_at: string | null;
  trainer_principal_approved_amount_bani: number | null;
  trainer_secundar_approved_at: string | null;
  trainer_secundar_approved_amount_bani: number | null;
};
type GroupRow = { id: string; contract_id: string | null };
type ContractRow = { id: string; legal_entity_id: string };

// [from, toExclusive) for the month `period` (always "YYYY-MM-01") names --
// same off-by-one-proof construction as payroll/page.tsx's own monthRange,
// kept separate rather than shared: this one takes the period string
// directly, that one takes the URL's "YYYY-MM".
function periodRange(period: string) {
  const [year, month] = period.split("-").map(Number);
  const pad = (n: number) => String(n).padStart(2, "0");
  const nextYear = month === 12 ? year + 1 : year;
  const nextMonth = month === 12 ? 1 : month + 1;
  return { from: period, toExclusive: `${nextYear}-${pad(nextMonth)}-01` };
}

// finance.operations.* -- the capability that identifies "the person who
// closes payroll" (docs/OPEN_ITEMS.md item 45 part 5; argued in full in
// 202609150001_create_payroll_periods.sql's own comment). Not
// contracts.*: Anka and Laura both happen to hold that too, via Contract
// Administrator, but for an unrelated reason -- the same
// coincidence-of-role mistake 202608300001 (suppliers) already rejected
// for the identical pair of capabilities on a different table.
// org.settings.manage/platform owner are checked alongside it, matching
// this codebase's standing convention (has_capability's own internal
// bypass covers platform owner for finance.operations.* already, but not
// org.settings.manage, which is never implied by any other capability
// check here).
export async function closePayrollPeriod(orgId: string, period: string): Promise<ActionResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: "Not signed in." };
  }

  const [isOwner, hasFinanceOperations] = await Promise.all([
    checkCapability(supabase, "org.settings.manage", orgId),
    checkCapability(supabase, "finance.operations.*", orgId),
  ]);
  if (!isOwner && !hasFinanceOperations) {
    return { ok: false, error: "Not permitted (requires finance.operations.*)." };
  }

  // Pre-check, same reasoning as markContractSigned
  // (app/(app)/contracts/actions.ts): turns "closing twice" into a real
  // message instead of a raw 23505 unique-violation. The 23505 branch
  // below stays as a backstop for the race between this check and the
  // insert, not the expected path.
  const { data: existing } = await supabase
    .from("payroll_periods")
    .select("id")
    .eq("organization_id", orgId)
    .eq("period", period)
    .maybeSingle();

  if (existing) {
    return { ok: false, error: PAYROLL_PERIOD_ALREADY_CLOSED_ERROR };
  }

  const { data, error } = await supabase
    .from("payroll_periods")
    .insert({ organization_id: orgId, period, closed_at: new Date().toISOString(), closed_by: user.id })
    .select("id")
    .single();

  if (error || !data) {
    if (error?.code === "23505") {
      return { ok: false, error: PAYROLL_PERIOD_ALREADY_CLOSED_ERROR };
    }
    return { ok: false, error: error?.message ?? "Could not close this month." };
  }

  // ---- The month-close snapshot (B2, item 177) ----
  // One row per (period, trainer, entity): the PAYABLE total PLUS the
  // trainer-principal bonus (item 175) for the same trainer/entity/period.
  // Written once, here, never again -- see the migration's own header for
  // why this does not make the table a ledger. A failure here does not
  // undo the close (closing is the real, already-committed fact; the
  // snapshot is a courtesy comparison, not the thing being closed) --
  // logged loudly instead, same choice as elsewhere on this screen.
  //
  // PAYABLE means APPROVED, not merely confirmed, as of item 185/186
  // (2026-11-09): a trainer's own confirmation is step one of Anca's real
  // three-step process, never the whole of it -- "o sesiune confirmata de
  // trainer NU e platibila. Platibila doar dupa aprobare." The amount
  // comes straight from each slot's own FROZEN
  // trainer_*_approved_amount_bani, not from a fresh calculate_org_
  // session_pay call: that call can disagree with what was actually
  // authorized if a grid has been restated in place since approval (the
  // measurement that decided freezing in the first place) -- the snapshot
  // must record what was authorized, not recompute a possibly-different
  // number at close time.
  const { from, toExclusive } = periodRange(period);

  const [{ data: sessions }, { data: bonusRows }] = await Promise.all([
    supabase
      .from("sessions")
      .select(
        "id, group_id, trainer_principal_id, trainer_secundar_id, trainer_principal_approved_at, trainer_principal_approved_amount_bani, trainer_secundar_approved_at, trainer_secundar_approved_amount_bani",
      )
      .eq("organization_id", orgId)
      .gte("session_date", from)
      .lt("session_date", toExclusive)
      .returns<SessionRow[]>(),
    supabase.rpc("calculate_org_principal_bonus", { p_organization_id: orgId, p_from: from, p_to_exclusive: toExclusive }),
  ]);

  if (!sessions) {
    console.error(`payroll_period_totals: could not read sessions for ${period} after closing -- snapshot skipped, close itself stands.`);
  } else {
    const groupIds = [...new Set(sessions.map((s) => s.group_id))];
    const { data: groups } = groupIds.length > 0
      ? await supabase.from("groups").select("id, contract_id").in("id", groupIds).returns<GroupRow[]>()
      : { data: [] as GroupRow[] };
    const contractIds = [...new Set((groups ?? []).map((g) => g.contract_id).filter((v): v is string => v !== null))];
    const { data: contracts } = contractIds.length > 0
      ? await supabase.from("contracts").select("id, legal_entity_id").in("id", contractIds).returns<ContractRow[]>()
      : { data: [] as ContractRow[] };
    const entityByContract = new Map((contracts ?? []).map((c) => [c.id, c.legal_entity_id]));
    const entityByGroup = new Map((groups ?? []).map((g) => [g.id, g.contract_id ? entityByContract.get(g.contract_id) ?? null : null]));
    const entityBySession = new Map(sessions.map((s) => [s.id, entityByGroup.get(s.group_id) ?? null]));

    const baniByKey = new Map<string, number>();
    const keyOf = (trainerId: string, entityId: string | null) => `${trainerId}::${entityId ?? "__unattributable__"}`;

    // Only APPROVED slots, at their own frozen amount -- never a confirmed-
    // but-unapproved slot, and never a live recalculation.
    for (const s of sessions) {
      const entityId = entityBySession.get(s.id) ?? null;
      if (s.trainer_principal_id && s.trainer_principal_approved_at !== null && s.trainer_principal_approved_amount_bani !== null) {
        const key = keyOf(s.trainer_principal_id, entityId);
        baniByKey.set(key, (baniByKey.get(key) ?? 0) + s.trainer_principal_approved_amount_bani);
      }
      if (s.trainer_secundar_id && s.trainer_secundar_approved_at !== null && s.trainer_secundar_approved_amount_bani !== null) {
        const key = keyOf(s.trainer_secundar_id, entityId);
        baniByKey.set(key, (baniByKey.get(key) ?? 0) + s.trainer_secundar_approved_amount_bani);
      }
    }

    // The bonus carries no entity of its own on the RPC's output (it is
    // keyed by client, not by group/contract) -- resolved the same way
    // /payroll's own page.tsx does, via entityOfClient, duplicated here
    // rather than imported: a second call site, same precedent as every
    // other small duplicated helper in this codebase (item 29's own
    // threshold is a sixth site, not a second).
    const bonusClientRows = (bonusRows ?? []) as BonusRow[];
    const bonusClientIds = [...new Set(bonusClientRows.map((r) => r.client_id))];
    const sampleGroupByClient = new Map<string, string>();
    if (bonusClientIds.length > 0) {
      const { data: bonusGroups } = await supabase
        .from("groups")
        .select("id, client_id")
        .in("client_id", bonusClientIds)
        .returns<{ id: string; client_id: string }[]>();
      for (const g of bonusGroups ?? []) {
        if (!sampleGroupByClient.has(g.client_id)) sampleGroupByClient.set(g.client_id, g.id);
      }
    }
    for (const r of bonusClientRows) {
      const groupId = sampleGroupByClient.get(r.client_id);
      const entityId = groupId ? entityByGroup.get(groupId) ?? null : null;
      const key = keyOf(r.trainer_id, entityId);
      baniByKey.set(key, (baniByKey.get(key) ?? 0) + Math.round(Number(r.amount) * 100));
    }

    const totalsRows = [...baniByKey.entries()].map(([key, amountBani]) => {
      const [trainerId, entityKey] = key.split("::");
      return {
        organization_id: orgId,
        payroll_period_id: data.id,
        trainer_id: trainerId,
        legal_entity_id: entityKey === "__unattributable__" ? null : entityKey,
        amount_bani: amountBani,
      };
    });

    if (totalsRows.length > 0) {
      const { error: snapshotError } = await supabase.from("payroll_period_totals").insert(totalsRows);
      if (snapshotError) {
        console.error(`payroll_period_totals: snapshot insert failed for ${period} -- close itself still stands:`, snapshotError);
      }
    }
  }

  revalidatePath("/payroll");
  return { ok: true, id: data.id };
}

export type ApprovedSlotResult = { session_id: string; slot: "principal" | "secundar" | null; status: string; amount_bani: number | null };
export type ApproveSessionPayResult = { ok: true; rows: ApprovedSlotResult[] } | { ok: false; error: string };

// Bulk, on purpose (item 185/186, Anca's own decision, not asked): one
// action approves every confirmed-and-not-yet-approved slot across
// however many session ids the screen sends, in one RPC call. The gate
// itself lives in app.rpc_approve_session_pay (finance.approvals.approve
// / finance.operations.* / org.settings.manage / platform owner) -- this
// action does not duplicate it, only forwards the per-slot result so the
// screen can report exactly what happened to each card.
export async function approveSessionPay(sessionIds: string[]): Promise<ApproveSessionPayResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: "Not signed in." };
  }
  if (sessionIds.length === 0) {
    return { ok: true, rows: [] };
  }

  const { data, error } = await supabase.rpc("rpc_approve_session_pay", { p_session_ids: sessionIds });
  if (error) {
    return { ok: false, error: error.message };
  }

  revalidatePath("/payroll");
  return { ok: true, rows: (data ?? []) as ApprovedSlotResult[] };
}
