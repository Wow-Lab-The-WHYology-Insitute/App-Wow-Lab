import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { GroupDetailClient } from "./group-detail-client";
import { GroupHeader } from "./group-header";
import { GroupInfoSection } from "./group-info-section";
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
};
type ClientLookupRow = { id: string; name: string };
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
};
type UserLookupRow = {
  id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
};
type RoleIdRow = { id: string };
type UserOrgRoleRow = { user_id: string };

// Same rule as groups/page.tsx's copy: never falls back to email (not even
// selected below anymore). full_name is NOT NULL but can itself be a raw
// email (handle_new_auth_user default) -- skipped, not trusted just for
// being non-null. "" (not null) signals "nothing safe to show" -- module/
// format/status labels now route through GroupHeader/GroupInfoSection's
// own useTranslations() (group-header.tsx, group-info-section.tsx), but
// this trainer-name fallback stays a plain "Unnamed" literal, unlike
// groups/page.tsx's callers (groups-client.tsx, group-detail-panel.tsx),
// which do translate it -- displayName() itself has no i18n wiring here.
function displayName(u: Pick<UserLookupRow, "full_name" | "first_name" | "last_name">) {
  const full = [u.first_name, u.last_name].filter(Boolean).join(" ");
  if (full) return full;
  if (u.full_name && !u.full_name.includes("@")) return u.full_name;
  return "";
}

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
      "id, organization_id, client_id, module, delivery_format, schedule_pattern, children_confirmed, children_billed, status, notes, age_range, school_year_calendar_link",
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
    .select("id, name")
    .eq("id", group.client_id)
    .maybeSingle<ClientLookupRow>();

  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, session_date, trainer_principal_id, trainer_secundar_id, status, attendance_count, experiment_delivered, duration_minutes, experiment_drive_link",
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

  const clientName = clientRow?.name ?? group.client_id;

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6">
      <GroupHeader
        clientName={clientName}
        module={group.module}
        deliveryFormat={group.delivery_format}
        status={group.status}
      />

      <GroupInfoSection
        clientName={clientName}
        module={group.module}
        deliveryFormat={group.delivery_format}
        schedulePattern={group.schedule_pattern}
        ageRange={group.age_range}
        calendarLink={group.school_year_calendar_link}
        childrenConfirmed={group.children_confirmed}
        childrenBilled={group.children_billed}
        notes={group.notes}
      />

      <GroupDetailClient
        groupId={group.id}
        organizationId={group.organization_id}
        sessions={sessionRows}
        canManageSessions={Boolean(canManageSessions)}
        trainerOptions={trainerOptions}
      />
    </div>
  );
}
