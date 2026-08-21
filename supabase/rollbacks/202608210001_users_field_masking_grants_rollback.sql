-- 202608210001_users_field_masking_grants_rollback.sql
-- Rolls back 202608210001: restores authenticated's original table-wide
-- SELECT on public.users (email/phone directly readable again, same as
-- before step 3). Does not touch public.users_masked, its function, or
-- app_masking_owner -- those are step 1's objects (202608200005) and are
-- unaffected by this migration in either direction.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD §6.2) --
-- `supabase db push` applies every file in migrations/ wholesale; to
-- actually roll back, copy this file into migrations/ with a fresh
-- timestamp, push, then move it back here.

revoke select (
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
) on public.users from authenticated;

grant select on public.users to authenticated;
