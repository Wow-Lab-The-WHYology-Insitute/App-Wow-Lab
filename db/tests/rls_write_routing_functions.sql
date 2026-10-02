-- db/tests/rls_write_routing_functions.sql
-- WOW LAB OS: proves item 91's fix -- confirmed live 2026-09-22 that a
-- trainer, using their own real session (public anon key + a non-httpOnly
-- @supabase/ssr cookie) could PATCH /rest/v1/sessions directly and set
-- their CO-TRAINER's trainer_secundar_confirmed_at (the pay-triggering
-- field, 202609150002's own header), entirely bypassing
-- confirmSessionAttendance's column narrowing, because RLS is row-only
-- and authenticated held a table-wide UPDATE grant.
--
-- 202609220001/202609220002 revoked that grant (table-wide on sessions;
-- column-level on contracts' 3 financial fields and groups.
-- children_confirmed) and routed every affected write through a
-- SECURITY DEFINER function in schema app, exposed via a thin public.*
-- wrapper for PostgREST. This file proves, for each protected surface:
-- (1) the raw write authenticated used to be able to make is now refused
-- at the grant level, not just the app layer; (2) each function's
-- allowed case still succeeds and every forbidden case is refused;
-- (3) sabotage -- temporarily re-grant the raw privilege and confirm the
-- raw-write assertion flips to fail, proving this file would catch the
-- exact regression it exists to guard.
--
-- Same pattern as every other file here: resolve fixture ids into
-- session GUCs while still privileged, switch role, exercise the real
-- tables/functions. Every block is BEGIN/ROLLBACK.
--
-- Fixture users (WOW LAB Test Org B): maxdigitalro+trainerb1/b2/b3
-- (trainers), test+ui-ops-manager-b (operations_manager),
-- test+ui-contract-admin-b (contract_administrator + finance_operations).

-- ============================================================================
-- Point 1 — SESSIONS: the raw write, blocked. This is the acceptance
-- test named directly: the exact PATCH that succeeded in the report
-- (principal writing the secundar's own confirmation column) must now be
-- refused.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_trainer_b1', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('app.fixture_trainer_b2', (select id::text from public.users where email = 'maxdigitalro+trainerb2@gmail.com'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_group, current_date, current_setting('app.fixture_trainer_b1')::uuid, current_setting('app.fixture_trainer_b2')::uuid, 'planned')
      returning id into v_session;
    perform set_config('app.fixture_session_wr', v_session::text, true);
  end $$;

  set local role authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b1')::text, 'role', 'authenticated')::text, true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      update public.sessions
        set trainer_secundar_confirmed_at = now()
        where id = current_setting('app.fixture_session_wr')::uuid;
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.raw_sessions_write_blocked', v_blocked::text, true);
  end $$;

  select 'RAW WRITE: principal cannot PATCH the co-trainer''s confirmed_at directly (authenticated has no UPDATE grant on sessions at all)' as check_name,
    current_setting('test.raw_sessions_write_blocked') as actual, 'true' as expected,
    current_setting('test.raw_sessions_write_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Point 2 — SESSIONS: each RPC function, allowed case succeeds, forbidden
-- case refused. Four functions, eight checks.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_trainer_b1', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('app.fixture_trainer_b2', (select id::text from public.users where email = 'maxdigitalro+trainerb2@gmail.com'), true);
  select set_config('app.fixture_trainer_b3', (select id::text from public.users where email = 'maxdigitalro+trainerb3@gmail.com'), true);
  select set_config('app.fixture_ops', (select id::text from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'), true);
  select set_config('app.fixture_finance', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);

  -- ------------------------------------------------------------------
  -- THE MONTH THIS BLOCK OWNS. Previously the fixture session was dated
  -- current_date, which made two of the checks below depend on something
  -- stated nowhere: that Test Org B's CURRENT month happens to be open.
  --
  -- rpc_update_session_attendance and rpc_confirm_session_attendance both
  -- gate on the SESSION's month (202609220001: `pp.period =
  -- date_trunc('month', v_session_date)` and `pp.closed_at is not null`),
  -- returning 'month_closed' instead of 'ok'. Mihai closed Test Org B's
  -- 2026-09 period deliberately through the app, and these two checks
  -- began failing with actual="month_closed" -- not a regression in the
  -- code, a precondition the suite had assumed and never asserted.
  --
  -- Worse than failing: it then SELF-HEALED on 2026-10-01, when
  -- current_date rolled into a month with no closing row. A check whose
  -- result depends on which month it is run in is not a check.
  --
  -- Both halves below are needed, and they fix different things:
  --   1. A PINNED date removes the calendar dependency -- this block now
  --      exercises the same month on every run, forever.
  --   2. Deleting any closing row for that month, inside the transaction,
  --      turns "this month is open" from an assumption into an ENFORCED
  --      precondition, so closing any month can never break this block.
  -- The delete is isolated by the block's own rollback, and against a
  -- month this far from real activity it will essentially never match a
  -- row -- it is a guard, not a mutation.
  select set_config('app.fixture_session_month_date', '2020-01-15', true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    -- (2) Enforce the precondition rather than hoping for it.
    delete from public.payroll_periods
    where organization_id = current_setting('app.test_org_wow_lab_b')::uuid
      and period = date_trunc('month', current_setting('app.fixture_session_month_date')::date::timestamptz)::date;

    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting RPC Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    -- (1) Pinned, not current_date.
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_group, current_setting('app.fixture_session_month_date')::date, current_setting('app.fixture_trainer_b1')::uuid, current_setting('app.fixture_trainer_b2')::uuid, 'planned')
      returning id into v_session;
    perform set_config('app.fixture_session_rpc', v_session::text, true);
  end $$;

  set local role authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b1')::text, 'role', 'authenticated')::text, true);
  select set_config('test.confirm_own', app.rpc_confirm_session_attendance(current_setting('app.fixture_session_rpc')::uuid, true), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b3')::text, 'role', 'authenticated')::text, true);
  select set_config('test.confirm_unrelated', app.rpc_confirm_session_attendance(current_setting('app.fixture_session_rpc')::uuid, true), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b2')::text, 'role', 'authenticated')::text, true);
  select set_config('test.attendance_own', app.rpc_update_session_attendance(current_setting('app.fixture_session_rpc')::uuid, 10, 'gaga'), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b3')::text, 'role', 'authenticated')::text, true);
  select set_config('test.attendance_unrelated', app.rpc_update_session_attendance(current_setting('app.fixture_session_rpc')::uuid, 1, 'x'), true);
  select set_config('test.allocation_unrelated', app.rpc_update_session_allocation(current_setting('app.fixture_session_rpc')::uuid, current_setting('app.fixture_trainer_b3')::uuid, null), true);
  select set_config('test.correction_unrelated', app.rpc_correct_session_confirmation(current_setting('app.fixture_session_rpc')::uuid, true, true), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_ops')::text, 'role', 'authenticated')::text, true);
  select set_config('test.allocation_ops', app.rpc_update_session_allocation(current_setting('app.fixture_session_rpc')::uuid, current_setting('app.fixture_trainer_b2')::uuid, current_setting('app.fixture_trainer_b1')::uuid), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_finance')::text, 'role', 'authenticated')::text, true);
  select set_config('test.correction_finance', app.rpc_correct_session_confirmation(current_setting('app.fixture_session_rpc')::uuid, false, false), true);

  select 'confirmSessionAttendance: own slot succeeds' as check_name, current_setting('test.confirm_own') as actual, 'ok' as expected, current_setting('test.confirm_own') = 'ok' as pass
  union all
  select 'confirmSessionAttendance: unrelated trainer refused', current_setting('test.confirm_unrelated'), 'not_assigned', current_setting('test.confirm_unrelated') = 'not_assigned'
  union all
  select 'updateSessionAttendance: own row succeeds', current_setting('test.attendance_own'), 'ok', current_setting('test.attendance_own') = 'ok'
  union all
  select 'updateSessionAttendance: unrelated trainer refused', current_setting('test.attendance_unrelated'), 'not_assigned', current_setting('test.attendance_unrelated') = 'not_assigned'
  union all
  select 'updateSessionAllocation: unrelated trainer refused (no sessions.create)', current_setting('test.allocation_unrelated'), 'not_permitted', current_setting('test.allocation_unrelated') = 'not_permitted'
  union all
  select 'updateSessionAllocation: operations_manager succeeds', current_setting('test.allocation_ops'), 'ok', current_setting('test.allocation_ops') = 'ok'
  union all
  select 'correctSessionConfirmation: unrelated trainer refused (no finance.operations.*)', current_setting('test.correction_unrelated'), 'not_permitted', current_setting('test.correction_unrelated') = 'not_permitted'
  union all
  select 'correctSessionConfirmation: finance.operations.* succeeds', current_setting('test.correction_finance'), 'ok', current_setting('test.correction_finance') = 'ok';
rollback;

-- ============================================================================
-- Point 2b — THE MONTH GATE ITSELF, which had no coverage anywhere in
-- db/tests/ until now.
-- ============================================================================
-- Point 2 above asserts both attendance RPCs return 'ok' when the session's
-- month is open. Nothing asserted the other side: that they return
-- 'month_closed' when it is closed. The gate has existed since 202609220001
-- and could have been deleted outright without a single check noticing --
-- the production incident that prompted this (Mihai closing Test Org B's
-- September) was in fact the first time anything exercised it, by accident.
--
-- This block is also what keeps Point 2's two 'ok' checks honest. On their
-- own, they pass both when the gate works and when the gate does not exist
-- at all. Paired with this block, the two halves fail for DIFFERENT reasons:
-- delete the gate and this block fails; break the row-match or capability
-- branch and Point 2 fails. That is item 100's fourth probe error applied
-- deliberately rather than tripped over -- two assertions that can only ever
-- agree are not two pieces of evidence.
--
-- Same pinned month as Point 2, closed here INSIDE the transaction rather
-- than depending on any real period's state.
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_trainer_b1', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('app.fixture_trainer_b2', (select id::text from public.users where email = 'maxdigitalro+trainerb2@gmail.com'), true);
  -- Resolved HERE, before `set local role authenticated`, not inline below.
  -- `authenticated` holds no table-level SELECT on public.users (202608200005
  -- step 3 revoked it, leaving only column grants that exclude email), so a
  -- `where email = '...'` lookup after the role switch fails with "permission
  -- denied for table users" -- which is item 100's second probe error, and is
  -- exactly what the first version of this block did.
  select set_config('app.fixture_finance', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('app.fixture_session_month_date', '2020-01-15', true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting MonthGate Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_group, current_setting('app.fixture_session_month_date')::date, current_setting('app.fixture_trainer_b1')::uuid, current_setting('app.fixture_trainer_b2')::uuid, 'planned')
      returning id into v_session;
    perform set_config('app.fixture_session_rpc_mg', v_session::text, true);

    -- Close the pinned month, here, for this transaction only. Deleted
    -- first so this is an insert rather than a conflict if one exists.
    delete from public.payroll_periods
    where organization_id = current_setting('app.test_org_wow_lab_b')::uuid
      and period = date_trunc('month', current_setting('app.fixture_session_month_date')::date::timestamptz)::date;
    insert into public.payroll_periods (organization_id, period, closed_at)
      values (current_setting('app.test_org_wow_lab_b')::uuid,
              date_trunc('month', current_setting('app.fixture_session_month_date')::date::timestamptz)::date,
              now());
  end $$;

  set local role authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b1')::text, 'role', 'authenticated')::text, true);
  select set_config('test.mg_confirm', app.rpc_confirm_session_attendance(current_setting('app.fixture_session_rpc_mg')::uuid, true), true);
  select set_config('test.mg_attendance', app.rpc_update_session_attendance(current_setting('app.fixture_session_rpc_mg')::uuid, 10, 'gaga'), true);

  -- correctSessionConfirmation is deliberately NOT month-gated (item 91 --
  -- Finance correcting a closed month is the whole point of that path), so
  -- it is checked here too, as the control: if a blanket month gate were
  -- ever added across all four RPCs, this is the check that would catch it.
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_finance')::text, 'role', 'authenticated')::text, true);
  select set_config('test.mg_correction', app.rpc_correct_session_confirmation(current_setting('app.fixture_session_rpc_mg')::uuid, true, true), true);

  select 'MONTH GATE: confirmSessionAttendance refuses a closed month' as check_name,
         current_setting('test.mg_confirm') as actual, 'month_closed' as expected,
         current_setting('test.mg_confirm') = 'month_closed' as pass
  union all
  select 'MONTH GATE: updateSessionAttendance refuses a closed month',
         current_setting('test.mg_attendance'), 'month_closed',
         current_setting('test.mg_attendance') = 'month_closed'
  union all
  select 'CONTROL: correctSessionConfirmation is NOT month-gated, by design',
         current_setting('test.mg_correction'), 'ok',
         current_setting('test.mg_correction') = 'ok';
rollback;

-- ============================================================================
-- Point 3 — CONTRACTS: the raw write, blocked (financial columns only --
-- everything else on contracts is unaffected by this migration).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_finance', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('app.test_legal_entity_b', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab_b')::uuid limit 1), true);

  do $$
  declare
    v_client uuid;
    v_contract uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Contract Client', 'corporate') returning id into v_client;
    insert into public.contracts (organization_id, client_id, legal_entity_id, exit_number, contract_type, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, current_setting('app.test_legal_entity_b')::uuid, 'WR-TEST-001', 'one_off_event', 'signed')
      returning id into v_contract;
    perform set_config('app.fixture_contract_wr', v_contract::text, true);
  end $$;

  set local role authenticated;
  -- test+ui-contract-admin-b holds contracts.* AND finance_operations --
  -- the fixture with a real, live write grant on contracts generally, so
  -- this is a genuine "otherwise-authorized writer, blocked on 3 specific
  -- columns anyway" test, not a capability-mismatch false negative.
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_finance')::text, 'role', 'authenticated')::text, true);

  do $$
  declare
    v_update_blocked boolean := false;
  begin
    begin
      update public.contracts
        set billing_rule = 'RAW WRITE ATTEMPT'
        where id = current_setting('app.fixture_contract_wr')::uuid;
    exception
      when insufficient_privilege then
        v_update_blocked := true;
    end;
    perform set_config('test.raw_contracts_update_blocked', v_update_blocked::text, true);
  end $$;

  select 'RAW WRITE: billing_rule cannot be PATCHed directly, even by a real contracts.* holder (column-level revoke, item 91)' as check_name,
    current_setting('test.raw_contracts_update_blocked') as actual, 'true' as expected,
    current_setting('test.raw_contracts_update_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Point 4 — CONTRACTS: rpc_set_contract_financials, allowed + forbidden.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_finance', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('app.fixture_trainer_b1', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('app.test_legal_entity_b', (select id::text from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab_b')::uuid limit 1), true);

  do $$
  declare
    v_client uuid;
    v_contract uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Contract RPC Client', 'corporate') returning id into v_client;
    insert into public.contracts (organization_id, client_id, legal_entity_id, exit_number, contract_type, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, current_setting('app.test_legal_entity_b')::uuid, 'WR-TEST-RPC-001', 'one_off_event', 'signed')
      returning id into v_contract;
    perform set_config('app.fixture_contract_rpc', v_contract::text, true);
  end $$;

  set local role authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b1')::text, 'role', 'authenticated')::text, true);
  select set_config('test.financials_trainer', app.rpc_set_contract_financials(current_setting('app.fixture_contract_rpc')::uuid, 'x', 1, 1), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_finance')::text, 'role', 'authenticated')::text, true);
  select set_config('test.financials_finance', app.rpc_set_contract_financials(current_setting('app.fixture_contract_rpc')::uuid, '100 lei/child', 5000, 4500), true);

  select 'rpc_set_contract_financials: trainer refused (no finance capability)' as check_name, current_setting('test.financials_trainer') as actual, 'not_permitted' as expected, current_setting('test.financials_trainer') = 'not_permitted' as pass
  union all
  select 'rpc_set_contract_financials: finance/contracts.* holder succeeds', current_setting('test.financials_finance'), 'ok', current_setting('test.financials_finance') = 'ok';
rollback;

-- ============================================================================
-- Point 5 — GROUPS: the raw write, blocked (children_confirmed only).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_ops', (select id::text from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Group Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    perform set_config('app.fixture_group_wr', v_group::text, true);
  end $$;

  set local role authenticated;
  -- operations_manager holds groups.create -- a real, live writer of
  -- groups generally (this is what makes the test meaningful: blocked on
  -- ONE column despite being otherwise fully authorized to write the row).
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_ops')::text, 'role', 'authenticated')::text, true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      update public.groups
        set children_confirmed = 999
        where id = current_setting('app.fixture_group_wr')::uuid;
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.raw_groups_update_blocked', v_blocked::text, true);
  end $$;

  select 'RAW WRITE: children_confirmed cannot be PATCHed directly, even by an operations_manager (column-level revoke, item 91)' as check_name,
    current_setting('test.raw_groups_update_blocked') as actual, 'true' as expected,
    current_setting('test.raw_groups_update_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Point 6 — GROUPS: rpc_set_group_children_confirmed, allowed + forbidden.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_ops', (select id::text from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'), true);
  select set_config('app.fixture_finance', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Group RPC Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    perform set_config('app.fixture_group_rpc', v_group::text, true);
  end $$;

  set local role authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_ops')::text, 'role', 'authenticated')::text, true);
  select set_config('test.children_ops', app.rpc_set_group_children_confirmed(current_setting('app.fixture_group_rpc')::uuid, 15), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_finance')::text, 'role', 'authenticated')::text, true);
  select set_config('test.children_finance', app.rpc_set_group_children_confirmed(current_setting('app.fixture_group_rpc')::uuid, 20), true);

  select 'rpc_set_group_children_confirmed: operations_manager refused (Anca''s 2026-09-11 decision -- sees, does not fill)' as check_name, current_setting('test.children_ops') as actual, 'not_permitted' as expected, current_setting('test.children_ops') = 'not_permitted' as pass
  union all
  select 'rpc_set_group_children_confirmed: contract_administrator succeeds', current_setting('test.children_finance'), 'ok', current_setting('test.children_finance') = 'ok';
rollback;

-- ============================================================================
-- Point 7 — SABOTAGE CHECK ("does this suite have teeth?"). Temporarily
-- re-grants the EXACT table-level UPDATE privilege this item revoked,
-- re-runs Point 1's exact assertion. Under the sabotaged (re-granted)
-- state, the raw write should now succeed, flipping `pass` to false --
-- proving this file would catch the exact regression it exists to guard
-- if the grant were ever accidentally restored (e.g. a future migration
-- doing `grant all on all tables in schema public to authenticated`,
-- exactly the kind of broad statement that could silently undo this).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab_b', (select id::text from public.organizations where name = 'WOW LAB Test Org B'), true);
  select set_config('app.fixture_trainer_b1', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('app.fixture_trainer_b2', (select id::text from public.users where email = 'maxdigitalro+trainerb2@gmail.com'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab_b')::uuid, 'Fixture WriteRouting Sabotage Client', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_client, 'gaga', 'wow_lab_party') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
      values (current_setting('app.test_org_wow_lab_b')::uuid, v_group, current_date, current_setting('app.fixture_trainer_b1')::uuid, current_setting('app.fixture_trainer_b2')::uuid, 'planned')
      returning id into v_session;
    perform set_config('app.fixture_session_sabotage_wr', v_session::text, true);
  end $$;

  -- Still privileged at this point (role not yet switched) -- sabotage:
  -- restore the exact grant item 91 revoked.
  grant update on public.sessions to authenticated;

  set local role authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fixture_trainer_b1')::text, 'role', 'authenticated')::text, true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      update public.sessions
        set trainer_secundar_confirmed_at = now()
        where id = current_setting('app.fixture_session_sabotage_wr')::uuid;
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.sabotage_raw_write_blocked', v_blocked::text, true);
  end $$;

  select 'SABOTAGE: principal writing the co-trainer''s confirmed_at, same assertion as Point 1, UPDATE grant on sessions restored to authenticated' as check_name,
    current_setting('test.sabotage_raw_write_blocked') as actual, 'true' as expected,
    current_setting('test.sabotage_raw_write_blocked')::boolean = true as pass;
    -- ^ this `pass` is expected to read FALSE here (actual will be false,
    -- the write succeeds) -- that is the whole point: restoring the grant
    -- makes this assertion fail, proving the suite would catch the exact
    -- regression that made the live PATCH in the report succeed.
rollback;
