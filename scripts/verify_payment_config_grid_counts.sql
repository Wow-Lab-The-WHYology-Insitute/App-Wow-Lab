select o.name as org_name,
  (select count(*) from public.trainer_grade_versions v where v.organization_id = o.id) as trainer_grades,
  (select count(*) from public.location_bonus_versions v where v.organization_id = o.id) as location_bonuses,
  (select count(*) from public.language_bonus_versions v where v.organization_id = o.id) as language_bonuses,
  (select count(*) from public.duration_multiplier_versions v where v.organization_id = o.id) as duration_multipliers,
  (select count(*) from public.contract_type_uplift_versions v where v.organization_id = o.id) as contract_type_uplifts,
  (select count(*) from public.lesson_plan_rate_versions v where v.organization_id = o.id) as lesson_plan_rate
from public.organizations o
where o.name in ('WOW LAB Test Org B', 'wow-lab', 'WOW LAB');
