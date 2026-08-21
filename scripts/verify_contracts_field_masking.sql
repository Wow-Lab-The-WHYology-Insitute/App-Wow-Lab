-- verify_contracts_field_masking.sql
-- Dry-run verification for supabase/migrations/202608190001_contracts_field_masking.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the forward migration's DDL, seeds fixtures, runs the five
-- mandatory assertions, then RAISES an exception whose message IS the full
-- report -- so the transaction can never commit, on purpose, even if every
-- assertion passes. Nothing here is meant to be applied; this is the
-- branch-less substitute for Supabase Branching (no Pro plan).
--
-- Run with: supabase db query --linked --file scripts/verify_contracts_field_masking.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Anything OTHER than that specific error (a plain syntax/permission error
-- from the DDL or seeding itself) means something in the migration is
-- broken, not just "an assertion failed" -- read the raw error, not the
-- report, in that case.
--
-- Session role stays postgres (BYPASSRLS) through all of Phase 0 and
-- Phase 1. SET LOCAL ROLE authenticated happens exactly once, in Phase 2.
-- After that point, every different simulated user is a change to
-- request.jwt.claims only -- never another role switch. RESET ROLE is
-- never called (per the SAD: it would return to cli_login_postgres on this
-- connection, not postgres, and everything needed from Phase 1 is already
-- resolved into session GUCs by the time we switch).

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608190001's DDL exactly, so what's being verified is
-- what will actually be applied, not an approximation of it.
-- ============================================================================

create role app_masking_owner with nologin nobypassrls inherit;
grant authenticated to app_masking_owner;
grant usage, create on schema app to app_masking_owner;
grant select (id, organization_id, billing_rule, estimated_value, previous_year_value)
  on public.contracts to app_masking_owner;

create function app.masked_contract_financials(target_contract_id uuid)
returns record
language sql
security definer
set search_path = ''
as $$
  select case
    when app.belongs_to_org(c.organization_id)
     and (
       app.has_capability('finance.operations.*', c.organization_id)
       or app.has_capability('finance.reporting.*', c.organization_id)
       or app.has_capability('clients.create', c.organization_id)
     )
    then row(c.billing_rule, c.estimated_value, c.previous_year_value)
    else null
  end
  from public.contracts c
  where c.id = target_contract_id;
$$;

-- ALTER ... OWNER TO requires the assigning role to be able to SET ROLE to
-- the target -- postgres is not automatically a member of a role it just
-- created (found running this, not anticipated: 42501 "must be able to
-- SET ROLE app_masking_owner"). Granted just long enough for the transfer,
-- then revoked -- app_masking_owner needs nothing further from postgres
-- once it owns the function.
grant app_masking_owner to postgres;
alter function app.masked_contract_financials(uuid) owner to app_masking_owner;
revoke app_masking_owner from postgres;

revoke execute on function app.masked_contract_financials(uuid) from public;
grant execute on function app.masked_contract_financials(uuid) to authenticated;

create or replace view public.contracts_billing_masked
with (security_invoker = true)
as
select
  c.id,
  c.organization_id,
  c.client_id,
  c.legal_entity_id,
  c.entry_number,
  c.exit_number,
  c.contract_type,
  c.period_start,
  c.period_end,
  c.status,
  c.renewal_of,
  f.billing_rule,
  c.drive_ref,
  c.notes,
  c.created_at,
  c.updated_at,
  c.signed_date,
  f.estimated_value,
  f.previous_year_value,
  c.offer_structure,
  c.ac_link
from public.contracts c
cross join lateral app.masked_contract_financials(c.id)
  as f(billing_rule text, estimated_value numeric, previous_year_value numeric);

revoke select on public.contracts from authenticated;

grant select (
  id, organization_id, client_id, legal_entity_id, contract_type,
  period_start, period_end, status, renewal_of, drive_ref, notes,
  created_at, updated_at, signed_date, offer_structure, ac_link,
  entry_number, exit_number
) on public.contracts to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged (postgres, BYPASSRLS). Resolve every fixture
-- id used below, and seed everything the assertions need, before the one
-- role switch in Phase 2. Nothing after this point can create data (RLS
-- INSERT policies restrict that to contract_administrator/Master, and org
-- B's own fixtures need to exist before either test user can be checked
-- against them).
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_user_finance', (select id::text from users where email = 'test+finance-ops-a@wowlab.dev'), true);
select set_config('app.test_user_nonfinance', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.test_user_contract_admin', (select id::text from users where email = 'test+contract-admin-a@wowlab.dev'), true);
select set_config('app.test_existing_client_a', (select id::text from clients where organization_id = current_setting('app.test_org_a')::uuid limit 1), true);
select set_config('app.test_existing_legal_entity_a', (select id::text from legal_entities where organization_id = current_setting('app.test_org_a')::uuid limit 1), true);

-- Sentinel client in org A with client_type = private_school. This matters:
-- the base SELECT policy on contracts (202608100003) additionally splits
-- finance_operations (private_school/parent_b2c clients) from
-- finance_reporting (everything else) at the ROW level, independent of the
-- column masking this migration adds. Without pinning client_type, whether
-- the finance fixture user can see the sentinel row at all would depend on
-- whatever client the row happened to reference -- assertion 1 needs that
-- to be unconditionally true, not incidentally true.
with ins as (
  insert into public.clients (organization_id, name, client_type, status)
  values (current_setting('app.test_org_a')::uuid, 'VERIFY sentinel client (masking dry run)', 'private_school', 'active')
  returning id
)
select set_config('app.test_sentinel_client_a', id::text, true) from ins;

with ins as (
  insert into public.contracts (
    organization_id, client_id, legal_entity_id, entry_number, exit_number,
    contract_type, status, billing_rule, estimated_value, previous_year_value
  )
  values (
    current_setting('app.test_org_a')::uuid,
    current_setting('app.test_sentinel_client_a')::uuid,
    current_setting('app.test_existing_legal_entity_a')::uuid,
    'VERIFY-ENTRY-A', 'VERIFY-EXIT-A',
    'framework', 'draft',
    'SENTINEL-BILLING-RULE-A', 111111.11, 222222.22
  )
  returning id
)
select set_config('app.test_contract_a', id::text, true) from ins;

-- A second, fully separate organization, seeded inside this same
-- transaction (SAD 6.1 assertion 3) -- neither fixture user has any
-- user_org_roles row here, so both belongs_to_org and has_capability
-- resolve false for it regardless of what they hold in org A.
with ins as (
  insert into organizations (name, slug, is_test)
  values ('VERIFY org B (masking dry run)', 'verify-masking-org-b', true)
  returning id
)
select set_config('app.test_org_b', id::text, true) from ins;

with ins as (
  insert into public.legal_entities (organization_id, name, entity_type)
  values (current_setting('app.test_org_b')::uuid, 'VERIFY org B legal entity', 'srl')
  returning id
)
select set_config('app.test_legal_entity_b', id::text, true) from ins;

with ins as (
  insert into public.clients (organization_id, name, client_type, status)
  values (current_setting('app.test_org_b')::uuid, 'VERIFY org B client', 'private_school', 'active')
  returning id
)
select set_config('app.test_client_b', id::text, true) from ins;

with ins as (
  insert into public.contracts (
    organization_id, client_id, legal_entity_id, entry_number, exit_number,
    contract_type, status, billing_rule, estimated_value, previous_year_value
  )
  values (
    current_setting('app.test_org_b')::uuid,
    current_setting('app.test_client_b')::uuid,
    current_setting('app.test_legal_entity_b')::uuid,
    'VERIFY-ENTRY-B', 'VERIFY-EXIT-B',
    'framework', 'draft',
    'SENTINEL-BILLING-RULE-B', 999999.99, 888888.88
  )
  returning id
)
select set_config('app.test_contract_b', id::text, true) from ins;

-- Ground truth, captured while still privileged: every org-A contract row
-- (pre-existing demo rows plus the sentinel just inserted) with its real
-- financial values and its client's client_type. Assertions 1 and 2
-- compare the view's output against this snapshot rather than against a
-- live re-read of the base table -- by the time those assertions run, the
-- session is authenticated and a live re-read of billing_rule is exactly
-- the access assertion 4 proves is gone.
create temp table _verify_expected_contracts on commit drop as
select c.id, c.billing_rule, c.estimated_value, c.previous_year_value, cl.client_type
from public.contracts c
join public.clients cl on cl.id = c.client_id
where c.organization_id = current_setting('app.test_org_a')::uuid;

grant select on _verify_expected_contracts to authenticated;

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;

-- ============================================================================
-- PHASE 3 -- assertions. Every check runs regardless of whether an earlier
-- one failed; the report accumulates all five results and is raised as a
-- single exception at the end, guaranteeing rollback either way.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_org_a uuid := current_setting('app.test_org_a')::uuid;
  v_org_b uuid := current_setting('app.test_org_b')::uuid;
  v_user_finance uuid := current_setting('app.test_user_finance')::uuid;
  v_user_nonfinance uuid := current_setting('app.test_user_nonfinance')::uuid;
  v_user_contract_admin uuid := current_setting('app.test_user_contract_admin')::uuid;
  v_contract_a uuid := current_setting('app.test_contract_a')::uuid;
  v_existing_client_a uuid := current_setting('app.test_existing_client_a')::uuid;
  v_existing_legal_entity_a uuid := current_setting('app.test_existing_legal_entity_a')::uuid;
  v_expected_total int;
  v_visible_count int;
  v_mismatch_count int;
  v_nonnull_count int;
  v_new_contract_id uuid;
  v_updated_id uuid;
begin
  select count(*) into v_expected_total from _verify_expected_contracts;

  -- ---- 1. Finance user, org A: real values on all (visible) rows ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_finance::text, 'role', 'authenticated')::text, true);

  select count(*) into v_visible_count
  from public.contracts_billing_masked v
  where v.organization_id = v_org_a;

  select count(*) into v_mismatch_count
  from public.contracts_billing_masked v
  join _verify_expected_contracts e on e.id = v.id
  where v.billing_rule is distinct from e.billing_rule
     or v.estimated_value is distinct from e.estimated_value
     or v.previous_year_value is distinct from e.previous_year_value;

  if v_visible_count > 0 and v_mismatch_count = 0 then
    report := report || format(E'\n1. PASS - finance user sees real values matching the base table on all %s visible org-A row(s)', v_visible_count);
  else
    report := report || format(E'\n1. FAIL - visible_rows=%s mismatched_rows=%s (expected visible_rows > 0 and mismatched_rows = 0)', v_visible_count, v_mismatch_count);
  end if;

  -- ---- 2. Non-finance user, org A: null on all rows ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_nonfinance::text, 'role', 'authenticated')::text, true);

  select count(*) into v_visible_count
  from public.contracts_billing_masked v
  where v.organization_id = v_org_a;

  select count(*) into v_nonnull_count
  from public.contracts_billing_masked v
  where v.organization_id = v_org_a
    and (v.billing_rule is not null or v.estimated_value is not null or v.previous_year_value is not null);

  if v_visible_count = v_expected_total and v_nonnull_count = 0 then
    report := report || format(E'\n2. PASS - non-finance user sees null on all %s org-A row(s)', v_visible_count);
  else
    report := report || format(E'\n2. FAIL - visible_rows=%s expected_rows=%s non_null_rows=%s (expected visible_rows = expected_rows and non_null_rows = 0)', v_visible_count, v_expected_total, v_nonnull_count);
  end if;

  -- ---- 3. Both users: zero rows from org B ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_finance::text, 'role', 'authenticated')::text, true);
  select count(*) into v_visible_count from public.contracts_billing_masked where organization_id = v_org_b;
  if v_visible_count = 0 then
    report := report || E'\n3a. PASS - finance user sees 0 rows from org B';
  else
    report := report || format(E'\n3a. FAIL - finance user sees %s row(s) from org B, expected 0', v_visible_count);
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_nonfinance::text, 'role', 'authenticated')::text, true);
  select count(*) into v_visible_count from public.contracts_billing_masked where organization_id = v_org_b;
  if v_visible_count = 0 then
    report := report || E'\n3b. PASS - non-finance user sees 0 rows from org B';
  else
    report := report || format(E'\n3b. FAIL - non-finance user sees %s row(s) from org B, expected 0', v_visible_count);
  end if;

  -- ---- 4. Direct base-table SELECT of a restricted column -> insufficient_privilege ----
  -- Run as the finance user deliberately: proves even a caller who is
  -- legitimately allowed to SEE these values through the view cannot reach
  -- them through the base table anymore. Non-finance was already proven
  -- leaky pre-migration (SAD section 1); the finance case is the one this
  -- migration must newly close.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_finance::text, 'role', 'authenticated')::text, true);
  begin
    perform c.billing_rule, c.estimated_value, c.previous_year_value
    from public.contracts c
    where c.id = v_contract_a;
    report := report || E'\n4. FAIL - direct base-table select of billing_rule/estimated_value/previous_year_value unexpectedly succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n4. PASS - direct base-table select raised insufficient_privilege as expected';
    when others then
      report := report || format(E'\n4. FAIL - unexpected error instead of insufficient_privilege: %s %s', sqlstate, sqlerrm);
  end;

  -- ---- 5. addContract / markContractSigned (.select("id")) still work ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_contract_admin::text, 'role', 'authenticated')::text, true);
  begin
    insert into public.contracts (
      organization_id, client_id, legal_entity_id, entry_number, exit_number,
      contract_type, period_start, period_end, billing_rule, signed_date,
      estimated_value, previous_year_value, status
    ) values (
      v_org_a, v_existing_client_a, v_existing_legal_entity_a,
      'VERIFY-ENTRY-WRITE', 'VERIFY-EXIT-WRITE', 'one_off_event', null, null,
      'verify write-path billing rule', null, null, null, 'draft'
    )
    returning id into v_new_contract_id;

    update public.contracts set status = 'signed'
    where id = v_new_contract_id
    returning id into v_updated_id;

    if v_updated_id = v_new_contract_id then
      report := report || format(E'\n5. PASS - addContract insert + markContractSigned update, both RETURNING id, succeeded (id=%s)', v_updated_id);
    else
      report := report || E'\n5. FAIL - update RETURNING id did not match the inserted id';
    end if;
  exception
    when others then
      report := report || format(E'\n5. FAIL - unexpected error: %s %s', sqlstate, sqlerrm);
  end;

  raise exception E'VERIFICATION REPORT for 202608190001_contracts_field_masking.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
