-- Rollback for 202609240002. Removes exactly the ten rows this
-- migration inserted -- scoped by organization + effective_from, so it
-- can't touch a row from a different date (e.g. a later grade change)
-- even though none exist yet.

do $$
declare
  v_org uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'rollback 202609240002: no organization with slug=wow-lab';
  end if;

  delete from public.trainer_grade_assignments
    where organization_id = v_org and effective_from = '2026-09-01';
end $$;
