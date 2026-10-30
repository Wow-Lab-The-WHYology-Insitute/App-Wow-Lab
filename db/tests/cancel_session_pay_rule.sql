-- db/tests/cancel_session_pay_rule.sql
-- app.rpc_cancel_session + the pay rule it drives (202610200003).
--
-- Not an RLS suite in the usual sense, but it DOES exercise the gate, since
-- "Operations and not the trainer" is half the decision. Impersonates a
-- different real user per check for exactly that reason -- unlike
-- calculate_session_pay.sql, where the behaviour under test is driven by
-- arguments rather than by who is asking.
--
-- THE RULE UNDER TEST, in one line:
--     payable = confirmed OR (cancelled AND reason = scoala_a_anulat_neanuntat)
-- and a cancelled workshop that is NOT payable returns 0 with NO
-- reason_code -- a decided zero, not a failure.
--
-- Fixtures roll back. Uses WOW LAB's real grids and real people.

-- ============================================================================
-- Block 1: the pay rule across all five categories, plus the decided zero.
-- ============================================================================
begin;
  select set_config('request.jwt.claims', json_build_object('sub',
    (select id from public.users where email='anca.tanasescu@gmail.com'), 'role','authenticated')::text, true);
  select set_config('app.wow_lab', (select id::text from public.organizations where slug='wow-lab'), true);
  select set_config('app.cat', (select id::text from public.users where email='catalina_moale@yahoo.com'), true);
  select set_config('app.client', (select id::text from public.clients where organization_id=current_setting('app.wow_lab')::uuid and name='Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('fa000000-0000-0000-0000-00000000000f', current_setting('app.wow_lab')::uuid,
          current_setting('app.client')::uuid, 'wow_mix', 'scoli_private_recurente', 'fr_de_es');

  -- Six identical workshops: one left alone, five cancelled one per category.
  -- Catalina grade 6 (150, restated 2026-10-30 per item 147/202610300001)
  -- x 1.2 (90 min) x 1.45 (imprejurimi + fr_de_es) = 261.00
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  select ('fb000000-0000-0000-0000-00000000000' || n)::uuid, current_setting('app.wow_lab')::uuid,
         'fa000000-0000-0000-0000-00000000000f', '2026-09-25', current_setting('app.cat')::uuid,
         'delivered', 90, 'imprejurimi'
  from generate_series(1,6) n;

  insert into check_results values (
    'baseline: an uncancelled workshop pays 261.00',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000001', current_setting('app.cat')::uuid) = 261.00
  );

  -- Cancel five, one per category, through the RPC.
  create temp table rpc_out (cat text, result text);
  do $$
  declare r record; res text; begin
    for r in select * from (values
        ('fb000000-0000-0000-0000-000000000002','scoala_a_anulat_anuntat', null),
        ('fb000000-0000-0000-0000-000000000003','scoala_a_anulat_neanuntat', null),
        ('fb000000-0000-0000-0000-000000000004','trainer_indisponibil', null),
        ('fb000000-0000-0000-0000-000000000005','vacanta', null),
        ('fb000000-0000-0000-0000-000000000006','alt_motiv','zi scurta anuntata telefonic')
      ) as t(sid, cat, note) loop
      select app.rpc_cancel_session(r.sid::uuid, r.cat, r.note) into res;
      insert into rpc_out values (r.cat, res);
    end loop;
  end $$;

  insert into check_results values (
    'all five categories accepted by the RPC',
    (select count(*) = 5 and bool_and(result = 'ok') from rpc_out)
  );

  -- THE RULE. Only scoala_a_anulat_neanuntat still pays.
  insert into check_results values (
    'scoala_a_anulat_anuntat -> decided zero',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000002', current_setting('app.cat')::uuid) = 0
  );
  insert into check_results values (
    'scoala_a_anulat_NEANUNTAT -> STILL PAID 261.00 (trainer travelled, empty room)',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000003', current_setting('app.cat')::uuid) = 261.00
  );
  insert into check_results values (
    'trainer_indisponibil -> decided zero',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000004', current_setting('app.cat')::uuid) = 0
  );
  insert into check_results values (
    'vacanta -> decided zero',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000005', current_setting('app.cat')::uuid) = 0
  );
  insert into check_results values (
    'alt_motiv -> decided zero (pay decided by hand)',
    app.calculate_session_pay('fb000000-0000-0000-0000-000000000006', current_setting('app.cat')::uuid) = 0
  );

  -- A decided zero carries NO reason_code. That is the whole distinction:
  -- reason_code means "could not compute", 0 means "computed, and nothing".
  insert into check_results values (
    'a decided zero has amount = 0 and reason_code IS NULL, never a reason',
    (select count(*) = 4 and bool_and(amount = 0 and reason_code is null)
     from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid, '2026-09-01', '2026-10-01') p
     join public.sessions s on s.id = p.session_id
     where s.group_id = 'fa000000-0000-0000-0000-00000000000f'
       and s.cancellation_category in ('scoala_a_anulat_anuntat','trainer_indisponibil','vacanta','alt_motiv'))
  );

  -- The confirmation columns are untouched by cancelling. If cancellation
  -- had been implemented by writing them, this is what would have broken.
  insert into check_results values (
    'cancelling writes NO confirmation timestamp',
    (select bool_and(trainer_principal_confirmed_at is null and trainer_secundar_confirmed_at is null)
     from public.sessions where group_id = 'fa000000-0000-0000-0000-00000000000f')
  );

  -- alt_motiv without a note is refused; the category is what makes
  -- cancellations countable and an uncategorised one would defeat it.
  do $$
  declare res text; begin
    select app.rpc_cancel_session('fb000000-0000-0000-0000-000000000001', 'alt_motiv', '   ') into res;
    insert into check_results values ('alt_motiv with a blank note is refused: note_required', res = 'note_required');
    select app.rpc_cancel_session('fb000000-0000-0000-0000-000000000001', 'scoala_a_anulat', null) into res;
    insert into check_results values ('the OLD four-value category is now rejected: invalid_category', res = 'invalid_category');
    select app.rpc_cancel_session('fb000000-0000-0000-0000-000000000002', 'vacanta', null) into res;
    insert into check_results values ('cancelling twice is refused: already_cancelled', res = 'already_cancelled');
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 2: the gate. Operations yes, the trainer no, Finance no.
-- ============================================================================
begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug='wow-lab'), true);
  select set_config('app.cat', (select id::text from public.users where email='catalina_moale@yahoo.com'), true);
  select set_config('app.client', (select id::text from public.clients where organization_id=current_setting('app.wow_lab')::uuid and name='Scoala Avenor'), true);

  create temp table check_results (check_name text, pass boolean);

  insert into public.groups (id, organization_id, client_id, module, delivery_format, language_group)
  values ('fa000000-0000-0000-0000-00000000000e', current_setting('app.wow_lab')::uuid,
          current_setting('app.client')::uuid, 'wow_mix', 'scoli_private_recurente', 'ro_en');
  insert into public.sessions (id, organization_id, group_id, session_date, trainer_principal_id, status, duration_minutes, location_tier)
  values ('fc000000-0000-0000-0000-00000000000a', current_setting('app.wow_lab')::uuid,
          'fa000000-0000-0000-0000-00000000000e', '2026-09-25', current_setting('app.cat')::uuid,
          'delivered', 90, 'imprejurimi');

  -- Alina Garofil holds only Trainer. She must NOT be able to cancel, even
  -- though a trainer CAN confirm -- the asymmetry is the decision.
  do $$
  declare res text; begin
    perform set_config('request.jwt.claims', json_build_object('sub',
      (select id from public.users where email='alina.garofil@outlook.com'), 'role','authenticated')::text, true);
    select app.rpc_cancel_session('fc000000-0000-0000-0000-00000000000a', 'vacanta', null) into res;
    insert into check_results values ('a Trainer is REFUSED: not_permitted', res = 'not_permitted');
  end $$;

  -- LAURA MOALE, not Anka Orban: finance.operations.* is deliberately absent
  -- from the gate, and Laura is the person who actually holds it WITHOUT
  -- sessions.create (Contract Administrator + Finance Operations). The first
  -- draft of this test used Anka and failed -- she also holds Operations
  -- Manager, so she has sessions.create and legitimately succeeds. The test
  -- was wrong about the person, not the gate; and because her cancellation
  -- went through, the two checks after it then failed on a session that was
  -- already cancelled. Picking the subject by measured capability rather
  -- than by job title is the fix.
  do $$
  declare res text; begin
    perform set_config('request.jwt.claims', json_build_object('sub',
      (select id from public.users where email='lauraflorentinaa220@gmail.com'), 'role','authenticated')::text, true);
    select app.rpc_cancel_session('fc000000-0000-0000-0000-00000000000a', 'vacanta', null) into res;
    insert into check_results values ('Finance Operations WITHOUT sessions.create is REFUSED: not_permitted', res = 'not_permitted');
  end $$;

  -- And the converse, stated because it is surprising: Anka Orban CAN
  -- cancel -- not through finance.operations.* but because she also holds
  -- Operations Manager. The gate is doing what it was designed to do; her
  -- role set is the thing item 142 is about.
  insert into check_results values (
    'Anka can cancel via Operations Manager, not via Finance (role sprawl, item 142)',
    (select bool_or(exists(select 1 from public.role_capabilities rc
                           join public.capabilities c on c.id=rc.capability_id
                           where rc.role_id=r.id and c.key='sessions.create'))
     from public.user_org_roles uor join public.roles r on r.id=uor.role_id
     join public.organizations o on o.id=uor.organization_id
     where o.slug='wow-lab' and uor.user_id=(select id from public.users where email='anka@asismart.ro'))
  );

  -- Catalina holds Operations Manager -> sessions.create.
  do $$
  declare res text; begin
    perform set_config('request.jwt.claims', json_build_object('sub',
      (select id from public.users where email='catalina_moale@yahoo.com'), 'role','authenticated')::text, true);
    select app.rpc_cancel_session('fc000000-0000-0000-0000-00000000000a', 'vacanta', null) into res;
    insert into check_results values ('Operations (sessions.create) SUCCEEDS: ok', res = 'ok');
  end $$;

  insert into check_results values (
    'the cancellation recorded its actor and timestamp',
    (select cancelled_by = current_setting('app.cat')::uuid and cancelled_at is not null
     from public.sessions where id = 'fc000000-0000-0000-0000-00000000000a')
  );

  select check_name, pass from check_results order by check_name;
rollback;

-- ============================================================================
-- Block 3: a cancellation inside a CLOSED month is permitted AND visible.
--
-- app.rpc_cancel_session has no month-closed gate, deliberately: that gate
-- exists on app.rpc_confirm_session_attendance because CONFIRMATION IS A PAY
-- INPUT, and cancellation is not. But cancelling inside a closed month
-- changes the CLIENT billing count for a month already invoiced, so it must
-- be VISIBLE rather than merely allowed -- which is /payroll's closed-months
-- list saying so (item 155).
--
-- This block asserts the query behind that line, including the distinction
-- the line depends on: a cancellation BEFORE the close is ordinary (the
-- closer saw it) and must NOT be counted.
--
-- A note on how this check was first written wrong, kept because the lesson
-- is the same one item 142 records: it picked its sessions with `limit 1` on
-- a date that carries four workshops (Avenor x2 + Scoala Germana x2) and no
-- ORDER BY, so it silently selected an Avenor row at 168.75 while the
-- expectation was hardcoded at Teodora's 114.00. The code was right and the
-- fixture was arbitrary. Rows are now pinned by group id, and the money
-- assertion is COMPUTED from the rows it cancelled rather than written as a
-- literal -- a test that hardcodes an amount it did not measure is asserting
-- its author's arithmetic, not the system's.
-- ============================================================================
begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug='wow-lab'), true);
  select set_config('app.cat', (select id::text from public.users where email='catalina_moale@yahoo.com'), true);

  create temp table check_results (check_name text, pass boolean);

  -- September closed on 1 October, by Anka -- ON CONFLICT DO NOTHING
  -- because September is, as of 2026-10-30, ALSO really closed in wow-lab
  -- for real (B1's own finding: closing protects nothing about the
  -- figures, but the payroll_periods row itself is real). The assertions
  -- below all read pp.closed_at back from the table rather than assuming
  -- this literal, so either the real row or this fixture's own serves
  -- them identically.
  insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
  values (current_setting('app.wow_lab')::uuid, '2026-09-01', '2026-10-01 09:00:00+00',
          (select id from public.users where email='anka@asismart.ro'))
  on conflict (organization_id, period) do nothing;

  -- Two real imported workshops on one Scoala Germana group, pinned.
  create temp table picked as
  select s.id, p.amount as before_amount
  from public.sessions s
  join public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid,'2026-09-01','2026-10-01') p
       on p.session_id = s.id
  where s.organization_id = current_setting('app.wow_lab')::uuid
    and s.group_id = 'c1000000-0000-0000-0000-0000000000b1'
    and s.session_date in ('2026-09-09','2026-09-16');

  insert into check_results values ('fixture: two workshops pinned on one group',
    (select count(*) = 2 from picked));

  select set_config('app.before_total',
    (select sum(p.amount)::text from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid,'2026-09-01','2026-10-01') p), true);

  -- Cancel both as Operations. The first is backdated to BEFORE the close.
  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.cat'), 'role','authenticated')::text, true);
  do $$
  declare rec record; res text; n int := 0; begin
    for rec in select id from picked order by id loop
      n := n + 1;
      select app.rpc_cancel_session(rec.id,
        case when n = 1 then 'vacanta' else 'scoala_a_anulat_anuntat' end, null) into res;
      if res <> 'ok' then raise exception 'cancel failed: %', res; end if;
      if n = 1 then
        update public.sessions set cancelled_at = '2026-09-20 10:00:00+00' where id = rec.id;
      end if;
    end loop;
  end $$;

  insert into check_results values (
    'cancelling inside a closed month is PERMITTED -- no month gate',
    (select count(*) = 2 from public.sessions where id in (select id from picked) and status = 'cancelled')
  );

  -- THE GUARD: exactly one is late, and it is the one cancelled after the close.
  insert into check_results values (
    'exactly 1 LATE cancellation is detected for the closed month',
    (select count(*) = 1
     from public.sessions s, public.payroll_periods pp
     where s.organization_id = current_setting('app.wow_lab')::uuid
       and pp.organization_id = s.organization_id
       and pp.period = '2026-09-01' and pp.closed_at is not null
       and s.status = 'cancelled' and s.cancelled_at is not null
       and to_char(s.session_date,'YYYY-MM') = to_char(pp.period,'YYYY-MM')
       and s.cancelled_at > pp.closed_at)
  );

  -- Found 2026-10-30: this query was missing the session-month filter its
  -- own sibling above (the LATE check) already has, and it had no reason
  -- to matter until real cancelled rows existed outside September --
  -- 202610200005/202610200007's six real October holiday-week cancellations
  -- all carry cancelled_at before this fixture's September close, so an
  -- unscoped "any cancelled session before the close" count caught them
  -- too (7, not 1). Scoped to September-dated sessions now, matching the
  -- LATE check exactly.
  insert into check_results values (
    'a cancellation BEFORE the close is NOT counted as late',
    (select count(*) = 1
     from public.sessions s, public.payroll_periods pp
     where s.organization_id = current_setting('app.wow_lab')::uuid
       and pp.organization_id = s.organization_id and pp.period = '2026-09-01'
       and s.status = 'cancelled' and s.cancelled_at <= pp.closed_at
       and to_char(s.session_date,'YYYY-MM') = to_char(pp.period,'YYYY-MM'))
  );

  -- And the money really moved, by exactly what was cancelled -- computed.
  insert into check_results values (
    'the month total dropped by exactly the cancelled amounts',
    (select sum(p.amount) from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid,'2026-09-01','2026-10-01') p)
      = current_setting('app.before_total')::numeric - (select sum(before_amount) from picked)
  );

  insert into check_results values (
    'both cancelled rows are decided zeros: amount 0, reason_code null',
    (select count(*) = 2 and bool_and(p.amount = 0 and p.reason_code is null)
     from public.calculate_org_session_pay(current_setting('app.wow_lab')::uuid,'2026-09-01','2026-10-01') p
     where p.session_id in (select id from picked))
  );

  select check_name, pass from check_results order by check_name;
rollback;
