-- app.rpc_cancel_session: the first and only way the application can
-- record that a workshop did not happen.
--
-- Item 139 measured the hole: of sessions' eighteen columns, exactly six
-- were writable after creation by any sanctioned path, `status` was not
-- one of them, no function deleted a session, and `authenticated` held
-- INSERT and SELECT only. So `status = 'cancelled'` existed in the CHECK
-- constraint and nothing in the system could ever set it. A workshop
-- cancelled, replaced by a school trip, lost to a parents' evening or a
-- short day stayed recorded, permanently, as a workshop that is going to
-- happen. Six such cases a year on two groups of one school, at 700-770
-- RON a session of client billing each.
--
-- NOT A DELETE, by convention 12: where a table already has a status value
-- meaning "no longer active, keep the row and its history", a hard delete
-- is a second contradictory answer. `cancelled` is that value.
--
-- THE REASON IS A CATEGORY, NOT FREE TEXT (Mihai's decision, 2026-10-16).
-- Free text would mean Anka can never answer "how many times did Avenor
-- cancel this year" -- the question you ask when renegotiating a
-- per-session price. A category answers it with a group by; text answers
-- it with somebody reading two hundred rows. The four come from last
-- year's real cases, and the first two point in opposite directions:
-- scoala_a_anulat is the client's doing and bears on the invoice,
-- trainer_indisponibil is ours and bears on the trainer. `alt_motiv`
-- requires the note, which is the only reason the note column is not
-- merely decorative.
--
-- PAY IS UNTOUCHED. Pay follows the two confirmation timestamps, exactly
-- as before; this function does not read or write them, and does not touch
-- attendance_count. A cancelled workshop nobody confirmed is simply not
-- paid, which is the rule that was already in force. The case of a trainer
-- who travelled to a school that cancelled on the spot is Anca's to answer
-- and does not change this function -- it would only decide whether a
-- separate way to record "the trainer travelled" is added later. What it
-- must never become is a reason to confirm delivery of something that was
-- not delivered: that would pay correctly and record falsely.
--
-- GATE: sessions.create (plus org.settings.manage / platform owner).
-- NOT the trainer: a trainer saying "it did not happen" is making an
-- assertion, not recording an observation, and has money on the client
-- side of it. And the schema had already decided this -- 202609150002's
-- own fork decision says `sessions.status` stays Operations' scheduling
-- field, and a cancellation is a fact about the schedule, not about
-- delivery. So the same capability that may create a workshop may cancel
-- it; this is the existing authority applied, not a new one.
--
-- finance.operations.* is deliberately ABSENT. At close Anka sees "not
-- confirmed", which is ambiguous between "it did not happen" and "it
-- happened and the trainer forgot"; Operations knows which, because the
-- school tells them. A gate that let Finance resolve that alone would be
-- inviting a guess about money. If the handoff bites, the repair is a
-- button on the unconfirmed row that flags it for Operations -- NOT
-- widening this gate, which is the comfortable change someone will reach
-- for later (item 139 records this so it does not happen quietly).
--
-- NO MONTH-CLOSED GATE, deliberately, and this is the one place this
-- function differs from its closest sibling. app.rpc_confirm_session_
-- attendance refuses once the month is closed because CONFIRMATION IS A
-- PAY INPUT -- locking it is what stops someone altering an invoice that
-- has already been issued. Cancellation is not a pay input, so the reason
-- for that gate does not transfer, and copying it would be copying a rule
-- without its argument.
--
-- But a cancellation inside a closed month changes the CLIENT billing
-- count for a month already invoiced, so it has to be VISIBLE rather than
-- merely permitted. Two things make it so: cancelled_at is stored (not
-- just inferable from row_history), and /payroll's closed-month list says
-- when a month contains a workshop cancelled after it was closed. The
-- screen ships with this migration, not after it.
--
-- WHAT IS NOT BUILT: un-cancelling. Reversal would need the pre-cancellation
-- status restored, and `status` is not recoverable from these four columns
-- alone -- it would mean either storing the previous value or reading
-- row_history. A mis-cancellation is therefore as permanent today as an
-- unheld workshop was yesterday, which is the same class of defect one
-- step smaller. Recorded in item 139 rather than guessed at here.

alter table public.sessions
  add column cancelled_at timestamptz,
  add column cancelled_by uuid references public.users(id),
  add column cancellation_category text,
  add column cancellation_note text;

comment on column public.sessions.cancelled_at is 'When the workshop was marked as not held. Stored rather than left to row_history because /payroll compares it against payroll_periods.closed_at to show that a closed month contains a cancellation made after closing.';
comment on column public.sessions.cancellation_category is 'Why it did not happen, as one of four categories rather than free text -- so "how many times did this client cancel" is a group by. scoala_a_anulat and trainer_indisponibil are the two causes with opposite consequences: the first bears on the client invoice, the second on the trainer.';
comment on column public.sessions.cancellation_note is 'Free-text detail alongside the category, never instead of it. Required only for alt_motiv.';

alter table public.sessions
  add constraint sessions_cancellation_category_check
  check (cancellation_category is null or cancellation_category in
    ('scoala_a_anulat', 'trainer_indisponibil', 'vacanta', 'alt_motiv'));

-- The four columns are set together with status = 'cancelled' or not at
-- all. Without this a row could carry a reason while reading as planned,
-- or read as cancelled with no reason at all -- and the second is exactly
-- the free-text-equivalent outcome the category exists to prevent.
alter table public.sessions
  add constraint sessions_cancellation_consistency_check
  check (
    case when status = 'cancelled' then
      cancellation_category is not null
      and cancelled_at is not null
      and cancelled_by is not null
      and (cancellation_category <> 'alt_motiv' or coalesce(btrim(cancellation_note), '') <> '')
    else
      cancellation_category is null
      and cancelled_at is null
      and cancelled_by is null
      and cancellation_note is null
    end
  );

comment on constraint sessions_cancellation_consistency_check on public.sessions is
  'A cancelled workshop carries all four cancellation columns; a non-cancelled one carries none of them. alt_motiv additionally requires a non-blank note -- the category is what makes cancellations countable, and an uncategorised cancellation would defeat it.';

-- ---------------------------------------------------------------------------
-- Narrowing INSERT, the way 202609220003 learned it has to be done.
-- ---------------------------------------------------------------------------
-- sessions' grant to authenticated is TABLE-level (relacl: authenticated=arm),
-- with no column ACLs at all -- so the four columns added above would be
-- insertable by any sessions.create holder the moment they exist, and a
-- direct PostgREST insert could create an already-cancelled workshop with a
-- fabricated cancelled_by. INSERTs are also not captured by
-- sessions_row_history, which is BEFORE DELETE OR UPDATE, so that would
-- leave no actor behind at all.
--
-- A column-level REVOKE alone would do NOTHING here: Postgres ACL entries
-- are additive and a table-wide grant keeps authorizing every column
-- regardless of a narrower revoke layered on top. 202609220001 shipped
-- exactly that mistake on contracts.billing_rule and the three financial
-- columns were never actually protected until 202609220003 revoked the
-- table-level grant and re-granted the explicit column list. Same fix
-- here, same shape: revoke INSERT on the table, grant it back on the
-- eighteen pre-existing columns only.
--
-- SELECT stays table-wide on purpose -- the new columns must be readable,
-- /payroll renders them. Only INSERT is narrowed. There is no UPDATE grant
-- to narrow: authenticated has never held one, which is why every session
-- write goes through a SECURITY DEFINER function already.
revoke insert on public.sessions from authenticated;
grant insert (
  id, organization_id, group_id, session_date,
  trainer_principal_id, trainer_secundar_id, status,
  attendance_count, experiment_delivered, notes,
  created_at, updated_at, duration_minutes, experiment_drive_link,
  location_tier, trainer_principal_confirmed_at, trainer_secundar_confirmed_at,
  start_time
) on public.sessions to authenticated;

-- ---------------------------------------------------------------------------
-- The function.
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

  -- Operations, not Finance and not the trainer. See the header.
  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('sessions.create', v_org)
  ) then
    return 'not_permitted';
  end if;

  if p_category is null or p_category not in
     ('scoala_a_anulat', 'trainer_indisponibil', 'vacanta', 'alt_motiv') then
    return 'invalid_category';
  end if;

  if p_category = 'alt_motiv' and coalesce(btrim(p_note), '') = '' then
    return 'note_required';
  end if;

  -- Not an error worth raising, but not silently re-stamped either: a
  -- second cancellation would move cancelled_at and lose the first
  -- actor, which is the one thing the closed-month view reads.
  if v_status = 'cancelled' then
    return 'already_cancelled';
  end if;

  -- Deliberately does NOT touch trainer_*_confirmed_at or
  -- attendance_count. Pay follows confirmation, unchanged.
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
  'Marks a workshop as not held: status = cancelled plus a required category and an optional note (required for alt_motiv). Gate: is_platform_owner() OR org.settings.manage OR sessions.create -- Operations, because a cancellation is a fact about the schedule (202609150002''s fork decision) and a trainer saying it did not happen is making an assertion. No month-closed gate, deliberately: that gate exists on confirmation because confirmation is a pay input, and cancellation is not. Does not touch pay. Does not reverse.';

revoke all on function app.rpc_cancel_session(uuid, text, text) from public;
grant execute on function app.rpc_cancel_session(uuid, text, text) to authenticated;

-- PostgREST-exposed wrapper: the app schema is not in config.toml's [api]
-- schemas list, so .rpc() cannot reach it. Same shape as the six wrappers
-- in 202609220002 -- SECURITY INVOKER, forwarding only, no elevation of
-- its own (the app.* function is already SECURITY DEFINER with its own
-- authorization check).
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
