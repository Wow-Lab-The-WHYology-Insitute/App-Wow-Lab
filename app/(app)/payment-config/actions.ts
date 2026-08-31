"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// error is a stable CODE, not a message -- deliberately different from
// most actions in this app (which return error.message raw and the
// caller shows it untranslated). The whole point of this page is that a
// Finance user never sees a raw Postgres/RLS error string; the client
// resolves this code through paymentConfigDict (EN+RO). Keep new codes
// added here in sync with that dict.
export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: "incomplete_form" | "save_failed" };

// Header-then-rows, not a single DB transaction (no RPC function backs
// this -- migration (c) is UI only, no new SQL). A single multi-row
// INSERT for the rates rows is itself atomic; the only real gap is
// between the header succeeding and the rows insert failing. If that
// happens, the header is deleted before returning an error, so a version
// that exists on screen is never one this app created incomplete --
// though app.resolve_* would catch an incomplete version loudly anyway
// (Sec12.9's two-step resolution), this avoids ever creating one in the
// first place rather than relying on that as the only backstop.
async function createVersion(
  headerTable: string,
  rowsTable: string,
  organizationId: string,
  effectiveDate: string,
  note: string,
  rows: Record<string, unknown>[],
): Promise<ActionResult> {
  if (!effectiveDate || rows.length === 0 || rows.some((r) => Object.values(r).some((v) => v === "" || v === null))) {
    return { ok: false, error: "incomplete_form" };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: "save_failed" };
  }

  const { data: version, error: versionError } = await supabase
    .from(headerTable)
    .insert({
      organization_id: organizationId,
      effective_date: effectiveDate,
      created_by: user.id,
      note: note.trim() || null,
    })
    .select("id")
    .single();

  if (versionError || !version) {
    return { ok: false, error: "save_failed" };
  }

  const { error: rowsError } = await supabase
    .from(rowsTable)
    .insert(rows.map((r) => ({ ...r, organization_id: organizationId, version_id: version.id })));

  if (rowsError) {
    await supabase.from(headerTable).delete().eq("id", version.id);
    return { ok: false, error: "save_failed" };
  }

  revalidatePath("/payment-config");
  return { ok: true, id: version.id };
}

export async function createTrainerGradeVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  rates: Record<number, string>, // grade level (1-6) -> rate
): Promise<ActionResult> {
  const rows = Object.entries(rates).map(([level, rate]) => ({
    grade_level: Number(level),
    rate: rate === "" ? null : Number(rate),
  }));
  return createVersion("trainer_grade_versions", "trainer_grade_rates", orgId, effectiveDate, note, rows);
}

export async function createLocationBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // tier -> bonus_percent
): Promise<ActionResult> {
  const rows = Object.entries(bonuses).map(([tier, pct]) => ({
    location_tier: tier,
    bonus_percent: pct === "" ? null : Number(pct),
  }));
  return createVersion("location_bonus_versions", "location_bonus_rates", orgId, effectiveDate, note, rows);
}

export async function createLanguageBonusVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  bonuses: Record<string, string>, // language group -> bonus_percent
): Promise<ActionResult> {
  const rows = Object.entries(bonuses).map(([group, pct]) => ({
    language_group: group,
    bonus_percent: pct === "" ? null : Number(pct),
  }));
  return createVersion("language_bonus_versions", "language_bonus_rates", orgId, effectiveDate, note, rows);
}

export async function createDurationMultiplierVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  // "30:standard" | "60:standard" | "90:standard" | "120:standard" | "120:scoala_altfel_saptamana_verde" -> multiplier
  multipliers: Record<string, string>,
): Promise<ActionResult> {
  const rows = Object.entries(multipliers).map(([key, mult]) => {
    const [minutes, context] = key.split(":");
    return {
      duration_minutes: Number(minutes),
      delivery_context: context,
      multiplier: mult === "" ? null : Number(mult),
    };
  });
  return createVersion("duration_multiplier_versions", "duration_multiplier_rates", orgId, effectiveDate, note, rows);
}

export async function createContractTypeUpliftVersion(
  orgId: string,
  effectiveDate: string,
  note: string,
  uplifts: Record<string, string>, // contract_type -> uplift_percent
): Promise<ActionResult> {
  const rows = Object.entries(uplifts).map(([type, pct]) => ({
    contract_type: type,
    uplift_percent: pct === "" ? null : Number(pct),
  }));
  return createVersion("contract_type_uplift_versions", "contract_type_uplift_rates", orgId, effectiveDate, note, rows);
}
