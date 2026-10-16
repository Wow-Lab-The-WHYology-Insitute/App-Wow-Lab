-- Revokes the payroll-capable roles from the two test accounts that can
-- actually sign in: test+ui-owner@wowlab.dev (Organization Owner) and
-- test+ui-finance-ops@wowlab.dev (Finance Operations), both in the real
-- wow-lab org.
--
-- WHY THESE TWO AND NOT THE OTHER FOUR. /payroll is gated on
-- finance.operations.* or org.settings.manage, and since 202610150003 it
-- shows every trainer's pay. Six accounts flagged is_test_account held one
-- of those capabilities in the PRODUCTION org. The distinction that
-- matters is not the flag -- it is `auth.users`:
--
--   * test+finance-ops-a@wowlab.dev and test+owner-a@wowlab.dev have NO
--     auth.users row (convention 11: seed.sql fixtures exist in
--     public.users only and cannot authenticate). They cannot open a
--     browser session at all, so they are not an exposure -- and they are
--     load-bearing: between them they are impersonated by four db/tests/
--     files, so revoking their roles would fail run_rls_suite.ts.
--   * maxdigitalro+finops@ and maxdigitalro+master@ are Mihai's own, kept
--     deliberately: he needs them to view the screens as each role.
--   * these two can sign in AND were nearly free to change -- between them
--     they are referenced by six one-off scripts/verify_*.sql and by ZERO
--     db/tests/ files.
--
-- So the two that can reach a real session are the two that cost nothing
-- to revoke, and the two that are load-bearing cannot reach a session.
-- is_test_account is no help here by its own definition ("purely a display
-- label, does not affect RLS, sorting, or filtering") -- and item 18
-- already recorded the trap from the other side: is_test_account = false
-- does not mean "a real person" either.
--
-- HOW, and it mirrors the app rather than inventing a shape. Both accounts
-- hold exactly one role row each, so deleting it would leave them with
-- zero user_org_roles rows and they would vanish from /admin/users'
-- Members list entirely. app/(app)/admin/users/actions.ts already refuses
-- to do that: when every role is unchecked it re-inserts a single row with
-- role_id = null, which is how "member, no role assigned" is represented
-- (202609040003/202609040004, and the partial unique index
-- user_org_roles_one_membership_per_org_user enforces one such row).
-- Same thing here, so the two accounts stay visible and role-less rather
-- than disappearing.
--
-- They keep their auth.users row and can still sign in -- they will land on
-- /profile and be refused by /payroll's own gate, which is the point. The
-- six scripts/verify_*.sql that impersonated them are re-pointed in this
-- same commit at test+owner-a / test+finance-ops-a, whose role sets are
-- IDENTICAL (verified: one role each, the same one) -- and which are the
-- right accounts for SQL impersonation anyway, since that is what
-- convention 11 says they exist for, while the test+ui-* accounts exist
-- for browser verification.
--
-- user_org_roles carries the row_history trigger, so both deletions are
-- captured there.

do $$
declare
  v_org uuid;
  v_user uuid;
  v_email text;
  v_emails text[] := array['test+ui-owner@wowlab.dev', 'test+ui-finance-ops@wowlab.dev'];
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'revoke_payroll_roles: no organization with slug wow-lab';
  end if;

  foreach v_email in array v_emails loop
    select id into v_user from public.users where email = v_email;
    if v_user is null then
      raise exception 'revoke_payroll_roles: no user %', v_email;
    end if;

    delete from public.user_org_roles
    where organization_id = v_org
      and user_id = v_user
      and role_id is not null;

    -- Only when nothing else is left, and only if there is no role-less
    -- row already -- the partial unique index allows exactly one.
    if not exists (
      select 1 from public.user_org_roles
      where organization_id = v_org and user_id = v_user
    ) then
      insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
      values (v_org, v_user, null, null);
    end if;
  end loop;
end $$;
