-- verify_remove_contracts_write_finance_exclusion.sql
-- Dry-run verification for
-- supabase/migrations/202609080001_remove_contracts_write_finance_exclusion.sql.
--
-- Run with: supabase db query --linked --file scripts/verify_remove_contracts_write_finance_exclusion.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

DO $$
begin
  drop policy if exists "authenticated insert contracts" on public.contracts;
  create policy "authenticated insert contracts" on public.contracts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated update contracts" on public.contracts;
  create policy "authenticated update contracts" on public.contracts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated delete contracts" on public.contracts;
  create policy "authenticated delete contracts" on public.contracts
    for delete
    to authenticated
    using (
      (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('contracts.*', organization_id)
      )
      and status = 'draft'
    );
end;
$$;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_laura uuid := (select id from public.users where email = 'lauraflorentinaa220@gmail.com');
  v_trainer uuid := (select id from public.users where email = 'popar216@gmail.com');
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where slug = 'wow-lab') limit 1);
  v_client uuid;
  v_contract_id uuid;
  v_caught boolean;
begin
  -- Fixture client, service-role (privileged context inside this DO block by default).
  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client', 'private_school')
  returning id into v_client;

  -- ---- 1. Laura (finance_operations + contract_administrator) can INSERT ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_laura::text, 'role', 'authenticated')::text, true);

  begin
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
    values (v_org, v_client, v_legal_entity, 'recurring_annual')
    returning id into v_contract_id;
    report := report || E'\n1. PASS - Laura (finance_operations + contract_administrator) can INSERT a contract';
  exception
    when insufficient_privilege then
      report := report || E'\n1. FAIL - Laura still blocked from INSERT';
  end;

  -- ---- 2. Laura can UPDATE it ----
  begin
    update public.contracts set billing_rule = 'test' where id = v_contract_id;
    report := report || E'\n2. PASS - Laura can UPDATE the contract she just created';
  exception
    when insufficient_privilege then
      report := report || E'\n2. FAIL - Laura still blocked from UPDATE';
  end;

  -- ---- 3. Laura can DELETE it (still draft) ----
  begin
    delete from public.contracts where id = v_contract_id;
    get diagnostics v_caught = row_count;
    report := report || E'\n3. PASS - Laura can DELETE the draft contract she created';
  exception
    when insufficient_privilege then
      report := report || E'\n3. FAIL - Laura still blocked from DELETE';
  end;

  -- ---- 4. A trainer (Raluca Popa) cannot INSERT ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
    values (v_org, v_client, v_legal_entity, 'recurring_annual');
    report := report || E'\n4. FAIL - a trainer was able to INSERT a contract';
  exception
    when insufficient_privilege then
      report := report || E'\n4. PASS - a trainer (Raluca Popa) still cannot INSERT a contract';
  end;

  -- reset back to privileged context to clean up the fixture client
  reset role;
  delete from public.clients where id = v_client;

  raise exception E'VERIFICATION REPORT for 202609080001 (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
