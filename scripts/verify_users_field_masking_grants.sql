-- verify_users_field_masking_grants.sql
-- Dry-run verification for supabase/migrations/202608210001_users_field_masking_grants.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the grant flip's DDL, then the six assertions, then RAISES an
-- exception whose message IS the full report -- so the transaction can
-- never commit, on purpose, even if every assertion passes.
--
-- Run with: supabase db query --linked --file scripts/verify_users_field_masking_grants.sql
-- Expect: a P0001 error whose message is the assertion report below.
--
-- Session role stays elevated (postgres-equivalent, BYPASSRLS) through
-- Phase 0 and Phase 1. SET LOCAL ROLE authenticated happens exactly once,
-- in Phase 2. After that, every different simulated user is a change to
-- request.jwt.claims only -- never another role switch (never RESET ROLE
-- either -- on this connection type that lands on cli_login_postgres, a
-- lesser role, not back on the elevated one).
--
-- Assertions 6c/6d don't need a role switch at all: has_table_privilege()/
-- has_column_privilege() report what a NAMED role can do without ever
-- becoming that role, so service_role's and postgres's own privileges can
-- be checked directly, from whatever role is current.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608210001's DDL exactly.
-- ============================================================================

revoke select on public.users from authenticated;

grant select (
  id,
  full_name,
  status,
  is_platform_owner,
  created_at,
  updated_at,
  first_name,
  last_name,
  avatar_url,
  is_test_account
) on public.users to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures and snapshot ground truth
-- before the one role switch.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_user_manage', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.test_user_fellow', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);

-- Ground truth, captured while still privileged -- assertions 3/4 compare
-- the view's output against this snapshot, same reasoning as
-- verify_users_masked_view.sql's own _verify_expected_users table.
create temp table _verify_expected_users on commit drop as
select id, email, phone
from public.users
where id in (
  current_setting('app.test_user_manage')::uuid,
  current_setting('app.test_user_fellow')::uuid
);

grant select on _verify_expected_users to authenticated;

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
  v_user_manage uuid := current_setting('app.test_user_manage')::uuid;
  v_user_fellow uuid := current_setting('app.test_user_fellow')::uuid;
  v_expected_email text;
  v_expected_phone text;
  v_got_email text;
  v_got_phone text;
  v_full_name text;
  v_status text;
  v_is_platform_owner boolean;
  v_created_at timestamptz;
  v_updated_at timestamptz;
  v_first_name text;
  v_last_name text;
  v_avatar_url text;
  v_is_test_account boolean;
  v_svc_table_select boolean;
  v_svc_email_select boolean;
  v_pg_email_select boolean;
  v_id_check uuid;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_manage::text, 'role', 'authenticated')::text, true);

  -- ---- 1. Direct base-table select of email/phone -> insufficient_privilege ----
  begin
    execute 'select email, phone from public.users where id = $1'
      into v_expected_email, v_expected_phone using v_user_manage;
    report := report || format(E'\n1. FAIL - direct select of email/phone unexpectedly succeeded (email=%s)', v_expected_email);
  exception
    when insufficient_privilege then
      report := report || E'\n1. PASS - direct base-table select of email/phone raised insufficient_privilege';
  end;

  -- ---- 2. Direct base-table select of the ten allowed columns -> succeeds ----
  begin
    execute 'select id, full_name, status, is_platform_owner, created_at, updated_at, first_name, last_name, avatar_url, is_test_account from public.users where id = $1'
      into v_id_check, v_full_name, v_status, v_is_platform_owner, v_created_at, v_updated_at, v_first_name, v_last_name, v_avatar_url, v_is_test_account
      using v_user_manage;
    report := report || E'\n2. PASS - direct base-table select of all ten allowed columns succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n2. FAIL - direct select of the ten allowed columns unexpectedly raised insufficient_privilege';
  end;

  -- ---- 3. Through the view: own row still shows real email/phone ----
  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_manage;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_manage;

  if v_got_email is not distinct from v_expected_email and v_got_phone is not distinct from v_expected_phone then
    report := report || E'\n3. PASS - own row still shows real email/phone through the view';
  else
    report := report || format(E'\n3. FAIL - expected email=%s phone=%s, got email=%s phone=%s', v_expected_email, v_expected_phone, v_got_email, v_got_phone);
  end if;

  -- ---- 4. Through the view: manage-holder sees a fellow member's real values ----
  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_fellow;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_fellow;

  if v_got_email is not distinct from v_expected_email and v_got_phone is not distinct from v_expected_phone then
    report := report || E'\n4. PASS - manage-holder still sees a fellow member''s real email/phone through the view';
  else
    report := report || format(E'\n4. FAIL - expected email=%s phone=%s, got email=%s phone=%s', v_expected_email, v_expected_phone, v_got_email, v_got_phone);
  end if;

  -- ---- 5. Through the view: non-manage caller sees null ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_fellow::text, 'role', 'authenticated')::text, true);

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_manage;

  if v_got_email is null and v_got_phone is null then
    report := report || E'\n5. PASS - non-manage caller still sees null for another member through the view';
  else
    report := report || format(E'\n5. FAIL - expected null/null, got email=%s phone=%s', v_got_email, v_got_phone);
  end if;

  -- ---- 6. Write paths still work ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_manage::text, 'role', 'authenticated')::text, true);

  -- 6a. profile/actions.ts's updateOwnProfile: UPDATE ... SET first_name,
  -- last_name, phone WHERE id = <self>, no RETURNING (confirmed against
  -- node_modules/@supabase/postgrest-js source: plain .update() without a
  -- chained .select() sends no `Prefer: return=` header at all, and
  -- PostgREST's own default for that case is return=minimal -- no
  -- representation built, no read-back of any column beyond what WHERE
  -- itself needs, which is `id`, already covered by assertion 2's grant).
  begin
    update public.users
      set first_name = 'Verify', last_name = 'Write', phone = '0000000000'
      where id = v_user_manage;
    report := report || E'\n6a. PASS - updateOwnProfile-shaped UPDATE (first_name/last_name/phone, no RETURNING) succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n6a. FAIL - updateOwnProfile-shaped UPDATE raised insufficient_privilege';
  end;

  -- 6b. profile/actions.ts's uploadOwnAvatar: UPDATE ... SET avatar_url
  -- WHERE id = <self>, no RETURNING -- same reasoning as 6a.
  begin
    update public.users
      set avatar_url = 'verify/test-path'
      where id = v_user_manage;
    report := report || E'\n6b. PASS - uploadOwnAvatar-shaped UPDATE (avatar_url, no RETURNING) succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n6b. FAIL - uploadOwnAvatar-shaped UPDATE raised insufficient_privilege';
  end;

  -- 6c. admin/users/actions.ts's inviteUser/disableAccess/enableAccess
  -- updates (first_name/last_name/phone, status) run through
  -- createServiceRoleClient() -- the service_role Postgres role, not
  -- authenticated. This migration's REVOKE/GRANT names authenticated
  -- only, so service_role's own privileges cannot have been touched by
  -- construction. Confirmed, not assumed: checked directly via
  -- has_table_privilege/has_column_privilege, no role switch needed --
  -- these functions report what the NAMED role can do without ever
  -- becoming that role.
  select has_table_privilege('service_role', 'public.users', 'SELECT') into v_svc_table_select;
  select has_column_privilege('service_role', 'public.users', 'email', 'SELECT') into v_svc_email_select;

  if v_svc_table_select and v_svc_email_select then
    report := report || E'\n6c. PASS - service_role retains full table-level SELECT (including email/phone) after this migration -- admin/users/actions.ts''s writes are unaffected';
  else
    report := report || format(E'\n6c. UNEXPECTED - service_role''s SELECT on public.users changed (table=%s, email=%s) -- this migration should not have touched service_role at all, re-check', v_svc_table_select, v_svc_email_select);
  end if;

  -- 6d. The invite trigger (handle_new_auth_user, confirmed live via
  -- pg_proc before writing this: SECURITY DEFINER, owned by postgres,
  -- which also owns public.users itself per pg_tables) inserts as
  -- postgres, not authenticated -- ownership implies full privileges on
  -- the table regardless of any GRANT/REVOKE naming authenticated.
  -- Confirmed, not assumed, the same way as 6c.
  select has_column_privilege('postgres', 'public.users', 'email', 'SELECT') into v_pg_email_select;

  if v_pg_email_select then
    report := report || E'\n6d. PASS - postgres (the invite trigger''s owner, and public.users'' own table owner) retains SELECT on email after this migration -- the trigger''s insert path is unaffected';
  else
    report := report || E'\n6d. UNEXPECTED - postgres lost SELECT on email -- this migration should not have touched postgres at all, re-check';
  end if;

  raise exception E'VERIFICATION REPORT for 202608210001_users_field_masking_grants.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
