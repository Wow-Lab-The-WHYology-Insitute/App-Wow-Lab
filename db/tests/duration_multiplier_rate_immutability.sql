-- db/tests/duration_multiplier_rate_immutability.sql
-- 202611090005 (item 188 point 2): a duration_multiplier_rates band
-- becomes immutable the moment a confirmed session's duration resolves to
-- it (via the nearest-band, 202610160004 shape); a correction is a new
-- duration_multiplier_versions row with corrects_version_id, same
-- effective_date, never an in-place edit -- same shape as
-- trainer_grade_rate_immutability.sql (202611090003), adapted for a band
-- key (duration_minutes, delivery_context) instead of an equality key
-- (grade_level).
--
-- Entirely synthetic fixtures, same convention as trainer_grade_rate_
-- immutability.sql: a disposable version at 2020-06-15, well before any
-- real duration_multiplier_versions row, and a past session date
-- (2020-06-16) so app.rpc_confirm_session_attendance's future_session
-- guard (202610220001) does not silently no-op the confirmation. Nothing
-- here reads or writes the real live grid -- that grid's own two locked
-- bands (60-minute and 90-minute standard) are proven inside
-- 202611090005's own assertion block, against real data, not here.

begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.catalina', (select id::text from public.users where email = 'catalina_moale@yahoo.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  -- A disposable, original ("head") version -- one band, 60 minutes,
  -- standard context.
  insert into public.duration_multiplier_versions (id, organization_id, effective_date, created_by, note)
  values ('dd000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'test fixture, 202611090005 -- original');

  insert into public.duration_multiplier_rates (id, organization_id, version_id, duration_minutes, delivery_context, multiplier)
  values
    ('dd100000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000001', 30, 'standard', 1.0),
    ('dd100000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000001', 60, 'standard', 1.0);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('dd200000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- 45 minutes -- not an exact band, rounds up to the 60-minute band,
  -- same shape as the real Avenor/Scoala Germana sessions 202610160004
  -- was written for.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('dd300000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'dd200000-0000-0000-0000-000000000001', '2020-06-16', current_setting('app.catalina')::uuid, 'delivered', 45, 'bucuresti');

  insert into check_results values (
    'before confirmation, the 60-minute band is NOT locked',
    not app.duration_multiplier_rate_is_locked('dd000000-0000-0000-0000-000000000001', 60, 'standard')
  );

  select set_config(
    'request.jwt.claims',
    json_build_object('sub', current_setting('app.catalina')::uuid, 'role', 'authenticated')::text,
    true
  );
  select app.rpc_confirm_session_attendance('dd300000-0000-0000-0000-000000000001', true);

  insert into check_results values (
    'after confirmation, the 60-minute band IS locked (45 minutes rounds up to it)',
    app.duration_multiplier_rate_is_locked('dd000000-0000-0000-0000-000000000001', 60, 'standard')
  );

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.duration_multiplier_rates set multiplier = 9.99
      where version_id = 'dd000000-0000-0000-0000-000000000001' and duration_minutes = 60 and delivery_context = 'standard';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('a direct multiplier UPDATE on the now-locked 60-minute band is refused', v_raised);
  end $$;

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.duration_multiplier_rates set duration_minutes = 61
      where version_id = 'dd000000-0000-0000-0000-000000000001' and duration_minutes = 60 and delivery_context = 'standard';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('moving the locked band''s own duration_minutes boundary is refused too, not only the multiplier', v_raised);
  end $$;

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      update public.duration_multiplier_versions set effective_date = '2020-06-17' where id = 'dd000000-0000-0000-0000-000000000001';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('the version''s own effective_date is refused once any of its bands is locked', v_raised);
  end $$;

  -- The 30-minute band on the SAME disposable version has no confirmed
  -- session on it -- it must stay genuinely editable even though the
  -- 60-minute band, on the same version row's sibling, is locked. Locking
  -- is per (version, duration_minutes, delivery_context), not per version.
  update public.duration_multiplier_rates set multiplier = 0.8
  where version_id = 'dd000000-0000-0000-0000-000000000001' and duration_minutes = 30 and delivery_context = 'standard';
  insert into check_results values (
    'the 30-minute band (unlocked) on the same version accepted its UPDATE',
    (select multiplier from public.duration_multiplier_rates where version_id = 'dd000000-0000-0000-0000-000000000001' and duration_minutes = 30 and delivery_context = 'standard') = 0.8
  );

  -- The correct expression of a correction: a new version, same
  -- effective_date, pointing back at the one it corrects.
  insert into public.duration_multiplier_versions (id, organization_id, effective_date, created_by, corrects_version_id, note)
  values ('dd000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'dd000000-0000-0000-0000-000000000001', 'test fixture, 202611090005 -- first correction');

  insert into public.duration_multiplier_rates (id, organization_id, version_id, duration_minutes, delivery_context, multiplier)
  values
    ('dd100000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000002', 30, 'standard', 1.0),
    ('dd100000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000002', 60, 'standard', 2.0);

  insert into check_results values (
    'resolve_grid_version now returns the CORRECTION, not the original, for the same date',
    app.resolve_grid_version(current_setting('app.wow_lab')::uuid, 'duration_multiplier', '2020-06-16') = 'dd000000-0000-0000-0000-000000000002'
  );
  insert into check_results values (
    'resolve_duration_multiplier now returns the corrected multiplier (2.0), not the original (1.0), for 45 minutes',
    app.resolve_duration_multiplier(current_setting('app.wow_lab')::uuid, 45, 'standard', '2020-06-16') = 2.0
  );
  insert into check_results values (
    'the ORIGINAL 60-minute band row is untouched -- still 1.0, never edited in place',
    (select multiplier from public.duration_multiplier_rates where version_id = 'dd000000-0000-0000-0000-000000000001' and duration_minutes = 60 and delivery_context = 'standard') = 1.0
  );

  -- A second hop -- same shape as the trainer_grade test's own second-hop
  -- check: a correction of a correction resolves to the newest one.
  insert into public.duration_multiplier_versions (id, organization_id, effective_date, created_by, corrects_version_id, note)
  values ('dd000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'dd000000-0000-0000-0000-000000000002', 'test fixture, 202611090005 -- second correction');

  insert into public.duration_multiplier_rates (id, organization_id, version_id, duration_minutes, delivery_context, multiplier)
  values
    ('dd100000-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', 30, 'standard', 1.0),
    ('dd100000-0000-0000-0000-000000000006', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', 60, 'standard', 3.0);

  insert into check_results values (
    'a two-deep correction chain resolves to the newest correction (3.0), not the middle (2.0) or the original (1.0)',
    app.resolve_duration_multiplier(current_setting('app.wow_lab')::uuid, 45, 'standard', '2020-06-16') = 3.0
  );

  do $$
  declare
    v_raised boolean := false;
  begin
    begin
      insert into public.duration_multiplier_versions (id, organization_id, effective_date, created_by, corrects_version_id)
      values (gen_random_uuid(), current_setting('app.wow_lab')::uuid, '2020-06-15', current_setting('app.catalina')::uuid, 'dd000000-0000-0000-0000-000000000001');
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
      update public.duration_multiplier_versions set corrects_version_id = id where id = 'dd000000-0000-0000-0000-000000000003';
    exception when others then
      v_raised := true;
    end;
    insert into check_results values ('a version cannot correct itself', v_raised);
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;
