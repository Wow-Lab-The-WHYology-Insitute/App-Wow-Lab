import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { ProfileSection } from "./profile-section";
import { TechnicalDetails } from "./technical-details";
import { ProfileHeading } from "./profile-heading";
import { DiagnosticIntro } from "./diagnostic-intro";
import { AccessSummary } from "./access-summary";
import { AccessDenied } from "@/components/ui/access-denied";

// S2: a diagnostic page proving the auth -> RLS loop works for a real
// logged-in session, not SQL Editor impersonation. Every query below runs
// through the session client (anon key + this user's own JWT) — there is
// no service_role anywhere in this file. S3 (this pass) only restyled the
// JSX below into the shared brand shell; the data-fetching is untouched.

type OrgRow = { id: string; name: string; slug: string };

type MembershipRow = {
  organization_id: string;
  organizations: { name: string; slug: string } | null;
  roles: { id: string; key: string; display_name: string } | null;
};

type RoleCapabilityRow = {
  role_id: string;
  capabilities: { key: string } | null;
};

const SPOT_CHECK_CAPABILITIES = ["org.members.manage", "org.audit.read"];

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    // Shouldn't be reachable — middleware redirects unauthenticated
    // requests before this ever renders.
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  // users_masked (202608200005): own-row branch always resolves to the
  // real email/phone here, same as the base table — this just routes the
  // read through the masked view now that it exists, per
  // docs/WOWLAB_SAD_Field_Masking.md §2.3 step 2.
  const { data: ownProfile } = await supabase
    .from("users_masked")
    .select("email, is_platform_owner, status, first_name, last_name, phone, avatar_url")
    .eq("id", user.id)
    .maybeSingle();

  // avatar_url is a Storage PATH in the private `avatars` bucket, never a
  // public URL — resolved to a short-lived signed URL here, through this
  // same session client, so "authenticated org members can read any
  // avatar" (storage.objects RLS, 202608120001) is what actually gates
  // this render, same as the /admin/users members list.
  let signedAvatarUrl: string | null = null;
  if (ownProfile?.avatar_url) {
    const { data: signed } = await supabase.storage
      .from("avatars")
      .createSignedUrl(ownProfile.avatar_url, 3600);
    signedAvatarUrl = signed?.signedUrl ?? null;
  }

  // RLS on organizations: app.is_platform_owner() OR app.belongs_to_org(id).
  // For anyone who isn't platform_owner, this list is the plainest possible
  // proof of cross-org isolation: it can only ever contain orgs this user
  // actually belongs to.
  const { data: visibleOrgs } = await supabase
    .from("organizations")
    .select("id, name, slug")
    .order("slug")
    .returns<OrgRow[]>();

  // RLS on user_org_roles: own row is always visible, independent of any
  // capability. This is exactly the query the SQL-impersonation suites
  // (db/tests/rls_ws_d_read.sql etc.) ran under `set role authenticated`;
  // here it runs under a real session instead.
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select(
      "organization_id, organizations(name, slug), roles(id, key, display_name)",
    )
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  // Tier 2 (S3 restructure): "You are X. You have access to: Y, Z." — the
  // SAME capability keys and labels app/(app)/layout.tsx uses to gate
  // navGroups, duplicated here rather than hardcoding a different/
  // simplified rule (e.g. checking role names). Not extracted into a
  // shared helper — layout.tsx's own checkCapability is a local, private
  // function, and Part D's scope is explicitly read-only against where the
  // nav array itself lives; this mirrors the same 4 checks instead, same
  // as how financeVisible's capability-check pattern is independently
  // duplicated (not shared) across clients/[id]/page.tsx and contracts/
  // page.tsx already.
  const roleLabel = [
    ...new Set(
      (memberships ?? []).map((m) => m.roles?.display_name).filter(Boolean),
    ),
  ].join(", ");

  // chromeDict keys, not display strings — AccessSummary (a client
  // component) resolves each to the same nav label chromeDict already
  // owns, rather than this file carrying a third hardcoded copy of
  // "Clients"/"Contracts"/etc. alongside chromeDict's and each domain's own
  // page_title.
  const visibleNavKeys: string[] = [];
  let canManageUsers = false;
  let canReadClients = false;
  let canReadContracts = false;
  let canReadGroups = false;
  for (const m of memberships ?? []) {
    if (!canManageUsers) {
      if (await checkCapability(supabase, "org.members.manage", m.organization_id)) {
        canManageUsers = true;
      }
    }
    if (!canReadClients) {
      if (await checkCapability(supabase, "clients.read", m.organization_id)) {
        canReadClients = true;
      }
    }
    if (!canReadContracts) {
      if (await checkCapability(supabase, "contracts.read", m.organization_id)) {
        canReadContracts = true;
      }
    }
    if (!canReadGroups) {
      const [hasGroupsRead, hasMyWork] = await Promise.all([
        checkCapability(supabase, "groups.read", m.organization_id),
        checkCapability(supabase, "mywork.*", m.organization_id),
      ]);
      if (hasGroupsRead || hasMyWork) canReadGroups = true;
    }
    if (canManageUsers && canReadClients && canReadContracts && canReadGroups) break;
  }
  if (canManageUsers) visibleNavKeys.push("nav_users_roles");
  if (canReadClients) visibleNavKeys.push("nav_clients");
  if (canReadContracts) visibleNavKeys.push("nav_contracts");
  if (canReadGroups) visibleNavKeys.push("nav_groups_enrollment");

  const roleIds = [
    ...new Set(
      (memberships ?? [])
        .map((m) => m.roles?.id)
        .filter((id): id is string => Boolean(id)),
    ),
  ];

  // role_capabilities and capabilities both carry an open SELECT policy for
  // any authenticated user (D1a) — this join is the exact same resolution
  // app.has_capability() runs internally (see 202607090001), just fetching
  // the full set instead of checking one key at a time.
  const { data: roleCapRows } =
    roleIds.length > 0
      ? await supabase
          .from("role_capabilities")
          .select("role_id, capabilities(key)")
          .in("role_id", roleIds)
          .returns<RoleCapabilityRow[]>()
      : { data: [] as RoleCapabilityRow[] };

  const capsByRole = new Map<string, string[]>();
  for (const row of roleCapRows ?? []) {
    if (!row.capabilities) continue;
    const list = capsByRole.get(row.role_id) ?? [];
    list.push(row.capabilities.key);
    capsByRole.set(row.role_id, list);
  }

  // Direct spot-check via the actual RPC path the real app uses
  // (public.has_capability -> app.has_capability, 202607130004), for a
  // couple of meaningful, well-known capabilities — this is the literal
  // "existing capability resolver" the S2 task names, exercised through a
  // real session rather than SQL impersonation. Deliberately NOT routed
  // through checkCapability() like the nav-gating checks above: this block
  // exists specifically to prove the raw RPC path works, and wrapping it
  // in the retry/fail-closed helper would test the helper instead of the
  // thing this diagnostic page says it's proving.
  const spotCheckResults: { cap: string; org: string; allowed: boolean }[] =
    [];
  for (const membership of memberships ?? []) {
    for (const cap of SPOT_CHECK_CAPABILITIES) {
      const { data: allowed } = await supabase.rpc("has_capability", {
        cap,
        org: membership.organization_id,
      });
      spotCheckResults.push({
        cap,
        org: membership.organizations?.slug ?? membership.organization_id,
        allowed: Boolean(allowed),
      });
    }
  }

  return (
    <div className="flex w-full flex-col gap-6">
      <div>
        <ProfileHeading />
        <DiagnosticIntro />
      </div>

      <ProfileSection
        email={ownProfile?.email ?? user.email ?? ""}
        initialFirstName={ownProfile?.first_name ?? null}
        initialLastName={ownProfile?.last_name ?? null}
        initialPhone={ownProfile?.phone ?? null}
        initialAvatarUrl={signedAvatarUrl}
      />

      <AccessSummary roleLabel={roleLabel} navKeys={visibleNavKeys} />

      <TechnicalDetails
        email={ownProfile?.email ?? user.email ?? ""}
        userId={user.id}
        isPlatformOwner={ownProfile?.is_platform_owner ?? false}
        status={ownProfile?.status ?? "?"}
        visibleOrgs={visibleOrgs ?? []}
        memberships={(memberships ?? []).map((m) => ({
          orgLabel: m.organizations?.slug ?? m.organization_id,
          roleLabel: m.roles?.display_name ?? "?",
          capabilities: m.roles ? (capsByRole.get(m.roles.id) ?? []) : [],
        }))}
        spotCheckResults={spotCheckResults}
      />
    </div>
  );
}
