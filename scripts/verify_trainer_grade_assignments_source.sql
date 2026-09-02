-- verify_trainer_grade_assignments_source.sql
-- Dry-run verification for
-- supabase/migrations/202609020001_add_trainer_grade_assignments_source.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Column-only migration, no backfill possible (the table is empty). This
-- script verifies exactly that: the column exists, is NOT NULL, has no
-- default, the CHECK rejects a third value, an insert omitting the
-- column fails, a valid insert with either allowed value succeeds, and
-- app.resolve_trainer_grade() is byte-identical before and after --
-- proving the migration touches only the table, not the function that
-- reads it.
--
-- Run with: supabase db query --linked --file scripts/verify_trainer_grade_assignments_source.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- snapshot the resolver's definition BEFORE the ALTER, then
-- mirror 202609020001's DDL exactly.
-- ============================================================================

select set_config('app.pre_alter_resolver_def', (select pg_get_functiondef('app.resolve_trainer_grade(uuid, date)'::regprocedure)), true);

alter table public.trainer_grade_assignments
  add column source text not null
    check (source in ('computed', 'manual'));

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_finance_ops', (select id::text from users where email = 'test+finance-ops-a@wowlab.dev'), true);
select set_config('app.test_trainer', (select id::text from users where email = 'test+trainer-a@wowlab.dev'), true);

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_finance_ops'), 'role', 'authenticated')::text, true);

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_org uuid := current_setting('app.test_org_a')::uuid;
  v_trainer uuid := current_setting('app.test_trainer')::uuid;
  v_finance_ops uuid := current_setting('app.test_finance_ops')::uuid;
  v_col_nullable text;
  v_col_default text;
  v_check_def text;
  v_caught boolean;
  v_sqlstate text;
  v_insert_id uuid;
  v_post_alter_resolver_def text;
begin
  -- ---- 1. column exists ----
  select is_nullable, column_default into v_col_nullable, v_col_default
  from information_schema.columns
  where table_schema = 'public' and table_name = 'trainer_grade_assignments' and column_name = 'source';

  if v_col_nullable is not null then
    report := report || E'\n1. PASS - trainer_grade_assignments.source exists';
  else
    report := report || E'\n1. FAIL - trainer_grade_assignments.source does not exist';
  end if;

  -- ---- 2. is NOT NULL ----
  if v_col_nullable = 'NO' then
    report := report || E'\n2. PASS - source is NOT NULL';
  else
    report := report || format(E'\n2. FAIL - expected is_nullable=NO, got %s', v_col_nullable);
  end if;

  -- ---- 3. has no default ----
  if v_col_default is null then
    report := report || E'\n3. PASS - source has no column default';
  else
    report := report || format(E'\n3. FAIL - expected no default, got %s', v_col_default);
  end if;

  -- ---- 4. CHECK rejects a third value ----
  begin
    insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values (v_org, v_trainer, 3, current_date, v_finance_ops, 'guessed');
    report := report || E'\n4. FAIL - expected check_violation inserting source=''guessed'', but the insert succeeded';
  exception
    when check_violation then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n4. PASS - source=''guessed'' raised check_violation (sqlstate %s)', v_sqlstate);
  end;

  -- ---- 5. insert omitting source fails ----
  begin
    insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by)
    values (v_org, v_trainer, 3, current_date, v_finance_ops);
    report := report || E'\n5. FAIL - expected not_null_violation omitting source entirely, but the insert succeeded';
  exception
    when not_null_violation then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      report := report || format(E'\n5. PASS - omitting source raised not_null_violation (sqlstate %s)', v_sqlstate);
  end;

  -- ---- 6a. a valid 'manual' insert succeeds ----
  insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (v_org, v_trainer, 3, current_date, v_finance_ops, 'manual')
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n6a. PASS - source=''manual'' insert succeeds';
  else
    report := report || E'\n6a. FAIL - the manual insert did not return an id';
  end if;

  -- ---- 6b. a valid 'computed' insert succeeds (different effective_from,
  -- trainer_date_unique otherwise rejects a same-day second row) ----
  insert into trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (v_org, v_trainer, 2, current_date - 1, v_finance_ops, 'computed')
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n6b. PASS - source=''computed'' insert succeeds';
  else
    report := report || E'\n6b. FAIL - the computed insert did not return an id';
  end if;

  -- ---- 7. app.resolve_trainer_grade is byte-identical before and after ----
  v_post_alter_resolver_def := pg_get_functiondef('app.resolve_trainer_grade(uuid, date)'::regprocedure);

  if v_post_alter_resolver_def = current_setting('app.pre_alter_resolver_def') then
    report := report || E'\n7. PASS - app.resolve_trainer_grade() definition is byte-identical before and after the ALTER -- this migration touches only the table';
  else
    report := report || E'\n7. FAIL - app.resolve_trainer_grade() definition changed:'
      || E'\n--- before ---\n' || current_setting('app.pre_alter_resolver_def')
      || E'\n--- after ---\n' || v_post_alter_resolver_def;
  end if;

  raise exception E'VERIFICATION REPORT for 202609020001_add_trainer_grade_assignments_source.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
