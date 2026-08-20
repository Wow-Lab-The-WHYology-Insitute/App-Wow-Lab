-- 202608200004_backfill_full_name_after_email_default_removed.sql
-- Cleans up the 10 pre-existing rows where full_name still equals the raw
-- email (the handle_new_auth_user default removed at the source in
-- 202608200003). Two different resolutions, not one blanket rule:
--
-- 1. anca.tanasescu@gmail.com, anka@asismart.ro: first_name/last_name are
--    already correctly set on both rows -- full_name was simply never
--    propagated from them. No ambiguity, no NULL needed: derived directly
--    from the columns that already have the answer, not a hardcoded
--    string, so there's no transcription/spelling risk.
--
-- 2. Every maxdigitalro+<role>@gmail.com alias, plus test+cascade-check:
--    set to NULL. A role suffix (+community, +finops, ...) is a label,
--    not a derivable name -- the even application of "NULL unless
--    genuinely derivable", not a pseudonym invented to fill the field.
--    displayName() (groups/page.tsx, admin-users-client.tsx) resolves
--    NULL/"" to the unnamed_user placeholder; this does not touch
--    first_name/last_name, which are already null on all 7 of these rows.
--
-- maxdigitalro@gmail.com is deliberately NOT included -- Mihai's own
-- account, real identity to be set through /profile, not backfilled here.
--
-- Step 0's four already-backfilled trainer accounts (202608200002) are
-- also not touched -- not rewriting already-committed history over a rule
-- that postdates it.
--
-- Idempotent: plain UPDATE keyed on email, same inputs always produce the
-- same result -- matches the established backfill style (202608110003,
-- 202608200002).

update public.users
set full_name = first_name || ' ' || last_name
where email in ('anca.tanasescu@gmail.com', 'anka@asismart.ro')
  and first_name is not null
  and last_name is not null;

update public.users
set full_name = null
where email in (
  'maxdigitalro+community@gmail.com',
  'maxdigitalro+finadmin@gmail.com',
  'maxdigitalro+finops@gmail.com',
  'maxdigitalro+inventory@gmail.com',
  'maxdigitalro+master@gmail.com',
  'maxdigitalro+ops@gmail.com',
  'test+cascade-check@wowlab.dev'
);
