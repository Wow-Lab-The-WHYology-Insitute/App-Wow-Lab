-- verify_payroll_periods_close.sql
-- Live verification of 202609150001 (payroll_periods) against WOW LAB
-- Test Org B: who may close, who may not despite holding a
-- coincidentally-overlapping capability, an absent row reading as open,
-- and closing twice being rejected.
--
-- Run with: supabase db query --linked --file scripts/verify_payroll_periods_close.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Everything here runs inside one transaction that always rolls back.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_finance uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'); -- holds contracts.* AND finance.operations.*
  v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'); -- operations_manager: neither contracts.* nor finance.operations.*
  v_contracts_only uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com'); -- Test Trainer B3, given a temporary contracts.* grant below, WITHOUT finance.operations.*
  v_contract_admin_role_id uuid := (select id from public.roles where key = 'contract_administrator');
  v_row_count int;
  v_period_1 date := date_trunc('month', current_date)::date;
  v_period_2 date := (date_trunc('month', current_date) + interval '1 month')::date;
  v_closed_at timestamptz;
  v_exists boolean;
begin
  if v_org is null or v_finance is null or v_ops is null or v_contracts_only is null or v_contract_admin_role_id is null then
    raise exception 'Fixture lookup failed. org=%, finance=%, ops=%, contracts_only=%, role=%',
      v_org, v_finance, v_ops, v_contracts_only, v_contract_admin_role_id;
  end if;

  -- Give Test Trainer B3 a temporary, transaction-scoped contracts.* grant
  -- (Contract Administrator role) so assertion 3 can isolate contracts.*
  -- alone, without finance.operations.* riding along -- the real-world
  -- fixture (test+ui-contract-admin-b@wowlab.dev) holds both, which can't
  -- tell the two capabilities apart.
  insert into public.user_org_roles (user_id, organization_id, role_id)
  values (v_contracts_only, v_org, v_contract_admin_role_id);

  -- ---- 1. Absent row reads as open, not closed ----
  select exists (
    select 1 from public.payroll_periods
    where organization_id = v_org and period = v_period_1 and closed_at is not null
  ) into v_exists;
  if v_exists is false then
    report := report || E'\n1. PASS - no payroll_periods row exists yet for this month, and the standard "closed" query (exists ... and closed_at is not null) correctly reads that as open, not closed';
  else
    report := report || E'\n1. FAIL - an absent row read as closed';
  end if;

  -- ---- 2. finance.operations.* (Test Contract Admin B) can close ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
  values (v_org, v_period_1, now(), v_finance);
  select closed_at into v_closed_at from public.payroll_periods where organization_id = v_org and period = v_period_1;
  if v_closed_at is not null then
    report := report || E'\n2. PASS - finance.operations.* (Test Contract Admin B) can close a month';
  else
    report := report || E'\n2. FAIL - the close insert did not stick';
  end if;

  -- ---- 3. contracts.* alone (no finance.operations.*) cannot close a different month ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_contracts_only::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (v_org, v_period_2, now(), v_contracts_only);
    report := report || E'\n3. FAIL - contracts.* alone was able to close a month -- this is the exact coincidence-of-role mistake the design was meant to avoid';
  exception when insufficient_privilege then
    report := report || E'\n3. PASS - contracts.* alone (Test Trainer B3, granted Contract Administrator but not Finance Operations) cannot close a month -- confirms finance.operations.*, not contracts.*, is the real gate';
  end;

  -- ---- 4. Operations (neither contracts.* nor finance.operations.*) cannot close ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (v_org, v_period_2, now(), v_ops);
    report := report || E'\n4. FAIL - Test Ops Manager B was able to close a month';
  exception when insufficient_privilege then
    report := report || E'\n4. PASS - Test Ops Manager B (operations_manager, neither capability) cannot close a month';
  end;

  -- ---- 5. Closing the same month twice is rejected (unique constraint) ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_finance::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (v_org, v_period_1, now(), v_finance);
    report := report || E'\n5. FAIL - the same organization+period was closed twice';
  exception when unique_violation then
    report := report || E'\n5. PASS - closing the same month twice is rejected at the database level (payroll_periods_organization_period_unique) -- app/(app)/payroll/actions.ts pre-checks this to turn it into a real message before ever reaching this constraint';
  end;

  -- ---- 6. A caller cannot attribute the close to someone else ----
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (v_org, v_period_2, now(), v_ops);
    report := report || E'\n6. FAIL - Test Contract Admin B was able to close a month and attribute it to Test Ops Manager B';
  exception when insufficient_privilege then
    report := report || E'\n6. PASS - the WITH CHECK''s closed_by = app.current_user_id() blocks closing on someone else''s behalf';
  end;

  -- reset back to privileged context to clean up
  reset role;
  delete from public.payroll_periods where organization_id = v_org and period in (v_period_1, v_period_2);
  delete from public.user_org_roles where user_id = v_contracts_only and organization_id = v_org and role_id = v_contract_admin_role_id;

  raise exception E'VERIFICATION REPORT for 202609150001 (payroll_periods), WOW LAB Test Org B (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
