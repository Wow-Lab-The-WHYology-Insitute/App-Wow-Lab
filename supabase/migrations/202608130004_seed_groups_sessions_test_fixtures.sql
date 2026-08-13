-- 202608130004_seed_groups_sessions_test_fixtures.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — test
-- fixture user.
--
-- Same rationale as 202608100005: TEST-ONLY fixture data (mirrors
-- supabase/seed.sql part 9-10's test+role@wowlab.dev pattern exactly),
-- delivered as a migration so it reaches the already-provisioned remote
-- via `db push`. supabase/seed.sql carries the same row for future
-- `db reset` runs.
--
-- Only one trainer fixture (test+trainer-a@wowlab.dev) existed before this
-- -- needed a SECOND trainer for db/tests/rls_groups_sessions.sql's
-- "Trainer A cannot see Trainer B's sessions" assertion.
--
-- Idempotent: identical on-conflict pattern as 202608100005.

insert into public.users (id, email, full_name, status, is_platform_owner)
values
  (gen_random_uuid(), 'test+trainer-b@wowlab.dev', 'Test Trainer B', 'active', false)
on conflict (email) do update
  set full_name = excluded.full_name,
      status = excluded.status,
      is_platform_owner = excluded.is_platform_owner,
      updated_at = now();

insert into public.user_org_roles (organization_id, user_id, role_id)
select o.id, u.id, r.id
from (
  values
    ('test+trainer-b@wowlab.dev', 'wow-lab', 'trainer')
) as m(user_email, org_slug, role_key)
join public.users u on u.email = m.user_email
join public.organizations o on o.slug = m.org_slug
join public.roles r on r.key = m.role_key
on conflict (organization_id, user_id, role_id) do nothing;
