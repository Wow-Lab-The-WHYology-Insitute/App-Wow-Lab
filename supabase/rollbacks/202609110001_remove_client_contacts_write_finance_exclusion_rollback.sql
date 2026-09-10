-- 202609110001_remove_client_contacts_write_finance_exclusion_rollback.sql
-- Rolls back 202609110001: restores the three client_contacts WRITE
-- policies (INSERT, UPDATE, DELETE) to their pre-2026-09-11 form,
-- byte-identical to 202608100003/202608270001's own predicates -- the
-- "not finance.reporting.* and not finance.operations.*" exclusion, back
-- in place.
--
-- Restoring this reinstates the exact structural block on Laura and Anka
-- that Anca's 2026-09-11 decision removed -- do not run this without
-- confirming that decision has actually changed, not just that a rollback
-- is convenient.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

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
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    );

  drop policy if exists "authenticated update client_contacts" on public.client_contacts;
  create policy "authenticated update client_contacts" on public.client_contacts
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    );

  drop policy if exists "authenticated delete client_contacts" on public.client_contacts;
  create policy "authenticated delete client_contacts" on public.client_contacts
    for delete
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or (
        app.has_capability('contracts.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
      )
    );
end;
$$;
