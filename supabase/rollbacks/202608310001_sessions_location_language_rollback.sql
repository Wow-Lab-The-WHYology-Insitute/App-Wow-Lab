-- 202608310001_sessions_location_language_rollback.sql
-- Rolls back 202608310001: drops location_tier and language_group (their
-- CHECK constraints drop automatically with the columns). Restores exact
-- pre-migration state -- neither column existed, nothing else on
-- sessions was touched by the forward migration.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

alter table public.sessions
  drop column location_tier,
  drop column language_group;
