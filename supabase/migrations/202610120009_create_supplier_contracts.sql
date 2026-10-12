-- ============================================================================
-- supplier_contracts -- SAD step 4, the 30 non-trainer rows of the supplier
-- contract register. Item 105 recorded this as blocked on one decision; the
-- decision is taken and written below rather than left in a comment.
-- ============================================================================
--
-- DEVIATION FROM SAD §3.3, DELIBERATE, WITH ITS REASON
-- ----------------------------------------------------
-- §3.3 specifies `contract_value numeric` and NO `rate`/`rate_unit`, on the
-- stated reasoning that "un contract de servicii are valoare, nu tarif orar".
-- **That assumption does not survive its own source.** Measured against the
-- register the spec was written for, of the 30 rows:
--
--   * most priced rows carry a RATE, not a value -- `80 RON/ORA`,
--     `400 euro/luna`, `1000 ron/trimestru`, `14.08 Euro/Ora`,
--     `10099.87 ron/curs`, `12 Eur/luna`, `80 EUR/ORA`, `75 eur/ora`
--   * two cannot be structured at all. ASISMART carries `80 RON/ORA, 90
--     RON/ORA` -- two rates with no stated rule for which applies when. Raluca
--     Margean carries three word-count tiers in one cell, as a bulleted list.
--   * `180 EURO +TVA` carries a tax qualifier, and Margean's tiers are stated
--     `net`. A numeric parse loses the +TVA, the net, and the tiering, and
--     those are the parts that decide what gets paid.
--
-- So price stays FREE TEXT, verbatim, in one column: `price_text`. The
-- precedent is `contracts.billing_rule`, which holds exactly this shape for
-- client contracts (`105 lei/copil/ședință`, `770 RON + TVA/ grupă/ ședință`)
-- and is read by people, not parsed. Nothing computes from either today.
--
-- `contract_value numeric` is KEPT, for the ten rows that carry a clean bare
-- number -- those are real and worth having structured. United Media's
-- `1928 EUR` is deliberately NOT among them: none of the ten bare numbers
-- carries a currency, so they are implicitly RON, and coercing `1928 EUR` to
-- 1928 would put euros in the same unitless column as lei with nothing able to
-- tell them apart. It stays in price_text, where the currency survives.
--
-- VALIDITY-IN-MONTHS IS NOT IMPORTED, on purpose. The register's formula
-- column errors (`#VALUE!`) on 8 rows and silently reads `0` on 5 more, and
-- the silent zeros are the worse half -- a 0 looks like an answer. It is
-- derivable from period_start and period_end whenever both exist, so storing
-- a known-wrong copy buys nothing.
create table public.supplier_contracts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id),
  legal_entity_id uuid not null references public.legal_entities(id),

  -- Both numbers, as §3.3 specifies. entry_number is Wow Lab's own (absent
  -- throughout this register -- all 30 rows are null); exit_number is the
  -- supplier's, and carries free text like `ANEXA 2` or
  -- `Act aditional 03 la contract 10/1...` as often as a number.
  entry_number text,
  exit_number text,

  signed_date date,
  period_start date,
  period_end date,

  -- `is_open_ended` beside a nullable `period_end`, because a null alone
  -- collapses two different facts the register states separately: five rows
  -- say `nedeterminat` (open-ended BY AGREEMENT) and three say `N/A` (end
  -- date NOT RECORDED). One is a property of the contract, the other a gap in
  -- the file, and a report that treats "no end date" as "runs forever" would
  -- be wrong about three rows and right about five.
  is_open_ended boolean not null default false,

  -- Self-referencing and nullable. Raluca Margean's three rows are one
  -- contract plus two amendments that chain the expiry to 2026-12-31; without
  -- this they import as three contracts, two of them apparently expired.
  -- Five chains resolve inside the register; four amendment-shaped rows name a
  -- base contract that was never entered and keep amends_contract_id null
  -- rather than pointing at a guess.
  amends_contract_id uuid references public.supplier_contracts(id),

  status text not null default 'draft',
  price_text text,
  contract_value numeric,
  drive_ref text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Same vocabulary as public.contracts, not a second one invented here.
  constraint supplier_contracts_status_check
    check (status in ('draft', 'sent', 'signed', 'expired', 'renewed')),

  -- The rule 202609020003 established for client contracts, applied here for
  -- the same reason: a signing date on something not signed is incoherent.
  -- Note the asymmetry is intentional -- status 'signed' with a NULL
  -- signed_date is allowed, which is exactly the three register rows that
  -- record a real contract whose date nobody wrote down.
  constraint supplier_contracts_signed_date_status_check
    check (signed_date is null or status in ('signed', 'expired', 'renewed')),

  -- An open-ended contract has no end date by definition. Stated as a
  -- constraint so the two columns cannot drift into saying both things.
  constraint supplier_contracts_open_ended_has_no_end_check
    check (not is_open_ended or period_end is null),

  -- A contract cannot amend itself. The chain is built by the importer and
  -- editable later; this is the one cycle cheap enough to forbid outright.
  constraint supplier_contracts_no_self_amend_check
    check (amends_contract_id is null or amends_contract_id <> id)
);

create index supplier_contracts_supplier_idx on public.supplier_contracts (organization_id, supplier_id);
create index supplier_contracts_entity_idx on public.supplier_contracts (organization_id, legal_entity_id);
create index supplier_contracts_amends_idx on public.supplier_contracts (amends_contract_id)
  where amends_contract_id is not null;

comment on table public.supplier_contracts is
  'Contracts with non-trainer suppliers -- SAD §3.3, step 4. DEVIATES from §3.3 on one point, on purpose: price is free text (price_text) because most priced rows in the source register carry a rate rather than a value, and two cannot be structured at all. contract_value is kept for the ten rows with a clean bare number. See this table''s creating migration for the measurement. Trainer contracts live in a separate table (§4): the counterparty is polymorphic and the write rule inverts.';
comment on column public.supplier_contracts.price_text is
  'The price exactly as the register states it -- `80 RON/ORA, 90 RON/ORA`, `180 EURO +TVA`, `1000 ron/trimestru`, Margean''s three word-count tiers as a bulleted list. Same shape and same purpose as contracts.billing_rule: read by a person, parsed by nothing. A numeric parse would lose the +TVA, the net, the tiering and the unit.';
comment on column public.supplier_contracts.contract_value is
  'Masked (SAD §5): visible to finance.reporting.* and the org owner, NOT to finance.operations.* -- Laura does not see supplier contracts at all (§7). Populated only for the ten source rows carrying a clean bare number, which are implicitly RON. United Media''s `1928 EUR` is deliberately excluded: there is no currency column, so storing it would mix euros into a unitless lei column.';
comment on column public.supplier_contracts.is_open_ended is
  'True only for a contract stated as `nedeterminat` in the register (five rows). Distinguishes "open-ended by agreement" from "end date not recorded" (three rows say `N/A`, one says `1 AN`, three are blank) -- a nullable period_end alone cannot tell those apart, and a renewals report would be wrong about every one of them.';
comment on column public.supplier_contracts.amends_contract_id is
  'The contract this row amends, within the same supplier and legal entity. Five chains resolve inside the register (CERISEO, FLEXIBLE/STEMplicity, ROMAN, and Margean''s two). Four amendment-shaped rows name a base contract that was never entered in the register and keep this null rather than pointing at a guess -- their parent reference survives in exit_number.';

-- ============================================================================
-- RLS -- finance.reporting.* and the platform owner, matching `suppliers`
-- ============================================================================
alter table public.supplier_contracts enable row level security;

-- NOT finance.operations.*, and that absence is the point rather than an
-- omission: SAD §5 and §7 are explicit that Laura does not see supplier
-- contracts at all, so she does not see their values either.
--
-- NO "own row" branch from suppliers.user_id, decided rather than skipped.
-- Four reasons, recorded because the symmetry with trainer_contracts makes its
-- absence look like an oversight:
--   1. Anca closed supplier-contract access on 2026-10-12 (item 110) --
--      "stays as it is". A new read path reopens a closed decision.
--   2. It would be the SECOND instance of item 107's measured cross-org leak,
--      and here the row it would leak carries contract_value, the column §5
--      masks. §5 itself says the one-clause fix deviates from the spec and
--      must be an explicit decision.
--   3. §5's trainer argument does not transfer. A trainer's own grade is a
--      fact about them they already know; a supplier contract is a negotiated
--      price between two parties, and the supplier holds their own signed copy
--      -- drive_ref points at the document they countersigned.
--   4. Five of 22 suppliers have a user_id at all, and none has asked.
-- If it is ever wanted, it ships with `and app.belongs_to_org(...)` on the
-- own-row branch from the first line.
create policy "authenticated select supplier_contracts" on public.supplier_contracts
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

-- SELECT only. No write path yet: these 30 rows arrive by migration
-- (202610120010) and no screen edits them. A write path gets its grant, its
-- policy and its row_history trigger together, in the migration that adds it.
grant select on public.supplier_contracts to authenticated;

create trigger supplier_contracts_set_updated_at
  before update on public.supplier_contracts
  for each row execute function trigger_set_updated_at();

-- row_history from the start, unlike lesson_plans: these rows carry amounts
-- and dates that Finance will correct by hand once a write path exists, and
-- item 104 records that this database cannot otherwise answer "who changed
-- this". The trigger fires BEFORE UPDATE OR DELETE only -- never on INSERT --
-- so the import itself leaves no history row, and 202610120010 is its own
-- provenance record.
create trigger supplier_contracts_row_history
  before delete or update on public.supplier_contracts
  for each row execute function row_history_capture();
