-- verify_contracts_signed_date_status_check.sql
-- Dry-run verification for
-- supabase/migrations/202609020003_add_contracts_signed_date_status_check.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Table-level constraint, no backfill possible (contracts is empty).
-- Verifies: the constraint rejects draft+signed_date, accepts
-- signed+signed_date, accepts a null signed_date at draft and at sent,
-- markContractSigned's exact UPDATE shape (status+signed_date together)
-- still succeeds, and addContract's new INSERT shape (status='draft',
-- no signed_date key at all) still succeeds -- the same shape the real
-- create form now sends after this round's removal of the field.
--
-- Run with: supabase db query --linked --file scripts/verify_contracts_signed_date_status_check.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202609020003's DDL exactly.
-- ============================================================================

alter table public.contracts
  add constraint contracts_signed_date_status_check
    check (signed_date is null or status in ('signed', 'expired', 'renewed'));

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures. clients is empty
-- post-purge, so a throwaway client is inserted here too, rolled back
-- with everything else.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_entity', (select id::text from legal_entities where organization_id = (select id from organizations where slug = 'wow-lab') limit 1), true);
select set_config('app.test_contract_admin', (select id::text from users where email = 'test+contract-admin-a@wowlab.dev'), true);

insert into clients (organization_id, name, client_type, status)
values (current_setting('app.test_org_a')::uuid, 'VERIFY-SIGNED-DATE-CHECK', 'private_school', 'active');

select set_config('app.test_client', (select id::text from clients where name = 'VERIFY-SIGNED-DATE-CHECK'), true);

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_contract_admin'), 'role', 'authenticated')::text, true);

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_org uuid := current_setting('app.test_org_a')::uuid;
  v_entity uuid := current_setting('app.test_entity')::uuid;
  v_client uuid := current_setting('app.test_client')::uuid;
  v_sqlstate text;
  v_insert_id uuid;
  v_signed_id uuid;
  v_row_count int;
begin
  -- ---- 1. draft + signed_date is rejected ----
  begin
    insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, signed_date)
    values (v_org, v_client, v_entity, 'one_off_event', 'draft', current_date);
    report := report || E'\n1. FAIL - expected check_violation for status=draft with signed_date set, but the insert succeeded';
  exception
    when check_violation then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n1. PASS - draft + signed_date raised check_violation (sqlstate %s)', v_sqlstate);
  end;

  -- ---- 2. signed + signed_date is accepted ----
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, signed_date)
  values (v_org, v_client, v_entity, 'one_off_event', 'signed', current_date)
  returning id into v_signed_id;

  if v_signed_id is not null then
    report := report || E'\n2. PASS - status=signed with signed_date set succeeds';
  else
    report := report || E'\n2. FAIL - the signed+signed_date insert did not return an id';
  end if;

  -- ---- 3a. null signed_date accepted at draft ----
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, signed_date)
  values (v_org, v_client, v_entity, 'one_off_event', 'draft', null)
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n3a. PASS - status=draft with signed_date=null succeeds';
  else
    report := report || E'\n3a. FAIL - the draft+null insert did not return an id';
  end if;

  -- ---- 3b. null signed_date accepted at sent ----
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, signed_date)
  values (v_org, v_client, v_entity, 'one_off_event', 'sent', null)
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n3b. PASS - status=sent with signed_date=null succeeds';
  else
    report := report || E'\n3b. FAIL - the sent+null insert did not return an id';
  end if;

  -- ---- 4. markContractSigned's exact UPDATE shape still works end to
  -- end -- a fresh draft row, transitioned the same way the action does:
  -- status and signed_date set together in one UPDATE, filtered by the
  -- same .in("status", ["draft","sent"]) guard. ----
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, status, signed_date)
  values (v_org, v_client, v_entity, 'one_off_event', 'draft', null)
  returning id into v_insert_id;

  update contracts
  set status = 'signed', signed_date = current_date
  where id = v_insert_id
    and status in ('draft', 'sent');

  get diagnostics v_row_count = row_count;

  if v_row_count = 1 then
    report := report || E'\n4. PASS - markContractSigned''s exact UPDATE shape (status+signed_date together, filtered by draft/sent) still succeeds against the new constraint';
  else
    report := report || format(E'\n4. FAIL - expected 1 row updated, got %s', v_row_count);
  end if;

  -- ---- 5. addContract's new INSERT shape (no signed_date key at all,
  -- matching the real create form after this round's field removal)
  -- still succeeds. ----
  insert into contracts (organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, billing_rule, estimated_value, previous_year_value, status)
  values (v_org, v_client, v_entity, 'one_off_event', null, null, null, null, null, 'draft')
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n5. PASS - addContract''s new INSERT shape (status=draft, signed_date omitted entirely) still succeeds';
  else
    report := report || E'\n5. FAIL - the addContract-shaped insert did not return an id';
  end if;

  raise exception E'VERIFICATION REPORT for 202609020003_add_contracts_signed_date_status_check.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
