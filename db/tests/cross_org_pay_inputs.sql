-- db/tests/cross_org_pay_inputs.sql
-- WOW LAB OS: a WRITE in one organization must not change an answer the pay
-- engine computes for another (202611160001, OPEN_ITEMS item 198).
--
-- Every other isolation check in this directory asks whether a user in Org B
-- can SEE Org A's rows. None asked whether a row Org B is allowed to WRITE
-- can change what Org A's functions compute. That class was missing, and
-- app.resolve_trainer_grade fell into it: it selected by trainer and date,
-- never by organization, so Test Org B's owner -- through RLS, on Org B's own
-- capability -- re-priced six confirmed wow-lab slots (item 196, P5).
--
-- The write is made as the attacker, through RLS, not as postgres: the
-- property is "what Org B is permitted to write", so the test permits only
-- that. The answer is read with the guard's own instrument
-- (app.grid_confirmed_pay_snapshot), which runs with full rights -- the same
-- visibility app.rpc_approve_session_pay has when it freezes an amount.
--
-- Every block is BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- the breach, re-run: an Org B grade row for a wow-lab trainer.
-- ============================================================================
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.teo',  (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('test.before', app.grid_confirmed_pay_snapshot(current_setting('app.org')::uuid, '2026-09-01')::text, true);
  select set_config('test.grade_before', app.resolve_trainer_grade(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, '2026-09-16')::text, true);

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (current_setting('app.orgb')::uuid, current_setting('app.teo')::uuid, 6, '2026-09-02', current_setting('app.bown')::uuid, 'manual');
  select set_config('role', 'postgres', true);

  select set_config('test.moved', (app.grid_correction_declaration(
    current_setting('test.before')::jsonb,
    app.grid_confirmed_pay_snapshot(current_setting('app.org')::uuid, '2026-09-01'))->'summary'->>'slots'), true);

  select 'an Org B grade row moves no confirmed wow-lab pay slot' as check_name,
    current_setting('test.moved') as actual, '0' as expected,
    current_setting('test.moved')::integer = 0 as pass
  union all
  select 'wow-lab still resolves Teodora''s own grade on 16.09',
    app.resolve_trainer_grade(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, '2026-09-16')::text,
    current_setting('test.grade_before'),
    app.resolve_trainer_grade(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, '2026-09-16')::text = current_setting('test.grade_before')
  union all
  -- Scoped, not a blanket deny: the row answers for the organization it was written in.
  select 'the same row answers for Org B, where it was written',
    app.resolve_trainer_grade(current_setting('app.orgb')::uuid, current_setting('app.teo')::uuid, '2026-09-16')::text, '6',
    app.resolve_trainer_grade(current_setting('app.orgb')::uuid, current_setting('app.teo')::uuid, '2026-09-16') = 6
  union all
  -- The unscoped form must not exist at all: an overload that still resolves
  -- is the breach kept available.
  select 'the two-argument resolve_trainer_grade no longer exists',
    (select count(*)::text from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'app' and p.proname = 'resolve_trainer_grade' and p.pronargs = 2), '0',
    (select count(*) = 0 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'app' and p.proname = 'resolve_trainer_grade' and p.pronargs = 2);
rollback;

-- ============================================================================
-- Point 2 -- SABOTAGE CHECK. Replaces the resolver with one that ignores its
-- organization argument (the pre-202611160001 body) and re-runs Point 1's
-- first assertion VERBATIM. The Org B row now answers for wow-lab, six
-- confirmed slots move, and `pass` must flip to false. If it does not,
-- Point 1 was not testing the filter.
-- ============================================================================
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.teo',  (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);

  create or replace function app.resolve_trainer_grade(p_organization_id uuid, p_trainer_id uuid, p_as_of date)
  returns integer language plpgsql stable set search_path to '' as $sabotage$
  declare v_grade_level integer;
  begin
    select grade_level into v_grade_level from public.trainer_grade_assignments
    where trainer_id = p_trainer_id and effective_from <= p_as_of
    order by effective_from desc limit 1;
    if v_grade_level is null then
      raise exception 'app.resolve_trainer_grade: no trainer_grade_assignments row for trainer % on or before %', p_trainer_id, p_as_of;
    end if;
    return v_grade_level;
  end;
  $sabotage$;

  select set_config('test.before', app.grid_confirmed_pay_snapshot(current_setting('app.org')::uuid, '2026-09-01')::text, true);
  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (current_setting('app.orgb')::uuid, current_setting('app.teo')::uuid, 6, '2026-09-02', current_setting('app.bown')::uuid, 'manual');
  select set_config('role', 'postgres', true);

  select set_config('test.moved', (app.grid_correction_declaration(
    current_setting('test.before')::jsonb,
    app.grid_confirmed_pay_snapshot(current_setting('app.org')::uuid, '2026-09-01'))->'summary'->>'slots'), true);

  select 'SABOTAGE: an Org B grade row moves no confirmed wow-lab pay slot, same assertion as point 1, organization filter removed' as check_name,
    current_setting('test.moved') as actual, '0' as expected,
    current_setting('test.moved')::integer = 0 as pass;
rollback;
