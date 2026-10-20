-- app.rpc_cancel_session, superseding 202610190001, with the five
-- categories and the pay rule Anca's answer requires.
--
-- 202610190001 is applied. It is NOT edited (the don't-edit-an-applied-
-- migration rule, DATABASE_CONVENTIONS §9); it is replaced here, and its
-- header's claim that "PAY IS UNTOUCHED" is corrected by this file and by
-- OPEN_ITEMS item 139.
--
-- ===========================================================================
-- WHY THIS GOES FIRST: it is the precondition for generating a schedule
-- ===========================================================================
-- Item 139 measured that a workshop, once created, is permanent -- six of
-- eighteen columns writable, `status` not among them, no delete anywhere.
-- That is why schedule generation was held behind a school-holiday
-- calendar: generation without one would put workshops into holidays that
-- nobody could remove. This function dissolves that dependency. Once a
-- workshop can be cancelled, one generated into a holiday is repairable,
-- and the calendar becomes a quality improvement rather than an absolute
-- precondition.
--
-- ===========================================================================
-- THE PAY RULE. Cancellation DOES touch pay, in exactly one case.
-- ===========================================================================
-- Anca's rule: the school gives notice and the trainer does not travel ->
-- not paid. The school gives notice and the trainer travels anyway because
-- they missed it -> their mistake, not paid. The school FORGETS to give
-- notice and the trainer finds an empty room -> PAID.
--
-- So the determinant is not who cancelled but WHETHER THE SCHOOL GAVE
-- NOTICE, which is why `scoala_a_anulat` had to split in two.
--
--     payable = confirmed OR (cancelled AND reason = scoala_a_anulat_neanuntat)
--
-- That rule lives in exactly one place: app.calculate_session_pay's own
-- guard, below. Not duplicated into the screen, not into the sums function.
--
-- PAYING WITHOUT A CONFIRMATION IS NOT A SECOND SOURCE OF AUTHORITY. It is
-- a second way of recording the same fact -- that the trainer's time was
-- spent. The trainer asserts it by confirming; Operations asserts it by
-- cancelling with "the school gave no notice". One fact, two witnesses.
--
-- AND THE CONFIRMATION COLUMNS ARE NOT REUSED FOR IT. They already carry
-- two documented meanings -- "Pay follows this timestamp" (202609150002)
-- and "when the trainer asserted delivery" (202609220001). A third would
-- make the column unusable for reasoning: nobody reading
-- trainer_principal_confirmed_at could then say what it attests. The
-- cancellation row is the witness; the pay rule reads both.
--
-- ===========================================================================
-- A DECIDED ZERO IS NOT A THIRD STATE. It is 0 with no reason_code.
-- ===========================================================================
-- A cancelled, non-payable workshop returns **0**, and `reason_code` stays
-- null. A calculable workshop can never produce 0 -- the smallest real
-- product is a rate times a multiplier times at least 1.00 -- so 0 is
-- unambiguously "a decided zero". The screen explains it from the session's
-- own cancellation data, which it already has.
--
-- `reason_code` remains EXCLUSIVELY for reasons that BLOCK the calculation:
-- a failure, not an answer. Mixing "could not be computed" with "computed,
-- and the answer is nothing" into one field would destroy the distinction
-- the classifier exists to make -- and would file a decided zero under
-- "Gaps in the pay grid, not fixable from this screen", which is the
-- opposite of true.
--
-- ===========================================================================
-- GATE: sessions.create (+ org.settings.manage / platform owner).
-- ===========================================================================
-- Operations, not Finance and not the trainer. 202609150002's fork decision
-- already assigned `sessions.status` to Operations as its scheduling field,
-- and a cancellation is a fact about the schedule. A trainer saying "it did
-- not happen" is making an assertion, not recording an observation, and has
-- money on the client side of it.
--
-- finance.operations.* is deliberately ABSENT, and that handoff is the
-- point rather than friction: at close Anka sees "not confirmed", which is
-- ambiguous between "it did not happen" and "it happened and the trainer
-- forgot". Operations knows which, because the school tells them. If it
-- bites, the repair is a button on the unconfirmed row that flags it for
-- Operations -- NOT widening this gate (item 139 records that so it does
-- not widen out of convenience).
--
-- NO MONTH-CLOSED GATE. app.rpc_confirm_session_attendance refuses once the
-- month is closed because CONFIRMATION IS A PAY INPUT -- locking it is what
-- stops someone altering an invoice already issued. Cancellation of the
-- non-payable kind is not a pay input, so that gate's reason does not
-- transfer. (The payable kind IS a pay input, and that is the one real
-- tension here -- see the note on the closed-month screen below.)

-- ---------------------------------------------------------------------------
-- 1. The five categories.
-- ---------------------------------------------------------------------------
alter table public.sessions
  drop constraint if exists sessions_cancellation_category_check;

alter table public.sessions
  add constraint sessions_cancellation_category_check
  check (cancellation_category is null or cancellation_category in (
    'scoala_a_anulat_anuntat',    -- school gave notice            -> not paid
    'scoala_a_anulat_neanuntat',  -- school gave NO notice         -> PAID
    'trainer_indisponibil',       -- trainer did not make it       -> not paid
    'vacanta',                    -- school-calendar holiday       -> not paid
    'alt_motiv'                   -- note required, decided by hand
  ));

comment on column public.sessions.cancellation_category is
  'Why the workshop did not happen, as one of five categories rather than free text -- so "how many times did this client cancel" is a group by rather than somebody reading 200 rows. The two school categories are split on WHETHER NOTICE WAS GIVEN, because that is what decides pay: scoala_a_anulat_neanuntat is the one cancelled workshop that is still paid (Anca''s rule -- the trainer travelled and found an empty room).';

-- ---------------------------------------------------------------------------
-- 2. The pay rule, in one place.
-- ---------------------------------------------------------------------------
-- app.calculate_session_pay gains a single guard at the top. Everything
-- below it is unchanged from 202609250001 -- same reads, same resolvers,
-- same unrounded product, same raise messages (so the reason_code
-- classifier and db/tests/payroll_reason_code_coverage.sql are unaffected).
create or replace function app.calculate_session_pay(
  p_session_id uuid,
  p_trainer_id uuid
)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_org uuid;
  v_session_date date;
  v_duration_minutes integer;
  v_location_tier text;
  v_principal_id uuid;
  v_secundar_id uuid;
  v_group_id uuid;
  v_status text;
  v_cancellation_category text;
  v_delivery_format text;
  v_language_group text;
  v_grade integer;
  v_rate numeric;
  v_duration_multiplier numeric;
  v_location_bonus numeric;
  v_language_bonus numeric;
begin
  if p_trainer_id is null then
    raise exception 'app.calculate_session_pay: p_trainer_id must not be null';
  end if;

  select organization_id, session_date, duration_minutes, location_tier,
         trainer_principal_id, trainer_secundar_id, group_id, status, cancellation_category
    into v_org, v_session_date, v_duration_minutes, v_location_tier,
         v_principal_id, v_secundar_id, v_group_id, v_status, v_cancellation_category
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    raise exception 'app.calculate_session_pay: no session % ', p_session_id;
  end if;

  if p_trainer_id is distinct from v_principal_id and p_trainer_id is distinct from v_secundar_id then
    raise exception 'app.calculate_session_pay: trainer % is not the principal or secundar trainer on session %', p_trainer_id, p_session_id;
  end if;

  -- THE PAY RULE, and the only place it exists.
  --
  --     payable = confirmed OR (cancelled AND scoala_a_anulat_neanuntat)
  --
  -- A cancelled workshop that is NOT payable returns 0, deliberately rather
  -- than raising: nothing is missing, the answer is nothing. 0 is
  -- unambiguous because a calculable workshop cannot produce it. Returned
  -- BEFORE every input guard below, so a cancelled workshop with no
  -- duration recorded reads as a decided zero rather than as a gap -- which
  -- is the common case, since a workshop that never happened is exactly the
  -- one nobody finished filling in.
  if v_status = 'cancelled' and v_cancellation_category is distinct from 'scoala_a_anulat_neanuntat' then
    return 0;
  end if;

  if v_duration_minutes is null then
    raise exception 'app.calculate_session_pay: session % has no duration_minutes recorded', p_session_id;
  end if;

  if v_location_tier is null then
    raise exception 'app.calculate_session_pay: session % has no location_tier recorded', p_session_id;
  end if;

  select delivery_format, language_group into v_delivery_format, v_language_group
  from public.groups
  where id = v_group_id;

  if v_language_group is null then
    raise exception 'app.calculate_session_pay: group % has no language_group recorded', v_group_id;
  end if;

  v_grade := app.resolve_trainer_grade(p_trainer_id, v_session_date);
  v_rate := app.resolve_trainer_grade_rate(v_org, v_grade, v_session_date);
  v_duration_multiplier := app.resolve_duration_multiplier(v_org, v_duration_minutes, v_delivery_format, v_session_date);
  v_location_bonus := app.resolve_location_bonus(v_org, v_location_tier, v_session_date);
  v_language_bonus := app.resolve_language_bonus(v_org, v_language_group, v_session_date);

  return v_rate * v_duration_multiplier * (1 + v_location_bonus / 100 + v_language_bonus / 100);
end;
$$;

comment on function app.calculate_session_pay(uuid, uuid) is
  'Pay for one trainer slot on one workshop, unrounded. Carries THE pay rule, in the only place it exists: payable = confirmed OR (cancelled AND cancellation_category = scoala_a_anulat_neanuntat). A cancelled workshop that is not payable returns 0 -- a decided zero, not a failure, which is why it has no reason_code and why a calculable workshop can never produce 0. Note this function does NOT read the confirmation timestamps: confirmation gates pay at the screen/sums layer (unconfirmed slots are listed, not summed), while this function answers "what is this slot worth" and refuses only the non-payable cancellations. SECURITY INVOKER.';

-- ---------------------------------------------------------------------------
-- 3. The function.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_cancel_session(
  p_session_id uuid,
  p_category text,
  p_note text
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_status text;
begin
  select organization_id, status into v_org, v_status
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('sessions.create', v_org)
  ) then
    return 'not_permitted';
  end if;

  if p_category is null or p_category not in
     ('scoala_a_anulat_anuntat', 'scoala_a_anulat_neanuntat',
      'trainer_indisponibil', 'vacanta', 'alt_motiv') then
    return 'invalid_category';
  end if;

  if p_category = 'alt_motiv' and coalesce(btrim(p_note), '') = '' then
    return 'note_required';
  end if;

  if v_status = 'cancelled' then
    return 'already_cancelled';
  end if;

  -- Does NOT touch trainer_*_confirmed_at or attendance_count. The pay
  -- consequence is read from the category by calculate_session_pay, never
  -- written into the confirmation columns.
  update public.sessions
  set status = 'cancelled',
      cancellation_category = p_category,
      cancellation_note = nullif(btrim(coalesce(p_note, '')), ''),
      cancelled_at = now(),
      cancelled_by = app.current_user_id()
  where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_cancel_session(uuid, text, text) is
  'Marks a workshop as not held: status = cancelled plus one of five categories and an optional note (required for alt_motiv). Gate: is_platform_owner() OR org.settings.manage OR sessions.create -- Operations, because a cancellation is a fact about the schedule (202609150002''s fork decision). No month-closed gate. Does not write the confirmation columns: the pay consequence is derived from the category by app.calculate_session_pay. Does not reverse -- see OPEN_ITEMS item 139.';

revoke all on function app.rpc_cancel_session(uuid, text, text) from public;
grant execute on function app.rpc_cancel_session(uuid, text, text) to authenticated;

create or replace function public.rpc_cancel_session(p_session_id uuid, p_category text, p_note text)
returns text
language sql
security invoker
set search_path to ''
as $$
  select app.rpc_cancel_session(p_session_id, p_category, p_note);
$$;

comment on function public.rpc_cancel_session(uuid, text, text) is
  'PostgREST-exposed wrapper around app.rpc_cancel_session(). SECURITY INVOKER, forwarding only.';

revoke all on function public.rpc_cancel_session(uuid, text, text) from public;
grant execute on function public.rpc_cancel_session(uuid, text, text) to authenticated;
