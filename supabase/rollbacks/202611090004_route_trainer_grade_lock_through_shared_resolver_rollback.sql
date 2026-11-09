-- Rollback for 202611090004_route_trainer_grade_lock_through_shared_resolver.sql
--
-- Restores app.resolve_grid_version to its pre-202611090004 form (the
-- plain 202610260001 body, no corrects_version_id exclusion on any
-- branch) and re-creates app.resolve_trainer_grade_version
-- (202611090003's original, since-dropped standalone function), so that
-- rolling this back alone returns the database to exactly 202611090003's
-- own (mistaken) end state. Rolling back 202611090003 itself afterward
-- removes the mechanism entirely, per that migration's own rollback.

create or replace function app.resolve_grid_version(
  p_organization_id uuid,
  p_grid text,
  p_as_of date
)
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  v_version_id uuid;
begin
  case p_grid
    when 'trainer_grade' then
      select id into v_version_id from public.trainer_grade_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'location_bonus' then
      select id into v_version_id from public.location_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'language_bonus' then
      select id into v_version_id from public.language_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'duration_multiplier' then
      select id into v_version_id from public.duration_multiplier_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'contract_type_uplift' then
      select id into v_version_id from public.contract_type_uplift_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    else
      raise exception 'app.resolve_grid_version: unknown grid %', p_grid;
  end case;

  return v_version_id;
end;
$$;

create or replace function app.resolve_trainer_grade_version(p_organization_id uuid, p_as_of date)
returns uuid
language sql
stable
set search_path to ''
as $$
  select id
  from public.trainer_grade_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
    and id not in (
      select corrects_version_id from public.trainer_grade_versions where corrects_version_id is not null
    )
  order by effective_date desc
  limit 1;
$$;

revoke all on function app.resolve_trainer_grade_version(uuid, date) from public;
grant execute on function app.resolve_trainer_grade_version(uuid, date) to authenticated, service_role;

create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_rate numeric;
begin
  v_version_id := app.resolve_trainer_grade_version(p_organization_id, p_as_of);

  if v_version_id is null then
    raise exception 'app.resolve_trainer_grade_rate: no trainer_grade_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate
  from public.trainer_grade_rates
  where version_id = v_version_id
    and grade_level = p_grade_level;

  if v_rate is null then
    raise exception 'app.resolve_trainer_grade_rate: version % has no row for grade level % -- incomplete version', v_version_id, p_grade_level;
  end if;

  return v_rate;
end;
$$;

create or replace function app.trainer_grade_rate_is_locked(p_version_id uuid, p_grade_level integer)
returns boolean
language sql
stable
set search_path to ''
as $$
  select exists (
    select 1
    from public.trainer_grade_versions v
    join public.sessions s on s.organization_id = v.organization_id
    cross join lateral (
      values
        (s.trainer_principal_id, s.trainer_principal_confirmed_at),
        (s.trainer_secundar_id, s.trainer_secundar_confirmed_at)
    ) as slot(trainer_id, confirmed_at)
    where v.id = p_version_id
      and slot.trainer_id is not null
      and slot.confirmed_at is not null
      and (
        select a.grade_level
        from public.trainer_grade_assignments a
        where a.trainer_id = slot.trainer_id
          and a.effective_from <= s.session_date
        order by a.effective_from desc
        limit 1
      ) = p_grade_level
      and app.resolve_trainer_grade_version(v.organization_id, s.session_date) = p_version_id
  );
$$;
