-- 202609110004_require_mywork_capability_on_sessions_trainer_branch_rollback.sql
-- Rolls back 202609110004: restores the sessions UPDATE policy to
-- 202609110003's own form -- the trainer branch reverts to a bare row
-- match, mywork.* check removed.
--
-- Restoring this reopens the gap 202609110004 closed: a user whose role
-- (and mywork.*) has been revoked, but whose id still sits in
-- trainer_principal_id/trainer_secundar_id on an existing session row,
-- would regain the ability to write attendance_count/experiment_delivered
-- on that row through this branch alone. Do not run this without a
-- specific reason to prefer the row-match-only form.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

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
      or (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
      or (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
    );
end;
$$;
