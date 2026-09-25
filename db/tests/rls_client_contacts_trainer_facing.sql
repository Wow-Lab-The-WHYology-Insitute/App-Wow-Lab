-- db/tests/rls_client_contacts_trainer_facing.sql
-- WOW LAB OS: impersonation-based checks for public.client_contacts' own
-- SELECT policy's mywork.* / trainer_facing branch (202609210002, the
-- CURRENT live, session-scoped shape) -- item 86's audit found
-- rls_clients_contracts.sql never covers client_contacts' trainer_facing
-- branch at all, and its only verification was a one-time dry run
-- (scripts/verify_client_contacts_trainer_facing_scoping.sql, written
-- BEFORE the fix, against WOW LAB Test Org B) with no re-runnable
-- sabotage check. This file promotes those same properties into the
-- permanent suite, against wow-lab, with a sabotage check added.
--
-- Item 77's own finding, the reason this file exists: the branch as
-- FIRST built (202608250001) was org-wide -- any mywork.* holder saw
-- EVERY trainer_facing contact in the org, not just ones tied to their
-- own allocated sessions. 202609210002 narrowed it to the session-scoped
-- shape this file tests.
--
-- Same pattern as every other file in this directory: resolve fixture ids
-- into session GUCs while still privileged, switch role, exercise the
-- real table. Every block is BEGIN/ROLLBACK.
--
-- Fixture users: test+trainer-a@wowlab.dev (allocated principal),
-- test+trainer-b@wowlab.dev (unrelated -- no session on the fixture
-- group) -- both already used throughout db/tests/rls_groups_sessions.sql
-- and rls_ws_d_write.sql.

-- ============================================================================
-- Point 1 — the core scoping property: allocated trainer sees the linked
-- trainer_facing contact; an unrelated trainer, holding the identical
-- mywork.* capability, does not; the allocated trainer does not see the
-- client's OTHER (unlinked) contact either.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.fixture_trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);
  select set_config('app.fixture_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_contact_facing uuid;
    v_contact_general uuid;
    v_group uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture CC Trainer-Facing Client', 'corporate')
      returning id into v_client;
    insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
      values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'Fixture Trainer-Facing Contact', '0700000010', 'trainer_facing')
      returning id into v_contact_facing;
    insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
      values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'Fixture General Contact', '0700000011', 'general')
      returning id into v_contact_general;
    insert into public.groups (organization_id, client_id, module, delivery_format, on_site_contact_id)
      values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'gaga', 'wow_lab_party', v_contact_facing)
      returning id into v_group;
    insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
      values (current_setting('app.test_org_wow_lab')::uuid, v_group, current_date, current_setting('app.fixture_trainer_a')::uuid, 'planned');

    perform set_config('app.fixture_contact_facing', v_contact_facing::text, true);
    perform set_config('app.fixture_contact_general', v_contact_general::text, true);
  end $$;

  select set_config(
    'request.jwt.claims',
    json_build_object('sub', current_setting('app.fixture_trainer_a')::text, 'role', 'authenticated')::text,
    true
  );
  select set_config('role', 'authenticated', true);
  select set_config('test.principal_sees_facing', (
    exists(select 1 from public.client_contacts where id = current_setting('app.fixture_contact_facing')::uuid)
  )::text, true);
  select set_config('test.principal_sees_general', (
    exists(select 1 from public.client_contacts where id = current_setting('app.fixture_contact_general')::uuid)
  )::text, true);

  select set_config(
    'request.jwt.claims',
    json_build_object('sub', current_setting('app.fixture_trainer_b')::text, 'role', 'authenticated')::text,
    true
  );
  select set_config('test.unrelated_sees_facing', (
    exists(select 1 from public.client_contacts where id = current_setting('app.fixture_contact_facing')::uuid)
  )::text, true);

  select 'trainer_a (allocated): sees the linked trainer_facing contact' as check_name,
    current_setting('test.principal_sees_facing') as actual, 'true' as expected,
    current_setting('test.principal_sees_facing')::boolean = true as pass
  union all
  select 'trainer_a (allocated): does NOT see the client''s other (unlinked) contact',
    current_setting('test.principal_sees_general'), 'false',
    current_setting('test.principal_sees_general')::boolean = false
  union all
  select 'trainer_b (unrelated, no session on this group): does NOT see the linked contact -- session-scoped, not org-wide',
    current_setting('test.unrelated_sees_facing'), 'false',
    current_setting('test.unrelated_sees_facing')::boolean = false;
rollback;

-- ============================================================================
-- Point 2 — SABOTAGE CHECK ("does this suite have teeth?"). Reverts the
-- mywork.* branch to the EXACT pre-202609210002 shape (item 77's own
-- finding): org-wide, any mywork.* holder + contact_purpose =
-- 'trainer_facing', no session/group scoping at all. Re-runs Point 1's
-- "unrelated trainer does NOT see it" assertion; under the reverted
-- (widened) policy trainer_b should now wrongly see the contact, flipping
-- `pass` to false. A plain SELECT, not wrapped in any exception handler --
-- immune to the "lookup failure indistinguishable from policy denial" bug
-- item 86 found and fixed in rls_ws_d_write.sql.
-- ============================================================================
begin;
  select set_config('app.test_org_wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.fixture_trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  do $$
  declare
    v_client uuid;
    v_contact_facing uuid;
  begin
    insert into public.clients (organization_id, name, client_type)
      values (current_setting('app.test_org_wow_lab')::uuid, 'Fixture CC Sabotage Client', 'corporate')
      returning id into v_client;
    insert into public.client_contacts (organization_id, client_id, full_name, phone, contact_purpose)
      values (current_setting('app.test_org_wow_lab')::uuid, v_client, 'Fixture Sabotage Trainer-Facing Contact', '0700000020', 'trainer_facing')
      returning id into v_contact_facing;
    -- No group, no session -- trainer_b is allocated to NOTHING here.
    -- Under the correct (narrowed) policy this contact is invisible to
    -- everyone but finance/ops/owner; under the reverted (widened) one,
    -- any mywork.* holder sees it purely from contact_purpose.
    perform set_config('app.fixture_contact_sabotage', v_contact_facing::text, true);
  end $$;

  -- Still privileged at this point (role not yet switched) -- revert the
  -- branch to the pre-202609210002 org-wide shape (quoted verbatim from
  -- that migration's own header).
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

  select set_config(
    'request.jwt.claims',
    json_build_object('sub', current_setting('app.fixture_trainer_b')::text, 'role', 'authenticated')::text,
    true
  );
  select set_config('role', 'authenticated', true);

  select 'SABOTAGE: trainer_b (unrelated, no session anywhere near this contact) now sees it, same assertion as Point 1, branch reverted to the pre-202609210002 org-wide shape' as check_name,
    (exists(select 1 from public.client_contacts where id = current_setting('app.fixture_contact_sabotage')::uuid))::text as actual,
    'false' as expected,
    (exists(select 1 from public.client_contacts where id = current_setting('app.fixture_contact_sabotage')::uuid)) = false as pass;
    -- ^ this `pass` is expected to read FALSE here (actual will be true) --
    -- that is the whole point: reverting the narrowing makes this
    -- assertion fail, proving the suite would have caught item 77's bug
    -- had this test existed before the narrowing fix shipped.
rollback;
