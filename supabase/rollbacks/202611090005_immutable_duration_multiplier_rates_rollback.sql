-- Rollback for 202611090005_immutable_duration_multiplier_rates.sql
--
-- Refuses if any correction chain has actually been used (a non-null
-- corrects_version_id exists anywhere) -- same guard as
-- 202611090003_immutable_trainer_grade_rates_rollback.sql, same reason.

do $$
begin
  if exists (select 1 from public.duration_multiplier_versions where corrects_version_id is not null) then
    raise exception 'immutable_duration_multiplier_rates rollback refused: a corrects_version_id chain already exists -- resolve or remove it by hand before rolling this back';
  end if;
end $$;

drop trigger if exists duration_multiplier_versions_block_locked_update on public.duration_multiplier_versions;
drop trigger if exists duration_multiplier_rates_block_locked_update on public.duration_multiplier_rates;

drop function if exists app.duration_multiplier_versions_block_locked_update();
drop function if exists app.duration_multiplier_rates_block_locked_update();
drop function if exists app.duration_multiplier_rate_is_locked(uuid, integer, text);

-- Restores app.resolve_grid_version's duration_multiplier branch to its
-- pre-202611090005 form (no corrects_version_id exclusion). This migration
-- never created a standalone resolver function, so there is nothing else
-- to drop here -- only this branch to revert.
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
        and id not in (
          select corrects_version_id from public.trainer_grade_versions
          where corrects_version_id is not null
        )
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

drop index if exists public.duration_multiplier_versions_org_date_head_unique;

alter table public.duration_multiplier_versions
  add constraint duration_multiplier_versions_org_date_unique unique (organization_id, effective_date);

drop index if exists public.duration_multiplier_versions_corrects_idx;

alter table public.duration_multiplier_versions
  drop constraint if exists duration_multiplier_versions_corrects_unique;

alter table public.duration_multiplier_versions
  drop constraint if exists duration_multiplier_versions_no_self_correct_check;

alter table public.duration_multiplier_versions
  drop column if exists corrects_version_id;
