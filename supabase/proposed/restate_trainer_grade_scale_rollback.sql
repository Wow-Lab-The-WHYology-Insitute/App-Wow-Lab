-- Rollback for the PROPOSED 202610200001. Restores 111-150 at 2026-09-01
-- exactly as 202609240001 left it, including that migration's own note.
--
-- Rolling this back restores a grid whose figures the payment record
-- contradicts for September and October 2026 (Lorina paid 107 on 30.09,
-- Alexandra's 228,00 = 114 x 2.00 on 12.10). Only do it to undo a mistaken
-- application.

do $$
declare
  v_org uuid;
  v_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_version from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2026-09-01';
  if v_version is null then
    raise exception 'rollback: no trainer_grade_versions row effective 2026-09-01';
  end if;

  update public.trainer_grade_rates r
  set rate = v.rate
  from (values (1, 111), (2, 119), (3, 127), (4, 134), (5, 142), (6, 150)) as v(grade_level, rate)
  where r.version_id = v_version and r.grade_level = v.grade_level;

  update public.trainer_grade_versions
  set note = 'Confirmed by Anca 2026-09-24: PFA-inclusive rates -- "in contractul cu trainerii PFA sau SRL vom avea direct 111 lei/ora tarif de baza junior." The 11.1% PFA/SRL uplift is already inside these six numbers; contract_type_uplift is not applied on top (see that grid''s own empty-on-purpose note below).'
  where id = v_version;
end $$;
