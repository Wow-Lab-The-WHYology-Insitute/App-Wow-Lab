-- 202609040003_allow_org_membership_without_role.sql
-- WOW LAB OS: user_org_roles.role_id becomes nullable, so "member of this
-- org, no role assigned yet" can exist as a real row instead of not
-- existing at all.
--
-- Found live, not assumed: /admin/users' Members list is anchored on
-- user_org_roles (FROM that table, not FROM users), so an account with
-- zero role rows in an org never appears as an input row to enumerate --
-- there is nothing to filter or drop, it was never fetched. Raluca
-- Margean (real account, created 2026-09-03, deliberately given no role
-- pending Anca's decision — item 22) is exactly this case: she exists,
-- can sign in, and is invisible on the one screen that would let an
-- admin fix that.
--
-- role_id was `not null` from the original schema (202607080002) because
-- every row was assumed to represent one specific role grant -- "member"
-- and "holds this role" were the same concept by construction. They
-- aren't: app.belongs_to_org() (202607090001) already defines org
-- membership as "has any user_org_roles row in this org", independent of
-- which role, and is already used that way elsewhere for RLS. A
-- role_id-nullable row satisfies that definition (still a row) while
-- contributing zero capabilities: app.has_capability()'s join is
-- `role_capabilities rc on rc.role_id = uor.role_id` -- `rc.role_id =
-- NULL` never matches, so a membership-only row grants nothing by
-- construction, not by an added exception. No RLS policy on
-- user_org_roles or users references role_id in its predicate (checked
-- live against 202607100002/202607100004 before this migration) --
-- membership and capability were already evaluated independently at the
-- RLS layer; only the NOT NULL constraint prevented the data from
-- reflecting that.
--
-- The existing unique constraint (organization_id, user_id, role_id)
-- does not protect against duplicate NULL-role rows for the same person
-- --standard SQL treats NULLs as distinct for uniqueness. The partial
-- index below covers exactly that gap: at most one no-role membership
-- row per (org, user). organization_id and user_id are both NOT NULL, so
-- ordinary uniqueness semantics apply to the indexed columns themselves;
-- only the WHERE clause is role_id-null-specific.

alter table public.user_org_roles
  alter column role_id drop not null;

create unique index user_org_roles_one_membership_per_org_user
  on public.user_org_roles (organization_id, user_id)
  where role_id is null;

comment on table public.user_org_roles is 'AUDITED: most security-sensitive membership table; row-history required. role_id nullable as of 202609040003 -- a null role_id means "member of this org, no role assigned yet" (app.belongs_to_org() still true, app.has_capability() never matches), not the absence of a row.';
