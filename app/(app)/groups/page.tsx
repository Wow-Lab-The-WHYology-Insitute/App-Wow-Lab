import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
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
type ClientLookupRow = { id: string; name: string; legal_name: string | null };
type ClientOptionRow = { id: string; name: string; organization_id: string };
type SessionLookupRow = {
  group_id: string;
  session_date: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
};
type UserLookupRow = {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
};

function displayName(u: Pick<UserLookupRow, "email" | "first_name" | "last_name">) {
  const full = [u.first_name, u.last_name].filter(Boolean).join(" ");
  return full || u.email;
}

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
  //
  // hasMasterAccess (org.settings.manage) is a THIRD, separate check, not
  // just a third branch of the same OR — found live: organization_owner/
  // platform_owner both hold mywork.* (a leftover from the one-time
  // blanket capability grant every pre-G1 capability got, supabase/
  // seed.sql parts 4/5) but not groups.read (a capability that didn't
  // exist yet when that grant ran), so hasMyWorkOnly && !hasGroupsRead
  // used to misread them as trainer-view. org.settings.manage is the same
  // Master-bypass signal the groups RLS policy itself checks
  // (202608130003) — a viewer who has it should never be trainer-view,
  // regardless of which legacy capabilities they also happen to hold.
  let hasGroupsRead = false;
  let hasMyWorkOnly = false;
  let hasMasterAccess = false;
  for (const m of memberships ?? []) {
    if (!createOrgId) {
      if (await checkCapability(supabase, "groups.create", m.organization_id)) {
        createOrgId = m.organization_id;
      }
    }
    if (!hasGroupsRead) {
      if (await checkCapability(supabase, "groups.read", m.organization_id)) {
        hasGroupsRead = true;
      }
    }
    if (!hasMyWorkOnly) {
      if (await checkCapability(supabase, "mywork.*", m.organization_id)) {
        hasMyWorkOnly = true;
      }
    }
    if (!hasMasterAccess) {
      if (await checkCapability(supabase, "org.settings.manage", m.organization_id)) {
        hasMasterAccess = true;
      }
    }
    if (createOrgId && hasGroupsRead && hasMyWorkOnly && hasMasterAccess) break;
  }
  const isTrainerView = hasMyWorkOnly && !hasGroupsRead && !hasMasterAccess;

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
          .select("id, name, legal_name")
          .in("id", clientIds)
          .returns<ClientLookupRow[]>()
      : { data: [] as ClientLookupRow[] };
  const clientNameById = new Map((clientRows ?? []).map((c) => [c.id, c.name]));
  const clientLegalNameById = new Map((clientRows ?? []).map((c) => [c.id, c.legal_name]));

  // Trainer names on the list: the CURRENT allocation, i.e. the most
  // recent session per group (by session_date desc) — not every trainer
  // who's ever rotated through it (sessions can span many occurrences with
  // rotating principal/secundar, per the G1 design; showing the full
  // rotation history on a list row would be noisy, not useful for an
  // at-a-glance scan). Flagged as an interpretation call in the report.
  const groupIds = (groups ?? []).map((g) => g.id);
  const { data: sessionRows } =
    groupIds.length > 0
      ? await supabase
          .from("sessions")
          .select("group_id, session_date, trainer_principal_id, trainer_secundar_id")
          .in("group_id", groupIds)
          .order("session_date", { ascending: false })
          .returns<SessionLookupRow[]>()
      : { data: [] as SessionLookupRow[] };

  const latestSessionByGroup = new Map<string, SessionLookupRow>();
  for (const s of sessionRows ?? []) {
    if (!latestSessionByGroup.has(s.group_id)) latestSessionByGroup.set(s.group_id, s);
  }

  const trainerIds = [
    ...new Set(
      [...latestSessionByGroup.values()]
        .flatMap((s) => [s.trainer_principal_id, s.trainer_secundar_id])
        .filter((v): v is string => v !== null),
    ),
  ];
  const { data: trainerUsers } =
    trainerIds.length > 0
      ? await supabase
          .from("users")
          .select("id, email, first_name, last_name")
          .in("id", trainerIds)
          .returns<UserLookupRow[]>()
      : { data: [] as UserLookupRow[] };
  const trainerNameById = new Map((trainerUsers ?? []).map((u) => [u.id, displayName(u)]));

  const rows = (groups ?? []).map((g) => {
    const latest = latestSessionByGroup.get(g.id);
    return {
      ...g,
      clientName: clientNameById.get(g.client_id) ?? g.client_id,
      clientLegalName: clientLegalNameById.get(g.client_id) ?? null,
      trainerPrincipalName: latest?.trainer_principal_id
        ? (trainerNameById.get(latest.trainer_principal_id) ?? "Unknown")
        : null,
      trainerSecundarName: latest?.trainer_secundar_id
        ? (trainerNameById.get(latest.trainer_secundar_id) ?? "Unknown")
        : null,
    };
  });

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
