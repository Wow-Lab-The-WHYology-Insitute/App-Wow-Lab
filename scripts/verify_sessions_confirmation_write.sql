-- verify_sessions_confirmation_write.sql
-- Live verification of 202609150002 (trainer_principal_confirmed_at /
-- trainer_secundar_confirmed_at + the sessions UPDATE policy's new
-- month-close gate and finance.operations.* branch), against WOW LAB
-- Test Org B.
--
-- Run with: supabase db query --linked --file scripts/verify_sessions_confirmation_write.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Everything here runs inside one transaction that always rolls back.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_principal uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com'); -- Test Trainer B1
  v_secundar uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com'); -- Test Trainer B2
  v_finance uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'); -- finance.operations.*
  v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where name = 'WOW LAB Test Org B') and name = 'Test Entity SRL');
  v_client uuid;
  v_contract uuid;
  v_group uuid;
  v_session_open uuid;   -- session in the open month (this month)
  v_session_other uuid;  -- session in a DIFFERENT, untouched month -- must be unaffected by closing this one
  v_row_count int;
  v_principal_confirmed timestamptz;
  v_secundar_confirmed timestamptz;
  v_this_month date := date_trunc('month', current_date)::date;
  v_other_month date := (date_trunc('month', current_date) + interval '2 months')::date;
begin
  if v_org is null or v_principal is null or v_secundar is null or v_finance is null or v_ops is null then
    raise exception 'Fixture lookup failed. org=%, principal=%, secundar=%, finance=%, ops=%',
      v_org, v_principal, v_secundar, v_finance, v_ops;
  end if;

  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client (confirmation)', 'private_school')
  returning id into v_client;

  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
  values (v_org, v_client, v_legal_entity, 'recurring_annual')
  returning id into v_contract;

  insert into public.groups (organization_id, client_id, contract_id, module, delivery_format)
  values (v_org, v_client, v_contract, 'gaga', 'recurring')
  returning id into v_group;

  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, v_this_month, v_principal, v_secundar, 'planned')
  returning id into v_session_open;

  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, v_other_month, v_principal, v_secundar, 'planned')
  returning id into v_session_other;

  -- ---- 1. The principal confirms their own session, month open ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_principal_confirmed_at = now() where id = v_session_open;
  select trainer_principal_confirmed_at into v_principal_confirmed from public.sessions where id = v_session_open;
  if v_principal_confirmed is not null then
    report := report || E'\n1. PASS - the principal (Test Trainer B1) can confirm their own session while the month is open';
  else
    report := report || E'\n1. FAIL - the principal''s confirmation did not stick';
  end if;

  -- ---- 2. The principal cannot touch the secundar's timestamp -- RLS alone would allow this row match; only the action's own column narrowing stops it (checked by inspecting confirmSessionAttendance, INFO below), but RLS itself is re-checked here at the row level to confirm the branch does not itself distinguish columns ----
  update public.sessions set trainer_secundar_confirmed_at = now() where id = v_session_open;
  get diagnostics v_row_count = row_count;
  select trainer_secundar_confirmed_at into v_secundar_confirmed from public.sessions where id = v_session_open;
  if v_row_count = 1 and v_secundar_confirmed is not null then
    report := report || E'\n2. INFO - as expected, RLS''s row match does not itself distinguish trainer_principal_confirmed_at from trainer_secundar_confirmed_at (the raw UPDATE above succeeded) -- confirmSessionAttendance (app/(app)/groups/actions.ts) is what actually enforces "a principal cannot write the secundar''s column": it reads the session first, compares the caller''s id against both slots, and includes exactly one of the two column keys in its own UPDATE payload -- an action-layer guarantee, not an RLS one, same division of labor as every prior capability-gated action this session';
  else
    report := report || E'\n2. FAIL - unexpected: the row match itself blocked a same-row column write';
  end if;
  update public.sessions set trainer_secundar_confirmed_at = null where id = v_session_open; -- undo, this session confirms as themselves below

  -- ---- 3. The secundar confirms their own session ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_secundar_confirmed_at = now() where id = v_session_open;
  select trainer_secundar_confirmed_at into v_secundar_confirmed from public.sessions where id = v_session_open;
  if v_secundar_confirmed is not null then
    report := report || E'\n3. PASS - the secundar (Test Trainer B2) can confirm their own session while the month is open';
  else
    report := report || E'\n3. FAIL - the secundar''s confirmation did not stick';
  end if;

  -- ---- 3b. Anka/Laura (finance.operations.*) can ALSO correct BEFORE close, not only after ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_secundar_confirmed_at = null where id = v_session_open;
  get diagnostics v_row_count = row_count;
  select trainer_secundar_confirmed_at into v_secundar_confirmed from public.sessions where id = v_session_open;
  if v_row_count = 1 and v_secundar_confirmed is null then
    report := report || E'\n3b. PASS - finance.operations.* (Test Contract Admin B, standing in for Anka/Laura) can correct the secundar''s confirmation BEFORE close too -- "before or after close" holds both ways, not just after';
  else
    report := report || E'\n3b. FAIL - the finance.operations.* correction branch did not admit the row before close';
  end if;
  update public.sessions set trainer_secundar_confirmed_at = now() where id = v_session_open; -- restore, so assertion 3''s state matches what the rest of the script expects

  -- ---- 4. Close this month (as finance.operations.*) ----
  insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
  values (v_org, v_this_month, now(), v_finance);
  report := report || E'\n4. INFO - this month closed by Test Contract Admin B (finance.operations.*)';

  -- ---- 5. The principal can no longer touch their own confirmation after close ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_principal_confirmed_at = null where id = v_session_open;
  get diagnostics v_row_count = row_count;
  if v_row_count = 0 then
    report := report || E'\n5. PASS - the principal cannot change their confirmation after their month closes (0 rows matched)';
  else
    report := report || E'\n5. FAIL - the principal was able to change their confirmation after close';
  end if;

  -- ---- 6. Attendance/experiment are ALSO blocked after close, not just confirmation -- Anca''s "cannot modify anything afterwards" is unqualified, and the close check sits on the whole trainer branch ----
  update public.sessions set attendance_count = 999 where id = v_session_open;
  get diagnostics v_row_count = row_count;
  if v_row_count = 0 then
    report := report || E'\n6. PASS - attendance_count is also blocked after close for the trainer -- the close gate sits on the whole trainer branch, not a copy scoped to the confirmation columns alone';
  else
    report := report || E'\n6. FAIL - the trainer could still write attendance_count after their month closed';
  end if;

  -- ---- 7. Anka (finance.operations.*) CAN correct after close ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_principal_confirmed_at = now() where id = v_session_open;
  get diagnostics v_row_count = row_count;
  if v_row_count = 1 then
    report := report || E'\n7. PASS - finance.operations.* (Test Contract Admin B, standing in for Anka/Laura) can correct the principal''s confirmation AFTER close';
  else
    report := report || E'\n7. FAIL - the finance.operations.* correction branch did not admit the row after close';
  end if;

  -- ---- 8. A session in a different, untouched month is unaffected by this month''s close ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  update public.sessions set trainer_principal_confirmed_at = now() where id = v_session_other;
  get diagnostics v_row_count = row_count;
  if v_row_count = 1 then
    report := report || E'\n8. PASS - the principal can still confirm a session in a different, open month -- closing this month did not affect it';
  else
    report := report || E'\n8. FAIL - a session in an untouched month was incorrectly blocked by another month''s close';
  end if;

  -- ---- 9. Operations (sessions.create) is unaffected by any of this ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  update public.sessions set status = 'confirmed' where id = v_session_open;
  get diagnostics v_row_count = row_count;
  if v_row_count = 1 then
    report := report || E'\n9. PASS - Test Ops Manager B (sessions.create) can still update the closed-month session -- the finance/trainer branches are additive, nothing narrowed the existing sessions.create branch';
  else
    report := report || E'\n9. FAIL - Operations lost its own existing access';
  end if;

  -- reset back to privileged context to clean up
  reset role;
  delete from public.sessions where id in (v_session_open, v_session_other);
  delete from public.groups where id = v_group;
  delete from public.contracts where id = v_contract;
  delete from public.clients where id = v_client;
  delete from public.payroll_periods where organization_id = v_org and period = v_this_month;

  raise exception E'VERIFICATION REPORT for 202609150002 (sessions confirmation columns + RLS), WOW LAB Test Org B (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
