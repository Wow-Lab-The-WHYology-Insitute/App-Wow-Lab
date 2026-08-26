-- 202608280001_contracts_delete.sql
-- contracts DELETE, per the delete-scope investigation (three tables
-- considered: contracts, clients, client_contacts -- not the same
-- problem; client_contacts shipped in 202608270001, clients is out of
-- scope entirely, see docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md
-- Sec8 and docs/DATABASE_CONVENTIONS.md Sec12).
--
-- Draft only, unlike client_contacts' unconditional delete -- a contract
-- is a record of a transaction, not just a person's details. Once it's
-- left draft (sent, signed, expired, renewed) it's something someone
-- acted on; deleting it would erase that, not just correct a mistake.
-- churned-style "mark it gone, keep the history" doesn't apply here
-- either -- a draft has no history worth keeping yet, which is exactly
-- why it's the one status this is safe for.
--
-- Predicate is identical to this table's own existing INSERT/UPDATE
-- policy (202608100003 -- org.settings.manage OR contracts.* excluding
-- either finance role), AND-ed with status = 'draft'. Confirmed live
-- before writing this migration, not copied from memory.
--
-- contracts_renewal_of_fkey (self-referencing, no ON DELETE clause --
-- implicit RESTRICT) is the one thing that can block this at the
-- database level: deleting a draft that another contract's renewal_of
-- points at raises a foreign-key violation (23503). Confirmed live
-- before writing this: zero contracts have renewal_of set anywhere in
-- production today, so this path is UNTESTABLE with real data -- the
-- verification script constructs it synthetically in a rolled-back
-- transaction. The application action must catch 23503 specifically and
-- surface an actionable message, not the raw constraint error.

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

grant delete on public.contracts to authenticated;
