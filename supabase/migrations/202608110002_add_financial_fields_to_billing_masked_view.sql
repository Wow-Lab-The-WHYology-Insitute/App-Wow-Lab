-- 202608110002_add_financial_fields_to_billing_masked_view.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain — extends
-- public.contracts_billing_masked (202608100004, corrected 202608100006)
-- to also mask the two new financially-sensitive columns added in
-- 202608110001: estimated_value, previous_year_value. Same unmask
-- condition as billing_rule — finance.operations.*, finance.reporting.*,
-- or clients.create (sales_manager) — kept as one CASE expression per
-- masked column so the three fields can never drift out of sync with
-- each other.
--
-- client_contract_number and signed_date are NOT financially sensitive
-- (they're reference metadata, not money) and are added as plain
-- passthrough columns, same as contract_number/period_start/etc already
-- are.
--
-- Row-level visibility is still entirely inherited from the base table's
-- RLS (security_invoker = true, unchanged) — this migration only adds
-- columns to the SELECT list, it does not touch filtering.
--
-- Idempotent: CREATE OR REPLACE VIEW. All new columns are appended at the
-- END of the SELECT list — Postgres's CREATE OR REPLACE VIEW forbids
-- inserting a column in the middle (it would shift every existing
-- column's ordinal position, which errors as "cannot change name of view
-- column"), so the new columns can't sit next to their logically-related
-- existing ones (client_contract_number near contract_number, etc.) the
-- way a fresh CREATE would read. A DROP + CREATE would allow proper
-- ordering but risks a window where the view doesn't exist; not worth it
-- for pure column ordering when every app query names its columns
-- explicitly (none use `select *`).

create or replace view public.contracts_billing_masked
with (security_invoker = true)
as
select
  c.id,
  c.organization_id,
  c.client_id,
  c.legal_entity_id,
  c.contract_number,
  c.contract_type,
  c.period_start,
  c.period_end,
  c.status,
  c.renewal_of,
  case
    when app.has_capability('finance.operations.*', c.organization_id)
      or app.has_capability('finance.reporting.*', c.organization_id)
      or app.has_capability('clients.create', c.organization_id)
    then c.billing_rule
    else null
  end as billing_rule,
  c.drive_ref,
  c.notes,
  c.created_at,
  c.updated_at,
  c.client_contract_number,
  c.signed_date,
  case
    when app.has_capability('finance.operations.*', c.organization_id)
      or app.has_capability('finance.reporting.*', c.organization_id)
      or app.has_capability('clients.create', c.organization_id)
    then c.estimated_value
    else null
  end as estimated_value,
  case
    when app.has_capability('finance.operations.*', c.organization_id)
      or app.has_capability('finance.reporting.*', c.organization_id)
      or app.has_capability('clients.create', c.organization_id)
    then c.previous_year_value
    else null
  end as previous_year_value
from public.contracts c;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule, estimated_value, and previous_year_value unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager) -- see 202608100006 for why clients.create is included. Also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) -- this view only masks these three columns. App code for non-finance/non-sales/non-master roles must query this view, not public.contracts directly, for any of the three masked fields.';

grant select on public.contracts_billing_masked to authenticated;
