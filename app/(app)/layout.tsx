import Image from "next/image";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { NavLink } from "./nav-link";
import { SignOutButton } from "./sign-out-button";

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

  return (
    <div className="flex min-h-screen">
      <aside className="bg-sidebar sticky top-0 flex h-screen w-60 flex-shrink-0 flex-col">
        <div className="flex items-center gap-2 p-6">
          <Image
            src="/logo-wowlab.png"
            alt=""
            width={28}
            height={28}
            className="h-7 w-auto"
          />
          <span className="font-display bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] bg-clip-text text-lg leading-none text-transparent">
            WOW LAB OS
          </span>
        </div>
        <nav className="flex flex-col gap-1 px-3">
          <NavLink href="/whoami" label="Dashboard" />
          {canManageUsers && <NavLink href="/admin/users" label="Users & Roles" />}
        </nav>
      </aside>

      <div className="bg-ink/[0.03] flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-black/5 bg-white px-8 py-4">
          <div className="font-body text-sm">
            <span className="text-ink font-semibold">{user.email}</span>
            {roleLabel && <span className="text-muted ml-2">· {roleLabel}</span>}
          </div>
          <SignOutButton />
        </header>
        <main className="flex-1 p-8">{children}</main>
      </div>
    </div>
  );
}
