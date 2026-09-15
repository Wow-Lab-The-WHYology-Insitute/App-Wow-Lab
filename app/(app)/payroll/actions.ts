"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { PAYROLL_PERIOD_ALREADY_CLOSED_ERROR } from "./close-error";

export type ActionResult = { ok: true; id: string } | { ok: false; error: string };

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

  revalidatePath("/payroll");
  return { ok: true, id: data.id };
}
