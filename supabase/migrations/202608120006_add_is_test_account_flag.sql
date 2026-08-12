-- 202608120006_add_is_test_account_flag.sql
-- WOW LAB OS: Mihai's decision — distinguish test accounts visually in
-- /admin/users' Members list, don't hide them (still needed for ongoing
-- Phase 1 verification work). An explicit boolean column rather than
-- pattern-matching on email (e.g. `email like 'test+%'`) at read time —
-- a stored flag can't misclassify a real address that happens to contain
-- "test", and doesn't require every future query to remember the pattern.
--
-- not null default false, matching the existing users.is_platform_owner
-- column's exact style (202607080002) rather than introducing a nullable
-- tri-state for what's really a plain boolean.
--
-- Backfill: the 13 currently-active test fixtures in the real wow-lab
-- org, confirmed live via user_org_roles (not re-derived from memory) —
-- 7 older C1 SQL-only fixtures (no auth.users row, impersonation-only)
-- plus 6 test+ui-* fixtures (real auth.users rows, used for this
-- session's live UI/Playwright verification work). This is 13, not the
-- 14 initially estimated -- the 2 previously-orphaned invite-test rows
-- (test+invite-with/without-073557) already accounted for that gap and
-- were removed in this same migration set (202608120004/5), not backfilled
-- here. test+ui-org-b@wowlab.dev is NOT included -- it lives in the
-- separate wow-lab-test-b org, not wow-lab, so it never appears in this
-- Members list at all.

alter table public.users
  add column if not exists is_test_account boolean not null default false;

comment on column public.users.is_test_account is 'Marks WS-D/C1/C2 test fixtures for visual distinction in the /admin/users Members list (a "Test" badge) -- purely a display label, does not affect RLS, sorting, or filtering. An explicit stored flag rather than pattern-matching on email at read time, so a real address can never be misclassified later.';

update public.users
set is_test_account = true
where email in (
  'test+catalina@wowlab.dev',
  'test+contract-admin-a@wowlab.dev',
  'test+finance-admin-a@wowlab.dev',
  'test+finance-ops-a@wowlab.dev',
  'test+owner-a@wowlab.dev',
  'test+sales-a@wowlab.dev',
  'test+trainer-a@wowlab.dev',
  'test+ui-contract-admin@wowlab.dev',
  'test+ui-finance-ops@wowlab.dev',
  'test+ui-ops@wowlab.dev',
  'test+ui-owner@wowlab.dev',
  'test+ui-sales@wowlab.dev',
  'test+ui-trainer@wowlab.dev'
);
