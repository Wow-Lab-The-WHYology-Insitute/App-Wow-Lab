-- 202608130001_create_groups_sessions_domain_tables.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions).
-- Source: docs/WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md, §2.
--
-- Central decision (SAD §1): Grupă ≠ Sesiune. `groups` is the enrollment
-- container (who, which module, what recurring pattern); `sessions` is a
-- single dated occurrence with its own trainer allocation, attendance, and
-- delivered experiment. Per Anca's confirmed answer, trainer
-- principal/secundar rotates session-by-session, so that allocation lives
-- on `sessions`, never on `groups`.
--
-- Enum-shaped columns (module, delivery_format, status) are `text` with a
-- CHECK constraint, matching the existing style in this codebase
-- (clients.client_type, contracts.status, etc.) rather than a native
-- Postgres enum type.
--
-- attendance_count/experiment_delivered live directly on `sessions`, not as
-- separate child tables (SAD §2: 1:1 relationship with the session, numeric-
-- first attendance, no per-child roster today) -- same "don't create
-- entities you don't need yet" principle already applied in SAD Clients &
-- Contracts.
--
-- Per DATABASE_CONVENTIONS.md: uuid pk, organization_id tenancy anchor,
-- snake_case plural table names, created_at/updated_at +
-- trigger_set_updated_at, row_history audit trigger (both tables are
-- explicitly 🔒 audited per the SAD), RLS enabled+forced with NO policies
-- yet (deny-by-default -- policies land in 202608130003).
--
-- Idempotent: `create table if not exists`, triggers/RLS/indexes guarded
-- the same way as 202608100001.

-- ============================================================================
-- groups — the enrollment container.
-- ============================================================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  client_id uuid not null references public.clients(id),
  module text not null check (module in (
    'gaga', 'green_energy', 'wow_mix', 'tiktok', 'food_science',
    'lotions', 'magic_physics', 'chem_me', 'chem_hs', 'lights',
    'detective', 'astronomy', 'doctor'
  )),
  delivery_format text not null check (delivery_format in ('recurring', 'scoala_altfel', 'saptamana_verde', 'party', 'corporate', 'custom')),
  schedule_pattern text,
  children_confirmed int,
  children_billed int,
  status text not null default 'active' check (status in ('active', 'paused', 'ended')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.groups is 'AUDITED. Enrollment container (SAD Operational §1/§2) — who, which module, what recurring pattern. NOT the same as a session (an individual dated occurrence, see public.sessions). Record-level RLS: Trainer/Senior Trainer see only groups referenced by a session they are allocated to (principal or secundar) — see 202608130003.';
comment on column public.groups.module is 'One of the 13 (of 15) confirmed real curriculum modules -- keys taken verbatim from docs/mockup/wow_lab_os_mockup.html''s MODULES object (gaga, green_energy, wow_mix, tiktok, food_science, lotions, magic_physics, chem_me, chem_hs, lights, detective, astronomy, doctor), sourced from the real Wow Lab curriculum sheets per that file''s own comment, not guessed here. 2 modules remain unconfirmed and are deliberately excluded, matching the mockup''s own stance. Stored as text+CHECK, not a table FK -- no curriculum-module reference table exists yet in this app.';
comment on column public.groups.delivery_format is 'WORKING DECISION, risk accepted (SAD §3): split from "Tip atelier" into module + delivery_format is Mihai''s interpretation today, NOT explicitly confirmed by Anca. Flagged here so this assumption is never silently forgotten.';
comment on column public.groups.children_confirmed is 'Per contract, at enrollment time.';
comment on column public.groups.children_billed is 'Per actual delivery -- can differ from children_confirmed (SAD §2, confirmed from the prior curriculum taxonomy work).';

create index if not exists groups_organization_id_idx on public.groups(organization_id);
create index if not exists groups_client_id_idx on public.groups(client_id);
create index if not exists groups_module_idx on public.groups(module);

-- ============================================================================
-- sessions — a single dated occurrence, with its own trainer allocation.
-- ============================================================================
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  group_id uuid not null references public.groups(id),
  session_date date not null,
  trainer_principal_id uuid references public.users(id),
  trainer_secundar_id uuid references public.users(id),
  status text not null default 'planned' check (status in ('planned', 'delivered', 'cancelled')),
  attendance_count int,
  experiment_delivered text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.sessions is 'AUDITED. A single dated occurrence of a group (SAD Operational §1) -- own trainer allocation, own attendance, own delivered experiment. Trainer principal/secundar rotate session-by-session (Anca''s confirmed answer on trainer principal/secundar), so allocation lives here, never on groups. Record-level RLS: Trainer/Senior Trainer see ONLY sessions where they are trainer_principal_id or trainer_secundar_id -- see 202608130003.';
comment on column public.sessions.trainer_principal_id is 'Nullable -- a session can exist (e.g. just scheduled) before allocation happens. No role CHECK constraint at the DB level (matches assigned_by on user_org_roles, users.id-shaped FKs elsewhere) -- app code / RLS write policy is responsible for only allowing sensible allocations.';
comment on column public.sessions.trainer_secundar_id is 'Same as trainer_principal_id. Secundar role rotates with principal session-by-session per Anca''s answer -- NOT a fixed pairing.';
comment on column public.sessions.attendance_count is 'Numeric-first (SAD §2/§5) -- a single count, not a per-child roster. A future per-child attendance table (session_child_attendance) would be a genuinely new entity if ever required, not a change to this column.';
comment on column public.sessions.experiment_delivered is 'Free text for now (SAD §5) -- no FK to a lesson-plans table, since none exists yet as a real table in this app (mockup only).';

create index if not exists sessions_organization_id_idx on public.sessions(organization_id);
create index if not exists sessions_group_id_idx on public.sessions(group_id);
create index if not exists sessions_trainer_principal_id_idx on public.sessions(trainer_principal_id);
create index if not exists sessions_trainer_secundar_id_idx on public.sessions(trainer_secundar_id);

-- ============================================================================
-- updated_at triggers (DATABASE_CONVENTIONS.md #4).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'groups' and trigger_name = 'groups_set_updated_at'
  ) then
    create trigger groups_set_updated_at
      before update on public.groups
      for each row execute function public.trigger_set_updated_at();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'sessions' and trigger_name = 'sessions_set_updated_at'
  ) then
    create trigger sessions_set_updated_at
      before update on public.sessions
      for each row execute function public.trigger_set_updated_at();
  end if;
end;
$$;

-- ============================================================================
-- row_history audit triggers (DATABASE_CONVENTIONS.md #8: BEFORE UPDATE OR
-- DELETE -- NOT insert, matching every existing audited table, including
-- Clients & Contracts -- see 202608100001's own comment on this exact
-- point).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'groups' and trigger_name = 'groups_row_history'
  ) then
    create trigger groups_row_history
      before update or delete on public.groups
      for each row execute function public.row_history_capture();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'sessions' and trigger_name = 'sessions_row_history'
  ) then
    create trigger sessions_row_history
      before update or delete on public.sessions
      for each row execute function public.row_history_capture();
  end if;
end;
$$;

-- ============================================================================
-- RLS: enabled + forced, deny-by-default. NO policies here
-- (DATABASE_CONVENTIONS.md #7) -- policies land in 202608130003.
-- ============================================================================
alter table public.groups enable row level security;
alter table public.groups force row level security;

alter table public.sessions enable row level security;
alter table public.sessions force row level security;
