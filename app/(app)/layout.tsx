import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { ShellChrome } from "./shell-chrome";
import { LocaleProvider } from "@/lib/i18n";
import { checkCapability } from "@/lib/capabilities";

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

  // avatar_url is a Storage PATH in the private `avatars` bucket, never a
  // public URL — resolved to a short-lived signed URL here, through this
  // same session client, same as /profile and /admin/users.
  const { data: ownProfile } = await supabase
    .from("users")
    .select("avatar_url")
    .eq("id", user.id)
    .maybeSingle();

  let avatarUrl: string | null = null;
  if (ownProfile?.avatar_url) {
    const { data: signed } = await supabase.storage
      .from("avatars")
      .createSignedUrl(ownProfile.avatar_url, 3600);
    avatarUrl = signed?.signedUrl ?? null;
  }

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

  // Operational (G2): gated on groups.read OR mywork.* — not groups.read
  // alone. Trainer/Senior Trainer deliberately hold mywork.* instead of
  // groups.read (G1's RLS design keeps their capability footprint scoped
  // to "my own work", not general org-roster read), so a groups.read-only
  // gate would hide this nav item from the exact roles the SAD names as
  // needing it ("Trainer/Senior Trainer (filtrat pe 'ale mele')") — this
  // OR is what actually matches the SAD's menu-level spec, not a literal
  // single-capability reading of it.
  let canReadGroups = false;
  for (const m of memberships ?? []) {
    if (
      (await checkCapability(supabase, "groups.read", m.organization_id)) ||
      (await checkCapability(supabase, "mywork.*", m.organization_id))
    ) {
      canReadGroups = true;
      break;
    }
  }

  // labelKey, not label: these render inside ShellChrome, a client
  // component that resolves them through useTranslations(chromeDict) — this
  // server component has no locale (that's a client-only, localStorage-
  // persisted preference), so it can only pass the key, never the string.
  const navGroups = [
    {
      items: [
        { href: "/profile", labelKey: "nav_profile" },
        ...(canManageUsers
          ? [{ href: "/admin/users", labelKey: "nav_users_roles" }]
          : []),
      ],
    },
    ...(canReadClients || canReadContracts
      ? [
          {
            labelKey: "nav_group_clients_contracts",
            items: [
              ...(canReadClients
                ? [{ href: "/clients", labelKey: "nav_clients" }]
                : []),
              ...(canReadContracts
                ? [{ href: "/contracts", labelKey: "nav_contracts" }]
                : []),
            ],
          },
        ]
      : []),
    ...(canReadGroups
      ? [
          {
            labelKey: "nav_group_operational",
            items: [{ href: "/groups", labelKey: "nav_groups_enrollment" }],
          },
        ]
      : []),
  ];

  return (
    <LocaleProvider>
      <ShellChrome
        navGroups={navGroups}
        userEmail={user.email ?? ""}
        roleLabel={roleLabel}
        avatarUrl={avatarUrl}
      >
        {children}
      </ShellChrome>
    </LocaleProvider>
  );
}
