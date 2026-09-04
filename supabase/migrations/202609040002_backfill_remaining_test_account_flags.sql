-- 202609040002_backfill_remaining_test_account_flags.sql
-- WOW LAB OS: is_test_account backfill, round 2 — 17 accounts the original
-- backfill (202608120006) missed, found by a full-table audit this session,
-- not by pattern-matching. Explicit id list, not a `LIKE 'test+%'`/
-- `LIKE 'maxdigitalro+%'` predicate: a pattern that's accurate today would
-- silently catch a real person who happens to match it later (e.g. a real
-- team member using a `name+something@gmail.com` alias) — the flag records
-- a one-time decision about specific rows, not a rule to keep re-evaluating.
--
-- Why these 17 were missed, grouped by reason:
--
-- (a) Predates 202608120006 but outside its scope. That migration's own
--     comment explicitly excludes wow-lab-test-b members ("test+ui-org-b@
--     wowlab.dev is NOT included -- it lives in the separate wow-lab-test-b
--     org... never appears in this Members list") because the flag's only
--     consumer at the time was the wow-lab Members list's "Test" badge.
--     That exclusion doesn't hold up: is_test_account is a column on
--     public.users, not scoped to an organization or to any particular
--     UI screen — a fixture sitting in the test org is still a fixture,
--     and the column doesn't know which org's Members list is asking.
--       - test+user-b@wowlab.dev (2026-07-09, wow-lab-test-b's owner)
--       - test+ui-org-b@wowlab.dev (2026-08-12, same org, same reason)
--
-- (b) Predates 202608120006, same class of thing as the test+ui-*@wowlab.dev
--     rows that migration DID mark true (per-role capability/UI verification
--     aliases), just a different domain because these needed a real inbox
--     for magic-link click-through rather than SQL-only impersonation.
--     Simply absent from that migration's static list.
--       - maxdigitalro+master@gmail.com
--       - maxdigitalro+ops@gmail.com
--       - maxdigitalro+finops@gmail.com
--       - maxdigitalro+finadmin@gmail.com
--       - maxdigitalro+community@gmail.com
--       - maxdigitalro+inventory@gmail.com
--       - maxdigitalro+trainer@gmail.com
--
-- (c) Created the same day as 202608120006 or shortly after; never
--     backfilled since because no second pass ever ran.
--       - test+cascade-check@wowlab.dev (2026-08-12)
--       - test+trainer-b@wowlab.dev (2026-08-13)
--
-- (d) Created 2026-09-02 (scripts/seed_test_org_b_trainers.ts), three weeks
--     after 202608120006 — the account-creation drift this backfill does
--     NOT fix at the source (see the follow-up report).
--       - maxdigitalro+trainerb1@gmail.com through +trainerb6@gmail.com
--
-- Explicitly NOT touched: the eight real accounts created 2026-09-03
-- (catalina_moale@yahoo.com and the other seven) — real people, correctly
-- false already, asserted as still false below.

update public.users
set is_test_account = true
where id in (
  'eee47818-3105-4e73-95d9-638f8b5c4781', -- test+user-b@wowlab.dev
  '12754013-fbe2-4643-8ec4-3357de69d2af', -- maxdigitalro+master@gmail.com
  'b88ea8aa-b8af-4d09-86ea-efa6c035bf5e', -- maxdigitalro+ops@gmail.com
  '28e99549-0a50-43e5-9feb-881e2f7d7b1b', -- maxdigitalro+finops@gmail.com
  'dfbf1092-5cb9-444c-913c-328dd21ee456', -- maxdigitalro+finadmin@gmail.com
  '5ffb6cf5-2742-494b-89cd-e4eb8bf13a14', -- maxdigitalro+community@gmail.com
  'fa6e8566-aea6-4048-80e3-22a705a03899', -- maxdigitalro+inventory@gmail.com
  '186e33ce-762c-45c5-8d8e-de3f59337cc4', -- maxdigitalro+trainer@gmail.com
  'ea63166e-14d6-4179-891d-132de3595c76', -- test+ui-org-b@wowlab.dev
  'a1cc089a-3a02-4e01-86f8-ea8b49ce711d', -- test+cascade-check@wowlab.dev
  '901d6d66-a365-4744-8c23-b2dd37e0e0cf', -- test+trainer-b@wowlab.dev
  'fab9f77c-ac27-43f2-ac8f-a0c03f668880', -- maxdigitalro+trainerb1@gmail.com
  '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', -- maxdigitalro+trainerb2@gmail.com
  'f30321ee-66bd-45bb-afe9-1592313101b0', -- maxdigitalro+trainerb3@gmail.com
  'e67e78a8-6ced-4123-b937-bd4ec4c2d28e', -- maxdigitalro+trainerb4@gmail.com
  '88c2d66b-64f3-4881-b2f2-a85ac3a060e5', -- maxdigitalro+trainerb5@gmail.com
  'b7bb9753-0523-4c44-ac31-c3acba3f6259'  -- maxdigitalro+trainerb6@gmail.com
)
and is_test_account = false;
