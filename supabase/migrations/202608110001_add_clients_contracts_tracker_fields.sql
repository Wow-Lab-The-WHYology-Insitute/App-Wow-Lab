-- 202608110001_add_clients_contracts_tracker_fields.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain — real gap found by
-- cross-checking against Wow Lab's actual, currently-used Google Sheets
-- contract tracker. Mihai confirmed: add all of the below now, in one
-- migration.
--
-- clients:
--   legal_name — formal company/foundation name, distinct from the
--     existing `name` (which stays as the school/operating name, e.g.
--     "Cambridge School" vs legal_name "KINGS OAK BRITISH INTERNATIONAL
--     SCHOOL S.R.L."). Two separate columns per Mihai's explicit decision
--     — not a rename, not a "prefer one" collapse.
--   cui — not every client type has one (nullable).
--
-- contracts:
--   client_contract_number — the CLIENT's own reference number for this
--     contract, distinct from our own `contract_number`.
--   signed_date — distinct from period_start; can predate it (a contract
--     can be signed before its coverage period begins).
--   estimated_value, previous_year_value — FINANCIALLY SENSITIVE, same
--     masking requirement as billing_rule. Added to
--     public.contracts_billing_masked's unmask condition in the next
--     migration (202608110002) — do not read these two columns from the
--     raw table anywhere non-finance-facing.
--
-- All nullable: no backfill obligation for existing rows (the C1 demo
-- rows and any real rows created before this migration).
--
-- Idempotent: `add column if not exists`.

alter table public.clients
  add column if not exists legal_name text,
  add column if not exists cui text;

comment on column public.clients.legal_name is 'Formal company/foundation name (e.g. for invoicing/legal purposes), distinct from the operating name in `name`. Nullable — not confirmed for every client.';
comment on column public.clients.cui is 'Romanian tax/registration id (Cod Unic de Inregistrare). Nullable — not every client type has one (e.g. parent_b2c).';

alter table public.contracts
  add column if not exists client_contract_number text,
  add column if not exists signed_date date,
  add column if not exists estimated_value numeric,
  add column if not exists previous_year_value numeric;

comment on column public.contracts.client_contract_number is 'The CLIENT''s own reference number for this contract (their filing system), distinct from our own contract_number.';
comment on column public.contracts.signed_date is 'Date the contract was actually signed. Distinct from period_start -- a contract can be signed before its coverage period begins.';
comment on column public.contracts.estimated_value is 'FINANCIALLY SENSITIVE -- masked the same way as billing_rule. Estimated total contract value. See public.contracts_billing_masked (202608110002) for the masking condition; never select this column from the raw table for a non-finance-facing query.';
comment on column public.contracts.previous_year_value is 'FINANCIALLY SENSITIVE -- masked the same way as billing_rule. Previous year''s actual invoiced value. See public.contracts_billing_masked (202608110002) for the masking condition; never select this column from the raw table for a non-finance-facing query.';
