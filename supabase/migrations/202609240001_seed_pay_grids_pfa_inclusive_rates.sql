-- Seeds five of the six payment-config grids with Anca's confirmed
-- figures (2026-09-24), effective 2026-09-01, PFA-inclusive -- the
-- 11.1% PFA/SRL uplift is already inside these rates ("in contractul cu
-- trainerii PFA sau SRL vom avea direct 111 lei/ora tarif de baza
-- junior"), so contract_type_uplift is not applied on top of them.
--
-- The sixth grid, contract_type_uplift, is deliberately left with zero
-- rows -- see the comment block near the end of this file and the
-- COMMENT ON FUNCTION at the bottom. Trainer grade assignments (which
-- trainer holds which grade) are a separate migration, since they need
-- a per-trainer_id fail-loud check this file's per-grid blocks don't.

do $$
declare
  v_org uuid;
  v_anca uuid;
  v_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'pay grid seed: no organization with slug=wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'pay grid seed: no user with email=anca.tanasescu@gmail.com';
  end if;

  -- ==========================================================================
  -- trainer_grade_rates -- PFA-inclusive, no contract_type_uplift on top.
  -- ==========================================================================
  insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
  values (
    v_org,
    '2026-09-01',
    v_anca,
    'Confirmed by Anca 2026-09-24: PFA-inclusive rates -- "in contractul cu trainerii PFA sau SRL vom avea direct 111 lei/ora tarif de baza junior." The 11.1% PFA/SRL uplift is already inside these six numbers; contract_type_uplift is not applied on top (see that grid''s own empty-on-purpose note below).'
  )
  returning id into v_version;

  insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate) values
    (v_org, v_version, 1, 111),  -- Junior
    (v_org, v_version, 2, 119),  -- Rising Star
    (v_org, v_version, 3, 127),  -- Enthusiastic Mid 1
    (v_org, v_version, 4, 134),  -- Experienced Mid 2
    (v_org, v_version, 5, 142),  -- Magic Senior 1
    (v_org, v_version, 6, 150);  -- Glowing Senior 2

  -- ==========================================================================
  -- location_bonus -- percent, as travel bonus relative to the tier
  -- already resolved for the session (sessions.location_tier).
  -- ==========================================================================
  insert into public.location_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'Confirmed by Anca 2026-09-24.')
  returning id into v_version;

  insert into public.location_bonus_rates (organization_id, version_id, location_tier, bonus_percent) values
    (v_org, v_version, 'bucuresti', 0),
    (v_org, v_version, 'imprejurimi', 25),
    (v_org, v_version, 'alte_orase', 100);

  -- ==========================================================================
  -- language_bonus -- percent, keyed to sessions.language_group's
  -- two-value vocabulary (ro_en / fr_de_es).
  -- ==========================================================================
  insert into public.language_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'Confirmed by Anca 2026-09-24: French/German/Spanish 20%, Romanian/English 0%.')
  returning id into v_version;

  insert into public.language_bonus_rates (organization_id, version_id, language_group, bonus_percent) values
    (v_org, v_version, 'fr_de_es', 20),
    (v_org, v_version, 'ro_en', 0);

  -- ==========================================================================
  -- lesson_plan_rates -- second version. The 2024-01-01/120 row is left
  -- exactly as it was (no UPDATE/DELETE grant exists on this table by
  -- design -- a correction is a new version, never an edit); work done
  -- before 2026-09-01 resolves against it unchanged.
  -- ==========================================================================
  insert into public.lesson_plan_rate_versions (organization_id, effective_date, created_by, note)
  values (
    v_org,
    '2026-09-01',
    v_anca,
    'Confirmed by Anca 2026-09-24: 133.20 lei/plan, PFA-inclusive, superseding the 120 lei/plan rate effective since 2024-01-01. That earlier version is untouched -- lesson plans written before 2026-09-01 resolve against 120, not this row.'
  )
  returning id into v_version;

  insert into public.lesson_plan_rates (organization_id, version_id, rate)
  values (v_org, v_version, 133.20);

  -- ==========================================================================
  -- duration_multiplier -- two delivery_context rows per duration.
  --
  -- standard: derived from 1,089 real approved rows, no exception.
  --
  -- scoala_altfel_saptamana_verde: 60 -> 1.0 is confirmed by one real
  -- Saptamana Verde row. 120 -> 2.0 is Anca's decision, going forward --
  -- NOT a correction of past pay: across 1,456 historical rows the x2
  -- multiplier was never once applied; the single Scoala Altfel two-hour
  -- row on record used 1.5, the standard-context rate. 90 appears
  -- nowhere in the data for this context at all -- seeded at 1.2 to
  -- match standard purely so the resolver has a row to return instead of
  -- raising on the one duration nobody has actually recorded yet. This
  -- is an ASSUMPTION, not an observation -- do not read the 90-minute
  -- scoala_altfel_saptamana_verde row as Anca-confirmed the way every
  -- other row in this migration is.
  -- ==========================================================================
  insert into public.duration_multiplier_versions (organization_id, effective_date, created_by, note)
  values (
    v_org,
    '2026-09-01',
    v_anca,
    'standard rows confirmed by Anca 2026-09-24, derived from 1,089 real approved rows with no exception. scoala_altfel_saptamana_verde: 60 confirmed by one real Saptamana Verde row; 120 (2.0) is Anca''s decision going forward, never once applied in 1,456 historical rows (the one Scoala Altfel two-hour row on record used the standard 1.5); 90 (1.2) is an assumption matching standard, not an observed value -- nothing in the data uses a 90-minute scoala_altfel/saptamana_verde session.'
  )
  returning id into v_version;

  insert into public.duration_multiplier_rates (organization_id, version_id, duration_minutes, delivery_context, multiplier) values
    (v_org, v_version, 30, 'standard', 1.0),
    (v_org, v_version, 60, 'standard', 1.0),
    (v_org, v_version, 90, 'standard', 1.2),
    (v_org, v_version, 120, 'standard', 1.5),
    (v_org, v_version, 60, 'scoala_altfel_saptamana_verde', 1.0),
    (v_org, v_version, 90, 'scoala_altfel_saptamana_verde', 1.2),  -- assumption, see note above -- not observed
    (v_org, v_version, 120, 'scoala_altfel_saptamana_verde', 2.0);
end $$;

-- ============================================================================
-- contract_type_uplift -- deliberately left at zero rows, zero versions.
--
-- The PFA-inclusive rates seeded above already have the 11.1% uplift
-- baked in (per Anca's own words in the trainer_grade_versions note
-- above), so contract_type_uplift has nothing left to add on top of
-- them for pfa/srl -- applying it would double the uplift. Seeding it at
-- 0% instead of leaving it empty was considered and rejected: a
-- 0%-seeded grid LOOKS configured (Finance would see three real rows in
-- /payment-config and reasonably assume it's live) while actually being
-- silently unreachable from any calculation -- the exact shape item 92
-- names ("a grid that exists and must never be applied is the shape
-- this register keeps finding"), one layer up from the additive-grant
-- bug that item was about. An empty grid is the honest signal: it says
-- "not wired in" instead of "configured and forgotten."
--
-- app.resolve_contract_type_uplift itself is left in place (dropping a
-- working, harmless resolver is a bigger and unrequested action) but
-- must never be called by app.calculate_session_pay or any future pay
-- calculation. See the COMMENT ON FUNCTION below -- this is the comment
-- "where the other resolvers are composed" a future calculation should
-- read before adding this one to the list.
-- ============================================================================
comment on function app.resolve_contract_type_uplift(uuid, text, date) is
  'Built, correct, and unused on purpose. The PFA-inclusive rates in trainer_grade_rates (effective 2026-09-01) already have the 11.1% PFA/SRL uplift baked in -- calling this from app.calculate_session_pay or any other pay calculation would double it. contract_type_uplift and contract_type_uplift_versions are deliberately kept at zero rows so this stays unreachable rather than silently misconfigured. See migration 202609240001 and OPEN_ITEMS.md.';
