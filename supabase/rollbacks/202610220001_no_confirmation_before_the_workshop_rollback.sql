-- Rollback for 202610220001_no_confirmation_before_the_workshop.sql.
--
-- Restores both RPCs to their pre-guard bodies: 202609220003's
-- rpc_confirm_session_attendance (item 91's column narrowing, which this
-- rollback KEEPS -- only the date guard is removed) and 202609150002's
-- rpc_correct_session_confirmation.
--
-- Applying this re-opens the ability to assert a future delivery with one
-- tap, on a screen that currently opens on June 2027. It exists so the pair
-- is reversible, not because reversing it is ever right.

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
  from public.sessions where id = p_session_id;

  if v_org is null then return 'not_found'; end if;

  v_is_principal := (v_principal = app.current_user_id());
  v_is_secundar := (v_secundar = app.current_user_id());
  if not v_is_principal and not v_is_secundar then return 'not_assigned'; end if;
  if not app.has_capability('mywork.*', v_org) then return 'not_assigned'; end if;

  select exists (
    select 1 from public.payroll_periods pp
    where pp.organization_id = v_org
      and pp.period = date_trunc('month', v_session_date::timestamptz)::date
      and pp.closed_at is not null
  ) into v_month_closed;

  if v_month_closed then return 'month_closed'; end if;

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
begin
  select organization_id into v_org from public.sessions where id = p_session_id;
  if v_org is null then return 'not_found'; end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('finance.operations.*', v_org)
  ) then
    return 'not_permitted';
  end if;

  update public.sessions
    set trainer_principal_confirmed_at = case when p_principal_confirmed then now() else null end,
        trainer_secundar_confirmed_at = case when p_secundar_confirmed then now() else null end
    where id = p_session_id;

  return 'ok';
end;
$$;
