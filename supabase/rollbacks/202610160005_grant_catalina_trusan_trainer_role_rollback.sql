-- Rollback for 202610160005. Removes Cătălina Trușan's Trainer role.
--
-- What this takes away, from the migration's own measurements: mywork.*
-- (so /my-work disappears and she can no longer confirm her own workshop
-- delivery -- the reason the grant exists), plus community.read,
-- finance.own.read and materials.custody, none of which any policy or any
-- line of code reads today. It takes away no visibility: her Operations
-- Manager grants already cover every table the own-slot branches touch.
--
-- She keeps Curriculum Manager, Evaluator and Operations Manager, so this
-- can never empty her membership and needs no role-less placeholder.
--
-- After this she is again absent from the trainer dropdown while
-- delivering four of the six groups, which is the state item 142 exists to
-- stop happening by accident.

delete from public.user_org_roles uor
using public.roles r
where r.id = uor.role_id
  and r.name = 'Trainer'
  and uor.organization_id = (select id from public.organizations where slug = 'wow-lab')
  and uor.user_id = (select id from public.users where email = 'catalina_moale@yahoo.com');
