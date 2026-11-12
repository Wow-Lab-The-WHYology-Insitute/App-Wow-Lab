-- db/tests/grid_confirmed_pay_guard.sql
-- OPEN_ITEMS.md item 194 / 202611120001 -- what stays immutable is the pay a
-- confirmed, unapproved session resolves to, not the grid row it read.
--
-- Every refusal case is induced the way /payment-config writes: as the Test
-- Org B Finance Operations account, through RLS, via
-- public.rpc_create_grid_version. Every "must pass" case is induced the same
-- way, because a rule that also blocks the legitimate case is as bad as none.
-- Migration-style writes (postgres, no RPC) are induced separately.
--
-- The guard is a DEFERRED constraint trigger, and every block here rolls
-- back, so a block that writes without the RPC forces it with SET
-- CONSTRAINTS ALL IMMEDIATE -- otherwise it would never fire.
--
-- Fixture, created and rolled back in each block: one Test Org B session,
-- 15.09.2026, 120 min, group bda1f577 (parteneriate_companii -> 'standard'
-- duration context, language ro_en), trainer 82b99dfb (grade 2) as
-- principal, confirmed, not approved.

-- ============================================================================
-- Blocks 1-4: one per grid, through the RPC as the finance user.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', case when grade_level = 2 then rate + 1 else rate end))
    from public.trainer_grade_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date);
  insert into payload select 'same', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', rate))
    from public.trainer_grade_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date);
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'backdated', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload where k = 'changed'));
  insert into r select 'left', jsonb_build_object('n', (select count(*) from public.trainer_grade_versions where note = 'TEST guard'));
  insert into r select 'same', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard same', (select rows from payload where k = 'same'));
  insert into r select 'future', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, current_date + 1000, 'TEST guard future', (select rows from payload where k = 'changed'));
  select set_config('role', 'postgres', true);

  select 'grade: a backdated version re-pricing a confirmed slot is refused, through the RPC, as the finance user' as check_name,
         (select res->>'error' from r where k = 'backdated') as actual, 'would_change_confirmed_pay' as expected,
         (select res->>'error' from r where k = 'backdated') = 'would_change_confirmed_pay' as pass
  union all
  select 'grade: the refusal says how many confirmed sessions and in which months',
         (select (res->'detail'->>'sessions') || ' / ' || (res->'detail'->>'months') from r where k = 'backdated'), '>=1 / includes 2026-09',
         (select (res->'detail'->>'sessions')::int >= 1 and res->'detail'->'months' ? '2026-09' from r where k = 'backdated')
  union all
  select 'grade: nothing of the refused version is left behind',
         (select res->>'n' from r where k = 'left'), '0', (select res->>'n' from r where k = 'left') = '0'
  union all
  select 'grade: a backdated version with identical values passes (no confirmed pay changes)',
         (select res->>'ok' from r where k = 'same'), 'true', (select (res->>'ok')::boolean from r where k = 'same')
  union all
  select 'grade: a future-dated version with changed values passes (touches no confirmed session)',
         (select res->>'ok' from r where k = 'future'), 'true', (select (res->>'ok')::boolean from r where k = 'future');
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('duration_minutes', duration_minutes, 'delivery_context', delivery_context,
      'multiplier', case when duration_minutes = 120 and delivery_context = 'standard' then multiplier + 0.1 else multiplier end))
    from public.duration_multiplier_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', current_date);
  insert into payload select 'same', jsonb_agg(jsonb_build_object('duration_minutes', duration_minutes, 'delivery_context', delivery_context, 'multiplier', multiplier))
    from public.duration_multiplier_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', current_date);
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'backdated', public.rpc_create_grid_version('duration_multiplier', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload where k = 'changed'));
  insert into r select 'left', jsonb_build_object('n', (select count(*) from public.duration_multiplier_versions where note = 'TEST guard'));
  insert into r select 'same', public.rpc_create_grid_version('duration_multiplier', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard same', (select rows from payload where k = 'same'));
  insert into r select 'future', public.rpc_create_grid_version('duration_multiplier', current_setting('t.org')::uuid, current_date + 1000, 'TEST guard future', (select rows from payload where k = 'changed'));
  select set_config('role', 'postgres', true);

  select 'duration: a backdated version re-pricing a confirmed slot is refused, through the RPC' as check_name,
         (select res->>'error' from r where k = 'backdated') as actual, 'would_change_confirmed_pay' as expected,
         (select res->>'error' from r where k = 'backdated') = 'would_change_confirmed_pay' as pass
  union all
  select 'duration: nothing of the refused version is left behind',
         (select res->>'n' from r where k = 'left'), '0', (select res->>'n' from r where k = 'left') = '0'
  union all
  select 'duration: a backdated version with identical values passes',
         (select res->>'ok' from r where k = 'same'), 'true', (select (res->>'ok')::boolean from r where k = 'same')
  union all
  select 'duration: a future-dated version with changed values passes',
         (select res->>'ok' from r where k = 'future'), 'true', (select (res->>'ok')::boolean from r where k = 'future');
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('location_tier', location_tier, 'bonus_percent', case when location_tier = 'imprejurimi' then bonus_percent + 5 else bonus_percent end))
    from public.location_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', current_date);
  insert into payload select 'same', jsonb_agg(jsonb_build_object('location_tier', location_tier, 'bonus_percent', bonus_percent))
    from public.location_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', current_date);
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'backdated', public.rpc_create_grid_version('location_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload where k = 'changed'));
  insert into r select 'left', jsonb_build_object('n', (select count(*) from public.location_bonus_versions where note = 'TEST guard'));
  insert into r select 'same', public.rpc_create_grid_version('location_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard same', (select rows from payload where k = 'same'));
  insert into r select 'future', public.rpc_create_grid_version('location_bonus', current_setting('t.org')::uuid, current_date + 1000, 'TEST guard future', (select rows from payload where k = 'changed'));
  select set_config('role', 'postgres', true);

  select 'location: a backdated version re-pricing a confirmed slot is refused, through the RPC' as check_name,
         (select res->>'error' from r where k = 'backdated') as actual, 'would_change_confirmed_pay' as expected,
         (select res->>'error' from r where k = 'backdated') = 'would_change_confirmed_pay' as pass
  union all
  select 'location: nothing of the refused version is left behind',
         (select res->>'n' from r where k = 'left'), '0', (select res->>'n' from r where k = 'left') = '0'
  union all
  select 'location: a backdated version with identical values passes',
         (select res->>'ok' from r where k = 'same'), 'true', (select (res->>'ok')::boolean from r where k = 'same')
  union all
  select 'location: a future-dated version with changed values passes',
         (select res->>'ok' from r where k = 'future'), 'true', (select (res->>'ok')::boolean from r where k = 'future');
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('language_group', language_group, 'bonus_percent', case when language_group = 'ro_en' then bonus_percent + 10 else bonus_percent end))
    from public.language_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', current_date);
  insert into payload select 'same', jsonb_agg(jsonb_build_object('language_group', language_group, 'bonus_percent', bonus_percent))
    from public.language_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', current_date);
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'backdated', public.rpc_create_grid_version('language_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload where k = 'changed'));
  insert into r select 'left', jsonb_build_object('n', (select count(*) from public.language_bonus_versions where note = 'TEST guard'));
  insert into r select 'same', public.rpc_create_grid_version('language_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard same', (select rows from payload where k = 'same'));
  insert into r select 'future', public.rpc_create_grid_version('language_bonus', current_setting('t.org')::uuid, current_date + 1000, 'TEST guard future', (select rows from payload where k = 'changed'));
  select set_config('role', 'postgres', true);

  select 'language: a backdated version re-pricing a confirmed slot is refused, through the RPC' as check_name,
         (select res->>'error' from r where k = 'backdated') as actual, 'would_change_confirmed_pay' as expected,
         (select res->>'error' from r where k = 'backdated') = 'would_change_confirmed_pay' as pass
  union all
  select 'language: nothing of the refused version is left behind',
         (select res->>'n' from r where k = 'left'), '0', (select res->>'n' from r where k = 'left') = '0'
  union all
  select 'language: a backdated version with identical values passes',
         (select res->>'ok' from r where k = 'same'), 'true', (select (res->>'ok')::boolean from r where k = 'same')
  union all
  select 'language: a future-dated version with changed values passes',
         (select res->>'ok' from r where k = 'future'), 'true', (select (res->>'ok')::boolean from r where k = 'future');
rollback;

-- ============================================================================
-- Blocks 5-8: SABOTAGE, one per grid -- the same backdated write through the
-- same RPC, with that grid's guard triggers disabled. The refusal check must
-- flip to false, or it has no teeth.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');
  alter table public.trainer_grade_versions disable trigger trainer_grade_versions_guard_confirmed_pay;
  alter table public.trainer_grade_rates disable trigger trainer_grade_rates_guard_confirmed_pay;
  create temp table payload (rows jsonb) on commit drop;
  insert into payload select jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', case when grade_level = 2 then rate + 1 else rate end))
    from public.trainer_grade_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date);
  create temp table r (res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload));
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: grade backdated re-pricing refused, guard triggers disabled' as check_name,
         (select res->>'error' from r) as actual, 'would_change_confirmed_pay' as expected,
         coalesce((select res->>'error' from r) = 'would_change_confirmed_pay', false) as pass;
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');
  alter table public.duration_multiplier_versions disable trigger duration_multiplier_versions_guard_confirmed_pay;
  alter table public.duration_multiplier_rates disable trigger duration_multiplier_rates_guard_confirmed_pay;
  create temp table payload (rows jsonb) on commit drop;
  insert into payload select jsonb_agg(jsonb_build_object('duration_minutes', duration_minutes, 'delivery_context', delivery_context,
      'multiplier', case when duration_minutes = 120 and delivery_context = 'standard' then multiplier + 0.1 else multiplier end))
    from public.duration_multiplier_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', current_date);
  create temp table r (res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select public.rpc_create_grid_version('duration_multiplier', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload));
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: duration backdated re-pricing refused, guard triggers disabled' as check_name,
         (select res->>'error' from r) as actual, 'would_change_confirmed_pay' as expected,
         coalesce((select res->>'error' from r) = 'would_change_confirmed_pay', false) as pass;
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');
  alter table public.location_bonus_versions disable trigger location_bonus_versions_guard_confirmed_pay;
  alter table public.location_bonus_rates disable trigger location_bonus_rates_guard_confirmed_pay;
  create temp table payload (rows jsonb) on commit drop;
  insert into payload select jsonb_agg(jsonb_build_object('location_tier', location_tier, 'bonus_percent', case when location_tier = 'imprejurimi' then bonus_percent + 5 else bonus_percent end))
    from public.location_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', current_date);
  create temp table r (res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select public.rpc_create_grid_version('location_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload));
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: location backdated re-pricing refused, guard triggers disabled' as check_name,
         (select res->>'error' from r) as actual, 'would_change_confirmed_pay' as expected,
         coalesce((select res->>'error' from r) = 'would_change_confirmed_pay', false) as pass;
rollback;

begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');
  alter table public.language_bonus_versions disable trigger language_bonus_versions_guard_confirmed_pay;
  alter table public.language_bonus_rates disable trigger language_bonus_rates_guard_confirmed_pay;
  create temp table payload (rows jsonb) on commit drop;
  insert into payload select jsonb_agg(jsonb_build_object('language_group', language_group, 'bonus_percent', case when language_group = 'ro_en' then bonus_percent + 10 else bonus_percent end))
    from public.language_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', current_date);
  create temp table r (res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select public.rpc_create_grid_version('language_bonus', current_setting('t.org')::uuid, '2026-09-01', 'TEST guard', (select rows from payload));
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: language backdated re-pricing refused, guard triggers disabled' as check_name,
         (select res->>'error' from r) as actual, 'would_change_confirmed_pay' as expected,
         coalesce((select res->>'error' from r) = 'would_change_confirmed_pay', false) as pass;
rollback;

-- ============================================================================
-- Block 9: scope. The same backdated location change, on a session at
-- alte_orase (no other confirmed Test Org B slot is there), in three states:
-- approved (pay already frozen) and unconfirmed (nothing asserted) must
-- pass; confirmed-unapproved must be refused. Migration-style writes
-- (postgres, no RPC), so this also proves migrations are held to it.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.actor', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'alte_orase', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', 'TEST grid_confirmed_pay_guard scope (rolled back)');
  create temp table r (k text primary key, refused boolean) on commit drop;

  do $$
  declare
    v_org uuid := current_setting('t.org')::uuid;
    v_prev uuid := app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', current_date);
    v_new uuid;
    v_state text;
    v_refused boolean;
  begin
    foreach v_state in array array['unconfirmed', 'approved', 'confirmed_unapproved'] loop
      update public.sessions set
        trainer_principal_confirmed_at = case when v_state = 'unconfirmed' then null else now() end,
        trainer_principal_approved_at = case when v_state = 'approved' then now() else null end,
        trainer_principal_approved_amount_bani = case when v_state = 'approved' then 1 else null end
      where notes = 'TEST grid_confirmed_pay_guard scope (rolled back)';
      v_refused := false;
      begin
        insert into public.location_bonus_versions (organization_id, effective_date, created_by, note)
          values (v_org, '2026-09-01', current_setting('t.actor')::uuid, 'TEST guard scope') returning id into v_new;
        insert into public.location_bonus_rates (organization_id, version_id, location_tier, bonus_percent)
          select v_org, v_new, location_tier, case when location_tier = 'alte_orase' then bonus_percent + 10 else bonus_percent end
          from public.location_bonus_rates where version_id = v_prev;
        set constraints all immediate;
        raise exception using errcode = 'P0W00';
      exception
        when sqlstate 'P0W01' then v_refused := true;
        when sqlstate 'P0W00' then null;
      end;
      set constraints all deferred;
      insert into r values (v_state, v_refused);
    end loop;
  end $$;

  select 'scope: an UNCONFIRMED slot does not block a backdated change (nothing asserted about it)' as check_name,
         (select refused::text from r where k = 'unconfirmed') as actual, 'false' as expected,
         (select not refused from r where k = 'unconfirmed') as pass
  union all
  select 'scope: an APPROVED slot does not block it (approval already froze the amount)',
         (select refused::text from r where k = 'approved'), 'false', (select not refused from r where k = 'approved')
  union all
  select 'scope: a CONFIRMED, UNAPPROVED slot blocks it -- written migration-style, no RPC',
         (select refused::text from r where k = 'confirmed_unapproved'), 'true', (select refused from r where k = 'confirmed_unapproved');
rollback;

-- ============================================================================
-- Block 10: UPDATE in place (migration-style) on location/language -- the
-- two grids that never had the old row lock. Re-pricing is refused; an
-- edit that changes no confirmed slot's pay passes.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_confirmed_pay_guard (rolled back)');
  create temp table r (k text primary key, refused boolean) on commit drop;

  do $$
  declare
    v_loc uuid := app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', current_date);
    v_lang uuid := app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', current_date);
    v_refused boolean;
  begin
    v_refused := false;
    begin
      update public.location_bonus_rates set bonus_percent = bonus_percent + 5 where version_id = v_loc and location_tier = 'imprejurimi';
      set constraints all immediate;
      raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W01' then v_refused := true; when sqlstate 'P0W00' then null;
    end;
    set constraints all deferred;
    insert into r values ('loc_used', v_refused);

    v_refused := false;
    begin
      update public.location_bonus_rates set bonus_percent = bonus_percent + 5 where version_id = v_loc and location_tier = 'alte_orase';
      set constraints all immediate;
      raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W01' then v_refused := true; when sqlstate 'P0W00' then null;
    end;
    set constraints all deferred;
    insert into r values ('loc_unused', v_refused);

    v_refused := false;
    begin
      update public.language_bonus_rates set bonus_percent = bonus_percent + 10 where version_id = v_lang and language_group = 'ro_en';
      set constraints all immediate;
      raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W01' then v_refused := true; when sqlstate 'P0W00' then null;
    end;
    set constraints all deferred;
    insert into r values ('lang_used', v_refused);
  end $$;

  select 'update: location imprejurimi edited in place under a confirmed slot is refused' as check_name,
         (select refused::text from r where k = 'loc_used') as actual, 'true' as expected, (select refused from r where k = 'loc_used') as pass
  union all
  select 'update: location alte_orase edited in place (no confirmed slot there) passes',
         (select refused::text from r where k = 'loc_unused'), 'false', (select not refused from r where k = 'loc_unused')
  union all
  select 'update: language ro_en edited in place under a confirmed slot is refused',
         (select refused::text from r where k = 'lang_used'), 'true', (select refused from r where k = 'lang_used');
rollback;

-- ============================================================================
-- Block 11: the RPC's own refusals -- all or nothing, no band dropped, the
-- date named as the problem when it is the problem.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  create temp table payload (k text primary key, rows jsonb) on commit drop;
  -- the five fields the old form had: drops 60 and 90 for scoala_altfel_saptamana_verde
  insert into payload select 'five_keys', jsonb_agg(jsonb_build_object('duration_minutes', duration_minutes, 'delivery_context', delivery_context, 'multiplier', multiplier))
    from public.duration_multiplier_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', current_date)
      and (duration_minutes::text || ':' || delivery_context) in ('30:standard', '60:standard', '90:standard', '120:standard', '120:scoala_altfel_saptamana_verde');
  -- a rows insert that fails AFTER the header insert succeeded (grade 7 violates the level CHECK)
  insert into payload select 'bad_row', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', rate)) || '[{"grade_level": 7, "rate": 1}]'::jsonb
    from public.trainer_grade_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date);
  insert into payload select 'grades', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', rate))
    from public.trainer_grade_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date);
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'missing', public.rpc_create_grid_version('duration_multiplier', current_setting('t.org')::uuid, current_date + 1000, 'TEST rpc', (select rows from payload where k = 'five_keys'));
  do $$
  begin
    begin
      insert into r select 'bad_row', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, current_date + 1000, 'TEST rpc atomic', (select rows from payload where k = 'bad_row'));
    exception when check_violation then
      insert into r values ('bad_row', jsonb_build_object('raised', sqlerrm));
    end;
  end $$;
  insert into r select 'orphans', jsonb_build_object('n', (select count(*) from public.trainer_grade_versions where note = 'TEST rpc atomic'));
  insert into r select 'date_taken', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, (select effective_date from public.trainer_grade_versions where id = app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', current_date)), 'TEST rpc', (select rows from payload where k = 'grades'));
  select set_config('role', 'postgres', true);

  select 'rpc: a duration version without the 60/90 Scoala Altfel bands is refused, naming both' as check_name,
         (select (res->>'error') || ' ' || (res->>'missing') from r where k = 'missing') as actual,
         'missing_bands ["60:scoala_altfel_saptamana_verde", "90:scoala_altfel_saptamana_verde"]' as expected,
         (select res->>'error' = 'missing_bands' and res->'missing' = '["60:scoala_altfel_saptamana_verde", "90:scoala_altfel_saptamana_verde"]'::jsonb from r where k = 'missing') as pass
  union all
  select 'rpc: a rows insert failing after the header raises to the caller',
         (select coalesce(res->>'raised', res::text) from r where k = 'bad_row'), 'a check_violation', (select res ? 'raised' from r where k = 'bad_row')
  union all
  select 'rpc: and leaves no orphan header behind (header + rows are one unit)',
         (select res->>'n' from r where k = 'orphans'), '0', (select res->>'n' from r where k = 'orphans') = '0'
  union all
  select 'rpc: a date already used by a version is reported as date_taken, not as bad values',
         (select res->>'error' from r where k = 'date_taken'), 'date_taken', (select res->>'error' from r where k = 'date_taken') = 'date_taken';
rollback;
