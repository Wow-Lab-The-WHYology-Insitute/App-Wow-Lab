import { createClient } from "@/lib/supabase/server";

// S2: a bare diagnostic page proving the auth -> RLS loop works for a real
// logged-in session, not SQL Editor impersonation. Every query below runs
// through the session client (anon key + this user's own JWT) — there is
// no service_role anywhere in this file. See app/whoami/README.md (or the
// chat report) for what each section is expected to show and why.

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

export default async function WhoAmIPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    // Shouldn't be reachable — middleware redirects unauthenticated
    // requests before this ever renders.
    return <main className="p-8">Not signed in.</main>;
  }

  const { data: ownProfile } = await supabase
    .from("users")
    .select("email, is_platform_owner, status")
    .eq("id", user.id)
    .maybeSingle();

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
  // real session rather than SQL impersonation.
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
    <main className="mx-auto max-w-2xl p-8 font-mono text-sm">
      <h1 className="mb-1 text-lg font-semibold">whoami (diagnostic)</h1>
      <p className="mb-6 text-xs text-gray-500">
        S2 proof: every value below came through your own session (anon key
        + your JWT), never service_role. Bare page — S3 adds the brand
        shell.
      </p>

      <Section title="Signed in as">
        <p>
          {ownProfile?.email ?? user.email} ({user.id})
        </p>
        <p>is_platform_owner: {String(ownProfile?.is_platform_owner ?? false)}</p>
        <p>status: {ownProfile?.status ?? "?"}</p>
      </Section>

      <Section title="Organizations visible via RLS (organizations table)">
        {(visibleOrgs ?? []).length === 0 && <p>(none)</p>}
        <ul className="list-inside list-disc">
          {(visibleOrgs ?? []).map((o) => (
            <li key={o.id}>
              {o.slug} — {o.name}
            </li>
          ))}
        </ul>
      </Section>

      <Section title="Your role(s) per organization (user_org_roles)">
        {(memberships ?? []).length === 0 && (
          <p>(none — no user_org_roles row for this user)</p>
        )}
        <ul className="list-inside list-disc">
          {(memberships ?? []).map((m, i) => (
            <li key={i}>
              {m.organizations?.slug ?? m.organization_id}:{" "}
              {m.roles?.display_name ?? "?"}
            </li>
          ))}
        </ul>
      </Section>

      <Section title="Resolved capabilities per organization (role_capabilities join)">
        {(memberships ?? []).map((m, i) => (
          <div key={i} className="mb-3">
            <p className="font-semibold">
              {m.organizations?.slug ?? m.organization_id}:
            </p>
            <ul className="list-inside list-disc">
              {m.roles && (capsByRole.get(m.roles.id)?.length ?? 0) > 0 ? (
                capsByRole.get(m.roles.id)!.map((key) => <li key={key}>{key}</li>)
              ) : (
                <li>(none)</li>
              )}
            </ul>
          </div>
        ))}
      </Section>

      <Section title="Spot-check via app.has_capability() RPC">
        <ul className="list-inside list-disc">
          {spotCheckResults.map((r, i) => (
            <li key={i}>
              has_capability(&apos;{r.cap}&apos;, {r.org}) ={" "}
              {String(r.allowed)}
            </li>
          ))}
        </ul>
      </Section>
    </main>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-6 border-b pb-4">
      <h2 className="mb-2 font-semibold">{title}</h2>
      {children}
    </section>
  );
}
