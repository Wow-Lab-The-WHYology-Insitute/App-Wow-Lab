-- 202609160002_fix_finance_ops_trainer_visibility_uor_rls.sql
-- Fixes a bug in 202609160001's finance.operations.* branch, caught by
-- live verification (scripts/verify_users_trainer_name_visibility.sql)
-- before this was reported as done: the branch read public.user_org_roles
-- directly --
--   exists (select 1 from public.user_org_roles target_uor join ...
--     where target_uor.user_id = users.id and ... and
--     app.has_capability('finance.operations.*', target_uor.organization_id))
-- -- but that FROM clause is itself subject to user_org_roles' own SELECT
-- policy: is_platform_owner() OR user_id = current_user_id() OR
-- has_capability('org.members.read', organization_id). A finance_operations
-- viewer holds finance.operations.*, not org.members.read, so the inner
-- read of the TARGET's own user_org_roles row returned zero rows before
-- has_capability('finance.operations.*', ...) was ever consulted -- the
-- branch was structurally dead for the one role it was written for.
-- Confirmed live: app.has_capability('finance.operations.*', <org>) alone
-- returned true for the finance fixture; the same check embedded in the
-- raw subquery returned false.
--
-- The original 202607100002 org.members.read branch has this same shape
-- but never hit the bug, because it's self-referential: entering that
-- branch already requires the viewer to hold org.members.read in the
-- org, which is the exact same capability that then makes the inner
-- user_org_roles row visible under that table's own RLS. finance.operations.*
-- and org.members.read are different capabilities, so no such
-- coincidence bails this branch out.
--
-- Fix: move the user_org_roles/roles read inside a SECURITY DEFINER
-- helper, the same way app.has_capability() itself already bypasses RLS
-- to do its own user_org_roles lookup. The helper takes the TARGET user
-- id (not the viewer) and returns whether that target holds trainer or
-- senior_trainer in an org where the CURRENT viewer (via
-- app.has_capability, unaffected by security definer -- it still reads
-- auth.uid()/the calling session's own capabilities, not the target's)
-- holds finance.operations.*. No broader grant than 202609160001 intended
-- -- same two cases, just no longer silently false for the one it names.
--
-- (The mywork.* branch does not have this bug: it reads public.sessions,
-- and the exact row it filters for -- viewer is principal or secundar,
-- and viewer holds mywork.* in that org -- is precisely sessions' own
-- RLS's mywork.* branch, so the viewer already has row-level access to
-- read it. Confirmed live: that branch's two checks (co-trainer visible,
-- unrelated trainer not visible) both passed already.)
DO $$
begin
  create or replace function app.viewer_sees_trainer_via_finance_ops(target_user_id uuid)
  returns boolean
  language sql
  stable
  security definer
  set search_path to ''
  as $inner$
    select exists (
      select 1
      from public.user_org_roles target_uor
      join public.roles target_role on target_role.id = target_uor.role_id
      where target_uor.user_id = target_user_id
        and target_role.key in ('trainer', 'senior_trainer')
        and app.has_capability('finance.operations.*', target_uor.organization_id)
    );
  $inner$;

  drop policy if exists "authenticated select users" on public.users;
  create policy "authenticated select users" on public.users
    for select
    to authenticated
    using (
      app.is_platform_owner()
      or id = app.current_user_id()
      or exists (
        select 1
        from public.user_org_roles uor
        where uor.user_id = users.id
          and app.has_capability('org.members.read', uor.organization_id)
      )
      or app.viewer_sees_trainer_via_finance_ops(users.id)
      or exists (
        select 1
        from public.sessions s
        where (s.trainer_principal_id = users.id or s.trainer_secundar_id = users.id)
          and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
          and app.has_capability('mywork.*', s.organization_id)
      )
    );
end;
$$;
