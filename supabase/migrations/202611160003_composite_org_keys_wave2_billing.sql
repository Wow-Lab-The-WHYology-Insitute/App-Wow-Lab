-- 202611160003_composite_org_keys_wave2_billing.sql
--
-- Tenant isolation, wave 2 of 3 (OPEN_ITEMS item 198): the 8 foreign keys
-- whose parent is a client, a contract or a legal entity -- who is billed,
-- by which entity. Same shape and same reasoning as 202611160002 (wave 1,
-- read its header): a composite key makes the database refuse a row in one
-- organization pointing at a parent in another, whoever writes it, and
-- makes the completeness of any scan of the functions irrelevant.
--
-- Tests first, failing against the live schema
-- (db/tests/cross_org_write_isolation.sql points 8, 10, 11): all 8
-- cross-org writes accepted, each with its control accepted; and an Org B
-- signed contract naming a fresh wow-lab prospect turned it 'active'
-- through public.client_effective_status (SECURITY DEFINER, reads contracts
-- by client only) -- induced the same morning, now permanent.
--
-- One layer, deliberately: no organization filter is added inside
-- client_effective_status. Mihai decided the keys; a second, reader-side
-- layer there is a separate decision, recorded in item 198's map.
--
-- Measured before writing: 0 existing cross-org references across all 8
-- keys. Delete rules kept: school_calendar_closures cascades, the rest NO
-- ACTION. Nullable keys (amends_contract_id, renewal_of,
-- payroll_period_totals.legal_entity_id) stay MATCH SIMPLE.

-- 1. The one parent without a referenceable (id, organization_id) yet.
alter table public.legal_entities add constraint legal_entities_id_organization_id_key unique (id, organization_id);

-- 2. The eight keys.
alter table public.contracts drop constraint contracts_client_id_fkey;
alter table public.contracts add constraint contracts_client_id_org_fkey
  foreign key (client_id, organization_id) references public.clients (id, organization_id);
alter table public.contracts drop constraint contracts_legal_entity_id_fkey;
alter table public.contracts add constraint contracts_legal_entity_id_org_fkey
  foreign key (legal_entity_id, organization_id) references public.legal_entities (id, organization_id);
alter table public.contracts drop constraint contracts_amends_contract_id_fkey;
alter table public.contracts add constraint contracts_amends_contract_id_org_fkey
  foreign key (amends_contract_id, organization_id) references public.contracts (id, organization_id);
alter table public.contracts drop constraint contracts_renewal_of_fkey;
alter table public.contracts add constraint contracts_renewal_of_org_fkey
  foreign key (renewal_of, organization_id) references public.contracts (id, organization_id);
alter table public.client_contacts drop constraint client_contacts_client_id_fkey;
alter table public.client_contacts add constraint client_contacts_client_id_org_fkey
  foreign key (client_id, organization_id) references public.clients (id, organization_id);
alter table public.school_calendar_closures drop constraint school_calendar_closures_client_id_fkey;
alter table public.school_calendar_closures add constraint school_calendar_closures_client_id_org_fkey
  foreign key (client_id, organization_id) references public.clients (id, organization_id) on delete cascade;
alter table public.payroll_period_totals drop constraint payroll_period_totals_legal_entity_id_fkey;
alter table public.payroll_period_totals add constraint payroll_period_totals_legal_entity_id_org_fkey
  foreign key (legal_entity_id, organization_id) references public.legal_entities (id, organization_id);
alter table public.supplier_contracts drop constraint supplier_contracts_legal_entity_id_fkey;
alter table public.supplier_contracts add constraint supplier_contracts_legal_entity_id_org_fkey
  foreign key (legal_entity_id, organization_id) references public.legal_entities (id, organization_id);

-- 3. Self-test: every one of the eight is composite with organization_id,
-- and no single-column key to the same column survives beside it.
do $$
declare
  v_missing text;
begin
  select string_agg(x.k, ', ') into v_missing
  from (values ('contracts.client_id'),
    ('contracts.legal_entity_id'),
    ('contracts.amends_contract_id'),
    ('contracts.renewal_of'),
    ('client_contacts.client_id'),
    ('school_calendar_closures.client_id'),
    ('payroll_period_totals.legal_entity_id'),
    ('supplier_contracts.legal_entity_id')) x(k)
  where not exists (
    select 1 from pg_constraint con join pg_class cl on cl.oid = con.conrelid
    where con.contype = 'f' and cl.relname = split_part(x.k, '.', 1) and array_length(con.conkey, 1) = 2
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = any (con.conkey) and a.attname = split_part(x.k, '.', 2))
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = any (con.conkey) and a.attname = 'organization_id'))
  or exists (
    select 1 from pg_constraint con join pg_class cl on cl.oid = con.conrelid
    where con.contype = 'f' and cl.relname = split_part(x.k, '.', 1) and array_length(con.conkey, 1) = 1
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = con.conkey[1] and a.attname = split_part(x.k, '.', 2)));
  if v_missing is not null then
    raise exception '202611160003 self-test: not composite with organization_id, or a single-column key survives: %', v_missing;
  end if;
end;
$$;
