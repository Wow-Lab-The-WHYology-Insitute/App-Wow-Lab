-- Rollback for 202609160001_add_users_trainer_name_visibility_branches.sql
-- Restores the "authenticated select users" policy to exactly
-- 202607100002's shape.

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
    );
end;
$$;
