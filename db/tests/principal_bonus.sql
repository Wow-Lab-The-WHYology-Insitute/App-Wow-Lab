-- db/tests/principal_bonus.sql
-- app.calculate_org_principal_bonus (B2, Anca 2026-10-29, item 175):
-- 20 lei per (trainer_principal_id, session_date, client_id) where that
-- trainer held the principal slot on at least one payable workshop that
-- day at that school WITH a secundar staffed.
--
-- Not an RLS suite -- SECURITY INVOKER / STABLE, no authorization branch
-- of its own, same reasoning as calculate_session_pay.sql's own header.
-- Impersonates anca.tanasescu@gmail.com (platform_owner) throughout.
--
-- Uses WOW LAB's real Avenor and Lycée clients/groups as the two
-- "schools" for the multi-school case -- real clients, synthetic
-- groups/sessions, all rolled back.

-- ============================================================================
-- Block 1: the worked case Anca's own examples are built on -- one day, one
-- school, SOME workshops with a secundar and some without. Still exactly
-- ONE bonus (the mixed-day case Mihai accepted 2026-10-30), not one per
-- qualifying session and not zero.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.alexandra', (select id::text from public.users where email = 'alexandra.nutu2010@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('bb000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- Teodora principal all day; Alexandra secundar on two of the three.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values
    ('bc000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000001', '2026-10-19', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'planned', 60, 'bucuresti'),
    ('bc000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000001', '2026-10-19', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'planned', 60, 'bucuresti'),
    ('bc000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000001', '2026-10-19', current_setting('app.teodora')::uuid, null, 'planned', 60, 'bucuresti');

  create temp table bonus_rows as
  select * from public.calculate_org_principal_bonus(current_setting('app.wow_lab')::uuid, '2026-10-19', '2026-10-20')
  where trainer_id = current_setting('app.teodora')::uuid;

  insert into check_results values (
    'mixed day (2 of 3 workshops have a secundar): exactly ONE bonus row, not one per session',
    (select count(*) = 1 from bonus_rows)
  );
  insert into check_results values (
    'the bonus is 20.00',
    (select amount = 20.00 from bonus_rows limit 1)
  );
  insert into check_results values (
    'dated and scoped to the right day and school',
    (select bonus_date = '2026-10-19' and client_id = current_setting('app.avenor_client')::uuid from bonus_rows limit 1)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: two schools, same day, same trainer -> 40, not 20. Two days,
-- same school -> 40, not 20. And zero secundar anywhere -> zero rows.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.alexandra', (select id::text from public.users where email = 'alexandra.nutu2010@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);
  select set_config('app.lycee_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name ilike '%Lycee%'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values
    ('bb000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es'),
    ('bb000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, current_setting('app.lycee_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- Same trainer, same day (2026-10-20), two different schools.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier)
  values
    ('bc000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000002', '2026-10-20', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'planned', 60, 'bucuresti'),
    ('bc000000-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000003', '2026-10-20', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'planned', 60, 'bucuresti'),
  -- Same trainer, same school (Avenor), a DIFFERENT day (2026-10-21).
    ('bc000000-0000-0000-0000-000000000006', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000002', '2026-10-21', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'planned', 60, 'bucuresti');

  create temp table bonus_rows as
  select * from public.calculate_org_principal_bonus(current_setting('app.wow_lab')::uuid, '2026-10-20', '2026-10-22')
  where trainer_id = current_setting('app.teodora')::uuid;

  insert into check_results values (
    'two schools, one day: two bonus rows (40 total), not one',
    (select count(*) filter (where bonus_date = '2026-10-20') = 2 from bonus_rows)
  );
  insert into check_results values (
    'one school, two days: two bonus rows total across the range (40), not one',
    (select count(*) filter (where client_id = current_setting('app.avenor_client')::uuid) = 2 from bonus_rows)
  );
  insert into check_results values (
    'three bonus rows total, 60.00 altogether',
    (select count(*) = 3 and sum(amount) = 60.00 from bonus_rows)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 3: cancellation payability mirrors calculate_session_pay's own
-- rule exactly -- a cancelled-and-not-neanuntat workshop does not trigger
-- the bonus even with a secundar staffed; a neanuntat one still does.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'anca.tanasescu@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.alexandra', (select id::text from public.users where email = 'alexandra.nutu2010@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('bb000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, trainer_secundar_id, status, duration_minutes, location_tier, cancellation_category, cancelled_at, cancelled_by)
  values
    -- vacanta: not payable, must not trigger the bonus either.
    ('bc000000-0000-0000-0000-000000000007', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000004', '2026-10-22', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'cancelled', 60, 'bucuresti', 'vacanta', now(), current_setting('app.teodora')::uuid),
    -- scoala_a_anulat_neanuntat: still payable, still triggers the bonus.
    ('bc000000-0000-0000-0000-000000000008', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000004', '2026-10-23', current_setting('app.teodora')::uuid, current_setting('app.alexandra')::uuid, 'cancelled', 60, 'bucuresti', 'scoala_a_anulat_neanuntat', now(), current_setting('app.teodora')::uuid);

  create temp table bonus_rows as
  select * from public.calculate_org_principal_bonus(current_setting('app.wow_lab')::uuid, '2026-10-22', '2026-10-24')
  where trainer_id = current_setting('app.teodora')::uuid;

  insert into check_results values (
    'vacanta (not payable) with a secundar staffed: no bonus for that day',
    (select not exists (select 1 from bonus_rows where bonus_date = '2026-10-22'))
  );
  insert into check_results values (
    'scoala_a_anulat_neanuntat (still payable) with a secundar staffed: bonus still fires',
    (select exists (select 1 from bonus_rows where bonus_date = '2026-10-23'))
  );
  insert into check_results values (
    'exactly one bonus row survives (the neanuntat day only)',
    (select count(*) = 1 from bonus_rows)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 4: no secundar anywhere -> zero rows. The common case, asserted
-- directly rather than only implied by the other blocks.
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
  values ('bb000000-0000-0000-0000-000000000005', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('bc000000-0000-0000-0000-000000000009', current_setting('app.wow_lab')::uuid, 'bb000000-0000-0000-0000-000000000005', '2026-10-24', current_setting('app.teodora')::uuid, 'planned', 60, 'bucuresti');

  insert into check_results values (
    'solo workshop, no secundar: zero bonus rows',
    (select count(*) = 0 from public.calculate_org_principal_bonus(current_setting('app.wow_lab')::uuid, '2026-10-24', '2026-10-25') where trainer_id = current_setting('app.teodora')::uuid)
  );

  select check_name, pass from check_results order by check_name;
rollback;
