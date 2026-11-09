-- Rollback for 202611090001_amends_contract_id_avenor_entity_split.sql.
--
-- Restores Avenor's single contract to its pre-split state, deletes the
-- September predecessor, then drops the column entirely -- nothing else in
-- this schema reads public.contracts.amends_contract_id as of this
-- migration (supplier_contracts has its own, separate, column of the same
-- name on a different table, untouched by this).
--
-- Refuses rather than overwrites if the existing contract has moved on
-- since (same defensive shape as 202610300008's own rollback).

do $$
declare
  v_existing_contract uuid := '906de33a-22d3-4832-97aa-6fbd5f6dfa41';
  v_predecessor uuid;
begin
  select amends_contract_id into v_predecessor from public.contracts where id = v_existing_contract;

  if v_predecessor is null then
    raise exception 'rollback: Avenor contract % has no amends_contract_id -- the forward migration may already have been rolled back, or never applied', v_existing_contract;
  end if;

  if (select period_start from public.contracts where id = v_existing_contract) <> '2026-10-01' then
    raise exception 'rollback: Avenor contract %''s period_start has changed since the split -- someone has acted on this since, refusing to silently restore over it', v_existing_contract;
  end if;

  update public.contracts
    set period_start = '2026-09-01',
        amends_contract_id = null
    where id = v_existing_contract;

  delete from public.contracts where id = v_predecessor;

  raise notice 'rollback: Avenor contract % restored to period_start 2026-09-01, amends_contract_id null; predecessor % deleted.', v_existing_contract, v_predecessor;
end $$;

alter table public.contracts drop constraint if exists contracts_no_self_amend_check;
drop index if exists public.contracts_amends_idx;
alter table public.contracts drop column if exists amends_contract_id;
