-- 202608210001_users_field_masking_grants.sql
-- Users field masking, step 3 of 3 (docs/WOWLAB_SAD_Field_Masking.md §2.3):
-- flip the base-table grants so authenticated can no longer read
-- public.users.email/phone directly at all -- public.users_masked
-- (202608200005) becomes the only path to those two columns. Both call
-- sites that used to read them off the base table (/profile,
-- /admin/users) were already migrated onto users_masked in step 2
-- (fb0dcd3) specifically so this step would be safe to do alone.
--
-- Column list verified live against information_schema immediately before
-- writing this migration -- 12 columns total on public.users today; the
-- 10 below are everything except email and phone. Not copied from the
-- SAD's own column list without checking: that list is descriptive text,
-- not source of truth (SAD §2.1's own note, added after the contracts
-- list went stale by two renamed columns). Confirmed identical to what's
-- specified this time -- no drift to report.
--
-- Traps 5.6/5.7 (temporary role membership for ALTER FUNCTION ... OWNER
-- TO, and holding that membership through every subsequent GRANT/REVOKE
-- on the function) do NOT apply here -- confirmed, not assumed: this
-- migration transfers no function ownership and creates no new function.
-- It only changes SELECT grants on a table that already has its owner
-- (postgres, confirmed live). There is no owner-role dance to get wrong.
--
-- UPDATE privilege on public.users for authenticated is untouched by this
-- migration -- confirmed live beforehand that it's already granted
-- table-wide (not column-scoped), so first_name/last_name/phone/
-- avatar_url/status remain writable by authenticated exactly as before.
-- This migration only ever says SELECT.
--
-- service_role and postgres (the invite trigger's owner, confirmed live
-- via pg_proc: handle_new_auth_user is SECURITY DEFINER owned by
-- postgres, which also owns public.users itself) are untouched by
-- construction -- this REVOKE/GRANT pair names authenticated only.

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
