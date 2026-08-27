-- verify_suppliers.sql
-- Dry-run verification for supabase/migrations/202608300001_suppliers.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the table + RLS + grants DDL, seeds a throwaway supplier in each of
-- two organizations, exercises the exact predicate
-- (is_platform_owner() OR finance.reporting.*) from five real fixture
-- identities plus cross-org isolation, then RAISES an exception whose
-- message IS the full report -- so the transaction can never commit, on
-- purpose, even if every assertion passes.
--
-- Run with: supabase db query --linked --file scripts/verify_suppliers.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608300001's DDL exactly.
-- ============================================================================

create table public.suppliers (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  name              text not null,
  legal_name        text,
  cui               text,
  service_type      text,
  status            text not null default 'active',
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint suppliers_status_check check (status in ('active', 'inactive'))
);

create trigger suppliers_row_history
  before delete or update on public.suppliers
  for each row execute function row_history_capture();

create trigger suppliers_set_updated_at
  before update on public.suppliers
  for each row execute function trigger_set_updated_at();

alter table public.suppliers enable row level security;

create policy "authenticated select suppliers" on public.suppliers
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert suppliers" on public.suppliers
  for insert
  to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated update suppliers" on public.suppliers
  for update
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  )
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert, update on public.suppliers to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, seed one throwaway
-- supplier in org A (for the SELECT/negative-role checks) and one in org B
-- (for cross-org isolation).
-- ============================================================================

select set_config('app.org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.org_b', (select id::text from organizations where slug = 'wow-lab-test-b'), true);
select set_config('app.anka', (select id::text from users where email = 'test+ui-finance-admin@wowlab.dev'), true);
select set_config('app.anca', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.laura', (select id::text from users where email = 'test+ui-finance-ops@wowlab.dev'), true);
select set_config('app.contract_admin', (select id::text from users where email = 'test+ui-contract-admin@wowlab.dev'), true);
select set_config('app.ops', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);

with ins as (
  insert into suppliers (organization_id, name, service_type)
  values (current_setting('app.org_a')::uuid, 'VERIFY Supplier Org A', 'seo')
  returning id
)
select set_config('app.supplier_a', id::text, true) from ins;

with ins as (
  insert into suppliers (organization_id, name, service_type)
  values (current_setting('app.org_b')::uuid, 'VERIFY Supplier Org B', 'accounting')
  returning id
)
select set_config('app.supplier_b', id::text, true) from ins;

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
  v_org_a uuid := current_setting('app.org_a')::uuid;
  v_org_b uuid := current_setting('app.org_b')::uuid;
  v_anka uuid := current_setting('app.anka')::uuid;
  v_anca uuid := current_setting('app.anca')::uuid;
  v_laura uuid := current_setting('app.laura')::uuid;
  v_contract_admin uuid := current_setting('app.contract_admin')::uuid;
  v_ops uuid := current_setting('app.ops')::uuid;
  v_supplier_a uuid := current_setting('app.supplier_a')::uuid;
  v_supplier_b uuid := current_setting('app.supplier_b')::uuid;
  v_count int;
  v_insert_id uuid;
  v_insert_blocked boolean;
  v_grant_count int;
  v_policy_count int;
begin
  -- ---- 1. Anka (finance_admin_reporting): select, insert, update ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_anka::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers where id = v_supplier_a;
  if v_count = 1 then
    report := report || E'\n1a. PASS - Anka can select the org A supplier';
  else
    report := report || E'\n1a. FAIL - Anka could not see the org A supplier';
  end if;

  insert into suppliers (organization_id, name, service_type)
  values (v_org_a, 'VERIFY Anka Insert', 'it')
  returning id into v_insert_id;
  if v_insert_id is not null then
    report := report || E'\n1b. PASS - Anka can insert a supplier';
  else
    report := report || E'\n1b. FAIL - Anka''s insert did not return an id';
  end if;

  update suppliers set notes = 'updated by Anka' where id = v_insert_id;
  select count(*) into v_count from suppliers where id = v_insert_id and notes = 'updated by Anka';
  if v_count = 1 then
    report := report || E'\n1c. PASS - Anka can update a supplier';
  else
    report := report || E'\n1c. FAIL - Anka''s update did not take effect';
  end if;

  -- ---- 2. Anca (organization_owner): select, insert, update ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_anca::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers where id = v_supplier_a;
  if v_count = 1 then
    report := report || E'\n2a. PASS - Anca can select the org A supplier';
  else
    report := report || E'\n2a. FAIL - Anca could not see the org A supplier';
  end if;

  insert into suppliers (organization_id, name, service_type)
  values (v_org_a, 'VERIFY Anca Insert', 'legal')
  returning id into v_insert_id;
  if v_insert_id is not null then
    report := report || E'\n2b. PASS - Anca can insert a supplier';
  else
    report := report || E'\n2b. FAIL - Anca''s insert did not return an id';
  end if;

  update suppliers set notes = 'updated by Anca' where id = v_insert_id;
  select count(*) into v_count from suppliers where id = v_insert_id and notes = 'updated by Anca';
  if v_count = 1 then
    report := report || E'\n2c. PASS - Anca can update a supplier';
  else
    report := report || E'\n2c. FAIL - Anca''s update did not take effect';
  end if;

  -- ---- 3. Laura (finance_operations): sees nothing -- the asymmetry Anca specified ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_laura::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers;
  if v_count = 0 then
    report := report || E'\n3a. PASS - Laura''s SELECT returns zero suppliers (of the 4+ that exist by this point)';
  else
    report := report || format(E'\n3a. FAIL - Laura can see %s supplier(s); expected 0', v_count);
  end if;

  v_insert_blocked := false;
  begin
    insert into suppliers (organization_id, name, service_type)
    values (v_org_a, 'VERIFY Laura Insert Should Fail', 'seo');
  exception
    when insufficient_privilege then
      v_insert_blocked := true;
  end;
  if v_insert_blocked then
    report := report || E'\n3b. PASS - Laura''s insert attempt was rejected by RLS (insufficient_privilege)';
  else
    report := report || E'\n3b. FAIL - Laura was able to insert a supplier';
  end if;

  -- ---- 4. Contract Administrator: sees nothing ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_contract_admin::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers;
  if v_count = 0 then
    report := report || E'\n4. PASS - Contract Administrator''s SELECT returns zero suppliers';
  else
    report := report || format(E'\n4. FAIL - Contract Administrator can see %s supplier(s); expected 0', v_count);
  end if;

  -- ---- 5. Operations Manager: sees nothing ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers;
  if v_count = 0 then
    report := report || E'\n5. PASS - Operations Manager''s SELECT returns zero suppliers';
  else
    report := report || format(E'\n5. FAIL - Operations Manager can see %s supplier(s); expected 0', v_count);
  end if;

  -- ---- 6. Cross-org isolation ----
  -- Anka holds finance.reporting.* in org A only (confirmed live before
  -- writing this script: none of the five fixtures used here have any
  -- membership row in org B at all) -- she should not see org B's
  -- supplier even though she clears the capability check in her own org.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_anka::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from suppliers where id = v_supplier_b;
  if v_count = 0 then
    report := report || E'\n6. PASS - Anka (org A only) cannot see org B''s supplier -- cross-org isolation holds';
  else
    report := report || E'\n6. FAIL - Anka could see a supplier belonging to a different organization';
  end if;

  -- ---- 7. No DELETE grant exists ----
  select count(*) into v_grant_count
  from information_schema.role_table_grants
  where table_schema = 'public' and table_name = 'suppliers'
    and grantee = 'authenticated' and privilege_type = 'DELETE';

  select count(*) into v_policy_count
  from pg_policies
  where schemaname = 'public' and tablename = 'suppliers' and cmd = 'DELETE';

  if v_grant_count = 0 and v_policy_count = 0 then
    report := report || E'\n7. PASS - no DELETE grant and no DELETE policy exist on suppliers';
  else
    report := report || format(E'\n7. FAIL - grant_count=%s policy_count=%s (expected 0 and 0)', v_grant_count, v_policy_count);
  end if;

  raise exception E'VERIFICATION REPORT for 202608300001_suppliers.sql (transaction WILL roll back -- nothing above or below this point was committed, including every throwaway VERIFY supplier):%', report;
end;
$verify$;

rollback;
