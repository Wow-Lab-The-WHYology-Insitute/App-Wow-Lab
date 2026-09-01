-- 202609010002_migration_history_recovery_drill_rollback.sql
-- Reverts 202609010002. Per WOWLAB_SAD_Field_Masking.md §6.2: lives here,
-- not in supabase/migrations/, so db push never auto-applies it. To run
-- for real: copy this file into supabase/migrations/ under a NEW
-- timestamp (not this one -- remote history already has this one),
-- run `supabase db push --linked`, then move it back here.

drop table if exists public._migration_history_recovery_drill;
