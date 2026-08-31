-- 202608310001_sessions_location_language.sql
-- sessions.location_tier / sessions.language_group -- prerequisites named
-- explicitly in docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md Sec12.5 and
-- Sec12 (payment model investigation): the trainer payment formula
-- resolves a location bonus and a language bonus per session, and neither
-- value exists anywhere in the schema today. Without these two columns,
-- two of the five payment config grids being built next (Sec12.8) would
-- have nothing to resolve against.
--
-- location_tier: NOT a users column. An earlier version of the SAD
-- proposed a trainer home-city column, resolved together with the
-- delivery location into a bonus tier. Wrong -- only two points of that
-- resolution are actually confirmed (home == delivery -> 0%; the two
-- non-Bucharest trainers delivering in Bucharest -> 100%), and there is
-- no confirmed rule for the general case. Recording the already-resolved
-- tier directly on the session, by whoever enters it (who already knows
-- the delivery location -- nothing else records that either -- and in
-- practice knows or can ask where the trainer travelled from), avoids
-- inventing an unconfirmed general rule to solve a problem that affects 2
-- of 11 active trainers. See Sec12.5's own correction.
--
-- language_group: same reasoning as location -- confirmed to vary per
-- session, not per client or per trainer, and confirmed absent from both
-- sessions and groups in the original schema investigation for this SAD.
--
-- Both nullable, NO BACKFILL, on purpose: existing sessions have no
-- recorded location or language and none is invented here. A session
-- missing either value simply can't have its location/language bonus
-- resolved -- that's the correct state for historical data entered before
-- this column existed, not something to guess into.
--
-- Values are a closed vocabulary from day one (matching every other
-- small-enum column in this schema -- groups.module, groups.status,
-- sessions.status), not free text needing later classification.

alter table public.sessions
  add column location_tier text null
    check (location_tier in ('bucuresti', 'imprejurimi', 'alte_orase')),
  add column language_group text null
    check (language_group in ('ro_en', 'fr_de_es'));
