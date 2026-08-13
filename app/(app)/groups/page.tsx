import { createClient } from "@/lib/supabase/server";
import { GroupsClient } from "./groups-client";

type MembershipRow = { organization_id: string };
type GroupRow = {
  id: string;
  client_id: string;
  module: string;
  delivery_format: string;
  schedule_pattern: string | null;
  children_confirmed: number | null;
  children_billed: number | null;
  status: string;
};
type ClientLookupRow = { id: string; name: string };
type ClientOptionRow = { id: string; name: string; organization_id: string };

// G2: list page for the Operational domain (G1 schema/RLS). No manual
// org-scoping on the fetch itself — groups' SELECT policy (202608130003)
// already resolves exactly which rows this session can see, including the
// Trainer/Senior Trainer row-level restriction to groups referenced by a
// session they're allocated to. Same shape as clients/page.tsx.
export default async function GroupsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reason="Not signed in." />;
  }

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  // Only used to (a) decide whether "+ New Group" renders and (b) know
  // which org a newly created group should belong to — the RLS INSERT
  // policy on groups (groups.create) is what actually decides whether the
  // insert succeeds, same relationship as clients/page.tsx's createOrgId.
  let createOrgId: string | null = null;
  // Trainer-view heading (task step 4): true only when the viewer's access
  // to this screen comes from mywork.* (own-work scope) and NOT from
  // groups.read (org-wide read) — mirrors app/(app)/layout.tsx's own
  // canReadGroups reasoning exactly, just split into its two branches here
  // so the page can tell them apart for display purposes. RLS itself
  // doesn't need this flag — the query below is already correctly scoped
  // either way; this only decides the heading/empty-state copy.
  let hasGroupsRead = false;
  let hasMyWorkOnly = false;
  for (const m of memberships ?? []) {
    if (!createOrgId) {
      const { data: allowed } = await supabase.rpc("has_capability", {
        cap: "groups.create",
        org: m.organization_id,
      });
      if (allowed) createOrgId = m.organization_id;
    }
    if (!hasGroupsRead) {
      const { data: allowed } = await supabase.rpc("has_capability", {
        cap: "groups.read",
        org: m.organization_id,
      });
      if (allowed) hasGroupsRead = true;
    }
    if (!hasMyWorkOnly) {
      const { data: allowed } = await supabase.rpc("has_capability", {
        cap: "mywork.*",
        org: m.organization_id,
      });
      if (allowed) hasMyWorkOnly = true;
    }
    if (createOrgId && hasGroupsRead && hasMyWorkOnly) break;
  }
  const isTrainerView = hasMyWorkOnly && !hasGroupsRead;

  const { data: groups } = await supabase
    .from("groups")
    .select(
      "id, client_id, module, delivery_format, schedule_pattern, children_confirmed, children_billed, status",
    )
    .order("created_at", { ascending: false })
    .returns<GroupRow[]>();

  // Two follow-up lookups rather than a PostgREST embed — same convention
  // as contracts/page.tsx's clientIds/legalEntityIds resolution, reused
  // here rather than inventing a second name-resolution approach.
  const clientIds = [...new Set((groups ?? []).map((g) => g.client_id))];
  const { data: clientRows } =
    clientIds.length > 0
      ? await supabase
          .from("clients")
          .select("id, name")
          .in("id", clientIds)
          .returns<ClientLookupRow[]>()
      : { data: [] as ClientLookupRow[] };
  const clientNameById = new Map((clientRows ?? []).map((c) => [c.id, c.name]));

  const rows = (groups ?? []).map((g) => ({
    ...g,
    clientName: clientNameById.get(g.client_id) ?? g.client_id,
  }));

  // Form options for "+ New Group": clients in the org the caller can
  // create groups in (only fetched when that org is known, i.e. the
  // button will actually render) — same pattern as contracts/page.tsx's
  // clientOptions.
  let clientOptions: ClientOptionRow[] = [];
  if (createOrgId) {
    const { data: co } = await supabase
      .from("clients")
      .select("id, name, organization_id")
      .eq("organization_id", createOrgId)
      .order("name")
      .returns<ClientOptionRow[]>();
    clientOptions = co ?? [];
  }

  return (
    <div className="flex w-full flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl text-brand-pink">
          {isTrainerView ? "Your Groups" : "Groups & Enrollment"}
        </h1>
        <p className="font-body text-muted mt-1 text-sm">
          {isTrainerView
            ? "Groups containing at least one session allocated to you, as principal or secundar trainer."
            : "Enrollment containers by client and module. Trainer allocation and delivery live on each group's sessions."}
        </p>
      </div>
      <GroupsClient
        groups={rows}
        createOrgId={createOrgId}
        clientOptions={clientOptions}
        isTrainerView={isTrainerView}
      />
    </div>
  );
}

function AccessDenied({ reason }: { reason: string }) {
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">Access denied</h1>
      <p className="font-body text-muted mt-1 text-sm">{reason}</p>
    </div>
  );
}
