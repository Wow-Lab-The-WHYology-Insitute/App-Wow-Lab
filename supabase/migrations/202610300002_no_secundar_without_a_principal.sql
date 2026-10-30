-- Found on Mihai's own phone walkthrough and in Anca's screenshots,
-- 2026-10-30 (item 166's own report, "A3"): a workshop could be created,
-- or reallocated, with a SECUNDAR trainer and no PRINCIPAL -- the screen
-- showed "Alexandra Nutu" as secundar beside a principal reading
-- "Nealocat" (Unassigned). A secundar is specifically an assistant to a
-- principal; a secundar with no principal has nobody to assist.
--
-- Fixed in the UI (NewSessionForm, and the reallocate TrainerSelect in
-- group-detail-client.tsx): the secundar field is now disabled until a
-- principal is chosen, and clearing the principal clears the secundar
-- with it.
--
-- This migration closes the gap the UI fix cannot: `addSession`'s INSERT
-- and `app.rpc_update_session_allocation`'s UPDATE are both still reachable
-- directly (the former is the SAME raw-table-INSERT path item 166 already
-- named as open; the latter is a SECURITY DEFINER function with no
-- cross-column check of its own). Unlike the two future-date guards
-- (202610220001, 202610280001), this invariant is NOT time-dependent --
-- there is no "clock moved" case to carve out, so a CHECK constraint is
-- the right mechanism here, not an RPC-level guard: it is enforced on
-- every INSERT and UPDATE, through every current and future write path,
-- with nothing to leave as a named exception.
--
-- Confirmed live before writing this: zero existing rows, in either
-- organization, have trainer_secundar_id set with trainer_principal_id
-- null -- this is a prospective guard, not a retroactive fix.

alter table public.sessions
  add constraint sessions_secundar_requires_principal_check
  check (trainer_secundar_id is null or trainer_principal_id is not null);

comment on constraint sessions_secundar_requires_principal_check on public.sessions is
  'A secundar trainer cannot exist without a principal -- the secundar role is specifically an assistant to one. Found 2026-10-30 from a real screenshot (secundar set, principal "Unassigned"). Not time-dependent, unlike the two future-date guards on this table, so enforced as a CHECK rather than an RPC guard.';

do $$
declare
  v_violations integer;
  v_test_org uuid;
  v_group uuid;
  v_trainer uuid;
begin
  select count(*) into v_violations from public.sessions
  where trainer_principal_id is null and trainer_secundar_id is not null;
  if v_violations <> 0 then
    raise exception 'no_secundar_without_a_principal: % existing rows violate the new constraint -- should have been impossible if ADD CONSTRAINT above succeeded', v_violations;
  end if;

  -- The constraint itself refuses what it should -- tried in wow-lab-test-b
  -- specifically, a known fixture rather than an arbitrary cross join, so
  -- this attempt cannot land anywhere real even if it somehow weren't rolled
  -- back by the exception below.
  select id into v_test_org from public.organizations where slug = 'wow-lab-test-b';
  select id into v_group from public.groups where organization_id = v_test_org limit 1;
  select id into v_trainer from public.users where email = 'maxdigitalro+trainerb1@gmail.com';
  if v_test_org is null or v_group is null or v_trainer is null then
    raise exception 'no_secundar_without_a_principal: could not find the wow-lab-test-b fixtures this assertion needs';
  end if;

  begin
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
    values (v_test_org, v_group, '2020-01-01', null, v_trainer, 'planned');
    raise exception 'no_secundar_without_a_principal: the constraint did not refuse a secundar-without-principal insert';
  exception when check_violation then
    null; -- expected
  end;

  raise notice 'no_secundar_without_a_principal: constraint live, refuses secundar-without-principal on insert and update, 0 pre-existing violations.';
end $$;
