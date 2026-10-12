-- Rollback for 202610120011 -- drops both tables and the resolver.
--
-- Run 202610120012's rollback first if the seed has landed, or accept that
-- this drops those rows with it (admin_rates cascades from the version row).
-- The figures are reproducible from Anca's 2026-08-07 and 2026-08-10 messages
-- as recorded in item 111, so the loss is recoverable.

drop function if exists app.resolve_admin_rate(uuid, uuid, text, text, text, date);
drop policy if exists "authenticated select admin_rates" on public.admin_rates;
drop policy if exists "authenticated select admin_rate_versions" on public.admin_rate_versions;
drop trigger if exists admin_rates_set_updated_at on public.admin_rates;
drop table if exists public.admin_rates;
drop table if exists public.admin_rate_versions;
