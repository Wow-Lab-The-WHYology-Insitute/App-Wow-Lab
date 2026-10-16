-- Rollback for 202610160002. Restores Organization Owner to
-- test+ui-owner@wowlab.dev and Finance Operations to
-- test+ui-finance-ops@wowlab.dev, and drops the role-less membership row
-- the migration left in their place.
--
-- Restoring these re-opens the exposure the migration closed: both
-- accounts can sign in, and with these roles back they can open /payroll
-- and read every trainer's pay in the production org. Only run this if
-- that is the intent -- the six scripts/verify_*.sql re-pointed in the
-- same commit do NOT need it, since test+owner-a / test+finance-ops-a
-- hold the identical roles and are the right accounts for SQL
-- impersonation anyway.

do $$
declare
  v_org uuid;
  v_user uuid;
  v_role uuid;
  v_pairs text[][] := array[
    array['test+ui-owner@wowlab.dev', 'Organization Owner'],
    array['test+ui-finance-ops@wowlab.dev', 'Finance Operations']
  ];
  v_i integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';

  for v_i in 1 .. array_length(v_pairs, 1) loop
    select id into v_user from public.users where email = v_pairs[v_i][1];
    select id into v_role from public.roles where name = v_pairs[v_i][2];
    if v_user is null or v_role is null then
      raise exception 'rollback: missing user % or role %', v_pairs[v_i][1], v_pairs[v_i][2];
    end if;

    insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
    values (v_org, v_user, v_role, null)
    on conflict (organization_id, user_id, role_id) do nothing;

    -- The role-less placeholder is only correct while they have no role.
    delete from public.user_org_roles
    where organization_id = v_org and user_id = v_user and role_id is null;
  end loop;
end $$;
