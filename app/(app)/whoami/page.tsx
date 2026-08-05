import { createClient } from "@/lib/supabase/server";

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
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl text-brand-pink">Dashboard</h1>
        <p className="font-body text-muted mt-1 text-sm">
          Diagnostic view: every value below came through your own session
          (anon key + your JWT), never service_role — proof the auth → RLS
          loop works, not yet a real Phase 1 dashboard.
        </p>
      </div>

      <Section title="Signed in as">
        <Kv label="Email" value={ownProfile?.email ?? user.email ?? "?"} />
        <Kv label="User ID" value={user.id} mono />
        <Kv
          label="Platform owner"
          value={String(ownProfile?.is_platform_owner ?? false)}
        />
        <Kv label="Status" value={ownProfile?.status ?? "?"} />
      </Section>

      <Section title="Organizations visible via RLS">
        {(visibleOrgs ?? []).length === 0 ? (
          <Empty>None</Empty>
        ) : (
          <ul className="flex flex-col gap-2">
            {(visibleOrgs ?? []).map((o) => (
              <li key={o.id} className="font-body text-ink text-sm">
                <span className="font-semibold">{o.slug}</span> — {o.name}
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section title="Your role(s) per organization">
        {(memberships ?? []).length === 0 ? (
          <Empty>No user_org_roles row for this user</Empty>
        ) : (
          <ul className="flex flex-wrap gap-2">
            {(memberships ?? []).map((m, i) => (
              <li key={i}>
                <Badge>
                  {m.organizations?.slug ?? m.organization_id}:{" "}
                  {m.roles?.display_name ?? "?"}
                </Badge>
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section title="Resolved capabilities per organization">
        <div className="flex flex-col gap-4">
          {(memberships ?? []).map((m, i) => (
            <div key={i}>
              <p className="font-body text-ink mb-2 text-sm font-semibold">
                {m.organizations?.slug ?? m.organization_id}
              </p>
              {m.roles && (capsByRole.get(m.roles.id)?.length ?? 0) > 0 ? (
                <ul className="flex flex-wrap gap-1.5">
                  {capsByRole.get(m.roles.id)!.map((key) => (
                    <li key={key}>
                      <Badge mono>{key}</Badge>
                    </li>
                  ))}
                </ul>
              ) : (
                <Empty>None</Empty>
              )}
            </div>
          ))}
        </div>
      </Section>

      <Section title="Spot-check via app.has_capability() RPC">
        <ul className="flex flex-col gap-1.5">
          {spotCheckResults.map((r, i) => (
            <li
              key={i}
              className="font-body text-ink flex items-center gap-2 text-sm"
            >
              <span className="font-mono text-xs">
                has_capability(&apos;{r.cap}&apos;, {r.org})
              </span>
              <Badge tone={r.allowed ? "neutral" : "pink"}>
                {String(r.allowed)}
              </Badge>
            </li>
          ))}
        </ul>
      </Section>
    </div>
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
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

function Kv({
  label,
  value,
  mono,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className={`text-ink ${mono ? "font-mono text-xs" : "font-body font-medium"}`}>
        {value}
      </span>
    </div>
  );
}

function Badge({
  children,
  mono,
  tone = "neutral",
}: {
  children: React.ReactNode;
  mono?: boolean;
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${mono ? "font-mono" : "font-body"} ${
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="font-body text-muted text-sm">{children}</p>;
}
