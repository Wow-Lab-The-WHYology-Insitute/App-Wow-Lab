-- `contracts.amends_contract_id` -- a self-referential FK, same shape as
-- `renewal_of` (202608100001) on this same table and, closer still,
-- `supplier_contracts.amends_contract_id` (202610120009, already live:
-- Raluca Margean's own amendment chain) -- "the contract THIS ROW amends."
-- Not a new mechanism, the second table to need the one that already
-- exists. Used here to split Avenor's single contract into two periods
-- under two different legal entities, item 182's real finding.
--
-- ===========================================================================
-- WHY THIS, NOT ENTITY-ON-SESSION -- THE DECISION, WITH ITS ACTUAL REASON
-- ===========================================================================
-- Item 182 wrote up two candidates and chose neither. Measured against
-- every real school in the current timesheet (105 rows), entity assignment
-- is SEQUENTIAL in every case but one:
--
--   DSBU             Experimente Wow            09.09..28.10         one entity
--   Lycee            Brandine                   07.09..13.10         one entity
--   Scoala ARC       Brandine                   19.10..20.10         one entity
--   Avenor           Experimente -> Brandine     02.09..30.09 / 07.10..28.10   sequential
--   Wow Lab Party    Brandine -> Experimente     19.09 / 31.10        sequential
--   Scoala Altfel    Brandine / STEMplicity / Experimente, CONCOMITENT across the same weeks
--
-- Scoala Altfel is the one concurrent case -- and it is concurrent only
-- because "Scoala Altfel" is not one school (item 172): 22 October alone
-- has STEMplicity/Bucharest-location rows and Brandine/"Other cities"
-- rows on the SAME day, and the location tier belongs to the school
-- (item 144) -- two location tiers the same day means two different
-- physical schools, not one school billed through two entities at once.
-- The concurrency is a symptom of the 188 empty CUIs (item 172), not a
-- property the entity model has to support. Once Altfel's rows are split
-- into their real schools, every real case left is sequential.
--
-- Entity-on-session (the other candidate) would have been the more general
-- mechanism, which is exactly why it was the wrong choice here -- generality
-- bought for a client that, per item 172, must not exist as a client.
-- Building for Scoala Altfel's apparent shape would have been a correct
-- argument resting on data this project has already decided not to import
-- as-is -- the shape item 17 names: a correct answer to the wrong question,
-- because the premise behind it was never checked against item 172's own
-- ruling. amends_contract_id -- a new contract succeeding an old one at a
-- dated boundary -- fits every real case once Altfel stops being one.
--
-- ===========================================================================
-- THE DATA: AVENOR'S SEPTEMBER PREDECESSOR
-- ===========================================================================
-- The existing contract (906de33a, Brandine, signed 2026-08-19, period
-- 2026-09-01..2027-06-30) is retreated to start 2026-10-01 -- it continues
-- to be the contract `groups.contract_id` points at, because it is the one
-- in force TODAY and going forward. A new row is created as its
-- PREDECESSOR: same client, same billing terms (the 2026-10-20 retroactive
-- price renegotiation really was retroactive to 1 September, and is not
-- touched here), different entity (Experimente Wow) and a period boxed to
-- September alone. `amends_contract_id` on the existing row points at the
-- new one.
--
-- entry_number/exit_number are NOT copied onto the new row: exit_number is
-- unique per organization (202608180002) and the existing row already
-- holds '205' for this one underlying agreement. The predecessor row is a
-- bookkeeping split of that same agreement, not a second physical
-- document, so it carries no registry number of its own.
--
-- THE CHANGEOVER DATE WAS WRITTEN HERE AS AN ASSUMPTION; CONFIRMED
-- 2026-11-09. At the time this migration was first applied, the timesheet
-- only placed September under Experimente Wow and October under Brandine,
-- with nothing finer-grained in between, so 2026-10-01 was assumed as the
-- boundary pending Anca. Anca has since confirmed, via Mihai, that the
-- switch to Brandine was from 2026-10-01 exactly -- the assumed date was
-- right. Nothing else about this migration changes; the data it wrote was
-- already correct under the assumption and remains so under the
-- confirmation.
--
-- October is untouched: it already reads Brandine, correctly, through the
-- unmodified existing row.
--
-- ===========================================================================
-- THE READ-SIDE CONSEQUENCE
-- ===========================================================================
-- Nothing stores an entity on `sessions` -- it has never been a stored fact,
-- always derived at read time from session -> group -> contract ->
-- legal_entity_id (app/(app)/payroll/page.tsx's own header). "Recalculating"
-- September is therefore a read-path change, not a data write to sessions:
-- `entityOfGroup` now walks the amends chain backward from the group's
-- current contract to find whichever link's period covers the SESSION'S
-- OWN date, instead of always reading the head contract. Shipped in the
-- same commit as this migration.

alter table public.contracts
  add column amends_contract_id uuid references public.contracts(id);

-- Same constraint, same name, as supplier_contracts_no_self_amend_check.
alter table public.contracts
  add constraint contracts_no_self_amend_check
  check (amends_contract_id is null or amends_contract_id <> id);

create index if not exists contracts_amends_idx
  on public.contracts(amends_contract_id)
  where amends_contract_id is not null;

comment on column public.contracts.amends_contract_id is
  'The contract THIS ROW amends -- same shape as supplier_contracts.amends_contract_id (202610120009) and renewal_of on this same table. Walked backward by app/(app)/payroll/page.tsx''s entityOfGroup to resolve which entity was in force on a given session''s own date, when a single client relationship spans more than one entity/price period over time. Item 182/decision: chosen over entity-on-session because every real school in the timesheet changes entity SEQUENTIALLY, not concurrently -- the one apparent counter-example (Scoala Altfel) is item 172''s unresolved identity problem, not a true concurrency.';

do $$
declare
  v_org uuid := '8e0dcc53-062f-4664-907d-826b9f45bec0';
  v_avenor_client uuid := '5847d8a4-be0c-46b4-971d-8f6052bf8ce3';
  v_existing_contract uuid := '906de33a-22d3-4832-97aa-6fbd5f6dfa41';
  v_brandine uuid := '94c8aeec-3c3c-49f0-b0f9-11a9cc71a245';
  v_experimente_wow uuid := 'b684d1a5-6cba-4a10-94fe-5eab9318dc60';
  v_existing record;
  v_new_contract uuid;
  v_switchover date := '2026-10-01'; -- CONFIRMED by Anca via Mihai, 2026-11-09 (written as an assumption at first apply -- see header).
begin
  select * into v_existing from public.contracts where id = v_existing_contract;
  if v_existing.id is null then
    raise exception 'amends-contract-id: Avenor contract % no longer exists -- re-verify before applying', v_existing_contract;
  end if;
  if v_existing.client_id <> v_avenor_client then
    raise exception 'amends-contract-id: contract % does not belong to client %', v_existing_contract, v_avenor_client;
  end if;
  if v_existing.legal_entity_id <> v_brandine or v_existing.period_start <> '2026-09-01' or v_existing.amends_contract_id is not null then
    raise exception 'amends-contract-id: Avenor contract %''s current state (entity %, period_start %, amends_contract_id %) is not what this migration expects -- someone has already touched it',
      v_existing_contract, v_existing.legal_entity_id, v_existing.period_start, v_existing.amends_contract_id;
  end if;

  -- The predecessor: same agreement, Experimente Wow, boxed to September.
  insert into public.contracts (
    organization_id, client_id, legal_entity_id, contract_type, period_start, period_end,
    status, billing_rule, drive_ref, notes, signed_date, estimated_value, previous_year_value,
    offer_structure, ac_link, entry_number, exit_number, amends_contract_id, renewal_of
  )
  values (
    v_org, v_avenor_client, v_experimente_wow, v_existing.contract_type, '2026-09-01', v_switchover - 1,
    v_existing.status, v_existing.billing_rule, v_existing.drive_ref,
    'Predecesor construit 2026-11-09 (item 182) din contractul ' || v_existing_contract::text ||
      ': aceeasi intelegere, entitate Experimente Wow, septembrie 2026 doar. Data comutarii (' ||
      v_switchover::text || ') e o presupunere, de confirmat cu Anca -- vezi item 182.',
    v_existing.signed_date, v_existing.estimated_value, v_existing.previous_year_value,
    v_existing.offer_structure, v_existing.ac_link, null, null, null, null
  )
  returning id into v_new_contract;

  update public.contracts
    set period_start = v_switchover,
        amends_contract_id = v_new_contract
    where id = v_existing_contract;

  raise notice 'amends-contract-id: Avenor predecessor % created (Experimente Wow, 2026-09-01..%), existing contract % retreated to start % and now amends it.',
    v_new_contract, v_switchover - 1, v_existing_contract, v_switchover;
end $$;

-- ---------------------------------------------------------------------------
-- Assertions: the chain resolves to the right entity on real session dates.
-- ---------------------------------------------------------------------------
do $$
declare
  v_existing_contract uuid := '906de33a-22d3-4832-97aa-6fbd5f6dfa41';
  v_experimente_wow uuid := 'b684d1a5-6cba-4a10-94fe-5eab9318dc60';
  v_predecessor uuid;
  v_sept_resolved uuid;
  v_oct_resolved uuid;
  v_n integer;
begin
  select amends_contract_id into v_predecessor from public.contracts where id = v_existing_contract;
  if v_predecessor is null then
    raise exception 'amends-contract-id: existing contract has no amends_contract_id after the migration';
  end if;

  if (select legal_entity_id from public.contracts where id = v_predecessor) <> v_experimente_wow then
    raise exception 'amends-contract-id: predecessor contract is not Experimente Wow';
  end if;
  if (select period_start from public.contracts where id = v_existing_contract) <> '2026-10-01' then
    raise exception 'amends-contract-id: existing contract did not retreat to 2026-10-01';
  end if;
  if (select exit_number from public.contracts where id = v_predecessor) is not null then
    raise exception 'amends-contract-id: predecessor must not carry the existing exit_number (unique per org)';
  end if;

  -- Mirrors the TS walk in app/(app)/payroll/page.tsx's contractForDate:
  -- start at the head contract, step to amends_contract_id while the date
  -- is earlier than the current link's own period_start. A September date
  -- resolves to the predecessor (Experimente Wow); an October date resolves
  -- to the existing row (Brandine), untouched.
  with recursive chain as (
    select id, period_start, amends_contract_id, 0 as depth
    from public.contracts where id = v_existing_contract
    union all
    select c.id, c.period_start, c.amends_contract_id, chain.depth + 1
    from chain join public.contracts c on c.id = chain.amends_contract_id
    where date '2026-09-02' < chain.period_start and chain.depth < 20
  )
  select id into v_sept_resolved from chain order by depth desc limit 1;
  if v_sept_resolved <> v_predecessor then
    raise exception 'amends-contract-id: 2026-09-02 did not resolve to the predecessor contract';
  end if;

  with recursive chain as (
    select id, period_start, amends_contract_id, 0 as depth
    from public.contracts where id = v_existing_contract
    union all
    select c.id, c.period_start, c.amends_contract_id, chain.depth + 1
    from chain join public.contracts c on c.id = chain.amends_contract_id
    where date '2026-10-07' < chain.period_start and chain.depth < 20
  )
  select id into v_oct_resolved from chain order by depth desc limit 1;
  if v_oct_resolved <> v_existing_contract then
    raise exception 'amends-contract-id: 2026-10-07 did not resolve to the existing (Brandine) contract';
  end if;

  select count(*) into v_n from public.sessions s
  join public.groups g on g.id = s.group_id
  where g.contract_id = v_existing_contract and s.session_date >= '2026-09-01' and s.session_date < '2026-10-01';
  raise notice 'amends-contract-id: % September Avenor sessions now resolve to Experimente Wow via the predecessor; October is unchanged.', v_n;
end $$;
