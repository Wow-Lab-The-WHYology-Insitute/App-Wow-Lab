-- 202608130002_seed_groups_sessions_capabilities.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — capability
-- grants.
--
-- Checked what's actually seeded (B4, supabase/seed.sql) before adding
-- anything, per the task's explicit instruction:
--   - trainers.allocate, trainers.substitute, trainers.engagement.read,
--     mywork.*, operations.* ALL already exist.
--   - mywork.* is already held by BOTH trainer and senior_trainer — this is
--     exactly the right capability for "Trainer/Senior Trainer see only
--     their OWN allocated sessions" (SAD §4's "ale mele" filter), so no new
--     capability or role grant is needed for that record-level rule at all.
--     The RLS policies (202608130003) check mywork.* combined with a
--     trainer_principal_id/trainer_secundar_id row match.
--   - trainers.allocate ("Allocate trainers to sessions") is semantically
--     narrower than what's needed here: Operations Manager must be able to
--     INSERT/UPDATE the full session row (session_date, status,
--     attendance_count, experiment_delivered, notes), not just the two
--     trainer-id columns. Reusing trainers.allocate as the sole write gate
--     would be a stretch of its stated meaning and would incorrectly imply
--     a future "trainer coordinator"-style role holding ONLY
--     trainers.allocate should also be able to edit unrelated session
--     fields. So this migration does NOT reuse it for the sessions write
--     policy — trainers.allocate remains exactly what it already was
--     (unused by RLS so far), and a new, correctly-scoped key is added
--     instead. This is a deliberate design choice, not a guess — flagged
--     in the final report.
--   - No existing capability at all covers "read/write the groups or
--     sessions tables in general" (operations_manager/finance_operations/
--     finance_admin_reporting hold nothing that would resolve for this
--     domain) — so groups.read/groups.create/sessions.read/sessions.create
--     are genuinely new, mirroring the exact clients.read/clients.create/
--     contracts.read/contracts.* naming convention from C1 (each business
--     entity gets its own capability domain, not nested under an existing
--     one like operations.*).
--
-- organization_owner ("Master") needs no explicit grant here — it already
-- receives every non-platform.* capability dynamically (seed.sql part 5),
-- and every policy below additionally checks
-- app.has_capability('org.settings.manage', organization_id) directly as
-- the Master marker, exactly matching the C1 RLS migration's own pattern.
--
-- Delivered as a migration (not a supabase/seed.sql-only edit) so it
-- reaches the already-provisioned remote via `db push`, per
-- DATABASE_CONVENTIONS.md #10 and the same reasoning as 202608100002.
-- supabase/seed.sql is updated in the same change so a fresh `db reset`
-- produces the identical end state.
--
-- Idempotent: ON CONFLICT DO NOTHING / DO UPDATE, same pattern as
-- supabase/seed.sql and 202608100002.

insert into public.capabilities (key, domain, resource, action, description)
values
  ('groups.read', 'groups', 'groups', 'read', 'Read group (enrollment container) records.'),
  ('groups.create', 'groups', 'groups', 'create', 'Create/update group records.'),
  ('sessions.read', 'sessions', 'sessions', 'read', 'Read session records (org-wide scope; Trainer/Senior Trainer use mywork.* + row-level allocation match instead of this key).'),
  ('sessions.create', 'sessions', 'sessions', 'create', 'Create/update session records, including trainer_principal_id/trainer_secundar_id allocation.')
on conflict (key) do update
  set domain = excluded.domain,
      resource = excluded.resource,
      action = excluded.action,
      description = excluded.description,
      updated_at = now();

insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (
  values
    ('operations_manager', 'groups.read'),
    ('operations_manager', 'groups.create'),
    ('operations_manager', 'sessions.read'),
    ('operations_manager', 'sessions.create'),

    ('finance_operations', 'groups.read'),
    ('finance_operations', 'sessions.read'),

    ('finance_admin_reporting', 'groups.read'),
    ('finance_admin_reporting', 'sessions.read')
) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;
