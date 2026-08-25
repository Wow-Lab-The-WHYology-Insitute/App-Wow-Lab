-- verify_client_contacts_row_filters.sql
-- Dry-run verification for
-- supabase/migrations/202608250001_client_contacts_row_filters_and_notes_grant.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Runs the policy-swap DDL, seeds fixtures, runs the seven assertions, then
-- RAISES an exception whose message IS the full report -- so the
-- transaction can never commit, on purpose, even if every assertion
-- passes.
--
-- Run with: supabase db query --linked --file scripts/verify_client_contacts_row_filters.sql
-- Expect: a P0001 error whose message is the assertion report below.
--
-- Session role stays elevated (postgres-equivalent, BYPASSRLS) through
-- Phase 0 and Phase 1. SET LOCAL ROLE authenticated happens exactly once,
-- in Phase 2. After that, every different simulated user is a change to
-- request.jwt.claims only -- never another role switch.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608250001's DDL exactly.
-- ============================================================================

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

revoke select on public.client_contacts from authenticated;

grant select (
  id,
  organization_id,
  client_id,
  full_name,
  role_at_client,
  email,
  phone,
  is_billing_contact,
  is_primary,
  contact_purpose,
  created_at,
  updated_at
) on public.client_contacts to authenticated;

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, seed what the assertions
-- need, before the one role switch.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_catalina', (select id::text from users where email = 'test+catalina@wowlab.dev'), true);
select set_config('app.test_finance_ops', (select id::text from users where email = 'test+finance-ops-a@wowlab.dev'), true);
select set_config('app.test_finance_admin', (select id::text from users where email = 'test+finance-admin-a@wowlab.dev'), true);
select set_config('app.test_trainer', (select id::text from users where email = 'test+trainer-a@wowlab.dev'), true);

select set_config('app.client_cambridge', (select id::text from clients where name = 'Cambridge School' and organization_id = current_setting('app.test_org_a')::uuid), true);
select set_config('app.client_zitec', (select id::text from clients where name = 'Zitec' and organization_id = current_setting('app.test_org_a')::uuid), true);

-- The one real production row (Vlad Rasnoveanu, both is_billing_contact and
-- is_primary) -- resolved via client_contacts itself, not by matching the
-- client's name as a string literal (accented characters, avoid the
-- encoding footgun entirely). There is exactly one row in the whole table
-- today (confirmed live before writing this), so this is unambiguous.
-- Not seeded -- this is live data, referenced read-only for assertion 1.
select set_config('app.real_lycee_contact', (select id::text from client_contacts limit 1), true);

-- Seeded fixtures, all dropped by the final ROLLBACK -- never persisted.
with ins as (
  insert into client_contacts (organization_id, client_id, full_name, is_billing_contact, is_primary, contact_purpose)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.client_cambridge')::uuid, 'VERIFY Billing Only (Cambridge)', true, false, null)
  returning id
)
select set_config('app.seeded_billing_only', id::text, true) from ins;

with ins as (
  insert into client_contacts (organization_id, client_id, full_name, is_billing_contact, is_primary, contact_purpose)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.client_zitec')::uuid, 'VERIFY Corporate Contact (Zitec)', false, false, null)
  returning id
)
select set_config('app.seeded_zitec_contact', id::text, true) from ins;

with ins as (
  insert into client_contacts (organization_id, client_id, full_name, is_billing_contact, is_primary, contact_purpose)
  values (current_setting('app.test_org_a')::uuid, current_setting('app.client_cambridge')::uuid, 'VERIFY Trainer Facing (Cambridge)', false, false, 'trainer_facing')
  returning id
)
select set_config('app.seeded_trainer_facing', id::text, true) from ins;

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_catalina uuid := current_setting('app.test_catalina')::uuid;
  v_finance_ops uuid := current_setting('app.test_finance_ops')::uuid;
  v_finance_admin uuid := current_setting('app.test_finance_admin')::uuid;
  v_trainer uuid := current_setting('app.test_trainer')::uuid;
  v_real_lycee_contact uuid := current_setting('app.real_lycee_contact')::uuid;
  v_seeded_billing_only uuid := current_setting('app.seeded_billing_only')::uuid;
  v_seeded_zitec uuid := current_setting('app.seeded_zitec_contact')::uuid;
  v_seeded_trainer_facing uuid := current_setting('app.seeded_trainer_facing')::uuid;
  v_client_cambridge uuid := current_setting('app.client_cambridge')::uuid;
  v_count int;
  v_full_name text;
begin
  -- ---- 1. Catalina sees the Lycee row -- it's primary, billing must not hide it ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_catalina::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from client_contacts where id = v_real_lycee_contact;
  if v_count = 1 then
    report := report || E'\n1. PASS - Catalina (operations_manager) sees the real Lycee Francais row (primary overrides the billing flag)';
  else
    report := report || format(E'\n1. FAIL - Catalina should see the primary+billing Lycee row, got count=%s', v_count);
  end if;

  -- ---- 2. Seeded billing-only (non-primary) contact invisible to Catalina ----
  select count(*) into v_count from client_contacts where id = v_seeded_billing_only;
  if v_count = 0 then
    report := report || E'\n2. PASS - non-primary billing-only contact is invisible to Catalina';
  else
    report := report || format(E'\n2. FAIL - Catalina should NOT see the non-primary billing-only contact, got count=%s', v_count);
  end if;

  -- ---- 3. Same row IS visible to finance_operations (private_school match) ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_finance_ops::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from client_contacts where id = v_seeded_billing_only;
  if v_count = 1 then
    report := report || E'\n3. PASS - finance_operations sees the same billing-only contact (Cambridge is private_school, in scope)';
  else
    report := report || format(E'\n3. FAIL - finance_operations should see the billing-only contact on a private_school client, got count=%s', v_count);
  end if;

  -- ---- 4. client_type segregation still intact ----
  -- 4a. finance_operations sees nothing for a corporate client (Zitec).
  select count(*) into v_count from client_contacts where id = v_seeded_zitec;
  if v_count = 0 then
    report := report || E'\n4a. PASS - finance_operations still sees nothing for the corporate client (Zitec)';
  else
    report := report || format(E'\n4a. FAIL - finance_operations should see nothing on a corporate client, got count=%s', v_count);
  end if;

  -- 4b. finance_admin_reporting sees nothing for a private school (Cambridge).
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_finance_admin::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from client_contacts where client_id = v_client_cambridge;
  if v_count = 0 then
    report := report || E'\n4b. PASS - finance_admin_reporting still sees nothing for the private-school client (Cambridge)';
  else
    report := report || format(E'\n4b. FAIL - finance_admin_reporting should see nothing on a private_school client, got count=%s', v_count);
  end if;

  -- ---- 5. Direct base-table select of notes -> insufficient_privilege ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_catalina::text, 'role', 'authenticated')::text, true);

  begin
    execute 'select notes from public.client_contacts where id = $1' into v_full_name using v_real_lycee_contact;
    report := report || E'\n5. FAIL - direct select of notes unexpectedly succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n5. PASS - direct base-table select of notes raised insufficient_privilege';
  end;

  -- ---- 6. Direct base-table select of the other columns -> succeeds ----
  begin
    execute 'select id, organization_id, client_id, full_name, role_at_client, email, phone, is_billing_contact, is_primary, contact_purpose, created_at, updated_at from public.client_contacts where id = $1'
      using v_real_lycee_contact;
    report := report || E'\n6. PASS - direct base-table select of all twelve non-notes columns succeeded';
  exception
    when insufficient_privilege then
      report := report || E'\n6. FAIL - direct select of the allowed columns unexpectedly raised insufficient_privilege';
  end;

  -- ---- 7. Trainer branch -- non-discriminating today, wired correctly ----
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from client_contacts where id = v_seeded_trainer_facing;
  if v_count = 1 then
    report := report || E'\n7a. PASS - trainer sees the seeded contact_purpose=''trainer_facing'' row';
  else
    report := report || format(E'\n7a. FAIL - trainer should see the trainer_facing row, got count=%s', v_count);
  end if;

  select count(*) into v_count from client_contacts where id = v_seeded_billing_only;
  if v_count = 0 then
    report := report || E'\n7b. PASS - trainer does NOT see the non-trainer_facing billing-only row on the same client -- the branch discriminates on contact_purpose, not just organization';
  else
    report := report || format(E'\n7b. FAIL - trainer should not see a non-trainer_facing row, got count=%s', v_count);
  end if;

  report := report || E'\n7c. NOTE (non-discriminating in production today) - this branch cannot fail in a way that reflects live traffic: trainer/senior_trainer hold no other capability that reaches client_contacts (confirmed live), and no production row has contact_purpose = ''trainer_facing'' yet (the one real row predates the column). 7a/7b prove the branch is wired correctly, not that it is protecting anything today. Re-verify this assertion the day a trainer-facing read capability is actually added.';

  raise exception E'VERIFICATION REPORT for 202608250001_client_contacts_row_filters_and_notes_grant.sql (transaction WILL roll back -- nothing above or below this point was committed, including the three seeded VERIFY contacts):%', report;
end;
$verify$;

rollback;
