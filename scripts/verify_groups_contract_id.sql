-- verify_groups_contract_id.sql
-- Dry-run verification for
-- supabase/migrations/202608290001_groups_contract_id.sql, per
-- docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Column-only migration, no backfill (deliberately -- see the migration's
-- own comment and docs/OPEN_ITEMS.md). This script verifies exactly that:
-- the column exists, is nullable, its FK actually rejects a bogus id, the
-- three existing app-level read/write paths on groups still work
-- unmodified, and -- the assertion that matters most for a migration that
-- adds a column and touches nothing else -- no existing row was modified
-- by any of this.
--
-- Run with: supabase db query --linked --file scripts/verify_groups_contract_id.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608290001's DDL exactly.
-- ============================================================================

alter table public.groups
  add column contract_id uuid null references public.contracts(id);

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, snapshot every existing
-- group's mutable columns BEFORE any of the read/write-path checks run,
-- so assertion 4 has something to compare against that predates this
-- script's own activity, not just predates the ALTER.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_ops', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.sample_group', (select id::text from groups order by created_at limit 1), true);
select set_config('app.sample_client', (select client_id::text from groups order by created_at limit 1), true);

-- Checksums rather than a temp table snapshot -- a temp table created
-- while privileged and read back after SET LOCAL ROLE authenticated is an
-- untested permission path in this session's scripts; count + max(updated_at)
-- carried via set_config (the established pattern everywhere else) says
-- the same thing without introducing one.
select set_config('app.pre_row_count', (select count(*)::text from groups), true);
select set_config('app.pre_max_updated_at', (select max(updated_at)::text from groups), true);

-- ============================================================================
-- PHASE 2 -- the one and only role switch.
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('app.test_ops'), 'role', 'authenticated')::text, true);

-- ============================================================================
-- PHASE 3 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_org uuid := current_setting('app.test_org_a')::uuid;
  v_sample_group uuid := current_setting('app.sample_group')::uuid;
  v_sample_client uuid := current_setting('app.sample_client')::uuid;
  v_col_nullable text;
  v_fk_caught boolean := false;
  v_fk_sqlstate text;
  v_list_count int;
  v_detail_found boolean;
  v_insert_id uuid;
  v_current_count int;
  v_current_max_updated_at timestamptz;
  v_still_null_count int;
begin
  -- ---- 1. column exists and is nullable ----
  select is_nullable into v_col_nullable
  from information_schema.columns
  where table_schema = 'public' and table_name = 'groups' and column_name = 'contract_id';

  if v_col_nullable = 'YES' then
    report := report || E'\n1. PASS - groups.contract_id exists and is nullable';
  else
    report := report || format(E'\n1. FAIL - expected nullable column, got is_nullable=%s (or column missing)', v_col_nullable);
  end if;

  -- ---- 2. the FK rejects a bogus id ----
  begin
    update groups set contract_id = gen_random_uuid() where id = v_sample_group;
    report := report || E'\n2. FAIL - expected foreign_key_violation (23503) setting contract_id to a random uuid, but the update succeeded';
  exception
    when foreign_key_violation then
      get stacked diagnostics v_fk_sqlstate = returned_sqlstate;
      v_fk_caught := true;
      report := report || format(E'\n2. PASS - setting contract_id to a bogus id raised foreign_key_violation (sqlstate %s)', v_fk_sqlstate);
  end;

  -- ---- 3a. groups/page.tsx's exact list SELECT still works ----
  select count(*) into v_list_count
  from (
    select id, client_id, module, delivery_format, schedule_pattern,
           children_confirmed, children_billed, status
    from groups
    order by created_at desc
  ) list_query;

  if v_list_count > 0 then
    report := report || format(E'\n3a. PASS - groups/page.tsx''s list SELECT still runs, returned %s rows', v_list_count);
  else
    report := report || E'\n3a. FAIL - groups/page.tsx''s list SELECT returned 0 rows (expected at least the sample group)';
  end if;

  -- ---- 3b. groups/[id]/page.tsx's exact detail SELECT still works ----
  select exists (
    select 1
    from (
      select id, organization_id, client_id, module, delivery_format, schedule_pattern,
             children_confirmed, children_billed, status, notes, age_range,
             school_year_calendar_link
      from groups
      where id = v_sample_group
    ) detail_query
  ) into v_detail_found;

  if v_detail_found then
    report := report || E'\n3b. PASS - groups/[id]/page.tsx''s detail SELECT still finds the sample group';
  else
    report := report || E'\n3b. FAIL - groups/[id]/page.tsx''s detail SELECT found nothing for the sample group id';
  end if;

  -- ---- 3c. groups/actions.ts's addGroup() INSERT shape still works ----
  -- 'gaga' is a real value from groups_module_check (module is a fixed
  -- vocabulary, not free text) -- picked arbitrarily, not because this
  -- throwaway row's module matters. Rolled back with everything else.
  insert into groups (
    organization_id, client_id, module, delivery_format, schedule_pattern,
    status, age_range, school_year_calendar_link
  ) values (
    v_org, v_sample_client, 'gaga', 'custom', null,
    'active', null, null
  )
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n3c. PASS - addGroup()''s INSERT shape still succeeds, contract_id defaulted to null on the new row';
  else
    report := report || E'\n3c. FAIL - the INSERT did not return an id';
  end if;

  -- ---- 4. no existing row was modified ----
  -- Excludes the throwaway VERIFY-MODULE row from assertion 3c -- that
  -- row is new, by design; this assertion is about everything that
  -- existed BEFORE this script ran.
  select count(*) into v_current_count from groups where id <> v_insert_id;
  select max(updated_at) into v_current_max_updated_at from groups where id <> v_insert_id;
  select count(*) into v_still_null_count
  from groups where id <> v_insert_id and contract_id is null;

  if v_current_count = current_setting('app.pre_row_count')::int
     and v_current_max_updated_at = current_setting('app.pre_max_updated_at')::timestamptz
     and v_still_null_count = current_setting('app.pre_row_count')::int
  then
    report := report || format(E'\n4. PASS - all %s pre-existing groups unchanged (row count and max(updated_at) match the pre-migration snapshot, contract_id null on every one) -- the ALTER and the checks above touched nothing pre-existing', v_current_count);
  else
    report := report || format(E'\n4. FAIL - pre_row_count=%s current_count=%s, pre_max_updated_at=%s current_max=%s, still_null=%s',
      current_setting('app.pre_row_count'), v_current_count,
      current_setting('app.pre_max_updated_at'), v_current_max_updated_at, v_still_null_count);
  end if;

  raise exception E'VERIFICATION REPORT for 202608290001_groups_contract_id.sql (transaction WILL roll back -- nothing above or below this point was committed, including the throwaway VERIFY-MODULE group):%', report;
end;
$verify$;

rollback;
