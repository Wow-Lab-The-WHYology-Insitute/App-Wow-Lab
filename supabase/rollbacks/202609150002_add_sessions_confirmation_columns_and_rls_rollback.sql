-- Rollback for 202609150002_add_sessions_confirmation_columns_and_rls.sql
-- Restores the sessions UPDATE policy to exactly 202609110004's shape.

DO $$
begin
  drop policy if exists "authenticated update sessions" on public.sessions;
  create policy "authenticated update sessions" on public.sessions
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
      or (
        app.has_capability('mywork.*', organization_id)
        and (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
      )
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
      or (
        app.has_capability('mywork.*', organization_id)
        and (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
      )
    );
end;
$$;

alter table public.sessions
  drop column if exists trainer_principal_confirmed_at,
  drop column if exists trainer_secundar_confirmed_at;
