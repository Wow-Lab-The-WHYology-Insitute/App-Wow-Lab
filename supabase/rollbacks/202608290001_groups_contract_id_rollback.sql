-- 202608290001_groups_contract_id_rollback.sql
-- Rolls back 202608290001: drops contract_id (and its FK constraint,
-- which drops automatically with the column). Restores exact
-- pre-migration state -- the column never existed, nothing else on
-- groups was touched by the forward migration.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

alter table public.groups
  drop column contract_id;
