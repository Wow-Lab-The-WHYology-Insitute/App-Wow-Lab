-- db/tests/vet_module.sql
-- Module 14, `vet` (202610070001, item 105). Not an RLS suite -- nothing
-- here has an authorization branch -- so no "rls_" prefix, same naming
-- choice as calculate_session_pay.sql and custom_workshop_type.sql.
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner, and it must carry check_name / actual / expected / pass. So each
-- block ends in exactly one union-all select in that shape.
--
-- Block 2 inserts a group and always rolls back. Nothing here touches real
-- WOW LAB data. public.groups has no `name` column -- a group is identified
-- by client + module -- so the fixture is marked in `notes`.

-- ============================================================================
-- Block 1: the three live groups are untouched, and the taxonomy now has 14.
-- ============================================================================
-- Asserted by id, not by a total row count. A global "there are exactly N
-- groups" check was removed from custom_workshop_type.sql for coupling the
-- test to unrelated fixture churn (item 102); the same reasoning applies here.
begin;
  select 'live group 1 (Lycee, WOW LAB) still wow_mix' as check_name,
         (select module from public.groups where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558') as actual,
         'wow_mix' as expected,
         (select module from public.groups where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558') = 'wow_mix' as pass
  union all
  select 'live group 2 (Lycee, WOW LAB) still wow_mix',
         (select module from public.groups where id = 'efbe7e46-758e-4634-b9d8-57205ac45576'),
         'wow_mix',
         (select module from public.groups where id = 'efbe7e46-758e-4634-b9d8-57205ac45576') = 'wow_mix'
  union all
  select 'live group 3 (MAX, Test Org B) still green_energy',
         (select module from public.groups where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95'),
         'green_energy',
         (select module from public.groups where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95') = 'green_energy'
  union all
  select 'no live group silently became vet',
         (select count(*)::text from public.groups where module = 'vet'),
         '0',
         (select count(*) from public.groups where module = 'vet') = 0
  union all
  select 'public.modules now holds 14 keys',
         (select count(*)::text from public.modules),
         '14',
         (select count(*) from public.modules) = 14
  union all
  select 'vet carries the sibling-matching label',
         (select display_label from public.modules where key = 'vet'),
         'I Wanna Be a Vet',
         (select display_label from public.modules where key = 'vet') = 'I Wanna Be a Vet';
rollback;

-- ============================================================================
-- Block 2: a group CAN be created with vet, and the CHECK still rejects a
-- module that does not exist.
-- ============================================================================
-- The negative half ACTUALLY ATTEMPTS the illegal insert rather than
-- asserting the absence of a row nothing ever inserted -- that weaker form is
-- an assertion that cannot fail (item 100's fourth probe error). Without it,
-- this block would pass identically if groups_module_check had been DROPPED
-- rather than widened: "vet is accepted" is not evidence the constraint
-- works, only that it does not reject vet.
--
-- Deliberately NOT named "SABOTAGE:" -- the runner reserves that prefix for
-- its own re-run-with-a-break mechanism, which this inline negative test does
-- not fit (it reported "this check has no teeth" about exactly such a check
-- in custom_workshop_type.sql's first version).
begin;
  create temp table sabotage_result (rejected boolean) on commit drop;
  create temp table baseline (n bigint) on commit drop;
  insert into baseline select count(*) from public.groups;

  insert into public.groups (organization_id, client_id, module, delivery_format, status, notes)
  select o.id,
         (select id from public.clients where organization_id = o.id limit 1),
         'vet', 'scoli_private_recurente', 'active',
         'ACCEPTANCE TEST -- vet module (rolled back)'
  from public.organizations o where o.name = 'WOW LAB';

  do $$
  begin
    begin
      insert into public.groups (organization_id, client_id, module, delivery_format, status, notes)
      select o.id,
             (select id from public.clients where organization_id = o.id limit 1),
             'definitely_not_a_real_module', 'scoli_private_recurente', 'active',
             'SABOTAGE -- must be rejected (rolled back)'
      from public.organizations o where o.name = 'WOW LAB';
      insert into sabotage_result values (false);   -- reached only if NOT rejected
    exception when check_violation then
      insert into sabotage_result values (true);
    end;
  end $$;

  select 'a group can be created with module vet' as check_name,
         (select count(*)::text from public.groups where module = 'vet') as actual,
         '1' as expected,
         (select count(*) from public.groups where module = 'vet') = 1 as pass
  union all
  select 'the stored value is exactly ''vet''',
         (select module from public.groups where notes = 'ACCEPTANCE TEST -- vet module (rolled back)'),
         'vet',
         (select module from public.groups where notes = 'ACCEPTANCE TEST -- vet module (rolled back)') = 'vet'
  union all
  select 'an invented fifteenth module is rejected by the constraint',
         (select rejected::text from sabotage_result),
         'true',
         (select rejected from sabotage_result)
  union all
  select 'exactly one group was added, nothing else changed',
         (select count(*)::text from public.groups),
         ((select n from baseline) + 1)::text,
         (select count(*) from public.groups) = (select n from baseline) + 1;
rollback;
