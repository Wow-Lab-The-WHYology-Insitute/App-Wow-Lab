-- 202608270001_client_contacts_delete.sql
-- client_contacts DELETE, per the delete-scope investigation (three tables
-- considered: contracts, clients, client_contacts -- not the same
-- problem). This is the simple one: confirmed live before writing this,
-- client_contacts has ZERO incoming foreign keys anywhere in the schema
-- -- nothing can be orphaned by deleting a row here, unlike contracts
-- (self-referencing renewal_of) or clients (referenced by client_contacts
-- itself, contracts, and groups -- which is why clients gets no delete
-- feature at all, see docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md
-- Sec8 and docs/DATABASE_CONVENTIONS.md Sec12).
--
-- No status condition, unlike the contracts round that follows this one --
-- a contact is a person's details, not a record of a transaction. A wrong
-- one should vanish outright, regardless of whether it's marked primary
-- or billing.
--
-- Predicate is identical to this table's own existing INSERT/UPDATE
-- policy (202608100003) -- whoever can create or edit a contact can
-- delete a wrong one. Confirmed live before writing this migration, not
-- copied from memory.
--
-- This also serves GDPR erasure. The retention anonymization job (SAD
-- Sec7, DATABASE_CONVENTIONS.md Sec9) runs automatically at 36 months --
-- it does not, and was never meant to, cover a person asking to be
-- removed now. Before this migration, there was no path to that at all
-- for client_contacts: no DELETE policy, no DELETE grant to authenticated.
-- This is that path.

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

grant delete on public.client_contacts to authenticated;
