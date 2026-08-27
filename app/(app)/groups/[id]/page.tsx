import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { GroupDetailClient } from "./group-detail-client";
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

const MODULE_LABELS: Record<string, string> = {
  gaga: "GAGA",
  green_energy: "Green Energy",
  wow_mix: "Wow Lab Mix",
  tiktok: "Wow TikTok Science",
  food_science: "Wow Food Science",
  lotions: "Wow Lotions and Potions",
  magic_physics: "Magic of Physics",
  chem_me: "Chemistry for Me",
  chem_hs: "Chemistry for Highschool",
  lights: "Lights and Colours",
  detective: "Detective Science",
  astronomy: "Astronomy",
  doctor: "I Wanna Be a Doctor",
};
const DELIVERY_FORMAT_LABELS: Record<string, string> = {
  recurring: "Recurring (school club)",
  scoala_altfel: "Școala Altfel",
  saptamana_verde: "Săptămâna Verde",
  party: "Party",
  corporate: "Corporate",
  custom: "Custom",
};
const GROUP_STATUS_LABELS: Record<string, string> = {
  active: "Active",
  paused: "Paused",
  ended: "Ended",
};

// Same rule as groups/page.tsx's copy: never falls back to email (not even
// selected below anymore). full_name is NOT NULL but can itself be a raw
// email (handle_new_auth_user default) -- skipped, not trusted just for
// being non-null. "" (not null) signals "nothing safe to show" -- this
// file has no i18n wiring today (MODULE_LABELS etc. above are plain
// English constants), so callers here fall back to a plain "Unnamed"
// literal rather than routing through useTranslations, unlike groups/
// page.tsx's callers (groups-client.tsx, group-detail-panel.tsx), which do.
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

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6">
      <div>
        <Link href="/groups" className="font-body text-muted text-xs hover:underline">
          ← Groups
        </Link>
        <h1 className="font-display text-2xl text-brand-pink">
          {clientRow?.name ?? group.client_id} · {MODULE_LABELS[group.module] ?? group.module}
        </h1>
        <div className="mt-2 flex flex-wrap gap-1.5">
          <Badge>{DELIVERY_FORMAT_LABELS[group.delivery_format] ?? group.delivery_format}</Badge>
          <Badge tone={group.status === "active" ? "neutral" : "pink"}>
            {GROUP_STATUS_LABELS[group.status] ?? group.status}
          </Badge>
        </div>
      </div>

      <Section title="Group info">
        <Kv label="Client" value={clientRow?.name ?? group.client_id} />
        <Kv label="Module" value={MODULE_LABELS[group.module] ?? group.module} />
        <Kv label="Delivery format" value={DELIVERY_FORMAT_LABELS[group.delivery_format] ?? group.delivery_format} />
        <Kv label="Schedule" value={group.schedule_pattern || "—"} />
        <Kv label="Age range" value={group.age_range || "—"} />
        <Kv
          label="School-year calendar"
          value={group.school_year_calendar_link ? "Open link" : "—"}
          href={group.school_year_calendar_link ?? undefined}
          external
        />
        {/* "Confirmed" here is the CONTRACT-TIME headcount (per enrollment,
            at signup) — distinct from each session's own "Present" count
            below (who actually showed up to THAT occurrence). Two
            different attendance concepts already existed as separate
            fields (children_confirmed here, sessions.attendance_count per
            session below) -- investigated per Anca's request, confirmed
            this already covers "contract-time confirmed vs. post-workshop
            actual-present", so only the labeling changed, no new column. */}
        <Kv label="Children confirmed (per contract)" value={group.children_confirmed?.toString() ?? "—"} />
        <Kv label="Children billed" value={group.children_billed?.toString() ?? "—"} />
        <Kv label="Notes" value={group.notes || "—"} />
      </Section>

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

function Section({ title, children }: { title: string; children: React.ReactNode }) {
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
  href,
  external,
}: {
  label: string;
  value: string;
  href?: string;
  external?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      {href ? (
        <a
          href={href}
          target={external ? "_blank" : undefined}
          rel={external ? "noreferrer" : undefined}
          className="text-brand-pink font-body font-medium hover:underline"
        >
          {value}
        </a>
      ) : (
        <span className="font-body text-ink font-medium">{value}</span>
      )}
    </div>
  );
}

function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink" ? "bg-brand-pink/10 text-brand-pink" : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
