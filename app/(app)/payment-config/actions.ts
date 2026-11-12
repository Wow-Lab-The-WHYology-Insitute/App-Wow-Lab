"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// error is a stable CODE, not a message: a Finance user never sees a raw
// Postgres/RLS string; the client resolves the code through
// paymentConfigDict (EN+RO). Keep new codes in sync with that dict.
export type ConfirmedPayImpact = {
  sessions: number;
  slots: number;
  unpriceable_slots: number;
  months: string[];
  total_before: number;
  total_after: number;
  delta: number;
};

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: "incomplete_form" | "save_failed" | "date_taken" }
  | { ok: false; error: "missing_bands"; missing: string[] }
  | { ok: false; error: "would_change_confirmed_pay"; detail: ConfirmedPayImpact };

type Grid = "trainer_grade" | "location_bonus" | "language_bonus" | "duration_multiplier" | "contract_type_uplift";

// One RPC, one transaction: header and rows are written together or not at
// all (202611120001). The two-step client insert this replaces could leave
// an orphan header -- its compensating DELETE had no grant (item 194).
async function createVersion(
  grid: Grid,
  organizationId: string,
  effectiveDate: string,
  note: string,
  rows: Record<string, unknown>[],
): Promise<ActionResult> {
  if (!effectiveDate || rows.length === 0 || rows.some((r) => Object.values(r).some((v) => v === "" || v === null))) {
    return { ok: false, error: "incomplete_form" };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_create_grid_version", {
    p_grid: grid,
    p_organization_id: organizationId,
    p_effective_date: effectiveDate,
    p_note: note,
    p_rows: rows,
  });

  if (error || !data) {
    return { ok: false, error: "save_failed" };
  }

  const result = data as ActionResult;
  if (result.ok) {
    revalidatePath("/payment-config");
  }
  return result;
}

const num = (v: string) => (v === "" ? null : Number(v));

export async function createTrainerGradeVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  rates: Record<number, string>, // grade level (1-6) -> rate
): Promise<ActionResult> {
  const rows = Object.entries(rates).map(([level, rate]) => ({ grade_level: Number(level), rate: num(rate) }));
  return createVersion("trainer_grade", orgId, effectiveDate, note, rows);
}

export async function createLocationBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // tier -> bonus_percent
): Promise<ActionResult> {
  const rows = Object.entries(bonuses).map(([tier, pct]) => ({ location_tier: tier, bonus_percent: num(pct) }));
  return createVersion("location_bonus", orgId, effectiveDate, note, rows);
}

export async function createLanguageBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // language group -> bonus_percent
): Promise<ActionResult> {
  const rows = Object.entries(bonuses).map(([group, pct]) => ({ language_group: group, bonus_percent: num(pct) }));
  return createVersion("language_bonus", orgId, effectiveDate, note, rows);
}

export async function createDurationMultiplierVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  // "<minutes>:<delivery_context>" -> multiplier, one entry per band the form rendered
  multipliers: Record<string, string>,
): Promise<ActionResult> {
  const rows = Object.entries(multipliers).map(([key, mult]) => {
    const [minutes, context] = key.split(":");
    return { duration_minutes: Number(minutes), delivery_context: context, multiplier: num(mult) };
  });
  return createVersion("duration_multiplier", orgId, effectiveDate, note, rows);
}

export async function createContractTypeUpliftVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  uplifts: Record<string, string>, // contract_type -> uplift_percent
): Promise<ActionResult> {
  const rows = Object.entries(uplifts).map(([type, pct]) => ({ contract_type: type, uplift_percent: num(pct) }));
  return createVersion("contract_type_uplift", orgId, effectiveDate, note, rows);
}
