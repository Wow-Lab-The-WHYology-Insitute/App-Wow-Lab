-- 202608180002_replace_contract_number_with_entry_exit.sql
-- WOW LAB OS — final decision on entry_number/exit_number, after two prior
-- passes on this exact question:
--   1. contract_number/client_contract_number added in C1 (202607130004-era
--      schema), sourced from Anca's real sheet data.
--   2. entry_number/exit_number added prematurely (202608160002), before
--      Anca and Anka had actually confirmed how they'd be used — rolled
--      back the same day (202608170001) with zero data loss, since no UI
--      ever exposed a way to write them.
--   3. THIS migration: Anca confirmed with Anka. entry_number/exit_number
--      REPLACE contract_number/client_contract_number outright, not
--      alongside them. exit_number becomes the primary display identifier
--      (Mihai's explicit call), with a defined UI fallback for the common
--      case where it's still unset (draft / not yet dispatched).
--
-- Data checked live before dropping (all 6 rows, the only rows that exist):
--   client_contract_number: NULL on every row -- nothing lost.
--   contract_number: "888", "DEMO-2026-001".."DEMO-2026-005" -- all either
--     the literal placeholder "888" or an explicitly-marked demo record
--     (all 5 DEMO- rows carry "Example seed record -- see migration
--     header, not a verified real contract." in notes already). No real,
--     non-demo contract_number value exists anywhere in this table today.

-- contracts_billing_masked selects contract_number and client_contract_number
-- directly (202608100004 onward) -- must drop it before the columns it
-- depends on can be dropped. CREATE OR REPLACE can't remove columns from a
-- view (SQLSTATE 42P16, hit and documented already in 202608170001) --
-- DROP + CREATE is the only path, which means the grant below is required
-- again too, same as last time.
drop view public.contracts_billing_masked;

alter table public.contracts drop column contract_number;
alter table public.contracts drop column client_contract_number;

-- Both nullable per the confirmed design: entry_number is plain text,
-- no uniqueness requirement. exit_number is the new primary identifier and
-- must be unique WHILE it's set, but a contract legitimately has none yet
-- while in draft or before formal dispatch -- a composite UNIQUE
-- constraint already permits any number of NULLs (Postgres never treats
-- NULL = NULL as a match for uniqueness purposes), so no partial index or
-- extra WHERE clause is needed to get that behavior. Scoped to
-- organization_id, mirroring the exact scoping the old
-- contracts_unique_organization_contract_number index used -- two
-- different organizations legitimately running independent numbering
-- schemes is not a collision.
alter table public.contracts add column entry_number text;
alter table public.contracts add column exit_number text;
alter table public.contracts
  add constraint contracts_unique_organization_exit_number
  unique (organization_id, exit_number);

create view public.contracts_billing_masked
with (security_invoker = true)
as
select
  id,
  organization_id,
  client_id,
  legal_entity_id,
  entry_number,
  exit_number,
  contract_type,
  period_start,
  period_end,
  status,
  renewal_of,
  case
    when app.has_capability('finance.operations.*', organization_id)
      or app.has_capability('finance.reporting.*', organization_id)
      or app.has_capability('clients.create', organization_id)
    then billing_rule
    else null
  end as billing_rule,
  drive_ref,
  notes,
  created_at,
  updated_at,
  signed_date,
  case
    when app.has_capability('finance.operations.*', organization_id)
      or app.has_capability('finance.reporting.*', organization_id)
      or app.has_capability('clients.create', organization_id)
    then estimated_value
    else null
  end as estimated_value,
  case
    when app.has_capability('finance.operations.*', organization_id)
      or app.has_capability('finance.reporting.*', organization_id)
      or app.has_capability('clients.create', organization_id)
    then previous_year_value
    else null
  end as previous_year_value,
  offer_structure,
  ac_link
from public.contracts;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule, estimated_value, and previous_year_value unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager). entry_number/exit_number replace contract_number/client_contract_number as of 202608180002 -- exit_number is the primary display identifier, nullable, unique per organization while set. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) -- this view only masks the three financial columns.';

grant select on public.contracts_billing_masked to authenticated;
