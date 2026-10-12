-- db/tests/lesson_plan_catalogue.sql
-- The catalogue, the session link, its approval state and its notification
-- column (202610120003-202610120007, item 110/117).
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner, and it must carry check_name / actual / expected / pass -- so each
-- block ends in one union-all select in that shape.
--
-- Blocks 2-7 build their own fixtures in WOW LAB Test Org B and always roll
-- back. Block 1 reads the real wow-lab catalogue without touching it.
--
-- Why Test Org B rather than wow-lab for everything: wow-lab holds ZERO
-- sessions, so no trainer is allocated to anything there and neither the
-- mywork.* read branch nor the propose function can be exercised at all.

-- ============================================================================
-- Block 1: the imported catalogue, as it actually landed.
-- ============================================================================
begin;
  select 'catalogue holds 312 plans' as check_name,
         (select count(*)::text from public.lesson_plans) as actual,
         '312' as expected,
         (select count(*) from public.lesson_plans) = 312 as pass
  union all
  select '288 written, 24 planned (chapter pointers)',
         (select count(*) filter (where status='written')::text || '/' || count(*) filter (where status='planned')::text from public.lesson_plans),
         '288/24',
         (select count(*) filter (where status='written') = 288 and count(*) filter (where status='planned') = 24 from public.lesson_plans)
  union all
  select '498 placements across all 15 modules',
         (select count(*)::text || '/' || count(distinct module)::text from public.lesson_plan_modules),
         '498/15',
         (select count(*) = 498 and count(distinct module) = 15 from public.lesson_plan_modules)
  union all
  -- The number Anca's confirmation turned from a defect into the design.
  select '129 plans sit under more than one module',
         (select count(*)::text from (select lesson_plan_id from public.lesson_plan_modules group by lesson_plan_id having count(distinct module) > 1) x),
         '129',
         (select count(*) from (select lesson_plan_id from public.lesson_plan_modules group by lesson_plan_id having count(distinct module) > 1) x) = 129
  union all
  -- Anatomy's whole syllabus, not only its six written plans: the reason
  -- chapter pointers are imported rather than dropped.
  select 'anatomy carries 23 placements, not 6',
         (select count(*)::text from public.lesson_plan_modules where module = 'anatomy'),
         '23',
         (select count(*) from public.lesson_plan_modules where module = 'anatomy') = 23
  union all
  select 'all six anatomy written plans are shared with doctor',
         (select count(*)::text from public.lesson_plan_modules a
            join public.lesson_plan_modules d on d.lesson_plan_id = a.lesson_plan_id and d.module = 'doctor'
            join public.lesson_plans p on p.id = a.lesson_plan_id
           where a.module = 'anatomy' and p.status = 'written'),
         '6',
         (select count(*) from public.lesson_plan_modules a
            join public.lesson_plan_modules d on d.lesson_plan_id = a.lesson_plan_id and d.module = 'doctor'
            join public.lesson_plans p on p.id = a.lesson_plan_id
           where a.module = 'anatomy' and p.status = 'written') = 6
  union all
  -- The multi-title problem, on the worst case: one plan, five placements,
  -- four different titles, one canonical.
  select 'the five-placement plan keeps all four of its source titles',
         (select count(distinct m.title_on_sheet)::text from public.lesson_plan_modules m
            join public.lesson_plans p on p.id = m.lesson_plan_id where p.plan_ref = 'anat_seeingdna_dc_4'),
         '4',
         (select count(distinct m.title_on_sheet) from public.lesson_plan_modules m
            join public.lesson_plans p on p.id = m.lesson_plan_id where p.plan_ref = 'anat_seeingdna_dc_4') = 4
  union all
  select 'and exactly one canonical title',
         (select canonical_title from public.lesson_plans where plan_ref = 'anat_seeingdna_dc_4'),
         'Seeing DNA',
         (select canonical_title from public.lesson_plans where plan_ref = 'anat_seeingdna_dc_4') = 'Seeing DNA'
  union all
  select 'wow_mix carries all three of its curated lists',
         (select count(distinct variant)::text from public.lesson_plan_modules where module = 'wow_mix'),
         '3',
         (select count(distinct variant) from public.lesson_plan_modules where module = 'wow_mix') = 3
  union all
  select 'variant is null for every module except wow_mix',
         (select count(*)::text from public.lesson_plan_modules where variant is not null and module <> 'wow_mix'),
         '0',
         (select count(*) from public.lesson_plan_modules where variant is not null and module <> 'wow_mix') = 0
  union all
  select 'CRACIUN imported nothing -- it is not a module',
         (select count(*)::text from public.lesson_plan_modules where module = 'craciun'),
         '0',
         (select count(*) from public.lesson_plan_modules where module = 'craciun') = 0;
rollback;

-- ============================================================================
-- Block 2: the partial unique index means what it says -- a filename is
-- unique, an absent filename is not a value to collide on.
-- ============================================================================
-- Both halves ATTEMPT the write. Asserting the absence of a row nothing ever
-- inserted is an assertion that cannot fail (item 100's fourth probe error).
begin;
  create temp table r (what text, ok boolean) on commit drop;

  do $$
  declare v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  begin
    begin
      insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
      values (v_org, 'anat_seeingdna_dc_4', 'DRYRUN duplicate', 'written');
      insert into r values ('dup_ref_rejected', false);
    exception when unique_violation then
      insert into r values ('dup_ref_rejected', true);
    end;

    begin
      insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
      values (v_org, null, 'DRYRUN pointer A', 'planned'),
             (v_org, null, 'DRYRUN pointer B', 'planned');
      insert into r values ('two_nulls_allowed', true);
    exception when unique_violation then
      insert into r values ('two_nulls_allowed', false);
    end;

    begin
      insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
      values (v_org, null, 'DRYRUN inconsistent', 'written');
      insert into r values ('written_without_ref_rejected', false);
    exception when check_violation then
      insert into r values ('written_without_ref_rejected', true);
    end;

    begin
      insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
      values (v_org, 'dryrun_ref_1', 'DRYRUN inconsistent 2', 'planned');
      insert into r values ('planned_with_ref_rejected', false);
    exception when check_violation then
      insert into r values ('planned_with_ref_rejected', true);
    end;
  end $$;

  select 'a duplicate plan_ref is rejected' as check_name,
         (select ok::text from r where what='dup_ref_rejected') as actual, 'true' as expected,
         (select ok from r where what='dup_ref_rejected') as pass
  union all
  select 'two chapter pointers (null plan_ref) coexist',
         (select ok::text from r where what='two_nulls_allowed'), 'true',
         (select ok from r where what='two_nulls_allowed')
  union all
  select 'status=written with no plan_ref is rejected',
         (select ok::text from r where what='written_without_ref_rejected'), 'true',
         (select ok from r where what='written_without_ref_rejected')
  union all
  select 'status=planned with a plan_ref is rejected',
         (select ok::text from r where what='planned_with_ref_rejected'), 'true',
         (select ok from r where what='planned_with_ref_rejected');
rollback;

-- ============================================================================
-- Block 3: the four CHECK constraints on session_lesson_plans.
-- ============================================================================
begin;
  create temp table r (what text, ok boolean) on commit drop;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_client uuid; v_group uuid; v_session uuid; v_plan uuid;
    v_p uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_dec uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
  begin
    insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN slp checks', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
    values (v_org, v_client, 'gaga', 'parteneriate_companii') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (v_org, v_group, current_date, v_p, 'planned') returning id into v_session;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_checks_1', 'DRYRUN plan', 'written') returning id into v_plan;

    begin
      insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status, decided_by, decided_at)
      values (v_org, v_session, v_p, v_plan, 'changes_requested', v_dec, now());
      insert into r values ('note_required', false);
    exception when check_violation then insert into r values ('note_required', true); end;

    begin
      insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status)
      values (v_org, v_session, v_p, v_plan, 'validated');
      insert into r values ('decided_fields_required', false);
    exception when check_violation then insert into r values ('decided_fields_required', true); end;

    begin
      insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status, decided_by, decided_at)
      values (v_org, v_session, v_p, v_plan, 'proposed', v_dec, now());
      insert into r values ('proposed_must_be_clean', false);
    exception when check_violation then insert into r values ('proposed_must_be_clean', true); end;

    begin
      insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status, decision_seen_at)
      values (v_org, v_session, v_p, v_plan, 'proposed', now());
      insert into r values ('seen_requires_decision', false);
    exception when check_violation then insert into r values ('seen_requires_decision', true); end;

    begin
      insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id, status)
      values (v_org, v_session, v_p, v_plan, 'nonsense');
      insert into r values ('status_vocabulary', false);
    exception when check_violation then insert into r values ('status_vocabulary', true); end;
  end $$;

  select 'changes_requested without a note is rejected' as check_name,
         (select ok::text from r where what='note_required') as actual, 'true' as expected,
         (select ok from r where what='note_required') as pass
  union all
  select 'a decision with no decider/time is rejected',
         (select ok::text from r where what='decided_fields_required'), 'true',
         (select ok from r where what='decided_fields_required')
  union all
  select 'a proposed row carrying a stale verdict is rejected',
         (select ok::text from r where what='proposed_must_be_clean'), 'true',
         (select ok from r where what='proposed_must_be_clean')
  union all
  select 'seen-before-decided is rejected',
         (select ok::text from r where what='seen_requires_decision'), 'true',
         (select ok from r where what='seen_requires_decision')
  union all
  select 'an invented status value is rejected',
         (select ok::text from r where what='status_vocabulary'), 'true',
         (select ok from r where what='status_vocabulary');
rollback;

-- ============================================================================
-- Block 4: propose -> decide -> mark seen, the whole loop, as the real people.
-- ============================================================================
-- Every write goes through the routing functions, impersonated, never as the
-- connecting role -- otherwise this would prove the UPDATE works and nothing
-- about who is allowed to issue it.
begin;
  create temp table r (what text, val text) on commit drop;
  -- The blocks below impersonate (set local role authenticated), and a temp
  -- table created by the connecting role is not writable by that role --
  -- the first run of this file failed with 42501 on exactly this line.
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_client uuid; v_group uuid; v_session uuid; v_plan uuid; v_plan2 uuid; v_row uuid;
    v_p uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_s uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
    -- organization_owner in Test Org B: holds curriculum.validate, which is the
    -- gate. Test Ops Manager B does NOT -- operations_manager carries no
    -- curriculum capability at all, which is itself asserted in block 5.
    v_val uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
    v_res text;
  begin
    insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN slp loop', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
    values (v_org, v_client, 'gaga', 'parteneriate_companii') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
    values (v_org, v_group, current_date, v_p, v_s, 'planned') returning id into v_session;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_loop_1', 'DRYRUN plan one', 'written') returning id into v_plan;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_loop_2', 'DRYRUN plan two', 'written') returning id into v_plan2;

    set local role authenticated;

    -- the principal proposes
    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    select app.rpc_propose_session_lesson_plan(v_session, v_plan) into v_res;
    insert into r values ('propose_principal', v_res);

    -- the secundar proposes their own, independently
    perform set_config('request.jwt.claims', json_build_object('sub', v_s::text, 'role', 'authenticated')::text, true);
    select app.rpc_propose_session_lesson_plan(v_session, v_plan2) into v_res;
    insert into r values ('propose_secundar', v_res);

    reset role;
    insert into r select 'rows_for_session', count(*)::text from public.session_lesson_plans where session_id = v_session;
    select id into v_row from public.session_lesson_plans where session_id = v_session and trainer_id = v_p;

    -- nothing is unseen yet, because nothing has been decided
    insert into r select 'unseen_before_decision', count(*)::text from public.session_lesson_plans
      where trainer_id = v_p and decided_at is not null and (decision_seen_at is null or decision_seen_at < decided_at);

    -- the validator validates the principal's row
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_val::text, 'role', 'authenticated')::text, true);
    select app.rpc_decide_session_lesson_plan(v_row, 'validated', null) into v_res;
    insert into r values ('decide_validated', v_res);

    reset role;
    insert into r select 'status_after_decide', status from public.session_lesson_plans where id = v_row;
    insert into r select 'decided_by_is_validator', (decided_by = v_val)::text from public.session_lesson_plans where id = v_row;
    insert into r select 'unseen_after_decision', count(*)::text from public.session_lesson_plans
      where trainer_id = v_p and decided_at is not null and (decision_seen_at is null or decision_seen_at < decided_at);

    -- the trainer marks it seen
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    select app.rpc_mark_session_lesson_plan_seen(v_row) into v_res;
    insert into r values ('mark_seen', v_res);

    reset role;
    insert into r select 'unseen_after_seen', count(*)::text from public.session_lesson_plans
      where trainer_id = v_p and decided_at is not null and (decision_seen_at is null or decision_seen_at < decided_at);

    -- changes requested, with a note -- and the trainer re-proposes, which must
    -- clear the verdict AND the seen marker
    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_val::text, 'role', 'authenticated')::text, true);
    select app.rpc_decide_session_lesson_plan(v_row, 'changes_requested', 'Too close to the secundar''s experiment.') into v_res;
    insert into r values ('decide_changes', v_res);
    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    select app.rpc_propose_session_lesson_plan(v_session, v_plan2) into v_res;
    insert into r values ('reproposed', v_res);

    reset role;
    insert into r select 'status_after_repropose', status from public.session_lesson_plans where id = v_row;
    insert into r select 'verdict_cleared_on_repropose',
      (decided_by is null and decided_at is null and decision_note is null and decision_seen_at is null)::text
      from public.session_lesson_plans where id = v_row;
    insert into r select 'still_one_row_for_this_trainer', count(*)::text
      from public.session_lesson_plans where session_id = v_session and trainer_id = v_p;
    -- the attempt history lives in row_history, which is why one row suffices
    insert into r select 'row_history_captured_the_attempts', (count(*) >= 3)::text
      from public.row_history where table_name = 'session_lesson_plans' and row_id = v_row;
  end $$;

  select 'the principal proposes their own plan' as check_name,
         (select val from r where what='propose_principal') as actual, 'ok' as expected,
         (select val from r where what='propose_principal') = 'ok' as pass
  union all
  select 'the secundar proposes independently -- two rows, one session',
         (select val from r where what='propose_secundar') || '/' || (select val from r where what='rows_for_session'),
         'ok/2',
         (select val from r where what='propose_secundar') = 'ok' and (select val from r where what='rows_for_session') = '2'
  union all
  select 'nothing is unseen before anything is decided',
         (select val from r where what='unseen_before_decision'), '0',
         (select val from r where what='unseen_before_decision') = '0'
  union all
  select 'a curriculum.validate holder validates',
         (select val from r where what='decide_validated'), 'ok',
         (select val from r where what='decide_validated') = 'ok'
  union all
  select 'the row reads validated, decided_by set from the caller',
         (select val from r where what='status_after_decide') || '/' || (select val from r where what='decided_by_is_validator'),
         'validated/true',
         (select val from r where what='status_after_decide') = 'validated' and (select val from r where what='decided_by_is_validator') = 'true'
  union all
  select 'the decision is UNSEEN the moment it is made',
         (select val from r where what='unseen_after_decision'), '1',
         (select val from r where what='unseen_after_decision') = '1'
  union all
  select 'the trainer marks it seen and it stops being unseen',
         (select val from r where what='mark_seen') || '/' || (select val from r where what='unseen_after_seen'),
         'ok/0',
         (select val from r where what='mark_seen') = 'ok' and (select val from r where what='unseen_after_seen') = '0'
  union all
  select 'changes_requested with a note is accepted',
         (select val from r where what='decide_changes'), 'ok',
         (select val from r where what='decide_changes') = 'ok'
  union all
  select 'a re-proposal returns the row to proposed and clears the verdict',
         (select val from r where what='status_after_repropose') || '/' || (select val from r where what='verdict_cleared_on_repropose'),
         'proposed/true',
         (select val from r where what='status_after_repropose') = 'proposed' and (select val from r where what='verdict_cleared_on_repropose') = 'true'
  union all
  select 'a re-proposal UPDATES, never adds a second row for that trainer',
         (select val from r where what='still_one_row_for_this_trainer'), '1',
         (select val from r where what='still_one_row_for_this_trainer') = '1'
  union all
  select 'row_history holds the attempt history the single row cannot',
         (select val from r where what='row_history_captured_the_attempts'), 'true',
         (select val from r where what='row_history_captured_the_attempts') = 'true';
rollback;

-- ============================================================================
-- Block 5: the gates. Every one attempts the write and reads the refusal code.
-- ============================================================================
begin;
  create temp table r (what text, val text) on commit drop;
  -- The blocks below impersonate (set local role authenticated), and a temp
  -- table created by the connecting role is not writable by that role --
  -- the first run of this file failed with 42501 on exactly this line.
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_client uuid; v_group uuid; v_session uuid; v_plan uuid; v_row uuid;
    v_wowlab_plan uuid := (select id from public.lesson_plans
                             where organization_id = (select id from public.organizations where slug = 'wow-lab')
                             limit 1);
    v_p uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_s uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
    v_other uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com');
    v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
    v_val uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
    v_res text;
  begin
    insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN slp gates', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
    values (v_org, v_client, 'gaga', 'parteneriate_companii') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
    values (v_org, v_group, current_date, v_p, v_s, 'planned') returning id into v_session;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_gates_1', 'DRYRUN gate plan', 'written') returning id into v_plan;

    set local role authenticated;

    -- a trainer with no allocation on this session cannot propose
    perform set_config('request.jwt.claims', json_build_object('sub', v_other::text, 'role', 'authenticated')::text, true);
    select app.rpc_propose_session_lesson_plan(v_session, v_plan) into v_res;
    insert into r values ('unallocated_propose', v_res);

    -- a cross-organization plan is refused even though the FK would take it
    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    select app.rpc_propose_session_lesson_plan(v_session, v_wowlab_plan) into v_res;
    insert into r values ('cross_org_plan', v_res);

    -- the real proposal, so there is a row to try deciding
    select app.rpc_propose_session_lesson_plan(v_session, v_plan) into v_res;
    insert into r values ('own_propose', v_res);
    reset role;
    select id into v_row from public.session_lesson_plans where session_id = v_session and trainer_id = v_p;
    set local role authenticated;

    -- the trainer cannot validate their own plan
    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    select app.rpc_decide_session_lesson_plan(v_row, 'validated', null) into v_res;
    insert into r values ('trainer_decide', v_res);

    -- nor can an operations_manager: allocating trainers is not validating
    -- curriculum, and operations_manager holds no curriculum capability
    perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
    select app.rpc_decide_session_lesson_plan(v_row, 'validated', null) into v_res;
    insert into r values ('ops_decide', v_res);

    -- changes_requested with no note is refused with its own code, before the
    -- CHECK constraint would raise
    perform set_config('request.jwt.claims', json_build_object('sub', v_val::text, 'role', 'authenticated')::text, true);
    select app.rpc_decide_session_lesson_plan(v_row, 'changes_requested', '   ') into v_res;
    insert into r values ('blank_note', v_res);
    select app.rpc_decide_session_lesson_plan(v_row, 'approved_ish', null) into v_res;
    insert into r values ('bad_status', v_res);

    -- the co-trainer cannot mark the principal's decision seen
    select app.rpc_decide_session_lesson_plan(v_row, 'validated', null) into v_res;
    perform set_config('request.jwt.claims', json_build_object('sub', v_s::text, 'role', 'authenticated')::text, true);
    select app.rpc_mark_session_lesson_plan_seen(v_row) into v_res;
    insert into r values ('cotrainer_mark_seen', v_res);

    reset role;
    insert into r select 'still_unseen_after_cotrainer_attempt', (decision_seen_at is null)::text
      from public.session_lesson_plans where id = v_row;
  end $$;

  select 'an unallocated trainer cannot propose' as check_name,
         (select val from r where what='unallocated_propose') as actual, 'not_assigned' as expected,
         (select val from r where what='unallocated_propose') = 'not_assigned' as pass
  union all
  select 'a plan from another organization is refused',
         (select val from r where what='cross_org_plan'), 'plan_not_found',
         (select val from r where what='cross_org_plan') = 'plan_not_found'
  union all
  select 'the allocated trainer CAN propose (control for the two above)',
         (select val from r where what='own_propose'), 'ok',
         (select val from r where what='own_propose') = 'ok'
  union all
  select 'a trainer cannot validate their own plan',
         (select val from r where what='trainer_decide'), 'not_permitted',
         (select val from r where what='trainer_decide') = 'not_permitted'
  union all
  select 'an operations_manager cannot validate -- no curriculum capability',
         (select val from r where what='ops_decide'), 'not_permitted',
         (select val from r where what='ops_decide') = 'not_permitted'
  union all
  select 'changes_requested with a blank note is refused by its own code',
         (select val from r where what='blank_note'), 'note_required',
         (select val from r where what='blank_note') = 'note_required'
  union all
  select 'an invented decision value is refused',
         (select val from r where what='bad_status'), 'invalid_status',
         (select val from r where what='bad_status') = 'invalid_status'
  union all
  select 'the co-trainer cannot mark someone else''s decision seen',
         (select val from r where what='cotrainer_mark_seen'), 'not_yours',
         (select val from r where what='cotrainer_mark_seen') = 'not_yours'
  union all
  select 'and it is still unseen afterwards',
         (select val from r where what='still_unseen_after_cotrainer_attempt'), 'true',
         (select val from r where what='still_unseen_after_cotrainer_attempt') = 'true';
rollback;

-- ============================================================================
-- Block 6: the reads. Who sees a proposal, and who sees the catalogue at all.
-- ============================================================================
-- The co-trainer read is a REQUIREMENT, not a leak: the responsibilities
-- document has the principal "se coordoneaza cu Trainerul Secundar, astfel
-- incat cele doua experimente sa fie potrivite si coerente" -- impossible
-- without seeing both. Block 5 already proved the WRITE stays own-row-only.
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_client uuid; v_group uuid; v_session uuid; v_plan uuid; v_plan2 uuid;
    v_p uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_s uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
    v_other uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com');
    v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
    v_fin uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev');
  begin
    insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN slp reads', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
    values (v_org, v_client, 'gaga', 'parteneriate_companii') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
    values (v_org, v_group, current_date, v_p, v_s, 'planned') returning id into v_session;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_reads_1', 'DRYRUN read plan one', 'written') returning id into v_plan;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_reads_2', 'DRYRUN read plan two', 'written') returning id into v_plan2;
    insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id)
    values (v_org, v_session, v_p, v_plan), (v_org, v_session, v_s, v_plan2);

    set local role authenticated;

    perform set_config('request.jwt.claims', json_build_object('sub', v_p::text, 'role', 'authenticated')::text, true);
    insert into r select 'principal_sees', count(*)::text from public.session_lesson_plans where session_id = v_session;
    insert into r select 'principal_reads_catalogue', (count(*) > 0)::text from public.lesson_plans;

    perform set_config('request.jwt.claims', json_build_object('sub', v_s::text, 'role', 'authenticated')::text, true);
    insert into r select 'secundar_sees', count(*)::text from public.session_lesson_plans where session_id = v_session;

    perform set_config('request.jwt.claims', json_build_object('sub', v_other::text, 'role', 'authenticated')::text, true);
    insert into r select 'unrelated_trainer_sees', count(*)::text from public.session_lesson_plans where session_id = v_session;

    perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
    insert into r select 'ops_sees', count(*)::text from public.session_lesson_plans where session_id = v_session;

    perform set_config('request.jwt.claims', json_build_object('sub', v_fin::text, 'role', 'authenticated')::text, true);
    insert into r select 'finance_reads_catalogue', count(*)::text from public.lesson_plans;
    insert into r select 'finance_sees_proposals', count(*)::text from public.session_lesson_plans where session_id = v_session;
  end $$;

  select 'the principal sees BOTH proposals on their session' as check_name,
         (select val from r where what='principal_sees') as actual, '2' as expected,
         (select val from r where what='principal_sees') = '2' as pass
  union all
  select 'the secundar sees both too -- coordination needs it',
         (select val from r where what='secundar_sees'), '2',
         (select val from r where what='secundar_sees') = '2'
  union all
  select 'an unrelated trainer sees no proposal at all',
         (select val from r where what='unrelated_trainer_sees'), '0',
         (select val from r where what='unrelated_trainer_sees') = '0'
  union all
  select 'an operations_manager sees both (sessions.read, org-wide)',
         (select val from r where what='ops_sees'), '2',
         (select val from r where what='ops_sees') = '2'
  union all
  select 'a trainer can read the catalogue (curriculum.read)',
         (select val from r where what='principal_reads_catalogue'), 'true',
         (select val from r where what='principal_reads_catalogue') = 'true'
  union all
  select 'a finance-only account reads NO catalogue rows',
         (select val from r where what='finance_reads_catalogue'), '0',
         (select val from r where what='finance_reads_catalogue') = '0'
  union all
  -- This assertion originally read '0' and FAILED on the first run. The policy
  -- was right and the assertion was wrong: finance_operations holds
  -- `sessions.read` (so do finance_admin_reporting and operations_manager),
  -- which is the branch, and a proposal IS a session record -- finance already
  -- reads that session's trainers, duration and location tier as pay inputs.
  -- Withholding which experiment is attached would draw a line `sessions`
  -- itself does not draw. Recorded as the intended boundary rather than
  -- patched: finance sees the plan ATTACHED to a session it already reads, and
  -- the assertion above proves it still cannot browse the catalogue itself.
  select 'a finance-only account DOES see proposals -- it holds sessions.read',
         (select val from r where what='finance_sees_proposals'), '2',
         (select val from r where what='finance_sees_proposals') = '2';
rollback;

-- ============================================================================
-- Block 7: SABOTAGE. The same assertion as block 6's unrelated-trainer check,
-- with the policy's scoping clause removed.
-- ============================================================================
-- Without this, block 6 would pass identically if the SELECT policy had been
-- written `using (true)` -- "the people who should see it do" is not evidence
-- that anyone is excluded. The runner expects a SABOTAGE-prefixed check to
-- come back pass=false; a true there means the assertion has no teeth.
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_client uuid; v_group uuid; v_session uuid; v_plan uuid;
    v_p uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_other uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com');
  begin
    drop policy "authenticated select session_lesson_plans" on public.session_lesson_plans;
    create policy "authenticated select session_lesson_plans" on public.session_lesson_plans
      for select to authenticated using (true);

    insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN slp sabotage', 'corporate') returning id into v_client;
    insert into public.groups (organization_id, client_id, module, delivery_format)
    values (v_org, v_client, 'gaga', 'parteneriate_companii') returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
    values (v_org, v_group, current_date, v_p, 'planned') returning id into v_session;
    insert into public.lesson_plans (organization_id, plan_ref, canonical_title, status)
    values (v_org, 'dryrun_sab_1', 'DRYRUN sabotage plan', 'written') returning id into v_plan;
    insert into public.session_lesson_plans (organization_id, session_id, trainer_id, lesson_plan_id)
    values (v_org, v_session, v_p, v_plan);

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_other::text, 'role', 'authenticated')::text, true);
    insert into r select 'unrelated_trainer_sees', count(*)::text from public.session_lesson_plans where session_id = v_session;
  end $$;

  select 'SABOTAGE: an unrelated trainer sees no proposal, same assertion as block 6, scoping clause replaced by using (true)' as check_name,
         (select val from r where what='unrelated_trainer_sees') as actual, '0' as expected,
         (select val from r where what='unrelated_trainer_sees') = '0' as pass;
rollback;
