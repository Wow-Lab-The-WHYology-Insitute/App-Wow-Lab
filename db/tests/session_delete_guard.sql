-- db/tests/session_delete_guard.sql
-- WOW LAB OS: DELETE on public.sessions (OPEN_ITEMS item 209, the sessions
-- family with items 166 and 199). Deleting a confirmed session does not MOVE
-- its pay, it ELIMINATES it, and service_role holds DELETE. Mihai's form
-- (2026-11-26): REFUSED, no sanctioned path -- a session that should not be
-- paid is CANCELLED; the status is the expression, deletion expresses
-- nothing legitimate.
--
-- Direct refusal, not item 208's capture: measured 2026-11-26, deleting all
-- 176 unconfirmed sessions of 226 left every organization's confirmed pay
-- identical (46 + 6 slots, 0 moved). A session's pay depends on no other
-- session row, so the deleted row alone says whether it carried confirmed
-- pay.
--
-- Written BEFORE the migration and run against the live schema first,
-- failing. §27: every refusal has a control that must pass, every control
-- asserts it was not empty. Every block is BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- CONTROL: deleting a future wow-lab session with no confirmation
-- and no approval is ACCEPTED. Non-empty: one row deleted, and the
-- precondition (no confirmation on it) is printed.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  select set_config('test.session', (select id::text from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is null and trainer_secundar_confirmed_at is null
      and trainer_principal_approved_at is null and trainer_secundar_approved_at is null
      and session_date > current_date
    order by session_date desc limit 1), true);
  do $$
  declare n int;
  begin
    delete from public.sessions where id = current_setting('test.session')::uuid;
    get diagnostics n = row_count;
    insert into r values ('deleted', n::text), ('result', 'accepted');
  exception when others then
    insert into r values ('result', 'refused ' || sqlstate);
  end $$;
  select 'CONTROL precondition: an unconfirmed, unapproved future session exists' as check_name,
    current_setting('test.session') as actual, 'a session id' as expected, current_setting('test.session') <> '' as pass
  union all
  select 'CONTROL: it was really deleted', (select v from r where k = 'deleted'), '1', (select v from r where k = 'deleted') = '1'
  union all
  select 'CONTROL: deleting a session with no confirmation is accepted',
    (select v from r where k = 'result'), 'accepted', (select v from r where k = 'result') = 'accepted';
rollback;

-- ============================================================================
-- Point 2 -- PROBE: deleting a confirmed, unapproved wow-lab session is
-- refused (P0W04).
-- §27 control: point 1.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  select set_config('test.session', (select id::text from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is not null and trainer_principal_approved_at is null
    order by session_date limit 1), true);
  do $$
  declare d text;
  begin
    delete from public.sessions where id = current_setting('test.session')::uuid;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W04' then
      get stacked diagnostics d = pg_exception_detail;
      insert into r values ('result', 'refused P0W04'), ('detail', d);
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'deleting a confirmed session is refused (P0W04)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W04' as expected,
    (select v from r where k = 'result') = 'refused P0W04' as pass
  union all
  select 'the refusal names the session and its confirmed principal slot',
    (select v from r where k = 'detail'), 'session_id, principal confirmed',
    coalesce((select v::jsonb->>'session_id' = current_setting('test.session') and (v::jsonb->>'principal_confirmed')::boolean
              from r where k = 'detail'), false);
rollback;

-- ============================================================================
-- Point 3 -- PROBE: deleting an APPROVED session is refused. No approval
-- exists in any organization today (measured 2026-11-26), so one is written
-- inside this rolled-back transaction, on a confirmed slot, as approval does.
-- §27 control: point 1.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  select set_config('test.session', (select id::text from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is not null and trainer_principal_approved_at is null
    order by session_date limit 1), true);
  update public.sessions set trainer_principal_approved_at = now(), trainer_principal_approved_amount_bani = 12700
  where id = current_setting('test.session')::uuid;
  do $$
  begin
    delete from public.sessions where id = current_setting('test.session')::uuid;
    insert into r values ('result', 'accepted');
  exception
    when sqlstate 'P0W04' then insert into r values ('result', 'refused P0W04');
    when others then insert into r values ('result', 'other ' || sqlstate);
  end $$;
  select 'deleting an approved session is refused (P0W04)' as check_name,
    (select v from r where k = 'result') as actual, 'refused P0W04' as expected,
    (select v from r where k = 'result') = 'refused P0W04' as pass;
rollback;

-- ============================================================================
-- Point 4 -- PROBE: the confirmation cleared by UPDATE and the session deleted
-- in the SAME transaction is refused: the guard reads what the transaction's
-- own history says the row was, not only what it is now.
-- CONTROL: the same two steps on an unconfirmed session (an unrelated column
-- updated, then deleted) are accepted -- the history check refuses a row
-- that WAS confirmed, not any row updated before its delete.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  select set_config('test.session', (select id::text from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is not null and trainer_principal_approved_at is null
    order by session_date limit 1), true);
  select set_config('test.control', (select id::text from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is null and trainer_secundar_confirmed_at is null
      and trainer_principal_approved_at is null and trainer_secundar_approved_at is null
      and session_date > current_date
    order by session_date desc limit 1), true);
  do $$
  declare n int;
  begin
    update public.sessions set notes = coalesce(notes, '') || ' ' where id = current_setting('test.control')::uuid;
    delete from public.sessions where id = current_setting('test.control')::uuid;
    get diagnostics n = row_count;
    insert into r values ('control_deleted', n::text), ('control', 'accepted');
  exception when others then insert into r values ('control', 'refused ' || sqlstate);
  end $$;
  do $$
  begin
    update public.sessions set trainer_principal_confirmed_at = null where id = current_setting('test.session')::uuid;
    delete from public.sessions where id = current_setting('test.session')::uuid;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W04' then insert into r values ('probe', 'refused P0W04');
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  select 'CONTROL: an unconfirmed session updated then deleted in one transaction was really deleted' as check_name,
    (select v from r where k = 'control_deleted') as actual, '1' as expected, (select v from r where k = 'control_deleted') = '1' as pass
  union all
  select 'CONTROL: updating then deleting an unconfirmed session is accepted',
    (select v from r where k = 'control'), 'accepted', (select v from r where k = 'control') = 'accepted'
  union all
  select 'clearing the confirmation and deleting in the same transaction is refused (P0W04)',
    (select v from r where k = 'probe'), 'refused P0W04', (select v from r where k = 'probe') = 'refused P0W04';
rollback;

-- ============================================================================
-- Point 5 -- TRUNCATE public.sessions (CASCADE, it has a child) is refused
-- unconditionally (P0W03), and the refusal is the sessions trigger's own.
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
  declare m text;
  begin
    truncate public.sessions cascade;
    insert into r values ('probe', 'accepted');
  exception
    when sqlstate 'P0W03' then
      get stacked diagnostics m = message_text;
      insert into r values ('probe', 'refused P0W03'), ('message', m);
    when others then insert into r values ('probe', 'other ' || sqlstate);
  end $$;
  select 'CONTROL: TRUNCATE of an unguarded pay table is accepted' as check_name,
    (select v from r where k = 'control') as actual, 'accepted' as expected, (select v from r where k = 'control') = 'accepted' as pass
  union all
  select 'TRUNCATE of sessions is refused (P0W03)',
    (select v from r where k = 'probe'), 'refused P0W03', (select v from r where k = 'probe') = 'refused P0W03'
  union all
  select 'the refusal names sessions', (select v from r where k = 'message'), 'TRUNCATE of sessions ...',
    coalesce((select v like 'TRUNCATE of sessions %' from r where k = 'message'), false);
rollback;

-- ============================================================================
-- Point 6 -- SABOTAGE for point 2: the DELETE trigger removed. The confirmed
-- session goes silently; pass MUST be false.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger sessions_guard_delete_confirmed on public.sessions;
  do $$
  begin
    delete from public.sessions where id = (select id from public.sessions
      where organization_id = (select id from public.organizations where slug = 'wow-lab')
        and trainer_principal_confirmed_at is not null and trainer_principal_approved_at is null
      order by session_date limit 1);
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W04' then insert into r values ('result', 'refused P0W04');
  end $$;
  select 'SABOTAGE: deleting a confirmed session is refused, same assertion as point 2, trigger removed' as check_name,
    (select v from r) as actual, 'refused P0W04' as expected, (select v from r) = 'refused P0W04' as pass;
rollback;

-- ============================================================================
-- Point 7 -- SABOTAGE for point 4: the transaction-history check removed (the
-- guard reads only the row as it is now). Clear-then-delete gets through.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  create or replace function app.session_confirmed_earlier_in_transaction(p_session_id uuid)
  returns boolean language sql stable set search_path = '' as $f$ select false $f$;
  do $$
  declare v uuid;
  begin
    select id into v from public.sessions
    where organization_id = (select id from public.organizations where slug = 'wow-lab')
      and trainer_principal_confirmed_at is not null and trainer_principal_approved_at is null
    order by session_date limit 1;
    update public.sessions set trainer_principal_confirmed_at = null where id = v;
    delete from public.sessions where id = v;
    insert into r values ('result', 'accepted');
  exception when sqlstate 'P0W04' then insert into r values ('result', 'refused P0W04');
  end $$;
  select 'SABOTAGE: clear-then-delete in one transaction is refused, same assertion as point 4, history check removed' as check_name,
    (select v from r) as actual, 'refused P0W04' as expected, (select v from r) = 'refused P0W04' as pass;
rollback;

-- ============================================================================
-- Point 8 -- SABOTAGE for point 5: the TRUNCATE trigger removed.
-- ============================================================================
begin;
  create temp table r (k text, v text) on commit drop;
  drop trigger sessions_guard_truncate on public.sessions;
  do $$
  begin
    truncate public.sessions cascade;
    insert into r values ('probe', 'accepted');
  exception when sqlstate 'P0W03' then insert into r values ('probe', 'refused P0W03');
  end $$;
  select 'SABOTAGE: TRUNCATE of sessions is refused, same assertion as point 5, trigger removed' as check_name,
    (select v from r) as actual, 'refused P0W03' as expected, (select v from r) = 'refused P0W03' as pass;
rollback;
