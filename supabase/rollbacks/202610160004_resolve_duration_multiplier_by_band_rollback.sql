-- Rollback for 202610160004. Restores the equality-match resolver from
-- 202609210006 verbatim (including its lack of a pinned search_path), and
-- restores the reason_code classifier that matched its message.
--
-- WHAT ROLLING THIS BACK COSTS. The equality resolver cannot price 45- or
-- 50-minute workshops, which is four of the six real 2026-2027 groups and
-- 26 of the 38 workshops already delivered. It also re-opens the
-- 30-minute Scoala Altfel gap. Do not roll this back to fix something
-- else; it is the only thing making the real schedule payable.
--
-- Both functions go together. Restoring the resolver without the
-- classifier would leave '%is longer than the longest band%' matching
-- nothing and the old message falling through to 'unknown' -- which
-- db/tests/payroll_reason_code_coverage.sql would catch, but only after
-- the screen had started printing raw SQL at Anka.
--
-- db/tests/payroll_org_session_pay.sql block 2 must also be reverted to
-- the 30-minute Scoala Altfel fixture; under the equality resolver the
-- over-120 fixture raises the same way, so the test would still pass but
-- for the wrong reason, which is worse than failing.

create or replace function app.resolve_duration_multiplier(
  p_organization_id uuid,
  p_duration_minutes integer,
  p_delivery_format text,
  p_as_of date
)
returns numeric
language plpgsql
stable
as $$
declare
  v_context text;
  v_version_id uuid;
  v_multiplier numeric;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  select id into v_version_id
  from public.duration_multiplier_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select multiplier into v_multiplier
  from public.duration_multiplier_rates
  where version_id = v_version_id
    and duration_minutes = p_duration_minutes
    and delivery_context = v_context;

  if v_multiplier is null then
    raise exception 'app.resolve_duration_multiplier: version % has no row for % minutes / context % -- incomplete version', v_version_id, p_duration_minutes, v_context;
  end if;

  return v_multiplier;
end;
$$;

-- The classifier as it stood before 202610160004: no 'no_duration_bands'
-- branch, and '%minutes / context%' back in place of
-- '%is longer than the longest band%'.
create or replace function app.calculate_org_session_pay(
  p_organization_id uuid,
  p_from date,
  p_to_exclusive date
)
returns table (
  session_id uuid,
  trainer_id uuid,
  slot text,
  amount numeric,
  reason_code text,
  error_text text
)
language plpgsql
stable
set search_path to ''
as $$
declare
  v_session record;
  v_slot text;
  v_trainer uuid;
  v_amount numeric;
  v_reason text;
  v_error text;
begin
  if p_from is null or p_to_exclusive is null then
    raise exception 'app.calculate_org_session_pay: p_from and p_to_exclusive must not be null';
  end if;

  if p_to_exclusive <= p_from then
    raise exception 'app.calculate_org_session_pay: p_to_exclusive (%) must be after p_from (%)', p_to_exclusive, p_from;
  end if;

  for v_session in
    select s.id, s.trainer_principal_id, s.trainer_secundar_id
    from public.sessions s
    where s.organization_id = p_organization_id
      and s.session_date >= p_from
      and s.session_date < p_to_exclusive
    order by s.session_date, s.id
  loop
    for v_slot, v_trainer in
      select *
      from (values ('principal', v_session.trainer_principal_id),
                   ('secundar', v_session.trainer_secundar_id)) as t(slot, trainer)
    loop
      if v_trainer is null then
        continue;
      end if;

      begin
        v_amount := round(app.calculate_session_pay(v_session.id, v_trainer), 2);
        v_reason := null;
        v_error := null;
      exception when others then
        v_amount := null;
        v_error := sqlerrm;
        v_reason := case
          when v_error like '%p_trainer_id must not be null%'              then 'no_trainer'
          when v_error like '%has no duration_minutes recorded%'           then 'no_duration'
          when v_error like '%has no location_tier recorded%'              then 'no_location'
          when v_error like '%has no language_group recorded%'             then 'no_language'
          when v_error like '%not the principal or secundar trainer%'      then 'not_on_session'
          when v_error like '%no session %'                                then 'no_session'
          when v_error like '%no trainer_grade_assignments row%'           then 'no_grade'
          when v_error like '%no trainer_grade_versions row effective%'    then 'no_grade_version'
          when v_error like '%has no row for grade level%'                 then 'no_grade_rate_row'
          when v_error like '%no duration_multiplier_versions row effective%' then 'no_duration_version'
          when v_error like '%minutes / context%'                         then 'no_duration_row'
          when v_error like '%no location_bonus_versions row effective%'    then 'no_location_version'
          when v_error like '%has no row for tier%'                        then 'no_location_row'
          when v_error like '%no language_bonus_versions row effective%'    then 'no_language_version'
          when v_error like '%has no row for language group%'              then 'no_language_row'
          else 'unknown'
        end;
      end;

      session_id := v_session.id;
      trainer_id := v_trainer;
      slot := v_slot;
      amount := v_amount;
      reason_code := v_reason;
      error_text := v_error;
      return next;
    end loop;
  end loop;
end;
$$;
