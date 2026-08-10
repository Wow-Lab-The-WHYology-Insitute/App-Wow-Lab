-- 202608100002_seed_clients_contracts_capabilities.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — capability grants.
--
-- No NEW capability keys are needed: clients.read, clients.create,
-- contracts.read, contracts.*, finance.operations.*, finance.reporting.*
-- all already exist from the B4 seed (supabase/seed.sql). What's missing is
-- two ROLE_CAPABILITIES grants: per the SAD (§6, "Menu: zona Clients &
-- Contracts vizibilă pentru ... Operations (read)") and the inline task spec
-- ("Menu-level ... sales_manager ... operations_curriculum_coordinator
-- (read-only)"), sales_manager and operations_manager both need read access
-- to `contracts`, which neither currently has (sales_manager has none of
-- contracts.read/contracts.*; operations_manager likewise).
--
-- "operations_curriculum_coordinator" from the task prompt does not exist as
-- a role key — the SAD (§3) names this "Operations Coordinator" and ties it
-- specifically to `clients.read`, already held by operations_manager (the
-- role Cătălina actually holds alongside curriculum_manager). This migration
-- maps that concept to operations_manager, not curriculum_manager — see the
-- final report for this assumption spelled out.
--
-- This is seed-shaped DATA (not a schema change), delivered as a migration
-- rather than a supabase/seed.sql-only edit because seed.sql is not
-- re-applied by `db push` against an already-provisioned remote — see
-- DATABASE_CONVENTIONS.md #10 and the task's explicit instruction to use "a
-- new migration, following the existing capability-seeding pattern".
-- supabase/seed.sql is ALSO updated in this same change so a fresh
-- `db reset` produces the identical end state.
--
-- Idempotent: identical ON CONFLICT DO NOTHING pattern as supabase/seed.sql
-- part 3.

insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (
  values
    ('sales_manager', 'contracts.read'),
    ('operations_manager', 'contracts.read')
) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;
