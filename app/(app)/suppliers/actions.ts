"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

// Same relationship as app/(app)/clients/actions.ts: runs through the
// caller's own session client, so the suppliers RLS INSERT policy
// (202608300001 -- is_platform_owner() OR finance.reporting.*) is the
// real authority. The finance.reporting.*-gated form in
// suppliers-client.tsx is a convenience; a request that reaches here
// without the capability gets rejected by RLS, not by app code.
//
// status is deliberately NOT accepted here -- addSupplier always creates
// 'active' (the column default), matching addClient's status: "prospect"
// pattern. There's no creation-time reason to start a supplier inactive.
export async function addSupplier(
  orgId: string,
  name: string,
  legalName: string,
  cui: string,
  serviceType: string,
  notes: string,
): Promise<ActionResult> {
  if (!name.trim()) {
    return { ok: false, error: "Name is required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("suppliers")
    .insert({
      organization_id: orgId,
      name: name.trim(),
      legal_name: legalName.trim() || null,
      cui: cui.trim() || null,
      service_type: serviceType.trim() || null,
      notes: notes.trim() || null,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create supplier." };
  }

  revalidatePath("/suppliers");
  return { ok: true, id: data.id };
}

export type VoidActionResult = { ok: true } | { ok: false; error: string };

// Fields editable, any status: name, legal_name, cui, service_type, notes,
// and status itself -- unlike clients.status (a real state machine gated
// by its own clients.convert capability), suppliers.status is a plain
// active/inactive toggle with no transition rules to protect, so it lives
// in the general update payload rather than a dedicated guarded action.
// Gated by the table's own UPDATE policy alone (identical to INSERT/
// SELECT: is_platform_owner() OR finance.reporting.*) -- same relationship
// updateClient has to the clients UPDATE policy for its own general fields.
export async function updateSupplier(
  supplierId: string,
  name: string,
  legalName: string,
  cui: string,
  serviceType: string,
  status: string,
  notes: string,
): Promise<VoidActionResult> {
  if (!name.trim()) {
    return { ok: false, error: "Name is required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("suppliers")
    .update({
      name: name.trim(),
      legal_name: legalName.trim() || null,
      cui: cui.trim() || null,
      service_type: serviceType.trim() || null,
      status,
      notes: notes.trim() || null,
    })
    .eq("id", supplierId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  // RLS blocks (rather than errors) an unauthorized UPDATE -- it succeeds
  // with 0 rows affected, not a thrown error. Same shape as
  // updateClientContact/updateClient elsewhere in this codebase.
  if (!data || data.length === 0) {
    return { ok: false, error: "Not permitted." };
  }

  revalidatePath(`/suppliers/${supplierId}`);
  revalidatePath("/suppliers");
  return { ok: true };
}
