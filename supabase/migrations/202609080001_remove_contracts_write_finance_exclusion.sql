-- 202609080001_remove_contracts_write_finance_exclusion.sql
-- WOW LAB OS: Anca's decision, 2026-09-06 — contract_administrator holders
-- write contracts regardless of any finance role also held. Removes the
-- "not finance.reporting.* and not finance.operations.*" exclusion from
-- the three WRITE policies on public.contracts (INSERT, UPDATE, DELETE)
-- only. SELECT is untouched, on purpose — see the scope note below.
--
-- Cannot edit 202608100003_add_clients_contracts_rls_policies.sql or
-- 202608280001_contracts_delete.sql — both already applied. This
-- migration is where the correction lives; anyone reading either old
-- file needs to land here, so both are quoted in full below, not just
-- referenced.
--
-- ============================================================================
-- WHAT THE OLD COMMENTS SAID, AND WHY THEY WERE WRITTEN THAT WAY
-- ============================================================================
--
-- 202608100003, directly above the INSERT policy this migration replaces:
--
--   "contracts — INSERT/UPDATE: contract_administrator (+ Master) only.
--   This is the one place finance_admin_reporting's shared 'contracts.*'
--   key MUST NOT grant write access (task: "Only contract_administrator
--   (+ Master) can INSERT/UPDATE contracts") — the "not
--   finance.reporting.*"/"not finance.operations.*" exclusions are
--   load-bearing here, not decorative."
--
-- 202608280001, describing the DELETE policy this migration also
-- replaces:
--
--   "Predicate is identical to this table's own existing INSERT/UPDATE
--   policy (202608100003 -- org.settings.manage OR contracts.* excluding
--   either finance role), AND-ed with status = 'draft'."
--
-- Checked against the actual reasoning available (git history, the SAD),
-- not assumed: the task instruction those comments cite traces to
-- docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md Sec6 -- "doar
-- contract_administrator (+ Master) pot crea/edita/marca semnat un
-- contract" ("only contract_administrator (+ Master) can create/edit/
-- mark a contract signed"). That instruction is a single-role
-- concentration rule. Its own recorded justification is narrower than
-- what the code enforced: `finance_admin_reporting` happens to hold the
-- identical `contracts.*` key (for reading corporate/state/grant
-- contracts, per the same SAD's own read-side segregation) -- without an
-- exclusion, that coincidence would let it pass a check meant to
-- identify "the contract administrator." That's the whole recorded
-- reason for excluding `finance.reporting.*`.
--
-- `finance.operations.*` was excluded too, with no reasoning recorded
-- anywhere for that half specifically. `finance_operations` never
-- independently holds `contracts.*` (its own grant is `contracts.read`)
-- -- so that exclusion could only ever matter for someone holding
-- `contracts.*` through a different role while also holding
-- `finance_operations`. That combination did not exist when this was
-- written. It exists now: Laura holds `finance_operations` +
-- `contract_administrator`, and Anka holds both finance roles plus
-- `contract_administrator` (item 31, OPEN_ITEMS.md -- her role set
-- exists to cover Laura's responsibilities during Laura's maternity
-- leave, contract administration included). Both were structurally
-- blocked from exactly the work those roles were assigned for.
--
-- ============================================================================
-- WHAT REPLACES IT
-- ============================================================================
--
-- Anca's decision, 2026-09-06: contract_administrator holders write
-- contracts regardless of any finance role also held. Accepted risk, in
-- her own terms: the person who writes the contract's terms may also be
-- the person who invoices on them -- she chose that over leaving Laura
-- and Anka structurally unable to do the contract-administration half of
-- their own assigned roles.
--
-- ============================================================================
-- SCOPE, DELIBERATELY NARROW
-- ============================================================================
--
-- WRITE only (INSERT/UPDATE/DELETE on contracts). SELECT is untouched --
-- there, the exclusion was never a lockout: finance roles read through
-- their own narrower branch instead (e.g. finance_operations paired with
-- `client_type in ('private_school','parent_b2c')`), which is the actual
-- read-side segregation the SAD specifies (Sec6: "Finance Operations vede
-- contractele școli private; Finance Admin vede corporate/stat/granturi
-- (segregare)"). Anca did not change that, and this migration does not
-- touch it. Same reasoning for `clients` SELECT and the
-- `client_contacts` row filters (202608250001) -- not touched.
--
-- `client_contacts` INSERT/UPDATE/DELETE carry the identical exclusion,
-- on the identical `contracts.*` branch, gating a task ("manage this
-- client's contacts") the 202608100003 comment itself describes as part
-- of what a contract administrator does. Reported to Mihai before this
-- migration was written, deliberately not included here -- Anca's
-- decision was about contracts, not client_contacts, and extending scope
-- without asking was exactly what was flagged against doing.

DO $$
begin
  drop policy if exists "authenticated insert contracts" on public.contracts;
  create policy "authenticated insert contracts" on public.contracts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated update contracts" on public.contracts;
  create policy "authenticated update contracts" on public.contracts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );

  drop policy if exists "authenticated delete contracts" on public.contracts;
  create policy "authenticated delete contracts" on public.contracts
    for delete
    to authenticated
    using (
      (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('contracts.*', organization_id)
      )
      and status = 'draft'
    );
end;
$$;
