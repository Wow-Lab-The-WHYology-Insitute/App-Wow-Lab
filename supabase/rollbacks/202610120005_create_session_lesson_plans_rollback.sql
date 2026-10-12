-- Rollback for 202610120005 -- drops the link table.
--
-- DESTRUCTIVE in a way the other rollbacks in this pass are not: these rows are
-- choices real people made (a trainer's experiment, Catalina's verdict) and
-- cannot be regenerated from any file. The catalogue rollback can re-import;
-- this one cannot.
--
-- Check what would be lost before running it:
--   select status, count(*) from public.session_lesson_plans group by status;
--   select count(*) from public.row_history where table_name = 'session_lesson_plans';
--
-- row_history rows for this table SURVIVE the drop (row_history is keyed by
-- table_name text, not by a foreign key), so the proposal history outlives the
-- table it describes. That is deliberate and worth knowing: it is evidence, not
-- orphaned debris.

drop policy if exists "authenticated select session_lesson_plans" on public.session_lesson_plans;
drop trigger if exists session_lesson_plans_set_updated_at on public.session_lesson_plans;
drop trigger if exists session_lesson_plans_row_history on public.session_lesson_plans;
drop table if exists public.session_lesson_plans;
