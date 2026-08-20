-- 202608190002_contracts_field_masking_rollback.sql
-- Rollback of 202608190001_contracts_field_masking.sql.
--
-- Per docs/WOWLAB_SAD_Field_Masking.md, section 6.2: written in the same
-- commit as the forward migration, not "theoretically reversible" — this
-- file is itself run inside a rolled-back transaction as part of
-- scripts/verify_contracts_field_masking.sql before either migration is
-- ever applied for real. Without Supabase Branching (no Pro plan, section
-- 6), this file is the only safety net if 202608190001 needs to come back
-- out after being applied live.
--
-- Order is the exact reverse of the forward migration, with one hard
-- constraint: the view must stop referencing app.masked_contract_financials
-- before that function can be dropped (Postgres will not drop a function a
-- view still depends on) — so grants, then view, then function, then role,
-- not role-first symmetry.
--
-- The view and its grant/comment below are copied verbatim from
-- 202608180002_replace_contract_number_with_entry_exit.sql (the immediately
-- prior definition) — DROP + CREATE, matching that migration's own choice,
-- not CREATE OR REPLACE, so this file is a byte-faithful replay of the last
-- known-good state rather than a diff against it.

-- ============================================================================
-- 3.3 reversal — restore the plain table-level grant. REVOKE the
-- column-level grant first (removing those column ACL entries entirely,
-- not leaving them as redundant residue once the table-level grant below
-- supersedes them), then GRANT back the original, unqualified table-level
-- SELECT — the exact grant confirmed live before 202608190001 ran
-- (information_schema.role_table_grants showed a single table-level SELECT
-- row for authenticated, not per-column entries).
revoke select (
  id, organization_id, client_id, legal_entity_id, contract_type,
  period_start, period_end, status, renewal_of, drive_ref, notes,
  created_at, updated_at, signed_date, offer_structure, ac_link,
  entry_number, exit_number
) on public.contracts from authenticated;

grant select on public.contracts to authenticated;

-- ============================================================================
-- 3.2 reversal — restore the pre-202608190001 view: masking via an inline
-- CASE per financial column, no lateral join, no function dependency.
drop view public.contracts_billing_masked;

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

-- ============================================================================
-- 3.1 reversal — drop the function (now safe: the view above no longer
-- references it), then the role that owned it. Explicit REVOKEs before
-- DROP ROLE are not strictly required (DROP ROLE already strips a role
-- from every other object's ACL automatically; only ownership blocks it,
-- and the function drop above already clears that) -- kept anyway so this
-- file states, in the open, exactly what it is undoing, symmetric with how
-- the forward migration states what it's granting.
drop function app.masked_contract_financials(uuid);

revoke select (id, organization_id, billing_rule, estimated_value, previous_year_value)
  on public.contracts from app_masking_owner;
revoke usage, create on schema app from app_masking_owner;
revoke authenticated from app_masking_owner;

drop role app_masking_owner;
