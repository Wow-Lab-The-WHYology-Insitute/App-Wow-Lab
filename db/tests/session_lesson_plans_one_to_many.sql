-- db/tests/session_lesson_plans_one_to_many.sql
-- B1 (item 179): session_lesson_plans is now one-to-many per
-- (session, trainer). Exercises app.rpc_propose_session_lesson_plan's new
-- ADD semantics, app.rpc_remove_session_lesson_plan, and
-- app.rpc_update_session_lesson_plan_delivered -- all through the
-- PostgREST-exposed public wrappers, same as the app actually calls.
--
-- Impersonates merisanteodora@gmail.com (a real trainer, grade 3) on a
-- synthetic session/group, rolled back.

begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);

  create temp table check_results (check_name text, pass boolean);
  grant insert, select on check_results to authenticated;

  -- Fixture (session, two catalogue plan ids) created here, PRIVILEGED --
  -- before the role switch below -- same reasoning as every other file's
  -- "fixtures created while privileged" pattern: Teodora herself holds no
  -- sessions.create, so she could not have inserted this session, and the
  -- RPCs under test are about what she can do to session_lesson_plans,
  -- not to sessions.
  do $$
  declare
    v_group uuid;
    v_session uuid;
    v_plan1 uuid;
    v_plan2 uuid;
  begin
    select g.id into v_group from public.groups g
    join public.clients c on c.id = g.client_id
    where g.organization_id = current_setting('app.wow_lab')::uuid and c.name = 'Scoala Avenor'
    limit 1;

    -- 2026-10-05, not 2026-09-25: September closed for real on 2026-10-29
    -- (see confirmation_future_guard.sql's own note on the same problem),
    -- and app.rpc_update_session_lesson_plan_delivered's month-closed gate
    -- would otherwise refuse this fixture's own update for a reason that
    -- has nothing to do with what this test is checking.
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.wow_lab')::uuid, v_group, '2026-10-05', current_setting('app.teodora')::uuid, 'planned', 90, 'imprejurimi')
    returning id into v_session;

    select id into v_plan1 from public.lesson_plans where organization_id = current_setting('app.wow_lab')::uuid order by canonical_title limit 1;
    select id into v_plan2 from public.lesson_plans where organization_id = current_setting('app.wow_lab')::uuid order by canonical_title offset 1 limit 1;

    perform set_config('app.session', v_session::text, true);
    perform set_config('app.plan1', v_plan1::text, true);
    perform set_config('app.plan2', v_plan2::text, true);
  end $$;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.teodora'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);

  -- ---- ADD, not replace: proposing a SECOND, different plan keeps both. ----
  select public.rpc_propose_session_lesson_plan(current_setting('app.session')::uuid, current_setting('app.plan1')::uuid);
  select public.rpc_propose_session_lesson_plan(current_setting('app.session')::uuid, current_setting('app.plan2')::uuid);

  insert into check_results values (
    'proposing two different plans on the same session+trainer keeps BOTH rows',
    (select count(*) = 2 from public.session_lesson_plans
     where session_id = current_setting('app.session')::uuid and trainer_id = current_setting('app.teodora')::uuid)
  );

  -- Re-proposing the SAME plan is a harmless no-op, not a third row.
  select public.rpc_propose_session_lesson_plan(current_setting('app.session')::uuid, current_setting('app.plan1')::uuid);
  insert into check_results values (
    're-proposing the SAME plan is idempotent -- still exactly 2 rows',
    (select count(*) = 2 from public.session_lesson_plans
     where session_id = current_setting('app.session')::uuid and trainer_id = current_setting('app.teodora')::uuid)
  );

  insert into check_results values (
    'delivered defaults to true on a fresh proposal',
    (select bool_and(delivered) from public.session_lesson_plans
     where session_id = current_setting('app.session')::uuid and trainer_id = current_setting('app.teodora')::uuid)
  );

  -- ---- delivered toggle, own row ----
  do $$
  declare v_row uuid;
  begin
    select id into v_row from public.session_lesson_plans
    where session_id = current_setting('app.session')::uuid and lesson_plan_id = current_setting('app.plan1')::uuid;
    perform set_config('app.row1', v_row::text, true);
  end $$;

  select public.rpc_update_session_lesson_plan_delivered(current_setting('app.row1')::uuid, false);
  insert into check_results values (
    'delivered can be set to false by the owning trainer',
    (select delivered = false from public.session_lesson_plans where id = current_setting('app.row1')::uuid)
  );

  -- ---- remove, own row ----
  select public.rpc_remove_session_lesson_plan(current_setting('app.row1')::uuid);
  insert into check_results values (
    'removing one row leaves the OTHER plan untouched -- exactly 1 remains',
    (select count(*) = 1 from public.session_lesson_plans
     where session_id = current_setting('app.session')::uuid and trainer_id = current_setting('app.teodora')::uuid)
  );
  insert into check_results values (
    'the removed row is gone, specifically',
    (select not exists(select 1 from public.session_lesson_plans where id = current_setting('app.row1')::uuid))
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: a trainer who is NOT on the session cannot propose, remove, or
-- toggle delivered on it -- the row-match guard survives the rewrite.
-- ============================================================================
begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.alina', (select id::text from public.users where email = 'alina.garofil@outlook.com'), true);

  create temp table check_results (check_name text, pass boolean);
  grant insert, select on check_results to authenticated;

  do $$
  declare v_group uuid; v_session uuid; v_plan uuid; v_row uuid;
  begin
    select g.id into v_group from public.groups g
    join public.clients c on c.id = g.client_id
    where g.organization_id = current_setting('app.wow_lab')::uuid and c.name = 'Scoala Avenor'
    limit 1;

    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.wow_lab')::uuid, v_group, '2026-10-05', current_setting('app.teodora')::uuid, 'planned', 90, 'imprejurimi')
    returning id into v_session;

    select id into v_plan from public.lesson_plans where organization_id = current_setting('app.wow_lab')::uuid limit 1;

    insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status)
    values (current_setting('app.wow_lab')::uuid, v_session, current_setting('app.teodora')::uuid, v_plan, 'proposed')
    returning id into v_row;

    perform set_config('app.session', v_session::text, true);
    perform set_config('app.plan', v_plan::text, true);
    perform set_config('app.row', v_row::text, true);
  end $$;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.alina'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);

  insert into check_results values (
    'a trainer NOT on the session cannot remove its plan',
    (select app.rpc_remove_session_lesson_plan(current_setting('app.row')::uuid)) = 'not_assigned'
  );
  insert into check_results values (
    'a trainer NOT on the session cannot toggle its delivered flag',
    (select app.rpc_update_session_lesson_plan_delivered(current_setting('app.row')::uuid, false)) = 'not_assigned'
  );

  select check_name, pass from check_results order by check_name;
rollback;
