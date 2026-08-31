-- 202608310002_payment_config_tables.sql
-- Payment configuration tables -- step from
-- docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md Sec12.8/Sec12.9. Five
-- policy grids (header + rows each, per Sec12.9's versioned-grid
-- decision), plus trainer_grade_assignments (the per-trainer history
-- Sec12.9 explicitly separates from the grids). All administered by
-- Finance -- Anca's explicit requirement is that changing an amount must
-- never require a code deploy.
--
-- Same predicate on all ten grid tables, confirmed live before writing
-- this (not assumed), matching trainer_contracts' own predicate (Sec5),
-- not suppliers' narrower one -- suppliers deliberately excludes Laura;
-- these grids feed trainer payment, which Laura owns day to day:
--
--   app.is_platform_owner()
--   or app.has_capability('finance.operations.*', organization_id)
--   or app.has_capability('finance.reporting.*', organization_id)
--
-- Resolves to exactly {finance_operations (Laura), finance_admin_reporting
-- (Anka), organization_owner (Anca), platform_owner} -- checked against
-- role_capabilities, not assumed. contract_administrator holds neither
-- key, checked and excluded, same discipline as Sec7.2.
--
-- SELECT + INSERT only. No UPDATE, no DELETE, on any of the eleven tables
-- here. This is a refinement on an earlier proposal (which granted
-- UPDATE): a version is supposed to be one atomic, nameable unit (Sec12.9)
-- -- if UPDATE were allowed, "was this version edited after the fact" is
-- a question that shouldn't have a "yes" answer, ever, for a financial
-- policy grid whose whole purpose is not to rewrite history silently. A
-- mistake gets corrected by inserting a new version, full stop, the same
-- way trainer_grade_assignments (below) has no closing step because a new
-- row always supersedes by being newer. No UPDATE also means no
-- updated_at column on any of these eleven tables -- it would only ever
-- equal created_at, so it isn't here.
--
-- row_history auditing is still attached to all eleven tables below, even
-- though no UPDATE/DELETE is granted to authenticated: defense in depth
-- for financial policy data, consistent with every other 🔒-audited table
-- in this SAD (suppliers, trainer_contracts, supplier_contracts). It will
-- not fire under normal application use; it exists for the day someone
-- with elevated access changes a row directly.
--
-- organization_id is denormalized onto every *_rates (child) table, not
-- resolved via a join to its *_versions parent -- matching client_contacts'
-- own precedent (a child table carrying its own organization_id rather
-- than requiring every RLS predicate to join up to its parent). Trusted,
-- not DB-enforced, to match whatever organization_id its own version row
-- carries -- the version-creation action inserts header and rows in one
-- transaction, the same way contracts.organization_id and
-- contracts.client_id aren't cross-validated by a trigger either.

-- ============================================================================
-- 1. trainer_grades
-- ============================================================================

create table public.trainer_grade_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint trainer_grade_versions_org_date_unique unique (organization_id, effective_date)
);

-- Six levels (Sec12.2) -- not seven, corrected from an earlier version of
-- the SAD that assumed lesson plans were a seventh grade. They are not
-- (Sec12.3): a separate, flat-rate work type, not represented anywhere in
-- this table.
create table public.trainer_grade_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.trainer_grade_versions(id),
  grade_level     integer not null,
  rate            numeric not null,
  constraint trainer_grade_rates_level_check check (grade_level between 1 and 6),
  constraint trainer_grade_rates_version_level_unique unique (version_id, grade_level)
);

create trigger trainer_grade_versions_row_history
  before delete or update on public.trainer_grade_versions
  for each row execute function row_history_capture();

create trigger trainer_grade_rates_row_history
  before delete or update on public.trainer_grade_rates
  for each row execute function row_history_capture();

alter table public.trainer_grade_versions enable row level security;
alter table public.trainer_grade_rates enable row level security;

create policy "authenticated select trainer_grade_versions" on public.trainer_grade_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert trainer_grade_versions" on public.trainer_grade_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select trainer_grade_rates" on public.trainer_grade_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert trainer_grade_rates" on public.trainer_grade_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.trainer_grade_versions to authenticated;
grant select, insert on public.trainer_grade_rates to authenticated;

-- ============================================================================
-- 2. location_bonuses
-- ============================================================================

create table public.location_bonus_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint location_bonus_versions_org_date_unique unique (organization_id, effective_date)
);

-- location_tier is the RESOLVED tier for a given session (Sec12.5's
-- correction: recorded per-session by whoever enters it, not derived from
-- a stored trainer home city -- see sessions.location_tier,
-- 202608310001). This table is just the bonus percentage per tier; it has
-- no opinion on how the tier was decided.
create table public.location_bonus_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.location_bonus_versions(id),
  location_tier   text not null,
  bonus_percent   numeric not null,
  constraint location_bonus_rates_tier_check check (location_tier in ('bucuresti', 'imprejurimi', 'alte_orase')),
  constraint location_bonus_rates_version_tier_unique unique (version_id, location_tier)
);

create trigger location_bonus_versions_row_history
  before delete or update on public.location_bonus_versions
  for each row execute function row_history_capture();

create trigger location_bonus_rates_row_history
  before delete or update on public.location_bonus_rates
  for each row execute function row_history_capture();

alter table public.location_bonus_versions enable row level security;
alter table public.location_bonus_rates enable row level security;

create policy "authenticated select location_bonus_versions" on public.location_bonus_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert location_bonus_versions" on public.location_bonus_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select location_bonus_rates" on public.location_bonus_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert location_bonus_rates" on public.location_bonus_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.location_bonus_versions to authenticated;
grant select, insert on public.location_bonus_rates to authenticated;

-- ============================================================================
-- 3. language_bonuses
-- ============================================================================

create table public.language_bonus_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint language_bonus_versions_org_date_unique unique (organization_id, effective_date)
);

create table public.language_bonus_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.language_bonus_versions(id),
  language_group  text not null,
  bonus_percent   numeric not null,
  constraint language_bonus_rates_group_check check (language_group in ('ro_en', 'fr_de_es')),
  constraint language_bonus_rates_version_group_unique unique (version_id, language_group)
);

create trigger language_bonus_versions_row_history
  before delete or update on public.language_bonus_versions
  for each row execute function row_history_capture();

create trigger language_bonus_rates_row_history
  before delete or update on public.language_bonus_rates
  for each row execute function row_history_capture();

alter table public.language_bonus_versions enable row level security;
alter table public.language_bonus_rates enable row level security;

create policy "authenticated select language_bonus_versions" on public.language_bonus_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert language_bonus_versions" on public.language_bonus_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select language_bonus_rates" on public.language_bonus_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert language_bonus_rates" on public.language_bonus_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.language_bonus_versions to authenticated;
grant select, insert on public.language_bonus_rates to authenticated;

-- ============================================================================
-- 4. duration_multipliers
-- ============================================================================

create table public.duration_multiplier_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint duration_multiplier_versions_org_date_unique unique (organization_id, effective_date)
);

-- duration_minutes is constrained to (30,60,90,120) -- confirmed against
-- the session form's actual dropdown
-- (app/(app)/groups/[id]/group-detail-client.tsx's NewSessionForm has
-- exactly these four <option> values, nothing else) at the time this
-- migration was written, not assumed.
--
-- Naming this coupling explicitly, per instruction, whether or not the
-- CHECK stays: nothing ties this CHECK to that dropdown except this
-- comment. If someone adds a fifth duration option to the session form
-- without a migration widening duration_multiplier_rates_minutes_check,
-- two things happen, both loud, neither at the point the option was
-- added: Finance cannot insert a rates row for the new duration (rejected
-- insert, needs explaining to whoever hits it), and every session entered
-- with that duration fails app.resolve_duration_multiplier (Sec12.9's
-- fail-loud requirement, working as designed) at payment-calculation
-- time, not at data-entry time -- by which point a number of sessions may
-- already have been entered with the new duration. The CHECK stays
-- anyway: the alternative is Finance able to enter a rate for a duration
-- no session will ever have, or a typo'd value, with nothing to catch it.
-- Between a loud failure when the two drift and silent garbage in the
-- policy table, the CHECK is the better failure mode -- but it is a
-- coupling, not a coincidence, and whoever touches the dropdown needs to
-- know this comment exists.
--
-- delivery_context carries the Scoala Altfel / Saptamana Verde 2h
-- exception (Sec12.6): ×2 instead of ×1.5, itself a Finance-editable
-- number, not a hardcoded resolver constant -- so it is a second row per
-- version at 120 minutes, not a special case in the function. In
-- practice, only the 120-minute duration will ever have two rows
-- (standard, scoala_altfel_saptamana_verde) per version; 30/60/90 have
-- one each. Nothing enforces "only 120 gets a second context" -- there is
-- no confirmed need for one on the shorter durations, so it isn't
-- constrained shut here, only documented.
create table public.duration_multiplier_rates (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  version_id        uuid not null references public.duration_multiplier_versions(id),
  duration_minutes  integer not null,
  delivery_context  text not null default 'standard',
  multiplier        numeric not null,
  constraint duration_multiplier_rates_minutes_check check (duration_minutes in (30, 60, 90, 120)),
  constraint duration_multiplier_rates_context_check check (delivery_context in ('standard', 'scoala_altfel_saptamana_verde')),
  constraint duration_multiplier_rates_version_key_unique unique (version_id, duration_minutes, delivery_context)
);

create trigger duration_multiplier_versions_row_history
  before delete or update on public.duration_multiplier_versions
  for each row execute function row_history_capture();

create trigger duration_multiplier_rates_row_history
  before delete or update on public.duration_multiplier_rates
  for each row execute function row_history_capture();

alter table public.duration_multiplier_versions enable row level security;
alter table public.duration_multiplier_rates enable row level security;

create policy "authenticated select duration_multiplier_versions" on public.duration_multiplier_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert duration_multiplier_versions" on public.duration_multiplier_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select duration_multiplier_rates" on public.duration_multiplier_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert duration_multiplier_rates" on public.duration_multiplier_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.duration_multiplier_versions to authenticated;
grant select, insert on public.duration_multiplier_rates to authenticated;

-- ============================================================================
-- 5. contract_type_uplifts
-- ============================================================================

create table public.contract_type_uplift_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint contract_type_uplift_versions_org_date_unique unique (organization_id, effective_date)
);

-- contract_type vocabulary matches trainer_contracts.contract_type
-- (Sec3.2) as of this migration: pfa, srl, drepturi_autor. Liberal
-- professions (medici, biologi) are still open (Sec12.10) -- when that's
-- confirmed, both this CHECK and trainer_contracts.contract_type's own
-- need widening together, in one migration. Same coupling risk as
-- duration_minutes above, named for the same reason.
create table public.contract_type_uplift_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.contract_type_uplift_versions(id),
  contract_type   text not null,
  uplift_percent  numeric not null,
  constraint contract_type_uplift_rates_type_check check (contract_type in ('pfa', 'srl', 'drepturi_autor')),
  constraint contract_type_uplift_rates_version_type_unique unique (version_id, contract_type)
);

create trigger contract_type_uplift_versions_row_history
  before delete or update on public.contract_type_uplift_versions
  for each row execute function row_history_capture();

create trigger contract_type_uplift_rates_row_history
  before delete or update on public.contract_type_uplift_rates
  for each row execute function row_history_capture();

alter table public.contract_type_uplift_versions enable row level security;
alter table public.contract_type_uplift_rates enable row level security;

create policy "authenticated select contract_type_uplift_versions" on public.contract_type_uplift_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert contract_type_uplift_versions" on public.contract_type_uplift_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select contract_type_uplift_rates" on public.contract_type_uplift_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert contract_type_uplift_rates" on public.contract_type_uplift_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.contract_type_uplift_versions to authenticated;
grant select, insert on public.contract_type_uplift_rates to authenticated;

-- ============================================================================
-- 6. trainer_grade_assignments -- per-trainer history, NOT a versioned
-- grid (Sec12.9). One row per trainer per grade change, superseded by
-- recency, no closing step. Signing a contract seeds the first row from
-- trainer_contracts.initial_grade_level (Sec3.2) -- that seeding is an
-- application-layer responsibility of the contract-signing action, not a
-- trigger here, matching this schema's general preference for explicit
-- action-layer writes over implicit trigger side effects on unrelated
-- tables.
-- ============================================================================

create table public.trainer_grade_assignments (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  trainer_id        uuid not null references public.users(id),
  grade_level       integer not null,
  effective_from    date not null,
  set_by            uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  constraint trainer_grade_assignments_level_check check (grade_level between 1 and 6),
  constraint trainer_grade_assignments_trainer_date_unique unique (trainer_id, effective_from)
);

create trigger trainer_grade_assignments_row_history
  before delete or update on public.trainer_grade_assignments
  for each row execute function row_history_capture();

alter table public.trainer_grade_assignments enable row level security;

-- 🔒 Masked by row visibility, not by a separate masking function: unlike
-- trainer_contracts (where Catalina needs some columns but not rate),
-- nothing on this table has a partial-visibility need -- it's the whole
-- row or nothing. A trainer's own grade is as sensitive as a rate
-- (Sec5/Sec12.9: grade + grid access reveals the rate), so SELECT allows
-- the trainer's own row, same as trainer_contracts' own-row branch.
--
-- INSERT is deliberately narrower than SELECT -- no own-row branch. A
-- trainer must never be able to write their own grade classification,
-- even though they can read it. This asymmetry is intentional, not an
-- oversight: the own-row read exists so trainers stop asking on WhatsApp
-- what grade they're at (Sec5's own reasoning for trainer_contracts),
-- not so they can set it.
create policy "authenticated select trainer_grade_assignments" on public.trainer_grade_assignments
  for select to authenticated
  using (
    trainer_id = app.current_user_id()
    or app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert trainer_grade_assignments" on public.trainer_grade_assignments
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.trainer_grade_assignments to authenticated;

-- ============================================================================
-- 7. Resolvers -- app.resolve_*(organization_id, ..., as_of date).
--
-- LANGUAGE plpgsql, a deliberate break from every existing app schema
-- function (all seven of which are LANGUAGE sql): a plain SQL function
-- resolving zero rows just returns NULL, silently -- correct for the
-- existing masking functions (NULL legitimately means "you can't see
-- this"), wrong here, where NULL would mean "no rate exists for this
-- date", a data-integrity failure that must stop the calculation
-- (Sec12.9). RAISE EXCEPTION requires plpgsql.
--
-- SECURITY INVOKER (the default -- no SECURITY DEFINER), also deliberate,
-- and a reversal from an earlier proposal that suggested DEFINER to match
-- the two masking functions. Those two are designed to be called by
-- anyone and decide internally what to reveal (their own
-- belongs_to_org/has_capability check gates the row(...) they return).
-- These six resolvers have no such internal check -- they just return
-- the stored value. SECURITY DEFINER on a function with no internal
-- authorization check would let any caller reconstruct the entire grid
-- (call with every grade_level/tier/date combination, read the values
-- back) regardless of their own SELECT rights on the underlying tables --
-- exactly the row-level protection above, bypassed through the function.
-- SECURITY INVOKER means only a caller who could already SELECT the
-- underlying row gets a real answer; anyone else's call finds zero rows
-- and hits the same RAISE as a genuine gap -- safe (an error, not a
-- leak), if not a maximally informative error for that caller. A future
-- calculation module that needs to run for a wider audience (e.g. a
-- trainer previewing their own estimated pay) is a separate, later
-- decision requiring its own embedded capability check -- not assumed
-- here.
--
-- Two-step resolution, not one join, in every resolver below: first find
-- the version effective on or before the date, THEN look up the specific
-- key within that one version. A single join across both tables, ordered
-- by version date and limited to one row, would silently fall back to an
-- older version's row for a key missing from the latest version -- masking
-- a real data-entry bug (a version created without all its rows) as a
-- normal historical lookup. Two steps means that specific failure gets
-- its own, distinct exception message instead of quietly resolving to
-- stale data.
--
-- Every RAISE EXCEPTION message below is developer-facing and stays
-- English, unconditionally -- it names internal identifiers (table names,
-- uuids) a Finance user should never see raw. Any caller surfacing this
-- to a Finance user must catch it and substitute a curated, translated
-- (EN+RO, via the app's existing i18n dict/t() pattern) message -- never
-- pass this text through to the UI. That catch-and-translate step belongs
-- to whatever calls these functions (the calculation module, not yet
-- built); it is not implemented here.
-- ============================================================================

create or replace function app.resolve_trainer_grade(p_trainer_id uuid, p_as_of date)
returns integer
language plpgsql
stable
set search_path to ''
as $$
declare
  v_grade_level integer;
begin
  select grade_level into v_grade_level
  from public.trainer_grade_assignments
  where trainer_id = p_trainer_id
    and effective_from <= p_as_of
  order by effective_from desc
  limit 1;

  if v_grade_level is null then
    raise exception 'app.resolve_trainer_grade: no trainer_grade_assignments row for trainer % on or before %', p_trainer_id, p_as_of;
  end if;

  return v_grade_level;
end;
$$;

create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_rate numeric;
begin
  select id into v_version_id
  from public.trainer_grade_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_trainer_grade_rate: no trainer_grade_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate
  from public.trainer_grade_rates
  where version_id = v_version_id
    and grade_level = p_grade_level;

  if v_rate is null then
    raise exception 'app.resolve_trainer_grade_rate: version % has no row for grade level % -- incomplete version', v_version_id, p_grade_level;
  end if;

  return v_rate;
end;
$$;

create or replace function app.resolve_location_bonus(p_organization_id uuid, p_location_tier text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_bonus numeric;
begin
  select id into v_version_id
  from public.location_bonus_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_location_bonus: no location_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select bonus_percent into v_bonus
  from public.location_bonus_rates
  where version_id = v_version_id
    and location_tier = p_location_tier;

  if v_bonus is null then
    raise exception 'app.resolve_location_bonus: version % has no row for tier % -- incomplete version', v_version_id, p_location_tier;
  end if;

  return v_bonus;
end;
$$;

create or replace function app.resolve_language_bonus(p_organization_id uuid, p_language_group text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_bonus numeric;
begin
  select id into v_version_id
  from public.language_bonus_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_language_bonus: no language_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select bonus_percent into v_bonus
  from public.language_bonus_rates
  where version_id = v_version_id
    and language_group = p_language_group;

  if v_bonus is null then
    raise exception 'app.resolve_language_bonus: version % has no row for language group % -- incomplete version', v_version_id, p_language_group;
  end if;

  return v_bonus;
end;
$$;

-- p_delivery_format is the group's raw delivery_format value (Sec12.6) --
-- the caller passes what's already on the row, not a pre-translated
-- context. The scoala_altfel/saptamana_verde -> extended-context mapping
-- lives here, once, rather than in every caller.
create or replace function app.resolve_duration_multiplier(p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_context text;
  v_multiplier numeric;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  select id into v_version_id
  from public.duration_multiplier_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select multiplier into v_multiplier
  from public.duration_multiplier_rates
  where version_id = v_version_id
    and duration_minutes = p_duration_minutes
    and delivery_context = v_context;

  if v_multiplier is null then
    raise exception 'app.resolve_duration_multiplier: version % has no row for % minutes / context % -- incomplete version', v_version_id, p_duration_minutes, v_context;
  end if;

  return v_multiplier;
end;
$$;

create or replace function app.resolve_contract_type_uplift(p_organization_id uuid, p_contract_type text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_uplift numeric;
begin
  select id into v_version_id
  from public.contract_type_uplift_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_contract_type_uplift: no contract_type_uplift_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select uplift_percent into v_uplift
  from public.contract_type_uplift_rates
  where version_id = v_version_id
    and contract_type = p_contract_type;

  if v_uplift is null then
    raise exception 'app.resolve_contract_type_uplift: version % has no row for contract type % -- incomplete version', v_version_id, p_contract_type;
  end if;

  return v_uplift;
end;
$$;

-- Least-privilege exposure, matching app schema's plain-helper-function
-- convention exactly (not the masking-function convention -- these are
-- SECURITY INVOKER, owned by whoever runs this migration, no
-- app_masking_owner ownership dance needed, unlike trap 5.7's functions).
revoke all on function app.resolve_trainer_grade(uuid, date) from public;
revoke all on function app.resolve_trainer_grade_rate(uuid, integer, date) from public;
revoke all on function app.resolve_location_bonus(uuid, text, date) from public;
revoke all on function app.resolve_language_bonus(uuid, text, date) from public;
revoke all on function app.resolve_duration_multiplier(uuid, integer, text, date) from public;
revoke all on function app.resolve_contract_type_uplift(uuid, text, date) from public;

grant execute on function app.resolve_trainer_grade(uuid, date) to authenticated, service_role;
grant execute on function app.resolve_trainer_grade_rate(uuid, integer, date) to authenticated, service_role;
grant execute on function app.resolve_location_bonus(uuid, text, date) to authenticated, service_role;
grant execute on function app.resolve_language_bonus(uuid, text, date) to authenticated, service_role;
grant execute on function app.resolve_duration_multiplier(uuid, integer, text, date) to authenticated, service_role;
grant execute on function app.resolve_contract_type_uplift(uuid, text, date) to authenticated, service_role;
