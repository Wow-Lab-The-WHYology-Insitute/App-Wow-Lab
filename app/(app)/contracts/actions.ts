"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

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
  const { data, error } = await supabase
    .from("contracts")
    .update({ status: "signed" })
    .eq("id", contractId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  // RLS blocks (rather than errors) an unauthorized UPDATE — it succeeds
  // with 0 rows affected, not a thrown error. Same shape the sabotage/
  // negative tests in db/tests/rls_clients_contracts.sql rely on.
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
