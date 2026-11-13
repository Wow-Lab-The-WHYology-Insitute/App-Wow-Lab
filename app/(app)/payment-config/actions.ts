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

// One mapping from a form's values to a grid's rows, shared by "new version"
// and "correct this version" so the two can never send different shapes.
function rowsFor(grid: Grid, values: Record<string, string>): Record<string, unknown>[] {
  const entries = Object.entries(values);
  switch (grid) {
    case "trainer_grade":
      return entries.map(([level, rate]) => ({ grade_level: Number(level), rate: num(rate) }));
    case "location_bonus":
      return entries.map(([tier, pct]) => ({ location_tier: tier, bonus_percent: num(pct) }));
    case "language_bonus":
      return entries.map(([group, pct]) => ({ language_group: group, bonus_percent: num(pct) }));
    case "duration_multiplier":
      // "<minutes>:<delivery_context>" -> multiplier, one entry per band the form rendered
      return entries.map(([key, mult]) => {
        const [minutes, context] = key.split(":");
        return { duration_minutes: Number(minutes), delivery_context: context, multiplier: num(mult) };
      });
    case "contract_type_uplift":
      return entries.map(([type, pct]) => ({ contract_type: type, uplift_percent: num(pct) }));
  }
}

export async function createTrainerGradeVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  rates: Record<number, string>, // grade level (1-6) -> rate
): Promise<ActionResult> {
  return createVersion("trainer_grade", orgId, effectiveDate, note, rowsFor("trainer_grade", rates as Record<string, string>));
}

export async function createLocationBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // tier -> bonus_percent
): Promise<ActionResult> {
  return createVersion("location_bonus", orgId, effectiveDate, note, rowsFor("location_bonus", bonuses));
}

export async function createLanguageBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // language group -> bonus_percent
): Promise<ActionResult> {
  return createVersion("language_bonus", orgId, effectiveDate, note, rowsFor("language_bonus", bonuses));
}

export async function createDurationMultiplierVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  multipliers: Record<string, string>,
): Promise<ActionResult> {
  return createVersion("duration_multiplier", orgId, effectiveDate, note, rowsFor("duration_multiplier", multipliers));
}

export async function createContractTypeUpliftVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  uplifts: Record<string, string>, // contract_type -> uplift_percent
): Promise<ActionResult> {
  return createVersion("contract_type_uplift", orgId, effectiveDate, note, rowsFor("contract_type_uplift", uplifts));
}

// ---------------------------------------------------------------------------
// Correcting a version (item 195, 202611140001). Preview returns the impact
// statement; apply sends back EXACTLY the statement the person confirmed, and
// the database refuses it (declaration_stale, with the new one) if the pay it
// describes has moved since. The statement is passed through untouched -- the
// database compares it with =.
// ---------------------------------------------------------------------------

export type CorrectableGrid = "trainer_grade" | "location_bonus" | "language_bonus" | "duration_multiplier";

export type Declaration = {
  affected: {
    session_id: string;
    slot: string;
    date: string;
    trainer_id: string | null;
    trainer: string | null;
    client: string | null;
    before: number | null;
    after: number | null;
  }[];
  frozen: {
    session_id: string;
    slot: string;
    date: string;
    trainer_id: string | null;
    trainer: string | null;
    client: string | null;
    approved_at: string;
    frozen: number | null;
    would_be: number | null;
  }[];
  by_trainer_month: { month: string; trainer_id: string | null; trainer: string | null; slots: number; before: number; after: number }[];
  summary: ConfirmedPayImpact;
  frozen_summary: { slots: number; frozen_total: number; would_be_total: number };
};

export type CorrectionError =
  | { ok: false; error: "forbidden" | "not_found" | "already_corrected" | "incomplete_form" | "save_failed" | "unknown_grid" }
  | { ok: false; error: "missing_bands"; missing: string[] }
  | { ok: false; error: "declaration_stale"; declaration: Declaration };

export type PreviewResult = { ok: true; declaration: Declaration } | CorrectionError;
export type ApplyResult = { ok: true; id: string } | CorrectionError;

export async function previewGridCorrection(
  grid: CorrectableGrid,
  versionId: string,
  note: string,
  values: Record<string, string>,
): Promise<PreviewResult> {
  const rows = rowsFor(grid, values);
  if (rows.some((r) => Object.values(r).some((v) => v === "" || v === null || Number.isNaN(v)))) {
    return { ok: false, error: "incomplete_form" };
  }
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_preview_grid_correction", {
    p_grid: grid,
    p_corrects_version_id: versionId,
    p_note: note,
    p_rows: rows,
  });
  if (error || !data) {
    return { ok: false, error: "save_failed" };
  }
  return data as PreviewResult;
}

export async function applyGridCorrection(
  grid: CorrectableGrid,
  versionId: string,
  note: string,
  values: Record<string, string>,
  declaration: Declaration,
): Promise<ApplyResult> {
  const rows = rowsFor(grid, values);
  if (rows.some((r) => Object.values(r).some((v) => v === "" || v === null || Number.isNaN(v)))) {
    return { ok: false, error: "incomplete_form" };
  }
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_apply_grid_correction", {
    p_grid: grid,
    p_corrects_version_id: versionId,
    p_note: note,
    p_rows: rows,
    p_declaration: declaration,
  });
  if (error || !data) {
    return { ok: false, error: "save_failed" };
  }
  const result = data as ApplyResult;
  if (result.ok) {
    revalidatePath("/payment-config");
    revalidatePath("/payroll");
  }
  return result;
}
