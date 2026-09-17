-- verify_clients_mywork_visibility.sql
-- Dry-run of 202609170001 against WOW LAB Test Org B: applies the exact
-- policy DDL that migration contains, then asserts, all inside one
-- transaction that always rolls back -- run BEFORE the real `db push`,
-- same "prove it before it's live" shape as scripts/verify_trainer_grade_
-- assignments_source.sql and scripts/verify_users_trainer_name_visibility.sql.
-- Run with: supabase db query --linked --file scripts/verify_clients_mywork_visibility.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

DO $$
begin
  drop policy if exists "authenticated select clients" on public.clients;
  create policy "authenticated select clients" on public.clients
    for select
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or (
        app.has_capability('clients.read', organization_id)
        and not app.has_capability('finance.operations.*', organization_id)
        and not app.has_capability('finance.reporting.*', organization_id)
      )
      or (
        app.has_capability('finance.operations.*', organization_id)
        and client_type in ('private_school', 'parent_b2c')
      )
      or (
        app.has_capability('finance.reporting.*', organization_id)
        and client_type not in ('private_school', 'parent_b2c')
      )
      or (
        app.has_capability('mywork.*', organization_id)
        and exists (
          select 1
          from public.groups g
          where g.client_id = clients.id
            and exists (
              select 1
              from public.sessions s
              where s.group_id = g.id
                and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
            )
        )
      )
    );
end;
$$;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_principal uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  v_secundar uuid := (select id from public.users where email = 'maxdigitalro+trainerb2@gmail.com');
  v_other_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb3@gmail.com'); -- not on this session
  v_client uuid;
  v_group uuid;
  v_session uuid;
  v_unrelated_client uuid;
  v_visible boolean;
begin
  if v_principal is null or v_secundar is null or v_other_trainer is null then
    raise exception 'Fixture lookup failed.';
  end if;

  insert into public.clients (organization_id, name, client_type) values (v_org, 'DRYRUN verify client (clients mywork visibility)', 'corporate') returning id into v_client;
  insert into public.clients (organization_id, name, client_type) values (v_org, 'DRYRUN verify unrelated client (clients mywork visibility)', 'corporate') returning id into v_unrelated_client;
  insert into public.groups (organization_id, client_id, module, delivery_format) values (v_org, v_client, 'gaga', 'recurring') returning id into v_group;
  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
  values (v_org, v_group, current_date, v_principal, v_secundar, 'planned') returning id into v_session;

  -- ---- 1. The principal can see the client of a session they're allocated to ----
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.clients where id = v_client) into v_visible;
  if v_visible then
    report := report || E'\n1. PASS - the principal (Test Trainer B1) can see the client of a session they are allocated to';
  else
    report := report || E'\n1. FAIL - the principal cannot see the client of their own session';
  end if;

  -- ---- 2. The secundar can see the same client ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.clients where id = v_client) into v_visible;
  if v_visible then
    report := report || E'\n2. PASS - the secundar (Test Trainer B2) can see the same client';
  else
    report := report || E'\n2. FAIL - the secundar cannot see the client of their own session';
  end if;

  -- ---- 3. An unrelated trainer (no session on this group) cannot see this client ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_other_trainer::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.clients where id = v_client) into v_visible;
  if not v_visible then
    report := report || E'\n3. PASS - an unrelated trainer (Test Trainer B3, no session on this group) cannot see the client -- scoped, not org-wide';
  else
    report := report || E'\n3. FAIL - an unrelated trainer can see the client -- branch is broader than intended';
  end if;

  -- ---- 4. The principal cannot see a second, unrelated client through this branch ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.clients where id = v_unrelated_client) into v_visible;
  if not v_visible then
    report := report || E'\n4. PASS - the principal cannot see an unrelated client with no group/session tying it to them';
  else
    report := report || E'\n4. FAIL - the principal can see an unrelated client -- branch leaks beyond the viewer''s own sessions';
  end if;

  raise exception '%', report;
end;
$verify$;

rollback;
