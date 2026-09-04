-- 202609040004_add_raluca_margean_membership_no_role.sql
-- WOW LAB OS: gives Raluca Margean (ralucamargean@yahoo.com) a real
-- user_org_roles row in wow-lab with role_id null, exactly the state
-- 202609040003 just made representable.
--
-- She has existed since 2026-09-03 (scripts/create_eight_real_wow_lab_
-- accounts.ts) with zero user_org_roles rows anywhere, deliberately --
-- evidence contradicted the original "trainer" proposal and no confirmed
-- alternative role existed (OPEN_ITEMS.md item 22). That left her not
-- just role-less but org-less: nothing in the schema recorded her as
-- belonging to wow-lab at all, so /admin/users' Members list (anchored
-- on user_org_roles) never had a row to show her by, independent of
-- whatever the list query itself did.
--
-- This migration does NOT assign her a role -- role_id is null,
-- deliberately, same as item 22 already recorded. It only records that
-- she is a member of wow-lab pending that decision, which is what
-- app.belongs_to_org() already means by "member" (202607090001) and
-- what the Members list query now keys on (page.tsx, same commit).
--
-- assigned_by: maxdigitalro@gmail.com (def47f4b-4452-49c5-bcea-
-- a35b06dddfa3), the real organization_owner account used for every
-- other script-driven write this session -- there is no real admin UI
-- session performing this one write, same as the original account
-- creation.
--
-- Idempotent: the partial unique index from 202609040003 means a second
-- run hits unique_violation, not a silent duplicate; ON CONFLICT DO
-- NOTHING against that index makes re-running this file a no-op instead
-- of an error.

insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
select
  (select id from public.organizations where slug = 'wow-lab'),
  (select id from public.users where email = 'ralucamargean@yahoo.com'),
  null,
  'def47f4b-4452-49c5-bcea-a35b06dddfa3'
on conflict (organization_id, user_id) where role_id is null do nothing;
