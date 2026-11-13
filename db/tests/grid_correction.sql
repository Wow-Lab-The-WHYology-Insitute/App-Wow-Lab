-- db/tests/grid_correction.sql
-- OPEN_ITEMS.md item 195 / 202611140001 -- the sanctioned correction path:
-- the exception to item 194's guard, made visible and recorded.
--
-- Every correction here goes through the real RPCs as a real Test Org B
-- account, and the approved fixture slot is approved through the real
-- app.rpc_approve_session_pay as the Operations Manager account.
--
-- Fixture, rolled back in each block: Test Org B, trainer 82b99dfb (grade 2)
-- as principal, group bda1f577 (ro_en, standard duration), 120 min, location
-- imprejurimi --
--   S1 2026-09-15 confirmed, NOT approved  -> must move with the correction
--   S2 2026-09-16 confirmed AND approved   -> must be listed as frozen, not moved

-- ============================================================================
-- Block 1: the whole trainer_grade flow -- preview writes nothing, a tampered
-- statement is refused, the real one applies, the approved slot stays
-- frozen and is listed, the record holds what was confirmed.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('t.ops', (select id::text from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'), true);
  select set_config('t.v', app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text, true);

  create temp table s (k text primary key, id uuid) on commit drop;
  with ins as (
    insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
    values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction S1'),
           (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-16', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction S2')
    returning id, notes)
  insert into s select right(notes, 2), id from ins;

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', case when grade_level = 2 then rate + 10 else rate end))
    from public.trainer_grade_rates where version_id = current_setting('t.v')::uuid;
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload, s to authenticated;
  grant all on r to authenticated;

  -- S2 approved the real way, by the Operations Manager.
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.ops'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'approve', to_jsonb(array_agg(a.status)) from public.rpc_approve_session_pay(array[(select id from s where k = 'S2')]) a;
  select set_config('role', 'postgres', true);
  insert into r select 'frozen_before', to_jsonb(trainer_principal_approved_amount_bani) from public.sessions where id = (select id from s where k = 'S2');

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST correction', (select rows from payload where k = 'changed'));
  insert into r select 'left_after_preview', to_jsonb((select count(*) from public.trainer_grade_versions where corrects_version_id = current_setting('t.v')::uuid));
  insert into r select 'tampered', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST correction', (select rows from payload where k = 'changed'),
    jsonb_set((select res->'declaration' from r where k = 'preview'), '{summary,total_after}', '1'::jsonb));
  insert into r select 'left_after_tampered', to_jsonb((select count(*) from public.trainer_grade_versions where corrects_version_id = current_setting('t.v')::uuid));
  insert into r select 'apply', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST correction', (select rows from payload where k = 'changed'),
    (select res->'declaration' from r where k = 'preview'));
  insert into r select 'again', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST correction', (select rows from payload where k = 'changed'),
    (select res->'declaration' from r where k = 'preview'));
  insert into r select 'record_visible', to_jsonb((select count(*) from public.grid_corrections where version_id = ((select res->>'id' from r where k = 'apply'))::uuid));
  select set_config('role', 'postgres', true);

  insert into r select 'pay_s1_after', to_jsonb(p.amount) from app.calculate_org_session_pay(current_setting('t.org')::uuid, '2026-09-15', '2026-09-16') p where p.session_id = (select id from s where k = 'S1');
  insert into r select 'frozen_after', to_jsonb(trainer_principal_approved_amount_bani) from public.sessions where id = (select id from s where k = 'S2');

  select 'S2 was approved through the real approval RPC (fixture precondition)' as check_name,
         (select res::text from r where k = 'approve') as actual, '["approved"]' as expected,
         (select res from r where k = 'approve') = '["approved"]'::jsonb as pass
  union all
  select 'preview lists the unapproved S1 as affected and never the approved S2',
         (select (res->'declaration'->'summary'->>'slots') from r where k = 'preview') || ' slot(s) affected',
         'S1 in affected, S2 not',
         (select exists (select 1 from jsonb_array_elements(res->'declaration'->'affected') e where (e->>'session_id')::uuid = (select id from s where k = 'S1'))
             and not exists (select 1 from jsonb_array_elements(res->'declaration'->'affected') e where (e->>'session_id')::uuid = (select id from s where k = 'S2'))
          from r where k = 'preview')
  union all
  select 'preview lists the approved S2 as frozen, with what the corrected rate would compute',
         (select (res->'declaration'->'frozen'->0->>'frozen') || ' -> would be ' || (res->'declaration'->'frozen'->0->>'would_be') from r where k = 'preview'),
         'frozen = approved amount, would_be > frozen',
         (select (res->'declaration'->'frozen'->0->>'session_id')::uuid = (select id from s where k = 'S2')
             and (res->'declaration'->'frozen'->0->>'frozen')::numeric * 100 = (select res::text::numeric from r where k = 'frozen_before')
             and (res->'declaration'->'frozen'->0->>'would_be')::numeric > (res->'declaration'->'frozen'->0->>'frozen')::numeric
          from r where k = 'preview')
  union all
  select 'preview writes nothing',
         (select res::text from r where k = 'left_after_preview'), '0', (select res::text from r where k = 'left_after_preview') = '0'
  union all
  select 'a statement that differs from the recomputed one is refused (declaration_stale), and returns the real one',
         (select res->>'error' from r where k = 'tampered'), 'declaration_stale',
         (select res->>'error' = 'declaration_stale' and res->'declaration' = (select res->'declaration' from r where k = 'preview') from r where k = 'tampered')
  union all
  select 'the refused correction leaves nothing behind',
         (select res::text from r where k = 'left_after_tampered'), '0', (select res::text from r where k = 'left_after_tampered') = '0'
  union all
  select 'the confirmed statement applies',
         (select res->>'ok' from r where k = 'apply'), 'true', (select (res->>'ok')::boolean from r where k = 'apply')
  union all
  select 'the shared resolver now returns the correcting version for the corrected period',
         app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text,
         (select res->>'id' from r where k = 'apply'),
         app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text = (select res->>'id' from r where k = 'apply')
  union all
  select 'the correcting version shares the corrected version''s effective date and points at it',
         (select v.effective_date::text || ' -> ' || v.corrects_version_id::text from public.trainer_grade_versions v where v.id = (select res->>'id' from r where k = 'apply')::uuid),
         'same date -> corrected id',
         (select v.effective_date = o.effective_date and v.corrects_version_id = o.id
            from public.trainer_grade_versions v, public.trainer_grade_versions o
           where v.id = (select res->>'id' from r where k = 'apply')::uuid and o.id = current_setting('t.v')::uuid)
  union all
  select 'S1 (unapproved) is now paid what the statement said',
         (select res::text from r where k = 'pay_s1_after'),
         (select e->>'after' from r, jsonb_array_elements(res->'declaration'->'affected') e where k = 'preview' and (e->>'session_id')::uuid = (select id from s where k = 'S1')),
         (select res::text::numeric from r where k = 'pay_s1_after')
           = (select (e->>'after')::numeric from r, jsonb_array_elements(res->'declaration'->'affected') e where k = 'preview' and (e->>'session_id')::uuid = (select id from s where k = 'S1'))
  union all
  select 'S2 (approved) keeps its frozen amount',
         (select res::text from r where k = 'frozen_after'), (select res::text from r where k = 'frozen_before'),
         (select res from r where k = 'frozen_after') = (select res from r where k = 'frozen_before')
  union all
  select 'grid_corrections holds exactly the statement that was confirmed, and the finance user can read it',
         (select res::text from r where k = 'record_visible'), '1',
         (select res::text from r where k = 'record_visible') = '1'
         and (select declaration from public.grid_corrections where version_id = (select res->>'id' from r where k = 'apply')::uuid)
             = (select res->'declaration' from r where k = 'preview')
  union all
  select 'grid_corrections duplicates no who/when column (the version row holds them)',
         (select string_agg(column_name, ',' order by column_name) from information_schema.columns where table_schema = 'public' and table_name = 'grid_corrections' and column_name ~ '(_by|actor|user)'),
         null, (select count(*) from information_schema.columns where table_schema = 'public' and table_name = 'grid_corrections' and column_name ~ '(_by|actor|user)') = 0
  union all
  select 'a corrected version cannot be corrected a second time (correct the correction instead)',
         (select res->>'error' from r where k = 'again'), 'already_corrected', (select res->>'error' from r where k = 'again') = 'already_corrected';
rollback;

-- ============================================================================
-- Block 2: the statement goes stale for a REAL reason, the shape measured on
-- 2026-11-12 (Cătălina confirmed 10 sessions in 5 minutes): between preview
-- and apply, another session in range is confirmed. The apply is refused and
-- hands back the new statement, which then applies.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('t.v', app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text, true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction stale A');

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', case when grade_level = 2 then rate + 10 else rate end))
    from public.trainer_grade_rates where version_id = current_setting('t.v')::uuid;
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST stale', (select rows from payload where k = 'changed'));
  select set_config('role', 'postgres', true);

  -- Meanwhile, a trainer confirms another session in the corrected period.
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-22', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction stale B');

  select set_config('role', 'authenticated', true);
  insert into r select 'apply_old', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST stale', (select rows from payload where k = 'changed'),
    (select res->'declaration' from r where k = 'preview'));
  insert into r select 'left', to_jsonb((select count(*) from public.trainer_grade_versions where corrects_version_id = current_setting('t.v')::uuid));
  insert into r select 'apply_new', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST stale', (select rows from payload where k = 'changed'),
    (select res->'declaration' from r where k = 'apply_old'));
  select set_config('role', 'postgres', true);

  select 'a statement confirmed before another session was confirmed is refused at write time' as check_name,
         (select res->>'error' from r where k = 'apply_old') as actual, 'declaration_stale' as expected,
         (select res->>'error' from r where k = 'apply_old') = 'declaration_stale' as pass
  union all
  select 'the refusal hands back the new statement, one slot larger',
         (select (res->'declaration'->'summary'->>'slots') from r where k = 'apply_old'),
         ((select (res->'declaration'->'summary'->>'slots')::int from r where k = 'preview') + 1)::text,
         (select (res->'declaration'->'summary'->>'slots')::int from r where k = 'apply_old') = (select (res->'declaration'->'summary'->>'slots')::int from r where k = 'preview') + 1
  union all
  select 'nothing was written by the refused apply',
         (select res::text from r where k = 'left'), '0', (select res::text from r where k = 'left') = '0'
  union all
  select 'the new statement, confirmed, applies',
         (select res->>'ok' from r where k = 'apply_new'), 'true', (select (res->>'ok')::boolean from r where k = 'apply_new');
rollback;

-- ============================================================================
-- Block 3: the other three grids, location and language newly given
-- corrects_version_id by this migration -- each corrected through the RPC,
-- and the shared resolver stops returning the corrected version.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction other grids');

  create temp table v (grid text primary key, id uuid, rows jsonb) on commit drop;
  insert into v select 'location_bonus', app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', '2026-09-15'),
    (select jsonb_agg(jsonb_build_object('location_tier', location_tier, 'bonus_percent', case when location_tier = 'imprejurimi' then bonus_percent + 5 else bonus_percent end))
       from public.location_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'location_bonus', '2026-09-15'));
  insert into v select 'language_bonus', app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', '2026-09-15'),
    (select jsonb_agg(jsonb_build_object('language_group', language_group, 'bonus_percent', case when language_group = 'ro_en' then bonus_percent + 5 else bonus_percent end))
       from public.language_bonus_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'language_bonus', '2026-09-15'));
  insert into v select 'duration_multiplier', app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', '2026-09-15'),
    (select jsonb_agg(jsonb_build_object('duration_minutes', duration_minutes, 'delivery_context', delivery_context,
              'multiplier', case when duration_minutes = 120 and delivery_context = 'standard' then multiplier + 0.1 else multiplier end))
       from public.duration_multiplier_rates where version_id = app.resolve_grid_version(current_setting('t.org')::uuid, 'duration_multiplier', '2026-09-15'));
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on v to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  -- One grid at a time: each applied correction re-prices the confirmed
  -- slots, so a preview taken before it would (rightly) be stale after it.
  insert into r select 'preview:location_bonus', public.rpc_preview_grid_correction(grid, id, 'TEST other', rows) from v where grid = 'location_bonus';
  insert into r select 'apply:location_bonus', public.rpc_apply_grid_correction(grid, id, 'TEST other', rows, (select res->'declaration' from r where k = 'preview:location_bonus')) from v where grid = 'location_bonus';
  insert into r select 'preview:language_bonus', public.rpc_preview_grid_correction(grid, id, 'TEST other', rows) from v where grid = 'language_bonus';
  insert into r select 'apply:language_bonus', public.rpc_apply_grid_correction(grid, id, 'TEST other', rows, (select res->'declaration' from r where k = 'preview:language_bonus')) from v where grid = 'language_bonus';
  insert into r select 'preview:duration_multiplier', public.rpc_preview_grid_correction(grid, id, 'TEST other', rows) from v where grid = 'duration_multiplier';
  insert into r select 'apply:duration_multiplier', public.rpc_apply_grid_correction(grid, id, 'TEST other', rows, (select res->'declaration' from r where k = 'preview:duration_multiplier')) from v where grid = 'duration_multiplier';
  select set_config('role', 'postgres', true);

  select g || ': preview finds the confirmed slots the correction moves (fixture S + Test Org B''s own)' as check_name,
         (select res->'declaration'->'summary'->>'slots' from r where k = 'preview:' || g) as actual, '>= 1' as expected,
         (select (res->'declaration'->'summary'->>'slots')::int >= 1 from r where k = 'preview:' || g) as pass
    from unnest(array['location_bonus', 'language_bonus', 'duration_multiplier']) g
  union all
  select g || ': the confirmed statement applies',
         (select res->>'ok' from r where k = 'apply:' || g), 'true', (select (res->>'ok')::boolean from r where k = 'apply:' || g)
    from unnest(array['location_bonus', 'language_bonus', 'duration_multiplier']) g
  union all
  select g || ': the shared resolver stops returning the corrected version',
         app.resolve_grid_version(current_setting('t.org')::uuid, g, '2026-09-15')::text, (select res->>'id' from r where k = 'apply:' || g),
         app.resolve_grid_version(current_setting('t.org')::uuid, g, '2026-09-15')::text = (select res->>'id' from r where k = 'apply:' || g)
    from unnest(array['location_bonus', 'language_bonus', 'duration_multiplier']) g;
rollback;

-- ============================================================================
-- Block 4: the gate, walked by real accounts (§25). PROVISIONAL gate: the
-- approval gate. Operations Manager (finance.approvals.approve only) passes;
-- a trainer is refused; a Finance Admin Reporting holder -- who CAN create an
-- ordinary version through the grids' INSERT policy -- is refused a
-- correction. Test Org B has no such holder, so the role is granted to a
-- trainer account inside this rolled-back block.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.ops', (select id::text from public.users where email = 'test+ui-ops-manager-b@wowlab.dev'), true);
  select set_config('t.trn', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('t.rep', (select id::text from public.users where email = 'maxdigitalro+trainerb2@gmail.com'), true);
  insert into public.user_org_roles (user_id, organization_id, role_id)
  values (current_setting('t.rep')::uuid, current_setting('t.org')::uuid, (select id from public.roles where key = 'finance_admin_reporting'));
  select set_config('t.v', app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text, true);

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'same', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', rate))
    from public.trainer_grade_rates where version_id = current_setting('t.v')::uuid;
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.ops'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'ops', public.rpc_preview_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST gate', (select rows from payload where k = 'same'));
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.trn'), 'role', 'authenticated')::text, true);
  insert into r select 'trainer', public.rpc_preview_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST gate', (select rows from payload where k = 'same'));
  insert into r select 'trainer_apply', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST gate', (select rows from payload where k = 'same'), '{}'::jsonb);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.rep'), 'role', 'authenticated')::text, true);
  insert into r select 'reporting', public.rpc_preview_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST gate', (select rows from payload where k = 'same'));
  insert into r select 'reporting_ordinary', public.rpc_create_grid_version('trainer_grade', current_setting('t.org')::uuid, current_date + 2000, 'TEST gate ordinary', (select rows from payload where k = 'same'));
  select set_config('role', 'postgres', true);

  select 'Operations Manager (finance.approvals.approve only) passes the correction gate' as check_name,
         (select res->>'ok' from r where k = 'ops') as actual, 'true' as expected, (select (res->>'ok')::boolean from r where k = 'ops') as pass
  union all
  select 'a trainer is refused a correction preview',
         (select res->>'error' from r where k = 'trainer'), 'forbidden', (select res->>'error' from r where k = 'trainer') = 'forbidden'
  union all
  select 'a trainer is refused a correction apply',
         (select res->>'error' from r where k = 'trainer_apply'), 'forbidden', (select res->>'error' from r where k = 'trainer_apply') = 'forbidden'
  union all
  select 'Finance Admin Reporting is refused a correction (provisional approval gate)',
         (select res->>'error' from r where k = 'reporting'), 'forbidden', (select res->>'error' from r where k = 'reporting') = 'forbidden'
  union all
  select 'Finance Admin Reporting can still create an ordinary future version (gate difference is deliberate)',
         (select res->>'ok' from r where k = 'reporting_ordinary'), 'true', (select (res->>'ok')::boolean from r where k = 'reporting_ordinary');
rollback;

-- ============================================================================
-- Block 5: grid_corrections cannot be written around the RPC by an app user,
-- and a corrects_version_id alone does not sanction anything: a
-- migration-style correction with no confirmed statement is refused by the
-- ordinary rule.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('t.v', app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text, true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction unsanctioned');
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant all on r to authenticated;

  do $$
  begin
    perform set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
    perform set_config('role', 'authenticated', true);
    begin
      insert into public.grid_corrections (organization_id, grid, version_id, declaration)
      values (current_setting('t.org')::uuid, 'trainer_grade', gen_random_uuid(), '{}');
      insert into r values ('direct_insert', '"allowed"');
    exception when insufficient_privilege then
      insert into r values ('direct_insert', '"42501"');
    end;
    perform set_config('role', 'postgres', true);
  end $$;

  do $$
  declare v_new uuid;
  begin
    begin
      insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note, corrects_version_id)
        select organization_id, effective_date, created_by, 'TEST unsanctioned', id from public.trainer_grade_versions where id = current_setting('t.v')::uuid
        returning id into v_new;
      insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
        select organization_id, v_new, grade_level, rate + 10 from public.trainer_grade_rates where version_id = current_setting('t.v')::uuid;
      set constraints all immediate;
      insert into r values ('unsanctioned', '"passed"');
    exception when sqlstate 'P0W01' then
      insert into r values ('unsanctioned', '"P0W01"');
    end;
    set constraints all deferred;
  end $$;

  select 'an app user cannot write grid_corrections directly' as check_name,
         (select res #>> '{}' from r where k = 'direct_insert') as actual, '42501' as expected,
         (select res #>> '{}' from r where k = 'direct_insert') = '42501' as pass
  union all
  select 'a correcting version with no confirmed statement is refused like any other re-pricing',
         (select res #>> '{}' from r where k = 'unsanctioned'), 'P0W01', (select res #>> '{}' from r where k = 'unsanctioned') = 'P0W01';
rollback;

-- ============================================================================
-- Block 6: SABOTAGE -- with the guard triggers disabled, a tampered statement
-- is no longer refused. Proves block 1's stale check is the guard's doing,
-- not an accident of the RPC.
-- ============================================================================
begin;
  select set_config('t.org', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('t.fin', (select id::text from public.users where email = 'test+ui-contract-admin-b@wowlab.dev'), true);
  select set_config('t.v', app.resolve_grid_version(current_setting('t.org')::uuid, 'trainer_grade', '2026-09-15')::text, true);
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, location_tier, status, trainer_principal_id, trainer_principal_confirmed_at, notes)
  values (current_setting('t.org')::uuid, 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2026-09-15', 120, 'imprejurimi', 'delivered', '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', now(), 'TEST grid_correction sabotage');
  alter table public.trainer_grade_versions disable trigger trainer_grade_versions_guard_confirmed_pay;
  alter table public.trainer_grade_rates disable trigger trainer_grade_rates_guard_confirmed_pay;

  create temp table payload (k text primary key, rows jsonb) on commit drop;
  insert into payload select 'changed', jsonb_agg(jsonb_build_object('grade_level', grade_level, 'rate', case when grade_level = 2 then rate + 10 else rate end))
    from public.trainer_grade_rates where version_id = current_setting('t.v')::uuid;
  create temp table r (k text primary key, res jsonb) on commit drop;
  grant select on payload to authenticated;
  grant all on r to authenticated;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('t.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'tampered', public.rpc_apply_grid_correction('trainer_grade', current_setting('t.v')::uuid, 'TEST sabotage', (select rows from payload where k = 'changed'),
    '{"summary": {"slots": 0}}'::jsonb);
  select set_config('role', 'postgres', true);

  select 'SABOTAGE: with the guard disabled, a tampered statement is still refused' as check_name,
         (select coalesce(res->>'error', 'ok') from r where k = 'tampered') as actual, 'declaration_stale' as expected,
         (select res->>'error' from r where k = 'tampered') = 'declaration_stale' as pass;
rollback;
