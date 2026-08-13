-- db/tests/rls_groups_sessions.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — live RLS
-- test suite. Mirrors db/tests/rls_clients_contracts.sql's exact style:
-- impersonation via set_config('request.jwt.claims', ...) inside a
-- begin/rollback block per point, fixtures created while still privileged
-- (before the role switch) when the impersonated role itself lacks the
-- write capability needed to set them up, final assertions as a single
-- UNION ALL'd SELECT so `supabase db query --file` (which only returns the
-- LAST statement's result set) can report every check_name/actual/
-- expected/pass row in one go.
--
-- Run each point's block independently: extract via
--   sed -n '<start>,<end>p' db/tests/rls_groups_sessions.sql > /tmp/point_N.sql
--   supabase db query --linked --file /tmp/point_N.sql
-- Every block ends in ROLLBACK — safe to re-run at any time, never leaves
-- fixture rows behind (confirmed at the end of this file).

-- ============================================================================
-- Points 1+2 — Trainer A sees ONLY sessions where they are trainer_
-- principal_id or trainer_secundar_id (zero rows for sessions they're not
-- allocated to), and specifically cannot see Trainer B's sessions. Also
-- confirms groups visibility follows the same rule: Trainer A sees the
-- group referenced by their own sessions, but NOT a second group that only
-- has a Trainer-B session.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);
  select set_config('app.test_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  -- Fixtures created while privileged (neither trainer role holds
  -- groups.create/sessions.create) — mirrors how C1's Point 4/5 set up
  -- fixtures before switching roles.
  do $$
  declare
    v_client uuid;
    v_group_a uuid; -- has trainer_a's sessions
    v_group_b uuid; -- has ONLY trainer_b's session
    v_session_principal uuid; -- trainer_a as principal
    v_session_secundar uuid;  -- trainer_a as secundar
    v_session_other_trainer uuid; -- trainer_b only, different group
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Client', 'private_school', 'active')
    returning id into v_client;

    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'gaga', 'recurring', 'active')
    returning id into v_group_a;
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'astronomy', 'recurring', 'active')
    returning id into v_group_b;

    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group_a, '2026-09-01', current_setting('app.test_trainer_a')::uuid, 'planned')
    returning id into v_session_principal;
    insert into public.sessions (organization_id, group_id, session_date, trainer_secundar_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group_a, '2026-09-08', current_setting('app.test_trainer_a')::uuid, 'planned')
    returning id into v_session_secundar;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group_b, '2026-09-01', current_setting('app.test_trainer_b')::uuid, 'planned')
    returning id into v_session_other_trainer;

    perform set_config('app.fixture_group_a', v_group_a::text, true);
    perform set_config('app.fixture_group_b', v_group_b::text, true);
    perform set_config('app.fixture_session_principal', v_session_principal::text, true);
    perform set_config('app.fixture_session_secundar', v_session_secundar::text, true);
    perform set_config('app.fixture_session_other_trainer', v_session_other_trainer::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+trainer-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'trainer_a: sees own session as PRINCIPAL' as check_name,
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_principal')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_principal')::uuid) = 1 as pass
  union all
  select 'trainer_a: sees own session as SECUNDAR',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_secundar')::uuid)::text,
    '1',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_secundar')::uuid) = 1
  union all
  select 'trainer_a: CANNOT see trainer_b''s session (zero rows, not allocated)',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_other_trainer')::uuid)::text,
    '0',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_other_trainer')::uuid) = 0
  union all
  select 'trainer_a: total visible sessions among the 3 fixtures is exactly 2 (no leakage beyond own allocation)',
    (select count(*) from public.sessions where id in (
      current_setting('app.fixture_session_principal')::uuid,
      current_setting('app.fixture_session_secundar')::uuid,
      current_setting('app.fixture_session_other_trainer')::uuid
    ))::text,
    '2',
    (select count(*) from public.sessions where id in (
      current_setting('app.fixture_session_principal')::uuid,
      current_setting('app.fixture_session_secundar')::uuid,
      current_setting('app.fixture_session_other_trainer')::uuid
    )) = 2
  union all
  select 'trainer_a: sees group_a (referenced by their own sessions)',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_a')::uuid)::text,
    '1',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_a')::uuid) = 1
  union all
  select 'trainer_a: CANNOT see group_b (referenced ONLY by trainer_b''s session, not all groups generally)',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_b')::uuid)::text,
    '0',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_b')::uuid) = 0;
rollback;

-- ============================================================================
-- Point 3 — Operations Manager (test+catalina) sees ALL groups/sessions in
-- the org, no trainer-style segregation (SAD/task: this domain has no
-- client-type-style record segregation the way Clients & Contracts does).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Ops Client', 'corporate', 'active')
    returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'detective', 'party', 'active')
    returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group, '2026-09-15', current_setting('app.test_trainer_b')::uuid, 'planned')
    returning id into v_session;

    perform set_config('app.fixture_group_ops', v_group::text, true);
    perform set_config('app.fixture_session_ops', v_session::text, true);
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

  select 'operations_manager: sees the fixture group (org-wide, not the allocated trainer)' as check_name,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_ops')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_ops')::uuid) = 1 as pass
  union all
  select 'operations_manager: sees the fixture session (allocated to trainer_b, not them)',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_ops')::uuid)::text,
    '1',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_ops')::uuid) = 1;
rollback;

-- ============================================================================
-- Point 4 — Finance Admin & Reporting sees all groups/sessions, but CANNOT
-- INSERT/UPDATE either table (action-level: SELECT only, per the task's
-- conservative reading of the SAD's flagged ambiguity).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Finance Admin Client', 'state_school', 'active')
    returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'lights', 'saptamana_verde', 'active')
    returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group, '2026-09-20', current_setting('app.test_trainer_a')::uuid, 'planned')
    returning id into v_session;

    perform set_config('app.fixture_group_fa', v_group::text, true);
    perform set_config('app.fixture_session_fa', v_session::text, true);
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

  do $$
  declare
    v_group_insert_blocked boolean := false;
    v_session_insert_blocked boolean := false;
    v_group_update_count int;
    v_session_update_count int;
  begin
    -- client_id is required on groups; finance_admin_reporting DOES hold
    -- clients.read but not clients.create, so reuse the existing fixture
    -- client (via the fixture group created while privileged, above) for
    -- the blocked INSERT attempt -- the point being tested is
    -- groups.create, not clients.create.
    begin
      insert into public.groups (organization_id, client_id, module, delivery_format, status)
      values (
        current_setting('app.test_org_wow_lab')::uuid,
        (select client_id from public.groups where id = current_setting('app.fixture_group_fa')::uuid),
        'chem_me', 'custom', 'active'
      );
    exception
      when insufficient_privilege then
        v_group_insert_blocked := true;
    end;
    perform set_config('test.fa_group_insert_blocked', v_group_insert_blocked::text, true);

    begin
      insert into public.sessions (organization_id, group_id, session_date, status)
      values (
        current_setting('app.test_org_wow_lab')::uuid,
        current_setting('app.fixture_group_fa')::uuid,
        '2026-09-21',
        'planned'
      );
    exception
      when insufficient_privilege then
        v_session_insert_blocked := true;
    end;
    perform set_config('test.fa_session_insert_blocked', v_session_insert_blocked::text, true);

    update public.groups set status = 'paused' where id = current_setting('app.fixture_group_fa')::uuid;
    get diagnostics v_group_update_count = row_count;
    perform set_config('test.fa_group_update_count', v_group_update_count::text, true);

    update public.sessions set status = 'cancelled' where id = current_setting('app.fixture_session_fa')::uuid;
    get diagnostics v_session_update_count = row_count;
    perform set_config('test.fa_session_update_count', v_session_update_count::text, true);
  end $$;

  select 'finance_admin: sees the fixture group (SELECT, org-wide)' as check_name,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_fa')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_fa')::uuid) = 1 as pass
  union all
  select 'finance_admin: sees the fixture session (SELECT, org-wide)',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_fa')::uuid)::text,
    '1',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_fa')::uuid) = 1
  union all
  select 'finance_admin: INSERT groups is BLOCKED (no groups.create)',
    current_setting('test.fa_group_insert_blocked'),
    'true',
    current_setting('test.fa_group_insert_blocked')::boolean = true
  union all
  select 'finance_admin: INSERT sessions is BLOCKED (no sessions.create)',
    current_setting('test.fa_session_insert_blocked'),
    'true',
    current_setting('test.fa_session_insert_blocked')::boolean = true
  union all
  select 'finance_admin: UPDATE groups affects 0 rows (no write capability)',
    current_setting('test.fa_group_update_count'),
    '0',
    current_setting('test.fa_group_update_count') = '0'
  union all
  select 'finance_admin: UPDATE sessions affects 0 rows (no write capability)',
    current_setting('test.fa_session_update_count'),
    '0',
    current_setting('test.fa_session_update_count') = '0';
rollback;

-- ============================================================================
-- Point 5 — Operations Manager (test+catalina) can create a group, create
-- a session, and set/change BOTH trainer_principal_id and
-- trainer_secundar_id.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);
  select set_config('app.test_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  -- clients.create is not held by operations_manager either -- reuse a
  -- privileged-created fixture client, same reasoning as Point 4.
  do $$
  declare
    v_client uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Ops-Create Client', 'private_school', 'active')
    returning id into v_client;
    perform set_config('app.fixture_client', v_client::text, true);
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

  do $$
  declare
    v_group uuid;
    v_session uuid;
    v_update_count int;
  begin
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, current_setting('app.fixture_client')::uuid, 'wow_mix', 'recurring', 'active')
    returning id into v_group;
    perform set_config('app.fixture_group', v_group::text, true);

    insert into public.sessions (organization_id, group_id, session_date, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group, '2026-10-01', 'planned')
    returning id into v_session;
    perform set_config('app.fixture_session', v_session::text, true);

    -- Set BOTH trainer fields, then CHANGE them in a second UPDATE, proving
    -- "set/change" (not just set-once).
    update public.sessions
       set trainer_principal_id = current_setting('app.test_trainer_a')::uuid,
           trainer_secundar_id = current_setting('app.test_trainer_b')::uuid
     where id = v_session;
    get diagnostics v_update_count = row_count;
    perform set_config('test.ops_allocate_count', v_update_count::text, true);

    update public.sessions
       set trainer_principal_id = current_setting('app.test_trainer_b')::uuid,
           trainer_secundar_id = current_setting('app.test_trainer_a')::uuid
     where id = v_session;
    get diagnostics v_update_count = row_count;
    perform set_config('test.ops_reallocate_count', v_update_count::text, true);
  end $$;

  select 'operations_manager: INSERT groups succeeds (groups.create)' as check_name,
    (select count(*) from public.groups where id = current_setting('app.fixture_group')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.groups where id = current_setting('app.fixture_group')::uuid) = 1 as pass
  union all
  select 'operations_manager: INSERT sessions succeeds (sessions.create)',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session')::uuid)::text,
    '1',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session')::uuid) = 1
  union all
  select 'operations_manager: UPDATE sets trainer_principal_id + trainer_secundar_id (1 row)',
    current_setting('test.ops_allocate_count'),
    '1',
    current_setting('test.ops_allocate_count') = '1'
  union all
  select 'operations_manager: UPDATE CHANGES trainer_principal_id + trainer_secundar_id (1 row, rotation)',
    current_setting('test.ops_reallocate_count'),
    '1',
    current_setting('test.ops_reallocate_count') = '1'
  union all
  select 'operations_manager: final trainer_principal_id reflects the rotation (now trainer_b)',
    (select trainer_principal_id::text from public.sessions where id = current_setting('app.fixture_session')::uuid),
    current_setting('app.test_trainer_b'),
    (select trainer_principal_id from public.sessions where id = current_setting('app.fixture_session')::uuid) = current_setting('app.test_trainer_b')::uuid
  union all
  select 'operations_manager: final trainer_secundar_id reflects the rotation (now trainer_a)',
    (select trainer_secundar_id::text from public.sessions where id = current_setting('app.fixture_session')::uuid),
    current_setting('app.test_trainer_a'),
    (select trainer_secundar_id from public.sessions where id = current_setting('app.fixture_session')::uuid) = current_setting('app.test_trainer_a')::uuid;
rollback;

-- ============================================================================
-- Point 6 — cross-org isolation for groups/sessions, reusing the org_b
-- fixture (test+user-b, organization_owner @ wow-lab-test-b only).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_org_wow_lab_test_b', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);

  do $$
  declare
    v_client_a uuid;
    v_client_b uuid;
    v_group_a uuid;
    v_group_b uuid;
    v_session_a uuid;
    v_session_b uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Org A Client', 'corporate', 'active')
    returning id into v_client_a;
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, 'Fixture GS Org B Client', 'corporate', 'active')
    returning id into v_client_b;

    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client_a, 'gaga', 'recurring', 'active')
    returning id into v_group_a;
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, v_client_b, 'gaga', 'recurring', 'active')
    returning id into v_group_b;

    insert into public.sessions (organization_id, group_id, session_date, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group_a, '2026-10-05', 'planned')
    returning id into v_session_a;
    insert into public.sessions (organization_id, group_id, session_date, status)
    values (current_setting('app.test_org_wow_lab_test_b')::uuid, v_group_b, '2026-10-05', 'planned')
    returning id into v_session_b;

    perform set_config('app.fixture_group_a', v_group_a::text, true);
    perform set_config('app.fixture_group_b', v_group_b::text, true);
    perform set_config('app.fixture_session_a', v_session_a::text, true);
    perform set_config('app.fixture_session_b', v_session_b::text, true);
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

  select 'user_b: cannot see wow-lab''s (org A) fixture group (cross-org isolation)' as check_name,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_a')::uuid)::text as actual,
    '0' as expected,
    (select count(*) from public.groups where id = current_setting('app.fixture_group_a')::uuid) = 0 as pass
  union all
  select 'user_b: cannot see wow-lab''s (org A) fixture session (cross-org isolation)',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_a')::uuid)::text,
    '0',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_a')::uuid) = 0
  union all
  select 'user_b: sees own org (org B) fixture group — isolation is scoped, not a blanket deny',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_b')::uuid)::text,
    '1',
    (select count(*) from public.groups where id = current_setting('app.fixture_group_b')::uuid) = 1
  union all
  select 'user_b: sees own org (org B) fixture session — isolation is scoped, not a blanket deny',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_b')::uuid)::text,
    '1',
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_b')::uuid) = 1;
rollback;

-- ============================================================================
-- Point 7 — SABOTAGE CHECK ("does this suite have teeth?")
-- Deliberately breaks the sessions SELECT record-level segregation to a
-- permissive (true) condition, then re-runs Point 1/2's exact "trainer_a
-- cannot see trainer_b's session" assertion (same expected = 0 / pass =
-- true shape). Under the sabotaged policy trainer_a wrongly sees trainer_
-- b's session too, so `actual` comes back 1 (not 0) and `pass` flips to
-- false — proving the suite would catch this exact regression. Undone by
-- ROLLBACK, including the ALTER POLICY — safe to re-run at any time.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.test_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_group uuid;
    v_session uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS Sabotage Client', 'corporate', 'active')
    returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'astronomy', 'recurring', 'active')
    returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group, '2026-10-10', current_setting('app.test_trainer_b')::uuid, 'planned')
    returning id into v_session;
    perform set_config('app.fixture_session_sabotage', v_session::text, true);
  end $$;

  -- Still privileged at this point (role not yet switched) — sabotage the
  -- real policy in place.
  alter policy "authenticated select sessions" on public.sessions
    using (true);

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+trainer-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'SABOTAGE: trainer_a sees trainer_b''s session, same assertion as Point 1/2, policy USING forced to (true)' as check_name,
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_sabotage')::uuid)::text as actual,
    '0' as expected,
    (select count(*) from public.sessions where id = current_setting('app.fixture_session_sabotage')::uuid) = 0 as pass;
    -- ^ this `pass` is expected to read FALSE here (actual will be 1, not
    -- 0) — that is the whole point: a broken record-level policy makes
    -- this assertion fail, proving the suite has teeth.
rollback;

-- ============================================================================
-- Point 8 — row_history captures UPDATE correctly on BOTH groups and
-- sessions (matching the established INSERT-not-captured convention
-- already confirmed for Clients & Contracts, DATABASE_CONVENTIONS.md #8:
-- BEFORE UPDATE OR DELETE only). Confirms BOTH halves live: zero row_
-- history rows exist right after INSERT, then exactly one appears after
-- UPDATE, with organization_id populated correctly.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  -- test+catalina (operations_manager) holds groups.create/sessions.create
  -- but NOT clients.create -- the fixture client is created while still
  -- privileged, same reasoning as every other block in this suite.
  do $$
  declare
    v_client uuid;
  begin
    insert into public.clients (organization_id, name, client_type, status)
    values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture GS RowHistory Client', 'private_school', 'active')
    returning id into v_client;
    perform set_config('app.fixture_client', v_client::text, true);
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

  do $$
  declare
    v_group uuid;
    v_session uuid;
  begin
    insert into public.groups (organization_id, client_id, module, delivery_format, status)
    values (current_setting('app.test_org_wow_lab')::uuid, current_setting('app.fixture_client')::uuid, 'lotions', 'recurring', 'active')
    returning id into v_group;
    perform set_config('app.fixture_group', v_group::text, true);
    perform set_config('test.group_history_before_update', (select count(*) from public.row_history where table_name = 'groups' and row_id = v_group)::text, true);

    insert into public.sessions (organization_id, group_id, session_date, status)
    values (current_setting('app.test_org_wow_lab')::uuid, v_group, '2026-10-15', 'planned')
    returning id into v_session;
    perform set_config('app.fixture_session', v_session::text, true);
    perform set_config('test.session_history_before_update', (select count(*) from public.row_history where table_name = 'sessions' and row_id = v_session)::text, true);

    update public.groups set status = 'paused' where id = v_group;
    update public.sessions set status = 'delivered', attendance_count = 12 where id = v_session;
  end $$;

  -- test+catalina has org.audit.read? No -- only organization_owner gets
  -- that via the B4 dynamic grant. RESET ROLE before querying row_history,
  -- same reasoning as C1 Point 5 -- verifies the TRIGGER fired, not this
  -- role's own audit-read capability (a separate, already-covered concern).
  reset role;

  select 'groups: row_history has ZERO rows right after INSERT (not captured, matches convention)' as check_name,
    current_setting('test.group_history_before_update') as actual,
    '0' as expected,
    current_setting('test.group_history_before_update') = '0' as pass
  union all
  select 'groups: row_history captured the UPDATE (exactly 1 row) with organization_id populated',
    (
      select count(*)::text || '/' || coalesce((select organization_id::text from public.row_history where table_name = 'groups' and row_id = current_setting('app.fixture_group')::uuid), 'NULL')
      from public.row_history where table_name = 'groups' and row_id = current_setting('app.fixture_group')::uuid
    ),
    '1/' || current_setting('app.test_org_wow_lab'),
    (
      select count(*) from public.row_history
      where table_name = 'groups' and row_id = current_setting('app.fixture_group')::uuid
        and organization_id = current_setting('app.test_org_wow_lab')::uuid
    ) = 1
  union all
  select 'sessions: row_history has ZERO rows right after INSERT (not captured, matches convention)',
    current_setting('test.session_history_before_update'),
    '0',
    current_setting('test.session_history_before_update') = '0'
  union all
  select 'sessions: row_history captured the UPDATE (exactly 1 row) with organization_id populated',
    (
      select count(*)::text || '/' || coalesce((select organization_id::text from public.row_history where table_name = 'sessions' and row_id = current_setting('app.fixture_session')::uuid), 'NULL')
      from public.row_history where table_name = 'sessions' and row_id = current_setting('app.fixture_session')::uuid
    ),
    '1/' || current_setting('app.test_org_wow_lab'),
    (
      select count(*) from public.row_history
      where table_name = 'sessions' and row_id = current_setting('app.fixture_session')::uuid
        and organization_id = current_setting('app.test_org_wow_lab')::uuid
    ) = 1;
rollback;

-- ============================================================================
-- Final hygiene check — confirm zero leftover "Fixture GS%" clients (every
-- block above ends in ROLLBACK; every group/session fixture is created
-- with client_id pointing at one of these clients, so if the client
-- rollback held, the dependent groups/sessions are gone too — same
-- reasoning and same check shape as C1's own hygiene check).
-- ============================================================================
select count(*) as leftover_fixture_clients from public.clients where name like 'Fixture GS%';
