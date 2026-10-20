-- Rollback for cancel_19_21_october_school_holidays.sql.
--
-- Returns the six workshops of 19-21 October to `planned` and unconfirmed --
-- the state 202610200004 left them in -- and clears the four cancellation
-- columns. It does NOT re-create anything, because the forward migration
-- deletes nothing.
--
-- NOTE what this cannot undo: row_history has recorded the cancellation and
-- its actor, and that record stays. That is correct -- the cancellation did
-- happen, and un-cancelling is a second event, not the erasure of a first.

do $$
declare
  v_org uuid;
  v_n integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'cancel-holiday rollback: no organization with slug wow-lab';
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org
      and session_date between '2026-10-19' and '2026-10-21'
      and (trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null)
  ) then
    raise exception 'cancel-holiday rollback: a workshop in 19-21 October has been confirmed since -- refusing to rewrite its status';
  end if;

  update public.sessions
  set status = 'planned',
      cancellation_category = null,
      cancellation_note = null,
      cancelled_at = null,
      cancelled_by = null
  where organization_id = v_org
    and session_date between '2026-10-19' and '2026-10-21'
    and status = 'cancelled'
    and cancellation_category = 'vacanta';

  get diagnostics v_n = row_count;
  if v_n <> 6 then
    raise exception 'cancel-holiday rollback: restored % workshops, expected 6', v_n;
  end if;

  raise notice 'cancel-holiday rollback: 6 workshops of 19-21 October are planned and uncancelled again';
end $$;
