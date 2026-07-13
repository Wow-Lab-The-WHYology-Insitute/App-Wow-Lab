-- 202607130006_grant_service_role_full_table_access.sql
-- WOW LAB OS, Next.js scaffolding S1 (auth): give service_role the table
-- grants it was always assumed to have.
--
-- Found while wiring up the admin server actions (§3 of the S1 task):
-- service_role's ONLY privileges on every public table were the platform
-- baseline (REFERENCES, TRIGGER, TRUNCATE — see 202607100008) — no SELECT,
-- INSERT, UPDATE, or DELETE anywhere. BYPASSRLS (which service_role has)
-- only skips row-security POLICY checks; it does not substitute for a
-- missing table-level GRANT, and none was ever issued. This was invisible
-- until now because every previous use of service_role this project (the
-- row_history/org_settings proofs, the D1b/hardening verification suites)
-- granted itself temporary, transaction-scoped privileges that rolled back
-- along with everything else, and audited a live session under
-- `set local role service_role` rather than a real PostgREST connection.
-- The admin actions in this task are the first real, permanent use of the
-- service_role client — hence the first time this gap actually blocked
-- something.
--
-- "service_role needs full access" is the design already stated for it
-- (this task's own instructions: "Do NOT touch service_role — it needs
-- full access"; the hardening migration's REVOKE deliberately excluded
-- it). This migration makes that already-stated intent true rather than
-- introducing new scope: SELECT/INSERT/UPDATE/DELETE on every current
-- table, plus a matching default-privileges entry (FOR ROLE postgres,
-- same as our own REVOKE in 202607100008) so future tables get it too.
--
-- Idempotent: GRANT and ALTER DEFAULT PRIVILEGES GRANT are naturally
-- re-runnable.

grant select, insert, update, delete on all tables in schema public to service_role;

alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to service_role;
