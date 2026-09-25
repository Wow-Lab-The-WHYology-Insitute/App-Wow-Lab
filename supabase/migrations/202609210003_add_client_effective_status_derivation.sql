-- OPEN_ITEMS.md item 78 (extends item 76's finding). Anca decided
-- (2026-09-21): a client is active once it has a signed contract.
--
-- Derived at read time, not stored -- chosen over having
-- markContractSigned also write clients.status, for the reasons item 78
-- records in full: that would create a second write path on a column
-- changeClientStatus's own comment already flags as owning entirely (the
-- same shape item 8 and item 45 part 5 both reject), and markContractSigned
-- is gated on contracts.*/finance.*/clients.create -- NOT clients.convert
-- (sales_manager-only, seed.sql) -- so a direct write there would hand a
-- Contract Administrator a status change the capability model reserves for
-- Sales.
--
-- security definer, not a plain RLS-scoped join: checked against item 68's
-- lesson before writing this. clients' own SELECT policy (202609170001)
-- has a mywork.* branch (session-scoped trainer visibility) that contracts'
-- SELECT policy (202608100003) has no equivalent of at all -- a plain
-- embedded select against contracts would silently return zero rows for a
-- trainer viewing an allocated client through that branch, always showing
-- "Prospect" regardless of truth. This bypasses RLS for exactly the one
-- boolean fact ("does this client have a signed contract"), the same
-- pattern app.has_capability already uses -- it does not change which
-- clients a viewer can see (the outer clients row is still filtered by
-- clients' own unchanged SELECT policy).
--
-- Exposed as a PostgREST computed column (public.client_effective_status(
-- clients)) so list and detail queries can select it directly
-- (status:client_effective_status), no N+1 RPC calls, no change to which
-- rows are returned.
--
-- paused/churned are the only stored overrides -- read as literal values,
-- always winning. Every other stored value (prospect, and the 3 legacy
-- rows still literally holding 'active' from Mihai's 2026-09-17 manual
-- move) falls through to the derivation. Confirmed live before writing
-- this: all 3 real WOW LAB clients (Scoala Avenor, Scoala Germana, Lycee
-- Francais) have stored status = 'active' and a signed contract each --
-- this leaves all 3 showing Active, unchanged, whether their stored value
-- is read as an override or falls through to the contract check.
create or replace function public.client_effective_status(c public.clients)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when c.status in ('paused', 'churned') then c.status
    when exists (
      select 1 from public.contracts ct
      where ct.client_id = c.id and ct.status = 'signed'
    ) then 'active'
    else 'prospect'
  end;
$$;

comment on function public.client_effective_status(public.clients) is
  'Computed column (item 78): effective clients.status. paused/churned stored values always win; otherwise active iff a signed contract exists, else prospect. security definer -- bypasses contracts RLS deliberately for this one boolean, see migration header. Nothing writes literal ''active'' to clients.status going forward (changeClientStatus writes ''prospect'' as the reactivate sentinel); the 3 legacy rows that already hold it are treated identically to ''prospect'' here (fall through to the contract check).';

grant execute on function public.client_effective_status(public.clients) to authenticated;
