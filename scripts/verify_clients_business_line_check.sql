-- verify_clients_business_line_check.sql
-- Dry-run verification for
-- supabase/migrations/202609100001_add_clients_business_line_check.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- The constraint is already live (migration applied 2026-09-10, not
-- re-applied here -- this only re-asserts it, so a second run of this
-- script still means something after the migration is long-applied).
-- Verifies: a value outside the three is rejected, null is accepted,
-- each of the three real values is accepted, and the two real rows in
-- `clients` are exactly what the migration's own comment says they
-- should be -- Maxdigital untouched at null, "Școala Franceză (Lycee
-- Francais)" backfilled from 'Scoli recurente' to
-- 'recurring_private_schools', not left as free text.
--
-- Run with: supabase db query --linked --file scripts/verify_clients_business_line_check.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_owner', (select id::text from users where email = 'anca.tanasescu@gmail.com'), true);

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_owner'), 'role', 'authenticated')::text, true);

do $verify$
declare
  report text := '';
  v_org uuid := current_setting('app.test_org_a')::uuid;
  v_sqlstate text;
  v_id uuid;
  v_maxdigital_bl text;
  v_lycee_bl text;
  v_lycee_name text;
begin
  -- ---- 1. a value outside the three is rejected ----
  begin
    insert into clients (organization_id, name, client_type, status, business_line)
    values (v_org, 'VERIFY-BUSINESS-LINE-CHECK-1', 'private_school', 'prospect', 'not_a_real_value');
    report := report || E'\n1. FAIL - expected check_violation for an out-of-set business_line, but the insert succeeded';
  exception
    when check_violation then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n1. PASS - out-of-set business_line raised check_violation (sqlstate %s)', v_sqlstate);
  end;

  -- ---- 2. null is accepted ----
  insert into clients (organization_id, name, client_type, status, business_line)
  values (v_org, 'VERIFY-BUSINESS-LINE-CHECK-2', 'private_school', 'prospect', null)
  returning id into v_id;

  if v_id is not null then
    report := report || E'\n2. PASS - business_line=null succeeds';
  else
    report := report || E'\n2. FAIL - the null-business_line insert did not return an id';
  end if;

  -- ---- 3. each of the three real values is accepted ----
  insert into clients (organization_id, name, client_type, status, business_line)
  values
    (v_org, 'VERIFY-BUSINESS-LINE-CHECK-3a', 'private_school', 'prospect', 'recurring_private_schools'),
    (v_org, 'VERIFY-BUSINESS-LINE-CHECK-3b', 'state_school', 'prospect', 'state_schools'),
    (v_org, 'VERIFY-BUSINESS-LINE-CHECK-3c', 'corporate', 'prospect', 'corporate_events');
  report := report || E'\n3. PASS - all three real values (recurring_private_schools, state_schools, corporate_events) insert without error';

  -- ---- 4. the two real rows are exactly what the migration's own
  -- comment claims: Maxdigital untouched at null, Lycee Francais
  -- backfilled, not left as the old free text. ----
  select business_line into v_maxdigital_bl from clients where name = 'Maxdigital';
  select name, business_line into v_lycee_name, v_lycee_bl from clients where legal_name = 'FUNDATIA LYCEE FRANCAIS ANNA DE NOAILLES';

  if v_maxdigital_bl is null then
    report := report || E'\n4a. PASS - Maxdigital.business_line is still null, untouched by the backfill';
  else
    report := report || format(E'\n4a. FAIL - Maxdigital.business_line is %L, expected null', v_maxdigital_bl);
  end if;

  if v_lycee_bl = 'recurring_private_schools' then
    report := report || format(E'\n4b. PASS - %s.business_line is recurring_private_schools, backfilled from the old free text', v_lycee_name);
  else
    report := report || format(E'\n4b. FAIL - Lycee Francais row has business_line=%L, expected recurring_private_schools', v_lycee_bl);
  end if;

  raise exception E'VERIFICATION REPORT for 202609100001_add_clients_business_line_check.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
