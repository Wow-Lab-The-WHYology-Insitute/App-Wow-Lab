-- Dry-run for 202609240001 + 202609240002 (inlined, not \i -- this runs
-- through `supabase db query --linked --file`, not psql, and \i is not
-- reliable through that path). Applies both inside a transaction that
-- always rolls back, then checks the seeded data by calling the real
-- resolver functions -- proving the consumption path, not just that
-- INSERT succeeded.

begin;

-- ============================================================================
-- 202609240001, verbatim
-- ============================================================================
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

  insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'dry run')
  returning id into v_version;

  insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate) values
    (v_org, v_version, 1, 111),
    (v_org, v_version, 2, 119),
    (v_org, v_version, 3, 127),
    (v_org, v_version, 4, 134),
    (v_org, v_version, 5, 142),
    (v_org, v_version, 6, 150);

  insert into public.location_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'dry run')
  returning id into v_version;

  insert into public.location_bonus_rates (organization_id, version_id, location_tier, bonus_percent) values
    (v_org, v_version, 'bucuresti', 0),
    (v_org, v_version, 'imprejurimi', 25),
    (v_org, v_version, 'alte_orase', 100);

  insert into public.language_bonus_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'dry run')
  returning id into v_version;

  insert into public.language_bonus_rates (organization_id, version_id, language_group, bonus_percent) values
    (v_org, v_version, 'fr_de_es', 20),
    (v_org, v_version, 'ro_en', 0);

  insert into public.lesson_plan_rate_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'dry run')
  returning id into v_version;

  insert into public.lesson_plan_rates (organization_id, version_id, rate)
  values (v_org, v_version, 133.20);

  insert into public.duration_multiplier_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-09-01', v_anca, 'dry run')
  returning id into v_version;

  insert into public.duration_multiplier_rates (organization_id, version_id, duration_minutes, delivery_context, multiplier) values
    (v_org, v_version, 30, 'standard', 1.0),
    (v_org, v_version, 60, 'standard', 1.0),
    (v_org, v_version, 90, 'standard', 1.2),
    (v_org, v_version, 120, 'standard', 1.5),
    (v_org, v_version, 60, 'scoala_altfel_saptamana_verde', 1.0),
    (v_org, v_version, 90, 'scoala_altfel_saptamana_verde', 1.2),
    (v_org, v_version, 120, 'scoala_altfel_saptamana_verde', 2.0);
end $$;

comment on function app.resolve_contract_type_uplift(uuid, text, date) is
  'dry run comment';

-- ============================================================================
-- 202609240002, verbatim
-- ============================================================================
do $$
declare
  v_org uuid;
  v_anca uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';

  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  select v_org, u.id, g.grade_level, '2026-09-01'::date, v_anca, 'manual'
  from (values
    ('catalina_moale@yahoo.com', 6),
    ('soniaganea05@gmail.com', 6),
    ('irinaeremia160@gmail.com', 6),
    ('elena.bacalum@gmail.com', 4),
    ('merisanteodora@gmail.com', 3),
    ('alexandra.nutu2010@gmail.com', 2),
    ('v.tobosaru@yahoo.com', 2),
    ('popar216@gmail.com', 1),
    ('alina.garofil@outlook.com', 1),
    ('rabalasov@gmail.com', 1)
  ) as g(email, grade_level)
  join public.users u on u.email = g.email;

  if (select count(*) from public.trainer_grade_assignments where organization_id = v_org and effective_from = '2026-09-01') <> 10 then
    raise exception 'expected 10 rows, got %', (select count(*) from public.trainer_grade_assignments where organization_id = v_org and effective_from = '2026-09-01');
  end if;
end $$;

-- ============================================================================
-- Resolver spot-checks
-- ============================================================================
select
  'grade 3 rate' as check_name,
  app.resolve_trainer_grade_rate((select id from public.organizations where slug = 'wow-lab'), 3, '2026-09-01') = 127 as pass
union all
select 'grade 6 rate',
  app.resolve_trainer_grade_rate((select id from public.organizations where slug = 'wow-lab'), 6, '2026-09-01') = 150
union all
select 'location bonus imprejurimi',
  app.resolve_location_bonus((select id from public.organizations where slug = 'wow-lab'), 'imprejurimi', '2026-09-01') = 25
union all
select 'language bonus fr_de_es',
  app.resolve_language_bonus((select id from public.organizations where slug = 'wow-lab'), 'fr_de_es', '2026-09-01') = 20
union all
select 'lesson plan rate, new',
  app.resolve_lesson_plan_rate((select id from public.organizations where slug = 'wow-lab'), '2026-09-01') = 133.20
union all
select 'lesson plan rate, pre-change date still resolves to old value',
  app.resolve_lesson_plan_rate((select id from public.organizations where slug = 'wow-lab'), '2026-08-31') = 120
union all
select 'duration standard 90',
  app.resolve_duration_multiplier((select id from public.organizations where slug = 'wow-lab'), 90, 'parteneriate_companii', '2026-09-01') = 1.2
union all
select 'duration scoala_altfel 120',
  app.resolve_duration_multiplier((select id from public.organizations where slug = 'wow-lab'), 120, 'scoala_altfel', '2026-09-01') = 2.0
union all
select 'contract_type_uplift version table still empty',
  (select count(*) from public.contract_type_uplift_versions where organization_id = (select id from public.organizations where slug = 'wow-lab')) = 0
union all
select 'trainer grade assignments count = 10',
  (select count(*) from public.trainer_grade_assignments where organization_id = (select id from public.organizations where slug = 'wow-lab') and effective_from = '2026-09-01') = 10
union all
select 'Catalina Trusan resolves to grade 6',
  app.resolve_trainer_grade((select id from public.users where email = 'catalina_moale@yahoo.com'), '2026-09-01') = 6
union all
select 'Luiza Mirt has no assignment at all',
  (select count(*) from public.trainer_grade_assignments where trainer_id = (select id from public.users where email = 'luiza.mirt8@gmail.com')) = 0;

rollback;
