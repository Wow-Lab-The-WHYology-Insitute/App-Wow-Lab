-- verify_group_notes_trainer_visibility.sql
-- Answers one question with the live policies rather than by reading the
-- render code: when an operations_manager writes `groups.notes`, does the
-- trainer allocated to a session in that group read it back?
--
-- Asked by Anca 2026-10-12 (item 110). Her answer said she sees no Notes
-- field in production; her own screenshot shows it, last row of Group
-- info, reading "—" because every real group's notes is NULL. So the
-- field exists -- the open half is visibility, and that is an RLS
-- question, not a UI one.
--
-- Run in WOW LAB Test Org B, not the real org, for the reason that makes
-- the real org unable to answer it at all: `wow-lab` holds zero sessions,
-- so no trainer is allocated to anything there and the `mywork.*` branch
-- cannot be exercised. Test Org B carries the same role keys
-- (operations_manager, trainer) against the same policies.
--
-- Run with: supabase db query --linked --file scripts/verify_group_notes_trainer_visibility.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
  v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
  v_principal uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  v_secundar uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
  v_other uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com');
  v_client uuid;
  v_group uuid;
  v_updated int;
  v_notes text;
  v_seen boolean;
  c_note constant text := 'DRYRUN note written by the ops manager';
begin
  if v_org is null or v_ops is null or v_principal is null or v_secundar is null or v_other is null then
    raise exception 'Fixture lookup failed.';
  end if;

  insert into public.clients (organization_id, name, client_type)
  values (v_org, 'DRYRUN verify client (group notes trainer visibility)', 'corporate')
  returning id into v_client;

  insert into public.groups (organization_id, client_id, module, delivery_format)
  values (v_org, v_client, 'gaga', 'parteneriate_companii')
  returning id into v_group;

  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, current_date, v_principal, v_secundar, 'planned');

  -- ---- 1. The operations_manager can write notes at all ----
  -- Cătălina's role. updateGroup gates this field on groups.create; the
  -- UPDATE policy admits the same capability. Writing it as her, not as
  -- the connecting role, is the only way to prove both agree.
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
  update public.groups set notes = c_note where id = v_group;
  get diagnostics v_updated = row_count;
  if v_updated = 1 then
    report := report || E'\n1. PASS - operations_manager (Catalina''s role) wrote groups.notes: 1 row updated';
  else
    report := report || format(E'\n1. FAIL - operations_manager wrote %s rows, expected 1 -- the note never lands', v_updated);
  end if;

  -- ---- 2. The allocated principal reads the note back ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select notes into v_notes from public.groups where id = v_group;
  if v_notes = c_note then
    report := report || E'\n2. PASS - the allocated trainer_principal reads the note back verbatim';
  else
    report := report || format(E'\n2. FAIL - the allocated trainer_principal read %L, expected %L', v_notes, c_note);
  end if;

  -- ---- 3. The allocated secundar reads it too ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  select notes into v_notes from public.groups where id = v_group;
  if v_notes = c_note then
    report := report || E'\n3. PASS - the allocated trainer_secundar reads the note back verbatim';
  else
    report := report || format(E'\n3. FAIL - the allocated trainer_secundar read %L, expected %L', v_notes, c_note);
  end if;

  -- ---- 4. An unallocated trainer sees no row at all ----
  -- The boundary that makes the answer to 2/3 safe rather than a leak:
  -- groups' mywork.* branch is scoped to the viewer's own sessions.
  perform set_config('request.jwt.claims', json_build_object('sub', v_other::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.groups where id = v_group) into v_seen;
  if not v_seen then
    report := report || E'\n4. PASS - a trainer with no session in this group sees no row, so no note';
  else
    report := report || E'\n4. FAIL - an unallocated trainer can see this group -- the note leaks past the allocation';
  end if;

  -- ---- 5. The trainer cannot write the note back ----
  -- Stated because "can see it" invites the next question. groups' UPDATE
  -- policy admits no mywork.* branch.
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  update public.groups set notes = 'DRYRUN trainer overwrite attempt' where id = v_group;
  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    report := report || E'\n5. PASS - the allocated trainer cannot write notes: 0 rows updated (read-only to them)';
  else
    report := report || format(E'\n5. FAIL - the allocated trainer updated %s rows -- notes is writable by trainers', v_updated);
  end if;

  raise exception '%', report;
end;
$verify$;

rollback;
