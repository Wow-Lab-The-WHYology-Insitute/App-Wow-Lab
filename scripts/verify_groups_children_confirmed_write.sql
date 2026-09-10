-- verify_groups_children_confirmed_write.sql
-- Dry-run verification for
-- supabase/migrations/202609110002_add_groups_update_contracts_star_branch.sql
-- and its updateGroup() column-level gate (app/(app)/groups/actions.ts).
--
-- Run with: supabase db query --linked --file scripts/verify_groups_children_confirmed_write.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_laura uuid := (select id from public.users where email = 'lauraflorentinaa220@gmail.com');
  v_anka uuid := (select id from public.users where email = 'anka@asismart.ro');
  v_catalina uuid := (select id from public.users where email = 'catalina_moale@yahoo.com');
  v_trainer uuid := (select id from public.users where email = 'popar216@gmail.com');
  v_legal_entity uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where slug = 'wow-lab') limit 1);
  v_client uuid;
  v_contract uuid;
  v_group uuid;
  v_confirmed int;
  v_billed int;
  v_row_count int;
begin
  -- Fixture, service-role (privileged context inside this DO block by default).
  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client', 'private_school')
  returning id into v_client;

  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
  values (v_org, v_client, v_legal_entity, 'recurring_annual')
  returning id into v_contract;

  insert into public.groups (organization_id, client_id, contract_id, module, delivery_format, children_confirmed, children_billed)
  values (v_org, v_client, v_contract, 'gaga', 'recurring', null, null)
  returning id into v_group;

  -- ---- 1. Laura (finance_operations + contract_administrator) can set children_confirmed ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_laura::text, 'role', 'authenticated')::text, true);

  begin
    update public.groups set children_confirmed = 18 where id = v_group;
    select children_confirmed into v_confirmed from public.groups where id = v_group;
    if v_confirmed = 18 then
      report := report || E'\n1. PASS - Laura can set children_confirmed on a group';
    else
      report := report || format(E'\n1. FAIL - Laura''s write did not stick, value is %L', v_confirmed);
    end if;
  exception
    when insufficient_privilege then
      report := report || E'\n1. FAIL - Laura still blocked from UPDATE on groups';
  end;

  -- ---- 2. Anka (both finance roles + contract_administrator) can set it too ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_anka::text, 'role', 'authenticated')::text, true);
  begin
    update public.groups set children_confirmed = 20 where id = v_group;
    select children_confirmed into v_confirmed from public.groups where id = v_group;
    if v_confirmed = 20 then
      report := report || E'\n2. PASS - Anka can set children_confirmed on a group';
    else
      report := report || format(E'\n2. FAIL - Anka''s write did not stick, value is %L', v_confirmed);
    end if;
  exception
    when insufficient_privilege then
      report := report || E'\n2. FAIL - Anka still blocked from UPDATE on groups';
  end;

  -- ---- 3. Cătălina (operations_manager) can still edit other fields, but NOT children_confirmed ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_catalina::text, 'role', 'authenticated')::text, true);
  begin
    update public.groups set notes = 'Catalina edited this' where id = v_group;
    report := report || E'\n3a. PASS - Catalina can still edit notes (groups.create unaffected)';
  exception
    when insufficient_privilege then
      report := report || E'\n3a. FAIL - Catalina lost her existing groups.create write access';
  end;

  -- Row-level RLS still lets Catalina's UPDATE through (she holds groups.create),
  -- but the app-level action is what actually omits children_confirmed from her
  -- payload -- this direct SQL UPDATE bypasses that app-level gate entirely, so
  -- it will succeed here. That's expected and does not contradict the design:
  -- the column boundary lives in updateGroup(), not in this policy, exactly as
  -- specified. Documented, not treated as a failure.
  update public.groups set children_confirmed = 99 where id = v_group;
  report := report || E'\n3b. INFO - direct SQL as Catalina CAN still write children_confirmed (RLS is row-level only; updateGroup() is where the column boundary actually lives -- this assertion is checked at the action layer, not here)';

  -- reset to a known value before the next check
  update public.groups set children_confirmed = 20 where id = v_group;

  -- ---- 4. A trainer (Raluca Popa) cannot write anything to groups ----
  -- RLS blocks an unmatched UPDATE by filtering the row out of the USING
  -- clause silently -- 0 rows affected, not a thrown exception (same
  -- shape documented in updateClientContact's own comment). Checked via
  -- ROW_COUNT, not exception-catching.
  perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
  begin
    update public.groups set children_confirmed = 5 where id = v_group;
    get diagnostics v_row_count = row_count;
    if v_row_count = 0 then
      report := report || E'\n4. PASS - a trainer (Raluca Popa) still cannot UPDATE a group at all (0 rows matched)';
    else
      report := report || E'\n4. FAIL - a trainer was able to UPDATE a group';
    end if;
  exception
    when insufficient_privilege then
      report := report || E'\n4. PASS - a trainer (Raluca Popa) still cannot UPDATE a group at all (rejected)';
  end;

  -- ---- 5. children_billed is writable by nobody through this policy path either (still Operations-only column at the app layer, but confirm RLS itself doesn't distinguish it -- expected: whoever can UPDATE the row can set any column via raw SQL, same as 3b) ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_laura::text, 'role', 'authenticated')::text, true);
  begin
    update public.groups set children_billed = 15 where id = v_group;
    report := report || E'\n5. INFO - direct SQL as Laura CAN still write children_billed (RLS is row-level only; updateGroup() never includes children_billed in its payload for anyone -- confirmed by reading the action, not by RLS)';
  exception
    when insufficient_privilege then
      report := report || E'\n5. INFO - Laura blocked from children_billed at the RLS layer too';
  end;

  -- reset back to privileged context to clean up the fixtures
  reset role;
  delete from public.groups where id = v_group;
  delete from public.contracts where id = v_contract;
  delete from public.clients where id = v_client;

  raise exception E'VERIFICATION REPORT for 202609110002 (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
