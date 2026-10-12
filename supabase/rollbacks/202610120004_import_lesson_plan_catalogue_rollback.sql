-- Rollback for 202610120004 -- removes the imported catalogue.
--
-- Scoped to wow-lab and to rows with no session link pointing at them. If a
-- trainer has already proposed one of these plans, the delete FAILS LOUDLY on
-- session_lesson_plans' foreign key rather than cascading -- deliberately: a
-- proposal is a record of a real choice a real person made, and removing the
-- catalogue under it is a human decision, not an automatic one.
--
-- Fully reproducible: re-running 202610120004 restores byte-identical rows,
-- ids included (uuid5 of the source key).
--
-- To see what would block it first:
--   select count(*) from public.session_lesson_plans;

delete from public.lesson_plan_modules
 where organization_id = (select id from public.organizations where slug = 'wow-lab');

delete from public.lesson_plans
 where organization_id = (select id from public.organizations where slug = 'wow-lab');
