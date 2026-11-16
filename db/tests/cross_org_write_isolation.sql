-- db/tests/cross_org_write_isolation.sql
-- WOW LAB OS: can a row Org B is allowed to write change what Org A computes?
-- (OPEN_ITEMS item 198, wave 1 -- every foreign key whose child is a PAY table.)
--
-- Written BEFORE the repair and run against the live schema first, failing,
-- on Mihai's instruction (2026-11-16): a test written after its repair only
-- confirms the repair, not the class. The pre-repair run is recorded in item
-- 198.
--
-- The one rule for every check here: it may pass for ONE reason only. A probe
-- that can be refused by something other than what it measures does not
-- measure anything. Mihai's own example, kept as the note it asked to be:
-- "a second standard 60-minute band in wow-lab's live duration version" is
-- refused by duration_multiplier_rates_version_key_unique BEFORE any
-- organization check exists, so "refused" there would have read as "guarded"
-- and been false. Therefore:
--   * every cross-org write targets a FRESH, EMPTY parent created in the same
--     block, so no unique key can be what refuses it; and
--   * every cross-org write has a CONTROL: the identical row, pointed at the
--     writer's own organization's parent, must be accepted. Control accepted +
--     cross-org refused = the organization is the only difference.
--
-- Users are out of scope by design: users are global (one person, many
-- organizations), `users` has no organization_id, and a composite key against
-- it cannot exist. Isolation there is the reader's job (item 198).
--
-- Every block is BEGIN/ROLLBACK. Writes in point 1 run as postgres: the
-- property is that the DATABASE refuses, whoever writes. Points 2-3 write as
-- Test Org B's owner through RLS: the attack as it was induced.

-- ============================================================================
-- Point 1 -- structural: the 15 wave-1 foreign keys, each with its control.
-- ============================================================================
begin;
  create temp table res (fk text, control text, cross_org text) on commit drop;

  do $$
  declare
    w uuid := (select id from public.organizations where slug = 'wow-lab');
    b uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    wu uuid := (select id from public.users where email = 'maxdigitalro@gmail.com');
    bu uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
    bt uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    b_le uuid := (select id from public.legal_entities where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b') order by id limit 1);
    b_client uuid := (select id from public.clients where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b') order by id limit 1);
    b_group uuid := 'bda1f577-f381-4ced-a7f4-4d3399175e95';
    w_group uuid := 'c1000000-0000-0000-0000-0000000000b2';
    w_client uuid := (select client_id from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2');
    w_contract uuid := (select id from public.contracts where organization_id = (select id from public.organizations where slug = 'wow-lab') order by id limit 1);
    w_pp uuid := (select id from public.payroll_periods where organization_id = (select id from public.organizations where slug = 'wow-lab') order by period limit 1);
    b_pp uuid := (select id from public.payroll_periods where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b') order by period limit 1);
    b_contract uuid;
    wv uuid; bv uuid;
    grid text;
    ctl text; xo text;
  begin
    -- An Org B contract, for the groups.contract_id control (Org B has none).
    insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type)
    values (b, b_client, b_le, 'one_off_event') returning id into b_contract;

    -- ---- the seven *_rates.version_id keys, and the four corrects_version_id keys
    foreach grid in array array['trainer_grade', 'duration_multiplier', 'location_bonus', 'language_bonus', 'lesson_plan_rate', 'admin_rate', 'contract_type_uplift'] loop
      -- A fresh, empty version in each organization: no unique key can refuse a row in it.
      if grid = 'admin_rate' then
        execute format('insert into public.%I_versions (organization_id, effective_date) values ($1, %L) returning id', grid, '2099-01-01') into wv using w;
        execute format('insert into public.%I_versions (organization_id, effective_date) values ($1, %L) returning id', grid, '2099-02-01') into bv using b;
      else
        execute format('insert into public.%I_versions (organization_id, effective_date, created_by) values ($1, %L, $2) returning id', grid, '2099-01-01') into wv using w, wu;
        execute format('insert into public.%I_versions (organization_id, effective_date, created_by) values ($1, %L, $2) returning id', grid, '2099-02-01') into bv using b, bu;
      end if;

      for i in 1..2 loop
        declare
          v_target uuid := case i when 1 then bv else wv end;
          v_sql text := case grid
            when 'trainer_grade'        then 'insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate) values ($1, $2, 1, 1)'
            when 'duration_multiplier'  then 'insert into public.duration_multiplier_rates (organization_id, version_id, delivery_context, duration_minutes, multiplier) values ($1, $2, ''standard'', 30, 1)'
            when 'location_bonus'       then 'insert into public.location_bonus_rates (organization_id, version_id, location_tier, bonus_percent) values ($1, $2, ''bucuresti'', 0)'
            when 'language_bonus'       then 'insert into public.language_bonus_rates (organization_id, version_id, language_group, bonus_percent) values ($1, $2, ''ro_en'', 0)'
            when 'lesson_plan_rate'     then 'insert into public.lesson_plan_rates (organization_id, version_id, rate) values ($1, $2, 1)'
            when 'admin_rate'           then 'insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, amount) values ($1, $2, $3, ''per_newsletter'', 1)'
            when 'contract_type_uplift' then 'insert into public.contract_type_uplift_rates (organization_id, version_id, contract_type, uplift_percent) values ($1, $2, ''pfa'', 0)'
          end;
          v_out text;
        begin
          begin
            execute v_sql using b, v_target, bt;
            v_out := 'accepted';
            raise exception using errcode = 'P0W00';
          exception
            when sqlstate 'P0W00' then null;
            when foreign_key_violation then v_out := 'refused';
            when others then v_out := 'other ' || sqlstate;
          end;
          if i = 1 then ctl := v_out; else xo := v_out; end if;
        end;
      end loop;
      insert into res values (case grid when 'lesson_plan_rate' then 'lesson_plan_rates' when 'admin_rate' then 'admin_rates' else grid || '_rates' end || '.version_id', ctl, xo);

      if grid in ('trainer_grade', 'duration_multiplier', 'location_bonus', 'language_bonus') then
        for i in 1..2 loop
          declare v_out text;
          begin
            begin
              execute format('insert into public.%I_versions (organization_id, effective_date, created_by, corrects_version_id) values ($1, %L, $2, $3)', grid, '2099-03-01')
                using b, bu, case i when 1 then bv else wv end;
              v_out := 'accepted';
              raise exception using errcode = 'P0W00';
            exception
              when sqlstate 'P0W00' then null;
              when foreign_key_violation then v_out := 'refused';
              when others then v_out := 'other ' || sqlstate;
            end;
            if i = 1 then ctl := v_out; else xo := v_out; end if;
          end;
        end loop;
        insert into res values (grid || '_versions.corrects_version_id', ctl, xo);
      end if;
    end loop;

    -- ---- sessions.group_id
    for i in 1..2 loop
      declare v_out text;
      begin
        begin
          insert into public.sessions (organization_id, group_id, session_date) values (b, case i when 1 then b_group else w_group end, '2099-01-05');
          v_out := 'accepted'; raise exception using errcode = 'P0W00';
        exception when sqlstate 'P0W00' then null; when foreign_key_violation then v_out := 'refused'; when others then v_out := 'other ' || sqlstate;
        end;
        if i = 1 then ctl := v_out; else xo := v_out; end if;
      end;
    end loop;
    insert into res values ('sessions.group_id', ctl, xo);

    -- ---- groups.client_id
    for i in 1..2 loop
      declare v_out text;
      begin
        begin
          insert into public.groups (organization_id, client_id, module, delivery_format) values (b, case i when 1 then b_client else w_client end, 'gaga', 'custom');
          v_out := 'accepted'; raise exception using errcode = 'P0W00';
        exception when sqlstate 'P0W00' then null; when foreign_key_violation then v_out := 'refused'; when others then v_out := 'other ' || sqlstate;
        end;
        if i = 1 then ctl := v_out; else xo := v_out; end if;
      end;
    end loop;
    insert into res values ('groups.client_id', ctl, xo);

    -- ---- groups.contract_id (the group's own client is Org B's either way)
    for i in 1..2 loop
      declare v_out text;
      begin
        begin
          insert into public.groups (organization_id, client_id, contract_id, module, delivery_format) values (b, b_client, case i when 1 then b_contract else w_contract end, 'gaga', 'custom');
          v_out := 'accepted'; raise exception using errcode = 'P0W00';
        exception when sqlstate 'P0W00' then null; when foreign_key_violation then v_out := 'refused'; when others then v_out := 'other ' || sqlstate;
        end;
        if i = 1 then ctl := v_out; else xo := v_out; end if;
      end;
    end loop;
    insert into res values ('groups.contract_id', ctl, xo);

    -- ---- payroll_period_totals.payroll_period_id
    for i in 1..2 loop
      declare v_out text;
      begin
        begin
          insert into public.payroll_period_totals (organization_id, payroll_period_id, trainer_id, legal_entity_id, amount_bani)
          values (b, case i when 1 then b_pp else w_pp end, bt, b_le, 0);
          v_out := 'accepted'; raise exception using errcode = 'P0W00';
        exception when sqlstate 'P0W00' then null; when foreign_key_violation then v_out := 'refused'; when others then v_out := 'other ' || sqlstate;
        end;
        if i = 1 then ctl := v_out; else xo := v_out; end if;
      end;
    end loop;
    insert into res values ('payroll_period_totals.payroll_period_id', ctl, xo);
  end;
  $$;

  select 'all 15 wave-1 keys were exercised' as check_name,
    (select count(*)::text from res) as actual, '15' as expected,
    (select count(*) = 15 from res) as pass
  union all
  select 'control accepted: ' || fk, control, 'accepted', control = 'accepted' from res
  union all
  select 'cross-org refused: ' || fk, cross_org, 'refused', cross_org = 'refused' from res;
rollback;

-- ============================================================================
-- Point 2 -- the band probe, permanent. A CONFIRMED wow-lab slot sits on the
-- Scoala Altfel 30-minute band; Test Org B's owner, through RLS, writes a
-- 9.0 band into wow-lab's live duration version. The slot's pay must not move.
-- Induced 2026-11-16 before the repair: 127,00 -> 1.143,00, guard silent.
-- ============================================================================
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.teo',  (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('app.wdur', app.resolve_grid_version(current_setting('app.org')::uuid, 'duration_multiplier', current_date)::text, true);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('55555555-0000-0000-0000-0000000000a1', current_setting('app.org')::uuid,
          (select client_id from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2'), 'gaga', 'scoala_altfel', 'ro_en');
  insert into public.sessions (id, organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at)
  values ('55555555-0000-0000-0000-0000000000b1', current_setting('app.org')::uuid, '55555555-0000-0000-0000-0000000000a1',
          '2026-10-21', 30, 'bucuresti', 'delivered', current_setting('app.teo')::uuid, now());
  select set_config('test.before', round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text, true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  begin
    insert into public.duration_multiplier_rates (organization_id, version_id, delivery_context, duration_minutes, multiplier)
    values (current_setting('app.orgb')::uuid, current_setting('app.wdur')::uuid, 'scoala_altfel_saptamana_verde', 30, 9.0);
  exception when foreign_key_violation then null;
  end;
  $$;
  select set_config('role', 'postgres', true);
  set constraints all immediate;

  select 'a confirmed wow-lab slot on the Altfel 30 band keeps its pay after Org B writes a band' as check_name,
    round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text as actual,
    current_setting('test.before') as expected,
    round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text = current_setting('test.before') as pass;
rollback;

-- ============================================================================
-- Point 3 -- the correction probe, permanent, on all four pay grids. This
-- checks NO amount: it checks that wow-lab STILL HAS A VERSION IN FORCE after
-- Test Org B's owner, through RLS, writes an Org B version whose
-- corrects_version_id names wow-lab's. Induced 2026-11-16 before the repair:
-- wow-lab's only grade version knocked out, 46 confirmed slots unpriceable --
-- a state where the engine gives no wrong figure, it gives no figure at all.
-- ============================================================================
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  create temp table targets on commit drop as
    select g as grid, app.resolve_grid_version(current_setting('app.org')::uuid, g, current_date) as wv
    from unnest(array['trainer_grade', 'duration_multiplier', 'location_bonus', 'language_bonus']) g;
  grant select on targets to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  declare t record; d date := '2099-04-01';  -- after every Org B session: the write cannot touch Org B's own pay, so only the cross-org effect is measured
  begin
    for t in select * from targets loop
      begin
        execute format('insert into public.%I_versions (organization_id, effective_date, created_by, corrects_version_id) values ($1, $2, $3, $4)', t.grid)
          using current_setting('app.orgb')::uuid, d, current_setting('app.bown')::uuid, t.wv;
      exception when foreign_key_violation then null;
      end;
      d := d + 1;
    end loop;
  end;
  $$;
  select set_config('role', 'postgres', true);
  set constraints all immediate;

  select 'wow-lab still has a ' || t.grid || ' version in force, and it is the same one' as check_name,
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, t.grid, current_date)::text, 'NONE') as actual,
    t.wv::text as expected,
    app.resolve_grid_version(current_setting('app.org')::uuid, t.grid, current_date) is not distinct from t.wv as pass
  from targets t;
rollback;

-- ============================================================================
-- Points 4-6 -- the correction probe's two layers, then the SABOTAGE.
--
-- The repair has two layers, either of which alone keeps wow-lab's version in
-- force: (a) the composite key on corrects_version_id refuses the cross-org
-- row; (b) app.resolve_grid_version's corrected-version subquery is filtered
-- on the organization, so even a cross-org row that got in would exclude
-- nothing outside its own organization. Removing ONE layer cannot fail point
-- 3 -- that is the point of having two -- so a single-layer sabotage would be
-- a check that cannot flip. Points 4 and 5 show each layer holding alone
-- (pass = true expected); point 6 removes both, and pass MUST be false.
-- trainer_grade only: it is the grid whose loss was measured.
-- ============================================================================

-- Point 4 -- layer (b) alone: the composite key reverted to the plain one.
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('app.wv', app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, true);
  alter table public.trainer_grade_versions drop constraint trainer_grade_versions_corrects_version_id_org_fkey;
  alter table public.trainer_grade_versions add constraint trainer_grade_versions_corrects_version_id_fkey
    foreign key (corrects_version_id) references public.trainer_grade_versions (id);
  insert into public.trainer_grade_versions (organization_id, effective_date, created_by, corrects_version_id)
  values (current_setting('app.orgb')::uuid, '2099-05-01', current_setting('app.bown')::uuid, current_setting('app.wv')::uuid);
  set constraints all immediate;
  select 'LAYER (b) alone: key reverted, the cross-org row is IN, wow-lab still has its grade version (subquery filter holds)' as check_name,
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, 'NONE') as actual,
    current_setting('app.wv') as expected,
    app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text = current_setting('app.wv') as pass;
rollback;

-- Point 5 -- layer (a) alone: the subquery filter removed, the key intact.
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('app.wv', app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, true);
  create or replace function app.resolve_grid_version(p_organization_id uuid, p_grid text, p_as_of date)
  returns uuid language plpgsql stable set search_path to '' as $sabotage$
  declare v uuid;
  begin
    if p_grid <> 'trainer_grade' then raise exception 'sabotage body covers trainer_grade only'; end if;
    select id into v from public.trainer_grade_versions
    where organization_id = p_organization_id and effective_date <= p_as_of
      and id not in (select corrects_version_id from public.trainer_grade_versions where corrects_version_id is not null)
    order by effective_date desc limit 1;
    return v;
  end;
  $sabotage$;
  do $$
  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, corrects_version_id)
    values (current_setting('app.orgb')::uuid, '2099-05-01', current_setting('app.bown')::uuid, current_setting('app.wv')::uuid);
  exception when foreign_key_violation then null;
  end;
  $$;
  select 'LAYER (a) alone: subquery filter removed, the key refuses the row, wow-lab still has its grade version' as check_name,
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, 'NONE') as actual,
    current_setting('app.wv') as expected,
    app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text = current_setting('app.wv') as pass;
rollback;

-- Point 6 -- SABOTAGE: both layers removed. Point 3's assertion, for
-- trainer_grade, must now be FALSE. If it is not, point 3 was not testing
-- the repair.
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('app.wv', app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, true);
  alter table public.trainer_grade_versions drop constraint trainer_grade_versions_corrects_version_id_org_fkey;
  alter table public.trainer_grade_versions add constraint trainer_grade_versions_corrects_version_id_fkey
    foreign key (corrects_version_id) references public.trainer_grade_versions (id);
  create or replace function app.resolve_grid_version(p_organization_id uuid, p_grid text, p_as_of date)
  returns uuid language plpgsql stable set search_path to '' as $sabotage$
  declare v uuid;
  begin
    if p_grid <> 'trainer_grade' then raise exception 'sabotage body covers trainer_grade only'; end if;
    select id into v from public.trainer_grade_versions
    where organization_id = p_organization_id and effective_date <= p_as_of
      and id not in (select corrects_version_id from public.trainer_grade_versions where corrects_version_id is not null)
    order by effective_date desc limit 1;
    return v;
  end;
  $sabotage$;
  insert into public.trainer_grade_versions (organization_id, effective_date, created_by, corrects_version_id)
  values (current_setting('app.orgb')::uuid, '2099-05-01', current_setting('app.bown')::uuid, current_setting('app.wv')::uuid);
  select 'SABOTAGE: wow-lab still has its trainer_grade version in force, same assertion as point 3, both layers removed' as check_name,
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, 'NONE') as actual,
    current_setting('app.wv') as expected,
    coalesce(app.resolve_grid_version(current_setting('app.org')::uuid, 'trainer_grade', current_date)::text, 'NONE') = current_setting('app.wv') as pass;
rollback;

-- ============================================================================
-- Point 7 -- SABOTAGE for point 2: the duration rates key reverted to the
-- plain one. Org B's band gets in, the guard (snapshotting the organization of
-- the row written) stays silent, the slot moves: pass MUST be false.
-- ============================================================================
begin;
  select set_config('app.org',  (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.teo',  (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('app.wdur', app.resolve_grid_version(current_setting('app.org')::uuid, 'duration_multiplier', current_date)::text, true);
  alter table public.duration_multiplier_rates drop constraint duration_multiplier_rates_version_id_org_fkey;
  alter table public.duration_multiplier_rates add constraint duration_multiplier_rates_version_id_fkey
    foreign key (version_id) references public.duration_multiplier_versions (id);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('55555555-0000-0000-0000-0000000000a1', current_setting('app.org')::uuid,
          (select client_id from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2'), 'gaga', 'scoala_altfel', 'ro_en');
  insert into public.sessions (id, organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at)
  values ('55555555-0000-0000-0000-0000000000b1', current_setting('app.org')::uuid, '55555555-0000-0000-0000-0000000000a1',
          '2026-10-21', 30, 'bucuresti', 'delivered', current_setting('app.teo')::uuid, now());
  select set_config('test.before', round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text, true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into public.duration_multiplier_rates (organization_id, version_id, delivery_context, duration_minutes, multiplier)
  values (current_setting('app.orgb')::uuid, current_setting('app.wdur')::uuid, 'scoala_altfel_saptamana_verde', 30, 9.0);
  select set_config('role', 'postgres', true);
  set constraints all immediate;

  select 'SABOTAGE: a confirmed wow-lab slot on the Altfel 30 band keeps its pay, same assertion as point 2, rates key reverted' as check_name,
    round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text as actual,
    current_setting('test.before') as expected,
    round(app.calculate_session_pay('55555555-0000-0000-0000-0000000000b1', current_setting('app.teo')::uuid), 2)::text = current_setting('test.before') as pass;
rollback;
