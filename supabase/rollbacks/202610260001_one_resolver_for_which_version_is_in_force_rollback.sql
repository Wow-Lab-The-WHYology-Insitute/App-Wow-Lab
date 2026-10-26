-- Rollback for 202610260001_one_resolver_for_which_version_is_in_force.sql.
--
-- Restores the five resolvers' inlined version selection and drops the shared
-- function and the screen's wrapper. Behaviour is identical in every state
-- EXCEPT the one this migration exists for: with the inlined copies back,
-- /payment-config is free to drift from the engine again the moment a version
-- is dated ahead.
--
-- Drop the wrapper first: current_grid_versions depends on
-- app.resolve_grid_version.

drop function if exists public.current_grid_versions(uuid, date);

create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_rate numeric;
begin
  select id into v_version_id from public.trainer_grade_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc limit 1;
  if v_version_id is null then
    raise exception 'app.resolve_trainer_grade_rate: no trainer_grade_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;
  select rate into v_rate from public.trainer_grade_rates
  where version_id = v_version_id and grade_level = p_grade_level;
  if v_rate is null then
    raise exception 'app.resolve_trainer_grade_rate: version % has no row for grade level % -- incomplete version', v_version_id, p_grade_level;
  end if;
  return v_rate;
end; $$;

create or replace function app.resolve_location_bonus(p_organization_id uuid, p_location_tier text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_bonus numeric;
begin
  select id into v_version_id from public.location_bonus_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc limit 1;
  if v_version_id is null then
    raise exception 'app.resolve_location_bonus: no location_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;
  select bonus_percent into v_bonus from public.location_bonus_rates
  where version_id = v_version_id and location_tier = p_location_tier;
  if v_bonus is null then
    raise exception 'app.resolve_location_bonus: version % has no row for tier % -- incomplete version', v_version_id, p_location_tier;
  end if;
  return v_bonus;
end; $$;

create or replace function app.resolve_language_bonus(p_organization_id uuid, p_language_group text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_bonus numeric;
begin
  select id into v_version_id from public.language_bonus_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc limit 1;
  if v_version_id is null then
    raise exception 'app.resolve_language_bonus: no language_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;
  select bonus_percent into v_bonus from public.language_bonus_rates
  where version_id = v_version_id and language_group = p_language_group;
  if v_bonus is null then
    raise exception 'app.resolve_language_bonus: version % has no row for language group % -- incomplete version', v_version_id, p_language_group;
  end if;
  return v_bonus;
end; $$;

create or replace function app.resolve_contract_type_uplift(p_organization_id uuid, p_contract_type text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_uplift numeric;
begin
  select id into v_version_id from public.contract_type_uplift_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc limit 1;
  if v_version_id is null then
    raise exception 'app.resolve_contract_type_uplift: no contract_type_uplift_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;
  select uplift_percent into v_uplift from public.contract_type_uplift_rates
  where version_id = v_version_id and contract_type = p_contract_type;
  if v_uplift is null then
    raise exception 'app.resolve_contract_type_uplift: version % has no row for contract type % -- incomplete version', v_version_id, p_contract_type;
  end if;
  return v_uplift;
end; $$;

create or replace function app.resolve_duration_multiplier(
  p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date
)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_context text; v_version_id uuid; v_multiplier numeric; v_top_band integer;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard' end;
  select id into v_version_id from public.duration_multiplier_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc limit 1;
  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;
  select r.multiplier into v_multiplier from public.duration_multiplier_rates r
  where r.version_id = v_version_id and r.delivery_context = v_context
    and r.duration_minutes >= p_duration_minutes
  order by r.duration_minutes asc limit 1;
  if v_multiplier is not null then return v_multiplier; end if;
  select max(r.duration_minutes) into v_top_band from public.duration_multiplier_rates r
  where r.version_id = v_version_id and r.delivery_context = v_context;
  if v_top_band is null then
    raise exception 'app.resolve_duration_multiplier: version % has no bands for context % -- incomplete version', v_version_id, v_context;
  end if;
  raise exception 'app.resolve_duration_multiplier: % minutes is longer than the longest band (% minutes) in version % / context %', p_duration_minutes, v_top_band, v_version_id, v_context;
end; $$;

drop function if exists app.resolve_grid_version(uuid, text, date);
