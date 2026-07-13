import { createClient } from "@/lib/supabase/server";
import { AdminUsersClient } from "./admin-users-client";

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
    return <AccessDenied reason="Not signed in." />;
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
    const { data: allowed } = await supabase.rpc("has_capability", {
      cap: "org.members.manage",
      org: m.organization_id,
    });
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
    return (
      <AccessDenied reason="You don't have org.members.manage in any organization." />
    );
  }

  const { data: roles } = await supabase
    .from("roles")
    .select("id, key, display_name")
    .order("display_name");

  const { data: memberRows } = await supabase
    .from("user_org_roles")
    .select("user_id, role_id, users(email, status), roles(id, key, display_name)")
    .eq("organization_id", managedOrg.id);

  const membersByUser = new Map<
    string,
    {
      userId: string;
      email: string;
      status: string;
      roleIds: string[];
      roleLabels: string[];
    }
  >();

  for (const row of memberRows ?? []) {
    const u = row.users as unknown as { email: string; status: string } | null;
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
        status: u.status,
        roleIds: [r.id],
        roleLabels: [r.display_name],
      });
    }
  }

  return (
    <main className="mx-auto max-w-3xl p-8">
      <h1 className="mb-1 text-xl font-semibold">Users &amp; roles</h1>
      <p className="mb-6 text-sm text-gray-600">
        Organization: {managedOrg.name} ({managedOrg.slug})
      </p>
      <AdminUsersClient
        orgId={managedOrg.id}
        roles={roles ?? []}
        members={Array.from(membersByUser.values())}
      />
    </main>
  );
}

function AccessDenied({ reason }: { reason: string }) {
  return (
    <main className="mx-auto max-w-md p-8">
      <h1 className="text-lg font-semibold">Access denied</h1>
      <p className="text-sm text-gray-600">{reason}</p>
    </main>
  );
}
