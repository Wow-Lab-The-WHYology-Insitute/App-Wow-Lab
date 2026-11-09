-- db/tests/session_pay_approval.sql
-- app.rpc_approve_session_pay (202611090002, item 185/186): approval
-- authorizes a confirmed session's pay and freezes the amount; it does
-- not recompute or change it, and it is gated on a CAPABILITY
-- (finance.approvals.approve, held via Operations Manager) rather than
-- on a role -- Cătălina Moale (real: Operations Manager + Trainer) is
-- the worked case, impersonated throughout to prove a trainer can also
-- be the approver.
--
-- Uses WOW LAB's real Avenor client and Teodora/Cătălina trainers
-- (both carry real trainer_grade_assignments rows) -- synthetic groups
-- and sessions, all rolled back.

-- ============================================================================
-- Block 1: Cătălina confirms her own session, then approves it herself --
-- the capability-not-role proof. Operations Manager holds neither
-- finance.operations.* nor finance.reporting.*; only the new capability.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'catalina_moale@yahoo.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.catalina', (select id::text from public.users where email = 'catalina_moale@yahoo.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('ca000000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ca100000-0000-0000-0000-000000000001', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000001', '2026-10-05', current_setting('app.catalina')::uuid, 'delivered', 60, 'bucuresti');

  select app.rpc_confirm_session_attendance('ca100000-0000-0000-0000-000000000001', true);

  create temp table approve_1 as
  select * from app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-000000000001'::uuid]);

  insert into check_results values (
    'Cătălina (Operations Manager, no finance.operations.*) approves her own confirmed session: status approved',
    (select status = 'approved' from approve_1 where slot = 'principal')
  );
  insert into check_results values (
    'the approval amount is positive, not null, not zero',
    (select amount_bani > 0 from approve_1 where slot = 'principal')
  );
  insert into check_results values (
    'the session row now carries the frozen amount and an approved_at timestamp',
    (select trainer_principal_approved_at is not null and trainer_principal_approved_amount_bani > 0
     from public.sessions where id = 'ca100000-0000-0000-0000-000000000001')
  );
  insert into check_results values (
    'row_history records Cătălina herself as the approving actor',
    (select actor_user_id = current_setting('app.catalina')::uuid
     from public.row_history where table_name = 'sessions' and row_id = 'ca100000-0000-0000-0000-000000000001'
     order by changed_at desc limit 1)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: a plain Trainer (Teodora -- no Operations Manager, no finance
-- capability) cannot approve, even her own confirmed session.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'merisanteodora@gmail.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('ca000000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ca100000-0000-0000-0000-000000000002', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000002', '2026-10-05', current_setting('app.teodora')::uuid, 'delivered', 60, 'bucuresti');

  select app.rpc_confirm_session_attendance('ca100000-0000-0000-0000-000000000002', true);

  create temp table approve_2 as
  select * from app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-000000000002'::uuid]);

  insert into check_results values (
    'a plain Trainer, confirmed herself, cannot approve her own pay -- not_permitted',
    (select status = 'not_permitted' and slot is null from approve_2)
  );
  insert into check_results values (
    'the session carries no approval after the refused attempt',
    (select trainer_principal_approved_at is null and trainer_principal_approved_amount_bani is null
     from public.sessions where id = 'ca100000-0000-0000-0000-000000000002')
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 3: bulk, mixed statuses in one array call -- not_confirmed,
-- approved, and already_approved (idempotent, amount unchanged) -- plus
-- a not_found id in the same batch.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'catalina_moale@yahoo.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('ca000000-0000-0000-0000-000000000003', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  -- A: never confirmed. B: confirmed, not yet approved. C: confirmed AND
  -- already approved once, up front, with a KNOWN prior amount.
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values
    ('ca100000-0000-0000-0000-00000000000a', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000003', '2026-10-05', current_setting('app.teodora')::uuid, 'delivered', 60, 'bucuresti'),
    ('ca100000-0000-0000-0000-00000000000b', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000003', '2026-10-12', current_setting('app.teodora')::uuid, 'delivered', 60, 'bucuresti'),
    ('ca100000-0000-0000-0000-00000000000c', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000003', '2026-10-19', current_setting('app.teodora')::uuid, 'delivered', 60, 'bucuresti');

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.teodora')::uuid, 'role', 'authenticated')::text, true);
  select app.rpc_confirm_session_attendance('ca100000-0000-0000-0000-00000000000b', true);
  select app.rpc_confirm_session_attendance('ca100000-0000-0000-0000-00000000000c', true);
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'catalina_moale@yahoo.com'), 'role', 'authenticated')::text,
    true
  );
  select app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-00000000000c'::uuid]);

  create temp table approve_3 as
  select * from app.rpc_approve_session_pay(array[
    'ca100000-0000-0000-0000-00000000000a'::uuid,
    'ca100000-0000-0000-0000-00000000000b'::uuid,
    'ca100000-0000-0000-0000-00000000000c'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid
  ]);

  insert into check_results values (
    'A (never confirmed): not_confirmed, no amount',
    (select status = 'not_confirmed' and amount_bani is null from approve_3 where session_id = 'ca100000-0000-0000-0000-00000000000a')
  );
  insert into check_results values (
    'B (confirmed, unapproved): approved, with a real amount, in the SAME bulk call',
    (select status = 'approved' and amount_bani > 0 from approve_3 where session_id = 'ca100000-0000-0000-0000-00000000000b')
  );
  insert into check_results values (
    'C (already approved before this call): already_approved, same amount as before, not recomputed',
    (select a3.status = 'already_approved' and a3.amount_bani = s.trainer_principal_approved_amount_bani
     from approve_3 a3 join public.sessions s on s.id = a3.session_id
     where a3.session_id = 'ca100000-0000-0000-0000-00000000000c')
  );
  insert into check_results values (
    'an id that does not exist in this batch: not_found, slot null',
    (select status = 'not_found' and slot is null from approve_3 where session_id = '00000000-0000-0000-0000-000000000000')
  );
  insert into check_results values (
    'exactly four rows returned for a four-element array, one per id',
    (select count(*) = 4 from approve_3)
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 4: the freeze survives a grid restatement -- the measurement that
-- decided this design, proven rather than only reasoned about. A rate
-- mutated IN PLACE on the same version_id changes what a fresh
-- calculate_session_pay call returns; the already-approved amount does
-- not move.
-- ============================================================================
begin;
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'catalina_moale@yahoo.com'), 'role', 'authenticated')::text,
    true
  );
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.teodora', (select id::text from public.users where email = 'merisanteodora@gmail.com'), true);
  select set_config('app.avenor_client', (select id::text from public.clients where organization_id = current_setting('app.wow_lab')::uuid and name = 'Scoala Avenor'), true);
  select set_config('app.teodora_version', (
    select tgr.version_id::text from public.trainer_grade_rates tgr
    join public.trainer_grade_assignments tga on tga.grade_level = tgr.grade_level and tga.organization_id = tgr.organization_id
    where tga.trainer_id = (select id from public.users where email = 'merisanteodora@gmail.com')
    limit 1
  ), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('ca000000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, current_setting('app.avenor_client')::uuid, 'gaga', 'parteneriate_companii', 'fr_de_es');

  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('ca100000-0000-0000-0000-000000000004', current_setting('app.wow_lab')::uuid, 'ca000000-0000-0000-0000-000000000004', '2026-10-05', current_setting('app.teodora')::uuid, 'delivered', 60, 'bucuresti');

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.teodora')::uuid, 'role', 'authenticated')::text, true);
  select app.rpc_confirm_session_attendance('ca100000-0000-0000-0000-000000000004', true);
  select set_config(
    'request.jwt.claims',
    json_build_object('sub', (select id from public.users where email = 'catalina_moale@yahoo.com'), 'role', 'authenticated')::text,
    true
  );
  select app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-000000000004'::uuid]);

  -- Restate the rate IN PLACE on the existing version -- same shape as
  -- 202610300001's own UPDATE, doubled here so the drift is unmistakable.
  update public.trainer_grade_rates
    set rate = rate * 2
    where version_id = current_setting('app.teodora_version')::uuid
      and grade_level = (select grade_level from public.trainer_grade_assignments where trainer_id = current_setting('app.teodora')::uuid);

  insert into check_results values (
    'a fresh calculate_session_pay call now returns roughly double -- the restatement DID move the live answer',
    (select app.calculate_session_pay('ca100000-0000-0000-0000-000000000004', current_setting('app.teodora')::uuid)
       > (select trainer_principal_approved_amount_bani / 100.0 * 1.5 from public.sessions where id = 'ca100000-0000-0000-0000-000000000004'))
  );
  insert into check_results values (
    'the already-approved, frozen amount on the session is UNCHANGED by the restatement',
    (select trainer_principal_approved_amount_bani from public.sessions where id = 'ca100000-0000-0000-0000-000000000004')
    =
    (select amount_bani from (select * from app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-000000000004'::uuid]) where slot = 'principal') x)
  );
  insert into check_results values (
    're-running approval on an already-approved session after the restatement still reports already_approved, not a new amount',
    (select status = 'already_approved' from app.rpc_approve_session_pay(array['ca100000-0000-0000-0000-000000000004'::uuid]) where slot = 'principal')
  );

  select check_name, pass from check_results order by check_name;
rollback;
