-- verify_clients_unique_cui.sql
-- Live verification of 202609150003 (clients_unique_organization_cui)
-- against WOW LAB Test Org B.
--
-- Run with: supabase db query --linked --file scripts/verify_clients_unique_cui.sql
-- Expect: a P0001 error whose message is the assertion report below.
-- Everything here runs inside one transaction that always rolls back.

begin;

do $verify$
declare
  report text := '';
  v_org_b uuid := (select id from public.organizations where name = 'WOW LAB Test Org B');
  v_org_other uuid;
  v_client_1 uuid;
  v_client_2 uuid;
  v_client_3 uuid;
  v_client_4 uuid;
  v_client_5 uuid;
  v_cui text := 'RO-VERIFY-CUI-9001';
begin
  if v_org_b is null then
    raise exception 'Fixture lookup failed. org_b=%', v_org_b;
  end if;

  -- A second, throwaway organization created inside this same
  -- transaction -- not the real WOW LAB org -- so the cross-org
  -- assertion below never touches real production data, even
  -- temporarily, even inside a transaction that always rolls back.
  insert into public.organizations (name, slug, is_test)
  values ('DRYRUN verify org (cui constraint scope)', 'dryrun-verify-cui-scope', true)
  returning id into v_org_other;

  -- ---- 1. First client with this CUI in org B: succeeds ----
  insert into public.clients (organization_id, name, client_type, cui)
  values (v_org_b, 'DRYRUN verify client A', 'private_school', v_cui)
  returning id into v_client_1;
  report := report || E'\n1. PASS - first client with this CUI in org B created';

  -- ---- 2. Second client, same org, same CUI: rejected ----
  begin
    insert into public.clients (organization_id, name, client_type, cui)
    values (v_org_b, 'DRYRUN verify client B', 'private_school', v_cui)
    returning id into v_client_2;
    report := report || E'\n2. FAIL - a second client with the same CUI in the same org was allowed';
  exception when unique_violation then
    report := report || E'\n2. PASS - a second client with the same CUI in the same org is rejected (clients_unique_organization_cui)';
  end;

  -- ---- 3. Two clients with NO cui in the same org: both accepted, no collision ----
  insert into public.clients (organization_id, name, client_type, cui)
  values (v_org_b, 'DRYRUN verify client C (no cui)', 'parent_b2c', null)
  returning id into v_client_3;
  insert into public.clients (organization_id, name, client_type, cui)
  values (v_org_b, 'DRYRUN verify client D (no cui)', 'parent_b2c', null)
  returning id into v_client_4;
  report := report || E'\n3. PASS - two clients with cui IS NULL in the same org both created -- Postgres treats each NULL as distinct, unaffected by the constraint';

  -- ---- 4. Same CUI in a DIFFERENT organization: accepted ----
  insert into public.clients (organization_id, name, client_type, cui)
  values (v_org_other, 'DRYRUN verify client E (other org)', 'private_school', v_cui)
  returning id into v_client_5;
  report := report || E'\n4. PASS - the identical CUI in a different organization is accepted -- the constraint is scoped to (organization_id, cui), not cui alone';

  -- reset back to privileged context to clean up
  delete from public.clients where id in (v_client_1, v_client_3, v_client_4, v_client_5);
  delete from public.organizations where id = v_org_other;

  raise exception E'VERIFICATION REPORT for 202609150003 (clients_unique_organization_cui), WOW LAB Test Org B + a throwaway second org (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
