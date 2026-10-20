-- Rollback for 202610200003. Restores the four-category CHECK from
-- 202610190001 and removes the pay rule from app.calculate_session_pay.
--
-- CHECK FOR CANCELLED ROWS FIRST. The four old categories do not include
-- the two school splits, so any row already cancelled with
-- scoala_a_anulat_anuntat or scoala_a_anulat_neanuntat will violate the
-- restored constraint and this rollback will fail on it -- deliberately,
-- rather than discarding the distinction that decides whether the trainer
-- is paid:
--
--   select id, cancellation_category from public.sessions
--   where cancellation_category like 'scoala_a_anulat%';
--
-- Decide what those rows become before running this.
--
-- And removing the pay rule means a cancelled, non-payable workshop stops
-- returning 0 and starts raising on whichever input it is missing -- so it
-- reappears on /payroll under "Gaps in the pay grid", which is the opposite
-- of true. Revert the screen in the same step.

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

  select organization_id, session_date, duration_minutes, location_tier, trainer_principal_id, trainer_secundar_id, group_id
    into v_org, v_session_date, v_duration_minutes, v_location_tier, v_principal_id, v_secundar_id, v_group_id
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    raise exception 'app.calculate_session_pay: no session % ', p_session_id;
  end if;

  if p_trainer_id is distinct from v_principal_id and p_trainer_id is distinct from v_secundar_id then
    raise exception 'app.calculate_session_pay: trainer % is not the principal or secundar trainer on session %', p_trainer_id, p_session_id;
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

alter table public.sessions
  drop constraint if exists sessions_cancellation_category_check;

alter table public.sessions
  add constraint sessions_cancellation_category_check
  check (cancellation_category is null or cancellation_category in
    ('scoala_a_anulat', 'trainer_indisponibil', 'vacanta', 'alt_motiv'));

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
  from public.sessions where id = p_session_id;
  if v_org is null then return 'not_found'; end if;

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

  if v_status = 'cancelled' then return 'already_cancelled'; end if;

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
