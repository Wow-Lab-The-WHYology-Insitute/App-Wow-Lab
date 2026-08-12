-- 202608120002_org_scope_avatar_read_policy.sql
-- WOW LAB OS: fixes a cross-org isolation gap in the avatars Storage read
-- policy (202608120001) before merging that feature to main. Mihai's call:
-- fix now, not deferred to Phase 2.
--
-- Gap: "avatars authenticated read" granted SELECT to any `authenticated`
-- role on the whole bucket, with no organization check at all — a user in
-- a completely different org (e.g. wow-lab-test-b) could read/sign a
-- wow-lab member's avatar. Every other cross-org boundary in this app (WS-D,
-- Clients & Contracts) is enforced; this one wasn't.
--
-- Fix mirrors the EXACT existing idiom already used for "can I read this
-- OTHER user's row" (see the "authenticated select users" policy,
-- 202607100002): resolve the TARGET's organization(s) via user_org_roles,
-- then check the CALLER against each of those orgs. That policy uses
-- app.has_capability('org.members.read', ...) because reading someone
-- else's full user row is capability-gated; this one uses
-- app.belongs_to_org(...) instead, because avatar read has no capability
-- gate -- any org-mate can see it, which is exactly what belongs_to_org
-- checks (platform_owner bypass already included inside that function, so
-- it doesn't need to be repeated here).
--
-- The avatar owner's id comes from the object path itself
-- ((storage.foldername(name))[1] -- '<user_id>/avatar', same convention
-- the owner-only write policies already rely on), cast to uuid.
--
-- Write policies (INSERT/UPDATE/DELETE, folder-ownership via auth.uid())
-- are untouched -- they were already correct, not part of this gap.

drop policy if exists "avatars authenticated read" on storage.objects;
create policy "avatars authenticated read" on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and exists (
      select 1
      from public.user_org_roles owner_membership
      where owner_membership.user_id = ((storage.foldername(name))[1])::uuid
        and app.belongs_to_org(owner_membership.organization_id)
    )
  );
