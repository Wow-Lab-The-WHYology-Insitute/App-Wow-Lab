import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { AdminUsersClient } from "./admin-users-client";
import { AdminUsersHeader } from "./admin-users-header";
import { AccessDenied } from "@/components/ui/access-denied";

type OrgMembership = {
  organization_id: string;
  organizations: { name: string; slug: string } | null;
};

export default async function AdminUsersPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  // Find an org this user belongs to where they hold org.members.manage.
  // S1 scope: single-org admin view (see report / code comments for the
  // platform_owner caveat — this screen isn't built for cross-org browsing).
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id, organizations(name, slug)")
    .eq("user_id", user.id)
    .returns<OrgMembership[]>();

  let managedOrg: { id: string; name: string; slug: string } | null = null;

  for (const m of memberships ?? []) {
    const allowed = await checkCapability(supabase, "org.members.manage", m.organization_id);
    if (allowed && m.organizations) {
      managedOrg = {
        id: m.organization_id,
        name: m.organizations.name,
        slug: m.organizations.slug,
      };
      break;
    }
  }

  if (!managedOrg) {
    return <AccessDenied reasonKey="access_denied_no_capability" />;
  }

  const { data: roles } = await supabase
    .from("roles")
    .select("id, key, display_name")
    .order("display_name");

  // Disambiguated embed: user_org_roles has two FKs to users (user_id and
  // assigned_by), so a bare `users_masked(...)` embed is ambiguous and
  // PostgREST rejects it (PGRST201). user_id (not assigned_by) is the
  // correct target: this maps by row.user_id below, and email/status must
  // describe that same member, not whoever assigned them the role.
  //
  // Embeds through users_masked (202608200005): confirmed live, not
  // assumed, that PostgREST resolves this FK-based embed through the view
  // exactly as it does through the base table — the join column (id) is a
  // direct, untransformed passthrough of users.id, so PostgREST's view
  // lineage tracing still finds the user_org_roles_user_id_fkey
  // relationship even though email/phone themselves are function-derived.
  // Every row here is already scoped to managedOrg, the same org the
  // caller holds org.members.manage in, so the view's predicate resolves
  // true for every member and email/phone come through unmasked — same
  // effective result as reading the base table, verified by direct REST
  // calls against both before this change was made. Grants stay unchanged
  // this step (SAD §2.3 step 3 flips them later).
  const { data: memberRows } = await supabase
    .from("user_org_roles")
    .select(
      "user_id, role_id, users_masked!user_org_roles_user_id_fkey(email, full_name, status, first_name, last_name, avatar_url, is_test_account), roles(id, key, display_name)",
    )
    .eq("organization_id", managedOrg.id);

  const membersByUser = new Map<
    string,
    {
      userId: string;
      email: string;
      fullName: string | null;
      status: string;
      roleIds: string[];
      roleLabels: string[];
      firstName: string | null;
      lastName: string | null;
      avatarPath: string | null;
      isTestAccount: boolean;
    }
  >();

  for (const row of memberRows ?? []) {
    const u = row.users_masked as unknown as {
      email: string;
      full_name: string | null;
      status: string;
      first_name: string | null;
      last_name: string | null;
      avatar_url: string | null;
      is_test_account: boolean;
    } | null;
    const r = row.roles as unknown as {
      id: string;
      key: string;
      display_name: string;
    } | null;
    if (!u || !r) continue;

    const existing = membersByUser.get(row.user_id);
    if (existing) {
      existing.roleIds.push(r.id);
      existing.roleLabels.push(r.display_name);
    } else {
      membersByUser.set(row.user_id, {
        userId: row.user_id,
        email: u.email,
        fullName: u.full_name,
        status: u.status,
        roleIds: [r.id],
        roleLabels: [r.display_name],
        firstName: u.first_name,
        lastName: u.last_name,
        avatarPath: u.avatar_url,
        isTestAccount: u.is_test_account,
      });
    }
  }

  // avatar_url on public.users is a Storage PATH in the private `avatars`
  // bucket, never a public URL — resolved to short-lived signed URLs here,
  // through this session's own client, so the "authenticated org members
  // can read any avatar" access model (storage.objects RLS, 202608120001)
  // is what actually gates this, not a service_role bypass. Batched via
  // createSignedUrls (one request) rather than one createSignedUrl call
  // per member.
  const rawMembers = Array.from(membersByUser.values());
  const avatarPaths = rawMembers
    .map((m) => m.avatarPath)
    .filter((p): p is string => Boolean(p));
  const signedUrlByPath = new Map<string, string>();
  if (avatarPaths.length > 0) {
    const { data: signed } = await supabase.storage
      .from("avatars")
      .createSignedUrls(avatarPaths, 3600);
    for (const s of signed ?? []) {
      if (s.path && s.signedUrl) signedUrlByPath.set(s.path, s.signedUrl);
    }
  }

  const members = rawMembers.map(({ avatarPath, ...m }) => ({
    ...m,
    avatarUrl: avatarPath ? (signedUrlByPath.get(avatarPath) ?? null) : null,
  }));

  return (
    <div className="flex w-full flex-col gap-6">
      <AdminUsersHeader orgName={managedOrg.name} orgSlug={managedOrg.slug} />
      <AdminUsersClient
        orgId={managedOrg.id}
        roles={roles ?? []}
        members={members}
      />
    </div>
  );
}

