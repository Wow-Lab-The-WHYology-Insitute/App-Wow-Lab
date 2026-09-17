-- Rollback for 202609160002_fix_finance_ops_trainer_visibility_uor_rls.sql
-- Restores the "authenticated select users" policy to exactly
-- 202609160001's shape (including its broken finance.operations.*
-- branch) and drops the helper function this migration added.

DO $$
begin
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
      or exists (
        select 1
        from public.user_org_roles target_uor
        join public.roles target_role on target_role.id = target_uor.role_id
        where target_uor.user_id = users.id
          and target_role.key in ('trainer', 'senior_trainer')
          and app.has_capability('finance.operations.*', target_uor.organization_id)
      )
      or exists (
        select 1
        from public.sessions s
        where (s.trainer_principal_id = users.id or s.trainer_secundar_id = users.id)
          and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
          and app.has_capability('mywork.*', s.organization_id)
      )
    );

  drop function if exists app.viewer_sees_trainer_via_finance_ops(uuid);
end;
$$;
