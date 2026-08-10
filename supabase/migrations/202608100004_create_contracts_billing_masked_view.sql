-- 202608100004_create_contracts_billing_masked_view.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — field-level masking
-- for contracts.billing_rule (SAD §6: "valoarea contractului / billing_rule
-- / marja -> vizibile doar Finance + Master; ascunse pentru Operations/
-- Community/Trainer chiar dacă văd fișa clientului").
--
-- security_invoker = true (Postgres 15+) is load-bearing: without it, a view
-- checks privileges/RLS as the VIEW OWNER (whoever ran this migration —
-- typically `postgres`, which bypasses RLS), not the querying user, which
-- would silently leak every row to every caller regardless of the base
-- table's record-level policy. With security_invoker, the view re-applies
-- the caller's own RLS on the underlying `contracts` SELECT, so row
-- visibility still comes entirely from 202608100003's record-level policy —
-- this view ONLY adds the billing_rule column masking on top.
--
-- Unmask condition: finance.operations.* OR finance.reporting.*. This
-- already covers platform_owner and organization_owner without a separate
-- check — has_capability() itself returns true unconditionally for
-- app.is_platform_owner(), and organization_owner holds every non-platform.*
-- capability (including both finance.* keys) via the B4 seed's dynamic
-- grant. It does NOT cover sales_manager — the task's own masking spec
-- listed only finance capabilities as an "e.g." example, and the SAD (§6)
-- is explicit that billing_rule is visible "doar Finance + Master", which
-- reads as exhaustive. This appears to conflict with the older,
-- team-confirmed decision in docs/progress.md #25 ("Sales Manager vede
-- regula de facturare pt TOTI clientii activi") from the mockup-feedback
-- round. The SAD is the more specific and more recent artifact for this
-- exact domain, so this migration follows it — but the conflict is real and
-- flagged in the final report for Mihai to resolve explicitly, not buried.
--
-- Real app queries for any role that isn't finance/master should read from
-- this view, not the raw `contracts` table, per the task's own instruction
-- — the base table itself is NOT column-restricted (see the comment on
-- contracts.billing_rule in 202608100001), so this is an application-layer
-- contract, not a hard database-level guarantee. Documented explicitly, not
-- silently assumed.
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
    then c.billing_rule
    else null
  end as billing_rule,
  c.drive_ref,
  c.notes,
  c.created_at,
  c.updated_at
from public.contracts c;

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule unless the caller holds finance.operations.* or finance.reporting.* (which also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant). Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) — this view only masks the one column. App code for non-finance/non-master roles must query this view, not public.contracts directly.';

grant select on public.contracts_billing_masked to authenticated;
