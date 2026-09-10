-- verify_sessions_trainer_attendance_write.sql
-- Dry-run verification for
-- supabase/migrations/202609110003_add_sessions_update_trainer_branch.sql
-- and its updateSessionAttendance() action (app/(app)/groups/actions.ts).
--
-- Run with: supabase db query --linked --file scripts/verify_sessions_trainer_attendance_write.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_principal uuid := (select id from public.users where email = 'popar216@gmail.com'); -- Raluca Popa
  v_secundar uuid := (select id from public.users where email = 'merisanteodora@gmail.com'); -- Teodora Merisan
  v_other_trainer uuid := (select id from public.users where email = 'alexandra.nutu2010@gmail.com'); -- not on this session
  v_catalina uuid := (select id from public.users where email = 'catalina_moale@yahoo.com');
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where slug = 'wow-lab') limit 1);
  v_client uuid;
  v_contract uuid;
  v_group uuid;
  v_session uuid;
  v_row_count int;
  v_attendance int;
  v_experiment text;
  v_status text;
  v_trainer_principal uuid;
begin
  -- Fixture, service-role (privileged context inside this DO block by default).
  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client', 'private_school')
  returning id into v_client;

  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
  values (v_org, v_client, v_legal_entity, 'recurring_annual')
  returning id into v_contract;

  insert into public.groups (organization_id, client_id, contract_id, module, delivery_format)
  values (v_org, v_client, v_contract, 'gaga', 'recurring')
  returning id into v_group;

  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, current_date, v_principal, v_secundar, 'planned')
  returning id into v_session;

  -- ---- 1. The assigned principal can write both fields on their own session ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);

  update public.sessions set attendance_count = 14, experiment_delivered = 'Volcano eruption' where id = v_session;
  select attendance_count, experiment_delivered into v_attendance, v_experiment from public.sessions where id = v_session;
  if v_attendance = 14 and v_experiment = 'Volcano eruption' then
    report := report || E'\n1. PASS - the assigned principal can write attendance_count and experiment_delivered on their own session';
  else
    report := report || format(E'\n1. FAIL - principal write did not stick, got attendance=%L experiment=%L', v_attendance, v_experiment);
  end if;

  -- ---- 2. The assigned secundar can too ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  update public.sessions set attendance_count = 15, experiment_delivered = 'Volcano eruption v2' where id = v_session;
  select attendance_count, experiment_delivered into v_attendance, v_experiment from public.sessions where id = v_session;
  if v_attendance = 15 and v_experiment = 'Volcano eruption v2' then
    report := report || E'\n2. PASS - the assigned secundar can write attendance_count and experiment_delivered too';
  else
    report := report || format(E'\n2. FAIL - secundar write did not stick, got attendance=%L experiment=%L', v_attendance, v_experiment);
  end if;

  -- ---- 3. A trainer NOT on this session cannot ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_other_trainer::text, 'role', 'authenticated')::text, true);
  update public.sessions set attendance_count = 99 where id = v_session;
  get diagnostics v_row_count = row_count;
  if v_row_count = 0 then
    report := report || E'\n3. PASS - a trainer not allocated to this session cannot UPDATE it (0 rows matched)';
  else
    report := report || E'\n3. FAIL - an unallocated trainer was able to UPDATE the session';
  end if;

  -- ---- 4. The assigned trainer cannot change trainer assignment or status through this path ----
  -- RLS alone would technically allow a matched trainer's raw UPDATE to
  -- touch any column (row-level, not column-level) -- this assertion
  -- is about updateSessionAttendance() itself, which never includes
  -- trainer_principal_id/trainer_secundar_id/status in its payload.
  -- Confirmed by reading the action (it only ever sets attendance_count/
  -- experiment_delivered), not re-derivable from raw SQL here -- same
  -- limit already documented for the column-level assertions in
  -- verify_groups_children_confirmed_write.sql.
  report := report || E'\n4. INFO - updateSessionAttendance() never includes trainer_principal_id/trainer_secundar_id/status in its UPDATE payload for anyone, confirmed by reading the action -- this is an action-layer guarantee, not RLS, and is confirmed live by the browser pass against the real deployed action';

  -- reset to a known value before the next check
  update public.sessions set attendance_count = 15, experiment_delivered = 'Volcano eruption v2' where id = v_session;

  -- ---- 5. Operations (Catalina) can still do what it could before ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_catalina::text, 'role', 'authenticated')::text, true);
  update public.sessions set status = 'confirmed' where id = v_session;
  select status into v_status from public.sessions where id = v_session;
  if v_status = 'confirmed' then
    report := report || E'\n5a. PASS - Catalina (operations_manager) can still update session status';
  else
    report := report || format(E'\n5a. FAIL - Catalina''s status write did not stick, got %L', v_status);
  end if;

  update public.sessions set trainer_principal_id = v_other_trainer where id = v_session;
  select trainer_principal_id into v_trainer_principal from public.sessions where id = v_session;
  if v_trainer_principal = v_other_trainer then
    report := report || E'\n5b. PASS - Catalina can still reassign trainer_principal_id (unaffected by the new trainer branch)';
  else
    report := report || E'\n5b. FAIL - Catalina''s reassignment did not stick';
  end if;

  -- reset back to privileged context to clean up the fixtures
  reset role;
  delete from public.sessions where id = v_session;
  delete from public.groups where id = v_group;
  delete from public.contracts where id = v_contract;
  delete from public.clients where id = v_client;

  raise exception E'VERIFICATION REPORT for 202609110003 (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
