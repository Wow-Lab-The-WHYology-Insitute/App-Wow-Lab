-- db/tests/rls_clients_contracts.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — impersonation-based
-- checks for supabase/migrations/202608100001..202608100005.
--
-- Same pattern as db/tests/rls_ws_d_read.sql and rls_ws_d_write.sql:
-- resolve fixture ids into session GUCs *while still running with full,
-- unrestricted access* (the connecting role, e.g. postgres via SQL Editor —
-- RLS is not yet in effect), THEN switch role to `authenticated` and set
-- request.jwt.claims to the fixture user's id, THEN exercise the REAL
-- tables. Every block is BEGIN/ROLLBACK — nothing here persists, including
-- the clients/contracts fixture rows each block creates for itself (blocks
-- cannot share fixtures across each other's rollback boundary, so each
-- block that needs data creates its own).
--
-- Fixture setup uses `DO $$ ... INSERT ... RETURNING id INTO v_id; PERFORM
-- set_config(...); END $$` blocks, not `select set_config('k', (insert ...
-- returning id), true)` — Postgres rejects a data-modifying statement
-- nested as a scalar subquery ("WITH clause containing a data-modifying
-- statement must be at the top level"); it must run inside PL/pgSQL.
--
-- Every block's assertions are combined into ONE final UNION ALL SELECT
-- (actual/expected cast to ::text for cross-row type uniformity), rather
-- than one SELECT per assertion as in the original WS-D suites — this suite
-- is run via `supabase db query --file`, which only returns the LAST
-- statement's result set per invocation, so every assertion that should be
-- visible in one run has to be one final multi-row result.
--
-- Fixture users used: test+finance-ops-a, test+finance-admin-a,
-- test+catalina (operations_manager), test+sales-a, test+contract-admin-a,
-- test+owner-a, test+user-b — see supabase/seed.sql and
-- supabase/migrations/202608100005_seed_clients_contracts_test_fixtures.sql.
--
-- Covers the task's 8-point validation list, in order, plus one bonus
-- DELETE-deny-all check (mentioned in the task's Action-level section but
-- not in the numbered list) for completeness with the WS-D suite's own
-- shape. Point 8 ("row_history captures INSERT/UPDATE") is implemented as
-- UPDATE-only — see the note at that block for why, and the final report.
--
-- Run block-by-block (each BEGIN..ROLLBACK is self-contained — split into
-- its own file/`supabase db query --linked --file` call to see every
-- block's result), or as a whole script in the SQL Editor where every
-- statement's output is shown.

-- ============================================================================
-- Point 1 — finance_operations sees ONLY private_school contracts, zero rows
-- for corporate/state.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  do $$
  declare
    v_client_private uuid;
    v_client_corporate uuid;
    v_contract_private uuid;
    v_contract_corporate uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Private School', 'private_school', 'active')
    returning id into v_client_private;
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Corporate Client', 'corporate', 'active')
    returning id into v_client_corporate;

    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_private, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-PRIVATE-001', 'recurring_annual', 'signed', '95 lei/copil/sedinta')
    returning id into v_contract_private;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_corporate, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-CORPORATE-001', 'one_off_event', 'signed', 'event contract')
    returning id into v_contract_corporate;

    perform set_config('app.fixture_contract_private', v_contract_private::text, true);
    perform set_config('app.fixture_contract_corporate', v_contract_corporate::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'finance_ops_a: sees the private_school contract' as check_name,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_private')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_private')::uuid) = 1 as pass
  union all
  select 'finance_ops_a: does NOT see the corporate contract (0 rows)',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_corporate')::uuid)::text,
    '0',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_corporate')::uuid) = 0;
rollback;

-- ============================================================================
-- Point 2 — finance_admin_reporting sees ONLY non-private_school contracts.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  do $$
  declare
    v_client_private uuid;
    v_client_state uuid;
    v_contract_private uuid;
    v_contract_state uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Private School 2', 'private_school', 'active')
    returning id into v_client_private;
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture State School', 'state_school', 'active')
    returning id into v_client_state;

    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_private, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-PRIVATE-002', 'recurring_annual', 'signed', '80 lei/copil')
    returning id into v_contract_private;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_state, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-STATE-001', 'framework', 'signed', 'grant framework contract')
    returning id into v_contract_state;

    perform set_config('app.fixture_contract_private', v_contract_private::text, true);
    perform set_config('app.fixture_contract_state', v_contract_state::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-admin-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'finance_admin_a: sees the state_school contract' as check_name,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_state')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_state')::uuid) = 1 as pass
  union all
  select 'finance_admin_a: does NOT see the private_school contract (0 rows)',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_private')::uuid)::text,
    '0',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_private')::uuid) = 0;
rollback;

-- ============================================================================
-- Point 3 — operations (test+catalina, operations_manager) sees client
-- records unrestricted, but billing_rule reads as NULL through
-- public.contracts_billing_masked. Also proves row-visibility itself is NOT
-- blocked (only the column) by checking the row count is still 1.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  do $$
  declare
    v_client uuid;
    v_contract uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Masking Client', 'corporate', 'active')
    returning id into v_client;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-MASK-001', 'one_off_event', 'signed', 'SECRET-RATE-4200-lei')
    returning id into v_contract;

    perform set_config('app.fixture_client', v_client::text, true);
    perform set_config('app.fixture_contract', v_contract::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+catalina@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'catalina (ops): sees the client record (clients.read, no type restriction)' as check_name,
    (select count(*) from public.clients where id = current_setting('app.fixture_client')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.clients where id = current_setting('app.fixture_client')::uuid) = 1 as pass
  union all
  select 'catalina (ops): row still visible through contracts_billing_masked (row count = 1, not blocked)',
    (select count(*) from public.contracts_billing_masked where id = current_setting('app.fixture_contract')::uuid)::text,
    '1',
    (select count(*) from public.contracts_billing_masked where id = current_setting('app.fixture_contract')::uuid) = 1
  union all
  select 'catalina (ops): billing_rule reads as NULL through contracts_billing_masked',
    coalesce((select billing_rule from public.contracts_billing_masked where id = current_setting('app.fixture_contract')::uuid), '<NULL>'),
    '<NULL>',
    (select billing_rule from public.contracts_billing_masked where id = current_setting('app.fixture_contract')::uuid) is null;
rollback;

-- ============================================================================
-- Point 4 — sales_manager can INSERT a client; cannot INSERT/UPDATE a
-- contract (must fail).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  -- Pre-existing client+contract for the negative UPDATE check below (sales_manager didn't create these).
  do $$
  declare
    v_client uuid;
    v_contract uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Sales Negative Client', 'corporate', 'active')
    returning id into v_client;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-SALES-NEG-001', 'one_off_event', 'draft')
    returning id into v_contract;

    perform set_config('app.fixture_client', v_client::text, true);
    perform set_config('app.fixture_contract', v_contract::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+sales-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  do $$
  declare
    v_new_client uuid;
    v_contract_blocked boolean := false;
    v_update_count int;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Sales-Created Client (rolled back)', 'private_school', 'prospect')
    returning id into v_new_client;
    perform set_config('test.sales_insert_client_ok', (v_new_client is not null)::text, true);

    begin
      insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status)
      values (
        current_setting('app.test_org_wow_lab')::uuid,
        current_setting('app.fixture_client')::uuid,
        current_setting('app.test_legal_entity')::uuid,
        'C1-TEST-SALES-SHOULD-FAIL',
        'one_off_event',
        'draft'
      );
    exception
      when insufficient_privilege then
        v_contract_blocked := true;
    end;
    perform set_config('test.sales_insert_contract_blocked', v_contract_blocked::text, true);

    update public.contracts
       set status = 'signed'
     where id = current_setting('app.fixture_contract')::uuid;
    get diagnostics v_update_count = row_count;
    perform set_config('test.sales_update_contract_count', v_update_count::text, true);
  end $$;

  select 'sales_a: INSERT clients succeeds (clients.create)' as check_name,
    current_setting('test.sales_insert_client_ok') as actual,
    'true' as expected,
    current_setting('test.sales_insert_client_ok')::boolean = true as pass
  union all
  select 'sales_a: INSERT contracts is BLOCKED (no contracts.* write capability)',
    current_setting('test.sales_insert_contract_blocked'),
    'true',
    current_setting('test.sales_insert_contract_blocked')::boolean = true
  union all
  select 'sales_a: UPDATE contracts (mark signed) affects 0 rows (no write capability)',
    current_setting('test.sales_update_contract_count'),
    '0',
    current_setting('test.sales_update_contract_count') = '0';
rollback;

-- ============================================================================
-- Point 5 — contract_administrator can INSERT a contract and UPDATE its
-- status to 'signed'. Also confirms row_history captures the UPDATE (see the
-- note in Point 8 below on why INSERT itself is not row_history-checked).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  -- contract_administrator has no clients.create — the client is set up
  -- while still privileged, matching how sales_manager's own INSERT-client
  -- capability was proven separately in Point 4.
  do $$
  declare
    v_client uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Contract Admin Client', 'corporate', 'active')
    returning id into v_client;
    perform set_config('app.fixture_client', v_client::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+contract-admin-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  do $$
  declare
    v_contract uuid;
    v_update_count int;
  begin
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status, billing_rule)
    values (current_setting('app.test_org_wow_lab')::uuid, current_setting('app.fixture_client')::uuid, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-CA-001', 'framework', 'draft', 'TBD')
    returning id into v_contract;
    perform set_config('app.fixture_contract', v_contract::text, true);

    update public.contracts set status = 'signed' where id = v_contract;
    get diagnostics v_update_count = row_count;
    perform set_config('test.ca_update_count', v_update_count::text, true);
  end $$;

  -- Still impersonating contract_administrator here — this is the row
  -- count THEY can see under their own RLS, which is exactly what Points
  -- 1-2 of this block are testing.
  select set_config('test.ca_insert_visible_count', (select count(*) from public.contracts where id = current_setting('app.fixture_contract')::uuid)::text, true);

  -- contract_administrator has no org.audit.read (only organization_owner
  -- gets that, via the B4 dynamic grant) — querying public.row_history
  -- while still impersonating them would be blocked by row_history's OWN
  -- RLS policy and wrongly read as "not captured". RESET ROLE drops back to
  -- the unrestricted connecting role (same as before any `set_config('role',
  -- 'authenticated', ...)` in this transaction) so this specific check
  -- verifies the trigger fired, not this particular role's audit-read
  -- capability (a separate, already-covered concern).
  reset role;

  select 'contract_admin_a: INSERT contracts succeeds' as check_name,
    current_setting('test.ca_insert_visible_count') as actual,
    '1' as expected,
    current_setting('test.ca_insert_visible_count') = '1' as pass
  union all
  select 'contract_admin_a: UPDATE contracts (mark signed) succeeds',
    current_setting('test.ca_update_count'),
    '1',
    current_setting('test.ca_update_count') = '1'
  union all
  select 'contract_admin_a: row_history captured the UPDATE with organization_id populated',
    (
      select rh.organization_id::text
      from public.row_history rh
      where rh.table_name = 'contracts'
        and rh.row_id = current_setting('app.fixture_contract')::uuid
      order by rh.changed_at desc
      limit 1
    ),
    current_setting('app.test_org_wow_lab'),
    (
      select rh.organization_id
      from public.row_history rh
      where rh.table_name = 'contracts'
        and rh.row_id = current_setting('app.fixture_contract')::uuid
      order by rh.changed_at desc
      limit 1
    ) = current_setting('app.test_org_wow_lab')::uuid;
rollback;

-- ============================================================================
-- Point 6 — cross-org isolation for clients/client_contacts/contracts,
-- reusing the org_b fixture (test+user-b, organization_owner @
-- wow-lab-test-b only). wow-lab-test-b has no seeded legal_entities, so one
-- is created transactionally here too (privileged, before the role switch).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_org_wow_lab_test_b', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.test_legal_entity_a', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  do $$
  declare
    v_legal_entity_b uuid;
    v_client_a uuid;
    v_client_b uuid;
    v_contract_a uuid;
    v_contract_b uuid;
  begin
    insert into public.legal_entities (organization_id, name, entity_type)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, 'Fixture Org B Legal Entity (rolled back)', 'srl')
    returning id into v_legal_entity_b;

    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Org A Client', 'corporate', 'active')
    returning id into v_client_a;
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, 'Fixture Org B Client', 'corporate', 'active')
    returning id into v_client_b;

    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_a, current_setting('app.test_legal_entity_a')::uuid, 'C1-TEST-ORGA-001', 'one_off_event', 'signed')
    returning id into v_contract_a;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, v_client_b, v_legal_entity_b, 'C1-TEST-ORGB-001', 'one_off_event', 'signed')
    returning id into v_contract_b;

    perform set_config('app.fixture_client_a', v_client_a::text, true);
    perform set_config('app.fixture_client_b', v_client_b::text, true);
    perform set_config('app.fixture_contract_a', v_contract_a::text, true);
    perform set_config('app.fixture_contract_b', v_contract_b::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+user-b@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'user_b: cannot see wow-lab''s (org A) fixture client (cross-org isolation)' as check_name,
    (select count(*) from public.clients where id = current_setting('app.fixture_client_a')::uuid)::text as actual,
    '0' as expected,
    (select count(*) from public.clients where id = current_setting('app.fixture_client_a')::uuid) = 0 as pass
  union all
  select 'user_b: cannot see wow-lab''s (org A) fixture contract (cross-org isolation)',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_a')::uuid)::text,
    '0',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_a')::uuid) = 0
  union all
  select 'user_b: sees own org (org B) fixture client — isolation is scoped, not a blanket deny',
    (select count(*) from public.clients where id = current_setting('app.fixture_client_b')::uuid)::text,
    '1',
    (select count(*) from public.clients where id = current_setting('app.fixture_client_b')::uuid) = 1
  union all
  select 'user_b: sees own org (org B) fixture contract — isolation is scoped, not a blanket deny',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_b')::uuid)::text,
    '1',
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_b')::uuid) = 1;
rollback;

-- ============================================================================
-- Bonus — DELETE stays deny-all (task's Action-level section, not in the
-- numbered 8-point list, included for parity with rls_ws_d_write.sql).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  do $$
  declare
    v_client uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Delete-Deny Client', 'corporate', 'active')
    returning id into v_client;
    perform set_config('app.fixture_client', v_client::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+owner-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      delete from public.clients where id = current_setting('app.fixture_client')::uuid;
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.delete_blocked', v_blocked::text, true);
  end $$;

  select 'owner_a: DELETE from clients is BLOCKED (deny-all, no grant anywhere — even for organization_owner)' as check_name,
    current_setting('test.delete_blocked') as actual,
    'true' as expected,
    current_setting('test.delete_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Point 7 — SABOTAGE CHECK ("does this suite have teeth?")
-- Deliberately breaks the contracts SELECT record-level segregation to a
-- permissive (true) condition, then re-runs Point 1's exact "does NOT see
-- the corporate contract" assertion (same expected = 0 / pass = true
-- shape). Under the sabotaged policy finance_operations wrongly sees the
-- corporate contract too, so `actual` comes back 1 (not 0) and `pass` flips
-- to false — proving the suite would catch this exact regression. Undone by
-- ROLLBACK, including the ALTER POLICY — safe to re-run at any time.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_legal_entity', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid and name = 'Experimente Wow SRL'), true);

  do $$
  declare
    v_client uuid;
    v_contract uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture Sabotage Corporate Client', 'corporate', 'active')
    returning id into v_client;
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, current_setting('app.test_legal_entity')::uuid, 'C1-TEST-SABOTAGE-001', 'one_off_event', 'signed')
    returning id into v_contract;
    perform set_config('app.fixture_contract_corporate', v_contract::text, true);
  end $$;

  -- Still privileged at this point (role not yet switched) — sabotage the
  -- real policy in place.
  alter policy "authenticated select contracts" on public.contracts
    using (true);

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'SABOTAGE: finance_ops_a sees the corporate contract, same assertion as Point 1, policy USING forced to (true)' as check_name,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_corporate')::uuid)::text as actual,
    '0' as expected,
    (select count(*) from public.contracts where id = current_setting('app.fixture_contract_corporate')::uuid) = 0 as pass;
    -- ^ this `pass` is expected to read FALSE here (actual will be 1, not
    -- 0) — that is the whole point: a broken record-level policy makes this
    -- assertion fail, proving the suite has teeth.
rollback;

-- ============================================================================
-- Point 8, note on scope — row_history INSERT/UPDATE.
-- DATABASE_CONVENTIONS.md #8 and every existing audited table (user_org_
-- roles, org_settings, legal_entities, file_refs) attach row_history_
-- capture() as `BEFORE UPDATE OR DELETE` only — INSERT is never captured
-- anywhere in this codebase (a new row has no prior state to diff; its own
-- created_at already marks the point-in-time creation). clients/
-- client_contacts/contracts follow that exact, already-reviewed convention
-- (202608100001) rather than the task prompt's literal "INSERT/UPDATE"
-- wording. UPDATE capture is verified above: Point 5 confirms it for
-- contracts (via contract_administrator's status change to 'signed'); the
-- identical trigger function/pattern is used verbatim on clients and
-- client_contacts, already proven correct on 4 other tables in WS-D
-- (db/tests/rls_ws_d_write.sql, "row_history captured the org_settings
-- UPDATE"), so it is not re-derived here per-table. Flagged explicitly in
-- the final report as a deviation from the task's literal wording, in favor
-- of DATABASE_CONVENTIONS.md, which the task also said to follow throughout.
-- ============================================================================
