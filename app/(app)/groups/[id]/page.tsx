import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { displayName } from "@/lib/display-name";
import { GroupDetailClient } from "./group-detail-client";
import { GroupHeader } from "./group-header";
import { GroupInfoSection } from "./group-info-section";
import { TrainerResourcesSection } from "./trainer-resources-section";
import { AccessDenied } from "@/components/ui/access-denied";

type GroupRow = {
  id: string;
  organization_id: string;
  client_id: string;
  module: string;
  delivery_format: string;
  schedule_pattern: string | null;
  children_confirmed: number | null;
  children_billed: number | null;
  status: string;
  notes: string | null;
  age_range: string | null;
  school_year_calendar_link: string | null;
  contract_id: string | null;
  address: string | null;
  on_site_contact_id: string | null;
  language_group: string | null;
};
type ClientLookupRow = { id: string; name: string; address: string | null };
type ContractLookupRow = { id: string; exit_number: string | null };
type ContractOptionRow = { id: string; client_id: string; exit_number: string | null };
type ContactLookupRow = { id: string; full_name: string; phone: string | null; contact_purpose: string | null };
type ContactOptionRow = { id: string; client_id: string; full_name: string };
type SessionRow = {
  id: string;
  session_date: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  status: string;
  attendance_count: number | null;
  experiment_delivered: string | null;
  duration_minutes: number | null;
  experiment_drive_link: string | null;
  trainer_principal_confirmed_at: string | null;
  trainer_secundar_confirmed_at: string | null;
  start_time: string | null;
};
type UserLookupRow = {
  id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
};
type RoleIdRow = { id: string };
type UserOrgRoleRow = { user_id: string };
type HomeCityRow = { trainer_id: string; city: string };

export default async function GroupDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  const { data: group } = await supabase
    .from("groups")
    .select(
      "id, organization_id, client_id, module, delivery_format, schedule_pattern, children_confirmed, children_billed, status, notes, age_range, school_year_calendar_link, contract_id, address, on_site_contact_id, language_group",
    )
    .eq("id", id)
    .maybeSingle<GroupRow>();

  if (!group) {
    // Either genuinely missing, or RLS-filtered for this viewer (a Trainer
    // with no allocated session in this group) — a single-row RLS query
    // can't distinguish the two, and shouldn't, same reasoning as
    // clients/[id]/page.tsx.
    return <AccessDenied reasonKey="access_denied_not_found_group" />;
  }

  const { data: clientRow } = await supabase
    .from("clients")
    .select("id, name, address")
    .eq("id", group.client_id)
    .maybeSingle<ClientLookupRow>();

  // The group's own linked on-site contact, for the read view -- resolved
  // the same way linkedContract is below: a null result here with
  // group.on_site_contact_id set is "linked, but RLS filters it out for
  // this viewer" (a trainer not allocated to any session in this group,
  // or the contact's own contact_purpose isn't trainer_facing -- see
  // 202609210002), not "no contact linked at all" -- same
  // null-vs-masked-vs-zero distinction contractVisible already draws.
  const { data: onSiteContact } = group.on_site_contact_id
    ? await supabase
        .from("client_contacts")
        .select("id, full_name, phone, contact_purpose")
        .eq("id", group.on_site_contact_id)
        .maybeSingle<ContactLookupRow>()
    : { data: null };

  // The group's own linked contract, for the read view -- resolved
  // separately from contractOptions below (which only exists for the
  // editor and is fetched org-wide). A null result here with
  // group.contract_id set is NOT the same fact as group.contract_id being
  // null itself: the first is "linked, but this session's contracts SELECT
  // policy filters it out" (e.g. a Trainer viewing a group whose contract
  // sits behind the finance-scoped branch), the second is "no contract
  // linked at all" -- collapsing them would misreport an RLS boundary as
  // an empty field, the same distinction ValueCell already draws for
  // null-vs-masked-vs-zero.
  const { data: linkedContract } = group.contract_id
    ? await supabase
        .from("contracts")
        .select("id, exit_number")
        .eq("id", group.contract_id)
        .maybeSingle<ContractLookupRow>()
    : { data: null };

  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, session_date, trainer_principal_id, trainer_secundar_id, status, attendance_count, experiment_delivered, duration_minutes, experiment_drive_link, trainer_principal_confirmed_at, trainer_secundar_confirmed_at, start_time",
    )
    .eq("group_id", id)
    .order("session_date", { ascending: false })
    .returns<SessionRow[]>();

  // Trainer names on session rows: batch-resolved from whichever ids
  // actually appear, not from a role-filtered universe — same two-lookup
  // convention as contracts/page.tsx's clientIds/legalEntityIds. A viewer
  // without org.members.read (Trainer/Senior Trainer, by design — see
  // 202608130005) will only get their OWN row back here; a co-trainer's
  // name resolves to null and falls back to "Unknown" below. Known, minor,
  // flagged in the migration and the final report — not silently patched
  // over.
  const trainerIdsInSessions = [
    ...new Set(
      (sessions ?? [])
        .flatMap((s) => [s.trainer_principal_id, s.trainer_secundar_id])
        .filter((v): v is string => v !== null),
    ),
  ];
  const { data: sessionTrainerUsers } =
    trainerIdsInSessions.length > 0
      ? await supabase
          .from("users")
          .select("id, full_name, first_name, last_name")
          .in("id", trainerIdsInSessions)
          .returns<UserLookupRow[]>()
      : { data: [] as UserLookupRow[] };
  const trainerNameById = new Map(
    (sessionTrainerUsers ?? []).map((u) => [u.id, displayName(u)]),
  );

  const sessionRows = (sessions ?? []).map((s) => ({
    ...s,
    trainerPrincipalName: s.trainer_principal_id
      ? (trainerNameById.get(s.trainer_principal_id) ?? "Unknown")
      : null,
    trainerSecundarName: s.trainer_secundar_id
      ? (trainerNameById.get(s.trainer_secundar_id) ?? "Unknown")
      : null,
  }));

  // sessions.create capability (matches the RLS INSERT/UPDATE policy on
  // sessions, 202608130003) — gates both "+ New Session" and the inline
  // trainer-reallocation edit, same relationship as createOrgId elsewhere.
  const canManageSessions = await checkCapability(supabase, "sessions.create", group.organization_id);

  // groups.create capability (matches the RLS UPDATE policy on groups
  // itself, 202608130003 -- Operations Manager + Master) — gates the group
  // record's own Edit action (notes, contract_id), same relationship
  // canManageContracts has to contracts' UPDATE policy.
  const canManage = await checkCapability(supabase, "groups.create", group.organization_id);

  // contracts.* capability (matches the groups UPDATE policy's new
  // 202609110002 branch) — gates writing children_confirmed only, per
  // Anca's 2026-09-11 decision. Deliberately separate from canManage:
  // Cătălina (operations_manager, canManage) sees the count but does not
  // fill it; Laura and Anka (contract_administrator, contracts.*) fill
  // it and nothing else on this record. Someone could hold both.
  const canWriteChildrenConfirmed = await checkCapability(supabase, "contracts.*", group.organization_id);

  // mywork.* (Trainer/Senior Trainer) -- gates the resources section
  // (trainer-resources-section.tsx). Anyone who can even load this page
  // as a trainer already has an allocated session in it (the groups
  // SELECT policy's mywork.* branch requires that row match), so this
  // check alone is enough to keep the section away from Operations/
  // Finance viewers without also needing a per-session check.
  const hasMywork = await checkCapability(supabase, "mywork.*", group.organization_id);

  // Gates the confirmation-correction control on the sessions below --
  // matches correctSessionConfirmation's own check (groups/actions.ts)
  // exactly, org.settings.manage OR finance.operations.*, so nobody who
  // can see the control is denied by the action underneath it, and nobody
  // who can act is left without a way to reach it.
  const canCorrectConfirmation =
    (await checkCapability(supabase, "org.settings.manage", group.organization_id)) ||
    (await checkCapability(supabase, "finance.operations.*", group.organization_id));

  // contractOptions: every contract in this group's org, only fetched when
  // the edit form will actually render -- same "only fetch what the
  // button needs" discipline as trainerOptions just above. GroupEditForm
  // filters this client-side to group.client_id, matching NewGroupForm's
  // (groups-client.tsx) filtering of the identical shape.
  let contractOptions: ContractOptionRow[] = [];
  let contactOptions: ContactOptionRow[] = [];
  if (canManage) {
    const { data: cto } = await supabase
      .from("contracts")
      .select("id, client_id, exit_number")
      .eq("organization_id", group.organization_id)
      .returns<ContractOptionRow[]>();
    contractOptions = cto ?? [];

    // Same "only fetch what the button needs" discipline as contractOptions
    // just above, filtered client-side by GroupEditForm to this group's own
    // client -- the on-site contact picker is deliberately link-only (item
    // 52's on-site-contact design record): it offers whichever contacts
    // already exist for the client, never creates a new one from this form.
    const { data: cno } = await supabase
      .from("client_contacts")
      .select("id, client_id, full_name")
      .eq("organization_id", group.organization_id)
      .returns<ContactOptionRow[]>();
    contactOptions = cno ?? [];
  }

  // Trainer picker options, only fetched when the form/edit controls will
  // actually render — same "only fetch what the button needs" discipline
  // as contracts/page.tsx's clientOptions/legalEntityOptions.
  let trainerOptions: { id: string; name: string }[] = [];
  if (canManageSessions) {
    const { data: roleRows } = await supabase
      .from("roles")
      .select("id")
      .in("key", ["trainer", "senior_trainer"])
      .returns<RoleIdRow[]>();
    const roleIds = (roleRows ?? []).map((r) => r.id);
    const { data: assignments } =
      roleIds.length > 0
        ? await supabase
            .from("user_org_roles")
            .select("user_id")
            .eq("organization_id", group.organization_id)
            .in("role_id", roleIds)
            .returns<UserOrgRoleRow[]>()
        : { data: [] as UserOrgRoleRow[] };
    const trainerUserIds = [...new Set((assignments ?? []).map((a) => a.user_id))];
    const { data: trainerUsers } =
      trainerUserIds.length > 0
        ? await supabase
            .from("users")
            .select("id, full_name, first_name, last_name")
            .in("id", trainerUserIds)
            .returns<UserLookupRow[]>()
        : { data: [] as UserLookupRow[] };
    trainerOptions = (trainerUsers ?? [])
      .map((u) => ({ id: u.id, name: displayName(u) || "Unnamed" }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  // Pre-fill input for NewSessionForm's location_tier suggestion (item
  // 95/96 report: entered, never derived -- this is a suggestion the
  // form can offer, not a value this page computes and trusts). Same
  // "only fetch what the button needs" discipline as trainerOptions just
  // above -- only fetched when the form that uses it will actually
  // render. trainer_home_cities' own SELECT RLS (202609240004) requires
  // sessions.create or broader, which canManageSessions already confirms
  // for this viewer.
  let trainerHomeCities: Record<string, string> = {};
  if (canManageSessions) {
    const { data: homeCityRows } = await supabase
      .from("trainer_home_cities")
      .select("trainer_id, city")
      .eq("organization_id", group.organization_id)
      .returns<HomeCityRow[]>();
    trainerHomeCities = Object.fromEntries((homeCityRows ?? []).map((r) => [r.trainer_id, r.city]));
  }

  // null, never group.client_id -- a raw id is not a display fallback
  // (OPEN_ITEMS.md item 66: RLS legitimately filtering the client row is
  // not the same fact as "no client", and must never render as an
  // identifier). GroupHeader/GroupInfoSection translate null to a
  // "not visible to your role" placeholder, same shape as contractVisible
  // below.
  const clientName = clientRow?.name ?? null;

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6">
      <GroupHeader
        clientName={clientName}
        module={group.module}
        deliveryFormat={group.delivery_format}
        status={group.status}
      />

      <GroupInfoSection
        groupId={group.id}
        clientId={group.client_id}
        clientName={clientName}
        module={group.module}
        deliveryFormat={group.delivery_format}
        schedulePattern={group.schedule_pattern}
        ageRange={group.age_range}
        calendarLink={group.school_year_calendar_link}
        childrenConfirmed={group.children_confirmed}
        childrenBilled={group.children_billed}
        notes={group.notes}
        contractId={group.contract_id}
        contractExitNumber={linkedContract?.exit_number ?? null}
        contractVisible={group.contract_id ? linkedContract !== null : true}
        // Group override, then the client's own default -- never null just
        // because the group itself never set one (item 52's address design:
        // client-level default, group-level override, COALESCE at read
        // time). "" (not null) if truly neither is set anywhere.
        address={group.address ?? clientRow?.address ?? null}
        addressIsOverride={Boolean(group.address)}
        onSiteContactId={group.on_site_contact_id}
        onSiteContactName={onSiteContact?.full_name ?? null}
        onSiteContactPhone={onSiteContact?.phone ?? null}
        onSiteContactNotYetTrainerFacing={
          Boolean(onSiteContact) && onSiteContact?.contact_purpose !== "trainer_facing"
        }
        onSiteContactVisible={group.on_site_contact_id ? onSiteContact !== null : true}
        languageGroup={group.language_group}
        canManage={Boolean(canManage)}
        canWriteChildrenConfirmed={Boolean(canWriteChildrenConfirmed)}
        contractOptions={contractOptions}
        contactOptions={contactOptions}
      />

      <GroupDetailClient
        groupId={group.id}
        organizationId={group.organization_id}
        sessions={sessionRows}
        canManageSessions={Boolean(canManageSessions)}
        canCorrectConfirmation={canCorrectConfirmation}
        trainerOptions={trainerOptions}
        trainerHomeCities={trainerHomeCities}
        // Same resolution GroupInfoSection already renders (group
        // override, then the client's own default) -- reused, not a
        // second address concept, for the location_tier pre-fill
        // heuristic's "does this address look like Bucharest" check.
        groupAddress={group.address ?? clientRow?.address ?? null}
        viewerId={user.id}
      />

      {hasMywork && <TrainerResourcesSection deliveryFormat={group.delivery_format} />}
    </div>
  );
}
