-- 202609020001_add_trainer_grade_assignments_source_rollback.sql
-- Reverts 202609020001. Per docs/WOWLAB_SAD_Field_Masking.md §6.2: lives
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
-- Safe unconditionally: the table was empty when the column was added,
-- and if this rollback is ever actually run, dropping the column loses
-- nothing that existed before 202609020001 by definition.

alter table public.trainer_grade_assignments
  drop column source;
