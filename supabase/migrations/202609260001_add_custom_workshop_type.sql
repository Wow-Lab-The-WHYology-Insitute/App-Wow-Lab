-- ============================================================================
-- Custom returns as a TENTH workshop type -- Anca, 2026-09-25.
-- ============================================================================
-- 202609210006 removed 'custom' four days ago, and said why in writing:
--
--   "No catch-all/escape-hatch value -- item 79 already flagged this as a
--    real structural gap (custom's old role has no equivalent here), and
--    Anca's decision was 'these nine replace the six,' not 'these nine plus
--    a fallback.' Not invented here; if a workshop genuinely doesn't fit
--    any of the nine, that is now a real gap to surface, not silently
--    absorbed."
--
-- That reasoning was correct at the time and is now superseded by the
-- person it deferred to. The gap WAS surfaced, exactly as intended, and
-- Anca answered it: Custom comes back. This migration is that answer, not
-- a reversal of a decision on our own authority.
--
-- Note the asymmetry with the removal: 'custom' was dropped in 202609210006
-- because ZERO live rows used it, so dropping it cost nothing. Adding it
-- back costs nothing either, for the same reason -- no row can become
-- invalid by WIDENING a CHECK constraint. This is a strictly additive
-- change; unlike its predecessor it rewrites no data at all.
--
-- ============================================================================
-- NO BEHAVIOURAL CHANGE IS NEEDED, AND THAT IS A FINDING, NOT AN OMISSION
-- ============================================================================
-- Both places this app branches on delivery_format are POSITIVE tests
-- against explicit values, never negative or substring tests. 'custom'
-- therefore lands on the correct side of each by construction, with no
-- edit -- confirmed by reading both, not assumed:
--
-- 1. app.resolve_duration_multiplier (202608310002) --
--       case when p_delivery_format in ('scoala_altfel','saptamana_verde')
--            then 'scoala_altfel_saptamana_verde' else 'standard' end
--    'custom' -> 'standard'. Correct: the scoala_altfel_saptamana_verde
--    context exists because those two NAMED national programmes pay x2.0
--    at 120 minutes instead of x1.5. It is keyed to a specific programme
--    schedule, not to "unusual" or "bespoke". Custom is by definition
--    neither programme, so it cannot inherit a multiplier that exists
--    because of them.
--
--    A second, concrete reason beyond semantics: 'standard' is seeded with
--    a 30-minute row and 'scoala_altfel_saptamana_verde' is NOT. Had custom
--    mapped to the programme context, a 30-minute custom workshop would
--    raise "version has no row for 30 minutes / context
--    scoala_altfel_saptamana_verde -- incomplete version". Standard is both
--    correct AND the only complete option.
--
--    This matters more than it did on 2026-09-21: app.calculate_session_pay
--    (202609250001) now CALLS this resolver, so the duration context is a
--    pay-affecting path, not the dormant one item 79 measured. Nothing
--    calls calculate_session_pay yet, so no pay moves today -- but the
--    assertion is worth a test, and db/tests/custom_workshop_type.sql has
--    one. It asserts behaviour this migration does NOT change, precisely
--    because that behaviour is now load-bearing.
--
-- 2. The "recurring" distinction (trainer-resources-section.tsx line 33,
--    groups-client.tsx line 748) -- both are `=== "scoli_private_recurente"`.
--    'custom' is one-off on both, which is correct: a custom workshop has
--    no recurring schedule pattern, so the create form must not offer one
--    and the trainer gets the one-off resources caption. 202609210006's own
--    column comment already committed to this reading -- "means
--    scoli_private_recurente ONLY ... not by a 'recurring' substring
--    check" -- and 'custom' is exactly the case that rule was written to
--    survive.
--
-- ============================================================================
-- THE CONSTRAINT
-- ============================================================================
-- Drop-then-add in one transaction, same ordering and same reasoning as
-- 202609210006: the column is never left unconstrained across a
-- transaction boundary. Unlike that migration there are no UPDATEs
-- between the two statements -- nothing to migrate.
--
-- 'custom' as the key: ASCII snake_case per Mihai's standing instruction,
-- and it is the SAME literal string the pre-2026-09-21 six-value list
-- used. Reusing it rather than minting a new one is deliberate -- same
-- reasoning 202609210006 applied to scoala_altfel/saptamana_verde keeping
-- their keys, and item 83's to paused/churned surviving the status
-- rename: the value did not change meaning, it changed status.
--
-- Placed LAST in the list, after party_companii, rather than sorted in.
-- The nine are Anca's list in her own order; custom is a later addition
-- and reads as one. The app's FORMAT_KEYS array matches this order.
alter table public.groups drop constraint groups_delivery_format_check;

alter table public.groups
  add constraint groups_delivery_format_check
  check (delivery_format in (
    'scoala_altfel',
    'saptamana_verde',
    'wow_lab_party',
    'parteneriate_companii',
    'cursuri_deschise',
    'scoli_private_ocazionale',
    'scoli_private_recurente',
    'evenimente_mall',
    'party_companii',
    'custom'
  ));

comment on column public.groups.delivery_format is
  'Anca''s nine workshop types (2026-09-21, item 79/85) PLUS custom, restored as a tenth on 2026-09-25 (item 102) after 202609210006 removed it for having zero live rows: scoala_altfel, saptamana_verde, wow_lab_party, parteneriate_companii, cursuri_deschise, scoli_private_ocazionale, scoli_private_recurente, evenimente_mall, party_companii, custom. The module+delivery_format SPLIT itself (vs. a single "Tip atelier" field) remains Mihai''s own interpretation, unconfirmed by either decision -- only the delivery_format vocabulary was decided. Recurring, for the resources-caption distinction (app/(app)/groups/[id]/trainer-resources-section.tsx) and the group-create form''s schedule-pattern shape (groups-client.tsx), means scoli_private_recurente ONLY -- not all ten, not custom, and not by a "recurring" substring check. For app.resolve_duration_multiplier, custom resolves to the standard context, NOT scoala_altfel_saptamana_verde -- asserted in db/tests/custom_workshop_type.sql because calculate_session_pay now depends on it.';
