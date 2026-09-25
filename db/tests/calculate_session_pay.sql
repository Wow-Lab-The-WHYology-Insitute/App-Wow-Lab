-- db/tests/calculate_session_pay.sql
-- app.calculate_session_pay (202609250001) -- not an RLS suite (this
-- function has no authorization branch of its own, see its own header
-- comment on why it's SECURITY INVOKER), so no "rls_" prefix, same
-- naming choice as capability_liveness.sql.
--
-- Impersonates anca.tanasescu@gmail.com (platform_owner) throughout, not
-- a different real user per check -- the behavior under test in every
-- case here is driven by the p_trainer_id ARGUMENT, not by the caller's
-- own identity, so one capable caller (who can actually read the
-- finance-gated rate tables SECURITY INVOKER exposes to them) avoids a
-- real ambiguity a non-finance impersonation would introduce: a plain
-- trainer querying trainer_grade_assignments gets zero rows back either
-- way, whether because they genuinely have no grade or because RLS
-- filtered them out -- using a capable caller throughout means every
-- raise in this file is caused by the data, not by who's asking.
--
-- Only the LAST statement's result set in each begin/rollback block is
-- what the runner actually sees (confirmed empirically against this
-- suite's own existing files -- capability_liveness.sql's first select
-- never surfaces either) -- so every block below ends in exactly one
-- combined select, never several scattered ones.
--
-- All fixtures (group, session) are inserted and read within transactions
-- that always roll back -- nothing here touches real WOW LAB data. Uses
-- WOW LAB's own real, already-seeded, PFA-inclusive pay grids (item 95)
-- rather than synthetic values, since the point of the "known case"
-- check is to confirm this function's arithmetic against the same real
-- rates Anca confirmed, not against numbers invented for the test.

-- ============================================================================
-- Block 1: the known case, a missing grade, and a trainer not on the
-- session.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.luiza', (select id::text from public.users where email = 'luiza.mirt8@gmail.com'), true);
  select set_config('app.alina', (select id::text from public.users where email = 'alina.garofil@outlook.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  -- Grade 3 (Teodora, rate 127) x 90min standard (1.2) x
  -- (1 + 25/100 + 20/100) = 127 x 1.2 x 1.45 = 220.98 exactly, unrounded.
  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('11111111-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values ('22222222-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, '11111111-0000-0000-0000-000000000001', '2026-09-25', current_setting('app.teodora')::uuid, null, 'planned', 90, 'imprejurimi');

  insert into check_results values (
    'known case: grade 3, 90min standard, imprejurimi, fr_de_es = 220.98 exactly',
    app.calculate_session_pay('22222222-0000-0000-0000-000000000001', current_setting('app.teodora')::uuid) = 220.98
  );

  -- Missing grade assignment raises, does not return zero or null.
  -- Luiza Mirt has no trainer_grade_assignments row at all (item 95).
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values ('22222222-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, '11111111-0000-0000-0000-000000000001', '2026-09-25', current_setting('app.luiza')::uuid, null, 'planned', 90, 'imprejurimi');

  do $$
  declare
    v_caught boolean := false;
  begin
    begin
      perform app.calculate_session_pay('22222222-0000-0000-0000-000000000002', current_setting('app.luiza')::uuid);
    exception when others then
      v_caught := true;
    end;
    insert into check_results values ('missing grade assignment raises, not zero/null', v_caught);
  end $$;

  -- A trainer not on the session is refused. Alina Garofil is neither
  -- principal nor secundar on the "known case" session above.
  do $$
  declare
    v_caught boolean := false;
    v_msg text;
  begin
    begin
      perform app.calculate_session_pay('22222222-0000-0000-0000-000000000001', current_setting('app.alina')::uuid);
    exception when others then
      v_caught := true;
      v_msg := sqlerrm;
    end;
    insert into check_results values ('trainer not on session is refused, naming both ids', v_caught and v_msg like '%not the principal or secundar%');
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: delivery context comes from the GROUP, not the session.
-- Same trainer, same location/language, only the group's delivery_format
-- differs, so the only variable affecting the result is the multiplier.
-- 127 x 2.0 x 1.45 = 368.30 (scoala_altfel); 127 x 1.5 x 1.45 = 276.225
-- (standard).
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('11111111-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'scoala_altfel', 'fr_de_es');

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('11111111-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values ('22222222-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, '11111111-0000-0000-0000-000000000003', '2026-09-25', current_setting('app.teodora')::uuid, null, 'planned', 120, 'imprejurimi');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values ('22222222-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, '11111111-0000-0000-0000-000000000004', '2026-09-25', current_setting('app.teodora')::uuid, null, 'planned', 120, 'imprejurimi');

  select 'scoala_altfel context at 120min yields 2.0 multiplier -> 368.30' as check_name,
    app.calculate_session_pay('22222222-0000-0000-0000-000000000003', current_setting('app.teodora')::uuid) = 368.30 as pass
  union all
  select 'standard context at 120min yields 1.5 multiplier -> 276.225',
    app.calculate_session_pay('22222222-0000-0000-0000-000000000004', current_setting('app.teodora')::uuid) = 276.225;
rollback;

-- ============================================================================
-- Block 3: SABOTAGE. Temporarily redefines the function to round its
-- result, confirming Block 1's exact-equality assertion actually has
-- teeth against the one regression this function was explicitly built to
-- never have (item 95's own reversed rounding assumption). A sabotage
-- row reading pass:false here is the runner-level PASS.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('11111111-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values ('22222222-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, '11111111-0000-0000-0000-000000000005', '2026-09-25', current_setting('app.teodora')::uuid, null, 'planned', 90, 'imprejurimi');

  create or replace function app.calculate_session_pay(p_session_id uuid, p_trainer_id uuid)
  returns numeric
  language plpgsql
  stable
  set search_path to ''
  as $sabotage$
  declare
    v_org uuid;
    v_session_date date;
    v_duration_minutes integer;
    v_location_tier text;
    v_group_id uuid;
    v_delivery_format text;
    v_language_group text;
    v_grade integer;
    v_rate numeric;
    v_duration_multiplier numeric;
    v_location_bonus numeric;
    v_language_bonus numeric;
  begin
    select organization_id, session_date, duration_minutes, location_tier, group_id
      into v_org, v_session_date, v_duration_minutes, v_location_tier, v_group_id
    from public.sessions where id = p_session_id;
    select delivery_format, language_group into v_delivery_format, v_language_group from public.groups where id = v_group_id;
    v_grade := app.resolve_trainer_grade(p_trainer_id, v_session_date);
    v_rate := app.resolve_trainer_grade_rate(v_org, v_grade, v_session_date);
    v_duration_multiplier := app.resolve_duration_multiplier(v_org, v_duration_minutes, v_delivery_format, v_session_date);
    v_location_bonus := app.resolve_location_bonus(v_org, v_location_tier, v_session_date);
    v_language_bonus := app.resolve_language_bonus(v_org, v_language_group, v_session_date);
    return round(v_rate * v_duration_multiplier * (1 + v_location_bonus / 100 + v_language_bonus / 100), 0);
  end;
  $sabotage$;

  select
    'SABOTAGE: rounded function no longer equals 220.98 exactly' as check_name,
    app.calculate_session_pay('22222222-0000-0000-0000-000000000005', current_setting('app.teodora')::uuid) = 220.98 as pass;
rollback;
