-- 202608160003_add_offer_fields_to_billing_masked_view.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain — extends
-- public.contracts_billing_masked (202608100004, corrected 202608100006,
-- extended 202608110002) with the 4 new columns from 202608160002.
--
-- entry_number/exit_number/offer_structure/ac_link are NOT financially
-- sensitive (no price/money value among them -- offer_structure names a
-- pricing MODEL, not an amount) -- added as plain passthrough columns,
-- same treatment as client_contract_number/signed_date in 202608110002.
--
-- Row-level visibility is still entirely inherited from the base table's
-- RLS (security_invoker = true, unchanged) -- this migration only adds
-- columns to the SELECT list.
--
-- Idempotent: CREATE OR REPLACE VIEW. New columns appended at the END of
-- the SELECT list -- same ordinal-position constraint explained in
-- 202608110002's own header comment.

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
  end as previous_year_value,
  c.entry_number,
  c.exit_number,
  c.offer_structure,
  c.ac_link
from public.contracts c;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule, estimated_value, and previous_year_value unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager) -- see 202608100006 for why clients.create is included. Also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant. entry_number/exit_number/offer_structure/ac_link are plain passthrough -- not financially sensitive. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) -- this view only masks the three financial columns. App code for non-finance/non-sales/non-master roles must query this view, not public.contracts directly, for any of the masked fields.';

grant select on public.contracts_billing_masked to authenticated;
