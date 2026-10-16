-- WOW LAB Test Org B had no pay grid at all: zero rows in
-- trainer_grade_rates, duration_multiplier_rates, location_bonus_rates
-- and language_bonus_rates, while holding the only three sessions in the
-- database and six graded trainers (B1-B6, from 2026-09-02). That is not
-- an obstacle to one feature, it is a hole in the test org: every
-- resolver raises there, so nothing that reads a rate could ever be
-- verified against it. 202609250001's own test suite works around this
-- by running against WOW LAB's real production grids instead.
--
-- Why a migration and not a script fixture. scripts/verify_pay_inputs_
-- through_app.ts already seeded grids exactly like these -- as fixtures,
-- then deleted them in cleanup, which is why the org has none today. A
-- grid is not a fixture: it is the org's standing configuration, the
-- thing a test org needs in order to BE a test org. Seeded once, kept.
--
-- The values are deliberately synthetic and deliberately NOT WOW LAB's
-- (111/119/127/134/142/150, 202609240001), so a test cannot pass by
-- accidentally reading production numbers and no one can mistake one
-- grid's output for the other's.
--
-- Grade 2 is 175 rather than a round number ON PURPOSE: 175 x 1.5 (120
-- min standard) x 1.25 (imprejurimi) = 328.125, a three-decimal product.
-- The rounding rule this round introduces (round per row, sum the
-- rounded rows) is only testable against a value that produces a third
-- decimal, and without one odd rate in here that case would exist only
-- in production data, where a test may not write.
--
-- effective_date 2020-01-01, not 2026-09-01 like production. A test org's
-- grid should resolve for any session date a fixture invents, including
-- the 2026-09-23 session that already exists; a realistic effective date
-- would make half the test cases fail on a date boundary that is not
-- what they are testing. The prior fixture made the same choice for the
-- same reason.
--
-- 30 minutes is seeded for context 'standard' and deliberately NOT for
-- 'scoala_altfel_saptamana_verde' -- mirroring the exact gap production
-- has. That gap is reachable (the workshop form's duration select offers
-- 30, and a group's delivery_format can be scoala_altfel), it is what
-- app.calculate_org_session_pay's 'no_duration_row' classifier exists
-- for, and reproducing it here is what lets the raise-isolation case be
-- verified in the test org instead of only against production.
--
-- Idempotent (convention 10): every insert is guarded, so re-running
-- changes nothing. on conflict targets each table's real unique key --
-- (organization_id, effective_date) on the versions,
-- (version_id, <grid key>) on the rates.

do $$
declare
  v_org uuid;
  v_author uuid;
  v_grade_version uuid;
  v_duration_version uuid;
  v_location_version uuid;
  v_language_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab-test-b';
  if v_org is null then
    raise exception 'seed_test_org_b_pay_grids: no organization with slug wow-lab-test-b';
  end if;

  -- created_by is NOT NULL on all four version tables. The org's own
  -- owner, not the ops manager the prior fixture used: a pay grid
  -- version is an owner/finance act, and Test Ops Manager B holds
  -- neither capability.
  select id into v_author from public.users where email = 'test+user-b@wowlab.dev';
  if v_author is null then
    raise exception 'seed_test_org_b_pay_grids: no user test+user-b@wowlab.dev to attribute the grid versions to';
  end if;

  -- ---- trainer grades ----
  insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2020-01-01', v_author, 'Test Org B standing pay grid (202610150004). Synthetic values, deliberately not WOW LAB''s.')
  on conflict (organization_id, effective_date) do nothing;

  select id into v_grade_version from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2020-01-01';

  insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
  values (v_org, v_grade_version, 1, 100),
         -- 175: the odd rate, so x1.5 x1.25 = 328.125 exercises rounding.
         (v_org, v_grade_version, 2, 175),
         (v_org, v_grade_version, 3, 200),
         (v_org, v_grade_version, 4, 250),
         (v_org, v_grade_version, 5, 300),
         (v_org, v_grade_version, 6, 350)
  on conflict (version_id, grade_level) do nothing;

  -- ---- duration multipliers ----
  insert into public.duration_multiplier_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2020-01-01', v_author, 'Test Org B standing pay grid (202610150004). 30 min absent for scoala_altfel on purpose -- mirrors production''s gap.')
  on conflict (organization_id, effective_date) do nothing;

  select id into v_duration_version from public.duration_multiplier_versions
  where organization_id = v_org and effective_date = '2020-01-01';

  insert into public.duration_multiplier_rates (organization_id, version_id, duration_minutes, delivery_context, multiplier)
  values (v_org, v_duration_version, 30, 'standard', 1.0),
         (v_org, v_duration_version, 60, 'standard', 1.0),
         (v_org, v_duration_version, 90, 'standard', 1.2),
         (v_org, v_duration_version, 120, 'standard', 1.5),
         -- No 30-minute row here. See the header.
         (v_org, v_duration_version, 60, 'scoala_altfel_saptamana_verde', 1.0),
         (v_org, v_duration_version, 90, 'scoala_altfel_saptamana_verde', 1.2),
         (v_org, v_duration_version, 120, 'scoala_altfel_saptamana_verde', 2.0)
  on conflict (version_id, duration_minutes, delivery_context) do nothing;

  -- ---- location bonuses ----
  insert into public.location_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2020-01-01', v_author, 'Test Org B standing pay grid (202610150004).')
  on conflict (organization_id, effective_date) do nothing;

  select id into v_location_version from public.location_bonus_versions
  where organization_id = v_org and effective_date = '2020-01-01';

  insert into public.location_bonus_rates (organization_id, version_id, location_tier, bonus_percent)
  values (v_org, v_location_version, 'bucuresti', 0),
         (v_org, v_location_version, 'imprejurimi', 25),
         (v_org, v_location_version, 'alte_orase', 100)
  on conflict (version_id, location_tier) do nothing;

  -- ---- language bonuses ----
  insert into public.language_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2020-01-01', v_author, 'Test Org B standing pay grid (202610150004).')
  on conflict (organization_id, effective_date) do nothing;

  select id into v_language_version from public.language_bonus_versions
  where organization_id = v_org and effective_date = '2020-01-01';

  insert into public.language_bonus_rates (organization_id, version_id, language_group, bonus_percent)
  values (v_org, v_language_version, 'ro_en', 0),
         (v_org, v_language_version, 'fr_de_es', 20)
  on conflict (version_id, language_group) do nothing;
end $$;

-- The MAX green_energy group holds all three of Test Org B's sessions and
-- has no language_group, which makes every one of them unpriceable on
-- app.calculate_session_pay's third guard before any grid is consulted --
-- the group-level input the function reads from groups, never from the
-- session (202609240003).
--
-- This is the one existing row this round changes, and it is a fill, not
-- a correction: language_group went NOT NULL-less precisely so groups
-- created before it existed could be backfilled. Guarded on `is null` so
-- a real value set later is never overwritten, and so re-running does
-- nothing. groups carries the row_history trigger, so the change is
-- captured there like any other.
update public.groups g
set language_group = 'ro_en'
where g.language_group is null
  and g.organization_id = (select id from public.organizations where slug = 'wow-lab-test-b');
