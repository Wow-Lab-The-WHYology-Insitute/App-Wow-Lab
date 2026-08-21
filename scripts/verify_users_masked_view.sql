-- verify_users_masked_view.sql
-- Dry-run verification for supabase/migrations/202608200005_users_masked_view.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the view's DDL, seeds fixtures, runs the six assertions, then
-- RAISES an exception whose message IS the full report -- so the
-- transaction can never commit, on purpose, even if every assertion
-- passes. Nothing here is meant to be applied; this is the branch-less
-- substitute for Supabase Branching (no Pro plan).
--
-- Run with: supabase db query --linked --file scripts/verify_users_masked_view.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Anything OTHER than that specific error (a plain syntax/permission
-- error from the DDL or seeding itself) means something in the migration
-- is broken, not just "an assertion failed" -- read the raw error, not
-- the report, in that case.
--
-- Session role stays postgres (BYPASSRLS) through Phase 0 and Phase 1.
-- SET LOCAL ROLE authenticated happens exactly once, in Phase 2. After
-- that, every different simulated user is a change to request.jwt.claims
-- only -- never another role switch.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608200005's DDL exactly.
-- ============================================================================

grant select (id, email, phone) on public.users to app_masking_owner;

create function app.masked_user_contact_fields(target_user_id uuid)
returns record
language sql
security definer
set search_path = ''
as $$
  select case
    when target_user_id = app.current_user_id()
      or exists (
        select 1
        from public.user_org_roles mine
        join public.user_org_roles theirs
          on theirs.organization_id = mine.organization_id
        where mine.user_id = app.current_user_id()
          and theirs.user_id = target_user_id
          and app.has_capability('org.members.manage', mine.organization_id)
      )
    then row(u.email, u.phone)
    else null
  end
  from public.users u
  where u.id = target_user_id;
$$;

grant app_masking_owner to postgres;
alter function app.masked_user_contact_fields(uuid) owner to app_masking_owner;
revoke execute on function app.masked_user_contact_fields(uuid) from public;
grant execute on function app.masked_user_contact_fields(uuid) to authenticated;
revoke app_masking_owner from postgres;

create view public.users_masked
with (security_invoker = true)
as
select
  u.id,
  f.email,
  u.full_name,
  u.status,
  u.is_platform_owner,
  u.created_at,
  u.updated_at,
  u.first_name,
  u.last_name,
  f.phone,
  u.avatar_url,
  u.is_test_account
from public.users u
cross join lateral app.masked_user_contact_fields(u.id)
  as f(email text, phone text);

grant select on public.users_masked to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged (postgres, BYPASSRLS). Resolve every fixture
-- id, and seed what assertion 4 needs, before the one role switch.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_user_manage', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.test_user_fellow', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.test_user_platform', (select id::text from users where email = 'test+platform@wowlab.dev'), true);
select set_config('app.test_user_orgb_only', (select id::text from users where email = 'test+cascade-check@wowlab.dev'), true);
select set_config('app.test_any_role_id', (select id::text from roles limit 1), true);

-- A second, fully separate organization, seeded inside this same
-- transaction -- assertion 4's whole point is the bound predicate, so the
-- org-B-only user must be verifiably isolated from org A, not just
-- assumed to be from today's data shape.
with ins as (
  insert into organizations (name, slug, is_test)
  values ('VERIFY org B (users masking dry run)', 'verify-users-masking-org-b', true)
  returning id
)
select set_config('app.test_org_b', id::text, true) from ins;

-- test+cascade-check@wowlab.dev holds zero roles anywhere today (confirmed
-- live before writing this) -- temporarily scoped to org B alone, for the
-- duration of this rolled-back transaction only.
with ins as (
  insert into user_org_roles (organization_id, user_id, role_id)
  values (
    current_setting('app.test_org_b')::uuid,
    current_setting('app.test_user_orgb_only')::uuid,
    current_setting('app.test_any_role_id')::uuid
  )
  returning id
)
select set_config('app.test_orgb_membership_id', id::text, true) from ins;

-- Ground truth, captured while still privileged: the real email/phone for
-- the manage-holder and their fellow org-A member. Assertions 1 and 2
-- compare the view's output against this snapshot rather than against a
-- live re-read of the base table under the simulated identity -- by the
-- time those assertions run, that live re-read is exactly what assertion
-- 6 is checking still works unmasked (grants are unchanged in this step),
-- not a substitute ground truth.
create temp table _verify_expected_users on commit drop as
select id, email, phone
from public.users
where id in (
  current_setting('app.test_user_manage')::uuid,
  current_setting('app.test_user_fellow')::uuid,
  current_setting('app.test_user_platform')::uuid
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
  v_org_a uuid := current_setting('app.test_org_a')::uuid;
  v_org_b uuid := current_setting('app.test_org_b')::uuid;
  v_user_manage uuid := current_setting('app.test_user_manage')::uuid;
  v_user_fellow uuid := current_setting('app.test_user_fellow')::uuid;
  v_user_platform uuid := current_setting('app.test_user_platform')::uuid;
  v_user_orgb_only uuid := current_setting('app.test_user_orgb_only')::uuid;
  v_expected_email text;
  v_expected_phone text;
  v_got_email text;
  v_got_phone text;
  v_can_select boolean;
begin
  -- ---- 1. Caller sees their own email and phone through the view ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_manage::text, 'role', 'authenticated')::text, true);

  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_manage;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_manage;

  if v_got_email is not distinct from v_expected_email and v_got_phone is not distinct from v_expected_phone then
    report := report || E'\n1. PASS - caller sees their own real email/phone through the view';
  else
    report := report || format(E'\n1. FAIL - expected email=%s phone=%s, got email=%s phone=%s', v_expected_email, v_expected_phone, v_got_email, v_got_phone);
  end if;

  -- ---- 2. org.members.manage holder sees a fellow org member's email/phone ----
  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_fellow;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_fellow;

  if v_got_email is not distinct from v_expected_email and v_got_phone is not distinct from v_expected_phone then
    report := report || E'\n2. PASS - org.members.manage holder sees a fellow org member''s real email/phone';
  else
    report := report || format(E'\n2. FAIL - expected email=%s phone=%s, got email=%s phone=%s', v_expected_email, v_expected_phone, v_got_email, v_got_phone);
  end if;

  -- ---- 3. Caller without org.members.manage sees NULL for another member ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_fellow::text, 'role', 'authenticated')::text, true);

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_manage;

  if v_got_email is null and v_got_phone is null then
    report := report || E'\n3. PASS - non-manage caller sees null for another member''s email/phone';
  else
    report := report || format(E'\n3. FAIL - expected null/null, got email=%s phone=%s', v_got_email, v_got_phone);
  end if;

  -- ---- 4. org.members.manage in org A sees NULL for a user only in org B ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_manage::text, 'role', 'authenticated')::text, true);

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_orgb_only;

  if v_got_email is null and v_got_phone is null then
    report := report || E'\n4. PASS - org A manage-holder sees null for a user who is only in org B';
  else
    report := report || format(E'\n4. FAIL - expected null/null, got email=%s phone=%s', v_got_email, v_got_phone);
  end if;

  -- ---- 5. Platform owner: report actual behavior, do not assume ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_platform::text, 'role', 'authenticated')::text, true);

  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_platform;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_platform;

  if v_got_email is not distinct from v_expected_email and v_got_phone is not distinct from v_expected_phone then
    report := report || E'\n5a. PASS - platform owner sees their own real email/phone (unconditional branch, same as anyone)';
  else
    report := report || format(E'\n5a. FAIL - platform owner''s own row: expected email=%s phone=%s, got email=%s phone=%s', v_expected_email, v_expected_phone, v_got_email, v_got_phone);
  end if;

  select email, phone into v_got_email, v_got_phone
  from public.users_masked where id = v_user_fellow;

  if v_got_email is null and v_got_phone is null then
    report := report || E'\n5b. CONFIRMED (not assumed) - platform owner sees null for another user''s email/phone through this predicate: has_capability()''s own is_platform_owner() bypass never gets evaluated, because platform owner holds zero user_org_roles rows (DATABASE_CONVENTIONS.md #3) and the EXISTS join''s "mine" side matches nothing for them. This is the actual, verified behavior -- not a bug introduced here, and not silently patched with an extra is_platform_owner() branch that was not in the specified predicate.';
  else
    report := report || format(E'\n5b. UNEXPECTED - platform owner saw a value for another user''s email/phone (email=%s phone=%s) -- contradicts the confirmed data shape (platform owner has 0 user_org_roles rows); re-check', v_got_email, v_got_phone);
  end if;

  -- ---- 6. Existing base-table reads still work (grants untouched this step) ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_user_manage::text, 'role', 'authenticated')::text, true);

  select has_column_privilege('authenticated', 'public.users', 'email', 'SELECT') into v_can_select;

  select email, phone into v_expected_email, v_expected_phone
  from _verify_expected_users where id = v_user_manage;

  begin
    select email, phone into v_got_email, v_got_phone
    from public.users where id = v_user_manage;

    if v_can_select and v_got_email is not distinct from v_expected_email then
      report := report || E'\n6. PASS - direct base-table select of email/phone still succeeds (grants untouched this step)';
    else
      report := report || format(E'\n6. FAIL - base-table select returned email=%s (can_select=%s)', v_got_email, v_can_select);
    end if;
  exception
    when insufficient_privilege then
      report := report || E'\n6. FAIL - direct base-table select unexpectedly raised insufficient_privilege (grants should be untouched in this step)';
  end;

  raise exception E'VERIFICATION REPORT for 202608200005_users_masked_view.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
