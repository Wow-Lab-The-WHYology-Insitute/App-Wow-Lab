-- db/tests/rls_ws_d_read.sql
-- WOW LAB OS, Phase 0 WS-D (D1a): impersonation-based checks for the SELECT
-- RLS policies + base GRANTs added in
-- supabase/migrations/202607100002_add_read_select_policies_ws_d_d1a.sql.
--
-- Unlike db/tests/rls_d0_helpers.sql (which only ever called the app.*
-- SECURITY DEFINER helpers directly, since no table policies existed yet),
-- this suite queries the REAL tables — public.legal_entities,
-- public.org_settings, public.users, etc. — as `authenticated`, so it
-- exercises the GRANT + POLICY combination end to end, not just the helpers.
--
-- Pattern per block: resolve the test fixture's user id / org id(s) into
-- session GUCs *while still running with full read access*, THEN switch role
-- to `authenticated` and set request.jwt.claims to that user's id, THEN query
-- the real tables. Run block-by-block in the SQL Editor, or as a whole
-- script. Every block is wrapped in BEGIN/ROLLBACK — nothing here persists,
-- and no fixture data is ever mutated.
--
-- Each assertion is a SELECT with an explicit `expected` column and a `pass`
-- boolean so results can be eyeballed directly in the result grid.

-- ============================================================================
-- Block 1 — test+trainer-a@wowlab.dev (trainer @ wow-lab)
-- Represents "any authenticated user" for the reference-table checks, since
-- trainer is one of the lowest-privilege roles in the catalog.
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

  select
    'trainer_a: roles readable (count > 0)' as check_name,
    (select count(*) from public.roles) as actual,
    true as expected,
    (select count(*) from public.roles) > 0 as pass;

  select
    'trainer_a: capabilities readable (count > 0)' as check_name,
    (select count(*) from public.capabilities) as actual,
    true as expected,
    (select count(*) from public.capabilities) > 0 as pass;

  select
    'trainer_a: role_capabilities readable (count > 0)' as check_name,
    (select count(*) from public.role_capabilities) as actual,
    true as expected,
    (select count(*) from public.role_capabilities) > 0 as pass;

  select
    'trainer_a: users returns exactly 1 row (own — no org.members.read)' as check_name,
    (select count(*) from public.users) as actual,
    1 as expected,
    (select count(*) from public.users) = 1 as pass;

  -- audit_log is currently empty in absolute terms (no business events have
  -- been logged yet), so a bare row-count of 0 here would pass trivially
  -- regardless of policy correctness. The has_capability check below is the
  -- real assertion; the row-count is kept for when the table has data.
  select
    'trainer_a: audit_log returns 0 rows (no org.audit.read) — table is globally empty right now, see note above' as check_name,
    (select count(*) from public.audit_log) as actual,
    0 as expected,
    (select count(*) from public.audit_log) = 0 as pass;

  select
    'trainer_a: has_capability(org.audit.read, wow-lab) = false — backstops the audit_log check above' as check_name,
    app.has_capability('org.audit.read', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('org.audit.read', current_setting('app.test_org_wow_lab')::uuid) = false as pass;
rollback;

-- ============================================================================
-- Block 2 — test+owner-a@wowlab.dev (organization_owner @ wow-lab)
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

  select
    'owner_a: legal_entities returns wow-lab''s 3 rows' as check_name,
    (select count(*) from public.legal_entities) as actual,
    3 as expected,
    (select count(*) from public.legal_entities) = 3 as pass;

  select
    'owner_a: org_settings returns exactly 1 row (wow-lab''s own)' as check_name,
    (select count(*) from public.org_settings) as actual,
    1 as expected,
    (select count(*) from public.org_settings) = 1 as pass;

  select
    'owner_a: the visible org_settings row is wow-lab''s own' as check_name,
    (select organization_id from public.org_settings limit 1) as actual,
    current_setting('app.test_org_wow_lab')::uuid as expected,
    (select organization_id from public.org_settings limit 1) = current_setting('app.test_org_wow_lab')::uuid as pass;
rollback;

-- ============================================================================
-- Block 3 — test+user-b@wowlab.dev (organization_owner @ wow-lab-test-b only)
-- The cross-org isolation checks — the crown jewel of this suite.
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
  select set_config('app.test_org_wow_lab_test_b', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);

  select set_config('role', 'authenticated', true);

  select
    'user_b: legal_entities for wow-lab returns 0 rows — cannot see wow-lab (cross-org isolation)' as check_name,
    (select count(*) from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid) as actual,
    0 as expected,
    (select count(*) from public.legal_entities where organization_id = current_setting('app.test_org_wow_lab')::uuid) = 0 as pass;

  select
    'user_b: org_settings for wow-lab returns 0 rows — cannot see wow-lab''s settings' as check_name,
    (select count(*) from public.org_settings where organization_id = current_setting('app.test_org_wow_lab')::uuid) as actual,
    0 as expected,
    (select count(*) from public.org_settings where organization_id = current_setting('app.test_org_wow_lab')::uuid) = 0 as pass;

  select
    'user_b: org_settings for own org (wow-lab-test-b) returns 1 row — isolation is scoped, not a blanket deny' as check_name,
    (select count(*) from public.org_settings where organization_id = current_setting('app.test_org_wow_lab_test_b')::uuid) as actual,
    1 as expected,
    (select count(*) from public.org_settings where organization_id = current_setting('app.test_org_wow_lab_test_b')::uuid) = 1 as pass;
rollback;
