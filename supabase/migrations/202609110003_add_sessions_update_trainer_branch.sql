-- 202609110003_add_sessions_update_trainer_branch.sql
-- WOW LAB OS: Anca's decision -- trainers enter attendance_count and
-- experiment_delivered directly, for sessions they are actually
-- allocated to. Today they hold no capability on sessions at all
-- (mywork.* appears only in the SELECT policy, 202608130003) and
-- attendance_count is writable only at session creation, by Operations,
-- before the session even happens.
--
-- Cannot edit 202608130003_add_groups_sessions_rls_policies.sql --
-- already applied. That migration's own comment, quoted in full:
--
--   "sessions — INSERT/UPDATE: Operations Manager (+Master) only,
--   including setting/changing trainer_principal_id/trainer_secundar_id
--   (ordinary columns on the row this policy already gates -- no
--   separate check needed for them specifically)."
--
-- That was correct and complete for the task spec it was written
-- against -- no role but Operations had any write access to sessions at
-- all. This migration adds the first one.
--
-- ============================================================================
-- WHAT REPLACES IT, AND WHY IT'S A ROW MATCH, NOT A CAPABILITY
-- ============================================================================
--
-- Deliberately NOT a capability branch (no "or app.has_capability(
-- 'sessions.write_own', ...)" or similar). sessions.create is the only
-- capability that currently touches this table's write policy, and it
-- is too broad for this: it also grants creating sessions and
-- reassigning trainer_principal_id/trainer_secundar_id, neither of
-- which a trainer recording their own attendance should be able to do.
-- A capability is an org-wide grant; what identifies "may this person
-- touch this specific session" here is the row itself --
-- trainer_principal_id = auth.uid() OR trainer_secundar_id =
-- auth.uid() -- the same row-match idiom the SELECT policy already uses
-- for mywork.*, minus the capability check, since no capability this
-- narrow exists or is being created for it.
--
-- ============================================================================
-- SCOPE, DELIBERATELY NARROW
-- ============================================================================
--
-- RLS restricts ROWS, not columns -- this migration only lets a matched
-- trainer's UPDATE reach their own session row at all. It says nothing
-- about which columns they may set; that boundary belongs in
-- updateSessionAttendance() (app/(app)/groups/actions.ts), narrowed to
-- exactly attendance_count and experiment_delivered, the same shape
-- updateSessionAllocation() already uses to narrow Operations' own
-- broader grant down to two different columns on this same table.
-- Nothing here grants a trainer the ability to change trainer_
-- principal_id/trainer_secundar_id/status through this new branch --
-- RLS would technically allow it (any column, for a matched row), the
-- action is what actually stops it.
--
-- No confirmation timestamps added here. Still blocked on Anca's four
-- open questions (docs/OPEN_ITEMS.md item 45 part 5's "still open, with
-- Anca" list) -- this row match is what those columns, once decided,
-- would extend: the same trainer_principal_id/trainer_secundar_id =
-- auth.uid() branch, a wider action payload. Not built ahead of the
-- decision.

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
