-- verify_row_history_actor_user_id.sql
-- Dry-run verification for
-- supabase/migrations/202608260001_fix_row_history_actor_user_id.sql,
-- per docs/WOWLAB_SAD_Field_Masking.md section 6.1 (same protocol, applied
-- to a trigger fix rather than a masking view/policy).
--
-- Runs the function replacement, exercises six real writes across six of
-- the nine triggered tables under four different session contexts (direct
-- Postgres connection, service_role, and authenticated twice), then RAISES
-- an exception whose message IS the full report -- so the transaction can
-- never commit, on purpose, even if every assertion passes.
--
-- Run with: supabase db query --linked --file scripts/verify_row_history_actor_user_id.sql
-- Expect: a P0001 error whose message is the assertion report below.
--
-- Role sequence, each an explicit named SET LOCAL ROLE, never RESET ROLE:
-- privileged (Phase 1, direct-connection write) -> service_role (Phase
-- 1.5, service-role write) -> authenticated (Phase 2, every remaining
-- write). All three are deliberate, distinct role contexts this fix must
-- behave correctly under -- not a violation of "one switch to
-- authenticated," which still holds: authenticated is entered exactly
-- once, after which every simulated identity change is a
-- request.jwt.claims change, not another role switch.
--
-- Verification reads row_history directly, once, from the final
-- authenticated context: test+ui-owner@wowlab.dev (organization_owner)
-- holds org.audit.read, so the "authenticated select row_history" policy
-- (platform owner OR org.audit.read on a non-null organization_id) lets it
-- see every row this script writes, including the ones written before it
-- became the active role -- RLS SELECT visibility depends on the row's
-- own organization_id and the reader's capability, not on who wrote it.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608260001's DDL exactly.
-- ============================================================================

create or replace function public.row_history_capture()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare
  captured jsonb;
begin
  captured := case
    when TG_OP = 'DELETE' then row_to_json(old)::jsonb
    else row_to_json(new)::jsonb
  end;

  insert into public.row_history (
    id, table_name, row_id, organization_id, actor_user_id,
    old_values, new_values, changed_at, created_at, updated_at
  ) values (
    gen_random_uuid(),
    tg_table_name,
    coalesce(old.id, new.id),
    nullif(captured ->> 'organization_id', '')::uuid,
    app.current_user_id(),
    row_to_json(old)::jsonb,
    case when new is null then null else row_to_json(new)::jsonb end,
    now(), now(), now()
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$function$;

-- ============================================================================
-- PHASE 0.5 -- test-only scaffolding, never applied for real: a temporary
-- DELETE policy+grant on clients, scoped to this rolled-back transaction,
-- purely to exercise row_history_capture()'s DELETE branch under a real
-- authenticated session. Confirmed live before writing this (Thread 1,
-- contract-deletion investigation): NO table among the nine triggered
-- ones grants authenticated a real DELETE path today. That is an
-- unrelated, deliberate gap -- not something this migration changes. This
-- scaffolding tests the TRIGGER's behavior on a DELETE event, not whether
-- authenticated should be able to delete clients (it still won't be able
-- to, outside this transaction).
-- ============================================================================

grant delete on public.clients to authenticated;

create policy "_test_temp_delete_clients_row_history_verify" on public.clients
  for delete
  to authenticated
  using (true);

-- ============================================================================
-- PHASE 1 -- still privileged (direct Postgres connection, no JWT at all).
-- Resolve fixtures, then perform the direct-connection write (assertion 4)
-- while still in this context.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_owner', (select id::text from users where email = 'test+ui-owner@wowlab.dev'), true);
select set_config('app.draft_contract', (select id::text from contracts where status = 'draft' and organization_id = current_setting('app.test_org_a')::uuid limit 1), true);
select set_config('app.legal_entity', (select id::text from legal_entities where organization_id = current_setting('app.test_org_a')::uuid limit 1), true);
select set_config('app.some_group', (select id::text from groups where organization_id = current_setting('app.test_org_a')::uuid limit 1), true);
select set_config('app.some_uor', (select id::text from user_org_roles where organization_id = current_setting('app.test_org_a')::uuid limit 1), true);

-- Assertion 4's write: no-op UPDATE, direct Postgres connection, no JWT.
update legal_entities set name = name where id = current_setting('app.legal_entity')::uuid;

-- ============================================================================
-- PHASE 1.5 -- service_role, no JWT sub claim.
-- ============================================================================
set local role service_role;

-- Assertion 3's write: no-op UPDATE, service_role.
update org_settings set evaluations_confidential = evaluations_confidential
  where organization_id = current_setting('app.test_org_a')::uuid;

-- ============================================================================
-- PHASE 2 -- the one switch into authenticated. Every write from here on
-- is test+ui-owner@wowlab.dev (organization_owner -- confirmed live to
-- hold org.settings.manage, org.entities.manage, org.members.manage,
-- clients.create, contracts.*, and org.audit.read, satisfying every
-- policy this script touches, including the one it reads row_history
-- back through).
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_owner'), 'role', 'authenticated')::text, true);

-- Assertion 1's write: no-op UPDATE on a real draft contract.
update contracts set notes = notes where id = current_setting('app.draft_contract')::uuid;

-- Assertion 2's write: insert a throwaway client, then delete it (the
-- policy from Phase 0.5 is what makes the delete possible here).
with ins as (
  insert into clients (organization_id, name, client_type, status)
  values (current_setting('app.test_org_a')::uuid, 'VERIFY row_history actor (throwaway)', 'corporate', 'prospect')
  returning id
)
select set_config('app.temp_client', id::text, true) from ins;

delete from clients where id = current_setting('app.temp_client')::uuid;

-- Assertion 6b's writes: no-op UPDATEs on two more triggered tables.
update groups set notes = notes where id = current_setting('app.some_group')::uuid;
update user_org_roles set assigned_by = assigned_by where id = current_setting('app.some_uor')::uuid;

-- ============================================================================
-- PHASE 3 -- assertions, read as authenticated (org.audit.read covers all
-- of the above via the org_a scoping).
-- ============================================================================
do $verify$
declare
  report text := '';
  v_owner uuid := current_setting('app.test_owner')::uuid;
  v_org_a uuid := current_setting('app.test_org_a')::uuid;
  v_contract uuid := current_setting('app.draft_contract')::uuid;
  v_legal_entity uuid := current_setting('app.legal_entity')::uuid;
  v_temp_client uuid := current_setting('app.temp_client')::uuid;
  v_group uuid := current_setting('app.some_group')::uuid;
  v_uor uuid := current_setting('app.some_uor')::uuid;
  v_actor uuid;
  v_org uuid;
  v_row_id uuid;
  v_table text;
  v_old jsonb;
  v_new jsonb;
  v_changed_at timestamptz;
  v_trigger_count int;
begin
  -- ---- 1. UPDATE from an authenticated session records that user's id ----
  select actor_user_id into v_actor from row_history
    where table_name = 'contracts' and row_id = v_contract
    order by created_at desc limit 1;
  if v_actor = v_owner then
    report := report || E'\n1. PASS - UPDATE on contracts, as authenticated, recorded the real actor';
  else
    report := report || format(E'\n1. FAIL - expected actor=%s, got %s', v_owner, v_actor);
  end if;

  -- ---- 2. DELETE from an authenticated session records that user's id ----
  select actor_user_id into v_actor from row_history
    where table_name = 'clients' and row_id = v_temp_client
    order by created_at desc limit 1;
  if v_actor = v_owner then
    report := report || E'\n2. PASS - DELETE on clients, as authenticated, recorded the real actor';
  else
    report := report || format(E'\n2. FAIL - expected actor=%s, got %s', v_owner, v_actor);
  end if;

  -- ---- 3. Write from service_role records NULL, no error ----
  select actor_user_id into v_actor from row_history
    where table_name = 'org_settings' and row_id = (select id from org_settings where organization_id = v_org_a)
    order by created_at desc limit 1;
  if v_actor is null then
    report := report || E'\n3. PASS - UPDATE on org_settings, as service_role, recorded NULL (no error was raised, or this row would not exist)';
  else
    report := report || format(E'\n3. FAIL - expected NULL actor for service_role, got %s', v_actor);
  end if;

  -- ---- 4. Write from a direct Postgres connection records NULL, no error ----
  select actor_user_id into v_actor from row_history
    where table_name = 'legal_entities' and row_id = v_legal_entity
    order by created_at desc limit 1;
  if v_actor is null then
    report := report || E'\n4. PASS - UPDATE on legal_entities, direct Postgres connection, recorded NULL (no error was raised, or this row would not exist)';
  else
    report := report || format(E'\n4. FAIL - expected NULL actor for a direct connection, got %s', v_actor);
  end if;

  -- ---- 5. Every other row_history column unchanged ----
  select organization_id, row_id, table_name, old_values, new_values, changed_at
    into v_org, v_row_id, v_table, v_old, v_new, v_changed_at
    from row_history
    where table_name = 'contracts' and row_id = v_contract
    order by created_at desc limit 1;

  if v_org = v_org_a
     and v_row_id = v_contract
     and v_table = 'contracts'
     and v_old is not null and (v_old ->> 'id')::uuid = v_contract
     and v_new is not null and (v_new ->> 'id')::uuid = v_contract
     and v_changed_at > now() - interval '5 minutes'
  then
    report := report || E'\n5. PASS - organization_id, row_id, table_name, old_values, new_values, changed_at all behave as before on the contracts UPDATE entry';
  else
    report := report || format(E'\n5. FAIL - organization_id=%s row_id=%s table_name=%s old_has_id=%s new_has_id=%s changed_at=%s',
      v_org, v_row_id, v_table, (v_old ->> 'id'), (v_new ->> 'id'), v_changed_at);
  end if;

  -- ---- 6. All nine triggered tables still fire correctly ----
  -- 6a. Structural: all nine triggers still attached, still pointing at
  -- row_history_capture (the function this migration replaced in place,
  -- not a new function -- so the trigger definitions themselves are
  -- untouched by construction, confirmed here rather than assumed).
  select count(*) into v_trigger_count
  from pg_trigger
  where tgfoid = 'row_history_capture'::regproc
    and not tgisinternal
    and tgrelid::regclass::text in (
      'client_contacts','clients','contracts','file_refs','groups',
      'legal_entities','org_settings','sessions','user_org_roles'
    );
  if v_trigger_count = 9 then
    report := report || E'\n6a. PASS - all nine triggered tables still have row_history_capture attached';
  else
    report := report || format(E'\n6a. FAIL - expected 9 tables with the trigger attached, found %s', v_trigger_count);
  end if;

  -- 6b. Literally exercised, beyond contracts/clients (already covered by
  -- 1/2): groups and user_org_roles.
  select actor_user_id into v_actor from row_history
    where table_name = 'groups' and row_id = v_group
    order by created_at desc limit 1;
  if v_actor = v_owner then
    report := report || E'\n6b-groups. PASS - UPDATE on groups, as authenticated, recorded the real actor';
  else
    report := report || format(E'\n6b-groups. FAIL - expected actor=%s, got %s', v_owner, v_actor);
  end if;

  select actor_user_id into v_actor from row_history
    where table_name = 'user_org_roles' and row_id = v_uor
    order by created_at desc limit 1;
  if v_actor = v_owner then
    report := report || E'\n6b-user_org_roles. PASS - UPDATE on user_org_roles, as authenticated, recorded the real actor';
  else
    report := report || format(E'\n6b-user_org_roles. FAIL - expected actor=%s, got %s', v_owner, v_actor);
  end if;

  raise exception E'VERIFICATION REPORT for 202608260001_fix_row_history_actor_user_id.sql (transaction WILL roll back -- nothing above or below this point was committed, including the temporary clients DELETE policy/grant and the throwaway client row):%', report;
end;
$verify$;

rollback;
