-- db/tests/confirmation_future_guard.sql
-- WOW LAB OS: a confirmation cannot be SET on a workshop that has not
-- happened, on either path -- and CLEARING one is never date-guarded.
--
-- 202610200004 wrote the rule down two days before anything enforced it:
-- "a confirmation is a person's assertion that they taught a class, and
-- nobody can make it in advance." It was honoured by one migration choosing
-- not to write a value, and by nothing else. 202610220001 made it a guard;
-- this file is what keeps it one.
--
-- The asymmetry is the part worth testing hardest. A symmetric guard would
-- look more principled and would (a) block the un-confirm control the trainer
-- screen now has, and (b) make every row confirmed in the future BEFORE the
-- guard unrepairable until its date arrived.
--
-- Fixtures are created inside each block against wow-lab's real groups and
-- rolled back, so the dates are relative to CURRENT_DATE and the file does
-- not rot the way a hardcoded 2027 date would.

-- ============================================================================
-- Point 1 -- the trainer's own path.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.lorina', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);

  do $$
  declare v_group uuid; v_future uuid; v_past uuid; v_today uuid;
  begin
    select g.id into v_group from public.groups g
    join public.clients c on c.id = g.client_id
    where g.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Germana'
    limit 1;

    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.org')::uuid, v_group, current_date + 30, '15:30',
            current_setting('app.lorina')::uuid, 'planned', 50, 'bucuresti')
    returning id into v_future;

    -- Yesterday, not -30 days: found 2026-10-30, the first time this file
    -- ran after a real payroll_periods row existed for real -- `current_date
    -- - 30` landed inside September, which by then Mihai had actually
    -- closed (B1's own finding), so confirming "normally" returned
    -- 'month_closed' instead of 'ok'. Yesterday is always inside whatever
    -- month is still open in practice -- Operations closes a COMPLETE prior
    -- month, never the one still running -- so this stays "in the past,
    -- confirmable" without being coupled to which months happen to be
    -- closed on the day this suite runs.
    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.org')::uuid, v_group, current_date - 1, '15:30',
            current_setting('app.lorina')::uuid, 'delivered', 50, 'bucuresti')
    returning id into v_past;

    -- The boundary: `> current_date`, not `>=`. A workshop TODAY is
    -- confirmable today -- the trainer confirms it that evening.
    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.org')::uuid, v_group, current_date, '15:30',
            current_setting('app.lorina')::uuid, 'planned', 50, 'bucuresti')
    returning id into v_today;

    perform set_config('app.s_future', v_future::text, true);
    perform set_config('app.s_past', v_past::text, true);
    perform set_config('app.s_today', v_today::text, true);
  end $$;

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.lorina')::text, 'role', 'authenticated')::text, true);

  select set_config('test.t_future_set', app.rpc_confirm_session_attendance(current_setting('app.s_future')::uuid, true), true);
  select set_config('test.t_future_clear', app.rpc_confirm_session_attendance(current_setting('app.s_future')::uuid, false), true);
  select set_config('test.t_past_set', app.rpc_confirm_session_attendance(current_setting('app.s_past')::uuid, true), true);
  select set_config('test.t_today_set', app.rpc_confirm_session_attendance(current_setting('app.s_today')::uuid, true), true);
  select set_config('test.t_future_still_null', (
    select trainer_principal_confirmed_at is null from public.sessions where id = current_setting('app.s_future')::uuid
  )::text, true);

  select 'a trainer CANNOT confirm a workshop 30 days out' as check_name,
    current_setting('test.t_future_set') as actual, 'future_session' as expected,
    current_setting('test.t_future_set') = 'future_session' as pass
  union all
  select 'and the timestamp really was not written',
    current_setting('test.t_future_still_null'), 'true',
    current_setting('test.t_future_still_null')::boolean
  union all
  select 'CLEARING a future confirmation is allowed -- "I did not teach this" is true about tomorrow',
    current_setting('test.t_future_clear'), 'ok',
    current_setting('test.t_future_clear') = 'ok'
  union all
  select 'a past workshop confirms normally',
    current_setting('test.t_past_set'), 'ok',
    current_setting('test.t_past_set') = 'ok'
  union all
  select 'TODAY is confirmable today -- the guard is > current_date, not >=',
    current_setting('test.t_today_set'), 'ok',
    current_setting('test.t_today_set') = 'ok';
rollback;

-- ============================================================================
-- Point 2 -- Operations' correction path carries the SAME guard, evaluated
-- per column so that clearing one slot works while the other stays set.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.lorina', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);
  select set_config('app.anka', (select id::text from public.users where email = 'anka@asismart.ro'), true);

  do $$
  declare v_group uuid; v_future uuid; v_dirty uuid;
  begin
    select g.id into v_group from public.groups g
    join public.clients c on c.id = g.client_id
    where g.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Germana'
    limit 1;

    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.org')::uuid, v_group, current_date + 30, '15:30',
            current_setting('app.lorina')::uuid, 'planned', 50, 'bucuresti')
    returning id into v_future;

    -- A future row that is ALREADY wrongly confirmed -- the state any row
    -- confirmed before 202610220001 would be in. Written directly, because
    -- the guard now makes it unreachable through the RPC, which is the point.
    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier,
                                 trainer_principal_confirmed_at)
    values (current_setting('app.org')::uuid, v_group, current_date + 31, '16:25',
            current_setting('app.lorina')::uuid, 'planned', 50, 'bucuresti', now())
    returning id into v_dirty;

    perform set_config('app.s_future', v_future::text, true);
    perform set_config('app.s_dirty', v_dirty::text, true);
  end $$;

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.anka')::text, 'role', 'authenticated')::text, true);

  select set_config('test.o_future_set', app.rpc_correct_session_confirmation(current_setting('app.s_future')::uuid, true, false), true);
  select set_config('test.o_dirty_clear', app.rpc_correct_session_confirmation(current_setting('app.s_dirty')::uuid, false, false), true);
  select set_config('test.o_dirty_is_clear', (
    select trainer_principal_confirmed_at is null from public.sessions where id = current_setting('app.s_dirty')::uuid
  )::text, true);

  select 'Operations CANNOT set a confirmation on a future workshop either -- the override instinct is about who may correct a record, not what may be asserted' as check_name,
    current_setting('test.o_future_set') as actual, 'future_session' as expected,
    current_setting('test.o_future_set') = 'future_session' as pass
  union all
  select 'Operations CAN clear a future confirmation made before the guard existed',
    current_setting('test.o_dirty_clear'), 'ok',
    current_setting('test.o_dirty_clear') = 'ok'
  union all
  select 'and the row really is clean afterwards -- the guard can clean up after itself',
    current_setting('test.o_dirty_is_clear'), 'true',
    current_setting('test.o_dirty_is_clear')::boolean;
rollback;

-- ============================================================================
-- Point 3 -- SABOTAGE CHECK. Restores the pre-guard body of the trainer's RPC
-- (202609220003's, column narrowing intact, date guard removed) and re-runs
-- Point 1's first assertion VERBATIM. Under the un-guarded function the
-- trainer now confirms a workshop 30 days out, so `pass` must flip to false.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.lorina', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);

  create or replace function app.rpc_confirm_session_attendance(p_session_id uuid, p_confirmed boolean)
  returns text language plpgsql security definer set search_path = public, pg_temp as $sab$
  declare v_org uuid; v_principal uuid; v_secundar uuid;
  begin
    select organization_id, trainer_principal_id, trainer_secundar_id
      into v_org, v_principal, v_secundar from public.sessions where id = p_session_id;
    if v_org is null then return 'not_found'; end if;
    if v_principal <> app.current_user_id() and coalesce(v_secundar, '00000000-0000-0000-0000-000000000000'::uuid) <> app.current_user_id()
      then return 'not_assigned'; end if;
    update public.sessions
      set trainer_principal_confirmed_at = case when p_confirmed then now() else null end
      where id = p_session_id;
    return 'ok';
  end; $sab$;

  do $$
  declare v_group uuid; v_future uuid;
  begin
    select g.id into v_group from public.groups g
    join public.clients c on c.id = g.client_id
    where g.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Germana' limit 1;
    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    values (current_setting('app.org')::uuid, v_group, current_date + 30, '15:30',
            current_setting('app.lorina')::uuid, 'planned', 50, 'bucuresti')
    returning id into v_future;
    perform set_config('app.s_future', v_future::text, true);
  end $$;

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.lorina')::text, 'role', 'authenticated')::text, true);
  select set_config('test.t_future_set', app.rpc_confirm_session_attendance(current_setting('app.s_future')::uuid, true), true);

  select 'SABOTAGE: a trainer CANNOT confirm a workshop 30 days out, same assertion as point 1, date guard removed from the RPC' as check_name,
    current_setting('test.t_future_set') as actual, 'future_session' as expected,
    current_setting('test.t_future_set') = 'future_session' as pass;
rollback;
