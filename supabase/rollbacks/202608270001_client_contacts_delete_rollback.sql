-- 202608270001_client_contacts_delete_rollback.sql
-- Rolls back 202608270001: removes the DELETE policy and the DELETE grant
-- to authenticated. Restores the exact pre-migration state -- no DELETE
-- path on client_contacts for anyone but service_role/postgres.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

drop policy "authenticated delete client_contacts" on public.client_contacts;

revoke delete on public.client_contacts from authenticated;
