-- 202608130005_grant_org_members_read_for_groups_sessions_ui.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions), G2 (UI) —
-- real RLS gap found while building the actual UI, not a UI-only fix.
--
-- The G2 spec requires showing trainer_principal/trainer_secundar NAMES on
-- the sessions list, and populating a trainer picker dropdown from users
-- holding the trainer/senior_trainer role. Both require reading OTHER
-- users' rows from public.users (and, for the picker, public.
-- user_org_roles) beyond "own row" -- which the "authenticated select
-- users"/"authenticated select user_org_roles" policies (202607100002)
-- only allow via org.members.read. Checked what's actually granted before
-- assuming: only organization_owner and platform_owner currently hold
-- org.members.read (both via the dynamic "all capabilities" grants, not
-- an explicit row) -- operations_manager and finance_admin_reporting,
-- who both already hold groups.read/sessions.read from 202608130002, do
-- NOT. Without this grant, a plain RLS-respecting query from either role
-- would silently return null/absent for every trainer name -- not an
-- error, just broken UI, which is worse.
--
-- org.members.read ("Read organization membership beyond own row (org
-- roster)") is exactly the right existing capability for this -- it was
-- created in 202607100002 specifically to close "the org admin capability
-- gap" for roster-reading needs, which is precisely what this is. No new
-- capability key needed.
--
-- Scope: operations_manager (primary need -- they allocate trainers by
-- name) and finance_admin_reporting (same visibility tier as their
-- existing groups.read/sessions.read grant, decision #25). Trainer/
-- Senior Trainer are deliberately NOT granted this -- they already see
-- their OWN name on their own sessions via the "own row" branch of the
-- users policy (id = app.current_user_id()), independent of org.
-- members.read; only a CO-trainer's name (the other of principal/
-- secundar on a shared session) would show blank for them. Flagged
-- explicitly in the final report as a known, minor limitation of this
-- first pass, not silently worked around by over-granting org-roster
-- access to a role that doesn't otherwise need it.
--
-- Idempotent: identical ON CONFLICT DO NOTHING pattern as 202608130002.
-- supabase/seed.sql is updated in the same change for a fresh `db reset`.

insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (
  values
    ('operations_manager', 'org.members.read'),
    ('finance_admin_reporting', 'org.members.read')
) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;
