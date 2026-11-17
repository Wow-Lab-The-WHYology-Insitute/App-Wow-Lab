-- db/tests/pay_input_guard.sql
-- WOW LAB OS: item 194's guard, extended to the two pay inputs it did not
-- cover (OPEN_ITEMS item 196): grade assignments, and a group's pay columns
-- (language_group, delivery_format). A change to either that re-prices
-- confirmed, not-yet-approved pay is refused (P0W01), unless it carries a
-- confirmed impact statement (item 195's sanctioned form) -- now held in
-- grid_corrections shaped as Mihai's option (b): one column per target, a
-- CHECK that exactly one is set, a composite key on each.
--
-- Written BEFORE the migration and run against the live schema first,
-- failing (§27 / item 198's practice). Amounts are asserted by SIGN and
-- count, not by exact lei: the real confirmed set grows as trainers confirm,
-- and the property is "refused, and says what moved", not "this many lei".
--
-- §27 throughout: every refusal has a control that must PASS (the same kind
-- of write, one variable changed), so a refusal can only mean the guard.
-- Every block is BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- CONTROL: a grade change that moves no confirmed pay is ACCEPTED.
-- Teodora at 4 from 01.10: her confirmed sessions are all in September
-- (item 196, P1). If this were refused, every refusal below would mean
-- nothing.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values ((select id from public.organizations where slug = 'wow-lab'), (select id from public.users where email = 'merisanteodora@gmail.com'),
            4, '2026-10-01', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'manual');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL: a grade change that moves no confirmed pay is accepted' as check_name,
    (select v from r) as actual, 'accepted' as expected, (select v from r) = 'accepted' as pass;
rollback;

-- ============================================================================
-- Point 2 -- a retroactive PROMOTION that re-prices confirmed pay is refused,
-- and the refusal says what moved (item 196, P3: Teodora 4 from 02.09).
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare d text;
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values ((select id from public.organizations where slug = 'wow-lab'), (select id from public.users where email = 'merisanteodora@gmail.com'),
            4, '2026-09-02', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'manual');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'a retroactive promotion that re-prices confirmed pay is refused (P0W01)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass
  union all
  select 'the refusal names the grade assignment and a POSITIVE delta on at least one slot',
    (select v from r where k = 'detail'), 'grid=trainer_grade_assignment, slots>0, delta>0',
    coalesce((select (v::jsonb->>'grid') = 'trainer_grade_assignment' and (v::jsonb->>'slots')::int > 0 and (v::jsonb->>'delta')::numeric > 0 from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 3 -- a retroactive DEMOTION is refused the same way, and the
-- statement carries the NEGATIVE delta (item 196 P4, item 197 point 3: a
-- grade model must support going down, and so must its guard).
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare d text;
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values ((select id from public.organizations where slug = 'wow-lab'), (select id from public.users where email = 'catalina_moale@yahoo.com'),
            5, '2026-10-01', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'manual');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'a retroactive demotion that re-prices confirmed pay is refused (P0W01)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass
  union all
  select 'the demotion''s refusal carries a NEGATIVE delta',
    (select v from r where k = 'detail'), 'slots>0, delta<0',
    coalesce((select (v::jsonb->>'slots')::int > 0 and (v::jsonb->>'delta')::numeric < 0 from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 4 -- a group's language change, through the group form's own path
-- (column grant + RLS, as the Organization Owner), is refused when the group
-- carries confirmed pay (item 196 P6). CONTROL: the identical change on a
-- fresh wow-lab group with no confirmed session is accepted.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('77777777-0000-0000-0000-0000000000a1', (select id from public.organizations where slug = 'wow-lab'),
          (select client_id from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2'), 'gaga', 'scoli_private_recurente', 'ro_en');
  select set_config('request.jwt.claims', json_build_object('sub', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  declare d text;
  begin
    update public.groups set language_group = 'fr_de_es' where id = 'c1000000-0000-0000-0000-0000000000b2';
    set constraints all immediate;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('probe', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  do $$
  begin
    update public.groups set language_group = 'fr_de_es' where id = '77777777-0000-0000-0000-0000000000a1';
    set constraints all immediate;
    insert into r values ('control', 'accepted');
  exception when others then insert into r values ('control', 'refused ' || sqlstate);
  end $$;
  select set_config('role', 'postgres', true);
  select 'CONTROL: the same language change on a group with no confirmed session is accepted' as check_name,
    (select v from r where k = 'control') as actual, 'accepted' as expected, (select v from r where k = 'control') = 'accepted' as pass
  union all
  select 'a group language change that re-prices confirmed pay is refused (P0W01), through the form''s own path',
    (select v from r where k = 'probe'), 'refused P0W01', (select v from r where k = 'probe') = 'refused P0W01'
  union all
  select 'the refusal names the group''s pay columns and at least one slot',
    (select v from r where k = 'detail'), 'grid=group_pay, slots>0',
    coalesce((select (v::jsonb->>'grid') = 'group_pay' and (v::jsonb->>'slots')::int > 0 from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 5 -- the sanctioned path for a grade change: preview gives the
-- guard's own statement; apply with exactly that statement passes and is
-- recorded; apply with a statement that is not the recomputation is refused
-- as stale.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teo', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('request.jwt.claims', json_build_object('sub', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_grade_assignment(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, 4, '2026-09-02');
  insert into r select 'stale', public.rpc_apply_grade_assignment(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, 4, '2026-09-02',
    jsonb_set((select v->'declaration' from r where k = 'preview'), '{summary,slots}', '0'));
  insert into r select 'apply', public.rpc_apply_grade_assignment(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, 4, '2026-09-02',
    (select v->'declaration' from r where k = 'preview'));
  select set_config('role', 'postgres', true);

  select 'preview returns the statement: at least one slot, positive delta' as check_name,
    (select (v->'declaration'->'summary')::text from r where k = 'preview') as actual, 'ok, slots>0, delta>0' as expected,
    coalesce((select (v->>'ok')::boolean and (v->'declaration'->'summary'->>'slots')::int > 0 and (v->'declaration'->'summary'->>'delta')::numeric > 0 from r where k = 'preview'), false) as pass
  union all
  select 'apply with a statement that is not the recomputation is refused as stale',
    (select v->>'error' from r where k = 'stale'), 'declaration_stale', (select v->>'error' from r where k = 'stale') = 'declaration_stale'
  union all
  select 'apply with the confirmed statement passes',
    (select v::text from r where k = 'apply'), 'ok', coalesce((select (v->>'ok')::boolean from r where k = 'apply'), false)
  union all
  select 'Teodora now resolves to grade 4 on 16.09',
    app.resolve_trainer_grade(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, '2026-09-16')::text, '4',
    app.resolve_trainer_grade(current_setting('app.org')::uuid, current_setting('app.teo')::uuid, '2026-09-16') = 4
  union all
  select 'exactly one statement, on the assignment column, equal to the preview',
    (select string_agg(target, ',') from public.grid_corrections where trainer_grade_assignment_id is not null), 'trainer_grade_assignment',
    (select count(*) = 1 and bool_and(target = 'trainer_grade_assignment')
            and bool_and(declaration = (select v->'declaration' from r where k = 'preview'))
     from public.grid_corrections where trainer_grade_assignment_id is not null);
rollback;

-- ============================================================================
-- Point 6 -- the sanctioned path for a group's pay columns.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  select set_config('request.jwt.claims', json_build_object('sub', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_group_pay_change('c1000000-0000-0000-0000-0000000000b2', 'fr_de_es', null);
  insert into r select 'apply', public.rpc_apply_group_pay_change('c1000000-0000-0000-0000-0000000000b2', 'fr_de_es', null,
    (select v->'declaration' from r where k = 'preview'));
  select set_config('role', 'postgres', true);

  select 'group preview returns the statement: at least one slot, positive delta' as check_name,
    (select (v->'declaration'->'summary')::text from r where k = 'preview') as actual, 'ok, slots>0, delta>0' as expected,
    coalesce((select (v->>'ok')::boolean and (v->'declaration'->'summary'->>'slots')::int > 0 and (v->'declaration'->'summary'->>'delta')::numeric > 0 from r where k = 'preview'), false) as pass
  union all
  select 'group apply with the confirmed statement passes, and the language changed',
    (select language_group from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2'), 'fr_de_es',
    coalesce((select (v->>'ok')::boolean from r where k = 'apply'), false)
      and (select language_group from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2') = 'fr_de_es'
  union all
  select 'the statement is recorded on the group column',
    (select string_agg(target, ',') from public.grid_corrections where group_id = 'c1000000-0000-0000-0000-0000000000b2'), 'group_pay',
    (select count(*) = 1 and bool_and(target = 'group_pay') from public.grid_corrections where group_id = 'c1000000-0000-0000-0000-0000000000b2');
rollback;

-- ============================================================================
-- Point 7 -- the gate (§25, walked by real accounts): a trainer cannot
-- preview a grade change; a person who does not belong to the organization
-- cannot be given a grade in it.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.lorina', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);
  select set_config('app.owner', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('app.outsider', (select id::text from public.users where email = 'maxdigitalro+trainerb1@gmail.com'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.lorina'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'trainer', public.rpc_preview_grade_assignment(current_setting('app.org')::uuid, current_setting('app.lorina')::uuid, 6, '2026-09-02');
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.owner'), 'role', 'authenticated')::text, true);
  insert into r select 'outsider', public.rpc_preview_grade_assignment(current_setting('app.org')::uuid, current_setting('app.outsider')::uuid, 3, '2026-09-02');
  select set_config('role', 'postgres', true);
  select 'a trainer cannot preview a grade change (gate)' as check_name,
    (select v->>'error' from r where k = 'trainer') as actual, 'forbidden' as expected, (select v->>'error' from r where k = 'trainer') = 'forbidden' as pass
  union all
  select 'a person outside the organization cannot be given a grade in it',
    (select v->>'error' from r where k = 'outsider'), 'not_member', (select v->>'error' from r where k = 'outsider') = 'not_member';
rollback;

-- ============================================================================
-- Point 8 -- option (b), structural. Exactly one target per statement; each
-- target keyed with its organization. CONTROL for the cross-org probe: the
-- same row on wow-lab's own target is accepted. The keys are DEFERRED (the
-- guards' undo needs it), so every write here forces the check at once:
-- without that, "accepted" would measure WHEN the key is checked, not
-- WHETHER it holds (§27).
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare
    w uuid := (select id from public.organizations where slug = 'wow-lab');
    b uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    g uuid := 'c1000000-0000-0000-0000-0000000000b2';
    a uuid := (select id from public.trainer_grade_assignments where organization_id = (select id from public.organizations where slug = 'wow-lab') order by id limit 1);
  begin
    begin insert into public.grid_corrections (organization_id, group_id, declaration) values (w, g, '{}'); set constraints all immediate; raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W00' then insert into r values ('control', 'accepted'); when others then insert into r values ('control', 'refused ' || sqlstate); end;
    begin insert into public.grid_corrections (organization_id, group_id, declaration) values (b, g, '{}'); set constraints all immediate; raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W00' then insert into r values ('cross_org', 'accepted'); when foreign_key_violation then insert into r values ('cross_org', 'refused'); when others then insert into r values ('cross_org', 'other ' || sqlstate); end;
    begin insert into public.grid_corrections (organization_id, group_id, trainer_grade_assignment_id, declaration) values (w, g, a, '{}'); set constraints all immediate; raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W00' then insert into r values ('two', 'accepted'); when check_violation then insert into r values ('two', 'refused'); when others then insert into r values ('two', 'other ' || sqlstate); end;
    begin insert into public.grid_corrections (organization_id, declaration) values (w, '{}'); set constraints all immediate; raise exception using errcode = 'P0W00';
    exception when sqlstate 'P0W00' then insert into r values ('none', 'accepted'); when check_violation then insert into r values ('none', 'refused'); when others then insert into r values ('none', 'other ' || sqlstate); end;
  end $$;
  select 'CONTROL: a statement on one wow-lab target is accepted' as check_name, (select v from r where k = 'control') as actual, 'accepted' as expected, (select v from r where k = 'control') = 'accepted' as pass
  union all select 'a statement naming another organization''s target is refused (composite key)', (select v from r where k = 'cross_org'), 'refused', (select v from r where k = 'cross_org') = 'refused'
  union all select 'a statement with two targets is refused (exactly one)', (select v from r where k = 'two'), 'refused', (select v from r where k = 'two') = 'refused'
  union all select 'a statement with no target is refused (exactly one)', (select v from r where k = 'none'), 'refused', (select v from r where k = 'none') = 'refused';
rollback;

-- ============================================================================
-- Point 9 -- found while building: UNIQUE (trainer_id, effective_from) had no
-- organization, so a grade row Org B writes for a shared person on a date
-- blocked wow-lab from writing the same person on the same date -- item
-- 198's class on a unique key. Org B writes first (through RLS), then
-- wow-lab writes the same person and date: must be accepted.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  select set_config('app.orgb', (select id::text from public.organizations where slug = 'wow-lab-test-b'), true);
  select set_config('app.teo',  (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.bown', (select id::text from public.users where email = 'test+user-b@wowlab.dev'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.bown'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (current_setting('app.orgb')::uuid, current_setting('app.teo')::uuid, 2, '2099-01-01', current_setting('app.bown')::uuid, 'manual');
  select set_config('role', 'postgres', true);
  do $$
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values ((select id from public.organizations where slug = 'wow-lab'), (select id from public.users where email = 'merisanteodora@gmail.com'),
            3, '2099-01-01', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'manual');
    insert into r values ('result', 'accepted');
  exception when others then insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'an Org B grade row does not block wow-lab from the same person on the same date' as check_name,
    (select v from r) as actual, 'accepted' as expected, (select v from r) = 'accepted' as pass;
rollback;

-- ============================================================================
-- Point 10 -- SABOTAGE for point 2: the assignment guard removed. The
-- retroactive promotion gets in silently; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger trainer_grade_assignments_guard_confirmed_pay on public.trainer_grade_assignments;
  do $$
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values ((select id from public.organizations where slug = 'wow-lab'), (select id from public.users where email = 'merisanteodora@gmail.com'),
            4, '2026-09-02', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'manual');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
  end $$;
  select 'SABOTAGE: a retroactive promotion that re-prices confirmed pay is refused, same assertion as point 2, guard removed' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 11 -- SABOTAGE for point 4: the group guard removed. pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  drop trigger groups_guard_confirmed_pay on public.groups;
  select set_config('request.jwt.claims', json_build_object('sub', (select id from public.users where email = 'maxdigitalro@gmail.com'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  begin
    update public.groups set language_group = 'fr_de_es' where id = 'c1000000-0000-0000-0000-0000000000b2';
    set constraints all immediate;
    insert into r values ('probe', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('probe', 'refused P0W01');
  end $$;
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: a group language change that re-prices confirmed pay is refused, same assertion as point 4, guard removed' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 12 -- the author of a statement (202611170003). A sanctioned group
-- change is applied by the Organization Owner; a Finance Operations account
-- WITHOUT org.audit.read (the person this exists for, §25) asks who made it.
-- It must get exactly ONE answer -- that change's author and moment -- even
-- though the group already carries other history rows (precondition, shown
-- non-empty, §27; group de6e6f56 has 2 real rows at 2 earlier moments --
-- c1...b2 had NONE, so a free search would also have returned one row and
-- the sabotage could never have flipped: caught when it passed), and reading row_history directly must still give it 0:
-- the access comes from the function bound to the statement, not from a
-- widened policy.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  select set_config('app.owner', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('app.fin',   (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  select set_config('test.history_before', (select count(*)::text from public.row_history where table_name = 'groups' and row_id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558'), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.owner'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_group_pay_change('de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558', 'fr_de_es', null);
  insert into r select 'apply', public.rpc_apply_group_pay_change('de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558', 'fr_de_es', null, (select v->'declaration' from r where k = 'preview'));
  select set_config('role', 'postgres', true);
  select set_config('test.stmt', (select id::text from public.grid_corrections where group_id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558'), true);
  select set_config('test.stmt_at', (select created_at::text from public.grid_corrections where group_id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558'), true);

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'author', coalesce((select jsonb_agg(to_jsonb(a)) from public.correction_statement_author(current_setting('test.stmt')::uuid) a), '[]'::jsonb);
  insert into r select 'direct_history', to_jsonb((select count(*) from public.row_history where table_name = 'groups'));
  select set_config('role', 'postgres', true);

  select 'precondition: the group already has other history rows, so "exactly one" is a measurement' as check_name,
    current_setting('test.history_before') as actual, '>= 1' as expected, current_setting('test.history_before')::int >= 1 as pass
  union all
  select 'a finance user without org.audit.read gets exactly ONE author for the statement',
    (select jsonb_array_length(v)::text from r where k = 'author'), '1', (select jsonb_array_length(v) = 1 from r where k = 'author')
  union all
  select 'the author is the person who made the change, at the statement''s own moment',
    (select v->0->>'actor_user_id' from r where k = 'author'), current_setting('app.owner'),
    coalesce((select v->0->>'actor_user_id' = current_setting('app.owner')
                     and (v->0->>'changed_at')::timestamptz = current_setting('test.stmt_at')::timestamptz from r where k = 'author'), false)
  union all
  select 'it returns the author and the moment, nothing else (no old/new values)',
    (select string_agg(key_name, ',' order by key_name) from r, jsonb_object_keys(r.v->0) as keys(key_name) where r.k = 'author'), 'actor_user_id,changed_at',
    (select string_agg(key_name, ',' order by key_name) from r, jsonb_object_keys(r.v->0) as keys(key_name) where r.k = 'author') = 'actor_user_id,changed_at'
  union all
  select 'the same finance user still reads 0 rows of row_history directly (no widened policy)',
    (select v::text from r where k = 'direct_history'), '0', (select v::text from r where k = 'direct_history') = '0';
rollback;

-- ============================================================================
-- Point 13 -- the author's gate: the statements' own. A trainer gets nothing;
-- an id that is not a statement gets nothing.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  select set_config('app.owner',  (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('app.lorina', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.owner'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_group_pay_change('c1000000-0000-0000-0000-0000000000b2', 'fr_de_es', null);
  insert into r select 'apply', public.rpc_apply_group_pay_change('c1000000-0000-0000-0000-0000000000b2', 'fr_de_es', null, (select v->'declaration' from r where k = 'preview'));
  insert into r select 'owner', to_jsonb((select count(*) from public.correction_statement_author((select id from public.grid_corrections where group_id = 'c1000000-0000-0000-0000-0000000000b2'))));
  insert into r select 'not_a_statement', to_jsonb((select count(*) from public.correction_statement_author(gen_random_uuid())));
  select set_config('role', 'postgres', true);
  select set_config('test.stmt', (select id::text from public.grid_corrections where group_id = 'c1000000-0000-0000-0000-0000000000b2'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.lorina'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'trainer', to_jsonb((select count(*) from public.correction_statement_author(current_setting('test.stmt')::uuid)));
  select set_config('role', 'postgres', true);
  select 'CONTROL: a reader of statements gets the author' as check_name, (select v::text from r where k = 'owner') as actual, '1' as expected, (select v::text from r where k = 'owner') = '1' as pass
  union all select 'a trainer gets nothing', (select v::text from r where k = 'trainer'), '0', (select v::text from r where k = 'trainer') = '0'
  union all select 'an id that is not a statement gets nothing', (select v::text from r where k = 'not_a_statement'), '0', (select v::text from r where k = 'not_a_statement') = '0';
rollback;

-- ============================================================================
-- Point 14 -- SABOTAGE for point 12: the function turned into a FREE search
-- of the group's history (every row, any moment) -- the back door around
-- org.audit.read it must not be. "Exactly one" must flip.
-- ============================================================================
begin;
  create temp table r (k text, v jsonb) on commit drop;
  grant all on r to authenticated;
  create or replace function app.correction_statement_author(p_statement_id uuid)
  returns table (actor_user_id uuid, changed_at timestamptz)
  language sql stable security definer set search_path = '' as $sabotage$
    select h.actor_user_id, h.changed_at from public.row_history h
    join public.grid_corrections g on g.group_id = h.row_id
    where g.id = p_statement_id and h.table_name = 'groups';
  $sabotage$;
  select set_config('app.owner', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('app.fin',   (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.owner'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'preview', public.rpc_preview_group_pay_change('de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558', 'fr_de_es', null);
  insert into r select 'apply', public.rpc_apply_group_pay_change('de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558', 'fr_de_es', null, (select v->'declaration' from r where k = 'preview'));
  select set_config('role', 'postgres', true);
  select set_config('test.stmt', (select id::text from public.grid_corrections where group_id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.fin'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into r select 'author', coalesce((select jsonb_agg(to_jsonb(a)) from public.correction_statement_author(current_setting('test.stmt')::uuid) a), '[]'::jsonb);
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: a finance user gets exactly ONE author for the statement, same assertion as point 12, function turned into a free search' as check_name,
    (select jsonb_array_length(v)::text from r where k = 'author') as actual, '1' as expected,
    (select jsonb_array_length(v) = 1 from r where k = 'author') as pass;
rollback;
