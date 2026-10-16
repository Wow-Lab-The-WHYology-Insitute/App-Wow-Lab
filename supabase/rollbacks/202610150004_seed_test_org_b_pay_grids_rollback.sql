-- Rollback for 202610150004. Deletes Test Org B's four grid versions and
-- their rates, returning the org to having no pay grid at all.
--
-- Scoped by organization_id AND by the 2020-01-01 effective_date this
-- migration used, so a grid version someone adds to Test Org B later --
-- with a real effective date, through /payment-config -- survives this.
-- Rates go before versions: version_id is a foreign key.
--
-- groups.language_group is NOT reverted, deliberately. The migration set
-- it to 'ro_en' on a group that had nothing, and "nothing" is not a
-- value worth restoring -- a null language_group makes every session in
-- that group unpriceable, which is the hole the fill closed. Reverting it
-- would re-break three sessions to undo a feature that no longer reads
-- them. row_history has the before-image if the value ever needs
-- recovering.

delete from public.trainer_grade_rates
where version_id in (
  select id from public.trainer_grade_versions
  where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
    and effective_date = '2020-01-01'
);
delete from public.trainer_grade_versions
where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
  and effective_date = '2020-01-01';

delete from public.duration_multiplier_rates
where version_id in (
  select id from public.duration_multiplier_versions
  where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
    and effective_date = '2020-01-01'
);
delete from public.duration_multiplier_versions
where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
  and effective_date = '2020-01-01';

delete from public.location_bonus_rates
where version_id in (
  select id from public.location_bonus_versions
  where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
    and effective_date = '2020-01-01'
);
delete from public.location_bonus_versions
where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
  and effective_date = '2020-01-01';

delete from public.language_bonus_rates
where version_id in (
  select id from public.language_bonus_versions
  where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
    and effective_date = '2020-01-01'
);
delete from public.language_bonus_versions
where organization_id = (select id from public.organizations where slug = 'wow-lab-test-b')
  and effective_date = '2020-01-01';
