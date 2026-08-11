import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ShellChrome } from "./shell-chrome";

type MembershipRow = {
  organization_id: string;
  roles: { display_name: string } | null;
};

// Wraps every has_capability RPC call used for nav-gating below. On error
// (not "capability denied", an actual failed request) this still defaults
// to false — hiding the nav item stays the correct fail-closed default,
// since real access is enforced by RLS regardless of what the nav shows,
// so failing open here would just be misleading, not safer. What this
// adds: one immediate retry (no backoff needed, this is a single fast RPC
// call) as cheap insurance against a one-off transient hiccup, and an
// explicit console.error if it fails twice — so a repeat of this isn't
// silent next time, it leaves a trace in Vercel's function logs keyed on
// the exact capability/org that failed.
async function checkCapability(
  supabase: Awaited<ReturnType<typeof createClient>>,
  cap: string,
  org: string,
): Promise<boolean> {
  let lastError: unknown = null;
  for (let attempt = 1; attempt <= 2; attempt++) {
    const { data, error } = await supabase.rpc("has_capability", { cap, org });
    if (!error) return Boolean(data);
    lastError = error;
  }
  console.error(
    `has_capability RPC failed twice (cap=${cap}, org=${org}) — defaulting to false (nav item hidden; RLS remains the real access control regardless of this UI gate):`,
    lastError,
  );
  return false;
}

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
    if (await checkCapability(supabase, "org.members.manage", m.organization_id)) {
      canManageUsers = true;
      break;
    }
  }

  // Clients & Contracts (C2): each item gated independently on its own
  // capability (clients.read / contracts.read), not "both or nothing" — a
  // future role could plausibly hold only one. In the current C1 seed
  // every role that has either capability has both, so this can't be
  // demonstrated split with today's fixtures, but the check stays
  // independent since that's the correct model going forward.
  let canReadClients = false;
  let canReadContracts = false;
  for (const m of memberships ?? []) {
    if (!canReadClients && (await checkCapability(supabase, "clients.read", m.organization_id))) {
      canReadClients = true;
    }
    if (!canReadContracts && (await checkCapability(supabase, "contracts.read", m.organization_id))) {
      canReadContracts = true;
    }
    if (canReadClients && canReadContracts) break;
  }

  const navGroups = [
    {
      items: [
        { href: "/whoami", label: "Dashboard" },
        ...(canManageUsers
          ? [{ href: "/admin/users", label: "Users & Roles" }]
          : []),
      ],
    },
    ...(canReadClients || canReadContracts
      ? [
          {
            label: "Clients & Contracts",
            items: [
              ...(canReadClients
                ? [{ href: "/clients", label: "Clients" }]
                : []),
              ...(canReadContracts
                ? [{ href: "/contracts", label: "Contracts" }]
                : []),
            ],
          },
        ]
      : []),
  ];

  return (
    <ShellChrome
      navGroups={navGroups}
      userEmail={user.email ?? ""}
      roleLabel={roleLabel}
    >
      {children}
    </ShellChrome>
  );
}
