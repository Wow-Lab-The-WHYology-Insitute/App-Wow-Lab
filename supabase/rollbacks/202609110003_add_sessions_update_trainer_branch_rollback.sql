-- 202609110003_add_sessions_update_trainer_branch_rollback.sql
-- Rolls back 202609110003: restores the sessions UPDATE policy to its
-- pre-2026-09-11 form, byte-identical to 202608130003's own predicate --
-- Operations Manager (+Master) only, the trainer row-match branch
-- removed.
--
-- Restoring this reinstates the exact block that kept a trainer from
-- ever writing attendance_count/experiment_delivered on their own
-- session -- do not run this without confirming Anca's decision has
-- actually changed, not just that a rollback is convenient.
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
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
    );
end;
$$;
