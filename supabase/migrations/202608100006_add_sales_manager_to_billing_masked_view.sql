-- 202608100006_add_sales_manager_to_billing_masked_view.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — correction to
-- public.contracts_billing_masked (202608100004).
--
-- 202608100004 followed the SAD's original §6 wording ("billing_rule
-- vizibile doar Finance + Master") literally, unmasking only for
-- finance.operations.*/finance.reporting.*. That was flagged at the time as
-- a probable conflict with the already-confirmed team decision in
-- docs/progress.md #25 ("Sales Manager vede regula de facturare pt TOTI
-- clientii activi", confirmed by Anca/Laura during the mockup-feedback
-- round) — not silently resolved either way, left for Mihai to call.
--
-- Mihai has now confirmed: progress.md #25 is the decision that stands.
-- docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md §6 has been amended in
-- place (a dated correction note, not a silent rewrite) to match. This
-- migration brings the view in line with the corrected SAD.
--
-- sales_manager is identified the same way the RLS policies in
-- 202608100003 already identify them for other purposes: the
-- 'clients.create' capability, which only sales_manager holds (per the B4
-- seed). This already covers platform_owner/organization_owner too, same
-- as the finance branches, via has_capability()'s own is_platform_owner()
-- bypass + the B4 seed's dynamic "all non-platform.* capabilities" grant to
-- organization_owner.
--
-- Idempotent: CREATE OR REPLACE VIEW.

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
  c.updated_at
from public.contracts c;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager) -- the last one added in 202608100006 per docs/progress.md #25, correcting 202608100004''s original finance-only condition. Also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) -- this view only masks the one column. App code for non-finance/non-sales/non-master roles must query this view, not public.contracts directly.';
