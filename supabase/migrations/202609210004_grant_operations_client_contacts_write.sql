-- OPEN_ITEMS.md item 80. Anca's decision (2026-09-21): Catalina
-- (operations_manager) should be able to create client contacts. Today
-- only clients.create (sales_manager) or contracts.* (contract_
-- administrator) can INSERT/UPDATE public.client_contacts (202609110001)
-- -- confirmed live before writing this: operations_manager holds
-- operations.*, clients.read, contracts.read, trainers.allocate/
-- substitute, calendars.*, groups.create, sessions.create -- neither
-- clients.create nor contracts.*, so Catalina genuinely cannot today.
--
-- Capability granted: operations.* -- not a new grant (seed.sql already
-- gives it to operations_manager alone, confirmed live, no other role
-- holds it), and the right semantic match: an on-site/school-operational
-- contact is operations work, the same domain as the trainer-allocation
-- and calendar capabilities she already owns for this table's sibling
-- workflows (item 77's on-site-contact link reuses an existing contact;
-- this is what lets her create the contact it points at in the first
-- place).
--
-- INSERT + UPDATE only -- NOT DELETE. Argued, not defaulted: a wrong
-- contact is fixable by editing (the actual named need -- a phone typo);
-- removing one outright is rarer and more consequential, and stays with
-- the existing owners (Sales/Contract Administrator/org owner). No
-- second write path concern here the way items 8/45/78 raise it --
-- operations.* joins the SAME two existing policies (clients.create OR
-- contracts.*) as a third alternative, not a new independent path to a
-- column only one place is supposed to own.
--
-- SELECT untouched, on purpose -- confirmed by construction, not just by
-- argument: this migration edits only the INSERT and UPDATE policies.
-- The finance client-type segregation (finance.operations.* ->
-- private_school/parent_b2c, finance.reporting.* -> everything else,
-- 202608250001) lives entirely in the SELECT policy, which this migration
-- never touches. Catalina can already read client_contacts today (her
-- clients.read capability satisfies the existing non-finance SELECT
-- branch, "clients.read AND NOT finance.operations.* AND NOT
-- finance.reporting.*") -- this only adds write.
--
-- Cannot edit 202609110001 -- already applied. Same drop-and-recreate
-- shape that migration itself already used on 202608100003/202608270001.
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
      or app.has_capability('operations.*', organization_id)
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
      or app.has_capability('operations.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('clients.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
      or app.has_capability('operations.*', organization_id)
    );
  -- DELETE policy (202609110001) intentionally left untouched.
end;
$$;
