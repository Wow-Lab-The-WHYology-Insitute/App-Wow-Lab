-- Rollback for 202609240001. Removes exactly the five versions (and
-- their rate rows) this migration inserted -- scoped by organization +
-- effective_date so it can't touch a version from a different date or
-- org. contract_type_uplift had no rows added, so there is nothing to
-- remove there; only the COMMENT ON FUNCTION is reverted.
--
-- Does NOT touch the pre-existing 2024-01-01/120 lesson_plan_rates row
-- -- that one predates this migration and this migration never modified
-- it.

do $$
declare
  v_org uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'rollback 202609240001: no organization with slug=wow-lab';
  end if;

  delete from public.trainer_grade_rates
    where version_id in (select id from public.trainer_grade_versions where organization_id = v_org and effective_date = '2026-09-01');
  delete from public.trainer_grade_versions
    where organization_id = v_org and effective_date = '2026-09-01';

  delete from public.location_bonus_rates
    where version_id in (select id from public.location_bonus_versions where organization_id = v_org and effective_date = '2026-09-01');
  delete from public.location_bonus_versions
    where organization_id = v_org and effective_date = '2026-09-01';

  delete from public.language_bonus_rates
    where version_id in (select id from public.language_bonus_versions where organization_id = v_org and effective_date = '2026-09-01');
  delete from public.language_bonus_versions
    where organization_id = v_org and effective_date = '2026-09-01';

  delete from public.lesson_plan_rates
    where version_id in (select id from public.lesson_plan_rate_versions where organization_id = v_org and effective_date = '2026-09-01');
  delete from public.lesson_plan_rate_versions
    where organization_id = v_org and effective_date = '2026-09-01';

  delete from public.duration_multiplier_rates
    where version_id in (select id from public.duration_multiplier_versions where organization_id = v_org and effective_date = '2026-09-01');
  delete from public.duration_multiplier_versions
    where organization_id = v_org and effective_date = '2026-09-01';
end $$;

comment on function app.resolve_contract_type_uplift(uuid, text, date) is null;
