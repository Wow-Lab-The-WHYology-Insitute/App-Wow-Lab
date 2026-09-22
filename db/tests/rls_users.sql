-- db/tests/rls_users.sql
-- WOW LAB OS: impersonation-based checks for public.users' own SELECT
-- policy (202609160002, the CURRENT live shape) -- the table this
-- register's audit (item 86) found had NO db/tests coverage at all,
-- despite having been rewritten four times (202607100002, 202609160001,
-- 202609160002) and despite item 68's finance.operations.* trainer-
-- visibility branch having shipped silently dead for a day, found only by
-- a person running a one-time script by hand
-- (scripts/verify_users_trainer_name_visibility.sql), never by any
-- re-runnable suite. This file exists so that specific shape of bug --
-- an inline EXISTS reading a table gated by ITS OWN RLS, silently
-- evaluating false for the viewer it was written for -- has a permanent,
-- sabotage-proven regression test from now on.
--
-- Same pattern as every other file in this directory: resolve fixture ids
-- into session GUCs while still privileged, switch role to authenticated,
-- set request.jwt.claims, exercise the real table. Every block is
-- BEGIN/ROLLBACK -- nothing here persists, including the sabotage block's
-- CREATE OR REPLACE FUNCTION.
--
-- Fixture users: test+finance-ops-a@wowlab.dev (finance_operations @
-- wow-lab), test+trainer-a@wowlab.dev (trainer @ wow-lab),
-- test+sales-a@wowlab.dev (sales_manager @ wow-lab -- NOT a trainer, the
-- negative control) -- see supabase/seed.sql.

-- ============================================================================
-- Point 1 — finance_ops_a sees trainer_a's user row (the branch item 68
-- found dead: app.viewer_sees_trainer_via_finance_ops()).
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.fixture_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'finance_ops_a: sees trainer_a''s user row (viewer_sees_trainer_via_finance_ops)' as check_name,
    (select count(*) from public.users where id = current_setting('app.fixture_trainer_a')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.users where id = current_setting('app.fixture_trainer_a')::uuid) = 1 as pass;
rollback;

-- ============================================================================
-- Point 2 — finance_ops_a does NOT see sales_a's user row (sales_a holds
-- no trainer role in wow-lab -- the branch is scoped to trainer/
-- senior_trainer specifically, not "any user finance_operations wants").
-- ============================================================================
begin;
  select set_config('app.fixture_sales_a', (select id::text from public.users where email = 'test+sales-a@wowlab.dev'), true);

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'finance_ops_a: does NOT see sales_a''s user row (not a trainer, branch is scoped)' as check_name,
    (select count(*) from public.users where id = current_setting('app.fixture_sales_a')::uuid)::text as actual,
    '0' as expected,
    (select count(*) from public.users where id = current_setting('app.fixture_sales_a')::uuid) = 0 as pass;
rollback;

-- ============================================================================
-- Point 3 — SABOTAGE CHECK ("does this suite have teeth?"). Reverts
-- app.viewer_sees_trainer_via_finance_ops() to the EXACT pre-202609160002
-- shape -- an inline read of user_org_roles, subject to that table's own
-- SELECT policy (is_platform_owner() OR user_id = current_user_id() OR
-- has_capability('org.members.read', ...)) -- which is precisely the bug
-- item 68 found: finance_ops_a holds finance.operations.*, not
-- org.members.read, so the inner read of trainer_a's own user_org_roles
-- row returns zero rows before has_capability('finance.operations.*',
-- ...) is ever consulted. Re-runs Point 1's exact assertion; under the
-- reverted (buggy) function it should now read 0, not 1, flipping `pass`
-- to false. A plain SELECT, not wrapped in any exception handler -- this
-- sabotage shape cannot suffer the "lookup failure indistinguishable from
-- policy denial" bug item 86 found and fixed in rls_ws_d_write.sql, since
-- no exception is ever raised or caught here.
-- ============================================================================
begin;
  select set_config('app.fixture_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);

  -- Still privileged at this point (role not yet switched) -- revert the
  -- helper to the exact broken pre-fix body (202609160001's own shape,
  -- quoted verbatim in 202609160002's own header).
  create or replace function app.viewer_sees_trainer_via_finance_ops(target_user_id uuid)
  returns boolean
  language sql
  stable
  as $inner$
    select exists (
      select 1
      from public.user_org_roles target_uor
      join public.roles target_role on target_role.id = target_uor.role_id
      where target_uor.user_id = target_user_id
        and target_role.key in ('trainer', 'senior_trainer')
        and app.has_capability('finance.operations.*', target_uor.organization_id)
    );
  $inner$;

  select set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', (select id from public.users where email = 'test+finance-ops-a@wowlab.dev'),
      'role', 'authenticated'
    )::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'SABOTAGE: finance_ops_a no longer sees trainer_a, same assertion as Point 1, helper reverted to the pre-202609160002 (SECURITY INVOKER, RLS-gated) shape' as check_name,
    (select count(*) from public.users where id = current_setting('app.fixture_trainer_a')::uuid)::text as actual,
    '1' as expected,
    (select count(*) from public.users where id = current_setting('app.fixture_trainer_a')::uuid) = 1 as pass;
    -- ^ this `pass` is expected to read FALSE here (actual will be 0, not
    -- 1) -- that is the whole point: reverting the fix makes this
    -- assertion fail, proving the suite would have caught item 68's bug
    -- had this test existed in August.
rollback;
