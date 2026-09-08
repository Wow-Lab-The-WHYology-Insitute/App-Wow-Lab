"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

export type VoidActionResult = { ok: true } | { ok: false; error: string };

// Same relationship as app/(app)/clients/actions.ts and app/(app)/contracts/
// actions.ts: runs through the caller's own session client, so the G1 RLS
// policies (202608130003 — groups.create/sessions.create, Operations
// Manager + Master only) are the real authority. The has_capability-gated
// forms in groups-client.tsx / [id]/group-detail-client.tsx are a
// convenience; a request that reaches here without the right capability
// gets rejected by RLS, not by app code.
export async function addGroup(
  orgId: string,
  clientId: string,
  module: string,
  deliveryFormat: string,
  schedulePattern: string,
  status: string,
  ageRange: string,
  schoolYearCalendarLink: string,
  contractId: string,
): Promise<ActionResult> {
  if (!clientId || !module || !deliveryFormat) {
    return { ok: false, error: "Client, module, and delivery format are required." };
  }

  const supabase = await createClient();

  // contract_id is optional (202608290001: a group can legitimately exist
  // before its contract is signed) but when supplied must belong to the
  // same client the group is being created for -- re-checked here, not
  // trusted from the form's own client-side filtering, same reasoning as
  // updateGroup below.
  if (contractId) {
    const { data: contract } = await supabase
      .from("contracts")
      .select("id, client_id")
      .eq("id", contractId)
      .maybeSingle();
    if (!contract || contract.client_id !== clientId) {
      return { ok: false, error: "That contract does not belong to the selected client." };
    }
  }

  const { data, error } = await supabase
    .from("groups")
    .insert({
      organization_id: orgId,
      client_id: clientId,
      module,
      delivery_format: deliveryFormat,
      schedule_pattern: schedulePattern.trim() || null,
      status,
      age_range: ageRange.trim() || null,
      school_year_calendar_link: schoolYearCalendarLink.trim() || null,
      contract_id: contractId || null,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create group." };
  }

  revalidatePath("/groups");
  return { ok: true, id: data.id };
}

// Same relationship as updateContract/updateClient: runs through the
// caller's own session client, so the "authenticated update groups" RLS
// policy (202608130003 -- groups.create, i.e. Operations Manager + Master)
// is the real authority; this action's own checks are a second, explicit
// line so the caller gets a real reason rather than a mystery no-op.
//
// In scope: notes and contract_id -- both plain scalars the RLS UPDATE
// policy already covers unconditionally, same as every other field on
// this table. Deliberately NOT in scope: children_confirmed and
// children_billed. The SAD (WOWLAB_SAD_Domeniul_Operational_Groups_
// Sessions.md §4) flagged children_billed as possibly needing masking for
// Operations, "de decis la construcție" -- that decision was never made,
// only deferred, and is now recorded as its own open question
// (OPEN_ITEMS.md). Adding either field to this action ahead of that
// answer would settle the question by accident, the same way ValueCell's
// hardcoded visible=true already did on the read side. They stay
// read-only until Anca answers.
export async function updateGroup(
  groupId: string,
  notes: string,
  contractId: string,
): Promise<ActionResult> {
  const supabase = await createClient();

  const { data: current } = await supabase
    .from("groups")
    .select("id, client_id")
    .eq("id", groupId)
    .maybeSingle();

  if (!current) {
    return { ok: false, error: "Group not found, or not visible to your role." };
  }

  if (contractId) {
    const { data: contract } = await supabase
      .from("contracts")
      .select("id, client_id")
      .eq("id", contractId)
      .maybeSingle();
    if (!contract || contract.client_id !== current.client_id) {
      return { ok: false, error: "That contract does not belong to this group's client." };
    }
  }

  const { data, error } = await supabase
    .from("groups")
    .update({
      notes: notes.trim() || null,
      contract_id: contractId || null,
    })
    .eq("id", groupId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted (requires Operations Manager or Master).",
    };
  }

  revalidatePath(`/groups/${groupId}`);
  revalidatePath("/groups");
  return { ok: true, id: groupId };
}

export async function addSession(
  orgId: string,
  groupId: string,
  sessionDate: string,
  trainerPrincipalId: string,
  trainerSecundarId: string,
  status: string,
  attendanceCount: string,
  experimentDelivered: string,
  durationMinutes: string,
  experimentDriveLink: string,
): Promise<ActionResult> {
  if (!groupId || !sessionDate) {
    return { ok: false, error: "Session date is required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sessions")
    .insert({
      organization_id: orgId,
      group_id: groupId,
      session_date: sessionDate,
      trainer_principal_id: trainerPrincipalId || null,
      trainer_secundar_id: trainerSecundarId || null,
      status,
      attendance_count: attendanceCount.trim() ? Number(attendanceCount) : null,
      experiment_delivered: experimentDelivered.trim() || null,
      duration_minutes: durationMinutes.trim() ? Number(durationMinutes) : null,
      experiment_drive_link: experimentDriveLink.trim() || null,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create session." };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true, id: data.id };
}

// The "rotation" case (task spec): reallocating trainer_principal_id/
// trainer_secundar_id on an existing session. Deliberately scoped to only
// these two columns — status/attendance_count/experiment_delivered are not
// part of this inline-edit affordance (not asked for by the task spec).
// RLS blocks (rather than errors) an unauthorized UPDATE — it succeeds
// with 0 rows affected, not a thrown error, same shape as
// markContractSigned in app/(app)/contracts/actions.ts.
export async function updateSessionAllocation(
  groupId: string,
  sessionId: string,
  trainerPrincipalId: string,
  trainerSecundarId: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("sessions")
    .update({
      trainer_principal_id: trainerPrincipalId || null,
      trainer_secundar_id: trainerSecundarId || null,
    })
    .eq("id", sessionId)
    .select("id");

  if (error) {
    return { ok: false, error: error.message };
  }
  if (!data || data.length === 0) {
    return {
      ok: false,
      error: "Not permitted (requires Operations Manager or Master).",
    };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true };
}
