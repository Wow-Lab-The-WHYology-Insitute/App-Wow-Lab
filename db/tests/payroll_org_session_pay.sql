-- db/tests/payroll_org_session_pay.sql
-- app.calculate_org_session_pay + public.calculate_org_session_pay
-- (202610150003). Not an RLS suite -- neither function has an
-- authorization branch of its own (both SECURITY INVOKER, the caller's
-- own SELECT rights on the pay grids are the gate), so no "rls_" prefix,
-- same naming choice as calculate_session_pay.sql and
-- capability_liveness.sql.
--
-- Takes a date range since 202610160001 ([p_from, p_to_exclusive)), so
-- blocks 1-3 pass a year-wide range and scope their own rows by group_id;
-- block 4 is about the range itself.
--
-- Calls the PUBLIC wrapper throughout, not app.*, because that is what
-- /payroll actually calls through .rpc() -- testing the app function
-- directly would leave the one thing this migration exists for (the
-- schema `app` is not reachable through PostgREST) untested.
--
-- Impersonates anca.tanasescu@gmail.com (platform_owner) throughout: the
-- behavior under test is driven by the DATA, not by who is asking, and a
-- caller who cannot read the finance-gated rate tables would get every
-- row back as a raise regardless of whether the grids are complete --
-- which would make every assertion here pass for the wrong reason. Same
-- reasoning as calculate_session_pay.sql's own header.
--
-- Uses WOW LAB's own real, already-seeded production pay grids (item 95,
-- 202609240001) rather than synthetic values, for two reasons: the
-- rounding rule has to be proved against a real rate that actually
-- produces a third decimal, and the raise-isolation case in block 2 is a
-- REAL gap in the real grid (30 minutes exists for context 'standard'
-- and not for 'scoala_altfel_saptamana_verde'), not a hole dug to be
-- fallen into.
--
-- All fixtures are inserted and read inside transactions that always
-- roll back -- nothing here touches real WOW LAB data, and the real org
-- has no sessions of its own for these to be confused with. Every query
-- is still scoped to the fixture's own group_id, so a real session added
-- later cannot drift these assertions.
--
-- Only the LAST statement's result set in each begin/rollback block is
-- what run_rls_suite.ts sees, so every block ends in exactly one
-- combined select.

-- ============================================================================
-- Block 1: THE ROUNDING RULE. Each workshop row rounds to 2 decimals, and
-- a trainer's total is the sum of the ROUNDED rows -- not the unrounded
-- sum rounded once at the end.
--
-- Grade 3 (Teodora, rate 127) x 1.5 (120 min, standard context) x
-- (1 + 25/100 imprejurimi + 20/100 fr_de_es) = 127 x 1.5 x 1.45 =
-- 276.225 exactly. A third decimal, which is the whole point: 276.225
-- rounds to 276.23, so two such rows total 552.46 -- while the unrounded
-- pair sums to 552.45 and rounding THAT at the end gives 552.45. One ban
-- apart. Anca adds these rows up by hand off the screen to issue the
-- invoice, so the screen's total has to be the one her calculator
-- produces.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('dd000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- Two workshops, same trainer, identical priced inputs. Two rows at
  -- 276.225 is the smallest fixture that can tell the two rounding rules
  -- apart at all.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ee000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000001', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
         ('ee000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000001', '2026-09-28', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi');

  create temp table pay_rows as
  select p.*
  from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-01-01', '2027-01-01') p
  join public.sessions s on s.id = p.session_id
  where s.group_id = 'dd000000-0000-0000-0000-000000000001';

  -- The underlying calculation is still unrounded. This asserts the
  -- rounding introduced by 202610150003 is a display decision taken in
  -- the new function, NOT a change to app.calculate_session_pay, whose
  -- own header refuses to round (444 of 1,456 historical amounts carry
  -- bani).
  insert into check_results values (
    'app.calculate_session_pay itself is still unrounded: 276.225',
    app.calculate_session_pay('ee000000-0000-0000-0000-000000000001', current_setting('app.teodora')::uuid) = 276.225
  );

  insert into check_results values (
    'each workshop row rounds to 2 decimals: 276.225 -> 276.23',
    (select count(*) = 2 and bool_and(amount = 276.23) from pay_rows)
  );

  insert into check_results values (
    'trainer total is the SUM OF ROUNDED rows: 552.46',
    (select sum(amount) = 552.46 from pay_rows)
  );

  -- The discriminating assertion, stated as the negative on purpose: this
  -- is the number the screen would show if the rule were "sum, then
  -- round", and it is the bug this test exists to prevent regressing to.
  insert into check_results values (
    'trainer total is NOT the rounded unrounded-sum: 552.45 is wrong',
    (select sum(amount) <> 552.45 from pay_rows)
  );

  insert into check_results values (
    'no row carries an error when every input is present',
    (select bool_and(reason_code is null and error_text is null) from pay_rows)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: A RAISE ON ONE SLOT DOES NOT TAKE THE MONTH DOWN.
--
-- The real gap, confirmed against the live grid before this was written:
-- duration_multiplier_rates holds 30 minutes for context 'standard' and
-- NOT for 'scoala_altfel_saptamana_verde'. It is reachable -- the
-- workshop form's duration select offers 30, and a group's
-- delivery_format can be scoala_altfel -- so this is a live defect the
-- screen has to survive, not a hypothetical.
--
-- Same trainer, same group, two workshops: one 30-minute (raises) and one
-- 90-minute (127 x 1.2 x 1.45 = 220.98). The 30-minute row must carry a
-- reason, the 90-minute row must still carry its amount, and the
-- trainer's total must be 220.98 rather than null, zero, or an error.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('dd000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'scoala_altfel', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ee000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000002', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', 30, 'imprejurimi'),
         ('ee000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000002', '2026-09-28', current_setting('app.teodora')::uuid, 'planned', 90, 'imprejurimi');

  create temp table pay_rows as
  select p.*
  from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-01-01', '2027-01-01') p
  join public.sessions s on s.id = p.session_id
  where s.group_id = 'dd000000-0000-0000-0000-000000000002';

  -- The call itself has to come back at all. Before this function existed
  -- the only way to ask was one raise-per-call, which aborts the
  -- statement -- the whole month would have been a 500 because of one
  -- 30-minute workshop.
  insert into check_results values (
    'the call returns both rows instead of aborting on the raise',
    (select count(*) = 2 from pay_rows)
  );

  insert into check_results values (
    '30 min + scoala_altfel: amount is null and reason_code is no_duration_row',
    (select amount is null and reason_code = 'no_duration_row'
     from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000003')
  );

  -- The raw message is kept alongside the code, always -- an unmatched
  -- shape would come back as 'unknown' with the real text rather than
  -- vanishing.
  insert into check_results values (
    'the raised message is preserved in error_text, not swallowed',
    (select error_text like '%minutes / context scoala_altfel_saptamana_verde%'
     from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000003')
  );

  insert into check_results values (
    'the other workshop keeps its amount: 220.98',
    (select amount = 220.98 and reason_code is null
     from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000004')
  );

  insert into check_results values (
    'the trainer keeps the total from their calculable workshops: 220.98',
    (select coalesce(sum(amount), 0) = 220.98 from pay_rows where amount is not null)
  );

  insert into check_results values (
    'exactly one workshop is uncalculable, counted by distinct session',
    (select count(distinct session_id) = 1 from pay_rows where amount is null)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 3: the five input gaps each get their own reason_code, so the
-- screen can say which one in plain language rather than printing a raw
-- message with a UUID in it (item 66's rule). One workshop per gap, all
-- on one trainer, all in one call -- which also re-proves the isolation:
-- four raises in a single call and the fifth row still carries money.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.luiza', (select id::text from public.users where email = 'luiza.mirt8@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  -- Two groups: one priced normally, one with no language recorded.
  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('dd000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es'),
         ('dd000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', null);

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values
    -- no duration recorded
    ('ee000000-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', null, 'imprejurimi'),
    -- no location tier recorded
    ('ee000000-0000-0000-0000-000000000006', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', 120, null),
    -- group has no language recorded
    ('ee000000-0000-0000-0000-000000000007', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000004', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
    -- Luiza Mirt has no grade at all (item 95: "grade 3 if she returns")
    ('ee000000-0000-0000-0000-000000000008', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-09-25', current_setting('app.luiza')::uuid, 'planned', 120, 'imprejurimi'),
    -- Dated before 2026-09-01, which is both the earliest grid version AND
    -- the earliest grade assignment in this org. This case asserted
    -- 'no_grade_version' when first written and FAILED: calculate_session_pay
    -- calls resolve_trainer_grade BEFORE resolve_trainer_grade_rate, so the
    -- missing ASSIGNMENT raises first and the missing grid version is never
    -- reached. Kept as the 'no_grade' case it actually is -- a real and
    -- different one from Luiza's (she has no assignment on any date; Teodora
    -- has one, just not this early) -- and the grid-version branch gets its
    -- own fixture below. Caught by running the suite, not by reading the code.
    ('ee000000-0000-0000-0000-000000000009', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-08-31', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
    -- the one that works, in the same call as all five failures
    ('ee000000-0000-0000-0000-00000000000a', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-09-25', current_setting('app.teodora')::uuid, 'planned', 90, 'imprejurimi');

  create temp table pay_rows as
  select p.*
  from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-01-01', '2027-01-01') p
  join public.sessions s on s.id = p.session_id
  where s.group_id in ('dd000000-0000-0000-0000-000000000003', 'dd000000-0000-0000-0000-000000000004');

  insert into check_results values ('reason_code no_duration',
    (select reason_code = 'no_duration' from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000005'));
  insert into check_results values ('reason_code no_location',
    (select reason_code = 'no_location' from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000006'));
  insert into check_results values ('reason_code no_language',
    (select reason_code = 'no_language' from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000007'));
  insert into check_results values ('reason_code no_grade (Luiza, item 95)',
    (select reason_code = 'no_grade' from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000008'));
  insert into check_results values ('reason_code no_grade (graded trainer, date before their first grade)',
    (select reason_code = 'no_grade' from pay_rows where session_id = 'ee000000-0000-0000-0000-000000000009'));

  -- The grid-version branch, which needs a grade that outruns the grid.
  -- Unreachable with today's real data -- every grade assignment and all
  -- four grid versions are effective 2026-09-01, so the assignment can
  -- never be the later of the two. It becomes reachable the moment a grid
  -- version is added with an effective_date after an existing assignment,
  -- which is an ordinary future state (a 2027 grid, nothing backdated). So
  -- the fixture gives Teodora an assignment from 2026-01-01, inside this
  -- rolled-back transaction, and asks for a workshop before the grid
  -- existed: the grade now resolves and the RATE is what is missing.
  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  values (current_setting('app.wow_lab')::uuid, current_setting('app.teodora')::uuid, 3, '2026-01-01',
          (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'manual');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ee000000-0000-0000-0000-00000000000b', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000003', '2026-02-01', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi');

  insert into check_results values (
    'reason_code no_grade_version (grade resolves, no grid version that early)',
    (select p.reason_code = 'no_grade_version'
     from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-01-01', '2027-01-01') p
     where p.session_id = 'ee000000-0000-0000-0000-00000000000b')
  );

  -- Nothing fell through to the catch-all. If a resolver's message is
  -- ever reworded, this is the assertion that fails -- deliberately, and
  -- before the screen starts printing raw SQL at Anka.
  insert into check_results values (
    'no row classified as unknown -- every raise shape is mapped',
    (select count(*) = 0 from pay_rows where reason_code = 'unknown')
  );

  insert into check_results values (
    'the one complete workshop still returns money among five failures: 220.98',
    (select amount = 220.98 from pay_rows where session_id = 'ee000000-0000-0000-0000-00000000000a')
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 4: THE RANGE IS THE SCOPE (202610160001). The function takes
-- [p_from, p_to_exclusive) rather than scanning the whole organization,
-- because /payroll's month now comes from the URL and the plpgsql loop
-- costs ~6 indexed lookups per trainer slot -- org-wide, that grows with
-- the org's history forever to render one month.
--
-- Asserts the three things a range has to get right: it includes p_from,
-- it EXCLUDES p_to_exclusive (the off-by-one that would silently drop the
-- 1st of the next month into the wrong payroll period, or the 31st out of
-- this one), and an inverted range raises rather than returning zero rows
-- -- because zero rows on this screen reads as "nobody is owed anything".
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('dd000000-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- One workshop on each boundary and one in the middle of the month.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values
    ('ef000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000005', '2026-09-30', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
    ('ef000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000005', '2026-10-01', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
    ('ef000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000005', '2026-10-31', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi'),
    ('ef000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, 'dd000000-0000-0000-0000-000000000005', '2026-11-01', current_setting('app.teodora')::uuid, 'planned', 120, 'imprejurimi');

  -- October 2026, exactly as /payroll builds it: first of the month, first
  -- of the next.
  create temp table october as
  select p.session_id
  from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-10-01', '2026-11-01') p
  join public.sessions s on s.id = p.session_id
  where s.group_id = 'dd000000-0000-0000-0000-000000000005';

  insert into check_results values (
    'p_from is INCLUSIVE: the 1st of the month is in',
    (select exists (select 1 from october where session_id = 'ef000000-0000-0000-0000-000000000002'))
  );
  insert into check_results values (
    'the last day of the month is in (31 days, not 30)',
    (select exists (select 1 from october where session_id = 'ef000000-0000-0000-0000-000000000003'))
  );
  insert into check_results values (
    'p_to_exclusive is EXCLUSIVE: the 1st of the NEXT month is out',
    (select not exists (select 1 from october where session_id = 'ef000000-0000-0000-0000-000000000004'))
  );
  insert into check_results values (
    'the last day of the PREVIOUS month is out',
    (select not exists (select 1 from october where session_id = 'ef000000-0000-0000-0000-000000000001'))
  );
  insert into check_results values (
    'exactly the two October workshops are returned, nothing else',
    (select count(*) = 2 from october)
  );

  -- An inverted range refuses. Zero rows would be indistinguishable from a
  -- month with no workshops, which on this screen is a statement about
  -- money.
  do $$
  declare
    v_caught boolean := false;
  begin
    begin
      perform * from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-11-01', '2026-10-01');
    exception when others then
      v_caught := true;
    end;
    insert into check_results values ('an inverted range raises rather than returning zero rows', v_caught);
  end $$;

  do $$
  declare
    v_caught boolean := false;
  begin
    begin
      perform * from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-10-01', '2026-10-01');
    exception when others then
      v_caught := true;
    end;
    insert into check_results values ('an empty range (from = to) raises rather than returning zero rows', v_caught);
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;
