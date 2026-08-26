-- verify_contracts_delete.sql
-- Dry-run verification for supabase/migrations/202608280001_contracts_delete.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the policy+grant DDL, seeds four throwaway contracts (a plain
-- draft, a signed one, and a self-referencing renewal_of pair), exercises
-- one authorized delete, two blocked deletes (wrong role, wrong status),
-- and the foreign-key-violation path -- which is UNTESTABLE with real
-- data today (confirmed live before writing this: zero contracts have
-- renewal_of set anywhere in production) -- then checks row_history on
-- the successful delete, then RAISES an exception whose message IS the
-- full report so the transaction can never commit, on purpose, even if
-- every assertion passes.
--
-- Run with: supabase db query --linked --file scripts/verify_contracts_delete.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608280001's DDL exactly.
-- ============================================================================

create policy "authenticated delete contracts" on public.contracts
  for delete
  to authenticated
  using (
    (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    )
    and status = 'draft'
  );

grant delete on public.contracts to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, seed four throwaway
-- contracts before the one role switch.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_contract_admin', (select id::text from users where email = 'test+ui-contract-admin@wowlab.dev'), true);
select set_config('app.test_ops', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.test_owner', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.lycee_client', '0440552d-5664-49c6-a606-8b47ca073631', true);
select set_config('app.legal_entity', 'b684d1a5-6cba-4a10-94fe-5eab9318dc60', true);

-- Plain draft, no relations -- the one that will actually get deleted.
with ins as (
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, entry_number)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, current_setting('app.legal_entity')::uuid, 'one_off_event', 'draft', 'VERIFY-PLAIN-DRAFT')
  returning id
)
select set_config('app.plain_draft', id::text, true) from ins;

-- Signed contract -- otherwise-authorized caller, but status != draft.
with ins as (
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, entry_number)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, current_setting('app.legal_entity')::uuid, 'one_off_event', 'signed', 'VERIFY-SIGNED')
  returning id
)
select set_config('app.signed_c', id::text, true) from ins;

-- Self-referencing pair: self_y.renewal_of = self_x.id -- constructs the
-- FK-violation path that cannot exist with real data today.
with ins as (
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, entry_number)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, current_setting('app.legal_entity')::uuid, 'one_off_event', 'draft', 'VERIFY-SELF-X')
  returning id
)
select set_config('app.self_x', id::text, true) from ins;

with ins as (
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, entry_number, renewal_of)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.lycee_client')::uuid, current_setting('app.legal_entity')::uuid, 'one_off_event', 'draft', 'VERIFY-SELF-Y', current_setting('app.self_x')::uuid)
  returning id
)
select set_config('app.self_y', id::text, true) from ins;

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
  v_plain_draft uuid := current_setting('app.plain_draft')::uuid;
  v_signed_c uuid := current_setting('app.signed_c')::uuid;
  v_self_x uuid := current_setting('app.self_x')::uuid;
  v_count int;
  v_actor uuid;
  v_old_entry text;
  v_fk_caught boolean := false;
  v_fk_sqlstate text;
begin
  -- ---- 1. contract_administrator deletes a plain draft: succeeds ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_contract_admin::text, 'role', 'authenticated')::text, true);

  delete from contracts where id = v_plain_draft;

  select count(*) into v_count from contracts where id = v_plain_draft;
  if v_count = 0 then
    report := report || E'\n1. PASS - contract_administrator deleted a plain draft contract';
  else
    report := report || E'\n1. FAIL - the plain draft still exists after a contract_administrator delete attempt';
  end if;

  -- ---- 2. contract_administrator (otherwise authorized) cannot delete a signed contract ----
  delete from contracts where id = v_signed_c;

  select count(*) into v_count from contracts where id = v_signed_c;
  if v_count = 1 then
    report := report || E'\n2. PASS - contract_administrator could not delete a signed contract (status condition held, RLS matched 0 rows, no error)';
  else
    report := report || E'\n2. FAIL - the signed contract is gone; the AND status = ''draft'' condition did not hold';
  end if;

  -- ---- 3. operations_manager (no contracts.*/org.settings.manage) cannot delete a draft ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);

  delete from contracts where id = v_self_x;

  select count(*) into v_count from contracts where id = v_self_x;
  if v_count = 1 then
    report := report || E'\n3. PASS - operations_manager could not delete a draft contract (capability condition held, RLS matched 0 rows, no error)';
  else
    report := report || E'\n3. FAIL - the draft contract is gone; operations_manager should not have been able to delete it';
  end if;

  -- ---- 4. FK violation: deleting a draft another contract's renewal_of points at ----
  -- Back to contract_administrator -- otherwise fully authorized, and the
  -- target IS a draft, so the ONLY thing that can block this is the FK.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_contract_admin::text, 'role', 'authenticated')::text, true);

  begin
    delete from contracts where id = v_self_x;
    report := report || E'\n4. FAIL - expected a foreign_key_violation (23503) deleting a draft referenced by another contract''s renewal_of, but the delete succeeded';
  exception
    when foreign_key_violation then
      get stacked diagnostics v_fk_sqlstate = returned_sqlstate;
      v_fk_caught := true;
      report := report || format(E'\n4. PASS - deleting a draft referenced by another contract''s renewal_of raised foreign_key_violation (sqlstate %s) -- confirmed the FK still fires; this scenario has zero real occurrences in production today, so this is the ONLY way to exercise it', v_fk_sqlstate);
  end;

  -- ---- 5. row_history captured the successful delete (assertion 1), with the real actor ----
  -- Switch jwt.claims to test+ui-owner@wowlab.dev (org.audit.read) before
  -- reading row_history back -- same reasoning as
  -- scripts/verify_client_contacts_delete.sql: RLS SELECT visibility on
  -- row_history depends on the READER's capability, not the writer's, and
  -- neither contract_administrator nor operations_manager holds
  -- org.audit.read.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);

  select actor_user_id, old_values ->> 'entry_number' into v_actor, v_old_entry
  from row_history
  where table_name = 'contracts' and row_id = v_plain_draft
  order by changed_at desc limit 1;

  if v_actor = v_contract_admin and v_old_entry = 'VERIFY-PLAIN-DRAFT' then
    report := report || E'\n5. PASS - row_history captured the delete: actor matches contract_administrator, old_values has the pre-delete entry_number';
  else
    report := report || format(E'\n5. FAIL - expected actor=%s entry_number=''VERIFY-PLAIN-DRAFT'', got actor=%s entry_number=%s', v_contract_admin, v_actor, v_old_entry);
  end if;

  raise exception E'VERIFICATION REPORT for 202608280001_contracts_delete.sql (transaction WILL roll back -- nothing above or below this point was committed, including all four seeded VERIFY contracts):%', report;
end;
$verify$;

rollback;
