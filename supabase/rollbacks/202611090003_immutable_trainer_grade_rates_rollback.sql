-- Rollback for 202611090003_immutable_trainer_grade_rates.sql
--
-- Refuses if any correction chain has actually been used (a non-null
-- corrects_version_id exists anywhere) -- rolling back the mechanism out
-- from under a real correction would leave that correction's own version
-- row orphaned from the resolution logic that was built to find it.

do $$
begin
  if exists (select 1 from public.trainer_grade_versions where corrects_version_id is not null) then
    raise exception 'immutable_trainer_grade_rates rollback refused: a corrects_version_id chain already exists -- resolve or remove it by hand before rolling this back';
  end if;
end $$;

drop trigger if exists trainer_grade_versions_block_locked_update on public.trainer_grade_versions;
drop trigger if exists trainer_grade_rates_block_locked_update on public.trainer_grade_rates;

drop function if exists app.trainer_grade_versions_block_locked_update();
drop function if exists app.trainer_grade_rates_block_locked_update();
drop function if exists app.trainer_grade_rate_is_locked(uuid, integer);

-- Restores resolve_trainer_grade_rate to its pre-202611090003 body (its
-- own version-selection, not delegated) and drops the extracted resolver.
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
  select id into v_version_id
  from public.trainer_grade_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

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

drop function if exists app.resolve_trainer_grade_version(uuid, date);

drop index if exists public.trainer_grade_versions_org_date_head_unique;

alter table public.trainer_grade_versions
  add constraint trainer_grade_versions_org_date_unique unique (organization_id, effective_date);

drop index if exists public.trainer_grade_versions_corrects_idx;

alter table public.trainer_grade_versions
  drop constraint if exists trainer_grade_versions_corrects_unique;

alter table public.trainer_grade_versions
  drop constraint if exists trainer_grade_versions_no_self_correct_check;

alter table public.trainer_grade_versions
  drop column if exists corrects_version_id;
