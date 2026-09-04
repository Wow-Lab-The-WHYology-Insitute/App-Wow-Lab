-- verify_allow_org_membership_without_role.sql
-- Dry-run verification for
-- supabase/migrations/202609040003_allow_org_membership_without_role.sql.
--
-- Run with: supabase db query --linked --file scripts/verify_allow_org_membership_without_role.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

alter table public.user_org_roles
  alter column role_id drop not null;

create unique index user_org_roles_one_membership_per_org_user
  on public.user_org_roles (organization_id, user_id)
  where role_id is null;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_user uuid := (select id from public.users where email = 'ralucamargean@yahoo.com');
  v_trainer_role uuid := (select id from public.roles where key = 'trainer');
  v_row_id uuid;
  v_caught boolean;
  v_belongs boolean;
  v_cap_count int;
begin
  -- ---- 1. a null-role row can be inserted ----
  insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
  values (v_org, v_user, null, v_user)
  returning id into v_row_id;

  if v_row_id is not null then
    report := report || E'\n1. PASS - null-role row inserted';
  else
    report := report || E'\n1. FAIL - insert did not return an id';
  end if;

  -- ---- 2. a second null-role row for the same (org, user) is rejected ----
  begin
    insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
    values (v_org, v_user, null, v_user);
    report := report || E'\n2. FAIL - a second null-role row for the same person/org was allowed';
  exception
    when unique_violation then
      report := report || E'\n2. PASS - a second null-role row for the same person/org raised unique_violation (the partial index)';
  end;

  -- ---- 3. app.belongs_to_org-equivalent: the row makes her "a member" ----
  select exists (
    select 1 from public.user_org_roles
    where user_id = v_user and organization_id = v_org
  ) into v_belongs;

  if v_belongs then
    report := report || E'\n3. PASS - app.belongs_to_org-equivalent query finds her (row exists, role_id null)';
  else
    report := report || E'\n3. FAIL - membership row not found';
  end if;

  -- ---- 4. app.has_capability-equivalent join: null role_id contributes zero capabilities ----
  select count(*) into v_cap_count
  from public.user_org_roles uor
  join public.role_capabilities rc on rc.role_id = uor.role_id
  where uor.user_id = v_user and uor.organization_id = v_org;

  if v_cap_count = 0 then
    report := report || E'\n4. PASS - the null-role row joins to zero role_capabilities rows (grants nothing)';
  else
    report := report || format(E'\n4. FAIL - expected 0 capability rows, got %s', v_cap_count);
  end if;

  -- ---- 5. a real role can still be added for the same person in the same org (no interference from the partial index) ----
  begin
    insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
    values (v_org, v_user, v_trainer_role, v_user);
    report := report || E'\n5. PASS - a real role insert for the same person/org still succeeds alongside the null-role row';
  exception
    when others then
      get stacked diagnostics v_caught = returned_sqlstate;
      report := report || format(E'\n5. FAIL - real role insert failed unexpectedly: %s', sqlerrm);
  end;

  -- ---- 6. the original 3-column unique constraint still blocks an exact duplicate real-role row ----
  begin
    insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
    values (v_org, v_user, v_trainer_role, v_user);
    report := report || E'\n6. FAIL - an exact duplicate (org, user, role) row was allowed';
  exception
    when unique_violation then
      report := report || E'\n6. PASS - exact duplicate (org, user, role) still raises unique_violation (original constraint intact)';
  end;

  raise exception E'VERIFICATION REPORT for 202609040003_allow_org_membership_without_role.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
