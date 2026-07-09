-- db/tests/rls_d0_helpers.sql
-- WOW LAB OS, Phase 0 WS-D (D0): impersonation-based checks for the RLS
-- helper functions in schema `app` (see supabase/migrations/202607090001_*).
--
-- No table policies exist yet (D1) — deny-by-default RLS means the
-- `authenticated` role cannot read public.users/organizations/etc. directly.
-- So each block resolves the test fixture's user id / org id into session
-- GUCs *while still running with full read access*, THEN switches role to
-- `authenticated`, and from that point on ONLY calls the app.* helper
-- functions (which are SECURITY DEFINER and read the tables internally
-- regardless of the caller's own grants). Nothing is asserted by reading
-- app tables directly as `authenticated` — that would fail with
-- "permission denied", not prove anything about the helpers.
--
-- Run block-by-block in the SQL Editor, or as a whole script. Every block
-- is wrapped in BEGIN/ROLLBACK — nothing here persists.
-- Each assertion is a SELECT with an explicit `expected` column and a
-- `pass` boolean so results can be eyeballed directly in the result grid.

-- ============================================================================
-- Block 1 — test+catalina@wowlab.dev
-- (operations_manager + curriculum_manager + evaluator @ wow-lab)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+catalina@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select set_config('role', 'authenticated', true);

  select
    'catalina: is_platform_owner()' as check_name,
    app.is_platform_owner() as actual,
    false as expected,
    app.is_platform_owner() = false as pass;

  select
    'catalina: has_capability(curriculum.lessons.read, wow-lab) — via curriculum.* wildcard' as check_name,
    app.has_capability('curriculum.lessons.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    true as expected,
    app.has_capability('curriculum.lessons.read', current_setting('app.test_org_wow_lab')::uuid) = true as pass;

  select
    'catalina: has_capability(finance.reporting.read, wow-lab) — not granted' as check_name,
    app.has_capability('finance.reporting.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('finance.reporting.read', current_setting('app.test_org_wow_lab')::uuid) = false as pass;

  select
    'catalina: has_capability(curriculumX.read, wow-lab) — dot-boundary, must NOT match curriculum.*' as check_name,
    app.has_capability('curriculumX.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('curriculumX.read', current_setting('app.test_org_wow_lab')::uuid) = false as pass;
rollback;

-- ============================================================================
-- Block 2 — test+platform@wowlab.dev (Platform Owner, no user_org_roles rows)
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+platform@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab_test_b', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);

  select set_config('role', 'authenticated', true);

  select
    'platform: is_platform_owner()' as check_name,
    app.is_platform_owner() as actual,
    true as expected,
    app.is_platform_owner() = true as pass;

  select
    'platform: belongs_to_org(wow-lab-test-b) — cross-org bypass, no user_org_roles row needed' as check_name,
    app.belongs_to_org(current_setting('app.test_org_wow_lab_test_b')::uuid) as actual,
    true as expected,
    app.belongs_to_org(current_setting('app.test_org_wow_lab_test_b')::uuid) = true as pass;
rollback;

-- ============================================================================
-- Block 3 — test+trainer-a@wowlab.dev (trainer @ wow-lab)
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
  select set_config('app.test_org_wow_lab_test_b', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);

  select set_config('role', 'authenticated', true);

  select
    'trainer_a: has_capability(finance.reporting.read, wow-lab) — not granted' as check_name,
    app.has_capability('finance.reporting.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('finance.reporting.read', current_setting('app.test_org_wow_lab')::uuid) = false as pass;

  select
    'trainer_a: has_capability(curriculum.read, wow-lab) — exact-match capability' as check_name,
    app.has_capability('curriculum.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    true as expected,
    app.has_capability('curriculum.read', current_setting('app.test_org_wow_lab')::uuid) = true as pass;

  select
    'trainer_a: belongs_to_org(wow-lab)' as check_name,
    app.belongs_to_org(current_setting('app.test_org_wow_lab')::uuid) as actual,
    true as expected,
    app.belongs_to_org(current_setting('app.test_org_wow_lab')::uuid) = true as pass;

  select
    'trainer_a: belongs_to_org(wow-lab-test-b) — no cross-org membership' as check_name,
    app.belongs_to_org(current_setting('app.test_org_wow_lab_test_b')::uuid) as actual,
    false as expected,
    app.belongs_to_org(current_setting('app.test_org_wow_lab_test_b')::uuid) = false as pass;
rollback;

-- ============================================================================
-- Block 4 — test+user-b@wowlab.dev (organization_owner @ wow-lab-test-b only)
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

  select
    'user_b: has_capability(clients.read, wow-lab) — no role in wow-lab' as check_name,
    app.has_capability('clients.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('clients.read', current_setting('app.test_org_wow_lab')::uuid) = false as pass;
rollback;
