-- verify_client_contacts_trainer_facing_scoping.sql
-- Dry-run of 202609210002 against WOW LAB Test Org B: applies the exact
-- policy DDL that migration contains, then asserts, all inside one
-- transaction that always rolls back -- run BEFORE the real `db push`,
-- same shape as scripts/verify_clients_mywork_visibility.sql.
-- Run with: supabase db query --linked --file scripts/verify_client_contacts_trainer_facing_scoping.sql

begin;

DO $$
begin
  drop policy "authenticated select client_contacts" on public.client_contacts;

  create policy "authenticated select client_contacts" on public.client_contacts
    for select
    to authenticated
    using (
      (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          app.has_capability('clients.read', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
        )
        or (
          app.has_capability('finance.operations.*', organization_id)
          and exists (
            select 1 from public.clients cl
            where cl.id = client_contacts.client_id
              and cl.client_type = any (array['private_school', 'parent_b2c'])
          )
        )
        or (
          app.has_capability('finance.reporting.*', organization_id)
          and exists (
            select 1 from public.clients cl
            where cl.id = client_contacts.client_id
              and cl.client_type <> all (array['private_school', 'parent_b2c'])
          )
        )
        or (
          app.has_capability('mywork.*', organization_id)
          and contact_purpose = 'trainer_facing'
          and exists (
            select 1
            from public.groups g
            where g.on_site_contact_id = client_contacts.id
              and exists (
                select 1
                from public.sessions s
                where s.group_id = g.id
                  and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
              )
          )
        )
      )
      and (
        not is_billing_contact
        or is_primary
        or app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('finance.operations.*', organization_id)
        or app.has_capability('finance.reporting.*', organization_id)
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
  v_contact_facing uuid;
  v_contact_general uuid;
  v_visible boolean;
begin
  if v_principal is null or v_secundar is null or v_other_trainer is null then
    raise exception 'Fixture lookup failed.';
  end if;

  insert into public.clients (organization_id, name, client_type)
    values (v_org, 'DRYRUN verify client (contact scoping)', 'corporate') returning id into v_client;

  insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
    values (v_org, v_client, 'DRYRUN Trainer-Facing Contact', '0700000000', 'trainer_facing') returning id into v_contact_facing;
  insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
    values (v_org, v_client, 'DRYRUN General Contact', '0700000001', 'general') returning id into v_contact_general;

  insert into public.groups (organization_id, client_id, module, delivery_format, on_site_contact_id)
    values (v_org, v_client, 'gaga', 'party', v_contact_facing) returning id into v_group;

  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status)
    values (v_org, v_group, current_date, v_principal, v_secundar, 'planned') returning id into v_session;

  set local role authenticated;

  -- ---- 1. The principal, allocated, sees the linked trainer_facing contact ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact_facing) into v_visible;
  if v_visible then
    report := report || E'\n1. PASS - the allocated principal sees the linked trainer_facing contact';
  else
    report := report || E'\n1. FAIL - the allocated principal cannot see the linked trainer_facing contact';
  end if;

  -- ---- 2. The secundar, allocated, sees it too ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_secundar::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact_facing) into v_visible;
  if v_visible then
    report := report || E'\n2. PASS - the allocated secundar sees the linked trainer_facing contact';
  else
    report := report || E'\n2. FAIL - the allocated secundar cannot see the linked trainer_facing contact';
  end if;

  -- ---- 3. An unrelated trainer (no session on this group) does not see it, even though it is trainer_facing ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_other_trainer::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact_facing) into v_visible;
  if not v_visible then
    report := report || E'\n3. PASS - an unrelated trainer (no session on this group) cannot see the linked contact -- scoped, not org-wide';
  else
    report := report || E'\n3. FAIL - an unrelated trainer can see the linked contact -- the branch leaks beyond the viewer''s own sessions';
  end if;

  -- ---- 4. The allocated principal does NOT see the client's OTHER contact (general, not linked as on-site) ----
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact_general) into v_visible;
  if not v_visible then
    report := report || E'\n4. PASS - the allocated principal does not see the client''s other (unlinked, non-trainer_facing) contact';
  else
    report := report || E'\n4. FAIL - the allocated principal sees a contact that was never linked as this group''s on-site contact';
  end if;

  -- ---- 5. Re-link the SAME contact but change contact_purpose to 'general' -- the link alone must not grant visibility ----
  -- Reset to the privileged (non-impersonated) context for the write --
  -- a trainer holds no UPDATE capability on client_contacts, so doing
  -- this update while still impersonating v_principal would silently
  -- affect 0 rows under that role's own RLS, not exercise what this
  -- assertion is actually for.
  reset role;
  update public.client_contacts set contact_purpose = 'general' where id = v_contact_facing;
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_principal::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.client_contacts where id = v_contact_facing) into v_visible;
  if not v_visible then
    report := report || E'\n5. PASS - linking a contact as on-site does not by itself make them trainer-visible; contact_purpose = ''trainer_facing'' is still required';
  else
    report := report || E'\n5. FAIL - the link alone grants visibility, independent of contact_purpose -- the two are supposed to be independent gates';
  end if;

  raise exception '%', report;
end;
$verify$;

rollback;
