-- Rollback for 202610160003. Restores Anka Orban's Trainer and Senior
-- Trainer roles in wow-lab.
--
-- What this gives back, measured in the migration's own header: mywork.*
-- (so /my-work reappears and she can confirm her own workshop delivery),
-- finance.own.read and materials.custody (both inert -- no policy and no
-- code reads either today). It gives back no visibility she does not
-- already have through her ten other roles.
--
-- Anca confirmed 2026-10-16 that she does not deliver workshops, so this
-- is here for reversibility, not as a path anyone is expected to take.

do $$
declare
  v_org uuid;
  v_user uuid;
  v_role text;
  v_roles text[] := array['Trainer', 'Senior Trainer'];
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_user from public.users where email = 'anka@asismart.ro';
  if v_org is null or v_user is null then
    raise exception 'rollback: missing org wow-lab or user anka@asismart.ro';
  end if;

  foreach v_role in array v_roles loop
    insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
    select v_org, v_user, r.id, null from public.roles r where r.name = v_role
    on conflict (organization_id, user_id, role_id) do nothing;
  end loop;
end $$;
