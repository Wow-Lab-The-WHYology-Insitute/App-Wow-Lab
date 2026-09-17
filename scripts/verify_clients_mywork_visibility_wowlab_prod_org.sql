-- verify_clients_mywork_visibility_wowlab_prod_org.sql
-- Confirms 202609170001's live policy against the REAL `WOW LAB` org
-- specifically, not just Test Org B -- zero real sessions exist in WOW LAB
-- today (confirmed live), so this is the only way to verify the branch
-- against production's own org id before a real trainer ever exercises it.
-- Pure SQL impersonation (set_config), no Auth API call -- does not touch
-- any real person's auth.users.last_sign_in_at, unlike a magiclink
-- verifyOtp would. Everything rolls back; this is read+insert-then-
-- rollback, never a commit.
-- Run with: supabase db query --linked --file scripts/verify_clients_mywork_visibility_wowlab_prod_org.sql

begin;

do $verify$
declare
  report text := '';
  v_org uuid := (select id from public.organizations where name = 'WOW LAB');
  v_trainer uuid := (select id from public.users where email = 'test+trainer-a@wowlab.dev');
  v_client uuid;
  v_group uuid;
  v_session uuid;
  v_visible boolean;
begin
  if v_org is null or v_trainer is null then
    raise exception 'Fixture lookup failed (org=%, trainer=%).', v_org, v_trainer;
  end if;

  insert into public.clients (organization_id, name, client_type) values (v_org, 'DRYRUN verify client (prod org)', 'corporate') returning id into v_client;
  insert into public.groups (organization_id, client_id, module, delivery_format) values (v_org, v_client, 'gaga', 'recurring') returning id into v_group;
  insert into public.sessions (organization_id, group_id, session_date, trainer_principal_id, status)
  values (v_org, v_group, current_date, v_trainer, 'planned') returning id into v_session;

  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
  select exists(select 1 from public.clients where id = v_client) into v_visible;
  if v_visible then
    report := report || E'\n1. PASS - a trainer in the real WOW LAB org can see the client of a session they are allocated to, via the new branch';
  else
    report := report || E'\n1. FAIL - the branch does not grant visibility in the WOW LAB org (only verified in Test Org B before)';
  end if;

  raise exception '%', report;
end;
$verify$;

rollback;
