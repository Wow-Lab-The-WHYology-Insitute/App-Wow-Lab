-- Rollback for 202610120009 -- drops the table.
--
-- Run 202610120010's rollback first if the import has landed, or accept that
-- this drops those 30 rows with it. They are reproducible from the register
-- (`Tabel contracte furnizori Wow Lab.xlsx`), so the loss is recoverable --
-- unlike anything Finance later edits by hand, which is why the table carries
-- row_history from the start.
--
-- row_history rows for this table SURVIVE the drop (row_history is keyed by
-- table_name text, not by a foreign key). That is deliberate: the history
-- outlives the table it describes and is evidence, not debris.

drop policy if exists "authenticated select supplier_contracts" on public.supplier_contracts;
drop trigger if exists supplier_contracts_row_history on public.supplier_contracts;
drop trigger if exists supplier_contracts_set_updated_at on public.supplier_contracts;
drop table if exists public.supplier_contracts;
