-- db/tests/pending/actor_pinned_to_caller.sql
-- PENDING (not run by the suite, which reads only db/tests/*.sql): it FAILS
-- against the live schema today, on purpose, and enters the suite in the
-- same commit as the repair Mihai chooses (OPEN_ITEMS item 210). Delete this
-- header when it moves.
--
-- §19, made executable (Mihai, 2026-11-27): the recorded actor is who did
-- the thing. Measured first, 2026-11-27:
--   * row_history.actor_user_id is automatic: row_history_capture writes
--     app.current_user_id(), which is auth.uid(). No function can forget it;
--     a migration or service_role writes NULL (§23). Point 5 pins that.
--   * The `*_by` columns are where the writer CHOOSES the value. Of the 11
--     an app user can in fact INSERT (column grant, and RLS with an INSERT
--     policy), ONE is pinned to the caller (payroll_periods.closed_by, WITH
--     CHECK closed_by = app.current_user_id()). The other 10 accept any user
--     id through a raw POST. (admin_rate_versions has the grant but no INSERT
--     policy: nobody can insert there, so it is not counted.)
--   * Five functions write a `*_by` column; each takes it from the caller.
--     Point 4 keeps that list closed: a new function writing one fails until
--     it is registered here, with the caller as its source.
-- §27: every probe has its control; every block is BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- the class, INSERT: every `*_by` column an app user can INSERT
-- is pinned to the caller by an INSERT policy's WITH CHECK. FAILS today (10).
-- ============================================================================
begin;
  select 'every *_by column app users can INSERT is pinned to the caller' as check_name,
    coalesce((select string_agg(cp.table_name || '.' || cp.column_name, ', ' order by cp.table_name)
      from information_schema.column_privileges cp
      where cp.table_schema = 'public' and cp.grantee = 'authenticated' and cp.privilege_type = 'INSERT'
        and cp.column_name ~ '_by$'
        -- writable in fact: RLS off, or at least one INSERT policy (admin_rate_versions has the
        -- column grant and RLS with no INSERT policy, so no app user can insert at all)
        and exists (select 1 from pg_catalog.pg_class c where c.oid = format('public.%I', cp.table_name)::regclass
                    and (not c.relrowsecurity or exists (select 1 from pg_catalog.pg_policy p2 where p2.polrelid = c.oid and p2.polcmd in ('a', '*'))))
        and not exists (
          select 1 from pg_catalog.pg_policy p
          where p.polrelid = format('public.%I', cp.table_name)::regclass and p.polcmd in ('a', '*')
            and pg_get_expr(p.polwithcheck, p.polrelid) ~ ('\m' || cp.column_name || '\s*=\s*(app\.current_user_id\(\)|auth\.uid\(\))'))), 'none') as actual,
    'none' as expected,
    not exists (
      select 1 from information_schema.column_privileges cp
      where cp.table_schema = 'public' and cp.grantee = 'authenticated' and cp.privilege_type = 'INSERT'
        and cp.column_name ~ '_by$'
        -- writable in fact: RLS off, or at least one INSERT policy (admin_rate_versions has the
        -- column grant and RLS with no INSERT policy, so no app user can insert at all)
        and exists (select 1 from pg_catalog.pg_class c where c.oid = format('public.%I', cp.table_name)::regclass
                    and (not c.relrowsecurity or exists (select 1 from pg_catalog.pg_policy p2 where p2.polrelid = c.oid and p2.polcmd in ('a', '*'))))
        and not exists (
          select 1 from pg_catalog.pg_policy p
          where p.polrelid = format('public.%I', cp.table_name)::regclass and p.polcmd in ('a', '*')
            and pg_get_expr(p.polwithcheck, p.polrelid) ~ ('\m' || cp.column_name || '\s*=\s*(app\.current_user_id\(\)|auth\.uid\(\))'))) as pass;
rollback;

-- ============================================================================
-- Point 2 -- CONTROL, induced: the one pinned column works. A Finance
-- Operations account inserting a payroll period with closed_by = SOMEONE
-- ELSE is refused (42501); with its own id, accepted. Without this, point
-- 3's refusal (once repaired) could be any other refusal.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  select set_config('test.me', (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  select set_config('test.other', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('test.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('test.me'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (current_setting('test.org')::uuid, '2099-01-01', now(), current_setting('test.other')::uuid);
    insert into r values ('other', 'accepted');
  exception when others then insert into r values ('other', 'refused ' || sqlstate);
  end $$;
  do $$
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (current_setting('test.org')::uuid, '2099-02-01', now(), current_setting('test.me')::uuid);
    insert into r values ('own', 'accepted');
  exception when others then insert into r values ('own', 'refused ' || sqlstate);
  end $$;
  select set_config('role', 'postgres', true);
  select 'CONTROL: a payroll period closed in the caller''s own name is accepted' as check_name,
    (select v from r where k = 'own') as actual, 'accepted' as expected, (select v from r where k = 'own') = 'accepted' as pass
  union all
  select 'a payroll period closed in SOMEONE ELSE''s name is refused (42501)',
    (select v from r where k = 'other'), 'refused 42501', (select v from r where k = 'other') = 'refused 42501';
rollback;

-- ============================================================================
-- Point 3 -- PROBE, induced: the same account inserting a grade version with
-- created_by = SOMEONE ELSE. FAILS today: accepted, and /payroll would show
-- the other person as its author. CONTROL: its own id, accepted. Dated 2099
-- so item 194's guard has nothing to protect.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  select set_config('test.me', (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  select set_config('test.other', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('test.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('test.me'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
    values (current_setting('test.org')::uuid, '2099-01-01', current_setting('test.other')::uuid, 'item 210 probe');
    insert into r values ('other', 'accepted');
  exception when others then insert into r values ('other', 'refused ' || sqlstate);
  end $$;
  do $$
  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
    values (current_setting('test.org')::uuid, '2099-02-01', current_setting('test.me')::uuid, 'item 210 control');
    insert into r values ('own', 'accepted');
  exception when others then insert into r values ('own', 'refused ' || sqlstate);
  end $$;
  select set_config('role', 'postgres', true);
  select 'CONTROL: a grade version created in the caller''s own name is accepted' as check_name,
    (select v from r where k = 'own') as actual, 'accepted' as expected, (select v from r where k = 'own') = 'accepted' as pass
  union all
  select 'a grade version created in SOMEONE ELSE''s name is refused (42501)',
    (select v from r where k = 'other'), 'refused 42501', (select v from r where k = 'other') = 'refused 42501';
rollback;

-- ============================================================================
-- Point 4 -- the class, functions: every function whose body names a `*_by`
-- column is REGISTERED here, and every registered writer takes the value from
-- the caller. A new function naming one fails until it is added, with its
-- source. The registry is the list measured 2026-11-27.
-- ============================================================================
begin;
  create temp table reg (fn text, kind text) on commit drop;
  insert into reg values
    ('app.grade_assignment_write', 'writer'), ('app.grid_correction_write', 'writer'),
    ('app.rpc_create_grid_version', 'writer'), ('app.rpc_cancel_session', 'writer'),
    ('app.rpc_decide_session_lesson_plan', 'writer'),
    ('public.handle_deleted_auth_user', 'nulls the column when the account it names is deleted'),
    ('app.correction_statement_author', 'reads only');
  create temp table fns on commit drop as
  select n.nspname || '.' || p.proname fn, p.prosrc src
  from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('app', 'public') and p.prokind = 'f'
    and p.prosrc ~ '\m(created_by|uploaded_by|closed_by|decided_by|cancelled_by|set_by|assigned_by)\M';
  select 'every function naming a *_by column is registered' as check_name,
    coalesce((select string_agg(fn, ', ') from fns where fn not in (select fn from reg)), 'none') as actual,
    'none' as expected, not exists (select 1 from fns where fn not in (select fn from reg)) as pass
  union all
  select 'every registered writer takes the actor from the caller (app.current_user_id() or auth.uid())',
    coalesce((select string_agg(f.fn, ', ') from fns f join reg using (fn) where reg.kind = 'writer'
              and f.src !~ '(app\.current_user_id\(\)|auth\.uid\(\))'), 'none'),
    'none',
    not exists (select 1 from fns f join reg using (fn) where reg.kind = 'writer' and f.src !~ '(app\.current_user_id\(\)|auth\.uid\(\))');
rollback;

-- ============================================================================
-- Point 5 -- row_history's actor is the caller, structurally:
-- row_history_capture writes app.current_user_id(), which returns auth.uid().
-- ============================================================================
begin;
  select 'row_history_capture records app.current_user_id(), and that is auth.uid()' as check_name,
    (pg_get_functiondef('public.row_history_capture'::regproc) ~ 'app\.current_user_id\(\)')::text
      || ' / ' || (pg_get_functiondef('app.current_user_id'::regproc) ~ 'auth\.uid\(\)')::text as actual,
    'true / true' as expected,
    pg_get_functiondef('public.row_history_capture'::regproc) ~ 'app\.current_user_id\(\)'
      and pg_get_functiondef('app.current_user_id'::regproc) ~ 'auth\.uid\(\)' as pass;
rollback;

-- ============================================================================
-- Point 6 -- SABOTAGE for point 2: the closed_by pin removed from the policy.
-- A period closed in someone else's name gets in; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  grant all on r to authenticated;
  do $$
  declare v_name text; v_check text;
  begin
    select polname, pg_get_expr(polwithcheck, polrelid) into v_name, v_check
    from pg_catalog.pg_policy where polrelid = 'public.payroll_periods'::regclass and polcmd = 'a';
    execute format('alter policy %I on public.payroll_periods with check (%s)', v_name,
                   regexp_replace(v_check, '\s*AND\s*\(closed_by = app\.current_user_id\(\)\)', ''));
  end $$;
  select set_config('test.me', (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  select set_config('test.other', (select id::text from public.users where email = 'maxdigitalro@gmail.com'), true);
  select set_config('test.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('test.me'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (current_setting('test.org')::uuid, '2099-01-01', now(), current_setting('test.other')::uuid);
    insert into r values ('other', 'accepted');
  exception when others then insert into r values ('other', 'refused ' || sqlstate);
  end $$;
  select set_config('role', 'postgres', true);
  select 'SABOTAGE: a payroll period closed in someone else''s name is refused, same assertion as point 2, pin removed' as check_name,
    (select v from r) as actual, 'refused 42501' as expected, (select v from r) = 'refused 42501' as pass;
rollback;

-- ============================================================================
-- Point 7 -- SABOTAGE for point 4: a new function that writes created_by from
-- a PARAMETER. It is not registered, so the class check must fail.
-- ============================================================================
begin;
  create function app.sabotage_write_as(p_actor uuid) returns void language sql set search_path = '' as $f$
    update public.trainer_grade_versions set note = note where created_by = p_actor $f$;
  select 'SABOTAGE: every function naming a *_by column is registered, same assertion as point 4, unregistered writer added' as check_name,
    coalesce((select string_agg(n.nspname || '.' || p.proname, ', ')
      from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname in ('app', 'public') and p.prokind = 'f'
        and p.prosrc ~ '\m(created_by|uploaded_by|closed_by|decided_by|cancelled_by|set_by|assigned_by)\M'
        and n.nspname || '.' || p.proname not in ('app.grade_assignment_write', 'app.grid_correction_write',
          'app.rpc_create_grid_version', 'app.rpc_cancel_session', 'app.rpc_decide_session_lesson_plan',
          'public.handle_deleted_auth_user', 'app.correction_statement_author')), 'none') as actual,
    'none' as expected,
    not exists (select 1
      from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname in ('app', 'public') and p.prokind = 'f'
        and p.prosrc ~ '\m(created_by|uploaded_by|closed_by|decided_by|cancelled_by|set_by|assigned_by)\M'
        and n.nspname || '.' || p.proname not in ('app.grade_assignment_write', 'app.grid_correction_write',
          'app.rpc_create_grid_version', 'app.rpc_cancel_session', 'app.rpc_decide_session_lesson_plan',
          'public.handle_deleted_auth_user', 'app.correction_statement_author')) as pass;
rollback;
