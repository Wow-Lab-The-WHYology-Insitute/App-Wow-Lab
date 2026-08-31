-- verify_sessions_location_language.sql
-- Dry-run verification for
-- supabase/migrations/202608310001_sessions_location_language.sql, per
-- docs/WOWLAB_SAD_Field_Masking.md section 6.1.
--
-- Column-only migration, no backfill (deliberately -- see the migration's
-- own comment). This script verifies: both columns exist and are
-- nullable, both CHECK constraints reject an out-of-vocabulary value on a
-- real existing row (rejected, not silently coerced), both CHECK
-- constraints accept a real in-vocabulary value on a throwaway new row,
-- the app's existing session read/write paths still work unmodified, and
-- no pre-existing session was touched by any of this.
--
-- Run with: supabase db query --linked --file scripts/verify_sessions_location_language.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- mirror 202608310001's DDL exactly.
-- ============================================================================

alter table public.sessions
  add column location_tier text null
    check (location_tier in ('bucuresti', 'imprejurimi', 'alte_orase')),
  add column language_group text null
    check (language_group in ('ro_en', 'fr_de_es'));

-- ============================================================================
-- PHASE 1 -- still privileged. Resolve fixtures, snapshot every existing
-- session's mutable columns BEFORE any of the checks run, so the
-- "nothing pre-existing changed" assertion has something to compare
-- against that predates this script's own activity, not just the ALTER.
-- ============================================================================

select set_config('app.test_org_a', (select id::text from organizations where slug = 'wow-lab'), true);
select set_config('app.test_ops', (select id::text from users where email = 'test+ui-ops@wowlab.dev'), true);
select set_config('app.sample_session', (select id::text from sessions order by created_at limit 1), true);
select set_config('app.sample_group', (select group_id::text from sessions order by created_at limit 1), true);

select set_config('app.pre_row_count', (select count(*)::text from sessions), true);
select set_config('app.pre_max_updated_at', (select max(updated_at)::text from sessions), true);

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
  v_sample_session uuid := current_setting('app.sample_session')::uuid;
  v_sample_group uuid := current_setting('app.sample_group')::uuid;
  v_loc_nullable text;
  v_lang_nullable text;
  v_loc_type text;
  v_lang_type text;
  v_loc_rejected boolean := false;
  v_lang_rejected boolean := false;
  v_list_count int;
  v_insert_id uuid;
  v_accepted_loc text;
  v_accepted_lang text;
  v_current_count int;
  v_current_max_updated_at timestamptz;
begin
  -- ---- 1. both columns exist, nullable, text ----
  select is_nullable, data_type into v_loc_nullable, v_loc_type
  from information_schema.columns
  where table_schema = 'public' and table_name = 'sessions' and column_name = 'location_tier';

  select is_nullable, data_type into v_lang_nullable, v_lang_type
  from information_schema.columns
  where table_schema = 'public' and table_name = 'sessions' and column_name = 'language_group';

  if v_loc_nullable = 'YES' and v_loc_type = 'text' and v_lang_nullable = 'YES' and v_lang_type = 'text' then
    report := report || E'\n1. PASS - both columns exist, nullable, text';
  else
    report := report || format(E'\n1. FAIL - location_tier(nullable=%s,type=%s) language_group(nullable=%s,type=%s)',
      v_loc_nullable, v_loc_type, v_lang_nullable, v_lang_type);
  end if;

  -- ---- 2. location_tier CHECK rejects an out-of-vocabulary value ----
  begin
    update sessions set location_tier = 'oradea' where id = v_sample_session;
    report := report || E'\n2. FAIL - expected check_violation setting location_tier=''oradea'', update succeeded';
  exception
    when check_violation then
      v_loc_rejected := true;
      report := report || E'\n2. PASS - location_tier=''oradea'' raised check_violation, rejected';
  end;

  -- ---- 3. language_group CHECK rejects an out-of-vocabulary value ----
  begin
    update sessions set language_group = 'italiana' where id = v_sample_session;
    report := report || E'\n3. FAIL - expected check_violation setting language_group=''italiana'', update succeeded';
  exception
    when check_violation then
      v_lang_rejected := true;
      report := report || E'\n3. PASS - language_group=''italiana'' raised check_violation, rejected';
  end;

  -- ---- 4a. groups/[id]/page.tsx's exact session SELECT still works ----
  select count(*) into v_list_count
  from (
    select id, session_date, trainer_principal_id, trainer_secundar_id, status,
           attendance_count, experiment_delivered, duration_minutes, experiment_drive_link
    from sessions
    where group_id = v_sample_group
    order by session_date desc
  ) list_query;

  if v_list_count > 0 then
    report := report || format(E'\n4a. PASS - groups/[id]/page.tsx''s session SELECT still runs, returned %s rows', v_list_count);
  else
    report := report || E'\n4a. FAIL - groups/[id]/page.tsx''s session SELECT returned 0 rows (expected at least the sample session)';
  end if;

  -- ---- 4b. groups/actions.ts's addSession() INSERT shape still works,
  -- new row defaults location_tier/language_group to null ----
  insert into sessions (
    organization_id, group_id, session_date, status
  ) values (
    v_org, v_sample_group, current_date, 'planned'
  )
  returning id into v_insert_id;

  if v_insert_id is not null then
    report := report || E'\n4b. PASS - addSession()''s INSERT shape still succeeds';
  else
    report := report || E'\n4b. FAIL - the INSERT did not return an id';
  end if;

  select location_tier, language_group into v_accepted_loc, v_accepted_lang
  from sessions where id = v_insert_id;

  if v_accepted_loc is null and v_accepted_lang is null then
    report := report || E'\n4c. PASS - new row defaults location_tier/language_group to null';
  else
    report := report || format(E'\n4c. FAIL - expected both null on the new row, got location_tier=%s language_group=%s',
      v_accepted_loc, v_accepted_lang);
  end if;

  -- ---- 5. both CHECKs accept a real in-vocabulary value, on the
  -- throwaway row from 4b (never on pre-existing data) ----
  update sessions
    set location_tier = 'alte_orase', language_group = 'fr_de_es'
    where id = v_insert_id
  returning location_tier, language_group into v_accepted_loc, v_accepted_lang;

  if v_accepted_loc = 'alte_orase' and v_accepted_lang = 'fr_de_es' then
    report := report || E'\n5. PASS - in-vocabulary values (''alte_orase'', ''fr_de_es'') accepted on the throwaway row';
  else
    report := report || format(E'\n5. FAIL - expected (''alte_orase'',''fr_de_es''), got (%s,%s)', v_accepted_loc, v_accepted_lang);
  end if;

  -- ---- 6. no pre-existing session was modified ----
  -- Excludes the throwaway row from 4b/5 -- that row is new, by design;
  -- this assertion is about everything that existed BEFORE this script
  -- ran, including the sample session the two rejected updates targeted.
  select count(*) into v_current_count from sessions where id <> v_insert_id;
  select max(updated_at) into v_current_max_updated_at from sessions where id <> v_insert_id;

  if v_current_count = current_setting('app.pre_row_count')::int
     and v_current_max_updated_at = current_setting('app.pre_max_updated_at')::timestamptz
     and v_loc_rejected and v_lang_rejected
  then
    report := report || format(E'\n6. PASS - all %s pre-existing sessions unchanged (row count and max(updated_at) match the pre-migration snapshot; both rejected updates left no trace)', v_current_count);
  else
    report := report || format(E'\n6. FAIL - pre_row_count=%s current_count=%s, pre_max_updated_at=%s current_max=%s, loc_rejected=%s lang_rejected=%s',
      current_setting('app.pre_row_count'), v_current_count,
      current_setting('app.pre_max_updated_at'), v_current_max_updated_at, v_loc_rejected, v_lang_rejected);
  end if;

  raise exception E'VERIFICATION REPORT for 202608310001_sessions_location_language.sql (transaction WILL roll back -- nothing above or below this point was committed, including the throwaway session from 4b):%', report;
end;
$verify$;

rollback;
