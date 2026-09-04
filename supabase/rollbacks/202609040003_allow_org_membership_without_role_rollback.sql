-- 202609040003_allow_org_membership_without_role_rollback.sql
-- Rolls back 202609040003: drops the partial unique index, restores
-- role_id to NOT NULL.
--
-- Will fail with a not-null violation if any row has role_id is null at
-- rollback time (by design — that failure is the correct signal that a
-- real no-role membership row exists and must be deleted or given a role
-- first; this rollback does not silently delete or reassign anyone).
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

drop index if exists public.user_org_roles_one_membership_per_org_user;

alter table public.user_org_roles
  alter column role_id set not null;

comment on table public.user_org_roles is 'AUDITED: most security-sensitive membership table; row-history required.';
