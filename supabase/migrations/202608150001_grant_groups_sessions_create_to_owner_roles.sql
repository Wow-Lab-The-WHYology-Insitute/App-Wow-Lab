-- 202608150001_grant_groups_sessions_create_to_owner_roles.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — capability
-- gap found during production regression verification (not a new bug from
-- that merge, pre-existing since G1 first shipped).
--
-- organization_owner and platform_owner both get a ONE-TIME blanket grant
-- of "every capability that existed when seed.sql ran" (supabase/seed.sql
-- parts 4/5, unconditional CROSS JOIN over public.capabilities at seed
-- time). groups.create/sessions.create (and groups.read/sessions.read)
-- didn't exist yet at that point -- they were introduced later by G1's own
-- capability migration (202608130002), which explicitly granted them to
-- operations_manager/finance_operations/finance_admin_reporting but never
-- to organization_owner/platform_owner. Confirmed live (not assumed) via
-- impersonation before writing this: both roles hold org.settings.manage
-- and clients.create (pre-existing at seed time) but neither holds
-- groups.create or sessions.create.
--
-- Practical effect: RLS itself was never broken -- both roles already
-- read/write groups and sessions today via the Master-bypass branch of
-- every G1 policy (app.is_platform_owner() OR app.has_capability(
-- 'org.settings.manage', organization_id), same idiom as Clients &
-- Contracts). What was missing is purely the UI-level "should I show
-- + New Group / + New Session" check in app/(app)/groups/page.tsx and
-- app/(app)/groups/[id]/page.tsx, which look at the specific
-- groups.create/sessions.create capability, not the broader Master
-- bypass -- so the buttons never rendered for organization_owner even
-- though the insert would have succeeded if attempted.
--
-- Scope: groups.create + sessions.create only, both roles. groups.read/
-- sessions.read are deliberately NOT touched here -- read access already
-- works today via the same Master-bypass RLS branch, so there is no actual
-- gap to close there (confirmed live: organization_owner already saw
-- every group/session in the production regression check that found
-- this).
--
-- supabase/seed.sql is NOT updated for this one -- unlike 202608130005
-- (org.members.read, a narrowly-targeted grant to specific roles with no
-- blanket coverage), organization_owner/platform_owner's blanket
-- CROSS JOIN in seed.sql parts 4/5 runs unconditionally over whatever
-- capabilities exist at that point, and on a fresh `db reset` all
-- migrations (including G1's 202608130002, which creates groups.create/
-- sessions.create) run BEFORE seed.sql -- so a fresh reset already picks
-- these up automatically today. Only the already-provisioned remote was
-- ever affected (seed.sql is not re-applied by `db push`, same reasoning
-- as 202608100002's own header comment).
--
-- Idempotent: identical ON CONFLICT DO NOTHING pattern as every other
-- capability-grant migration in this codebase.

insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (
  values
    ('organization_owner', 'groups.create'),
    ('organization_owner', 'sessions.create'),
    ('platform_owner', 'groups.create'),
    ('platform_owner', 'sessions.create')
) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;
