-- db/tests/trainer_grade_rate_immutability.sql
-- 202611090003 (item 187, point 2): a trainer_grade_rates row becomes
-- immutable the moment a confirmed session resolves on it; a correction
-- is a new trainer_grade_versions row with corrects_version_id, same
-- effective_date, never an in-place edit -- the same shape
-- contracts.amends_contract_id (202611090001) already applies to a
-- succession, applied here to a correction instead.
--
-- Entirely synthetic fixtures: a disposable version at a date well
-- before the real grid's own earliest row (2020-06-15, before any real
-- trainer_grade_versions or trainer_grade_assignments row exists -- a
-- FUTURE date was tried first and rejected the session's own
-- confirmation outright, 'future_session', per 202610220001's guard: a
-- confirmation asserts a class was already taught, and nothing makes
-- that true in advance) and a disposable trainer_grade_assignment on
-- Cătălina's real id at that same date. Nothing here reads or writes the
-- real Sept-Nov 2026 grid -- that grid's own live-locked state (grades
-- 2/3/6) is proven inside the migration's own assertion block, against
-- real data, not here.

begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.catalina', (select id::text from public.users where email = 'catalina_moale@yahoo.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  -- A disposable, original ("head") version -- six rows, only grade 1 used.
  insert into public.trainer_grade_versions (id, organization_id, effective_date, created_by, note)
  values ('cc000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'test fixture, 202611090003 -- original');

  insert into public.trainer_grade_rates (id, organization_id, version_id, grade_level, rate)
  select gen_random_uuid(), current_setting('app.wow_lab')::uuid, 'cc000000-0000-0000-0000-000000000001', g, 500 + g
  from generate_series(1, 6) as g;

  insert into public.trainer_grade_assignments (id, organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values ('cc100000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.catalina')::uuid, 1, '2020-06-15', current_setting('app.catalina')::uuid, 'manual');

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('cc200000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('cc300000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'cc200000-0000-0000-0000-000000000001', '2020-06-16', current_setting('app.catalina')::uuid, 'delivered', 60, 'bucuresti');

  insert into check_results values (
    'before confirmation, the disposable rate is NOT locked',
    not app.trainer_grade_rate_is_locked('cc000000-0000-0000-0000-000000000001', 1)
  );

  select set_config(
    'request.jwt.claims',
    json_build_object('sub', current_setting('app.catalina')::uuid, 'role', 'authenticated')::text,
    true
  );
  select app.rpc_confirm_session_attendance('cc300000-0000-0000-0000-000000000001', true);

  insert into check_results values (
    'after confirmation, the disposable rate IS locked',
    app.trainer_grade_rate_is_locked('cc000000-0000-0000-0000-000000000001', 1)
  );

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.trainer_grade_rates set rate = 999 where version_id = 'cc000000-0000-0000-0000-000000000001' and grade_level = 1;
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('a direct rate UPDATE on the now-locked row is refused', v_raised);
  end $$;

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.trainer_grade_versions set effective_date = '2020-06-17' where id = 'cc000000-0000-0000-0000-000000000001';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('the version''s own effective_date is refused once any of its rates is locked', v_raised);
  end $$;

  -- Grade 2 on the same disposable version has no confirmed session on
  -- it -- it must stay genuinely editable even though grade 1, on the
  -- SAME version row's sibling, is locked. Locking is per (version,
  -- grade), not per version.
  update public.trainer_grade_rates set rate = 600 where version_id = 'cc000000-0000-0000-0000-000000000001' and grade_level = 2;
  insert into check_results values (
    'grade 2 (unlocked) on the same version accepted its UPDATE',
    (select rate from public.trainer_grade_rates where version_id = 'cc000000-0000-0000-0000-000000000001' and grade_level = 2) = 600
  );

  -- The correct expression of a correction: a new version, same
  -- effective_date, pointing back at the one it corrects.
  insert into public.trainer_grade_versions (id, organization_id, effective_date, created_by, corrects_version_id, note)
  values ('cc000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'cc000000-0000-0000-0000-000000000001', 'test fixture, 202611090003 -- first correction');

  insert into public.trainer_grade_rates (id, organization_id, version_id, grade_level, rate)
  select gen_random_uuid(), current_setting('app.wow_lab')::uuid, 'cc000000-0000-0000-0000-000000000002', g, 700 + g
  from generate_series(1, 6) as g;

  insert into check_results values (
    'resolve_grid_version now returns the CORRECTION, not the original, for the same date',
    app.resolve_grid_version(current_setting('app.wow_lab')::uuid, 'trainer_grade', '2020-06-16') = 'cc000000-0000-0000-0000-000000000002'
  );
  insert into check_results values (
    'resolve_trainer_grade_rate now returns the corrected rate (701), not the original (501)',
    app.resolve_trainer_grade_rate(current_setting('app.wow_lab')::uuid, 1, '2020-06-16') = 701
  );
  insert into check_results values (
    'the ORIGINAL rate row is untouched -- still 501, never edited in place',
    (select rate from public.trainer_grade_rates where version_id = 'cc000000-0000-0000-0000-000000000001' and grade_level = 1) = 501
  );

  -- A second hop -- exactly the 202610200001-then-202610300001 shape:
  -- a correction of a correction resolves to the newest one.
  insert into public.trainer_grade_versions (id, organization_id, effective_date, created_by, corrects_version_id, note)
  values ('cc000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'cc000000-0000-0000-0000-000000000002', 'test fixture, 202611090003 -- second correction');

  insert into public.trainer_grade_rates (id, organization_id, version_id, grade_level, rate)
  select gen_random_uuid(), current_setting('app.wow_lab')::uuid, 'cc000000-0000-0000-0000-000000000003', g, 900 + g
  from generate_series(1, 6) as g;

  insert into check_results values (
    'a two-deep correction chain resolves to the newest correction (901), not the middle (701) or the original (501)',
    app.resolve_trainer_grade_rate(current_setting('app.wow_lab')::uuid, 1, '2020-06-16') = 901
  );

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      insert into public.trainer_grade_versions (id, organization_id, effective_date, created_by, corrects_version_id)
      values (gen_random_uuid(), current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'cc000000-0000-0000-0000-000000000001');
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('a second, independent correction of an already-corrected version is refused (one corrector per version)', v_raised);
  end $$;

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.trainer_grade_versions set corrects_version_id = id where id = 'cc000000-0000-0000-0000-000000000003';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('a version cannot correct itself', v_raised);
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;
