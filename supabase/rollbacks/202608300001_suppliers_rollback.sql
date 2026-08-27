-- 202608300001_suppliers_rollback.sql
-- Rolls back 202608300001: drops the suppliers table entirely (policies,
-- triggers, and grants all drop with it). Restores exact pre-migration
-- state -- the table never existed.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

drop table public.suppliers;
