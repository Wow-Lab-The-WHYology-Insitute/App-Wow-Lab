-- db/tests/supplier_contracts.sql
-- supplier_contracts (202610120009/202610120010, SAD step 4, item 127).
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner, and it must carry check_name / actual / expected / pass.
--
-- Blocks 2-4 build their own fixtures in WOW LAB Test Org B and roll back.
-- Block 1 reads the real wow-lab import without touching it.

-- ============================================================================
-- Block 1: the 30 imported rows, as they actually landed.
-- ============================================================================
begin;
  select 'the register''s 30 non-trainer rows imported' as check_name,
         (select count(*)::text from public.supplier_contracts) as actual,
         '30' as expected,
         (select count(*) from public.supplier_contracts) = 30 as pass
  union all
  select 'split across the three legal entities 22/5/3',
         (select string_agg(x.n::text, '/' order by x.n desc) from
            (select count(*) n from public.supplier_contracts group by legal_entity_id) x),
         '22/5/3',
         (select string_agg(x.n::text, '/' order by x.n desc) from
            (select count(*) n from public.supplier_contracts group by legal_entity_id) x) = '22/5/3'
  union all
  select 'every row resolved a supplier and an entity',
         (select count(*)::text from public.supplier_contracts
           where supplier_id is null or legal_entity_id is null),
         '0',
         (select count(*) from public.supplier_contracts
           where supplier_id is null or legal_entity_id is null) = 0
  union all
  -- The five `nedeterminat` rows, distinguished from the four other kinds of
  -- absent end date -- which is the whole reason is_open_ended exists.
  select 'five contracts are open-ended, and no open-ended row carries an end date',
         (select count(*)::text from public.supplier_contracts where is_open_ended)
           || '/' ||
         (select count(*)::text from public.supplier_contracts where is_open_ended and period_end is not null),
         '5/0',
         (select count(*) from public.supplier_contracts where is_open_ended) = 5
           and (select count(*) from public.supplier_contracts where is_open_ended and period_end is not null) = 0
  union all
  select 'seven more have no end date for a DIFFERENT reason (N/A, "1 AN", blank)',
         (select count(*)::text from public.supplier_contracts
           where not is_open_ended and period_end is null),
         '7',
         (select count(*) from public.supplier_contracts
           where not is_open_ended and period_end is null) = 7
  union all
  select 'ten rows carry a clean numeric value',
         (select count(*)::text from public.supplier_contracts where contract_value is not null),
         '10',
         (select count(*) from public.supplier_contracts where contract_value is not null) = 10
  union all
  -- The §3.3 deviation, asserted as data: United Media's price is a string
  -- with a currency and must NOT have been coerced into the unitless column.
  select 'United Media''s "1928 EUR" stayed text and did NOT become a value',
         (select coalesce(max(contract_value)::text, 'null') from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id
           where s.name = 'United Media Corporation S.R.L.'),
         'null',
         (select count(*) from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id
           where s.name = 'United Media Corporation S.R.L.' and contract_value is not null) = 0
  union all
  select 'price_text kept ASISMART''s two unexplained rates verbatim',
         (select distinct price_text from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id where s.name = 'ASISMART SRL'),
         '80 RON/ORA, 90 RON/ORA',
         (select count(distinct price_text) from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id
           where s.name = 'ASISMART SRL' and price_text = '80 RON/ORA, 90 RON/ORA') = 1
  union all
  select 'five amendment chains resolved',
         (select count(*)::text from public.supplier_contracts where amends_contract_id is not null),
         '5',
         (select count(*) from public.supplier_contracts where amends_contract_id is not null) = 5
  union all
  -- The reason amends_contract_id exists: without it these are three
  -- contracts, two of them apparently expired.
  select 'Margean''s chain is base + 2 amendments, ending 2026-12-31',
         (select count(*)::text from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id where s.name = 'RALUCA MARGEAN')
           || ' rows, last expiry ' ||
         (select max(period_end)::text from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id where s.name = 'RALUCA MARGEAN'),
         '3 rows, last expiry 2026-12-31',
         (select count(*) from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id where s.name = 'RALUCA MARGEAN') = 3
           and (select max(period_end) from public.supplier_contracts sc
                  join public.suppliers s on s.id = sc.supplier_id
                 where s.name = 'RALUCA MARGEAN') = '2026-12-31'::date
  union all
  select 'no amendment points at itself',
         (select count(*)::text from public.supplier_contracts where amends_contract_id = id),
         '0',
         (select count(*) from public.supplier_contracts where amends_contract_id = id) = 0
  union all
  select 'three real contracts are signed with no recorded date',
         (select count(*)::text from public.supplier_contracts
           where status = 'signed' and signed_date is null),
         '3',
         (select count(*) from public.supplier_contracts
           where status = 'signed' and signed_date is null) = 3
  union all
  -- The nine trainer rows must NOT be here: different table, different write
  -- rule, and trainer_contracts does not exist yet (item 105).
  select 'no trainer contract leaked into this table',
         (select count(*)::text from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id
           where s.name in ('TRUȘAN FLORINA CĂTĂLINA PFA', 'POPA C. RALUCA-MARIA-DIETETICIAN',
                            'MERIȘAN IOANA-TEODORA PFA')),
         '0',
         (select count(*) from public.supplier_contracts sc
            join public.suppliers s on s.id = sc.supplier_id
           where s.name in ('TRUȘAN FLORINA CĂTĂLINA PFA', 'POPA C. RALUCA-MARIA-DIETETICIAN',
                            'MERIȘAN IOANA-TEODORA PFA')) = 0;
rollback;

-- ============================================================================
-- Block 2: the four CHECK constraints. Each one ATTEMPTS the illegal write.
-- ============================================================================
begin;
  create temp table r (what text, ok boolean) on commit drop;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_sup uuid; v_ent uuid; v_row uuid;
  begin
    select id into v_ent from public.legal_entities where organization_id = v_org limit 1;
    insert into public.suppliers (organization_id, name, status)
    values (v_org, 'DRYRUN supplier (supplier_contracts checks)', 'active') returning id into v_sup;
    insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status)
    values (v_org, v_sup, v_ent, 'draft') returning id into v_row;

    begin
      insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status, signed_date)
      values (v_org, v_sup, v_ent, 'draft', current_date);
      insert into r values ('signed_date_needs_signed_status', false);
    exception when check_violation then insert into r values ('signed_date_needs_signed_status', true); end;

    begin
      insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status, is_open_ended, period_end)
      values (v_org, v_sup, v_ent, 'signed', true, current_date);
      insert into r values ('open_ended_cannot_have_end', false);
    exception when check_violation then insert into r values ('open_ended_cannot_have_end', true); end;

    begin
      update public.supplier_contracts set amends_contract_id = v_row where id = v_row;
      insert into r values ('no_self_amend', false);
    exception when check_violation then insert into r values ('no_self_amend', true); end;

    begin
      insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status)
      values (v_org, v_sup, v_ent, 'countersigned-ish');
      insert into r values ('status_vocabulary', false);
    exception when check_violation then insert into r values ('status_vocabulary', true); end;

    -- The permitted asymmetry, asserted so nobody "fixes" it: a signed
    -- contract whose date nobody recorded is three real register rows.
    begin
      insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status, signed_date)
      values (v_org, v_sup, v_ent, 'signed', null);
      insert into r values ('signed_without_date_allowed', true);
    exception when check_violation then insert into r values ('signed_without_date_allowed', false); end;
  end $$;

  select 'a signing date on a draft is rejected' as check_name,
         (select ok::text from r where what='signed_date_needs_signed_status') as actual, 'true' as expected,
         (select ok from r where what='signed_date_needs_signed_status') as pass
  union all
  select 'open-ended with an end date is rejected',
         (select ok::text from r where what='open_ended_cannot_have_end'), 'true',
         (select ok from r where what='open_ended_cannot_have_end')
  union all
  select 'a contract cannot amend itself',
         (select ok::text from r where what='no_self_amend'), 'true',
         (select ok from r where what='no_self_amend')
  union all
  select 'an invented status is rejected',
         (select ok::text from r where what='status_vocabulary'), 'true',
         (select ok from r where what='status_vocabulary')
  union all
  select 'signed with NO date is allowed, on purpose',
         (select ok::text from r where what='signed_without_date_allowed'), 'true',
         (select ok from r where what='signed_without_date_allowed');
rollback;

-- ============================================================================
-- Block 3: who can read it. finance.reporting.* and the owner, nobody else --
-- and Laura's capability is the one that must NOT work.
-- ============================================================================
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_sup uuid; v_ent uuid;
    v_owner uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
    v_fin_ops uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev');
    v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
    v_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  begin
    select id into v_ent from public.legal_entities where organization_id = v_org limit 1;
    insert into public.suppliers (organization_id, name, status)
    values (v_org, 'DRYRUN supplier (supplier_contracts rls)', 'active') returning id into v_sup;
    insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status, contract_value, price_text)
    values (v_org, v_sup, v_ent, 'signed', 4242, 'DRYRUN 80 RON/ORA');

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role','authenticated')::text, true);
    insert into r select 'owner', count(*)::text from public.supplier_contracts where organization_id = v_org;

    perform set_config('request.jwt.claims', json_build_object('sub', v_fin_ops::text, 'role','authenticated')::text, true);
    insert into r select 'finance_operations', count(*)::text from public.supplier_contracts where organization_id = v_org;
    insert into r select 'finance_operations_has_cap',
      app.has_capability('finance.operations.*', v_org)::text;
    insert into r select 'finance_operations_lacks_reporting',
      (not app.has_capability('finance.reporting.*', v_org))::text;

    perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role','authenticated')::text, true);
    insert into r select 'operations_manager', count(*)::text from public.supplier_contracts where organization_id = v_org;

    perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role','authenticated')::text, true);
    insert into r select 'trainer', count(*)::text from public.supplier_contracts where organization_id = v_org;
  end $$;

  select 'the org owner reads supplier contracts' as check_name,
         (select val from r where what='owner') as actual, '1' as expected,
         (select val from r where what='owner') = '1' as pass
  union all
  -- SAD §5/§7: Laura does not see supplier contracts AT ALL, so not their
  -- values either. The two control rows below prove the account really does
  -- hold finance.operations.* and really does lack finance.reporting.* --
  -- without them, "sees 0 rows" could just mean a mis-specified fixture.
  select 'a finance.operations.*-only account reads NOTHING',
         (select val from r where what='finance_operations'), '0',
         (select val from r where what='finance_operations') = '0'
  union all
  select 'CONTROL: that account does hold finance.operations.*',
         (select val from r where what='finance_operations_has_cap'), 'true',
         (select val from r where what='finance_operations_has_cap') = 'true'
  union all
  select 'CONTROL: and does not hold finance.reporting.*',
         (select val from r where what='finance_operations_lacks_reporting'), 'true',
         (select val from r where what='finance_operations_lacks_reporting') = 'true'
  union all
  select 'an operations_manager reads nothing',
         (select val from r where what='operations_manager'), '0',
         (select val from r where what='operations_manager') = '0'
  union all
  select 'a trainer reads nothing',
         (select val from r where what='trainer'), '0',
         (select val from r where what='trainer') = '0';
rollback;

-- ============================================================================
-- Block 4: SABOTAGE. Add finance.operations.* to the policy and Laura's
-- "reads NOTHING" assertion must flip.
-- ============================================================================
-- Without this, block 3 would pass identically if the policy were
-- `using (false)` for everyone but the owner, or if the fixture simply had no
-- rows -- "she sees zero" is not evidence that the branch excluding her is the
-- thing doing the excluding.
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_sup uuid; v_ent uuid;
    v_fin_ops uuid := (select id from public.users where email = 'test+ui-contract-admin-b@wowlab.dev');
  begin
    drop policy "authenticated select supplier_contracts" on public.supplier_contracts;
    create policy "authenticated select supplier_contracts" on public.supplier_contracts
      for select to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('finance.reporting.*', organization_id)
        or app.has_capability('finance.operations.*', organization_id)   -- the sabotage
      );

    select id into v_ent from public.legal_entities where organization_id = v_org limit 1;
    insert into public.suppliers (organization_id, name, status)
    values (v_org, 'DRYRUN supplier (supplier_contracts sabotage)', 'active') returning id into v_sup;
    insert into public.supplier_contracts (organization_id, supplier_id, legal_entity_id, status, contract_value)
    values (v_org, v_sup, v_ent, 'signed', 4242);

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_fin_ops::text, 'role','authenticated')::text, true);
    insert into r select 'finance_operations', count(*)::text from public.supplier_contracts where organization_id = v_org;
  end $$;

  select 'SABOTAGE: a finance.operations.*-only account reads NOTHING, same assertion as block 3, finance.operations.* added to the SELECT policy' as check_name,
         (select val from r where what='finance_operations') as actual, '0' as expected,
         (select val from r where what='finance_operations') = '0' as pass;
rollback;

-- ============================================================================
-- Block 5: no exit_number carries the spreadsheet's ".0" (202610130002).
-- ============================================================================
-- Thirteen of the thirty rows arrived as "83.0", "5881.0" and the like --
-- Excel reading a contract number as a float. The migration stripped the
-- suffix on exactly the rows whose whole value was digits-then-".0".
--
-- Asserted against the WHOLE table and not against those thirteen ids,
-- because the thing worth guarding is not "the migration ran" but "no number
-- in this column has a decimal part", which is also true of every row added
-- after it. The eleven values that were deliberately left alone are checked
-- by name on the other side: a test that only demanded the absence of ".0"
-- would be satisfied by a migration that had destroyed '1/15.01.2026' too.
begin;
  select 'no exit_number ends in the float suffix ".0"' as check_name,
         (select count(*)::text from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$') as actual,
         '0' as expected,
         (select count(*) from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$') = 0 as pass
  union all
  -- Nothing at all, not just the fully-numeric shape: catches a later import
  -- of "ANEXA 2.0" or "1/15.01.2026.0", which the anchored pattern above
  -- would miss.
  select 'nor does any exit_number end in ".0" in any other shape',
         (select count(*)::text from public.supplier_contracts where exit_number like '%.0'),
         '0',
         (select count(*) from public.supplier_contracts where exit_number like '%.0') = 0
  union all
  -- The other half: the values that were supposed to survive, did. A slash
  -- followed by a date is exactly what a `like '%.0'` cleanup would have
  -- truncated, so it is named here rather than left to the count above.
  select 'the eleven non-numeric exit_numbers were left intact',
         (select count(*)::text from public.supplier_contracts
           where exit_number in ('N/A', 'ANEXA 2', '1/15.01.2026', '2388738/14.09.2025',
                                 '2388729/05.01.2026', 'Act aditional 1', 'Act aditional 2',
                                 'ACT ADITIONAL 1/ 5881 din 01.07.2025',
                                 'Act aditional 03 la contract 10/10/2022 din 10.10.2022',
                                 'Act aditional 03 la contract 18/11/2022 din 18.11.2022')),
         '10',
         (select count(*) from public.supplier_contracts
           where exit_number in ('N/A', 'ANEXA 2', '1/15.01.2026', '2388738/14.09.2025',
                                 '2388729/05.01.2026', 'Act aditional 1', 'Act aditional 2',
                                 'ACT ADITIONAL 1/ 5881 din 01.07.2025',
                                 'Act aditional 03 la contract 10/10/2022 din 10.10.2022',
                                 'Act aditional 03 la contract 18/11/2022 din 18.11.2022')) = 10
  union all
  select 'the thirteen cleaned numbers are present in their bare form',
         (select count(*)::text from public.supplier_contracts
           where exit_number in ('4','8','9','23','83','112','152','512','2626','5881','155420','1311175','2388729')),
         '13',
         (select count(*) from public.supplier_contracts
           where exit_number in ('4','8','9','23','83','112','152','512','2626','5881','155420','1311175','2388729')) = 13;
rollback;

-- ============================================================================
-- Block 6: SABOTAGE -- put one ".0" back and block 5's first check must fail.
-- ============================================================================
begin;
  update public.supplier_contracts set exit_number = '83.0'
   where exit_number = '83';

  select 'SABOTAGE: one exit_number is "83.0" again, same assertion as block 5' as check_name,
         (select count(*)::text from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$') as actual,
         '0' as expected,
         (select count(*) from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$') = 0 as pass;
rollback;
