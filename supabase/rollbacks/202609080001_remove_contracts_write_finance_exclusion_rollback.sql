-- 202609080001_remove_contracts_write_finance_exclusion_rollback.sql
-- Rolls back 202609080001: restores the three contracts WRITE policies
-- (INSERT, UPDATE, DELETE) to their pre-2026-09-08 form, byte-identical
-- to 202608100003/202608280001's own predicates -- the
-- "not finance.reporting.* and not finance.operations.*" exclusion, back
-- in place.
--
-- Restoring this reinstates the exact structural block on Laura and Anka
-- that Anca's 2026-09-06 decision removed -- do not run this without
-- confirming that decision has actually changed, not just that a rollback
-- is convenient.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

DO $$
begin
  drop policy if exists "authenticated insert contracts" on public.contracts;
  create policy "authenticated insert contracts" on public.contracts
    for insert
    to authenticated
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    );

  drop policy if exists "authenticated update contracts" on public.contracts;
  create policy "authenticated update contracts" on public.contracts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    );

  drop policy if exists "authenticated delete contracts" on public.contracts;
  create policy "authenticated delete contracts" on public.contracts
    for delete
    to authenticated
    using (
      (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      )
      and status = 'draft'
    );
end;
$$;
