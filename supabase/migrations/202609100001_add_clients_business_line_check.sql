-- 202609100001_add_clients_business_line_check.sql
-- WOW LAB OS: clients.business_line becomes a real, defined three-value
-- field, restoring the taxonomy it was named after but never carried.
--
-- Source of the three values, quoted exactly: `wow_lab_master_analysis.md`
-- §9 "BUSINESS LINES & EVENTS" / "Three Business Lines" (2026-05-27, over
-- two months before any feedback from Anca on the phrase — see
-- docs/OPEN_ITEMS.md item 48 for the full provenance check). Confirmed by
-- Anca 2026-09-10.
--   1. Recurring Private Schools — weekly groups, full school year.
--   2. State Schools — Școala Altfel / Săptămâna Verde.
--   3. Corporate & Private Events.
-- This is a company-level service category, not a per-client fact one
-- value can capture alone (a school can buy a weekly club and a Școala
-- Altfel week at once) -- the grain question is recorded, not solved,
-- in docs/OPEN_ITEMS.md item 48's follow-up report. This migration only
-- restores the definition to the column that already exists; it does not
-- change what the column is attached to.
--
-- Verified live before writing this, not assumed from the task that
-- asked for it: `clients` holds two real rows today, not the one the
-- request named.
--   - Maxdigital (corporate) -- business_line null. Matches the premise.
--   - "Școala Franceză (Lycee Francais)" (private_school) -- business_line
--     = 'Scoli recurente', free text entered before this migration, not
--     one of the three values below. A private school named 'recurring
--     schools' maps to exactly one of the three, unambiguously --
--     backfilled below to `recurring_private_schools` rather than left to
--     violate the constraint this migration adds. Recorded here, not
--     silently folded in: this is a real client's data, changed on an
--     unambiguous but unconfirmed reading, same as any other backfill in
--     this project gets a paper trail.
--
-- Nullable stays nullable, deliberately: not every client is classified
-- yet, and a NOT NULL constraint here would block client creation on a
-- decision the person entering the client may not be ready to make.
--
-- Idempotent: the backfill is scoped to the one known-wrong current
-- value, so a second run finds no matching rows and no-ops; the
-- constraint is dropped-and-readded by name, the only way to add a CHECK
-- idempotently.

update public.clients
set business_line = 'recurring_private_schools'
where business_line = 'Scoli recurente';

do $$
begin
  if exists (
    select 1 from pg_constraint where conname = 'clients_business_line_check'
  ) then
    alter table public.clients drop constraint clients_business_line_check;
  end if;
  alter table public.clients
    add constraint clients_business_line_check
    check (business_line is null or business_line in (
      'recurring_private_schools', 'state_schools', 'corporate_events'
    ));
end;
$$;

comment on column public.clients.business_line is 'Company-level service category (WOW_LAB_OS_Solution_Architecture_Document.md''s companion wow_lab_master_analysis.md §9, "Three Business Lines", 2026-05-27; confirmed by Anca 2026-09-10): recurring_private_schools | state_schools (Scoala Altfel / Saptamana Verde) | corporate_events. Nullable -- not every client is classified yet. NOTE (docs/OPEN_ITEMS.md item 48''s follow-up): this is a company-level category a single client can hold more than one of at once (a private school with both a weekly club and a Scoala Altfel week) -- this column can only ever record one. Grain mismatch recorded, not resolved, by this migration.';
