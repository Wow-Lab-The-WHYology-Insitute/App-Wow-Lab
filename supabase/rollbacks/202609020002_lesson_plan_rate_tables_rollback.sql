-- 202609020002_lesson_plan_rate_tables_rollback.sql
-- Reverts 202609020002. Per docs/WOWLAB_SAD_Field_Masking.md §6.2: lives
-- here, not in supabase/migrations/, so db push never auto-applies it.
--
-- To run for real: copy this file into supabase/migrations/ under a NEW
-- timestamp (not this one -- remote history already has this one), run
-- `supabase db push --linked`, then run `supabase migration repair
-- --status reverted <that-new-timestamp> --linked` immediately after --
-- §6.2 was missing that exact step until 2026-09-01 (commit `b7bbffb`);
-- skipping it leaves the next `db push`, for any reason, broken on the
-- mismatch. Then move this file back here.
--
-- Drops the tables and the resolver together -- taking the seeded
-- version (120 lei, effective 2024-01-01) with them. If lesson-plan pay
-- is rebuilt later, that figure is Anca's confirmed real value, not a
-- placeholder -- re-enter it, don't invent a new one.

drop function if exists app.resolve_lesson_plan_rate(uuid, date);
drop table if exists public.lesson_plan_rates;
drop table if exists public.lesson_plan_rate_versions;
