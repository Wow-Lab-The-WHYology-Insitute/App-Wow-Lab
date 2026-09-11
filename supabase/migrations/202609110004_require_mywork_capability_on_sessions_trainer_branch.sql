-- 202609110004_require_mywork_capability_on_sessions_trainer_branch.sql
-- WOW LAB OS: correction to 202609110003 -- the trainer branch it added to
-- the sessions UPDATE policy was a row match alone (trainer_principal_id =
-- auth.uid() OR trainer_secundar_id = auth.uid()), with no capability
-- check. That migration's own comment reasoned this was deliberate: no
-- capability narrower than mywork.* exists for "may this person touch
-- this specific session," and creating one (e.g. sessions.write_own) is
-- too much ceremony for a two-column edit. Both true -- but the
-- conclusion drawn from them was wrong. The choice was never "a narrow
-- new capability, or nothing" -- mywork.* already exists, is already
-- held by trainer/senior_trainer, and is already paired with this exact
-- row match on the SELECT policy for this same table
-- (202608130003): "app.has_capability('mywork.*', organization_id) AND
-- (trainer_principal_id = app.current_user_id() OR trainer_secundar_id =
-- app.current_user_id())". The UPDATE branch dropped the capability half
-- of that pair for no stated reason connected to the "no narrow
-- capability exists" argument -- that argument is about a *different,
-- narrower* capability, not about mywork.* itself.
--
-- What this bought in practice was near nothing (only trainer/
-- senior_trainer ever hold mywork.*, and only they are ever placed in
-- trainer_principal_id/trainer_secundar_id today) and what it cost was
-- real: a session row's trainer columns are the only thing this branch
-- checks. A user who no longer holds any role in the org -- role
-- reassigned, access revoked, mywork.* gone -- but whose id is still
-- sitting in trainer_principal_id on an old row (nothing here ever
-- clears that column on role change) could still write attendance_count/
-- experiment_delivered on it, indefinitely, through this branch alone.
-- Pairing with mywork.* closes that -- the same reasoning
-- DATABASE_CONVENTIONS.md's status-over-deletion rule applies elsewhere:
-- a row outliving the fact that granted access to it is not itself a
-- bug, but nothing should keep trusting that fact forever without
-- re-checking it.
--
-- Cannot edit 202609110003 -- already applied. Same drop-and-recreate
-- shape 202609110002 used to add a branch to an applied policy.
--
-- No behavior change for any of the six real wow-lab-test-b trainer
-- fixtures or any real wow-lab trainer verified against 202609110003 --
-- all hold mywork.* via the trainer/senior_trainer role, confirmed live
-- before writing this. Re-verified below, not just carried over.

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
