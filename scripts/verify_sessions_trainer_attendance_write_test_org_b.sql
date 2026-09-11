-- verify_sessions_trainer_attendance_write_test_org_b.sql
-- Live verification of 202609110003 + its correction 202609110004
-- (require mywork.* alongside the row match on the sessions UPDATE
-- policy's trainer branch), run against WOW LAB Test Org B using the six
-- real trainer fixtures (Test Trainer B1-B6) rather than real wow-lab
-- people -- the prior verification for this feature (see
-- scripts/verify_sessions_trainer_attendance_write.sql) ran against
-- 'wow-lab' only.
--
-- Run with: supabase db query --linked --file scripts/verify_sessions_trainer_attendance_write_test_org_b.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Everything in this script is created and deleted inside one
-- transaction that always rolls back -- no fixture created here is ever
-- committed.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_principal uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com'); -- Test Trainer B1
  v_secundar uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com'); -- Test Trainer B2
  v_other_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com'); -- Test Trainer B3, not on this session
  v_capability_less uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'); -- contract_administrator + finance_operations, neither sessions.create nor mywork.*
  v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'); -- operations_manager
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where name = 'WOW LAB Test Org B') and name = 'Test Entity SRL');
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
  if v_principal is null or v_secundar is null or v_other_trainer is null or v_capability_less is null or v_ops is null then
    raise exception 'Fixture lookup failed -- one or more Test Org B accounts not found. principal=%, secundar=%, other_trainer=%, capability_less=%, ops=%',
      v_principal, v_secundar, v_other_trainer, v_capability_less, v_ops;
  end if;

  -- Fixture, service-role (privileged context inside this DO block by default).
  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client (test org B)', 'private_school')
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

  -- ---- 1. The assigned principal (Test Trainer B1, holds mywork.*) can write both fields ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);

  update public.sessions set attendance_count = 12, experiment_delivered = 'Baking-soda volcano' where id = v_session;
  select attendance_count, experiment_delivered into v_attendance, v_experiment from public.sessions where id = v_session;
  if v_attendance = 12 and v_experiment = 'Baking-soda volcano' then
    report := report || E'\n1. PASS - Test Trainer B1 (assigned principal, holds mywork.*) can write attendance_count and experiment_delivered on their own session';
  else
    report := report || format(E'\n1. FAIL - principal write did not stick, got attendance=%L experiment=%L', v_attendance, v_experiment);
  end if;

  -- ---- 2. The assigned secundar (Test Trainer B2) can too ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  update public.sessions set attendance_count = 13, experiment_delivered = 'Baking-soda volcano v2' where id = v_session;
  select attendance_count, experiment_delivered into v_attendance, v_experiment from public.sessions where id = v_session;
  if v_attendance = 13 and v_experiment = 'Baking-soda volcano v2' then
    report := report || E'\n2. PASS - Test Trainer B2 (assigned secundar) can write attendance_count and experiment_delivered too';
  else
    report := report || format(E'\n2. FAIL - secundar write did not stick, got attendance=%L experiment=%L', v_attendance, v_experiment);
  end if;

  -- ---- 3. THE CORRECTION ITSELF: a row match with no mywork.* cannot write ----
  -- Reallocate the session's principal slot (service role, outside RLS) to
  -- v_capability_less -- a real account that holds neither sessions.create
  -- nor mywork.* (contract_administrator + finance_operations only). Under
  -- 202609110003 alone (row match, no capability check) this account's own
  -- UPDATE would have matched and succeeded. Under 202609110004 it must not.
  reset role;
  update public.sessions set trainer_principal_id = v_capability_less where id = v_session;
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_capability_less::text, 'role', 'authenticated')::text, true);
  update public.sessions set attendance_count = 999 where id = v_session;
  get diagnostics v_row_count = row_count;
  if v_row_count = 0 then
    report := report || E'\n3. PASS - a row-matched account with no mywork.* (Test Contract Admin B) cannot UPDATE the session -- this is what 202609110004 fixes over 202609110003 alone';
  else
    report := report || E'\n3. FAIL - a row-matched account with no mywork.* was able to UPDATE the session -- the capability gate is not being enforced';
  end if;

  -- restore the principal slot before the remaining assertions
  reset role;
  update public.sessions set trainer_principal_id = v_principal, attendance_count = 13, experiment_delivered = 'Baking-soda volcano v2' where id = v_session;

  -- ---- 4. A trainer NOT on this session (Test Trainer B3, holds mywork.*) cannot ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_other_trainer::text, 'role', 'authenticated')::text, true);
  update public.sessions set attendance_count = 999 where id = v_session;
  get diagnostics v_row_count = row_count;
  if v_row_count = 0 then
    report := report || E'\n4. PASS - Test Trainer B3 (holds mywork.*, not allocated to this session) cannot UPDATE it (0 rows matched)';
  else
    report := report || E'\n4. FAIL - an unallocated trainer was able to UPDATE the session';
  end if;

  -- ---- 5. The assigned trainer cannot change trainer assignment or status through this path ----
  report := report || E'\n5. INFO - updateSessionAttendance() (app/(app)/groups/actions.ts) never includes trainer_principal_id/trainer_secundar_id/status in its UPDATE payload for anyone, confirmed by reading the action -- an action-layer guarantee, not RLS. RLS alone (rows 1-4 above) would technically allow a matched trainer''s raw UPDATE to touch any column; the action is what actually stops it, same limit already documented in verify_groups_children_confirmed_write.sql and verify_sessions_trainer_attendance_write.sql';

  -- ---- 6. Operations (Test Ops Manager B) retains what it had ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  update public.sessions set status = 'confirmed' where id = v_session;
  select status into v_status from public.sessions where id = v_session;
  if v_status = 'confirmed' then
    report := report || E'\n6a. PASS - Test Ops Manager B (operations_manager) can still update session status';
  else
    report := report || format(E'\n6a. FAIL - Ops status write did not stick, got %L', v_status);
  end if;

  update public.sessions set trainer_principal_id = v_other_trainer where id = v_session;
  select trainer_principal_id into v_trainer_principal from public.sessions where id = v_session;
  if v_trainer_principal = v_other_trainer then
    report := report || E'\n6b. PASS - Test Ops Manager B can still reassign trainer_principal_id (unaffected by the trainer branch or its correction)';
  else
    report := report || E'\n6b. FAIL - Ops reassignment did not stick';
  end if;

  -- reset back to privileged context to clean up the fixtures
  reset role;
  delete from public.sessions where id = v_session;
  delete from public.groups where id = v_group;
  delete from public.contracts where id = v_contract;
  delete from public.clients where id = v_client;

  raise exception E'VERIFICATION REPORT for 202609110003 + 202609110004, WOW LAB Test Org B (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
