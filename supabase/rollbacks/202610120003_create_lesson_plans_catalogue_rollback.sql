-- Rollback for 202610120003 -- drops the catalogue tables.
--
-- NOT a true undo once 202610120004 has imported into them, and not safe to
-- run on its own after session_lesson_plans exists (202610120005 points at
-- lesson_plans). Run that migration's rollback first; this one will otherwise
-- fail on the dependent foreign key, loudly, which is the intended behaviour
-- rather than a cascade that silently deletes approval rows.
--
-- The import is reproducible from the workbook, so the data loss here is
-- recoverable by re-running 202610120004 -- unlike a rollback that discards
-- something typed in by a person.

drop trigger if exists lesson_plan_modules_set_updated_at on public.lesson_plan_modules;
drop trigger if exists lesson_plans_set_updated_at on public.lesson_plans;

drop policy if exists "authenticated select lesson_plan_modules" on public.lesson_plan_modules;
drop policy if exists "authenticated select lesson_plans" on public.lesson_plans;

drop table if exists public.lesson_plan_modules;
drop table if exists public.lesson_plans;
