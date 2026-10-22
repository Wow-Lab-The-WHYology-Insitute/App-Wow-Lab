-- A confirmation cannot be set on a workshop that has not happened yet --
-- on EITHER path, the trainer's and Operations'.
--
-- ===========================================================================
-- THE RULE WAS ALREADY WRITTEN DOWN. IT JUST WASN'T ENFORCED ANYWHERE.
-- ===========================================================================
-- 202610200004, two days ago, refused to mark six inserted workshops as
-- confirmed, and said why in its own header:
--
--   "Marking them confirmed would assert a future delivery, which is exactly
--    what was refused when backdating a confirmation was refused: a
--    confirmation is a person's assertion that they taught a class, and
--    nobody can make it in advance."
--
-- That is a correctness rule about what the column MEANS. It was honoured by
-- a migration choosing not to write a value, and by nothing else. Both RPCs
-- would let anyone do exactly what that paragraph refuses, with one tap.
--
-- Yesterday that was unreachable in practice -- the furthest row was seven
-- days out. 202610200009 generated 172 workshops to 30 June 2027, the group
-- screen sorts session_date DESC, so a trainer's page now OPENS on June 2027.
-- The same guard, the same direction, and until now it existed only in our
-- heads and in a comment.
--
-- ===========================================================================
-- THE GUARD IS ASYMMETRIC, AND THAT IS THE WHOLE DESIGN
-- ===========================================================================
--   SETTING a confirmation (true)  on a future date -> REFUSED
--   CLEARING a confirmation (false) on a future date -> ALWAYS ALLOWED
--
-- Three reasons, and the third is the one that would have been missed:
--
--   1. The asymmetry is in the fact itself. "I taught this" cannot be true
--      about tomorrow. "I did not teach this" is true about tomorrow by
--      default, so clearing one never asserts anything false.
--   2. It is what makes un-confirming shippable. The screen is about to gain
--      an un-confirm control (item 160). A symmetric guard would block the
--      repair on exactly the rows most likely to need it.
--   3. IT LETS THE GUARD CLEAN UP AFTER ITSELF. Any row confirmed in the
--      future BEFORE this migration stays wrong forever under a symmetric
--      guard -- the only way to fix it would be to wait for the date to
--      arrive. Asymmetric, the mistake is repairable the moment the guard
--      exists.
--
-- `session_date > current_date`, not `>=`. A workshop today is confirmable
-- today: Lorina's 28 October runs at 15:30 and she confirms it that evening.
-- Only tomorrow onwards is refused. (Both sessions are date-only; there is no
-- start_time comparison here, deliberately -- a trainer confirming at 15:00
-- for a 15:30 workshop is ten minutes of imprecision, while a trainer unable
-- to confirm until midnight is a broken screen.)
--
-- ===========================================================================
-- WHY OPERATIONS GETS THE SAME GUARD, which was the open question
-- ===========================================================================
-- The instinct is that Operations should be able to override -- it is the
-- correction path, it exists precisely to fix what trainers got wrong, and
-- 202610200002 used it to confirm 38 workshops on Anca's behalf.
--
-- Every one of those 38 was in the PAST. That is not a coincidence, it is the
-- shape of the function: a correction is a statement that THE RECORD IS
-- WRONG, and there is no record yet about a workshop that has not happened.
--
-- The override instinct is about WHO MAY CORRECT A RECORD. The guard is about
-- WHAT MAY BE ASSERTED. No role makes a future delivery true, and a
-- capability that could would be a capability to write down something false.
-- Same substitution as DATABASE_CONVENTIONS.md §19 -- reaching for a
-- permission when the question was about a fact.
--
-- Operations keeps everything that is genuinely theirs: no month-closed gate
-- (unchanged -- they correct closed months, that is the point), both slots in
-- one call, and the unrestricted ability to CLEAR a confirmation on any date.
--
-- IF A REAL CASE EVER APPEARS for pre-recording a delivery -- a school
-- confirming a term in advance by contract, say -- it is a different fact
-- with a different column, not this one. Record it as an item; do not widen
-- this.
--
-- ===========================================================================
-- ONE EXISTING ROW VIOLATES THE RULE, AND IT STAYS (convention §20)
-- ===========================================================================
-- `wow-lab-test-b` (is_test = true), the MAX group, 2026-11-08, principal
-- confirmed. A seed fixture for db/tests/payroll_org_session_pay.sql, written
-- by a migration rather than through an RPC, so this guard never saw it.
--
-- It is NOT corrected here. These are RPC guards, not a CHECK constraint, and
-- a CHECK would be wrong: it would make "the clock moved" into a constraint
-- violation on a row nobody touched. The fixture is recorded rather than
-- quietly left, because "no session is confirmed in the future" is a claim
-- somebody will make later and it is false by exactly one row.
--
-- The real organization is clean: zero future-dated confirmations.

-- ---------------------------------------------------------------------------
-- 1. The trainer's own path.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_confirm_session_attendance(
  p_session_id uuid,
  p_confirmed boolean
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
  v_is_principal boolean;
  v_is_secundar boolean;
  v_month_closed boolean;
begin
  select organization_id, session_date, trainer_principal_id, trainer_secundar_id
    into v_org, v_session_date, v_principal, v_secundar
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  v_is_principal := (v_principal = app.current_user_id());
  v_is_secundar := (v_secundar = app.current_user_id());
  if not v_is_principal and not v_is_secundar then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  -- THE NEW GUARD. Setting only -- clearing a confirmation on a future
  -- workshop is always allowed, and is how a mistake gets repaired.
  if p_confirmed and v_session_date > current_date then
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

  -- Exactly one of the two columns, chosen by which slot the CALLER holds --
  -- never both, never the caller's own non-slot, and there is no p_column
  -- parameter to ask with (item 91).
  if v_is_principal then
    update public.sessions
      set trainer_principal_confirmed_at = case when p_confirmed then now() else null end
      where id = p_session_id;
  else
    update public.sessions
      set trainer_secundar_confirmed_at = case when p_confirmed then now() else null end
      where id = p_session_id;
  end if;

  return 'ok';
end;
$$;

comment on function app.rpc_confirm_session_attendance(uuid, boolean) is
  'The trainer''s own confirmation that they taught a workshop. Writes exactly one of the two timestamp columns, chosen by which slot the CALLER holds (item 91 -- there is no column parameter to ask with). Returns: ok | not_found | not_assigned | future_session | month_closed. `future_session` is returned when p_confirmed is true and session_date > current_date: a confirmation is an assertion that a class was taught and nobody can make it in advance (202610200004''s own reasoning, enforced here rather than left as a comment). CLEARING a confirmation is never date-guarded -- "I did not teach this" is true about tomorrow by default, and that asymmetry is what lets a trainer repair their own mistake and what lets rows confirmed before this guard existed be cleaned up.';

-- ---------------------------------------------------------------------------
-- 2. Operations' correction path -- same guard, per column.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_correct_session_confirmation(
  p_session_id uuid,
  p_principal_confirmed boolean,
  p_secundar_confirmed boolean
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_session_date date;
  v_principal_was boolean;
  v_secundar_was boolean;
begin
  select organization_id, session_date,
         trainer_principal_confirmed_at is not null,
         trainer_secundar_confirmed_at is not null
    into v_org, v_session_date, v_principal_was, v_secundar_was
  from public.sessions where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('finance.operations.*', v_org)
  ) then
    return 'not_permitted';
  end if;

  -- Same guard, and per column rather than per call: a correction that
  -- CLEARS one slot on a future workshop must still go through, including
  -- when the other slot is already (wrongly) confirmed and is being left
  -- alone. Only TURNING ONE ON is refused.
  if v_session_date > current_date
     and ((p_principal_confirmed and not v_principal_was)
       or (p_secundar_confirmed and not v_secundar_was)) then
    return 'future_session';
  end if;

  update public.sessions
    set trainer_principal_confirmed_at = case when p_principal_confirmed then now() else null end,
        trainer_secundar_confirmed_at = case when p_secundar_confirmed then now() else null end
    where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_correct_session_confirmation(uuid, boolean, boolean) is
  'Operations'' correction of BOTH confirmation slots on one workshop. Gate: platform owner OR org.settings.manage OR finance.operations.*. NO month-closed gate -- correcting a closed month is the reason this exists. Returns: ok | not_found | not_permitted | future_session. It carries the SAME future-date guard as the trainer''s own path, and the reason it is not an exception for Operations: a correction says THE RECORD IS WRONG, and there is no record yet about a workshop that has not happened. The override instinct is about who may correct a record; the guard is about what may be asserted, and no role makes a future delivery true (DATABASE_CONVENTIONS.md §19). The guard is evaluated PER COLUMN against the current value, so clearing a wrongly-set future confirmation always succeeds even when the other slot stays set.';

-- ---------------------------------------------------------------------------
-- 3. Assertions.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_future integer;
  v_test_future integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'confirm-guard: no organization with slug wow-lab'; end if;

  -- The real org has nothing to clean up. If this ever fails, the guard
  -- still ships -- but somebody confirmed a future workshop first.
  select count(*) into v_future from public.sessions
  where organization_id = v_org and session_date > current_date
    and (trainer_principal_confirmed_at is not null or trainer_secundar_confirmed_at is not null);
  if v_future <> 0 then
    raise exception 'confirm-guard: % future-dated confirmations already exist in wow-lab -- clear them before relying on this guard', v_future;
  end if;

  -- And the one known exception, named rather than left to be discovered.
  select count(*) into v_test_future from public.sessions s
  join public.organizations o on o.id = s.organization_id
  where o.is_test and s.session_date > current_date
    and (s.trainer_principal_confirmed_at is not null or s.trainer_secundar_confirmed_at is not null);
  if v_test_future <> 1 then
    raise exception 'confirm-guard: expected exactly 1 future-dated confirmation in test organizations (the MAX fixture), found %', v_test_future;
  end if;

  -- Both functions still exist with their signatures intact.
  if to_regprocedure('app.rpc_confirm_session_attendance(uuid, boolean)') is null
     or to_regprocedure('app.rpc_correct_session_confirmation(uuid, boolean, boolean)') is null then
    raise exception 'confirm-guard: a function signature changed';
  end if;

  raise notice 'confirm-guard: both confirmation paths refuse future_session when SETTING; clearing stays open on every date. wow-lab has 0 future confirmations; 1 known test fixture is left as-is';
end $$;
