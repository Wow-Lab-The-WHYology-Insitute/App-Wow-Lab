-- 202608190001_contracts_field_masking.sql
-- WOW LAB OS — Field masking, step 1 of 6: public.contracts.
-- Spec: docs/WOWLAB_SAD_Field_Masking.md, section 3 (mechanism), section 5
-- (traps this migration exists to avoid), section 7 (rollout order: this
-- table first — mechanism proven, decision made, view already exists).
--
-- Problem this closes (SAD section 1, verified live): authenticated has
-- table-level SELECT on public.contracts, so any session can bypass
-- contracts_billing_masked's masking by querying the base table directly.
-- The view's own masking was always correct — the base table was the open
-- door behind it.
--
-- Column list note: SAD section 2.1's literal 18-column list still names
-- contract_number/client_contract_number, which predate this migration's
-- writing — those two were dropped and replaced by entry_number/exit_number
-- in 202608180002, also written 2026-08-18 but after the SAD doc. This
-- migration grants the CURRENT live 18 non-financial columns (confirmed via
-- information_schema.columns against the linked project, not copied from
-- the doc): id, organization_id, client_id, legal_entity_id, contract_type,
-- period_start, period_end, status, renewal_of, drive_ref, notes,
-- created_at, updated_at, signed_date, offer_structure, ac_link,
-- entry_number, exit_number. Same count (18), different two names.

-- ============================================================================
-- 3.1 — dedicated role owning the masking function.
--
-- NOLOGIN: never a session identity, only ever a function owner.
-- NOBYPASSRLS: the entire point (SAD 5.5) — postgres has BYPASSRLS in this
--   project despite not being a superuser; a SECURITY DEFINER function
--   owned by postgres would skip org isolation entirely. This role must not
--   repeat that mistake.
-- INHERIT: not optional (SAD 5.1, proven live: a NOINHERIT member of
--   authenticated does not satisfy `TO authenticated` policies — the view
--   returned zero rows for everyone, Finance included, not a leak but a
--   silent outage). Without INHERIT, membership in authenticated below is
--   inert and this function's own read of public.contracts would find
--   nothing, since public.contracts is FORCE ROW LEVEL SECURITY and no
--   policy is written `TO app_masking_owner` directly.
--
-- Membership in authenticated is required for the same reason INHERIT is:
-- when this role's SECURITY DEFINER function queries public.contracts, the
-- row it's evaluated against is gated by the `authenticated select
-- contracts` policy (202608100003). That policy is scoped `TO
-- authenticated` by name, not `TO public` — a role outside that membership
-- satisfies no policy at all under FORCE RLS and sees zero rows,
-- regardless of what request.jwt.claims says. The double predicate inside
-- the function (belongs_to_org + capability, SAD 3.1) is the real security
-- boundary; this membership is what lets the function's own row lookup
-- reach the row in the first place so that predicate has something to
-- evaluate.
create role app_masking_owner with nologin nobypassrls inherit;
grant authenticated to app_masking_owner;

-- Trap 5.4, adapted: the SAD's own text names "schema public" because that
-- trap was found against the (rejected, section 4) view-ownership-transfer
-- alternative, where the view itself lives in public. This implementation
-- keeps the view's ownership untouched (3.2) — the object actually being
-- assigned a new owner here is the function in schema app, so the schema
-- that needs USAGE + CREATE for the new owner is app, not public. USAGE
-- alone would already be inherited via the authenticated grant above
-- (authenticated already holds USAGE on schema app); CREATE is the piece
-- authenticated does not have and this role needs, to legally own an
-- object there. Both stated explicitly rather than relying on inheritance
-- for half of it, so this migration is legible on its own.
grant usage, create on schema app to app_masking_owner;

-- Direct, explicit grant on exactly the three masked columns (plus the two
-- the function's own predicate needs to read: id to find the row,
-- organization_id for belongs_to_org). Deliberately not inherited from
-- authenticated's grant below — that grant excludes these three columns by
-- design; this role's whole purpose is to be the one reader that still can,
-- under its own function's gate, not under a blanket table grant.
grant select (id, organization_id, billing_rule, estimated_value, previous_year_value)
  on public.contracts to app_masking_owner;

-- ============================================================================
-- 3.1 — the masking function itself. Verbatim from the SAD.
--
-- The predicate is double, not single: it checks both that the row's own
-- organization_id belongs to the caller (app.belongs_to_org) AND that the
-- caller holds one of the three unmask capabilities IN THAT SAME
-- organization. organization_id is read from the row, by id, inside the
-- function — never accepted as a parameter. This closes the oracle
-- scenario (SAD 3.1 / 5.3): a Finance caller in org A who supplies an id
-- belonging to org B is checked against their real membership in B (which
-- they don't have), not against whatever id they passed in — they get
-- null, not org B's numbers.
create function app.masked_contract_financials(target_contract_id uuid)
returns record
language sql
security definer
set search_path = ''
as $$
  select case
    when app.belongs_to_org(c.organization_id)
     and (
       app.has_capability('finance.operations.*', c.organization_id)
       or app.has_capability('finance.reporting.*', c.organization_id)
       or app.has_capability('clients.create', c.organization_id)
     )
    then row(c.billing_rule, c.estimated_value, c.previous_year_value)
    else null
  end
  from public.contracts c
  where c.id = target_contract_id;
$$;

-- ALTER ... OWNER TO requires the assigning role to be able to SET ROLE to
-- the target role — postgres is not automatically a member of a role it
-- just created. Granted just long enough for the transfer, then revoked;
-- app_masking_owner needs nothing further from postgres once it owns the
-- function.
grant app_masking_owner to postgres;
alter function app.masked_contract_financials(uuid) owner to app_masking_owner;
revoke app_masking_owner from postgres;

-- Defense in depth alongside schema app's non-exposure to PostgREST
-- (verified live in the SAD, section 3.1: Accept-Profile: app → 406
-- PGRST106). New functions get EXECUTE granted to PUBLIC by default in
-- Postgres — revoked explicitly here rather than left to that default, so
-- the only path to this function is the one the view uses. authenticated
-- still needs EXECUTE: the view stays security_invoker (3.2), so the
-- lateral call below runs under the CALLING role's privileges, not the
-- function owner's — the caller needs its own standing permission to
-- invoke it at all, security definer or not.
revoke execute on function app.masked_contract_financials(uuid) from public;
grant execute on function app.masked_contract_financials(uuid) to authenticated;

-- ============================================================================
-- 3.2 — the view. security_invoker stays true, untouched. Org isolation
-- keeps resolving through the caller's own grants on public.contracts (the
-- same RLS policy every other read on this table already goes through) —
-- this migration does not introduce a second, parallel isolation
-- mechanism. One function call per row via cross join lateral, not one
-- call per masked column (the prior CASE-per-column form made up to nine
-- has_capability calls per row; this makes three, inside one function
-- call, evaluated once).
--
-- Column list, order, names, and types are identical to the immediately
-- prior definition (202608180002) — only billing_rule/estimated_value/
-- previous_year_value change from an inline CASE to the lateral join's
-- output, so this is CREATE OR REPLACE, not DROP + CREATE (no column is
-- removed, renamed, retyped, or reordered — Postgres accepts changing an
-- existing column's defining expression in place). A table alias (c) is
-- introduced for the base table, required now that billing_rule etc. would
-- otherwise be ambiguous between public.contracts' own column and the
-- lateral join's output column of the same name.
create or replace view public.contracts_billing_masked
with (security_invoker = true)
as
select
  c.id,
  c.organization_id,
  c.client_id,
  c.legal_entity_id,
  c.entry_number,
  c.exit_number,
  c.contract_type,
  c.period_start,
  c.period_end,
  c.status,
  c.renewal_of,
  f.billing_rule,
  c.drive_ref,
  c.notes,
  c.created_at,
  c.updated_at,
  c.signed_date,
  f.estimated_value,
  f.previous_year_value,
  c.offer_structure,
  c.ac_link
from public.contracts c
cross join lateral app.masked_contract_financials(c.id)
  as f(billing_rule text, estimated_value numeric, previous_year_value numeric);

comment on view public.contracts_billing_masked is 'SECURITY INVOKER view over contracts: nulls billing_rule, estimated_value, and previous_year_value unless the caller holds finance.operations.*, finance.reporting.*, or clients.create (sales_manager), resolved once per row via app.masked_contract_financials() (SECURITY DEFINER, owned by app_masking_owner -- a NOLOGIN/NOBYPASSRLS/INHERIT role, never postgres, see docs/WOWLAB_SAD_Field_Masking.md 3.1/5.5) rather than a CASE per column. Also covers platform_owner/organization_owner via has_capability()''s own bypass + the B4 dynamic grant. Row visibility is inherited unchanged from the base table''s RLS policy (202608100003) via this view''s own security_invoker=true -- this view only masks the three financial columns. As of 202608190001, public.contracts itself no longer grants authenticated SELECT on these three columns at all (see below) -- this view, not the base table, is the only path to them for non-privileged callers. App code for non-finance/non-sales/non-master roles must query this view, not public.contracts directly, for any of the masked fields -- and after this migration, direct base-table reads of these three columns fail for everyone, finance included.';

-- ============================================================================
-- 3.3 — grants on the base table. Order is not cosmetic (trap 5.2, proven
-- live with has_column_privilege() on a throwaway table): a column-level
-- REVOKE cannot retract a table-level GRANT, because no column-level grant
-- was ever issued for it to retract — the migration would run, report
-- success, and change nothing. REVOKE the table-level grant FIRST, then
-- GRANT the allowed columns explicitly, by name, no wildcard. A column
-- added later does not automatically become readable — that's intentional
-- (SAD 2.1): a new column's visibility is a decision, not a default.
--
-- INSERT and UPDATE on public.contracts are untouched — their policies
-- (202608100003) already gate on capability, not just org membership, and
-- this migration's own verification (assertion 5) confirms the
-- addContract/markContractSigned .select("id") pattern still works, since
-- id is one of the 18 columns below.
revoke select on public.contracts from authenticated;

grant select (
  id, organization_id, client_id, legal_entity_id, contract_type,
  period_start, period_end, status, renewal_of, drive_ref, notes,
  created_at, updated_at, signed_date, offer_structure, ac_link,
  entry_number, exit_number
) on public.contracts to authenticated;
