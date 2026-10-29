"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import {
  SESSION_CONFIRMATION_FUTURE_ERROR,
  SESSION_CONFIRMATION_MONTH_CLOSED_ERROR,
  SESSION_ATTENDANCE_MONTH_CLOSED_ERROR,
  SESSION_ATTENDANCE_FUTURE_ERROR,
  SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR,
} from "./session-write-errors";

export type ActionResult =
  | { ok: true; id: string; firstWorkshopCreated?: boolean }
  | { ok: false; error: string };

export type VoidActionResult = { ok: true } | { ok: false; error: string };

// VOCABULARY, since this file says "workshop" to users and "sessions" to the
// database in the same function. The interface was renamed 2026-10-12 (item
// 120): RO atelier, EN workshop -- the words Anca and the trainers actually
// use, and already the majority in both dictionaries before the rename.
// public.sessions and everything keyed on it deliberately did NOT move: its
// own RLS policies, four SECURITY DEFINER routing functions, row_history rows
// already written under that table_name, app.calculate_session_pay and its
// five resolvers, and 13 suite files all name it. A rename buys vocabulary
// consistency and costs a migration touching every one of them, plus history
// rows that would then disagree with the table they describe.

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
  languageGroup: string,
  // Opt-in, never silent. Defaulted ON by the form for the nine one-off
  // formats (where schedulePattern IS a date) and OFF for
  // scoli_private_recurente (where it is a weekly rhythm with no date in it).
  createFirstWorkshop: boolean = false,
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
      // Group-level, not session-level (202609240003) -- entered once
      // here, never per session.
      language_group: languageGroup || null,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create group." };
  }

  // ---- The first workshop, if asked for (item 119) ----
  // ONE workshop, never a series. A recurring club runs ~30 a year and
  // generating those needs term dates, a holiday calendar and an end date,
  // none of which exist here -- that is a scheduling feature nobody has
  // specified. Generating the first one turns a field that produced nothing
  // into a head start.
  //
  // Parsed, not trusted: schedulePattern is free text with no enforced
  // grammar, and for a recurring group it holds "Tuesday 16:00", which has no
  // date in it at all. If the leading token is not an ISO date this creates
  // nothing and says so, rather than inventing "the next Tuesday" -- which
  // would be a guess about when term starts.
  let firstWorkshopCreated = false;
  if (createFirstWorkshop) {
    const trimmed = schedulePattern.trim();
    const match = /^(\d{4}-\d{2}-\d{2})(?:\s+(\d{2}:\d{2}))?$/.exec(trimmed);
    if (match) {
      const { error: sessionError } = await supabase.from("sessions").insert({
        organization_id: orgId,
        group_id: data.id,
        session_date: match[1],
        start_time: match[2] ?? null,
        status: "planned",
        // Everything else stays null on purpose. duration_minutes and
        // location_tier are what the pay calculation needs and are NOT known
        // at scheduling time -- location depends on which trainer is
        // assigned, and nobody is assigned yet. /payroll's pre-close check
        // (item 121) is where their absence surfaces, not here.
      });
      // A group that exists without its first workshop is a recoverable state
      // (add the workshop by hand); a failed group creation is not. So this
      // failure is reported through the flag, never by discarding the group.
      firstWorkshopCreated = !sessionError;
    }
  }

  revalidatePath("/groups");
  revalidatePath(`/groups/${data.id}`);
  return { ok: true, id: data.id, firstWorkshopCreated };
}

// Same relationship as updateContract/updateClient: runs through the
// caller's own session client, so the "authenticated update groups" RLS
// policy (202608130003, extended 202609110002 with a contracts.* branch)
// is the real authority; this action's own checks are a second, explicit
// line so the caller gets a real reason rather than a mystery no-op.
//
// notes/contract_id: in scope for groups.create holders (Operations
// Manager + Master), unchanged. children_confirmed: in scope for
// contracts.* holders (contract_administrator -- Laura, Anka) as of
// Anca's 2026-09-11 decision, and for them specifically -- Cătălina
// (operations_manager) sees the count but does not fill it. RLS
// restricts rows, not columns, so this is the real boundary: each field
// is only ever added to the UPDATE payload when its own capability check
// passes, matching updateContract's pattern for its finance fields
// (omit from the payload when the check fails, rather than sending it
// and leaning on RLS to reject the whole row). This also protects a
// contracts.*-only caller's notes/contract_id from being silently reset
// to empty by a form that never shows those fields to them -- both are
// left out of the payload entirely for that caller, not sent as blanks.
//
// children_billed stays out of scope, unchanged. The SAD (WOWLAB_SAD_
// Domeniul_Operational_Groups_Sessions.md §4) flagged it as possibly
// needing masking for Operations, "de decis la construcție" -- that
// decision was never made, only deferred, and is recorded as its own
// open question (OPEN_ITEMS.md). Adding it here ahead of that answer
// would settle the question by accident, the same way ValueCell's
// hardcoded visible=true already did on the read side. Stays read-only
// until Anca answers that one too.
export async function updateGroup(
  groupId: string,
  notes: string,
  contractId: string,
  childrenConfirmed: string,
  address: string,
  onSiteContactId: string,
  languageGroup: string,
  // Added 2026-10-12 (item 119). It was writable at the database level all
  // along -- authenticated has had UPDATE on this column since the table was
  // created -- and simply had no control anywhere after creation, so a
  // mistyped schedule could not be corrected without direct SQL.
  schedulePattern: string = "",
): Promise<ActionResult> {
  const supabase = await createClient();

  const { data: current } = await supabase
    .from("groups")
    .select("id, client_id, organization_id")
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

  // Same re-check as contractId above, same reasoning: constrained to
  // this client's own contacts, not trusted from the form's own
  // client-side filtering (item 52's on-site-contact design record) --
  // a raw FK to client_contacts(id) alone can't express "belongs to the
  // same client as this group."
  if (onSiteContactId) {
    const { data: contact } = await supabase
      .from("client_contacts")
      .select("id, client_id")
      .eq("id", onSiteContactId)
      .maybeSingle();
    if (!contact || contact.client_id !== current.client_id) {
      return { ok: false, error: "That contact does not belong to this group's client." };
    }
  }

  const [isOwner, hasGroupsCreate, hasContractsStar] = await Promise.all([
    checkCapability(supabase, "org.settings.manage", current.organization_id),
    checkCapability(supabase, "groups.create", current.organization_id),
    checkCapability(supabase, "contracts.*", current.organization_id),
  ]);
  const canManageGroupFields = isOwner || hasGroupsCreate;
  const canWriteChildrenConfirmed = isOwner || hasContractsStar;

  if (!canManageGroupFields && !canWriteChildrenConfirmed) {
    return {
      ok: false,
      error: "Not permitted (requires Operations Manager, Master, or a contract administrator).",
    };
  }

  // notes/contract_id/address/on_site_contact_id/language_group:
  // unaffected by item 91 -- still a direct .update(), still RLS-gated
  // exactly as before (language_group's own column-level grant added
  // alongside it, 202609240003). Only children_confirmed moved, below.
  if (canManageGroupFields) {
    const { error } = await supabase
      .from("groups")
      .update({
        notes: notes.trim() || null,
        contract_id: contractId || null,
        address: address.trim() || null,
        on_site_contact_id: onSiteContactId || null,
        language_group: languageGroup || null,
        schedule_pattern: schedulePattern.trim() || null,
      })
      .eq("id", groupId);

    if (error) {
      return { ok: false, error: error.message };
    }
  }

  // children_confirmed: routed through app.rpc_set_group_children_confirmed
  // (item 91, 2026-09-22) -- authenticated's column-level UPDATE grant on
  // this column is revoked; a contracts.* holder (or owner) is now the
  // only writer, via the function's own re-check, matching Anca's
  // 2026-09-11 decision this action already encoded (operations_manager
  // sees the count but does not fill it). Splits what used to be one
  // atomic UPDATE into two separate writes when both fields change at
  // once -- a failure between them is recoverable (re-save), not silently
  // lost, but no longer perfectly atomic.
  if (canWriteChildrenConfirmed) {
    const { data: rpcResult, error: rpcError } = await supabase.rpc("rpc_set_group_children_confirmed", {
      p_group_id: groupId,
      p_children_confirmed: childrenConfirmed.trim() ? Number(childrenConfirmed) : null,
    });
    if (rpcError) {
      return { ok: false, error: rpcError.message };
    }
    if (rpcResult !== "ok") {
      return {
        ok: false,
        error: "Not permitted (requires Operations Manager, Master, or a contract administrator).",
      };
    }
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
  startTime: string,
  locationTier: string,
): Promise<ActionResult> {
  if (!groupId || !sessionDate) {
    return { ok: false, error: "Workshop date is required." };
  }

  // Found 2026-10-28 alongside the identical gap on rpc_update_session_attendance
  // (202610280001): this insert is the OTHER place attendance_count/
  // experiment_delivered can be written, and nothing here checked the date
  // either. NewSessionForm's own attendance/experiment fields exist for
  // logging a one-off workshop that already happened and was never entered
  // until after the fact -- not for a workshop scheduled ahead. Same
  // sentinel, same message, same principle as that RPC's guard; this path
  // just isn't routed through an RPC (item 91 only revoked UPDATE, not
  // INSERT), so the check has to live here instead of in the database.
  const todayIso = new Date().toISOString().slice(0, 10);
  if (sessionDate > todayIso && (attendanceCount.trim() || experimentDelivered.trim())) {
    return { ok: false, error: SESSION_ATTENDANCE_FUTURE_ERROR };
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
      // No end time stored alongside this -- derived at read time from
      // start_time + duration_minutes when both exist, never both stored
      // (item 52's time-range design: same precedent as contract expiry
      // and children_billed). Not defaulted from groups.schedule_pattern
      // -- free text, no enforced grammar, nothing here parses it.
      start_time: startTime || null,
      // Entered, never derived (item 95/96 report: the school side has
      // only free-text addresses, and travel depends on who's assigned,
      // not the school alone) -- the form pre-fills a suggestion from the
      // assigned trainer's home city, but this action trusts whatever
      // value actually arrives, pre-filled-then-confirmed or manually
      // chosen, same as every other field here.
      location_tier: locationTier || null,
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create workshop." };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true, id: data.id };
}

// The "rotation" case (task spec): reallocating trainer_principal_id/
// trainer_secundar_id on an existing session. Deliberately scoped to only
// these two columns — status/attendance_count/experiment_delivered are not
// part of this inline-edit affordance (not asked for by the task spec).
//
// Routed through app.rpc_update_session_allocation (item 91, 2026-09-22):
// authenticated no longer has table-level UPDATE on sessions at all --
// confirmed live that a raw PATCH to /rest/v1/sessions bypassed this
// action's own column narrowing entirely (a trainer could write their
// CO-trainer's confirmation timestamp directly, the pay-triggering
// field). The RPC function re-checks org.settings.manage/sessions.create
// itself (SECURITY DEFINER, bypasses RLS by construction) -- this action
// no longer relies on RLS's row admission alone the way it used to.
export async function updateSessionAllocation(
  groupId: string,
  sessionId: string,
  trainerPrincipalId: string,
  trainerSecundarId: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_update_session_allocation", {
    p_session_id: sessionId,
    p_trainer_principal_id: trainerPrincipalId || null,
    p_trainer_secundar_id: trainerSecundarId || null,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data !== "ok") {
    return {
      ok: false,
      error: "Not permitted (requires Operations Manager or Master).",
    };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true };
}

// The assigned trainer recording their own session (Anca's decision,
// 2026-09-11): attendance_count and experiment_delivered, on a session
// where the caller is trainer_principal_id or trainer_secundar_id.
// Row-matched via RLS alone (202609110003) -- no capability check here,
// matching updateSessionAllocation's own reasoning: the real gate is
// the row match, this action's job is narrowing the columns a matched
// caller can reach, not re-checking who they are a second time. Scoped
// to exactly these two fields -- not trainer_principal_id/
// trainer_secundar_id, not status. RLS's WITH CHECK would technically
// still allow a matched trainer to touch other columns on their own row
// via a raw request; this action is what actually stops it, the same
// division of labor as every other capability-gated action in this
// codebase (RLS restricts rows, the action restricts columns).
//
// experiment_delivered stays free text -- the experiment catalogue does
// not exist (docs/OPEN_ITEMS.md item 45 part 3, item 52) and this is not
// building toward one; a trainer types what they ran, same as Operations
// already could at session creation.
// Pre-checked the same way confirmSessionAttendance is (added per the
// payroll walkthrough finding that this action's own error collapsed two
// different causes -- "not your session" and "your month is closed" --
// into one message that named only the first, even when the second was
// what actually happened. RLS's row match (202609110004) can't tell them
// apart either -- both fail as the identical silent zero-rows -- so the
// distinction has to be made here, before the write, same as confirm's.
// Routed through app.rpc_update_session_attendance (item 91, 2026-09-22)
// -- authenticated no longer has table-level UPDATE on sessions.
// Everything this action used to pre-check (signed in, row match, month
// open) is re-checked INSIDE the SECURITY DEFINER function itself now --
// this action's own pre-checks below are kept anyway, not because the
// function needs them, but so the specific error messages
// (SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR / SESSION_ATTENDANCE_MONTH_
// CLOSED_ERROR) stay exact rather than collapsing into one generic
// "not permitted" -- the function's own return code is what actually
// gates the write regardless of what this action concluded first.
export async function updateSessionAttendance(
  groupId: string,
  sessionId: string,
  attendanceCount: string,
  experimentDelivered: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: "Not signed in." };
  }

  const { data, error } = await supabase.rpc("rpc_update_session_attendance", {
    p_session_id: sessionId,
    p_attendance_count: attendanceCount.trim() ? Number(attendanceCount) : null,
    p_experiment_delivered: experimentDelivered.trim() || null,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "Workshop not found, or not visible to your role." };
  }
  if (data === "not_assigned") {
    return { ok: false, error: SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR };
  }
  if (data === "month_closed") {
    return { ok: false, error: SESSION_ATTENDANCE_MONTH_CLOSED_ERROR };
  }
  if (data === "future_session") {
    return { ok: false, error: SESSION_ATTENDANCE_FUTURE_ERROR };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true };
}

// The trainer's own confirmation (Anca's decision, 2026-09-12): pay
// follows this timestamp, not attendance_count or status. Row-matched
// via RLS (202609150002's trainer branch), which now also requires the
// session's own month to be open -- "a trainer cannot modify anything
// afterwards" is unqualified, so the same branch attendance_count/
// experiment_delivered already go through was extended, not copied.
//
// Column narrowing: RLS's row match admits BOTH trainer_principal_id and
// trainer_secundar_id equally -- a principal and a secundar on the same
// session match the identical branch, and neither USING nor WITH CHECK
// can tell which of the two columns a raw UPDATE touches (confirmed live,
// scripts/verify_sessions_confirmation_write.sql assertion 2). This
// action is what actually stops a principal from writing the secundar's
// timestamp and vice versa: it reads the session first, compares the
// caller's own id against both slots, and includes exactly one of the
// two column keys in the UPDATE payload -- never both, never the wrong
// one.
//
// The same pre-read is also why this can return a real error instead of
// RLS's identical silent zero-rows for two different causes: "not your
// session" (checked here, before ever attempting the write) and "your
// month is closed" (checked via payroll_periods, which mywork.* holders
// can read for exactly this reason -- 202609150001).
// Routed through app.rpc_confirm_session_attendance (item 91, 2026-09-22)
// -- the exact write a live test confirmed bypassable via raw PostgREST
// PATCH on 2026-09-22 (a principal setting trainer_secundar_confirmed_at
// directly, with authenticated holding an unrestricted table-level
// UPDATE grant on sessions). Which column gets written is now resolved
// INSIDE the SECURITY DEFINER function, from the row + the caller's own
// id -- there is no column parameter here at all, so this action (or any
// other caller of the RPC) has no way to even ASK for the other
// trainer's slot, let alone be trusted not to.
export async function confirmSessionAttendance(
  groupId: string,
  sessionId: string,
  confirmed: boolean,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: "Not signed in." };
  }

  const { data, error } = await supabase.rpc("rpc_confirm_session_attendance", {
    p_session_id: sessionId,
    p_confirmed: confirmed,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "Workshop not found, or not visible to your role." };
  }
  if (data === "not_assigned") {
    return { ok: false, error: SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR };
  }
  if (data === "month_closed") {
    return { ok: false, error: SESSION_CONFIRMATION_MONTH_CLOSED_ERROR };
  }
  // 202610220001: setting a confirmation on a workshop that has not happened.
  // Only ever returned for confirmed === true -- clearing is never guarded.
  if (data === "future_session") {
    return { ok: false, error: SESSION_CONFIRMATION_FUTURE_ERROR };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true };
}

// Anka's correction path (Anca's decision, 2026-09-12): either
// timestamp, before or after close. Gated explicitly on
// finance.operations.* here, checked in this action rather than left to
// RLS's unconditional finance.operations.* branch (202609150002) alone
// -- this action's whole point is to be the deliberate, capability-
// gated correction path, not a row-matched one, so it should say "not
// permitted" for the right reason rather than rely on a silent
// zero-rows-affected it never even attempts to explain.
//
// finance.operations.* is the same capability identified for
// payroll_periods (app/(app)/payroll/actions.ts) -- "the person who
// closes payroll" and "the person who corrects a trainer's
// confirmation" are the same role by Anca's own framing ("Corrections
// are normally Laura's role, currently covered by Anka"), not
// contracts.*, which both happen to hold too for an unrelated reason.
//
// Writes both columns every call, to whatever state the caller passes
// for each -- there is no row match to fall back on here, so unlike
// confirmSessionAttendance this is not scoped to "one slot only."
// Routed through app.rpc_correct_session_confirmation (item 91,
// 2026-09-22) -- authenticated no longer has table-level UPDATE on
// sessions. Before this, RLS's unconditional finance.operations.* branch
// admitted a finance.operations.* holder to write ANY column on ANY
// session via a raw request (attendance_count, status, trainer
// assignment), not just the two confirmation columns this action ever
// exposed -- the function now re-checks the capability itself and writes
// only those two, closing that gap too.
export async function correctSessionConfirmation(
  groupId: string,
  sessionId: string,
  principalConfirmed: boolean,
  secundarConfirmed: boolean,
): Promise<VoidActionResult> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc("rpc_correct_session_confirmation", {
    p_session_id: sessionId,
    p_principal_confirmed: principalConfirmed,
    p_secundar_confirmed: secundarConfirmed,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "Workshop not found, or not visible to your role." };
  }
  if (data === "not_permitted") {
    return { ok: false, error: "Not permitted (requires finance.operations.*)." };
  }
  // 202610220001 guards Operations too, and the reason it is not an exception
  // for them is in that migration's header: a correction says the record is
  // wrong, and there is no record yet about a workshop that has not happened.
  // Evaluated per column there, so CLEARING a wrongly-set future confirmation
  // still returns ok.
  if (data === "future_session") {
    return { ok: false, error: SESSION_CONFIRMATION_FUTURE_ERROR };
  }

  revalidatePath(`/groups/${groupId}`);
  return { ok: true };
}

// ============================================================================
// Lesson-plan proposal and validation (item 117, Anca 2026-10-12).
// ============================================================================
// All three thin, for the same reason updateSessionAttendance is thin: the
// SECURITY DEFINER function underneath re-checks everything (row match,
// capability, organization, state) and its return code is what actually gates
// the write. These translate the code into a message a person can act on.
//
// No capability pre-check in any of them. updateGroup and updateContract do
// pre-check, to give a specific reason instead of a mystery no-op -- but those
// write through RLS, where a refusal IS a silent zero-rows. Here the function
// returns 'not_permitted' / 'not_assigned' explicitly, so a second check in
// front of it would only add a way for the two to disagree.

export async function proposeSessionLessonPlan(
  groupId: string,
  sessionId: string,
  lessonPlanId: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_propose_session_lesson_plan", {
    p_session_id: sessionId,
    p_lesson_plan_id: lessonPlanId,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "Workshop not found, or not visible to your role." };
  }
  if (data === "not_assigned") {
    return { ok: false, error: SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR };
  }
  if (data === "plan_not_found") {
    return { ok: false, error: "That lesson plan is not in this organization's catalogue." };
  }
  if (data !== "ok") {
    return { ok: false, error: `Unexpected result from rpc_propose_session_lesson_plan: ${data}` };
  }

  revalidatePath(`/groups/${groupId}`);
  // The trainer's own screen shows the same row, so it has to drop its cached
  // copy too -- a proposal made here appears there, and a verdict made here
  // appears there as a notification.
  revalidatePath("/my-work");
  return { ok: true };
}

export async function decideSessionLessonPlan(
  groupId: string,
  rowId: string,
  status: "validated" | "changes_requested",
  note: string,
): Promise<VoidActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_decide_session_lesson_plan", {
    p_row_id: rowId,
    p_status: status,
    p_note: note.trim() || null,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "That proposal no longer exists." };
  }
  if (data === "not_permitted") {
    return { ok: false, error: "Not permitted (requires curriculum.validate)." };
  }
  if (data === "note_required") {
    return { ok: false, error: "Say what needs changing — a request for changes needs a note." };
  }
  if (data === "invalid_status") {
    return { ok: false, error: `Not a decision: ${status}.` };
  }
  if (data !== "ok") {
    return { ok: false, error: `Unexpected result from rpc_decide_session_lesson_plan: ${data}` };
  }

  revalidatePath(`/groups/${groupId}`);
  revalidatePath("/my-work");
  return { ok: true };
}

export async function markSessionLessonPlanSeen(rowId: string): Promise<VoidActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("rpc_mark_session_lesson_plan_seen", {
    p_row_id: rowId,
  });

  if (error) {
    return { ok: false, error: error.message };
  }
  if (data === "not_found") {
    return { ok: false, error: "That proposal no longer exists." };
  }
  if (data === "not_yours") {
    return { ok: false, error: "That is not your proposal." };
  }
  if (data === "nothing_to_see") {
    return { ok: false, error: "That proposal has not been decided yet." };
  }
  if (data !== "ok") {
    return { ok: false, error: `Unexpected result from rpc_mark_session_lesson_plan_seen: ${data}` };
  }

  revalidatePath("/my-work");
  return { ok: true };
}
