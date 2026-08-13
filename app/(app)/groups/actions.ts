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
): Promise<ActionResult> {
  if (!clientId || !module || !deliveryFormat) {
    return { ok: false, error: "Client, module, and delivery format are required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("groups")
    .insert({
      organization_id: orgId,
      client_id: clientId,
      module,
      delivery_format: deliveryFormat,
      schedule_pattern: schedulePattern.trim() || null,
      status,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create group." };
  }

  revalidatePath("/groups");
  return { ok: true, id: data.id };
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
