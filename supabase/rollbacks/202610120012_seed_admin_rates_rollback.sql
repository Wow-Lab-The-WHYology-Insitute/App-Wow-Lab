-- Rollback for 202610120012 -- removes the admin rate version and its rates.
--
-- admin_rates cascades from the version row, so deleting the version is
-- enough; the explicit delete is kept so the intent reads in the file rather
-- than depending on a cascade.
--
-- Reproducible from Anca's 2026-08-07/2026-08-10 figures as recorded in item
-- 111, so this loses no information that is not written down elsewhere.

delete from public.admin_rates
 where organization_id = (select id from public.organizations where slug = 'wow-lab');

delete from public.admin_rate_versions
 where organization_id = (select id from public.organizations where slug = 'wow-lab');
