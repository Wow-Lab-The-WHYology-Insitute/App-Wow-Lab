-- 202609110001_remove_client_contacts_write_finance_exclusion.sql
-- WOW LAB OS: Anca's decision, 2026-09-11 -- the same tradeoff as
-- 202609080001 (contracts, 2026-09-06), extended to client_contacts.
-- Removes the "not finance.reporting.* and not finance.operations.*"
-- exclusion from the three WRITE policies on public.client_contacts
-- (INSERT, UPDATE, DELETE) only. SELECT and the row filters inside it
-- are untouched, on purpose -- see the scope note below.
--
-- Cannot edit 202608100003_add_clients_contracts_rls_policies.sql (INSERT/
-- UPDATE) or 202608270001_client_contacts_delete.sql (DELETE) -- both
-- already applied. This migration is where the correction lives; anyone
-- reading either old file needs to land here.
--
-- ============================================================================
-- WHAT THE OLD COMMENT SAID, AND WHY IT WAS WRITTEN THAT WAY
-- ============================================================================
--
-- 202608100003, directly above the INSERT/UPDATE policies this migration
-- replaces:
--
--   "client_contacts -- INSERT/UPDATE. Neither the task nor the SAD
--   specifies action-level rules for this table. Inferred default
--   (flagged in the final report): whoever can own the client
--   relationship (clients.create = sales_manager) or the contract
--   (contracts.* excluding the two finance roles = contract_administrator)
--   can manage its contacts, plus org/platform owner."
--
-- 202608270001's own DELETE policy comment says its predicate is
-- "deliberately IDENTICAL to the existing INSERT/UPDATE predicate" --
-- it carries no independent reasoning of its own, so nothing further to
-- quote there.
--
-- Unlike the contracts exclusion (202609080001 -- load-bearing, to stop
-- finance_admin_reporting passing a write check through its own shared
-- contracts.* read key), this one was never claimed as load-bearing at
-- all. Its own comment already flagged it as an *inferred* default, not
-- a specified rule -- this table's exclusion was weaker on its own
-- terms than the one already removed from contracts.
--
-- ============================================================================
-- WHAT REPLACES IT
-- ============================================================================
--
-- Anca's decision, 2026-09-11: the same tradeoff as contracts, applied
-- here too -- contract_administrator holders manage a client's contacts
-- regardless of any finance role also held. This closes the half item 37
-- (OPEN_ITEMS.md) left open: the contracts fix was scoped to contracts
-- specifically and deliberately not widened to client_contacts without
-- asking her first. This migration is that second answer.
--
-- ============================================================================
-- SCOPE, DELIBERATELY NARROW -- SAME REASONING AS 202609080001
-- ============================================================================
--
-- WRITE only (INSERT/UPDATE/DELETE on client_contacts). SELECT is
-- untouched -- there, the exclusion is not a lockout: finance roles read
-- through their own client-type-scoped branch instead
-- (finance_operations -> private_school/parent_b2c, finance_reporting ->
-- everything else), which is the read segregation the SAD specifies and
-- Anca did not change. The is_billing_contact row-level masking inside
-- the same SELECT policy is untouched for the same reason.

DO $$
begin
  drop policy if exists "authenticated insert client_contacts" on public.client_contacts;
  create policy "authenticated insert client_contacts" on public.client_contacts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated update client_contacts" on public.client_contacts;
  create policy "authenticated update client_contacts" on public.client_contacts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated delete client_contacts" on public.client_contacts;
  create policy "authenticated delete client_contacts" on public.client_contacts
    for delete
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );
end;
$$;
