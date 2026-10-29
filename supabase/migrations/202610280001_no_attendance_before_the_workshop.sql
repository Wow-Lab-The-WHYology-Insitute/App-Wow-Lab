-- Found on Mihai's own phone walkthrough, 2026-10-28, the trainer's test
-- account in wow-lab-test-b: the "Record attendance" button rendered on a
-- workshop dated 10 November -- two weeks in the future -- and nothing
-- stopped it from being used. "12 children attended" on a workshop that has
-- not happened is the same false assertion 202610220001 already refused for
-- the confirmation timestamp, written on a different button.
--
-- ===========================================================================
-- THE GUARD IS SYMMETRIC HERE, UNLIKE 202610220001's -- AND THAT IS THE
-- DIFFERENCE, NOT AN INCONSISTENCY.
-- ===========================================================================
-- The confirmation guard refuses SETTING a future confirmation but always
-- allows CLEARING one, because "I did not teach this" is true about
-- tomorrow by default -- clearing never asserts anything false.
--
-- attendance_count/experiment_delivered have no such asymmetry. There is no
-- legitimate reason to WRITE either column -- including writing them back to
-- null -- on a workshop that has not happened: nothing happened yet for
-- there to be a number of children or an experiment to record, or to clear.
-- So this guard refuses the write outright, in either direction, whenever
-- session_date > current_date. A trainer undoing a mis-tap on a future row
-- never had anything real to undo in the first place.
--
-- Same boundary as the confirmation guard: `session_date > current_date`,
-- not `>=` -- a workshop today is recordable today.
--
-- ===========================================================================
-- ONE EXISTING ROW VIOLATES THE RULE, AND IT STAYS (convention §20) --
-- SAME ROW 202610220001 ALREADY NAMED, NOW DOUBLY SO.
-- ===========================================================================
-- `wow-lab-test-b` (is_test = true), the MAX group, 2026-11-08: principal
-- confirmed AND attendance_count = 20 AND experiment_delivered set. The same
-- seed fixture 202610220001 recorded as the one known exception to ITS own
-- guard (db/tests/payroll_org_session_pay.sql's fixture, written by a
-- migration rather than through an RPC) also violates this one. Confirmed
-- live before writing this guard, not assumed.
--
-- It is NOT corrected here, for the identical reason 202610220001 gave: this
-- is an RPC guard, not a CHECK constraint, and a CHECK would turn "the clock
-- moved" into a migration-time constraint violation on a row nobody is
-- touching right now. Checked live: this is the ONLY row anywhere, in either
-- organization, where a future session_date carries attendance_count,
-- experiment_delivered, or either confirmation timestamp -- the real
-- organization is clean.
--
-- ===========================================================================
-- THE SECOND WRITE PATH -- addSession, found while answering "is this the
-- only button", per Mihai's own instruction not to stop at the one button.
-- ===========================================================================
-- app/(app)/groups/actions.ts's addSession creates a new session with a
-- direct `.insert()`, never through an RPC (item 91 only re-routed UPDATE
-- paths; authenticated still holds table-level INSERT on sessions, gated by
-- sessions.create via RLS). Its own form (NewSessionForm) carries real
-- attendance/experiment fields at creation time -- meant for logging a
-- one-off workshop that already happened and was never entered until after
-- the fact -- and nothing stopped the identical false assertion from being
-- made the moment the date picked is in the future instead of the past.
-- Patched at the action, in the same commit, on the same principle; see that
-- file's own comment. NOT routed through a new RPC here -- that would mean
-- revoking authenticated's table-level INSERT on sessions the way item 91
-- revoked its UPDATE grant, which is a larger decision this pass does not
-- make. The TypeScript guard closes the one real path (NewSessionForm); a
-- raw PostgREST POST past it is not closed by this migration and is named
-- here rather than left to be discovered, same as every other known gap in
-- this register.

create or replace function app.rpc_update_session_attendance(
  p_session_id uuid,
  p_attendance_count int,
  p_experiment_delivered text
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_session_date date;
  v_principal uuid;
  v_secundar uuid;
  v_month_closed boolean;
begin
  select organization_id, session_date, trainer_principal_id, trainer_secundar_id
    into v_org, v_session_date, v_principal, v_secundar
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  if v_principal is distinct from app.current_user_id() and v_secundar is distinct from app.current_user_id() then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  -- THE NEW GUARD. Unlike the confirmation guard, symmetric: nothing about
  -- attendance_count/experiment_delivered can be true yet for a workshop
  -- that has not happened, so there is no "clearing is always fine" case to
  -- carve out.
  if v_session_date > current_date then
    return 'future_session';
  end if;

  select exists (
    select 1 from public.payroll_periods pp
    where pp.organization_id = v_org
      and pp.period = date_trunc('month', v_session_date::timestamptz)::date
      and pp.closed_at is not null
  ) into v_month_closed;

  if v_month_closed then
    return 'month_closed';
  end if;

  update public.sessions
    set attendance_count = p_attendance_count,
        experiment_delivered = p_experiment_delivered
    where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_update_session_attendance(uuid, int, text) is 'Item 91, guard added 202610280001. Writes ONLY attendance_count/experiment_delivered. Row match (caller is trainer_principal_id or trainer_secundar_id) + mywork.* + not-in-the-future + month-open. Returns: ok | not_found | not_assigned | future_session | month_closed. `future_session` fires whenever session_date > current_date, for EITHER value including a null -- unlike the confirmation guard (202610220001), there is no asymmetric "clearing is always allowed" case: nothing about attendance can be true, or need clearing, before the workshop happens.';

-- ---------------------------------------------------------------------------
-- Assertions.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_future integer;
  v_test_future integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'attendance-guard: no organization with slug wow-lab'; end if;

  -- The real org has nothing to clean up.
  select count(*) into v_future from public.sessions
  where organization_id = v_org and session_date > current_date
    and (attendance_count is not null or experiment_delivered is not null);
  if v_future <> 0 then
    raise exception 'attendance-guard: % future-dated attendance rows already exist in wow-lab -- clear them before relying on this guard', v_future;
  end if;

  -- And the one known exception, named rather than left to be discovered --
  -- the same fixture 202610220001 already named for the confirmation guard.
  select count(*) into v_test_future from public.sessions s
  join public.organizations o on o.id = s.organization_id
  where o.is_test and s.session_date > current_date
    and (s.attendance_count is not null or s.experiment_delivered is not null);
  if v_test_future <> 1 then
    raise exception 'attendance-guard: expected exactly 1 future-dated attendance row in test organizations (the MAX fixture), found %', v_test_future;
  end if;

  if to_regprocedure('app.rpc_update_session_attendance(uuid, int, text)') is null then
    raise exception 'attendance-guard: function signature changed';
  end if;

  raise notice 'attendance-guard: app.rpc_update_session_attendance refuses future_session for EITHER value, symmetrically. wow-lab has 0 future attendance rows; 1 known test fixture is left as-is.';
end $$;
