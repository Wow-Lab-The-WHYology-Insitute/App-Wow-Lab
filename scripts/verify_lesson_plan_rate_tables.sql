-- verify_lesson_plan_rate_tables.sql
-- Dry-run verification for
-- supabase/migrations/202609020002_lesson_plan_rate_tables.sql, per
-- docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Mirrors 202609020002's DDL and seed exactly, then checks: both tables
-- carry the same RLS shape as the five existing grids, the seeded
-- version resolves to 120 for 2024-01-01 itself and for a later real
-- date (31.08.2026, one of the actual lesson-plan dates this rate needs
-- to cover), a date before 2024-01-01 raises rather than returning null
-- or falling back to anything, and the one-row-per-version constraint on
-- lesson_plan_rates actually rejects a second row for the same version.
--
-- Run with: supabase db query --linked --file scripts/verify_lesson_plan_rate_tables.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202609020002's DDL and seed exactly.
-- ============================================================================

create table public.lesson_plan_rate_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint lesson_plan_rate_versions_org_date_unique unique (organization_id, effective_date)
);

create table public.lesson_plan_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.lesson_plan_rate_versions(id),
  rate            numeric not null,
  constraint lesson_plan_rates_version_unique unique (version_id)
);

create trigger lesson_plan_rate_versions_row_history
  before delete or update on public.lesson_plan_rate_versions
  for each row execute function row_history_capture();

create trigger lesson_plan_rates_row_history
  before delete or update on public.lesson_plan_rates
  for each row execute function row_history_capture();

alter table public.lesson_plan_rate_versions enable row level security;
alter table public.lesson_plan_rates enable row level security;

create policy "authenticated select lesson_plan_rate_versions" on public.lesson_plan_rate_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert lesson_plan_rate_versions" on public.lesson_plan_rate_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select lesson_plan_rates" on public.lesson_plan_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert lesson_plan_rates" on public.lesson_plan_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.lesson_plan_rate_versions to authenticated;
grant select, insert on public.lesson_plan_rates to authenticated;

create or replace function app.resolve_lesson_plan_rate(p_organization_id uuid, p_as_of date)
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
  from public.lesson_plan_rate_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_lesson_plan_rate: no lesson_plan_rate_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate
  from public.lesson_plan_rates
  where version_id = v_version_id;

  if v_rate is null then
    raise exception 'app.resolve_lesson_plan_rate: version % has no rate row -- incomplete version', v_version_id;
  end if;

  return v_rate;
end;
$$;

revoke all on function app.resolve_lesson_plan_rate(uuid, date) from public;
grant execute on function app.resolve_lesson_plan_rate(uuid, date) to authenticated, service_role;

do $$
declare
  v_org uuid;
  v_anca uuid;
  v_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';

  insert into public.lesson_plan_rate_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2024-01-01', v_anca, 'Confirmed by Anca: 120 lei net per plan, unchanged since 2024.')
  returning id into v_version;

  insert into public.lesson_plan_rates (organization_id, version_id, rate)
  values (v_org, v_version, 120);

  perform set_config('app.seeded_version', v_version::text, true);
end $$;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_finance_ops', (select id::text from users where email = 'test+finance-ops-a@wowlab.dev'), true);

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_finance_ops'), 'role', 'authenticated')::text, true);

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_org uuid := current_setting('app.test_org_a')::uuid;
  v_seeded_version uuid := current_setting('app.seeded_version')::uuid;
  v_rls_count int;
  v_rate numeric;
  v_caught boolean;
  v_sqlstate text;
begin
  -- ---- 1. both tables exist with the five-grid RLS shape ----
  -- RLS enabled on both, and the SELECT policy's qual matches the exact
  -- three-branch predicate used on all five existing grids.
  select count(*) into v_rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('lesson_plan_rate_versions', 'lesson_plan_rates')
    and c.relrowsecurity = true;

  if v_rls_count = 2 then
    report := report || E'\n1a. PASS - both tables exist with row level security enabled';
  else
    report := report || format(E'\n1a. FAIL - expected RLS enabled on both tables, got %s', v_rls_count);
  end if;

  select count(*) into v_rls_count
  from pg_policies
  where schemaname = 'public'
    and tablename in ('lesson_plan_rate_versions', 'lesson_plan_rates')
    and cmd = 'SELECT'
    and qual = '(app.is_platform_owner() OR app.has_capability(''finance.operations.*''::text, organization_id) OR app.has_capability(''finance.reporting.*''::text, organization_id))';

  if v_rls_count = 2 then
    report := report || E'\n1b. PASS - both tables'' SELECT policy is byte-identical to the five existing grids'' predicate';
  else
    report := report || format(E'\n1b. FAIL - expected 2 matching SELECT policies, got %s', v_rls_count);
  end if;

  -- ---- 2a. seeded version resolves to 120 for 2024-01-01 itself ----
  v_rate := app.resolve_lesson_plan_rate(v_org, '2024-01-01'::date);
  if v_rate = 120 then
    report := report || E'\n2a. PASS - resolve_lesson_plan_rate(2024-01-01) = 120';
  else
    report := report || format(E'\n2a. FAIL - expected 120, got %s', v_rate);
  end if;

  -- ---- 2b. seeded version resolves to 120 for 31.08.2026, one of the
  -- actual lesson-plan dates this rate needs to cover ----
  v_rate := app.resolve_lesson_plan_rate(v_org, '2026-08-31'::date);
  if v_rate = 120 then
    report := report || E'\n2b. PASS - resolve_lesson_plan_rate(2026-08-31) = 120';
  else
    report := report || format(E'\n2b. FAIL - expected 120, got %s', v_rate);
  end if;

  -- ---- 3. a date before 2024-01-01 raises, not null, not a fallback ----
  v_caught := false;
  begin
    v_rate := app.resolve_lesson_plan_rate(v_org, '2023-12-31'::date);
  exception
    when others then
      v_caught := true;
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n3. PASS - resolve_lesson_plan_rate(2023-12-31) raised (sqlstate %s): %s', v_sqlstate, sqlerrm);
  end;
  if not v_caught then
    report := report || format(E'\n3. FAIL - expected an exception for a date before the earliest version, got a value instead: %s', v_rate);
  end if;

  -- ---- 4. one-row-per-version constraint holds ----
  begin
    insert into lesson_plan_rates (organization_id, version_id, rate)
    values (v_org, v_seeded_version, 999);
    report := report || E'\n4. FAIL - expected unique_violation inserting a second rate row for the same version, but the insert succeeded';
  exception
    when unique_violation then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n4. PASS - a second lesson_plan_rates row for the same version_id raised unique_violation (sqlstate %s)', v_sqlstate);
  end;

  raise exception E'VERIFICATION REPORT for 202609020002_lesson_plan_rate_tables.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
