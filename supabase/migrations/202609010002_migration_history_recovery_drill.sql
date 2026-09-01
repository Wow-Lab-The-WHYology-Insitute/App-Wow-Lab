-- 202609010002_migration_history_recovery_drill.sql
-- Throwaway, harmless, reversible -- exists solely to prove the
-- supabase/rollbacks/ recovery procedure (WOWLAB_SAD_Field_Masking.md
-- §6.2) actually works end-to-end, now that 202608310001/202608310002/
-- 202609010001's missing migration-history rows have been repaired
-- (supabase migration repair --status applied). We only knew the
-- procedure was broken by that gap; this drill is what confirms it is
-- fixed, not an assumption. Rolled back in the same session via its
-- companion file in supabase/rollbacks/, following §6.2's documented
-- steps exactly, not a variant of them.

create table public._migration_history_recovery_drill (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

comment on table public._migration_history_recovery_drill is 'Throwaway table, not part of the application schema. Created only to drill the supabase/rollbacks/ recovery procedure end-to-end after the 2026-09-01 migration-history repair. Should not exist outside that drill -- see 202609010002 and its rollback.';
