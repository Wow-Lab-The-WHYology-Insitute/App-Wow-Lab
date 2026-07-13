-- db/tests/capability_liveness.sql
-- WOW LAB OS, Next.js scaffolding S1 (auth), §4: proves app.has_capability()
-- is NOT JWT-cached — a mid-session role change (an admin editing
-- user_org_roles directly, exactly like app/admin/users/actions.ts'
-- editRoles()) is reflected on the very next call, using the SAME JWT the
-- whole time (no re-login, no new token).
--
-- has_capability() is SECURITY DEFINER and resolves purely from
-- app.current_user_id() (= auth.uid(), read from the request.jwt.claims
-- GUC) joined live against user_org_roles/role_capabilities/capabilities —
-- see supabase/migrations/202607090001_create_app_schema_rls_helper_functions.sql.
-- It carries no cache of its own, and Postgres role played no part in that
-- resolution — request.jwt.claims is set once below and never touched
-- again, while every other statement here runs as whatever role is already
-- connected (no SET ROLE needed at all, unlike the RLS read/write suites,
-- since this test never queries a table through a policy — only the
-- SECURITY DEFINER function itself).
--
-- Wrapped in BEGIN/ROLLBACK — the mid-session role grant below never
-- persists.

begin;
  -- test+finance-ops-a@wowlab.dev currently holds only 'finance_operations'
  -- in wow-lab, which does not include org.settings.manage.
  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select
    'BEFORE role change: finance_ops_a has_capability(org.settings.manage) = false' as check_name,
    app.has_capability('org.settings.manage', current_setting('app.test_org_wow_lab')::uuid) as actual,
    false as expected,
    app.has_capability('org.settings.manage', current_setting('app.test_org_wow_lab')::uuid) = false as pass;

  -- Simulates an admin action (e.g. editRoles()) granting this user
  -- organization_owner mid-session — request.jwt.claims is NOT touched.
  insert into public.user_org_roles (organization_id, user_id, role_id)
  select
    current_setting('app.test_org_wow_lab')::uuid,
    (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
    (select id from public.roles where key = 'organization_owner');

  select
    'AFTER role change, SAME session/JWT: finance_ops_a has_capability(org.settings.manage) = true immediately' as check_name,
    app.has_capability('org.settings.manage', current_setting('app.test_org_wow_lab')::uuid) as actual,
    true as expected,
    app.has_capability('org.settings.manage', current_setting('app.test_org_wow_lab')::uuid) = true as pass;
rollback;
