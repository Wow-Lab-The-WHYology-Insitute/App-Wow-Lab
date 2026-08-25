"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { CLIENT_STATUS_TRANSITIONS } from "./status";

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

// Unlike app/(app)/admin/users/actions.ts, this never touches
// lib/supabase-admin.ts (service_role). The C1 RLS policy on clients
// (supabase/migrations/202608100003) already gates INSERT on
// clients.create — this action runs the insert through the caller's own
// session client and lets that policy be the actual authority. If someone
// reaches this action without the capability, RLS rejects the insert (no
// grant match on WITH CHECK) and Postgres/PostgREST surface that as an
// error here — the UI-level capability check that hides the "+ New
// Client" button is a convenience, not the enforcement.
export async function addClient(
  orgId: string,
  name: string,
  clientType: string,
  businessLine: string,
  legalName: string,
  cui: string,
): Promise<ActionResult> {
  if (!name.trim() || !clientType) {
    return { ok: false, error: "Name and client type are required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("clients")
    .insert({
      organization_id: orgId,
      name: name.trim(),
      client_type: clientType,
      business_line: businessLine.trim() || null,
      legal_name: legalName.trim() || null,
      cui: cui.trim() || null,
      status: "prospect",
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create client." };
  }

  revalidatePath("/clients");
  return { ok: true, id: data.id };
}

export type VoidActionResult = { ok: true } | { ok: false; error: string };

// Same relationship as addClient: runs through the caller's own session
// client, so the client_contacts RLS INSERT/UPDATE policies
// (202608100003 — org/platform owner, clients.create, or contracts.*
// excluding either finance role) are the real authority. The
// canManageContacts()-gated form in clients/[id]/page.tsx is a
// convenience; a request that reaches here without the right capability
// gets rejected by RLS, not by app code.
export async function addClientContact(
  orgId: string,
  clientId: string,
  fullName: string,
  roleAtClient: string,
  email: string,
  phone: string,
  contactPurpose: string,
  isPrimary: boolean,
  isBillingContact: boolean,
): Promise<ActionResult> {
  if (!fullName.trim()) {
    return { ok: false, error: "Full name is required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("client_contacts")
    .insert({
      organization_id: orgId,
      client_id: clientId,
      full_name: fullName.trim(),
      role_at_client: roleAtClient.trim() || null,
      email: email.trim() || null,
      phone: phone.trim() || null,
      contact_purpose: contactPurpose || null,
      is_primary: isPrimary,
      is_billing_contact: isBillingContact,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create contact." };
  }

  revalidatePath(`/clients/${clientId}`);
  return { ok: true, id: data.id };
}

export async function updateClientContact(
  clientId: string,
  contactId: string,
  fullName: string,
  roleAtClient: string,
  email: string,
  phone: string,
  contactPurpose: string,
  isPrimary: boolean,
  isBillingContact: boolean,
): Promise<VoidActionResult> {
  if (!fullName.trim()) {
    return { ok: false, error: "Full name is required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("client_contacts")
    .update({
      full_name: fullName.trim(),
      role_at_client: roleAtClient.trim() || null,
      email: email.trim() || null,
      phone: phone.trim() || null,
      contact_purpose: contactPurpose || null,
      is_primary: isPrimary,
      is_billing_contact: isBillingContact,
    })
    .eq("id", contactId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  // RLS blocks (rather than errors) an unauthorized UPDATE — it succeeds
  // with 0 rows affected, not a thrown error, same shape as
  // markContractSigned in app/(app)/contracts/actions.ts.
  if (!data || data.length === 0) {
    return { ok: false, error: "Not permitted." };
  }

  revalidatePath(`/clients/${clientId}`);
  return { ok: true };
}

// DELETE policy on client_contacts (202608270001) is deliberately IDENTICAL
// to the existing INSERT/UPDATE predicate (202608100003) -- org/platform
// owner, clients.create, or contracts.* excluding either finance role. No
// status condition: a contact is a person's details, not a transaction
// record, so a wrong one vanishes outright regardless of primary/billing
// flags. This also serves GDPR erasure -- the 36-month retention
// anonymization job never covered a person asking to be removed now; this
// is that path (see the migration's own comment, and DATABASE_CONVENTIONS
// Sec9/Sec12).
//
// Unlike updateClientContact above, this explicitly re-checks the
// predicate via checkCapability before attempting the write, rather than
// leaning on RLS's silent "0 rows affected" alone -- same reasoning as
// changeClientStatus/updateClient's explicit checks: a delete deserves a
// real "not permitted" message, not a delete that silently no-ops. The RLS
// policy remains the actual enforcement; this is defense-in-depth plus a
// better error.
export async function deleteClientContact(
  contactId: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();

  const { data: contact } = await supabase
    .from("client_contacts")
    .select("id, client_id, organization_id, full_name")
    .eq("id", contactId)
    .maybeSingle();

  if (!contact) {
    return {
      ok: false,
      error: "Contact not found, or not visible to your role.",
    };
  }

  const [isOwner, hasClientsCreate, hasContractsStar, isFinanceReporting, isFinanceOps] =
    await Promise.all([
      checkCapability(supabase, "org.settings.manage", contact.organization_id),
      checkCapability(supabase, "clients.create", contact.organization_id),
      checkCapability(supabase, "contracts.*", contact.organization_id),
      checkCapability(supabase, "finance.reporting.*", contact.organization_id),
      checkCapability(supabase, "finance.operations.*", contact.organization_id),
    ]);
  const canDelete =
    isOwner || hasClientsCreate || (hasContractsStar && !isFinanceReporting && !isFinanceOps);

  if (!canDelete) {
    return { ok: false, error: "Not permitted." };
  }

  const { data, error } = await supabase
    .from("client_contacts")
    .delete()
    .eq("id", contactId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return { ok: false, error: "Not permitted." };
  }

  revalidatePath(`/clients/${contact.client_id}`);
  return { ok: true };
}

// Owns clients.status entirely -- the edit form (updateClient, below)
// never touches this column. Same reasoning as markContractSigned: this
// is the only write path to the column today, so the guard lives here,
// not in a DB constraint or trigger; a second write path appearing is the
// point to reconsider that.
//
// Gated on clients.convert specifically, checked explicitly here rather
// than left to the table's own UPDATE policy (org.settings.manage OR
// clients.create) -- that policy is coarser than this action needs. Today
// clients.convert and clients.create are held by the identical three
// roles (organization_owner, platform_owner, sales_manager), so this
// changes nothing about who can act -- but it means a future role split
// (someone gets clients.create without clients.convert) is enforced
// correctly the day it happens, not silently allowed because the action
// only ever checked the coarser capability. The .eq("status", ...) on the
// write itself is still there too, as the same defense-in-depth the RLS
// policy already provides against a stale read.
export async function changeClientStatus(
  clientId: string,
  newStatus: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const supabase = await createClient();

  const { data: current } = await supabase
    .from("clients")
    .select("organization_id, status")
    .eq("id", clientId)
    .maybeSingle();

  if (!current) {
    return {
      ok: false,
      error: "Client not found, or not visible to your role.",
    };
  }

  const allowedNext = CLIENT_STATUS_TRANSITIONS[current.status] ?? [];
  if (!allowedNext.includes(newStatus)) {
    return {
      ok: false,
      error: `Cannot move from "${current.status}" to "${newStatus}".`,
    };
  }

  const canConvert = await checkCapability(
    supabase,
    "clients.convert",
    current.organization_id,
  );
  if (!canConvert) {
    return {
      ok: false,
      error: "Not permitted (requires sales_manager or Master).",
    };
  }

  const { data, error } = await supabase
    .from("clients")
    .update({ status: newStatus })
    .eq("id", clientId)
    .eq("status", current.status)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted, or the status already changed.",
    };
  }

  revalidatePath(`/clients/${clientId}`);
  revalidatePath("/clients");
  return { ok: true };
}

// Fields editable in V1, any status: name, client_type, business_line,
// legal_name, cui, notes -- gated by the table's own UPDATE policy
// (org.settings.manage OR clients.create), which is already exactly the
// right granularity for these, same relationship addClient already has to
// the INSERT policy. status is deliberately excluded -- changeClientStatus
// above owns that column entirely.
//
// external_crm_ref is different: checked here explicitly against
// crm_link.*, a capability seeded specifically for this field (seed.sql:
// "ActiveCampaign CRM reference/link") and never referenced anywhere in
// app code until now. Confirmed live before writing this: crm_link.* is
// held today by the identical three roles as clients.create
// (organization_owner, platform_owner, sales_manager) -- so this gate is
// NON-DISCRIMINATING in production right now. Every caller who can reach
// this action at all already holds crm_link.* too. It is wired correctly
// and protects nothing yet -- same honesty as the trainer branch on
// client_contacts (202608250001's contact_purpose = 'trainer_facing'
// branch). RE-VERIFY THE DAY a role holds clients.create without
// crm_link.* -- that's the day this line actually starts doing something.
//
// When the check fails, external_crm_ref is left OUT of the payload
// entirely -- not set to null, not overwritten with whatever the form
// happened to prefill. Same rule as contracts' financial fields: a field
// this session cannot edit is a field this action must not touch, even if
// the caller somehow submitted a value for it.
export async function updateClient(
  clientId: string,
  name: string,
  clientType: string,
  businessLine: string,
  legalName: string,
  cui: string,
  notes: string,
  externalCrmRef: string,
): Promise<ActionResult> {
  if (!name.trim() || !clientType) {
    return { ok: false, error: "Name and client type are required." };
  }

  const supabase = await createClient();

  const { data: current } = await supabase
    .from("clients")
    .select("organization_id")
    .eq("id", clientId)
    .maybeSingle();

  if (!current) {
    return {
      ok: false,
      error: "Client not found, or not visible to your role.",
    };
  }

  const canEditCrmLink = await checkCapability(
    supabase,
    "crm_link.*",
    current.organization_id,
  );

  const payload: Record<string, unknown> = {
    name: name.trim(),
    client_type: clientType,
    business_line: businessLine.trim() || null,
    legal_name: legalName.trim() || null,
    cui: cui.trim() || null,
    notes: notes.trim() || null,
  };

  if (canEditCrmLink) {
    payload.external_crm_ref = externalCrmRef.trim() || null;
  }

  const { data, error } = await supabase
    .from("clients")
    .update(payload)
    .eq("id", clientId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted (requires sales_manager or Master).",
    };
  }

  revalidatePath(`/clients/${clientId}`);
  revalidatePath("/clients");
  return { ok: true, id: clientId };
}
