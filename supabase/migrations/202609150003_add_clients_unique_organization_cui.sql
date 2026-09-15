-- 202609150003_add_clients_unique_organization_cui.sql
-- WOW LAB OS: unique (organization_id, cui) on clients, to stop the same
-- school being entered twice under the same tax id. Recommended in a
-- delivered report 2026-09-09 (docs/OPEN_ITEMS.md, the item recording
-- that report and what happened after it), never built until now.
--
-- Plain unique constraint, not a partial index -- matches the exact
-- precedent already in this schema (contracts_unique_organization_
-- exit_number, 202608180002) rather than introducing a new shape.
-- Postgres treats every NULL as distinct from every other NULL under a
-- plain UNIQUE constraint, so any number of clients with cui IS NULL
-- coexist without conflict; uniqueness only applies once a value is
-- actually set. No WHERE clause needed to get that behavior -- it is
-- the default for a normal unique constraint on a nullable column, the
-- same reason exit_number's own constraint needed none.
--
-- Verified live before writing this, not assumed: zero (organization_id,
-- cui) pairs with a non-null, non-blank cui repeat anywhere today --
--   select organization_id, cui, count(*) from public.clients
--   where cui is not null and trim(cui) <> '' group by 1, 2 having count(*) > 1;
-- returned no rows. Safe to add today. Not addressed: the same CUI
-- written two ways ("RO24395293" vs "24395293" vs "ro 24395293") would
-- not collide under this constraint -- a normalize-on-write question,
-- deferred, not solved by this migration. Decided later, if ever; safe
-- to leave as a plain string comparison for now.
alter table public.clients
  add constraint clients_unique_organization_cui
  unique (organization_id, cui);
