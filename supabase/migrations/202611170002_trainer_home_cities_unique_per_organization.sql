-- 202611170002_trainer_home_cities_unique_per_organization.sql
--
-- OPEN_ITEMS item 198, the class's second form (unique keys that ignore the
-- organization), its one real instance: UNIQUE (trainer_id) on an
-- org-scoped table, while users are global. Induced 2026-11-17 through RLS:
-- Org B recorded Lorina's home city first, and wow-lab could then no longer
-- record its own trainer's (23505) -- a denial, not a corruption: nothing in
-- wow-lab moved, a write became impossible. Repaired as Mihai decided
-- (2026-11-17): the key gains the organization. 11 rows, all wow-lab, so
-- nothing can collide on apply.
--
-- An open question this repair does NOT answer, written into item 198 on
-- Mihai's instruction: a home city is a property of the PERSON, and users are
-- global by design. If it should be global, the right repair was the
-- opposite one -- drop organization_id rather than add it to the key. Cheap
-- to change while the table holds 11 rows.
--
-- Test: db/tests/cross_org_write_isolation.sql points 15-16 (the class test,
-- second form, and its SABOTAGE), failing against the live schema before
-- this migration.

alter table public.trainer_home_cities drop constraint trainer_home_cities_trainer_unique;
alter table public.trainer_home_cities add constraint trainer_home_cities_org_trainer_unique unique (organization_id, trainer_id);
