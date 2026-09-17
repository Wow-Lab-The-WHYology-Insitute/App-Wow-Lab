-- verify_users_trainer_name_visibility.sql
-- Live verification of 202609160001 against WOW LAB Test Org B.
-- Run with: supabase db query --linked --file scripts/verify_users_trainer_name_visibility.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Everything here runs inside one transaction that always rolls back.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_principal uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  v_secundar uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
  v_other_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com'); -- not on this session
  v_finance uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev');
  v_owner uuid := (select id from public.users where email = 'test+ui-org-b@wowlab.dev'); -- to check finance can NOT see via the new branch
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where name = 'WOW LAB Test Org B') and name = 'Test Entity SRL');
  v_client uuid;
  v_contract uuid;
  v_group uuid;
  v_session uuid;
  v_visible boolean;
begin
  if v_principal is null or v_secundar is null or v_other_trainer is null or v_finance is null or v_owner is null then
    raise exception 'Fixture lookup failed.';
  end if;

  insert into public.clients (organization_id, name, client_type) values (v_org, 'DRYRUN verify client (users visibility)', 'private_school') returning id into v_client;
  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type) values (v_org, v_client, v_legal_entity, 'recurring_annual') returning id into v_contract;
  insert into public.groups (organization_id, client_id, contract_id, module, delivery_format) values (v_org, v_client, v_contract, 'gaga', 'recurring') returning id into v_group;
  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, current_date, v_principal, v_secundar, 'planned') returning id into v_session;

  -- ---- 1. finance.operations.* can see a trainer's row ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.users where id = v_principal) into v_visible;
  if v_visible then
    report := report || E'\n1. PASS - finance.operations.* (Test Contract Admin B) can see a trainer''s row';
  else
    report := report || E'\n1. FAIL - finance.operations.* cannot see a trainer''s row';
  end if;

  -- ---- 2. finance.operations.* cannot see a NON-trainer's row (the owner) through the new branch ----
  select exists(select 1 from public.users where id = v_owner) into v_visible;
  if not v_visible then
    report := report || E'\n2. PASS - finance.operations.* cannot see a non-trainer''s row (Test Org B Owner) -- the new branch is scoped to the trainer role, not org-wide';
  else
    report := report || E'\n2. FAIL - finance.operations.* can see a non-trainer''s row -- broader than intended';
  end if;

  -- ---- 3. The principal can see their co-trainer (secundar) on a shared session ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.users where id = v_secundar) into v_visible;
  if v_visible then
    report := report || E'\n3. PASS - the principal (Test Trainer B1) can see their co-trainer''s (B2) row on a shared session';
  else
    report := report || E'\n3. FAIL - the principal cannot see their co-trainer''s row';
  end if;

  -- ---- 4. The principal cannot see an UNRELATED trainer's row (not on any shared session) ----
  select exists(select 1 from public.users where id = v_other_trainer) into v_visible;
  if not v_visible then
    report := report || E'\n4. PASS - the principal cannot see an unrelated trainer (Test Trainer B3, no shared session) -- the new branch is session-scoped, not trainer-to-trainer org-wide';
  else
    report := report || E'\n4. FAIL - the principal can see an unrelated trainer -- broader than intended';
  end if;

  reset role;
  delete from public.sessions where id = v_session;
  delete from public.groups where id = v_group;
  delete from public.contracts where id = v_contract;
  delete from public.clients where id = v_client;

  raise exception E'VERIFICATION REPORT for 202609160001 (users trainer-name visibility), WOW LAB Test Org B (transaction WILL roll back):%', report;
end;
$verify$;

rollback;
