-- verify_remaining_test_account_flags.sql
-- Dry-run verification for
-- supabase/migrations/202609040002_backfill_remaining_test_account_flags.sql.
--
-- Asserts: all 17 listed ids read is_test_account = true afterwards; the
-- eight real accounts created 2026-09-03 still read false; and the total
-- count of is_test_account = true rows equals the pre-migration count
-- plus 17 (not more, not less -- proves the UPDATE touched exactly these
-- 17 rows, nothing else).
--
-- Run with: supabase db query --linked --file scripts/verify_remaining_test_account_flags.sql
-- Expect: a P0001 error whose message is the assertion report below.

begin;

-- ============================================================================
-- PHASE 0 -- snapshot the true-count BEFORE the UPDATE.
-- ============================================================================

select set_config('app.true_count_before', (select count(*)::text from public.users where is_test_account = true), true);

-- ============================================================================
-- PHASE 1 -- mirror 202609040002's UPDATE exactly.
-- ============================================================================

update public.users
set is_test_account = true
where id in (
  'eee47818-3105-4e73-95d9-638f8b5c4781', -- test+user-b@wowlab.dev
  '12754013-fbe2-4643-8ec4-3357de69d2af', -- maxdigitalro+master@gmail.com
  'b88ea8aa-b8af-4d09-86ea-efa6c035bf5e', -- maxdigitalro+ops@gmail.com
  '28e99549-0a50-43e5-9feb-881e2f7d7b1b', -- maxdigitalro+finops@gmail.com
  'dfbf1092-5cb9-444c-913c-328dd21ee456', -- maxdigitalro+finadmin@gmail.com
  '5ffb6cf5-2742-494b-89cd-e4eb8bf13a14', -- maxdigitalro+community@gmail.com
  'fa6e8566-aea6-4048-80e3-22a705a03899', -- maxdigitalro+inventory@gmail.com
  '186e33ce-762c-45c5-8d8e-de3f59337cc4', -- maxdigitalro+trainer@gmail.com
  'ea63166e-14d6-4179-891d-132de3595c76', -- test+ui-org-b@wowlab.dev
  'a1cc089a-3a02-4e01-86f8-ea8b49ce711d', -- test+cascade-check@wowlab.dev
  '901d6d66-a365-4744-8c23-b2dd37e0e0cf', -- test+trainer-b@wowlab.dev
  'fab9f77c-ac27-43f2-ac8f-a0c03f668880', -- maxdigitalro+trainerb1@gmail.com
  '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', -- maxdigitalro+trainerb2@gmail.com
  'f30321ee-66bd-45bb-afe9-1592313101b0', -- maxdigitalro+trainerb3@gmail.com
  'e67e78a8-6ced-4123-b937-bd4ec4c2d28e', -- maxdigitalro+trainerb4@gmail.com
  '88c2d66b-64f3-4881-b2f2-a85ac3a060e5', -- maxdigitalro+trainerb5@gmail.com
  'b7bb9753-0523-4c44-ac31-c3acba3f6259'  -- maxdigitalro+trainerb6@gmail.com
)
and is_test_account = false;

-- ============================================================================
-- PHASE 2 -- assertions.
-- ============================================================================
do $verify$
declare
  report text := '';
  v_true_before int := current_setting('app.true_count_before')::int;
  v_true_after int;
  v_seventeen_false_count int;
  v_real_eight_true_count int;
begin
  -- ---- 1. all 17 now read true ----
  select count(*) into v_seventeen_false_count
  from public.users
  where id in (
    'eee47818-3105-4e73-95d9-638f8b5c4781',
    '12754013-fbe2-4643-8ec4-3357de69d2af',
    'b88ea8aa-b8af-4d09-86ea-efa6c035bf5e',
    '28e99549-0a50-43e5-9feb-881e2f7d7b1b',
    'dfbf1092-5cb9-444c-913c-328dd21ee456',
    '5ffb6cf5-2742-494b-89cd-e4eb8bf13a14',
    'fa6e8566-aea6-4048-80e3-22a705a03899',
    '186e33ce-762c-45c5-8d8e-de3f59337cc4',
    'ea63166e-14d6-4179-891d-132de3595c76',
    'a1cc089a-3a02-4e01-86f8-ea8b49ce711d',
    '901d6d66-a365-4744-8c23-b2dd37e0e0cf',
    'fab9f77c-ac27-43f2-ac8f-a0c03f668880',
    '82b99dfb-b938-41f5-850c-fbd9beb5b6e5',
    'f30321ee-66bd-45bb-afe9-1592313101b0',
    'e67e78a8-6ced-4123-b937-bd4ec4c2d28e',
    '88c2d66b-64f3-4881-b2f2-a85ac3a060e5',
    'b7bb9753-0523-4c44-ac31-c3acba3f6259'
  )
  and is_test_account = false;

  if v_seventeen_false_count = 0 then
    report := report || E'\n1. PASS - all 17 listed ids now read is_test_account = true';
  else
    report := report || format(E'\n1. FAIL - %s of the 17 listed ids still read is_test_account = false', v_seventeen_false_count);
  end if;

  -- ---- 2. the eight real accounts still read false ----
  select count(*) into v_real_eight_true_count
  from public.users
  where email in (
    'catalina_moale@yahoo.com',
    'lauraflorentinaa220@gmail.com',
    'alexandra.nutu2010@gmail.com',
    'merisanteodora@gmail.com',
    'rabalasov@gmail.com',
    'popar216@gmail.com',
    'luiza.mirt8@gmail.com',
    'ralucamargean@yahoo.com'
  )
  and is_test_account = true;

  if v_real_eight_true_count = 0 then
    report := report || E'\n2. PASS - the eight real accounts (2026-09-03) still read is_test_account = false';
  else
    report := report || format(E'\n2. FAIL - %s of the eight real accounts now read is_test_account = true', v_real_eight_true_count);
  end if;

  -- ---- 3. total true count = before + 17 exactly ----
  select count(*) into v_true_after from public.users where is_test_account = true;

  if v_true_after = v_true_before + 17 then
    report := report || format(E'\n3. PASS - total is_test_account=true count went from %s to %s (exactly +17)', v_true_before, v_true_after);
  else
    report := report || format(E'\n3. FAIL - expected %s (before=%s + 17), got %s', v_true_before + 17, v_true_before, v_true_after);
  end if;

  raise exception E'VERIFICATION REPORT for 202609040002_backfill_remaining_test_account_flags.sql (transaction WILL roll back -- nothing above or below this point was committed):%', report;
end;
$verify$;

rollback;
