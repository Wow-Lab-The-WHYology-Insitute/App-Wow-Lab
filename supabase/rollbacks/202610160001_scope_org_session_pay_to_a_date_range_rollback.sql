-- Rollback for 202610160001. Drops the range-scoped pair and restores the
-- org-wide single-argument pair from 202610150003 verbatim.
--
-- Restored rather than merely dropped, because /payroll has a caller: a
-- bare drop would leave the page's .rpc() hitting nothing. The page's own
-- guard renders the "sums not available" state rather than crashing, so it
-- would degrade to confirmations and the pre-close check -- but a screen
-- that silently stops showing money is worse than one that is obviously
-- rolled back, so this restores the function the previous page version
-- called.
--
-- Rolling this back WITHOUT reverting app/(app)/payroll to its
-- 202610150003-era state leaves a signature mismatch: the page calls
-- calculate_org_session_pay(uuid, date, date) and only (uuid) would exist.
-- Revert both in the same step.

drop function if exists public.calculate_org_session_pay(uuid, date, date);
drop function if exists app.calculate_org_session_pay(uuid, date, date);

create or replace function app.calculate_org_session_pay(p_organization_id uuid)
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
  for v_session in
    select s.id, s.trainer_principal_id, s.trainer_secundar_id
    from public.sessions s
    where s.organization_id = p_organization_id
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
          when v_error like '%has no duration_minutes recorded%'          then 'no_duration'
          when v_error like '%has no location_tier recorded%'             then 'no_location'
          when v_error like '%has no language_group recorded%'            then 'no_language'
          when v_error like '%not the principal or secundar trainer%'     then 'not_on_session'
          when v_error like '%no trainer_grade_assignments row%'          then 'no_grade'
          when v_error like '%no trainer_grade_versions row effective%'   then 'no_grade_version'
          when v_error like '%has no row for grade level%'                then 'no_grade_rate_row'
          when v_error like '%no duration_multiplier_versions row effective%' then 'no_duration_version'
          when v_error like '%minutes / context%'                        then 'no_duration_row'
          when v_error like '%no location_bonus_versions row effective%'  then 'no_location_version'
          when v_error like '%has no row for tier%'                       then 'no_location_row'
          when v_error like '%no language_bonus_versions row effective%'  then 'no_language_version'
          when v_error like '%has no row for language group%'             then 'no_language_row'
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

revoke all on function app.calculate_org_session_pay(uuid) from public;
grant execute on function app.calculate_org_session_pay(uuid) to authenticated, service_role;

create or replace function public.calculate_org_session_pay(p_organization_id uuid)
returns table (
  session_id uuid,
  trainer_id uuid,
  slot text,
  amount numeric,
  reason_code text,
  error_text text
)
language sql
security invoker
set search_path to ''
as $$
  select * from app.calculate_org_session_pay(p_organization_id);
$$;

revoke all on function public.calculate_org_session_pay(uuid) from public;
grant execute on function public.calculate_org_session_pay(uuid) to authenticated;
