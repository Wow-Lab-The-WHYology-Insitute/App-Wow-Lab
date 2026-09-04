-- 202609040001_fix_test_platform_is_test_account_flag.sql
-- WOW LAB OS: data correction, flagged this session (OPEN_ITEMS.md item 27,
-- 2026-08-26), now fixed on Mihai's explicit instruction.
--
-- test+platform@wowlab.dev is the sole is_platform_owner = true account and
-- is plainly a fixture by every naming convention this project uses
-- (test+ prefix, wowlab.dev domain — same pattern as test+catalina@wowlab.dev,
-- test+user-b@wowlab.dev, and every other row the original backfill
-- (202608120006) marked true). It was simply missing from that migration's
-- static list, not a deliberate distinction — item 27 already called this a
-- data-entry gap, not a real one.
--
-- is_test_account is purely a display label (202608120006's own column
-- comment) — does not affect RLS, sorting, or filtering. This fix changes
-- nothing about what this account can do, only how it's badged in
-- /admin/users' Members list.
--
-- Idempotent: matches on the known-wrong current state, so a second run
-- finds zero matching rows and no-ops.

update public.users
set is_test_account = true
where email = 'test+platform@wowlab.dev'
  and is_test_account = false;
