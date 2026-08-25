"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

// Same relationship as app/(app)/clients/actions.ts: runs through the
// caller's own session client, so the C1 RLS INSERT/UPDATE policies on
// contracts (202608100003 — contract_administrator + Master only,
// excluding finance_admin_reporting despite it sharing the contracts.*
// capability key) are the real authority. The has_capability-gated
// buttons in contracts-client.tsx / [id]/contract-detail-client.tsx are a
// convenience; a request that reaches here without the right capability
// gets rejected by RLS, not by app code.
export async function addContract(
  orgId: string,
  clientId: string,
  legalEntityId: string,
  entryNumber: string,
  exitNumber: string,
  contractType: string,
  periodStart: string,
  periodEnd: string,
  billingRule: string,
  signedDate: string,
  estimatedValue: string,
  previousYearValue: string,
): Promise<ActionResult> {
  if (!clientId || !legalEntityId || !contractType) {
    return {
      ok: false,
      error: "Client, legal entity, and type are required.",
    };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("contracts")
    .insert({
      organization_id: orgId,
      client_id: clientId,
      legal_entity_id: legalEntityId,
      entry_number: entryNumber.trim() || null,
      exit_number: exitNumber.trim() || null,
      contract_type: contractType,
      period_start: periodStart || null,
      period_end: periodEnd || null,
      billing_rule: billingRule.trim() || null,
      signed_date: signedDate || null,
      estimated_value: estimatedValue.trim() ? Number(estimatedValue) : null,
      previous_year_value: previousYearValue.trim() ? Number(previousYearValue) : null,
      status: "draft",
    })
    .select("id")
    .single();

  if (error || !data) {
    // 23505 = unique_violation. The only unique constraint this insert can
    // hit is contracts_unique_organization_exit_number (202608180002) —
    // Postgres's own message names the constraint but reads as raw SQL,
    // not something to show a non-technical user.
    if (error?.code === "23505") {
      return {
        ok: false,
        error: "This exit number is already used by another contract in your organization.",
      };
    }
    return { ok: false, error: error?.message ?? "Could not create contract." };
  }

  revalidatePath("/contracts");
  return { ok: true, id: data.id };
}

export async function markContractSigned(
  contractId: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const supabase = await createClient();

  // Read current status/signed_date first, under the caller's own session
  // (RLS still applies) — this is what lets us tell "not visible to you /
  // doesn't exist" apart from "visible, but the wrong status" below,
  // rather than collapsing both into one ambiguous 0-rows-affected error.
  const { data: current } = await supabase
    .from("contracts")
    .select("status, signed_date")
    .eq("id", contractId)
    .maybeSingle();

  if (!current) {
    return {
      ok: false,
      error: "Contract not found, or not visible to your role.",
    };
  }

  if (current.status !== "draft" && current.status !== "sent") {
    return {
      ok: false,
      error: `Cannot mark as signed from status "${current.status}".`,
    };
  }

  // signed_date: only set if it isn't already there — addContract lets a
  // date be backdated at creation time, and that value must win over
  // "today" if it's already set.
  const signedDate = current.signed_date ?? new Date().toISOString().slice(0, 10);

  // .in("status", [...]) here is defense against a race: the read above
  // and this write aren't atomic, so if the status changed between them
  // (e.g. two tabs), this still won't move anything but a draft/sent row.
  const { data, error } = await supabase
    .from("contracts")
    .update({ status: "signed", signed_date: signedDate })
    .eq("id", contractId)
    .in("status", ["draft", "sent"])
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  // RLS blocks (rather than errors) an unauthorized UPDATE — it succeeds
  // with 0 rows affected, not a thrown error. Same shape the sabotage/
  // negative tests in db/tests/rls_clients_contracts.sql rely on. At this
  // point the status check above has already passed, so 0 rows here means
  // capability, not status.
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted (requires contract_administrator or Master).",
    };
  }

  revalidatePath(`/contracts/${contractId}`);
  revalidatePath("/contracts");
  return { ok: true };
}

// Fields editable in V1, any status: client_id, legal_entity_id,
// contract_type, period_start, period_end, entry_number, exit_number,
// drive_ref, notes, offer_structure, ac_link. Deliberately excluded:
// status (markContractSigned owns every transition into/out of it) and
// renewal_of (no renewal flow exists yet — a bare FK input with nothing
// behind it isn't a feature, see docs discussion this round).
//
// financials is null when the caller's session cannot read billing_rule /
// estimated_value / previous_year_value through contracts_billing_masked
// — the SAME three-capability check the masking function itself uses
// (finance.operations.*, finance.reporting.*, clients.create), re-checked
// HERE rather than trusted from the client. The form only ever shows
// financial inputs when it already knows the caller can see real values,
// but a client is not a trust boundary — this action independently
// verifies before ever touching those three columns, and if the check
// fails, they are left OUT of the update payload entirely. Not set to
// null, not overwritten with whatever masked value the form happened to
// prefill — simply never mentioned in the UPDATE, so Postgres never
// touches them. A field this session cannot read is a field it cannot
// write, symmetrically with the SELECT-side masking.
export async function updateContract(
  contractId: string,
  clientId: string,
  legalEntityId: string,
  contractType: string,
  periodStart: string,
  periodEnd: string,
  entryNumber: string,
  exitNumber: string,
  driveRef: string,
  notes: string,
  offerStructure: string,
  acLink: string,
  financials: {
    billingRule: string;
    estimatedValue: string;
    previousYearValue: string;
  } | null,
): Promise<ActionResult> {
  if (!clientId || !legalEntityId || !contractType) {
    return {
      ok: false,
      error: "Client, legal entity, and type are required.",
    };
  }

  const supabase = await createClient();

  const { data: current } = await supabase
    .from("contracts")
    .select("organization_id")
    .eq("id", contractId)
    .maybeSingle();

  if (!current) {
    return {
      ok: false,
      error: "Contract not found, or not visible to your role.",
    };
  }

  const financeVisible =
    (await checkCapability(supabase, "finance.operations.*", current.organization_id)) ||
    (await checkCapability(supabase, "finance.reporting.*", current.organization_id)) ||
    (await checkCapability(supabase, "clients.create", current.organization_id));

  const payload: Record<string, unknown> = {
    client_id: clientId,
    legal_entity_id: legalEntityId,
    contract_type: contractType,
    period_start: periodStart || null,
    period_end: periodEnd || null,
    entry_number: entryNumber.trim() || null,
    exit_number: exitNumber.trim() || null,
    drive_ref: driveRef.trim() || null,
    notes: notes.trim() || null,
    offer_structure: offerStructure || null,
    ac_link: acLink.trim() || null,
  };

  if (financeVisible && financials) {
    payload.billing_rule = financials.billingRule.trim() || null;
    payload.estimated_value = financials.estimatedValue.trim()
      ? Number(financials.estimatedValue)
      : null;
    payload.previous_year_value = financials.previousYearValue.trim()
      ? Number(financials.previousYearValue)
      : null;
  }

  const { data, error } = await supabase
    .from("contracts")
    .update(payload)
    .eq("id", contractId)
    .select("id");

  if (error) {
    if (error.code === "23505") {
      return {
        ok: false,
        error: "This exit number is already used by another contract in your organization.",
      };
    }
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted (requires contract_administrator or Master).",
    };
  }

  revalidatePath(`/contracts/${contractId}`);
  revalidatePath("/contracts");
  return { ok: true, id: contractId };
}
