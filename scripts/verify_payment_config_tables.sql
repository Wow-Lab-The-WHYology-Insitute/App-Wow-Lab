-- verify_payment_config_tables.sql
-- Dry-run verification for
-- supabase/migrations/202608310002_payment_config_tables.sql, per
-- docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Multi-role, multi-phase: unlike a single-table column migration, this
-- one lives or dies on RLS actually distinguishing Finance from everyone
-- else, and on the resolvers actually failing loud rather than silently
-- resolving to a stale value. Each phase switches identity via
-- set local role + request.jwt.claims (transaction-scoped, safe to repeat)
-- and appends to a report carried across phases via set_config, since a
-- single do-block can't hold multiple role switches itself.
--
-- Run with: supabase db query --linked --file scripts/verify_payment_config_tables.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608310002's DDL exactly.
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

create table public.location_bonus_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint location_bonus_versions_org_date_unique unique (organization_id, effective_date)
);

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

create table public.duration_multiplier_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint duration_multiplier_versions_org_date_unique unique (organization_id, effective_date)
);

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

create table public.contract_type_uplift_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint contract_type_uplift_versions_org_date_unique unique (organization_id, effective_date)
);

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

create or replace function app.resolve_trainer_grade(p_trainer_id uuid, p_as_of date)
returns integer
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

create or replace function app.resolve_location_bonus(p_organization_id uuid, p_location_tier text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

create or replace function app.resolve_language_bonus(p_organization_id uuid, p_language_group text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

create or replace function app.resolve_duration_multiplier(p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

create or replace function app.resolve_contract_type_uplift(p_organization_id uuid, p_contract_type text, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $body$
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
$body$;

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

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures.
-- ============================================================================

select set_config('app.org', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.finance_ops', (select id::text from users where email = 'test+finance-ops-a@wowlab.dev'), true);
select set_config('app.finance_admin', (select id::text from users where email = 'test+finance-admin-a@wowlab.dev'), true);
select set_config('app.trainer', (select id::text from users where email = 'test+trainer-a@wowlab.dev'), true);
select set_config('app.ops_manager', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.report', '', true);

-- ============================================================================
-- PHASE 2 -- as Laura-equivalent (finance_operations). Build the happy
-- path: one version + full rows per grid, one grade assignment. Then the
-- two failure-mode assertions that matter most: a genuine gap, and an
-- incomplete version (the reason this migration resolves in two steps,
-- not one join -- see the migration's own comment).
-- ============================================================================

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.finance_ops'), 'role', 'authenticated')::text, true);

do $phase2$
declare
  report text := current_setting('app.report');
  v_org uuid := current_setting('app.org')::uuid;
  v_trainer uuid := current_setting('app.trainer')::uuid;
  v_finance_ops uuid := current_setting('app.finance_ops')::uuid;
  v_grade_v1 uuid;
  v_grade_v2 uuid;
  v_loc_v uuid;
  v_lang_v uuid;
  v_dur_v uuid;
  v_uplift_v uuid;
  v_rate numeric;
  v_bonus numeric;
  v_mult numeric;
  v_uplift numeric;
  v_grade integer;
  v_caught boolean;
begin
  -- ---- build one complete version per grid, dated 60 days ago ----
  insert into trainer_grade_versions (organization_id, effective_date, created_by)
    values (v_org, current_date - 60, v_finance_ops) returning id into v_grade_v1;
  insert into trainer_grade_rates (organization_id, version_id, grade_level, rate) values
    (v_org, v_grade_v1, 1, 30), (v_org, v_grade_v1, 2, 40), (v_org, v_grade_v1, 3, 50),
    (v_org, v_grade_v1, 4, 60), (v_org, v_grade_v1, 5, 70), (v_org, v_grade_v1, 6, 80);

  insert into location_bonus_versions (organization_id, effective_date, created_by)
    values (v_org, current_date - 60, v_finance_ops) returning id into v_loc_v;
  insert into location_bonus_rates (organization_id, version_id, location_tier, bonus_percent) values
    (v_org, v_loc_v, 'bucuresti', 0), (v_org, v_loc_v, 'imprejurimi', 50), (v_org, v_loc_v, 'alte_orase', 100);

  insert into language_bonus_versions (organization_id, effective_date, created_by)
    values (v_org, current_date - 60, v_finance_ops) returning id into v_lang_v;
  insert into language_bonus_rates (organization_id, version_id, language_group, bonus_percent) values
    (v_org, v_lang_v, 'ro_en', 0), (v_org, v_lang_v, 'fr_de_es', 20);

  insert into duration_multiplier_versions (organization_id, effective_date, created_by)
    values (v_org, current_date - 60, v_finance_ops) returning id into v_dur_v;
  insert into duration_multiplier_rates (organization_id, version_id, duration_minutes, delivery_context, multiplier) values
    (v_org, v_dur_v, 30, 'standard', 1.0), (v_org, v_dur_v, 60, 'standard', 1.0),
    (v_org, v_dur_v, 90, 'standard', 1.2), (v_org, v_dur_v, 120, 'standard', 1.5),
    (v_org, v_dur_v, 120, 'scoala_altfel_saptamana_verde', 2.0);

  insert into contract_type_uplift_versions (organization_id, effective_date, created_by)
    values (v_org, current_date - 60, v_finance_ops) returning id into v_uplift_v;
  insert into contract_type_uplift_rates (organization_id, version_id, contract_type, uplift_percent) values
    (v_org, v_uplift_v, 'pfa', 11.1), (v_org, v_uplift_v, 'srl', 11.1), (v_org, v_uplift_v, 'drepturi_autor', 0);

  insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by)
    values (v_org, v_trainer, 1, current_date - 60, v_finance_ops);

  report := report || E'\n2a. PASS - one complete version + full rows inserted for all five grids, plus one trainer_grade_assignments row, all as finance_operations';

  -- ---- resolvers return the right values ----
  v_grade := app.resolve_trainer_grade(v_trainer, current_date);
  v_rate := app.resolve_trainer_grade_rate(v_org, v_grade, current_date);
  v_bonus := app.resolve_location_bonus(v_org, 'alte_orase', current_date);
  v_mult := app.resolve_duration_multiplier(v_org, 120, 'scoala_altfel', current_date);
  v_uplift := app.resolve_contract_type_uplift(v_org, 'pfa', current_date);

  if v_grade = 1 and v_rate = 30 and v_bonus = 100 and v_mult = 2.0 and v_uplift = 11.1 then
    report := report || E'\n2b. PASS - resolvers return correct values: grade=1, rate=30, location_bonus(alte_orase)=100, duration_multiplier(120,scoala_altfel)=2.0 (the exception path, not 1.5), uplift(pfa)=11.1';
  else
    report := report || format(E'\n2b. FAIL - got grade=%s rate=%s bonus=%s mult=%s uplift=%s', v_grade, v_rate, v_bonus, v_mult, v_uplift);
  end if;

  -- ---- duration_multiplier: same 120 minutes, standard context, must be 1.5 not 2.0 ----
  v_mult := app.resolve_duration_multiplier(v_org, 120, 'recurring', current_date);
  if v_mult = 1.5 then
    report := report || E'\n2c. PASS - duration_multiplier(120,recurring)=1.5 -- the exception is keyed to delivery_format, not duration alone';
  else
    report := report || format(E'\n2c. FAIL - expected 1.5 for (120,recurring), got %s', v_mult);
  end if;

  -- ---- genuine gap: a date before any version exists ----
  begin
    v_bonus := app.resolve_location_bonus(v_org, 'alte_orase', current_date - 3650);
    report := report || E'\n2d. FAIL - expected an exception resolving a date 10 years before any version, got a value instead';
  exception
    when others then
      report := report || format(E'\n2d. PASS - resolving 10 years before any version raised: %s', sqlerrm);
  end;

  -- ---- incomplete version: a second, later version missing one row,
  -- must fail distinctly, not silently fall back to v1's row for that key ----
  insert into trainer_grade_versions (organization_id, effective_date, created_by)
    values (v_org, current_date, v_finance_ops) returning id into v_grade_v2;
  insert into trainer_grade_rates (organization_id, version_id, grade_level, rate) values
    (v_org, v_grade_v2, 1, 35), (v_org, v_grade_v2, 2, 45), (v_org, v_grade_v2, 3, 55),
    (v_org, v_grade_v2, 4, 65), (v_org, v_grade_v2, 5, 75);
    -- grade_level 6 deliberately omitted from v2

  v_caught := false;
  begin
    v_rate := app.resolve_trainer_grade_rate(v_org, 6, current_date);
  exception
    when others then
      v_caught := true;
      if sqlerrm like '%incomplete version%' and sqlerrm like format('%%%s%%', v_grade_v2) then
        report := report || format(E'\n2e. PASS - grade 6 as of today resolved to the NEW version %s (correct -- it is the latest), then failed on THAT version''s missing row, not a silent fallback to v1''s grade-6 rate of 80: %s', v_grade_v2, sqlerrm);
      else
        report := report || format(E'\n2e. FAIL - exception raised but not the expected one: %s', sqlerrm);
      end if;
  end;
  if not v_caught then
    report := report || E'\n2e. FAIL - expected an exception for grade 6 against the incomplete v2 version, got a value instead (silent fallback to an older version would be exactly the bug this two-step design exists to prevent)';
  end if;

  -- grade 1 still resolves correctly against v2 (the row that IS there)
  v_rate := app.resolve_trainer_grade_rate(v_org, 1, current_date);
  if v_rate = 35 then
    report := report || E'\n2f. PASS - grade 1 as of today correctly resolves to v2''s rate (35), not v1''s stale 30';
  else
    report := report || format(E'\n2f. FAIL - expected 35 from v2, got %s', v_rate);
  end if;

  perform set_config('app.report', report, true);
end;
$phase2$;

-- ============================================================================
-- PHASE 3 -- as Anka-equivalent (finance_admin_reporting). Confirms the
-- OTHER branch of the shared predicate also sees everything Laura's
-- branch inserted -- not just "some capability worked", but specifically
-- finance.reporting.* on its own.
-- ============================================================================

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.finance_admin'), 'role', 'authenticated')::text, true);

do $phase3$
declare
  report text := current_setting('app.report');
  v_org uuid := current_setting('app.org')::uuid;
  v_count int;
begin
  select count(*) into v_count from trainer_grade_rates where organization_id = v_org;
  if v_count = 11 then -- 6 (v1) + 5 (v2)
    report := report || E'\n3. PASS - finance_admin_reporting (Anka-equivalent) sees all 11 trainer_grade_rates rows via the reporting branch of the shared predicate, without ever using finance.operations.*';
  else
    report := report || format(E'\n3. FAIL - expected 11 visible rows, finance_admin_reporting saw %s', v_count);
  end if;
  perform set_config('app.report', report, true);
end;
$phase3$;

-- ============================================================================
-- PHASE 4 -- as the trainer whose grade this all describes. Own-row read
-- allowed; everything else, including writing their own grade, is not.
-- ============================================================================

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.trainer'), 'role', 'authenticated')::text, true);

do $phase4$
declare
  report text := current_setting('app.report');
  v_org uuid := current_setting('app.org')::uuid;
  v_trainer uuid := current_setting('app.trainer')::uuid;
  v_own_count int;
  v_grid_count int;
  v_insert_blocked boolean := false;
begin
  select count(*) into v_own_count from trainer_grade_assignments where trainer_id = v_trainer;
  if v_own_count = 1 then
    report := report || E'\n4a. PASS - the trainer can read their own trainer_grade_assignments row';
  else
    report := report || format(E'\n4a. FAIL - expected 1 own row visible, trainer saw %s', v_own_count);
  end if;

  select count(*) into v_grid_count from trainer_grade_rates;
  if v_grid_count = 0 then
    report := report || E'\n4b. PASS - the trainer sees zero trainer_grade_rates rows -- cannot browse the pay grid';
  else
    report := report || format(E'\n4b. FAIL - expected the whole grid hidden, trainer saw %s rows', v_grid_count);
  end if;

  begin
    insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by)
      values (v_org, v_trainer, 6, current_date, v_trainer);
    report := report || E'\n4c. FAIL - the trainer successfully self-assigned grade 6, expected a policy rejection';
  exception
    when insufficient_privilege then
      v_insert_blocked := true;
      report := report || E'\n4c. PASS - the trainer cannot insert their own trainer_grade_assignments row (RLS 42501), even though they can read it';
  end;

  perform set_config('app.report', report, true);
end;
$phase4$;

-- ============================================================================
-- PHASE 5 -- as Catalina-equivalent (operations_manager). Allocates
-- trainers, reads contract validity elsewhere in this SAD -- has no
-- business here at all. Every one of the eleven tables must be invisible.
-- ============================================================================

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.ops_manager'), 'role', 'authenticated')::text, true);

do $phase5$
declare
  report text := current_setting('app.report');
  v_org uuid := current_setting('app.org')::uuid;
  v_total int;
  v_insert_blocked boolean := false;
begin
  select
    (select count(*) from trainer_grade_versions) +
    (select count(*) from trainer_grade_rates) +
    (select count(*) from location_bonus_versions) +
    (select count(*) from location_bonus_rates) +
    (select count(*) from language_bonus_versions) +
    (select count(*) from language_bonus_rates) +
    (select count(*) from duration_multiplier_versions) +
    (select count(*) from duration_multiplier_rates) +
    (select count(*) from contract_type_uplift_versions) +
    (select count(*) from contract_type_uplift_rates) +
    (select count(*) from trainer_grade_assignments)
  into v_total;

  if v_total = 0 then
    report := report || E'\n5a. PASS - operations_manager (Catalina-equivalent) sees zero rows across all eleven tables';
  else
    report := report || format(E'\n5a. FAIL - expected 0 visible rows across all eleven tables, operations_manager saw %s', v_total);
  end if;

  begin
    insert into location_bonus_versions (organization_id, effective_date, created_by)
      values (v_org, current_date, current_setting('app.ops_manager')::uuid);
    report := report || E'\n5b. FAIL - operations_manager successfully inserted a location_bonus_versions row, expected a policy rejection';
  exception
    when insufficient_privilege then
      v_insert_blocked := true;
      report := report || E'\n5b. PASS - operations_manager cannot insert into location_bonus_versions (RLS 42501)';
  end;

  perform set_config('app.report', report, true);
end;
$phase5$;

-- ============================================================================
-- FINAL -- surface the accumulated report and roll back everything.
-- ============================================================================

do $final$
begin
  raise exception E'VERIFICATION REPORT for 202608310002_payment_config_tables.sql (transaction WILL roll back -- nothing above was committed):%', current_setting('app.report');
end;
$final$;

rollback;
