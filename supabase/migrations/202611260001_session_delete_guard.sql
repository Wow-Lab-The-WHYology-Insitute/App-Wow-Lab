-- 202611260001_session_delete_guard.sql
--
-- DELETE and TRUNCATE on public.sessions (OPEN_ITEMS item 209; the sessions
-- family with items 166 and 199). Item 208 named it: deleting a confirmed
-- session does not MOVE its pay, it ELIMINATES it, and service_role holds
-- DELETE on sessions. App users do not: their table-level grant on sessions
-- is SELECT only (measured 2026-11-17, item 208), and no DELETE grant exists.
--
-- THE FORM (Mihai, 2026-11-26): REFUSED, with no sanctioned path. A session
-- that should not be paid is CANCELLED -- the status is the correct
-- expression, the same way a correction is a new version (§26). Deletion
-- expresses nothing legitimate.
--
-- WHY A DIRECT REFUSAL, NOT ITEM 208'S CAPTURE -- measured, not assumed.
-- Capture is needed when a delete changes pay held by OTHER rows (a rate
-- prices every session that resolves to it). Induced 2026-11-26: all 176
-- unconfirmed sessions of 226, every organization, deleted in one rolled-back
-- transaction -- every organization's confirmed pay identical before and
-- after (wow-lab 46 slots, Test Org B 6, 0 moved). A session's pay depends on
-- no other session row, so the deleted row alone says whether it carried
-- confirmed pay. §24's counter-reciprocal: this holds for TODAY's pay rules.
-- A future rule that reads across sessions (a monthly volume tier, a
-- per-day cap) makes it stale -- re-measure before adding one.
--
-- WHAT IS REFUSED (P0W04): deleting a session with any slot confirmed or
-- approved, AND a session whose confirmation or approval was cleared by an
-- UPDATE earlier in the same transaction (clear-then-delete). The second is
-- read from row_history, which captures every UPDATE of sessions with its old
-- values at changed_at = now(), i.e. this transaction's own timestamp.
--
-- WHAT IS NOT: clearing a confirmation in one transaction and deleting in a
-- later one. The clearing itself is the unguarded write -- sessions' own pay
-- columns, item 199 -- and is named there, not hidden here.
--
-- HISTORY, measured before building (report, not repair): 104 sessions were
-- ever deleted, all with a NULL actor. 41 carried a confirmation, 1 an
-- approval -- all 41 in Test Org B, each confirmed seconds or minutes before
-- its delete (verification runs cleaned up by hand; none of the 4 repository
-- scripts that delete sessions commits). In wow-lab: 9 deletes, none
-- confirmed. After this migration such a cleanup is refused: a verification
-- run cancels its session or rolls back.
--
-- Test: db/tests/session_delete_guard.sql, written first, run failing.

-- 1. Was this session confirmed or approved earlier in THIS transaction?
create or replace function app.session_confirmed_earlier_in_transaction(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.row_history h
    where h.table_name = 'sessions'
      and h.row_id = p_session_id
      and h.changed_at = now()
      and (h.old_values->>'trainer_principal_confirmed_at' is not null
        or h.old_values->>'trainer_secundar_confirmed_at' is not null
        or h.old_values->>'trainer_principal_approved_at' is not null
        or h.old_values->>'trainer_secundar_approved_at' is not null)
  );
$$;

-- 2. The refusal, BEFORE each deleted row (immediate: there is nothing to
--    wait for, the row itself is the evidence).
create or replace function app.session_delete_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.trainer_principal_confirmed_at is not null or old.trainer_secundar_confirmed_at is not null
     or old.trainer_principal_approved_at is not null or old.trainer_secundar_approved_at is not null
     or app.session_confirmed_earlier_in_transaction(old.id) then
    raise exception using
      errcode = 'P0W04',
      message = format(
        'Session %s (%s) carries a trainer''s confirmation or an approval and cannot be deleted: deleting it would eliminate its pay. A session that should not be paid is cancelled -- its status says so -- never deleted. (202611260001, OPEN_ITEMS item 209)',
        old.id, old.session_date),
      detail = jsonb_build_object(
        'verb', 'DELETE', 'table', 'sessions', 'session_id', old.id, 'session_date', old.session_date,
        'principal_confirmed', old.trainer_principal_confirmed_at is not null,
        'secundar_confirmed', old.trainer_secundar_confirmed_at is not null,
        'approved', old.trainer_principal_approved_at is not null or old.trainer_secundar_approved_at is not null,
        'cleared_earlier_in_transaction', old.trainer_principal_confirmed_at is null and old.trainer_secundar_confirmed_at is null
          and old.trainer_principal_approved_at is null and old.trainer_secundar_approved_at is null)::text;
  end if;
  return old;
end;
$$;

-- The name sorts before sessions_row_history, so a refused delete leaves no
-- history row behind (BEFORE triggers fire in name order).
create trigger sessions_guard_delete_confirmed
  before delete on public.sessions
  for each row execute function app.session_delete_guard();

-- 3. TRUNCATE: unconditional, item 208's function and reasoning.
create trigger sessions_guard_truncate
  before truncate on public.sessions
  for each statement execute function app.pay_truncate_guard();

revoke all on function app.session_delete_guard() from public;
revoke all on function app.session_confirmed_earlier_in_transaction(uuid) from public;

-- 4. Self-test: both triggers, of the right kind.
do $$
begin
  if (select count(*) from pg_catalog.pg_trigger
      where tgrelid = 'public.sessions'::regclass and not tgisinternal
        and ((tgname = 'sessions_guard_delete_confirmed' and tgtype & 11 = 11)
          or (tgname = 'sessions_guard_truncate' and tgtype & 34 = 34 and tgtype & 1 = 0))) <> 2 then
    raise exception 'self-test: the two sessions guard triggers are not both in place';
  end if;
end $$;
