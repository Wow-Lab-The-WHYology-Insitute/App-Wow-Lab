-- The 2026-2027 schedule, first half: four missing groups and the 38
-- workshops already delivered between 2026-09-02 and 2026-10-16.
--
-- This is the first real data in the operational tables. The organization
-- had ZERO sessions before this migration -- /payroll has been correct and
-- empty since it was built.
--
-- ===========================================================================
-- WHAT IS EXPLICIT HERE, AND WHY NONE OF IT IS LEFT TO A DEFAULT
-- ===========================================================================
--
-- location_tier IS WRITTEN ON EVERY ROW. Item 144 established that the
-- location bonus is a property of the SCHOOL, not of the trainer, and that
-- the model should move to a tier on the client -- but that is written, not
-- built. Today the only automatic input is a form prefill that fires only
-- when the trainer's home city is Bucharest AND the group's address contains
-- "bucur", and every group here has address = null, so it would never fire.
-- Leaving the tier to be typed 38 times is how 38 workshops end up 25% short.
-- The values are read off real paid rows in the timesheet, not assumed:
--   Lycee Francais  -> imprejurimi (25%)  -- 128 of 129 real rows
--   Scoala Avenor   -> imprejurimi (25%)  -- 161 of 166 real rows
--   Scoala Germana  -> bucuresti   (0%)   -- 44 of 50 real rows (DSBU)
-- The German school being 0% while two schools in the same city are 25% is
-- exactly why this was checked rather than inferred.
--
-- duration_minutes IS THE REAL LENGTH, NOT THE BAND. 45 at Avenor, 50 at
-- Scoala Germana, 90 at Lycee. Since 202610160004 the resolver bands
-- (smallest band at or above the actual length), so 45 and 50 both resolve
-- through the 60 band and pay 1.0x. Writing 60 into the column would
-- produce the same money and make the row lie about the workshop -- a band
-- is a lookup key, not a fact about a class. The real length is also what
-- start_time + duration_minutes has to reconstruct for the timetable.
--
-- THE SCOALA GERMANA HANDOVER. Lorina Ciurusniuc took the two Wednesday
-- groups over from Teodora Merisan from the session after 25 September.
-- Teodora: 9, 16, 23 September. Lorina: 30 September, 7, 14 October. Six
-- and six across the two groups. Her grade is effective 2026-09-30, so a
-- workshop mis-dated earlier would RAISE rather than quietly compute --
-- which is the guard, not an inconvenience.
--
-- INSERTED UNCONFIRMED, THEN CONFIRMED THROUGH THE SANCTIONED RPC.
-- app.rpc_correct_session_confirmation is the Operations-corrects path; it
-- stamps now(), so confirmed_at is the IMPORT date, not the workshop date.
-- That is the truth: nobody confirmed anything on 2 September. The
-- alternative -- writing a backdated timestamp straight into the column --
-- would fabricate a trainer's assertion, and INSERTs are not captured by
-- sessions_row_history (BEFORE DELETE OR UPDATE), so it would leave no
-- actor behind either. Going through the RPC makes each confirmation an
-- UPDATE, which row_history captures with its actor.
--
-- WHICH IS WHY THIS MIGRATION IMPERSONATES. app.current_user_id() reads the
-- JWT, and a migration has none -- so the RPC's gate would refuse and
-- row_history's actor_user_id would be null. request.jwt.claims is set to
-- Anca (platform owner) for the duration, the same mechanism db/tests/*.sql
-- uses. The actor on all 38 confirmations is therefore her, which is
-- accurate: this import is being run on her instruction.
--
-- ===========================================================================
-- THE ASSERTIONS, which are the point of doing this as a migration
-- ===========================================================================
-- It refuses unless the result is exactly 6,118.50 across 38 workshops, and
-- exactly 4,792.50 / 684.00 / 642.00 split by trainer and invoicing entity.
-- That figure was computed independently by Mihai before the import and
-- matched to the ban; every per-workshop rate in it also matches a real
-- paid row in the timesheet (Lycee 202.50 = Catalina's own 1.5h Surroundings
-- rows; Teodora 114.00 and Lorina 107.00 are their September rows verbatim).
-- An import that silently produced a different total would be worse than one
-- that failed.

do $$
declare
  v_org uuid;
  v_anca uuid;
  v_before_sessions integer;
  v_before_groups integer;
  v_after_sessions integer;
  v_after_groups integer;
  v_total numeric;
  v_rec record;
  v_res text;
  v_unconfirmed integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'import: no organization with slug wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'import: no user anca.tanasescu@gmail.com to attribute the confirmations to';
  end if;

  select count(*) into v_before_sessions from public.sessions where organization_id = v_org;
  select count(*) into v_before_groups from public.groups where organization_id = v_org;
  raise notice 'import: BEFORE -- % sessions, % groups in wow-lab', v_before_sessions, v_before_groups;

  -- Refuses to run twice. The real org had zero sessions; if it has any,
  -- something else has happened and this migration's assertions would be
  -- measuring a mixture.
  if v_before_sessions <> 0 then
    raise exception 'import: expected 0 sessions in wow-lab, found % -- refusing to import on top of existing data', v_before_sessions;
  end if;
  if v_before_groups <> 2 then
    raise exception 'import: expected the 2 existing Lycee groups, found % -- re-read before importing', v_before_groups;
  end if;

  -- Impersonate Anca so the RPC's gate passes and row_history records a
  -- real actor. Scoped to this transaction (is_local = true).
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_anca::text, 'role', 'authenticated')::text, true);

  -- ---- The four missing groups ----
  -- Avenor: Wednesday 15:15-16:00 and 16:15-17:00, Wow Lab Mix at both.
  -- Scoala Germana: Wednesday 15:30-16:20 Chemistry for Me (chem_me) and
  -- 16:25-17:15 Wow Lab Mix 2-4 (wow_mix). All ro_en, all
  -- scoli_private_recurente, each linked to its own client's contract.
  insert into public.groups (id, organization_id, client_id, contract_id, module,
                             delivery_format, schedule_pattern, language_group, status)
  select spec.gid, v_org, c.id, ct.id, spec.mod, 'scoli_private_recurente',
         spec.pattern, 'ro_en', 'active'
  from (values
    ('c1000000-0000-0000-0000-0000000000a1'::uuid, 'Scoala Avenor',  'wow_mix', 'Wednesday 15:15'),
    ('c1000000-0000-0000-0000-0000000000a2'::uuid, 'Scoala Avenor',  'wow_mix', 'Wednesday 16:15'),
    ('c1000000-0000-0000-0000-0000000000b1'::uuid, 'Scoala Germana', 'chem_me', 'Wednesday 15:30'),
    ('c1000000-0000-0000-0000-0000000000b2'::uuid, 'Scoala Germana', 'wow_mix', 'Wednesday 16:25')
  ) spec(gid, cname, mod, pattern)
  join public.clients c on c.name = spec.cname and c.organization_id = v_org
  join public.contracts ct on ct.client_id = c.id;

  -- ---- Lycee Francais: 6 Mondays + 6 Tuesdays, 90 min, imprejurimi ----
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, g.id, d::date, '16:00',
         (select id from public.users where email = 'catalina_moale@yahoo.com'),
         'delivered', 90, 'imprejurimi'
  from public.groups g
  join public.clients c on c.id = g.client_id
  cross join lateral generate_series(
    case when g.schedule_pattern like 'Monday%' then '2026-09-07'::date else '2026-09-08'::date end,
    '2026-10-16'::date, interval '7 days') d
  where g.organization_id = v_org and c.name like 'Școala Franceză%';

  -- ---- Avenor: 7 Wednesdays x 2 groups, 45 min REAL, imprejurimi ----
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, d::date, x.st,
         (select id from public.users where email = 'catalina_moale@yahoo.com'),
         'delivered', 45, 'imprejurimi'
  from (values ('c1000000-0000-0000-0000-0000000000a1'::uuid, '15:15'::time),
               ('c1000000-0000-0000-0000-0000000000a2'::uuid, '16:15'::time)) x(gid, st)
  cross join lateral generate_series('2026-09-02'::date, '2026-10-16'::date, interval '7 days') d;

  -- ---- Scoala Germana: 6 Wednesdays x 2 groups, 50 min REAL, bucuresti ----
  -- Teodora to 23 September inclusive, Lorina from 30 September.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, d::date, x.st,
         case when d::date <= '2026-09-23'
              then (select id from public.users where email = 'merisanteodora@gmail.com')
              else (select id from public.users where email = 'lorina.ciurusniuc@gmail.com') end,
         'delivered', 50, 'bucuresti'
  from (values ('c1000000-0000-0000-0000-0000000000b1'::uuid, '15:30'::time),
               ('c1000000-0000-0000-0000-0000000000b2'::uuid, '16:25'::time)) x(gid, st)
  cross join lateral generate_series('2026-09-09'::date, '2026-10-16'::date, interval '7 days') d;

  -- ---- Confirm each, through the RPC, never by writing the column ----
  for v_rec in
    select id from public.sessions where organization_id = v_org order by session_date, id
  loop
    select app.rpc_correct_session_confirmation(v_rec.id, true, false) into v_res;
    if v_res <> 'ok' then
      raise exception 'import: rpc_correct_session_confirmation returned % for session %', v_res, v_rec.id;
    end if;
  end loop;

  select count(*) into v_unconfirmed
  from public.sessions
  where organization_id = v_org and trainer_principal_confirmed_at is null;
  if v_unconfirmed <> 0 then
    raise exception 'import: % sessions still unconfirmed after the RPC loop', v_unconfirmed;
  end if;

  -- ---- Assertions on the shape of what was written ----
  if exists (select 1 from public.sessions where organization_id = v_org and location_tier is null) then
    raise exception 'import: a session has no location_tier -- every row must carry it explicitly';
  end if;

  if exists (
    select 1 from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.clients c on c.id = g.client_id
    where s.organization_id = v_org
      and ((c.name like 'Școala Franceză%' and (s.duration_minutes <> 90 or s.location_tier <> 'imprejurimi'))
        or (c.name = 'Scoala Avenor'      and (s.duration_minutes <> 45 or s.location_tier <> 'imprejurimi'))
        or (c.name = 'Scoala Germana'     and (s.duration_minutes <> 50 or s.location_tier <> 'bucuresti')))
  ) then
    raise exception 'import: a session carries the wrong real duration or tier for its school';
  end if;

  -- ---- Assertions on the money ----
  select sum(p.amount) into v_total
  from public.calculate_org_session_pay(v_org, '2026-09-01', '2026-10-17') p;
  if v_total is distinct from 6118.50 then
    raise exception 'import: total is %, expected 6118.50', v_total;
  end if;

  if (select count(*) from public.calculate_org_session_pay(v_org, '2026-09-01', '2026-10-17')) <> 38 then
    raise exception 'import: expected 38 priced trainer slots';
  end if;

  -- Per trainer and invoicing entity, which is how the money is actually
  -- invoiced (one invoice per trainer per entity -- item 136).
  if not exists (
    select 1 from (
      select coalesce(u.full_name,'?') as trainer, le.name as entity,
             count(*) as n, sum(p.amount) as total
      from public.calculate_org_session_pay(v_org, '2026-09-01', '2026-10-17') p
      join public.sessions s on s.id = p.session_id
      join public.groups g on g.id = s.group_id
      join public.contracts ct on ct.id = g.contract_id
      join public.legal_entities le on le.id = ct.legal_entity_id
      left join public.users u on u.id = p.trainer_id
      group by 1, 2
    ) x
    where (x.trainer = 'Cătălina Trușan'   and x.entity = 'Brandine Advertising SRL' and x.n = 26 and x.total = 4792.50)
  ) then
    raise exception 'import: Catalina/Brandine is not 26 workshops at 4792.50';
  end if;

  if not exists (
    select 1 from (
      select coalesce(u.full_name,'?') as trainer, le.name as entity,
             count(*) as n, sum(p.amount) as total
      from public.calculate_org_session_pay(v_org, '2026-09-01', '2026-10-17') p
      join public.sessions s on s.id = p.session_id
      join public.groups g on g.id = s.group_id
      join public.contracts ct on ct.id = g.contract_id
      join public.legal_entities le on le.id = ct.legal_entity_id
      left join public.users u on u.id = p.trainer_id
      group by 1, 2
    ) x
    where (x.trainer = 'Teodora Merișan'   and x.entity = 'Experimente Wow SRL' and x.n = 6 and x.total = 684.00)
  ) then
    raise exception 'import: Teodora/Experimente Wow is not 6 workshops at 684.00';
  end if;

  if not exists (
    select 1 from (
      select coalesce(u.full_name,'?') as trainer, le.name as entity,
             count(*) as n, sum(p.amount) as total
      from public.calculate_org_session_pay(v_org, '2026-09-01', '2026-10-17') p
      join public.sessions s on s.id = p.session_id
      join public.groups g on g.id = s.group_id
      join public.contracts ct on ct.id = g.contract_id
      join public.legal_entities le on le.id = ct.legal_entity_id
      left join public.users u on u.id = p.trainer_id
      group by 1, 2
    ) x
    where (x.trainer = 'Lorina Ciurusniuc' and x.entity = 'Experimente Wow SRL' and x.n = 6 and x.total = 642.00)
  ) then
    raise exception 'import: Lorina/Experimente Wow is not 6 workshops at 642.00';
  end if;

  select count(*) into v_after_sessions from public.sessions where organization_id = v_org;
  select count(*) into v_after_groups from public.groups where organization_id = v_org;
  if v_after_sessions <> 38 or v_after_groups <> 6 then
    raise exception 'import: AFTER is % sessions / % groups, expected 38 / 6', v_after_sessions, v_after_groups;
  end if;

  raise notice 'import: AFTER -- % sessions (was %), % groups (was %); total 6118.50 across 38 slots, all confirmed by Anca at import time',
    v_after_sessions, v_before_sessions, v_after_groups, v_before_groups;
end $$;
