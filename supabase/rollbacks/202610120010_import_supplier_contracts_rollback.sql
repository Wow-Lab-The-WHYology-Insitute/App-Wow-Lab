-- Rollback for 202610120010 -- removes the 30 imported supplier contracts.
--
-- Scoped to wow-lab. Amendment links are cleared first so the self-referencing
-- foreign key cannot block the delete, and because a half-deleted chain is a
-- worse state than none.
--
-- Fully reproducible: re-running 202610120010 restores byte-identical rows,
-- ids included (uuid5 of the register row number).
--
-- Anything Finance has edited by hand since the import is NOT reproducible --
-- check public.row_history for table_name = 'supplier_contracts' before running
-- this, and note those rows survive the delete.

update public.supplier_contracts set amends_contract_id = null
 where organization_id = (select id from public.organizations where slug = 'wow-lab');

delete from public.supplier_contracts
 where organization_id = (select id from public.organizations where slug = 'wow-lab');
