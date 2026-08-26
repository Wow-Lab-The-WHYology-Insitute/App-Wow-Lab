-- 202608280001_contracts_delete_rollback.sql
-- Rolls back 202608280001: removes the DELETE policy and the DELETE grant
-- to authenticated. Restores the exact pre-migration state -- no DELETE
-- path on contracts for anyone but service_role/postgres.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

drop policy "authenticated delete contracts" on public.contracts;

revoke delete on public.contracts from authenticated;
