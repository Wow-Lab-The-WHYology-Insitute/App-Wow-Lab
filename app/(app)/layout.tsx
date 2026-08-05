import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ShellChrome } from "./shell-chrome";

type MembershipRow = {
  organization_id: string;
  roles: { display_name: string } | null;
};

// S3 brand shell for every authenticated page. Nav items are additive by
// design: each entry below is just an href/label pair gated by whatever
// capability check it needs — add a new one when its screen actually
// ships, don't pre-list Phase 1 screens that don't exist yet.
export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    // Belt-and-suspenders — middleware already redirects unauthenticated
    // requests before this layout ever renders.
    redirect("/login");
  }

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id, roles(display_name)")
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  const roleLabel = [
    ...new Set((memberships ?? []).map((m) => m.roles?.display_name).filter(Boolean)),
  ].join(", ");

  // Same has_capability RPC loop app/(app)/admin/users/page.tsx uses to
  // decide access server-side — reused here (not hardcoded) purely to
  // decide whether the nav item is worth showing at all.
  let canManageUsers = false;
  for (const m of memberships ?? []) {
    const { data: allowed } = await supabase.rpc("has_capability", {
      cap: "org.members.manage",
      org: m.organization_id,
    });
    if (allowed) {
      canManageUsers = true;
      break;
    }
  }

  const navItems = [
    { href: "/whoami", label: "Dashboard" },
    ...(canManageUsers ? [{ href: "/admin/users", label: "Users & Roles" }] : []),
  ];

  return (
    <ShellChrome
      navItems={navItems}
      userEmail={user.email ?? ""}
      roleLabel={roleLabel}
    >
      {children}
    </ShellChrome>
  );
}
