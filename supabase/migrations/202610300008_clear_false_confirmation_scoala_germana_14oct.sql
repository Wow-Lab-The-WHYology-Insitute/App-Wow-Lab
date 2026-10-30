-- Clears the trainer_principal_confirmed_at assertion on the two 2026-10-14
-- Scoala Germana sessions (item 176), per Mihai's explicit instruction,
-- 2026-10-30. Does NOT cancel, delete, or change status -- only withdraws
-- the confirmation statement itself.
--
-- ===========================================================================
-- WHY: item 152's own rule, applied to the rows that produced it
-- ===========================================================================
-- Item 152 (§17, fourth application) found that `202610200002`'s import
-- confirmed these two rows under a reason true for 36 of the 38 imported
-- workshops and false for these 2 -- the real timesheet's last DSBU row for
-- Scoala Germana is 7 October, not 14. The rule that finding set, written
-- there and restated here because it is what licenses this migration:
--
--   "A workshop imported as already-held needs an external record saying
--    it happened, on that date. A recurrence pattern says what was
--    SCHEDULED, never what was DELIVERED -- those are different facts, and
--    only one of them is evidence."
--
-- These two rows have no such record. Under our own rule, they cannot be
-- confirmed. That is not the same as knowing they were NOT taught -- nobody
-- has checked that either way -- which is exactly why the STATEMENT is
-- withdrawn and the SESSION is not touched. "Confirmed" would assert a fact
-- nobody has evidence for; "cancelled" would assert its opposite, equally
-- unevidenced. Only "we don't yet know" is honest, and that is simply the
-- absence of a confirmation -- the column's own default state.
--
-- ===========================================================================
-- THE FIRST REAL USE OF THE GUARD'S ASYMMETRY (202610220001)
-- ===========================================================================
-- That migration gave three reasons for SETTING a confirmation on a future
-- date being refused while CLEARING one stays unrestricted on every date.
-- The third: "it lets the guard clean up after itself... the mistake is
-- repairable the moment the guard exists." These two rows are not
-- future-dated -- the guard's literal future-date check never touched
-- them -- but they are exactly the shape of mistake that reasoning was
-- written for: an assertion made before the rule existed, repaired once it
-- did. This is that repair. Nothing about this withdrawal needed a special
-- exception or a wait for any date to arrive -- clearing a confirmation was
-- never restricted, on any date, which is the whole point being exercised
-- here for the first time against a real row rather than a hypothetical.
--
-- ===========================================================================
-- WHY THIS IS A DIRECT UPDATE, NOT A CALL TO app.rpc_correct_session_confirmation
-- -- AND WHY NO ACTOR IS ATTRIBUTED
-- ===========================================================================
-- That RPC is the real write path and is not bypassed lightly -- but its
-- gate requires org.settings.manage or finance.operations.* on a REAL
-- account, and in wow-lab today exactly two real accounts hold either:
-- Anca (the "Platform Owner" role) and Laura (Finance Operations). Neither
-- of them decided this. Mihai did, directly, in this conversation -- and
-- his own real account (hello@maxdigital.ro) holds no role in wow-lab at
-- all, so it cannot pass that gate either.
--
-- Borrowing Anca's or Laura's identity to pass the gate would repeat, in
-- this very migration, the exact mistake item 152 corrected: a real
-- person's name attached, in row_history, to a decision they did not make.
-- Point 2 of Mihai's own instruction names this precisely -- the false
-- confirmation's damage was never "two extra rows," it was "an assertion in
-- a person's name that they never made." Fixing that by making a NEW false
-- attribution, to clear the first one, would not be a fix.
--
-- So this migration impersonates nobody. `app.current_user_id()` (which is
-- `auth.uid()`, which is what `row_history_capture()` actually calls --
-- confirmed by reading `202608260001`'s own fix) returns a clean NULL with
-- no request.jwt.claims set, already verified empirically by that same
-- migration under both a direct connection and an unimpersonated
-- service-role session. `row_history` will record `actor_user_id = NULL`
-- on both rows this writes. That NULL is the honest answer: no specific
-- person is asserting this withdrawal. It is this project's own written
-- rule being applied to data that violates it.

do $$
declare
  v_row1 record;
  v_row2 record;
  v_expected_confirmed_at timestamptz := '2026-10-20 12:24:11.22144+00';
begin
  select id, session_date, status, trainer_principal_confirmed_at
    into v_row1
  from public.sessions
  where id = '725eaf35-49ce-4adc-92db-d71db1f6fea7';

  select id, session_date, status, trainer_principal_confirmed_at
    into v_row2
  from public.sessions
  where id = '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46';

  if v_row1.id is null or v_row2.id is null then
    raise exception 'clear-false-confirmation: one or both target sessions no longer exist -- re-read item 176 before re-running this';
  end if;

  if v_row1.session_date <> '2026-10-14' or v_row2.session_date <> '2026-10-14' then
    raise exception 'clear-false-confirmation: a target row''s session_date has changed -- re-verify before applying';
  end if;

  if v_row1.status <> 'delivered' or v_row2.status <> 'delivered' then
    raise exception 'clear-false-confirmation: a target row''s status has changed (expected delivered, found % / %) -- re-verify before applying, status is not what this migration touches', v_row1.status, v_row2.status;
  end if;

  if v_row1.trainer_principal_confirmed_at is distinct from v_expected_confirmed_at
     or v_row2.trainer_principal_confirmed_at is distinct from v_expected_confirmed_at then
    raise exception 'clear-false-confirmation: a target row''s trainer_principal_confirmed_at is not the known 2026-10-20 import timestamp any more -- someone else has already touched this, re-verify before applying';
  end if;

  update public.sessions
    set trainer_principal_confirmed_at = null
    where id in ('725eaf35-49ce-4adc-92db-d71db1f6fea7', '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46');

  raise notice 'clear-false-confirmation: trainer_principal_confirmed_at cleared on both 2026-10-14 Scoala Germana sessions. status untouched (still delivered). actor_user_id on both new row_history rows is NULL, by design -- see this migration''s own header.';
end $$;

do $$
declare
  v_still_confirmed integer;
  v_status_1 text;
  v_status_2 text;
  v_history_actor_1 uuid;
  v_history_actor_2 uuid;
begin
  select count(*) into v_still_confirmed
  from public.sessions
  where id in ('725eaf35-49ce-4adc-92db-d71db1f6fea7', '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46')
    and trainer_principal_confirmed_at is not null;

  if v_still_confirmed <> 0 then
    raise exception 'clear-false-confirmation: % row(s) still carry a confirmation after the update', v_still_confirmed;
  end if;

  select status into v_status_1 from public.sessions where id = '725eaf35-49ce-4adc-92db-d71db1f6fea7';
  select status into v_status_2 from public.sessions where id = '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46';
  if v_status_1 <> 'delivered' or v_status_2 <> 'delivered' then
    raise exception 'clear-false-confirmation: status changed when it should not have (% / %)', v_status_1, v_status_2;
  end if;

  select actor_user_id into v_history_actor_1
  from public.row_history
  where table_name = 'sessions' and row_id = '725eaf35-49ce-4adc-92db-d71db1f6fea7'
  order by changed_at desc limit 1;

  select actor_user_id into v_history_actor_2
  from public.row_history
  where table_name = 'sessions' and row_id = '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46'
  order by changed_at desc limit 1;

  if v_history_actor_1 is not null or v_history_actor_2 is not null then
    raise exception 'clear-false-confirmation: the newest row_history row carries a non-null actor_user_id -- this migration was impersonated, which it must not be';
  end if;

  raise notice 'clear-false-confirmation: assertion passed. Both sessions: status=delivered, trainer_principal_confirmed_at=null, newest row_history actor_user_id=null.';
end $$;
