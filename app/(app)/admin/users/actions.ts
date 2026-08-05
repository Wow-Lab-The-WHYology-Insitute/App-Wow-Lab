"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { createServiceRoleClient } from "@/lib/supabase-admin";

export type ActionResult = { ok: true } | { ok: false; error: string };

const MEMBERS_MANAGE = "org.members.manage";

/**
 * Every admin action's FIRST step: check the caller's own session-scoped
 * capability using the normal anon-key + user-session client — exactly
 * like any other RLS-protected query. Nothing privileged happens before
 * this passes.
 */
async function assertCanManageOrg(
  orgId: string,
): Promise<{ actorUserId: string } | { error: string }> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { error: "Not signed in." };
  }

  const { data: allowed, error } = await supabase.rpc("has_capability", {
    cap: MEMBERS_MANAGE,
    org: orgId,
  });

  if (error || !allowed) {
    return { error: "You don't have permission to manage this organization." };
  }

  return { actorUserId: user.id };
}

async function writeAuditLog(params: {
  organizationId: string;
  actorUserId: string;
  eventType: string;
  targetId: string;
  payload: Record<string, unknown>;
}) {
  // SERVICE_ROLE — privileged, dev-review-required, only reached after the
  // capability check in assertCanManageOrg() above.
  const admin = createServiceRoleClient();
  await admin.from("audit_log").insert({
    organization_id: params.organizationId,
    actor_user_id: params.actorUserId,
    event_type: params.eventType,
    target_table: "users",
    target_id: params.targetId,
    payload: params.payload,
  });
}

export async function inviteUser(
  orgId: string,
  email: string,
  roleIds: string[],
): Promise<ActionResult> {
  const check = await assertCanManageOrg(orgId);
  if ("error" in check) return { ok: false, error: check.error };

  if (!email || roleIds.length === 0) {
    return { ok: false, error: "Email and at least one role are required." };
  }

  // SERVICE_ROLE — privileged, dev-review-required, only reached after the
  // capability check above. inviteUserByEmail creates the auth.users row;
  // public.handle_new_auth_user() (202607130004) creates the matching
  // public.users row synchronously via an AFTER INSERT trigger, so it
  // already exists by the time this call returns.
  const admin = createServiceRoleClient();
  const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
  });

  if (error || !data.user) {
    return { ok: false, error: error?.message ?? "Invite failed." };
  }

  const { error: rolesError } = await admin.from("user_org_roles").insert(
    roleIds.map((roleId) => ({
      organization_id: orgId,
      user_id: data.user!.id,
      role_id: roleId,
      assigned_by: check.actorUserId,
    })),
  );

  if (rolesError) {
    return { ok: false, error: rolesError.message };
  }

  await writeAuditLog({
    organizationId: orgId,
    actorUserId: check.actorUserId,
    eventType: "user.invited",
    targetId: data.user.id,
    payload: { email, roleIds },
  });

  revalidatePath("/admin/users");
  return { ok: true };
}

export async function editRoles(
  orgId: string,
  targetUserId: string,
  roleIds: string[],
): Promise<ActionResult> {
  const check = await assertCanManageOrg(orgId);
  if ("error" in check) return { ok: false, error: check.error };

  // SERVICE_ROLE — privileged, dev-review-required, only reached after the
  // capability check above. Delete-then-reinsert (rather than a diff) is
  // deliberate: user_org_roles is audited, so this produces a clean
  // DELETE + INSERT row_history trail showing exactly what changed.
  const admin = createServiceRoleClient();

  const { error: deleteError } = await admin
    .from("user_org_roles")
    .delete()
    .eq("organization_id", orgId)
    .eq("user_id", targetUserId);

  if (deleteError) {
    return { ok: false, error: deleteError.message };
  }

  if (roleIds.length > 0) {
    const { error: insertError } = await admin.from("user_org_roles").insert(
      roleIds.map((roleId) => ({
        organization_id: orgId,
        user_id: targetUserId,
        role_id: roleId,
        assigned_by: check.actorUserId,
      })),
    );

    if (insertError) {
      return { ok: false, error: insertError.message };
    }
  }

  await writeAuditLog({
    organizationId: orgId,
    actorUserId: check.actorUserId,
    eventType: "user.roles_updated",
    targetId: targetUserId,
    payload: { roleIds },
  });

  revalidatePath("/admin/users");
  return { ok: true };
}

export async function disableAccess(
  orgId: string,
  targetUserId: string,
): Promise<ActionResult> {
  const check = await assertCanManageOrg(orgId);
  if ("error" in check) return { ok: false, error: check.error };

  // SERVICE_ROLE — privileged, dev-review-required, only reached after the
  // capability check above.
  //
  // Honest note on "force sign-out of any active session": the admin API's
  // signOut(jwt, scope) takes a session's JWT, not a user id — there is no
  // "kill this user id's sessions" method in this SDK. ban_duration ('none'
  // to lift, per the SDK's own type) blocks new logins/token refreshes
  // immediately. For an ALREADY-issued access token, our middleware uses
  // supabase.auth.getUser() rather than getSession() specifically because
  // getUser() revalidates against the Auth server on every request — so a
  // banned user's very next request (anywhere in this app) is rejected,
  // rather than waiting out the JWT's own expiry. That is the actual
  // enforcement mechanism here.
  const admin = createServiceRoleClient();
  const { error: banError } = await admin.auth.admin.updateUserById(
    targetUserId,
    { ban_duration: "876000h" }, // ~100 years — the SDK's own documented convention for an effectively permanent ban
  );

  if (banError) {
    return { ok: false, error: banError.message };
  }

  const { error: statusError } = await admin
    .from("users")
    .update({ status: "disabled" })
    .eq("id", targetUserId);

  if (statusError) {
    return { ok: false, error: statusError.message };
  }

  await writeAuditLog({
    organizationId: orgId,
    actorUserId: check.actorUserId,
    eventType: "user.disabled",
    targetId: targetUserId,
    payload: {},
  });

  revalidatePath("/admin/users");
  return { ok: true };
}

export async function enableAccess(
  orgId: string,
  targetUserId: string,
): Promise<ActionResult> {
  const check = await assertCanManageOrg(orgId);
  if ("error" in check) return { ok: false, error: check.error };

  // SERVICE_ROLE — privileged, dev-review-required, only reached after the
  // capability check above. Deliberately does NOT touch user_org_roles —
  // re-enabling lifts the ban only; roles must be explicitly re-assigned,
  // so stale permissions are never silently reinstated.
  const admin = createServiceRoleClient();
  const { error: unbanError } = await admin.auth.admin.updateUserById(
    targetUserId,
    { ban_duration: "none" },
  );

  if (unbanError) {
    return { ok: false, error: unbanError.message };
  }

  const { error: statusError } = await admin
    .from("users")
    .update({ status: "active" })
    .eq("id", targetUserId);

  if (statusError) {
    return { ok: false, error: statusError.message };
  }

  await writeAuditLog({
    organizationId: orgId,
    actorUserId: check.actorUserId,
    eventType: "user.enabled",
    targetId: targetUserId,
    payload: {},
  });

  revalidatePath("/admin/users");
  return { ok: true };
}
