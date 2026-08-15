-- 202608170001_remove_premature_entry_exit_number.sql
-- WOW LAB OS: rollback of contracts.entry_number/exit_number
-- (202608160002), added prematurely.
--
-- These two columns were added from an earlier version of a live-feedback
-- task prompt, before Mihai's follow-up clarified that this specific
-- decision was still pending between Anca and Anka — not confirmed scope
-- yet. Caught and corrected the same day, before any UI ever exposed a way
-- to WRITE either column (they were read-only Kv rows on the contract
-- detail page) and before any real data was entered — confirmed live
-- immediately before this migration: 0 of 6 contracts had either column
-- set. Zero data-loss impact. Recorded here (rather than silently editing
-- 202608160002/202608160003 in place) so migration history stays an
-- honest record of what actually happened, per this codebase's
-- established convention of never editing an already-applied migration.
--
-- offer_structure/ac_link/contact_purpose from that same original
-- migration are NOT part of this rollback -- those were confirmed, real
-- scope and stay.
--
-- Order matters: the view (202608160003) selects these two columns, so it
-- has to be rebuilt WITHOUT them before the columns themselves can be
-- dropped -- otherwise the DROP COLUMN would fail (view still depends on
-- them) or leave the view broken. CREATE OR REPLACE VIEW cannot remove a
-- column that existed in the prior definition (only add at the end, or
-- change an existing column's expression in place) -- confirmed live via
-- the actual error (SQLSTATE 42P16, "cannot drop columns from view") when
-- first attempting this as a plain CREATE OR REPLACE. DROP + CREATE
-- instead, both inside this migration's own transaction, so there's no
-- window where the view is actually missing to any concurrent query.

drop view if exists public.contracts_billing_masked;

create view public.contracts_billing_masked
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
  c.offer_structure,
  c.ac_link
from public.contracts c;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule, estimated_value, and previous_year_value unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager) -- see 202608100006 for why clients.create is included. Also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant. offer_structure/ac_link are plain passthrough -- not financially sensitive. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) -- this view only masks the three financial columns. App code for non-finance/non-sales/non-master roles must query this view, not public.contracts directly, for any of the masked fields.';

grant select on public.contracts_billing_masked to authenticated;

alter table public.contracts
  drop column if exists entry_number,
  drop column if exists exit_number;
