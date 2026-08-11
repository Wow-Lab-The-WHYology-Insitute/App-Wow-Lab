-- 202608110003_backfill_real_client_legal_data.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain — backfills legal_name
-- and cui for Wow Lab's 5 existing demo clients with their REAL legal
-- identifiers, sourced directly from Wow Lab's actual, currently-used
-- Google Sheets contract tracker.
--
-- IMPORTANT — data provenance, do not confuse with the demo contract data:
-- these 5 clients (rows in public.clients) are the same demo client rows
-- created by earlier C1/C2 seed migrations, and this migration backfills
-- REAL, verifiable legal_name/cui values onto them. This is UNRELATED to
-- and does NOT change the DEMO- prefixed contract_number values, dates, or
-- pricing on public.contracts — those remain illustrative placeholder data
-- from the C2 seed and are not sourced from the real tracker.
--
-- Confidence: 4 of 5 rows (Cambridge School, IBSB, King's Oak, Lycée
-- Français) are taken directly from actual contract rows in the tracker —
-- high confidence. Zitec's cui was found only in an aggregate reference
-- list in the tracker, not on an actual contract row for Zitec — LOWER
-- CONFIDENCE, worth Mihai double-checking against the real Zitec contract
-- when one exists. Zitec has no legal_name given (left null).
--
-- Idempotent: plain UPDATE keyed on (organization_id, name) is safe to
-- re-run — same inputs always produce the same result. Scoped to the
-- 'wow-lab' organization so this can never accidentally touch another
-- org's same-named client.

update public.clients
set legal_name = 'FUNDATIA MATEAS',
    cui = '35807977'
where organization_id = (select id from public.organizations where slug = 'wow-lab')
  and name = 'Cambridge School';

update public.clients
set legal_name = 'FUNDATIA INTERNATIONAL BRITISH SCHOOL OF BUCHAREST',
    cui = 'RO13212072'
where organization_id = (select id from public.organizations where slug = 'wow-lab')
  and name = 'IBSB';

update public.clients
set legal_name = 'KINGS OAK BRITISH INTERNATIONAL SCHOOL S.R.L.',
    cui = 'RO42686827'
where organization_id = (select id from public.organizations where slug = 'wow-lab')
  and name = 'King''s Oak';

update public.clients
set legal_name = 'FUNDATIA LYCEE FRANCAIS ANNA DE NOAILLES',
    cui = '18153988'
where organization_id = (select id from public.organizations where slug = 'wow-lab')
  and name = 'Lycée Français';

-- LOWER CONFIDENCE: cui only, found in an aggregate reference list rather
-- than an actual Zitec contract row in the tracker. No legal_name given.
update public.clients
set cui = 'RO15496736'
where organization_id = (select id from public.organizations where slug = 'wow-lab')
  and name = 'Zitec';
