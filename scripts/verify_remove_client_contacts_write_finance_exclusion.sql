-- verify_remove_client_contacts_write_finance_exclusion.sql
-- Dry-run verification for
-- supabase/migrations/202609110001_remove_client_contacts_write_finance_exclusion.sql.
--
-- Run with: supabase db query --linked --file scripts/verify_remove_client_contacts_write_finance_exclusion.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

DO $$
begin
  drop policy if exists "authenticated insert client_contacts" on public.client_contacts;
  create policy "authenticated insert client_contacts" on public.client_contacts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated update client_contacts" on public.client_contacts;
  create policy "authenticated update client_contacts" on public.client_contacts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated delete client_contacts" on public.client_contacts;
  create policy "authenticated delete client_contacts" on public.client_contacts
    for delete
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );
end;
$$;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_laura uuid := (select id from public.users where email = 'lauraflorentinaa220@gmail.com');
  v_anka uuid := (select id from public.users where email = 'anka@asismart.ro');
  v_trainer uuid := (select id from public.users where email = 'popar216@gmail.com');
  v_client_private uuid;
  v_client_corporate uuid;
  v_contact_id uuid;
  v_select_count int;
begin
  -- Mixed fixture, service-role (privileged context inside this DO block
  -- by default) -- one private_school client, one corporate client, so
  -- the read-segregation assertion has something real to distinguish.
  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client (private)', 'private_school')
  returning id into v_client_private;

  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client (corporate)', 'corporate')
  returning id into v_client_corporate;

  insert into public.client_contacts (organization_id, client_id, full_name)
  values (v_org, v_client_corporate, 'DRYRUN corporate contact');

  -- ---- 1. Laura (finance_operations + contract_administrator) can INSERT ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_laura::text, 'role', 'authenticated')::text, true);

  begin
    insert into public.client_contacts (organization_id, client_id, full_name)
    values (v_org, v_client_private, 'DRYRUN Laura contact')
    returning id into v_contact_id;
    report := report || E'\n1. PASS - Laura (finance_operations + contract_administrator) can INSERT a client contact';
  exception
    when insufficient_privilege then
      report := report || E'\n1. FAIL - Laura still blocked from INSERT';
  end;

  -- ---- 2. Laura can UPDATE it ----
  begin
    update public.client_contacts set role_at_client = 'test' where id = v_contact_id;
    report := report || E'\n2. PASS - Laura can UPDATE the contact she just created';
  exception
    when insufficient_privilege then
      report := report || E'\n2. FAIL - Laura still blocked from UPDATE';
  end;

  -- ---- 3. Read segregation still holds: Laura sees the private-school
  -- contact, not the corporate one (SELECT policy untouched) ----
  select count(*) into v_select_count from public.client_contacts where client_id = v_client_corporate;
  if v_select_count = 0 then
    report := report || E'\n3. PASS - Laura cannot see the corporate client''s contact (read segregation intact)';
  else
    report := report || E'\n3. FAIL - Laura can see the corporate client''s contact -- SELECT segregation broken';
  end if;

  select count(*) into v_select_count from public.client_contacts where client_id = v_client_private;
  if v_select_count >= 1 then
    report := report || E'\n3b. PASS - Laura can see the private-school client''s own contact';
  else
    report := report || E'\n3b. FAIL - Laura cannot see the private-school client''s own contact';
  end if;

  -- ---- 4. Laura can DELETE it ----
  begin
    delete from public.client_contacts where id = v_contact_id;
    report := report || E'\n4. PASS - Laura can DELETE the contact she created';
  exception
    when insufficient_privilege then
      report := report || E'\n4. FAIL - Laura still blocked from DELETE';
  end;

  -- ---- 5. Anka (both finance roles + contract_administrator) can INSERT, UPDATE, DELETE ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_anka::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.client_contacts (organization_id, client_id, full_name)
    values (v_org, v_client_private, 'DRYRUN Anka contact')
    returning id into v_contact_id;
    update public.client_contacts set role_at_client = 'test' where id = v_contact_id;
    delete from public.client_contacts where id = v_contact_id;
    report := report || E'\n5. PASS - Anka (both finance roles + contract_administrator) can INSERT, UPDATE, and DELETE a client contact';
  exception
    when insufficient_privilege then
      report := report || E'\n5. FAIL - Anka still blocked';
  end;

  -- ---- 6. A trainer (Raluca Popa) cannot INSERT ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.client_contacts (organization_id, client_id, full_name)
    values (v_org, v_client_private, 'DRYRUN trainer contact');
    report := report || E'\n6. FAIL - a trainer was able to INSERT a client contact';
  exception
    when insufficient_privilege then
      report := report || E'\n6. PASS - a trainer (Raluca Popa) still cannot INSERT a client contact';
  end;

  -- reset back to privileged context to clean up the fixtures
  reset role;
  delete from public.client_contacts where client_id in (v_client_private, v_client_corporate);
  delete from public.clients where id in (v_client_private, v_client_corporate);

  raise exception E'VERIFICATION REPORT for 202609110001 (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
