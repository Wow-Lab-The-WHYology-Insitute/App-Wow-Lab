-- db/tests/custom_workshop_type.sql
-- The tenth workshop type, 'custom' (202609260001, item 102). Not an RLS
-- suite -- nothing here has an authorization branch -- so no "rls_"
-- prefix, same naming choice as calculate_session_pay.sql.
--
-- Only the LAST statement's result set in each begin/rollback block is
-- what the runner sees, and it must carry the four columns the runner
-- reads: check_name, actual, expected, pass. So every block below ends in
-- exactly one union-all select in that shape.
--
-- Block 3 inserts a group and always rolls back; blocks 1 and 2 only read.
-- Nothing here touches real WOW LAB data.
--
-- Note: public.groups has NO name column -- a group is identified by
-- client + module. The block-3 fixture is therefore marked in `notes`.

-- ============================================================================
-- Block 1: the three live rows are untouched, and no row became custom.
-- ============================================================================
-- The forward migration widened a CHECK constraint and wrote no data. This
-- asserts that literally: the exact three rows 202609210006 set, still
-- holding exactly what it set them to, by id.
begin;
  select 'live row 1 (Lycee, WOW LAB) still scoli_private_recurente' as check_name,
         (select delivery_format from public.groups where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558') as actual,
         'scoli_private_recurente' as expected,
         (select delivery_format from public.groups where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558') = 'scoli_private_recurente' as pass
  union all
  select 'live row 2 (Lycee, WOW LAB) still scoli_private_recurente',
         (select delivery_format from public.groups where id = 'efbe7e46-758e-4634-b9d8-57205ac45576'),
         'scoli_private_recurente',
         (select delivery_format from public.groups where id = 'efbe7e46-758e-4634-b9d8-57205ac45576') = 'scoli_private_recurente'
  union all
  select 'live row 3 (MAX, Test Org B) still parteneriate_companii',
         (select delivery_format from public.groups where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95'),
         'parteneriate_companii',
         (select delivery_format from public.groups where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95') = 'parteneriate_companii'
  union all
  -- Deliberately NOT a global "there are exactly three groups" assertion.
  -- That was the first version and it failed immediately: a fourth group
  -- (Test Org B / MAX / doctor / party_companii) was left behind by an
  -- earlier verification run on 2026-09-25. A total-row-count check
  -- couples this test to unrelated fixture churn and fails for reasons
  -- that have nothing to do with the tenth workshop type. The three rows
  -- this migration must not disturb are asserted by id above, which is the
  -- actual claim.
  select 'no row silently became custom',
         (select count(*)::text from public.groups where delivery_format = 'custom'),
         '0',
         (select count(*) from public.groups where delivery_format = 'custom') = 0;
rollback;

-- ============================================================================
-- Block 2: custom resolves to the STANDARD duration context, not the
-- scoala_altfel_saptamana_verde one.
-- ============================================================================
-- This asserts behaviour the migration does NOT change -- which is exactly
-- why it is worth a test. app.calculate_session_pay (202609250001) calls
-- this resolver, so the duration context is a pay-affecting path now, not
-- the dormant one item 79 measured.
--
-- Asserted by VALUE against the real seeded WOW LAB grids, not by reading
-- the function's source: at 120 minutes standard pays x1.5 and the
-- programme context pays x2.0, so custom returning 1.5 can only have taken
-- the standard branch. The two named programmes are checked alongside as
-- controls -- if the resolver ever stopped distinguishing them at all,
-- custom matching 1.5 would prove nothing, and those controls fail rather
-- than letting this block quietly pass.
--
-- The 30-minute check is the second, independent reason standard is the
-- only correct mapping: 'standard' is seeded with a 30-minute row and
-- 'scoala_altfel_saptamana_verde' is not, so a 30-minute custom workshop
-- mapped to the programme context would RAISE rather than return.
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  set local role authenticated;

  select 'custom @120min resolves to the standard context (x1.5)' as check_name,
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'custom', current_date)::text as actual,
         '1.5' as expected,
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'custom', current_date) = 1.5 as pass
  union all
  select 'CONTROL: scoala_altfel @120min still doubles (x2.0)',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'scoala_altfel', current_date)::text,
         '2.0',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'scoala_altfel', current_date) = 2.0
  union all
  select 'CONTROL: saptamana_verde @120min still doubles (x2.0)',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'saptamana_verde', current_date)::text,
         '2.0',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 120, 'saptamana_verde', current_date) = 2.0
  union all
  select 'custom @30min resolves at all (programme context has no 30min row)',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 30, 'custom', current_date)::text,
         '1.0',
         app.resolve_duration_multiplier((select id from public.organizations where name = 'WOW LAB'), 30, 'custom', current_date) = 1.0;
rollback;

-- ============================================================================
-- Block 3: a group CAN be created with custom, and the constraint still
-- rejects an illegal value.
-- ============================================================================
-- The sabotage check ACTUALLY ATTEMPTS the illegal insert rather than
-- asserting the absence of a row nothing ever inserted. That weaker form --
-- "no row holds an illegal value" -- is an assertion that cannot fail, and
-- item 100's fourth probe error is exactly this mistake, caught one day
-- earlier. Without a real attempt, this block would pass identically if the
-- constraint had been DROPPED rather than widened: "custom is accepted" is
-- not evidence the constraint works, only that it does not reject custom.
begin;
  create temp table sabotage_result (rejected boolean) on commit drop;
  -- Baseline captured rather than hard-coded, for the same reason block 1
  -- drops its total-count check: the number of groups in this shared
  -- database changes for reasons unrelated to this migration.
  create temp table baseline (n bigint) on commit drop;
  insert into baseline select count(*) from public.groups;

  insert into public.groups (organization_id, client_id, module, delivery_format, status, notes)
  select
    o.id,
    (select id from public.clients where organization_id = o.id limit 1),
    'wow_mix',
    'custom',
    'active',
    'ACCEPTANCE TEST -- custom workshop type (rolled back)'
  from public.organizations o
  where o.name = 'WOW LAB';

  -- The real sabotage: a value outside the ten must raise check_violation.
  -- Wrapped in its own subtransaction so the failure is caught rather than
  -- aborting the block.
  do $$
  begin
    begin
      insert into public.groups (organization_id, client_id, module, delivery_format, status, notes)
      select
        o.id,
        (select id from public.clients where organization_id = o.id limit 1),
        'wow_mix',
        'definitely_not_a_real_workshop_type',
        'active',
        'SABOTAGE -- must be rejected (rolled back)'
      from public.organizations o
      where o.name = 'WOW LAB';
      -- Reached only if the constraint FAILED to reject it.
      insert into sabotage_result values (false);
    exception when check_violation then
      insert into sabotage_result values (true);
    end;
  end $$;

  select 'a group can be created with custom' as check_name,
         (select count(*)::text from public.groups where delivery_format = 'custom') as actual,
         '1' as expected,
         (select count(*) from public.groups where delivery_format = 'custom') = 1 as pass
  union all
  select 'the stored value is exactly ''custom''',
         (select delivery_format from public.groups where notes = 'ACCEPTANCE TEST -- custom workshop type (rolled back)'),
         'custom',
         (select delivery_format from public.groups where notes = 'ACCEPTANCE TEST -- custom workshop type (rolled back)') = 'custom'
  union all
  -- NOT named "SABOTAGE:" on purpose. The runner reserves that prefix for
  -- its own mechanism -- it re-runs the block with a deliberate break
  -- applied and requires the check to flip false. This is an inline
  -- negative test of a different kind: it performs the illegal insert
  -- itself and records whether the constraint raised. Naming it SABOTAGE
  -- made the runner apply machinery it does not fit and report "this check
  -- has no teeth" when the check is in fact the one with teeth.
  select 'an invented eleventh value is rejected by the constraint',
         (select rejected::text from sabotage_result),
         'true',
         (select rejected from sabotage_result)
  union all
  select 'exactly one group was added, nothing else changed',
         (select count(*)::text from public.groups),
         ((select n from baseline) + 1)::text,
         (select count(*) from public.groups) = (select n from baseline) + 1;
rollback;
