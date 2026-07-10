-- db/tests/rls_ws_d_write.sql
-- WOW LAB OS, Phase 0 WS-D (D1b): impersonation-based checks for the WRITE
-- (INSERT/UPDATE) RLS policies + base GRANTs added in
-- supabase/migrations/202607100004_add_write_policies_ws_d_d1b.sql.
--
-- Same pattern as db/tests/rls_ws_d_read.sql: resolve fixture ids into
-- session GUCs while still privileged, switch role to `authenticated`, set
-- request.jwt.claims to the fixture's user id, then exercise the REAL
-- tables under RLS. Every block is wrapped in BEGIN/ROLLBACK — no fixture
-- data is ever mutated, including the "successful" INSERT/UPDATE proofs.
--
-- Two different failure shapes show up here, and each block tests for the
-- right one:
--   - UPDATE whose USING clause excludes every candidate row: the statement
--     succeeds but silently affects 0 rows. No exception.
--   - INSERT (or any statement) whose WITH CHECK fails, or that has no
--     GRANT at all: the statement raises an "insufficient_privilege"
--     (42501) error. These blocks use a small DO block with an inner
--     BEGIN/EXCEPTION to turn that error into a clean boolean, so the
--     result can still be read as a plain SELECT row like everywhere else.
--
-- Run block-by-block in the SQL Editor, or as a whole script.

-- ============================================================================
-- Block 1 — test+owner-a@wowlab.dev (organization_owner @ wow-lab): POSITIVE
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+owner-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select set_config('role', 'authenticated', true);

  with updated as (
    update public.org_settings
       set evaluations_confidential = not evaluations_confidential
     where organization_id = current_setting('app.test_org_wow_lab')::uuid
    returning id
  )
  select
    'owner_a: UPDATE org_settings (toggle evaluations_confidential) on wow-lab succeeds' as check_name,
    (select count(*) from updated) as actual,
    1 as expected,
    (select count(*) from updated) = 1 as pass;

  -- End-to-end audit trail check: row_history_capture() is SECURITY DEFINER
  -- (202607100006), so the trigger's own insert succeeds regardless of the
  -- invoking (authenticated) role's own grants — and organization_id is
  -- denormalized correctly onto the captured row.
  select
    'owner_a: row_history captured the org_settings UPDATE with organization_id populated' as check_name,
    (
      select rh.organization_id
      from public.row_history rh
      where rh.table_name = 'org_settings'
        and rh.row_id = (select id from public.org_settings where organization_id = current_setting('app.test_org_wow_lab')::uuid)
      order by rh.changed_at desc
      limit 1
    ) as actual,
    current_setting('app.test_org_wow_lab')::uuid as expected,
    (
      select rh.organization_id
      from public.row_history rh
      where rh.table_name = 'org_settings'
        and rh.row_id = (select id from public.org_settings where organization_id = current_setting('app.test_org_wow_lab')::uuid)
      order by rh.changed_at desc
      limit 1
    ) = current_setting('app.test_org_wow_lab')::uuid as pass;

  with inserted as (
    insert into public.user_org_roles (organization_id, user_id, role_id)
    select
      current_setting('app.test_org_wow_lab')::uuid,
      (select id from public.users where email = 'test+catalina@wowlab.dev'),
      (select id from public.roles where key = 'trainer')
    returning id
  )
  select
    'owner_a: INSERT user_org_roles (assign trainer to catalina) in wow-lab succeeds' as check_name,
    (select count(*) from inserted) as actual,
    1 as expected,
    (select count(*) from inserted) = 1 as pass;

  with inserted as (
    insert into public.legal_entities (organization_id, name, entity_type)
    values (
      current_setting('app.test_org_wow_lab')::uuid,
      'WS-D D1b Test Entity (rolled back, never persists)',
      'srl'
    )
    returning id
  )
  select
    'owner_a: INSERT legal_entities in wow-lab succeeds' as check_name,
    (select count(*) from inserted) as actual,
    1 as expected,
    (select count(*) from inserted) = 1 as pass;
rollback;

-- ============================================================================
-- Block 2 — test+trainer-a@wowlab.dev: NEGATIVE (privilege-escalation guard)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+trainer-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select set_config('role', 'authenticated', true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      insert into public.user_org_roles (organization_id, user_id, role_id)
      values (
        current_setting('app.test_org_wow_lab')::uuid,
        (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
        (select id from public.roles where key = 'evaluator')
      );
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.trainer_insert_blocked', v_blocked::text, true);
  end $$;

  select
    'trainer_a: INSERT into user_org_roles in wow-lab is BLOCKED (no org.members.manage) — privilege-escalation guard' as check_name,
    current_setting('test.trainer_insert_blocked')::boolean as actual,
    true as expected,
    current_setting('test.trainer_insert_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Block 3 — test+finance-ops-a@wowlab.dev: NEGATIVE (wrong capability)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select set_config('role', 'authenticated', true);

  with updated as (
    update public.org_settings
       set evaluations_confidential = evaluations_confidential
     where organization_id = current_setting('app.test_org_wow_lab')::uuid
    returning id
  )
  select
    'finance_ops_a: UPDATE org_settings on wow-lab is BLOCKED (no org.settings.manage)' as check_name,
    (select count(*) from updated) as actual,
    0 as expected,
    (select count(*) from updated) = 0 as pass;
rollback;

-- ============================================================================
-- Block 4 — test+user-b@wowlab.dev: NEGATIVE (cross-org write isolation)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+user-b@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select set_config('role', 'authenticated', true);

  with updated as (
    update public.org_settings
       set evaluations_confidential = evaluations_confidential
     where organization_id = current_setting('app.test_org_wow_lab')::uuid
    returning id
  )
  select
    'user_b: UPDATE wow-lab''s org_settings affects 0 rows (cross-org write isolation)' as check_name,
    (select count(*) from updated) as actual,
    0 as expected,
    (select count(*) from updated) = 0 as pass;
rollback;

-- ============================================================================
-- Block 5 — any authenticated (using trainer_a): NEGATIVE (DELETE deny-all)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+trainer-a@wowlab.dev'),
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
      delete from public.legal_entities where id = (select id from public.legal_entities limit 1);
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.delete_blocked', v_blocked::text, true);
  end $$;

  select
    'trainer_a: DELETE from legal_entities is BLOCKED (deny-all, no grant anywhere)' as check_name,
    current_setting('test.delete_blocked')::boolean as actual,
    true as expected,
    current_setting('test.delete_blocked')::boolean = true as pass;
rollback;

-- ============================================================================
-- Block 6 — SABOTAGE CHECK ("does this suite have teeth?")
-- Deliberately breaks the user_org_roles INSERT policy to a permissive
-- (true) condition, then re-runs the EXACT SAME assertion as Block 2 (same
-- `expected = true`, i.e. "should be blocked"). Under the sabotaged policy
-- the insert wrongly succeeds, so `actual` comes back false and `pass`
-- flips to false — proving the suite would catch this exact regression if
-- it ever happened for real. Everything here, including the ALTER POLICY,
-- is undone by the ROLLBACK — safe to re-run at any time.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+trainer-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  -- Still privileged at this point (role not yet switched) — sabotage the
  -- real policy in place.
  alter policy "authenticated insert user_org_roles" on public.user_org_roles
    with check (true);

  select set_config('role', 'authenticated', true);

  do $$
  declare
    v_blocked boolean := false;
  begin
    begin
      insert into public.user_org_roles (organization_id, user_id, role_id)
      values (
        current_setting('app.test_org_wow_lab')::uuid,
        (select id from public.users where email = 'test+finance-admin-a@wowlab.dev'),
        (select id from public.roles where key = 'evaluator')
      );
    exception
      when insufficient_privilege then
        v_blocked := true;
    end;
    perform set_config('test.sabotage_blocked', v_blocked::text, true);
  end $$;

  select
    'SABOTAGE: trainer_a INSERT into user_org_roles, same assertion as Block 2, policy WITH CHECK forced to (true)' as check_name,
    current_setting('test.sabotage_blocked')::boolean as actual,
    true as expected,
    current_setting('test.sabotage_blocked')::boolean = true as pass;
    -- ^ this `pass` is expected to read FALSE here — that is the whole
    -- point: a broken policy makes this assertion fail, proving the suite
    -- has teeth. See docs/progress.md for how this run's result was
    -- reported.
rollback;
