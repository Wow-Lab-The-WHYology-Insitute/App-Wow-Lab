-- Rollback for 202609170001_add_clients_mywork_visibility_branch.sql
-- Restores "authenticated select clients" to exactly its 202608100003
-- shape (no mywork.* branch).

DO $$
begin
  drop policy if exists "authenticated select clients" on public.clients;
  create policy "authenticated select clients" on public.clients
    for select
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('clients.read', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
      )
      or (
        app.has_capability('finance.operations.*', organization_id)
        and client_type in ('private_school', 'parent_b2c')
      )
      or (
        app.has_capability('finance.reporting.*', organization_id)
        and client_type not in ('private_school', 'parent_b2c')
      )
    );
end;
$$;
