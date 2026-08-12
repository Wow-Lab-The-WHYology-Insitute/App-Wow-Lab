-- 202608120003_fix_avatar_read_policy_via_shares_org_helper.sql
-- WOW LAB OS: fixes a real bug in 202608120002's org-scoped avatar read
-- policy, found via live testing (not assumed) immediately after applying
-- it: the within-org POSITIVE case broke too — a wow-lab member couldn't
-- read another wow-lab member's avatar either, not just cross-org readers.
--
-- Root cause: 202608120002's policy inlined a raw correlated subquery
-- directly against public.user_org_roles inside the USING clause:
--   exists (select 1 from public.user_org_roles owner_membership
--           where owner_membership.user_id = <owner> and app.belongs_to_org(...))
-- That subquery runs AS THE CALLING ROLE (not security definer), so it is
-- itself subject to user_org_roles' OWN "authenticated select
-- user_org_roles" RLS policy (202607100002) -- which only lets a caller
-- see (a) their own row, (b) rows in orgs where they hold
-- org.members.read, or (c) everything if platform_owner. A caller with
-- neither org.members.read nor platform_owner (e.g. operations_manager)
-- can't see the OWNER's user_org_roles row at all, so the subquery found
-- zero rows and denied everyone except platform_owner -- confirmed live via
-- SQL impersonation (app.belongs_to_org() with a literal org id returned
-- true, but the exact same call wrapped in the correlated subquery
-- returned false, and a direct `select 1 from user_org_roles where
-- user_id = <other user>` under that impersonation returned zero rows).
--
-- The existing "authenticated select users" policy (202607100002) has the
-- same subquery SHAPE but doesn't hit this bug for its own purpose,
-- because it's deliberately capability-gated (org.members.read) -- for
-- THAT policy, "only org.members.read holders can resolve this" is the
-- intended restriction, not a bug. Avatars need the opposite: ANY org-mate
-- can read, unconditionally on capability -- so reusing that subquery
-- shape verbatim silently imported an unwanted extra restriction.
--
-- Fix: every other cross-user/cross-org check in this codebase
-- (app.has_capability, app.belongs_to_org, app.is_platform_owner) is a
-- SECURITY DEFINER function specifically so it can read user_org_roles/
-- users while bypassing their deny-by-default RLS -- that's the actual
-- established mechanism, not a raw inline subquery. This adds one more
-- helper in that same family, app.shares_org_with(other_user_id), and the
-- avatar read policy calls it instead of inlining the subquery itself.

create or replace function app.shares_org_with(other_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    app.is_platform_owner()
    or exists (
      select 1
      from public.user_org_roles mine
      join public.user_org_roles theirs
        on theirs.organization_id = mine.organization_id
      where mine.user_id = app.current_user_id()
        and theirs.user_id = other_user_id
    );
$$;

comment on function app.shares_org_with(uuid) is 'True if the current user and `other_user_id` share membership in at least one common organization, or the current user is platform owner. SECURITY DEFINER to bypass deny-by-default RLS on user_org_roles -- needed because, unlike app.belongs_to_org(org), the caller does not already know which org to check.';

revoke all on function app.shares_org_with(uuid) from public;
grant execute on function app.shares_org_with(uuid) to authenticated, service_role;

drop policy if exists "avatars authenticated read" on storage.objects;
create policy "avatars authenticated read" on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and app.shares_org_with(((storage.foldername(name))[1])::uuid)
  );
