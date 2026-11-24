-- db/tests/pay_input_delete_guard.sql
-- WOW LAB OS: the missing verbs on the ten pay-input tables (OPEN_ITEMS item
-- 208): DELETE and TRUNCATE. Items 194/196 guard INSERT and UPDATE; a
-- migration or service_role DELETE made 762,00 / 8.588,00 lei of confirmed pay
-- unpriceable with every guard silent (item 208's measured table).
--
-- The form Mihai confirmed 2026-11-17: the "before" of a DELETE is CAPTURED at
-- the transaction's first delete in an organization and compared at commit --
-- never simulated by undo, because a cascade-shaped delete cannot be undone
-- (re-inserting a rate whose version is gone: 23503, measured). TRUNCATE is
-- refused unconditionally, by a statement-level BEFORE TRUNCATE.
--
-- Written BEFORE the migration and run against the live schema first,
-- failing. §27 throughout: every refusal has a control that must PASS, and
-- every control asserts it was not empty (a row was really deleted, and the
-- precondition that makes it a control was measured, not assumed).
-- Every block is BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- CONTROL: deleting a grade rate no confirmed slot resolves to is
-- ACCEPTED (grade 5 of wow-lab's version in force: no trainer holds grade 5).
-- Non-empty: exactly one row deleted, and 0 confirmed unapproved slots on it.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  insert into r select 'slots_on_grade_5', count(*)::text
  from public.sessions s
  cross join lateral (values (s.trainer_principal_id, s.trainer_principal_confirmed_at, s.trainer_principal_approved_at),
                             (s.trainer_secundar_id, s.trainer_secundar_confirmed_at, s.trainer_secundar_approved_at)) x(tid, c, a)
  where s.organization_id = (select id from public.organizations where slug = 'wow-lab')
    and x.tid is not null and x.c is not null and x.a is null
    and app.resolve_trainer_grade(s.organization_id, x.tid, s.session_date) = 5;
  do $$
  declare n int;
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 5;
    get diagnostics n = row_count;
    insert into r values ('deleted', n::text);
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL precondition: no confirmed, unapproved slot resolves to grade 5' as check_name,
    (select v from r where k = 'slots_on_grade_5') as actual, '0' as expected, (select v from r where k = 'slots_on_grade_5') = '0' as pass
  union all
  select 'CONTROL: deleting the grade-5 rate deletes exactly one row',
    (select v from r where k = 'deleted'), '1', (select v from r where k = 'deleted') = '1'
  union all
  select 'CONTROL: deleting a rate no confirmed slot resolves to is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 2 -- PROBE: deleting the grade-3 rate (Teodora's 6 confirmed slots)
-- is refused (P0W01), and the refusal says the slots became unpriceable.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare d text;
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 3;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'deleting a grade rate confirmed pay resolves to is refused (P0W01)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass
  union all
  select 'the refusal names DELETE and the table, and every moved slot became unpriceable',
    (select v from r where k = 'detail'), 'verb=DELETE, table=trainer_grade_rates, slots>0, unpriceable=slots',
    coalesce((select v::jsonb->>'verb' = 'DELETE' and v::jsonb->>'table' = 'trainer_grade_rates'
                     and (v::jsonb->>'slots')::int > 0 and (v::jsonb->>'unpriceable_slots')::int = (v::jsonb->>'slots')::int
              from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 3 -- CONTROL: deleting the grade assignment of a trainer with no
-- confirmed, unapproved slot is ACCEPTED (Elena Bacalum). Non-empty: one row.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  insert into r select 'slots', count(*)::text
  from public.sessions s
  where s.organization_id = (select id from public.organizations where slug = 'wow-lab')
    and ((s.trainer_principal_id = (select id from public.users where email = 'elena.bacalum@gmail.com')
          and s.trainer_principal_confirmed_at is not null and s.trainer_principal_approved_at is null)
      or (s.trainer_secundar_id = (select id from public.users where email = 'elena.bacalum@gmail.com')
          and s.trainer_secundar_confirmed_at is not null and s.trainer_secundar_approved_at is null));
  do $$
  declare n int;
  begin
    delete from public.trainer_grade_assignments
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_id = (select id from public.users where email = 'elena.bacalum@gmail.com');
    get diagnostics n = row_count;
    insert into r values ('deleted', n::text);
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL precondition: Elena Bacalum has no confirmed, unapproved slot' as check_name,
    (select v from r where k = 'slots') as actual, '0' as expected, (select v from r where k = 'slots') = '0' as pass
  union all
  select 'CONTROL: deleting her assignment deletes at least one row',
    (select v from r where k = 'deleted'), '>= 1', (select v from r where k = 'deleted')::int >= 1
  union all
  select 'CONTROL: deleting an assignment no confirmed slot rests on is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 4 -- PROBE: deleting Teodora's grade assignment is refused (P0W01).
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare d text;
  begin
    delete from public.trainer_grade_assignments
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_id = (select id from public.users where email = 'merisanteodora@gmail.com');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'deleting a grade assignment confirmed pay rests on is refused (P0W01)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass
  union all
  select 'the refusal names the assignments table and at least one slot',
    (select v from r where k = 'detail'), 'table=trainer_grade_assignments, slots>0',
    coalesce((select v::jsonb->>'table' = 'trainer_grade_assignments' and (v::jsonb->>'slots')::int > 0 from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 5 -- CONTROL, and the moment of capture (Mihai, 2026-11-17): a
-- version INSERTED earlier in the same transaction, dated 2099, then deleted
-- with its rate, is ACCEPTED. The capture happens at the first DELETE, so it
-- sees the state AFTER the insert; the insert is judged by its own guard.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare n int;
  begin
    insert into public.trainer_grade_versions (id, organization_id, effective_date, created_by, note)
    values ('77777777-0000-0000-0000-000000000208', (select id from public.organizations where slug = 'wow-lab'), '2099-01-01',
            (select id from public.users where email = 'maxdigitalro@gmail.com'), 'item 208 test');
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
    values ((select id from public.organizations where slug = 'wow-lab'), '77777777-0000-0000-0000-000000000208', 3, 999);
    delete from public.trainer_grade_rates where version_id = '77777777-0000-0000-0000-000000000208';
    get diagnostics n = row_count;
    delete from public.trainer_grade_versions where id = '77777777-0000-0000-0000-000000000208';
    insert into r values ('deleted', n::text);
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL: the inserted rate was really deleted' as check_name,
    (select v from r where k = 'deleted') as actual, '1' as expected, (select v from r where k = 'deleted') = '1' as pass
  union all
  select 'CONTROL: inserting then deleting a future version in one transaction is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 6 -- PROBE: the version in force deleted together with its rates
-- (rates first: the order the foreign key does NOT stop) is refused, and the
-- refusal covers every confirmed, unapproved wow-lab slot.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  insert into r select 'confirmed_slots', count(*)::text
  from public.sessions s
  cross join lateral (values (s.trainer_principal_id, s.trainer_principal_confirmed_at, s.trainer_principal_approved_at),
                             (s.trainer_secundar_id, s.trainer_secundar_confirmed_at, s.trainer_secundar_approved_at)) x(tid, c, a)
  where s.organization_id = (select id from public.organizations where slug = 'wow-lab')
    and x.tid is not null and x.c is not null and x.a is null;
  do $$
  declare d text; v_version uuid;
  begin
    select id into v_version from public.trainer_grade_versions
    where organization_id = (select id from public.organizations where slug = 'wow-lab') and effective_date <= current_date
    order by effective_date desc limit 1;
    delete from public.trainer_grade_rates where version_id = v_version;
    delete from public.trainer_grade_versions where id = v_version;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W01'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'deleting the version in force with its rates is refused (P0W01)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass
  union all
  select 'the refusal covers every confirmed, unapproved wow-lab slot',
    (select (v::jsonb->>'slots') from r where k = 'detail'), (select v from r where k = 'confirmed_slots'),
    coalesce((select (v::jsonb->>'slots') = (select v from r where k = 'confirmed_slots') and (v::jsonb->>'slots')::int > 0 from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 7 -- PROBE: a harmful DELETE after an earlier check in the same
-- transaction is still judged. A harmless delete, constraints forced
-- immediate (the check runs and passes), then the grade-3 rate deleted and
-- forced again: refused. A check that ran once must not excuse what follows.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 5;
    set constraints all immediate;
    insert into r values ('first', 'accepted');
    set constraints all deferred;
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 3;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'a harmful delete after an earlier passed check in the same transaction is refused' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W01' as expected,
    (select v from r where k = 'result') = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 8 -- CONTROL: a confirmation made AFTER a delete in the same
-- transaction is not the delete's effect. Harmless delete (grade 5), then one
-- of Lorina's unconfirmed 28 October sessions confirmed: ACCEPTED. Non-empty:
-- the session really became a confirmed, priced slot.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 5;
    update public.sessions set trainer_principal_confirmed_at = now()
    where id = 'a06dab18-e487-4e02-a76c-86e6c1ebb2f0' and trainer_principal_confirmed_at is null;
    insert into r select 'new_slot',
      coalesce((app.grid_confirmed_pay_snapshot(organization_id, session_date) ? 'a06dab18-e487-4e02-a76c-86e6c1ebb2f0:principal')::text, 'false')
      from public.sessions where id = 'a06dab18-e487-4e02-a76c-86e6c1ebb2f0';
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL precondition: the session became a confirmed slot inside the transaction' as check_name,
    (select v from r where k = 'new_slot') as actual, 'true' as expected, (select v from r where k = 'new_slot') = 'true' as pass
  union all
  select 'CONTROL: a confirmation after a harmless delete in the same transaction is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 9 -- CONTROL: deleting a fresh group with no session is ACCEPTED.
-- (A group WITH sessions cannot be deleted at all: sessions_group_id_org_fkey,
-- no action. That is the key's protection, not this guard's, and is not
-- counted as coverage -- §27.)
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('77777777-0000-0000-0000-0000000002a8', (select id from public.organizations where slug = 'wow-lab'),
          (select client_id from public.groups where id = 'c1000000-0000-0000-0000-0000000000b2'), 'gaga', 'scoli_private_recurente', 'ro_en');
  do $$
  declare n int;
  begin
    delete from public.groups where id = '77777777-0000-0000-0000-0000000002a8';
    get diagnostics n = row_count;
    insert into r values ('deleted', n::text);
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL: the fresh group was really deleted' as check_name,
    (select v from r where k = 'deleted') as actual, '1' as expected, (select v from r where k = 'deleted') = '1' as pass
  union all
  select 'CONTROL: deleting a group with no session is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 10 -- PROBE: TRUNCATE of a guarded table is refused (P0W03).
-- CONTROL: TRUNCATE of an unguarded pay table (contract_type_uplift_rates,
-- zero rows by design, item 188) is accepted in the same transaction shape,
-- so the refusal cannot be a grant or a lock.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  begin
    truncate public.contract_type_uplift_rates;
    insert into r values ('control', 'accepted');
  exception when others then insert into r values ('control', 'refused ' || sqlstate);
  end $$;
  do $$
  begin
    truncate public.trainer_grade_rates;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W03' then insert into r values ('probe', 'refused P0W03');
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  select 'CONTROL: TRUNCATE of an unguarded pay table is accepted' as check_name,
    (select v from r where k = 'control') as actual, 'accepted' as expected, (select v from r where k = 'control') = 'accepted' as pass
  union all
  select 'TRUNCATE of a guarded pay table is refused (P0W03)',
    (select v from r where k = 'probe'), 'refused P0W03', (select v from r where k = 'probe') = 'refused P0W03';
rollback;

-- ============================================================================
-- Point 11 -- TRUNCATE is refused UNCONDITIONALLY (Mihai, 2026-11-17: a
-- TRUNCATE of a grid with no confirmed session is just as catastrophic).
-- Every confirmation in every organization cleared first, inside this
-- rolled-back transaction, so no confirmed slot exists anywhere -- measured,
-- not assumed -- and TRUNCATE is still refused.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  update public.sessions set trainer_principal_confirmed_at = null where trainer_principal_confirmed_at is not null;
  update public.sessions set trainer_secundar_confirmed_at = null where trainer_secundar_confirmed_at is not null;
  insert into r select 'confirmed_anywhere', count(*)::text from public.sessions
  where trainer_principal_confirmed_at is not null or trainer_secundar_confirmed_at is not null;
  do $$
  begin
    truncate public.location_bonus_rates;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W03' then insert into r values ('probe', 'refused P0W03');
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  select 'precondition: no confirmed slot exists in any organization' as check_name,
    (select v from r where k = 'confirmed_anywhere') as actual, '0' as expected, (select v from r where k = 'confirmed_anywhere') = '0' as pass
  union all
  select 'TRUNCATE is refused even where no confirmed pay depends on it (P0W03)',
    (select v from r where k = 'probe'), 'refused P0W03', (select v from r where k = 'probe') = 'refused P0W03';
rollback;

-- ============================================================================
-- Point 12 -- TRUNCATE ... CASCADE from an UNGUARDED parent is refused when
-- it reaches a guarded table: TRUNCATE clients CASCADE reaches groups.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  declare m text;
  begin
    truncate public.clients cascade;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W03' then
      get stacked diagnostics m = message_text;
      insert into r values ('probe', 'refused P0W03'), ('message', m);
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  select 'TRUNCATE CASCADE from an unguarded parent is refused where it reaches a guarded table (P0W03)' as check_name,
    (select v from r where k = 'probe') as actual, 'refused P0W03' as expected, (select v from r where k = 'probe') = 'refused P0W03' as pass
  union all
  select 'the refusal is the guarded table''s own: it names groups, which clients cannot carry a trigger for',
    (select v from r where k = 'message'), 'TRUNCATE of groups ...', coalesce((select v like 'TRUNCATE of groups %' from r where k = 'message'), false);
rollback;

-- ============================================================================
-- Point 13 -- SABOTAGE for point 2: the rates' DELETE check removed. The
-- grade-3 rate goes silently; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger trainer_grade_rates_guard_confirmed_pay_delete on public.trainer_grade_rates;
  do $$
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 3;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
  end $$;
  select 'SABOTAGE: deleting a grade rate confirmed pay resolves to is refused, same assertion as point 2, check removed' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 14 -- SABOTAGE for point 4: the assignments' DELETE check removed.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger trainer_grade_assignments_guard_confirmed_pay_delete on public.trainer_grade_assignments;
  do $$
  begin
    delete from public.trainer_grade_assignments
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_id = (select id from public.users where email = 'merisanteodora@gmail.com');
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
  end $$;
  select 'SABOTAGE: deleting a grade assignment confirmed pay rests on is refused, same assertion as point 4, check removed' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 15 -- SABOTAGE for point 6: the checks on versions AND rates removed.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger trainer_grade_rates_guard_confirmed_pay_delete on public.trainer_grade_rates;
  drop trigger trainer_grade_versions_guard_confirmed_pay_delete on public.trainer_grade_versions;
  do $$
  declare v_version uuid;
  begin
    select id into v_version from public.trainer_grade_versions
    where organization_id = (select id from public.organizations where slug = 'wow-lab') and effective_date <= current_date
    order by effective_date desc limit 1;
    delete from public.trainer_grade_rates where version_id = v_version;
    delete from public.trainer_grade_versions where id = v_version;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
  end $$;
  select 'SABOTAGE: deleting the version in force with its rates is refused, same assertion as point 6, checks removed' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 16 -- SABOTAGE for point 7: the delete counter stops advancing after
-- the first check (the capture trigger dropped between the two deletes), so
-- the check reads "already judged" -- the once-only shape point 7 forbids.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  do $$
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 5;
    set constraints all immediate;
    set constraints all deferred;
    drop trigger trainer_grade_rates_guard_delete_capture on public.trainer_grade_rates;
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 3;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W01' then insert into r values ('result', 'refused P0W01');
  end $$;
  select 'SABOTAGE: a harmful delete after an earlier passed check is refused, same assertion as point 7, counter frozen' as check_name,
    (select v from r) as actual, 'refused P0W01' as expected, (select v from r) = 'refused P0W01' as pass;
rollback;

-- ============================================================================
-- Point 17 -- SABOTAGE for point 8: the "after" no longer restricted to the
-- slots confirmed before the first delete. The new confirmation is then
-- counted as the delete's effect and refused; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  create or replace function app.pay_delete_guard_restrict(p_before jsonb, p_after jsonb)
  returns jsonb language sql immutable set search_path = '' as $f$ select p_after $f$;
  do $$
  begin
    delete from public.trainer_grade_rates r
    using public.trainer_grade_versions v
    where v.id = r.version_id and v.organization_id = (select id from public.organizations where slug = 'wow-lab')
      and v.effective_date <= current_date and r.grade_level = 5;
    update public.sessions set trainer_principal_confirmed_at = now()
    where id = 'a06dab18-e487-4e02-a76c-86e6c1ebb2f0' and trainer_principal_confirmed_at is null;
    set constraints all immediate;
    insert into r values ('result', 'accepted');
  exception when others then insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'SABOTAGE: a confirmation after a harmless delete is accepted, same assertion as point 8, restriction removed' as check_name,
    (select v from r) as actual, 'accepted' as expected, (select v from r) = 'accepted' as pass;
rollback;

-- ============================================================================
-- Point 18 -- SABOTAGE for point 10: the rates' TRUNCATE trigger removed.
-- The grid is emptied; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger trainer_grade_rates_guard_truncate on public.trainer_grade_rates;
  do $$
  begin
    truncate public.trainer_grade_rates;
    insert into r values ('probe', 'accepted');
  exception when sqlstate 'P0W03' then insert into r values ('probe', 'refused P0W03');
  end $$;
  select 'SABOTAGE: TRUNCATE of a guarded pay table is refused, same assertion as point 10, trigger removed' as check_name,
    (select v from r) as actual, 'refused P0W03' as expected, (select v from r) = 'refused P0W03' as pass;
rollback;
