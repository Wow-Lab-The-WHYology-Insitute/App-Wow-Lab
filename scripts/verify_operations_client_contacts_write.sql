-- verify_operations_client_contacts_write.sql
-- Dry-run of 202609210004 against WOW LAB Test Org B: applies the exact
-- INSERT/UPDATE policy DDL that migration contains, then asserts, all
-- inside one transaction that always rolls back -- same shape as
-- scripts/verify_client_contacts_trainer_facing_scoping.sql.
-- Run with: supabase db query --linked --file scripts/verify_operations_client_contacts_write.sql

begin;

DO $$
begin
  drop policy "authenticated insert client_contacts" on public.client_contacts;
  create policy "authenticated insert client_contacts" on public.client_contacts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
      or app.has_capability('operations.*', organization_id)
    );

  drop policy "authenticated update client_contacts" on public.client_contacts;
  create policy "authenticated update client_contacts" on public.client_contacts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
      or app.has_capability('operations.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
      or app.has_capability('operations.*', organization_id)
    );
end;
$$;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  -- operations_manager: holds operations.*, clients.read -- NOT
  -- clients.create or contracts.* -- exactly Catalina's real shape.
  v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
  -- trainer: holds mywork.* only.
  v_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  -- contract_administrator AND finance_operations both -- holds
  -- clients.read/contracts.* (would satisfy the non-finance SELECT
  -- branch) AND finance.operations.* (which excludes them from it),
  -- landing them on the finance.operations.* branch alone -- private_
  -- school/parent_b2c only. The right fixture to prove finance
  -- segregation is unweakened even for someone who ALSO holds a broad
  -- write capability.
  v_finance uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev');
  v_client uuid;
  v_contact uuid;
  v_rows int;
  v_visible boolean;
  v_insert_failed boolean := false;
begin
  if v_ops is null or v_trainer is null or v_finance is null then
    raise exception 'Fixture lookup failed.';
  end if;

  -- corporate, not private_school/parent_b2c -- puts it on finance_
  -- operations' EXCLUDED side, so assertion 5 below is a real negative.
  insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN verify client (item 80, ops write)', 'corporate') returning id into v_client;

  set local role authenticated;

  -- ---- 1. operations_manager CAN insert a contact on any client ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
      values (v_org, v_client, 'DRYRUN Ops-Created Contact', '0700000010', 'general')
      returning id into v_contact;
    report := report || E'\n1. PASS - operations_manager (Catalina''s shape) can INSERT a client_contacts row on any client';
  exception when insufficient_privilege or others then
    v_insert_failed := true;
    report := report || E'\n1. FAIL - operations_manager could not INSERT: ' || sqlerrm;
  end;

  if v_insert_failed then
    raise exception '%', report;
  end if;

  -- ---- 2. operations_manager CAN edit it (the named real need: correcting a phone typo) ----
  update public.client_contacts set phone = '0700000099' where id = v_contact;
  get diagnostics v_rows = row_count;
  if v_rows = 1 then
    report := report || E'\n2. PASS - operations_manager can UPDATE the contact (phone correction)';
  else
    report := report || E'\n2. FAIL - operations_manager could not UPDATE the contact';
  end if;

  -- ---- 3. operations_manager CANNOT delete it -- not granted, deliberately ----
  delete from public.client_contacts where id = v_contact;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    report := report || E'\n3. PASS - operations_manager cannot DELETE the contact (not granted, item 80)';
  else
    report := report || E'\n3. FAIL - operations_manager deleted the contact -- DELETE should not have been granted';
  end if;

  -- ---- 4. A trainer still cannot create a contact ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
      values (v_org, v_client, 'DRYRUN Trainer-Attempted Contact', '0700000020', 'general');
    report := report || E'\n4. FAIL - a trainer was able to INSERT a client_contacts row -- should have been rejected';
  exception when insufficient_privilege or others then
    report := report || E'\n4. PASS - a trainer cannot INSERT a client_contacts row (mywork.* only, not operations.*/clients.create/contracts.*)';
  end;

  -- ---- 5. Finance SELECT segregation is unweakened, even for a user who ALSO holds contracts.*/clients.read ----
  -- v_finance holds finance.operations.* (private_school/parent_b2c only)
  -- AND contracts.*/clients.read (which would otherwise satisfy the
  -- broader non-finance branch) -- this client is 'corporate', so if
  -- segregation is intact, they see nothing here despite the broader
  -- capabilities they also hold.
  reset role;
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact) into v_visible;
  if not v_visible then
    report := report || E'\n5. PASS - finance.operations.* (via contract_administrator+finance_operations combo) still cannot see a corporate client''s contact -- segregation unweakened by this migration';
  else
    report := report || E'\n5. FAIL - finance segregation leaked -- a finance.operations.* holder saw a non-private_school/parent_b2c contact';
  end if;

  -- ---- 6. Sanity: operations_manager can still read what they created (SELECT untouched, still reachable via clients.read) ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact) into v_visible;
  if v_visible then
    report := report || E'\n6. PASS - operations_manager can read the contact it created (clients.read branch, unchanged)';
  else
    report := report || E'\n6. FAIL - operations_manager cannot read its own created contact';
  end if;

  raise exception '%', report;
end;
$verify$;

rollback;
