-- db/tests/grid_version_in_force.sql
-- WOW LAB OS: the screen's "current" and the engine's "in force" are the
-- same answer because they are the same function (202610260001).
--
-- The failure this prevents is not hypothetical and not a bug anyone wrote:
-- /payment-config took `versions[0]` -- the newest row that EXISTS -- while
-- every pay resolver takes the newest with effective_date <= the workshop's
-- date. Identical while nothing is dated ahead; and item 147 is the
-- instruction that ends that, seeding the 111-150 scale with a signed
-- contract's own start date. A January contract puts the row in in December,
-- and from that day the screen reads 150 at grade 6 while payroll correctly
-- pays 135.
--
-- Block 2 creates exactly that state and asserts the two still agree.

-- ============================================================================
-- Point 1 -- today, with nothing dated ahead: the state the old screen was
-- also right in. If these disagree, something is already scheduled.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select 'five grids answered, one row each' as check_name,
    (select count(*)::text from public.current_grid_versions(current_setting('app.org')::uuid)) as actual,
    '5' as expected,
    (select count(*) = 5 from public.current_grid_versions(current_setting('app.org')::uuid)) as pass
  union all
  -- Four, not five. contract_type_uplift is deliberately empty (item 147 --
  -- there is no uplift to apply), and asserting the number rather than "at
  -- least one" keeps that decision stated instead of invisible (§20).
  select 'four grids have a version in force; contract_type_uplift is empty BY DECISION',
    (select count(*) filter (where version_id is not null)::text
     from public.current_grid_versions(current_setting('app.org')::uuid)),
    '4',
    (select count(*) filter (where version_id is not null) = 4
     from public.current_grid_versions(current_setting('app.org')::uuid))
  union all
  select 'and it is contract_type_uplift that is the null one',
    (select coalesce(version_id::text, 'null') from public.current_grid_versions(current_setting('app.org')::uuid)
     where grid = 'contract_type_uplift'),
    'null',
    (select version_id is null from public.current_grid_versions(current_setting('app.org')::uuid)
     where grid = 'contract_type_uplift')
  union all
  select 'with nothing scheduled, in-force == newest row (the only state the old screen was right in)',
    (select (version_id = (select id from public.trainer_grade_versions
                           where organization_id = current_setting('app.org')::uuid
                           order by effective_date desc limit 1))::text
     from public.current_grid_versions(current_setting('app.org')::uuid) where grid = 'trainer_grade'),
    'true',
    (select version_id = (select id from public.trainer_grade_versions
                          where organization_id = current_setting('app.org')::uuid
                          order by effective_date desc limit 1)
     from public.current_grid_versions(current_setting('app.org')::uuid) where grid = 'trainer_grade')
  union all
  select 'a date before every version resolves to null, not to the newest row',
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', '2020-01-01')::text, 'null'),
    'null',
    app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', '2020-01-01') is null;
rollback;

-- ============================================================================
-- Point 2 -- ITEM 147'S ROW, created. A trainer_grade version dated two
-- months out, exactly as a January contract would produce in December.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.ahead', (current_date + 60)::text, true);

  do $$
  declare v_new uuid; v_me uuid;
  begin
    select id into v_me from public.users where email = 'maxdigitalro@gmail.com';
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
    values (current_setting('app.org')::uuid, (current_date + 60)::date, v_me,
            'fixture: the 111-150 scale, dated by a contract that starts later (item 147)')
    returning id into v_new;

    -- 111-150, the scale item 147 names.
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
    select current_setting('app.org')::uuid, v_new, x.lvl, x.rate
    from (values (1,111),(2,119),(3,127),(4,134),(5,142),(6,150)) x(lvl, rate);

    perform set_config('app.new_version', v_new::text, true);
  end $$;

  select 'the scheduled version is NOT what is in force today' as check_name,
    (select (version_id = current_setting('app.new_version')::uuid)::text
     from public.current_grid_versions(current_setting('app.org')::uuid) where grid = 'trainer_grade') as actual,
    'false' as expected,
    (select version_id <> current_setting('app.new_version')::uuid
     from public.current_grid_versions(current_setting('app.org')::uuid) where grid = 'trainer_grade') as pass
  union all
  -- THE ONE THAT MATTERS: `versions[0]` and the engine now DISAGREE, which is
  -- the whole reason the screen stopped using versions[0].
  select 'the newest row that EXISTS is the scheduled one -- which is what the old screen would have shown',
    (select (id = current_setting('app.new_version')::uuid)::text from public.trainer_grade_versions
     where organization_id = current_setting('app.org')::uuid order by effective_date desc limit 1),
    'true',
    (select id = current_setting('app.new_version')::uuid from public.trainer_grade_versions
     where organization_id = current_setting('app.org')::uuid order by effective_date desc limit 1)
  union all
  select 'pay today still resolves grade 6 to 135, not the scheduled 150',
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, current_date)::text,
    '135',
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, current_date) = 135
  union all
  select 'and ON the effective date it resolves to 150 -- the scheduled version does take effect',
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, (current_date + 60)::date)::text,
    '150',
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, (current_date + 60)::date) = 150
  union all
  select 'the screen and the engine agree on that date too',
    (select (version_id = current_setting('app.new_version')::uuid)::text
     from public.current_grid_versions(current_setting('app.org')::uuid, (current_date + 60)::date)
     where grid = 'trainer_grade'),
    'true',
    (select version_id = current_setting('app.new_version')::uuid
     from public.current_grid_versions(current_setting('app.org')::uuid, (current_date + 60)::date)
     where grid = 'trainer_grade');
rollback;

-- ============================================================================
-- Point 3 -- SABOTAGE. Replaces the shared resolver with `versions[0]`'s
-- logic -- newest row that exists, ignoring the date -- and re-runs point 2's
-- "pay today still resolves to 135" VERBATIM. Under the sabotaged function
-- today's pay jumps to the scheduled 150, so `pass` must flip to false.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);

  do $$
  declare v_new uuid; v_me uuid;
  begin
    select id into v_me from public.users where email = 'maxdigitalro@gmail.com';
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
    values (current_setting('app.org')::uuid, (current_date + 60)::date, v_me, 'sabotage fixture')
    returning id into v_new;
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
    select current_setting('app.org')::uuid, v_new, x.lvl, x.rate
    from (values (1,111),(2,119),(3,127),(4,134),(5,142),(6,150)) x(lvl, rate);
  end $$;

  create or replace function app.resolve_grid_version(p_organization_id uuid, p_grid text, p_as_of date)
  returns uuid language plpgsql stable set search_path = '' as $sab$
  declare v_version_id uuid;
  begin
    -- The old screen's question, in the engine's place: newest row that
    -- EXISTS, p_as_of ignored entirely.
    if p_grid = 'trainer_grade' then
      select id into v_version_id from public.trainer_grade_versions
      where organization_id = p_organization_id order by effective_date desc limit 1;
    end if;
    return v_version_id;
  end; $sab$;

  select 'SABOTAGE: pay today still resolves grade 6 to 135, not the scheduled 150, same assertion as point 2, resolver ignores the date' as check_name,
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, current_date)::text as actual,
    '135' as expected,
    app.resolve_trainer_grade_rate(current_setting('app.org')::uuid, 6, current_date) = 135 as pass;
rollback;
