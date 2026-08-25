-- verify_client_contacts_delete.sql
-- Dry-run verification for supabase/migrations/202608270001_client_contacts_delete.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the policy+grant DDL, seeds two throwaway contacts, exercises one
-- authorized delete and one unauthorized attempt, checks row_history on
-- the successful delete, then RAISES an exception whose message IS the
-- full report -- so the transaction can never commit, on purpose, even if
-- every assertion passes.
--
-- Run with: supabase db query --linked --file scripts/verify_client_contacts_delete.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608270001's DDL exactly.
-- ============================================================================

create policy "authenticated delete client_contacts" on public.client_contacts
  for delete
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or app.has_capability('clients.create', organization_id)
    or (
      app.has_capability('contracts.*', organization_id)
      and not app.has_capability('finance.reporting.*', organization_id)
      and not app.has_capability('finance.operations.*', organization_id)
    )
  );

grant delete on public.client_contacts to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, seed two throwaway
-- contacts (one for each half of the test) before the one role switch.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_contract_admin', (select id::text from users where email = 'test+ui-contract-admin@wowlab.dev'), true);
select set_config('app.test_ops', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.test_owner', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.lycee_client', (select client_id::text from client_contacts limit 1), true);

with ins as (
  insert into client_contacts (organization_id, client_id, full_name)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, 'VERIFY Delete Authorized')
  returning id
)
select set_config('app.contact_authorized', id::text, true) from ins;

with ins as (
  insert into client_contacts (organization_id, client_id, full_name)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, 'VERIFY Delete Unauthorized')
  returning id
)
select set_config('app.contact_unauthorized', id::text, true) from ins;

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_contract_admin uuid := current_setting('app.test_contract_admin')::uuid;
  v_ops uuid := current_setting('app.test_ops')::uuid;
  v_owner uuid := current_setting('app.test_owner')::uuid;
  v_contact_authorized uuid := current_setting('app.contact_authorized')::uuid;
  v_contact_unauthorized uuid := current_setting('app.contact_unauthorized')::uuid;
  v_count int;
  v_actor uuid;
  v_old_name text;
begin
  -- ---- 1. contract_administrator (contracts.* without finance) can delete ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_contract_admin::text, 'role', 'authenticated')::text, true);

  delete from client_contacts where id = v_contact_authorized;

  select count(*) into v_count from client_contacts where id = v_contact_authorized;
  if v_count = 0 then
    report := report || E'\n1. PASS - contract_administrator deleted the authorized throwaway contact';
  else
    report := report || E'\n1. FAIL - the row still exists after a contract_administrator delete attempt';
  end if;

  -- ---- 2. operations_manager (no clients.create, no contracts.*) cannot delete ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);

  delete from client_contacts where id = v_contact_unauthorized;

  select count(*) into v_count from client_contacts where id = v_contact_unauthorized;
  if v_count = 1 then
    report := report || E'\n2. PASS - operations_manager could not delete the row (RLS silently matched 0 rows, no error)';
  else
    report := report || E'\n2. FAIL - the row is gone; operations_manager should not have been able to delete it';
  end if;

  -- ---- 3. row_history captured the successful delete, with the real actor ----
  -- Switch jwt.claims (not role -- still 'authenticated') to
  -- test+ui-owner@wowlab.dev, which holds org.audit.read: RLS SELECT
  -- visibility on row_history depends on the READER's capability, not on
  -- who wrote the row (same reasoning as
  -- scripts/verify_row_history_actor_user_id.sql). Neither
  -- contract_administrator nor operations_manager holds org.audit.read,
  -- so reading back under either of them would show 0 rows regardless of
  -- whether the trigger fired correctly.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);

  select actor_user_id, old_values ->> 'full_name' into v_actor, v_old_name
  from row_history
  where table_name = 'client_contacts' and row_id = v_contact_authorized
  order by changed_at desc limit 1;

  if v_actor = v_contract_admin and v_old_name = 'VERIFY Delete Authorized' then
    report := report || E'\n3. PASS - row_history captured the delete: actor matches contract_administrator, old_values has the pre-delete name';
  else
    report := report || format(E'\n3. FAIL - expected actor=%s name=''VERIFY Delete Authorized'', got actor=%s name=%s', v_contract_admin, v_actor, v_old_name);
  end if;

  raise exception E'VERIFICATION REPORT for 202608270001_client_contacts_delete.sql (transaction WILL roll back -- nothing above or below this point was committed, including both seeded VERIFY contacts):%', report;
end;
$verify$;

rollback;
