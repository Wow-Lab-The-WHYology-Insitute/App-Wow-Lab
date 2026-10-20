-- The six workshops between 17 and 21 October, INSERTED UNCONFIRMED.
--
-- ===========================================================================
-- WHAT CHANGES HERE, AND IT IS NOT THE SIZE OF THE BATCH
-- ===========================================================================
-- The 38 of 202610200002 were HISTORY: delivered, and already approved by
-- Anca in the real timesheet with `Approval Status = "Aprobat"` on every
-- row. That approval is what justified importing them confirmed, and what
-- justified her name as the actor (item 152's correction).
--
-- These six have nothing behind them. Four of them HAVE NOT HAPPENED YET --
-- they are tomorrow, Wednesday 21 October. So they go in UNCONFIRMED, and
-- status = 'planned' rather than 'delivered'.
--
-- Marking them confirmed would assert a future delivery, which is exactly
-- what was refused when backdating a confirmation was refused: a
-- confirmation is a person's assertion that they taught a class, and
-- nobody can make it in advance. The same reasoning, pointed forwards
-- instead of backwards.
--
-- Monday 19 and Tuesday 20 October have passed, and they are still
-- 'planned' and still unconfirmed -- because the application does not know
-- they were delivered. It knows they were scheduled. Those are different
-- facts and only one of them is in evidence.
--
-- **So these are the first workshops this application holds BEFORE they
-- happen.** Everything until now was a record of what had already occurred.
-- From tomorrow the schedule is live in the app, and /payroll's unconfirmed
-- list stops being empty for a real reason: six slots waiting for the
-- trainers who will teach them to say they did.
--
-- ===========================================================================
-- WHY IT STOPS AT 21 OCTOBER
-- ===========================================================================
-- The autumn holiday is 24 October - 1 November 2026: module 1 ends Friday
-- 23 October, return is Monday 2 November (national school-year structure,
-- 2026-2027). The six workshops that a naive weekly projection would place
-- on 26, 27 and 28 October DO NOT HAPPEN, so they are not inserted.
--
-- Not "inserted and cancellable later". app.rpc_cancel_session
-- (202610200003) does make a wrongly-generated workshop repairable, and
-- that is what unblocks schedule generation -- but repairable is not a
-- reason to write down something known to be false. The next real
-- workshops are the week of 2 November.
--
-- ===========================================================================
-- THE SAME GUARDS AS THE IMPORT, for the same reasons
-- ===========================================================================
-- location_tier explicit on every row (item 144: the prefill cannot fire,
-- every group has address = null). duration_minutes is the REAL length --
-- 90 Lycee, 45 Avenor, 50 Scoala Germana -- never the band. Trainers as
-- they actually are: Lycee and Avenor are Catalina's, Scoala Germana is
-- Lorina's since the 30 September handover.
--
-- No impersonation here, and nothing to impersonate for: this migration
-- writes no confirmations, so there is no actor to record. That absence is
-- itself the point -- item 152's reason only licensed confirming rows Anca
-- had already approved, and these are not such rows.

do $$
declare
  v_org uuid;
  v_cat uuid;
  v_lor uuid;
  v_before integer;
  v_after integer;
  v_six integer;
  v_value numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'schedule: no organization with slug wow-lab';
  end if;

  select id into v_cat from public.users where email = 'catalina_moale@yahoo.com';
  select id into v_lor from public.users where email = 'lorina.ciurusniuc@gmail.com';
  if v_cat is null or v_lor is null then
    raise exception 'schedule: missing Catalina or Lorina';
  end if;

  select count(*) into v_before from public.sessions where organization_id = v_org;
  raise notice 'schedule: BEFORE -- % sessions', v_before;

  if v_before <> 38 then
    raise exception 'schedule: expected the 38 imported workshops, found % -- re-read before adding more', v_before;
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date between '2026-10-17' and '2026-10-21'
  ) then
    raise exception 'schedule: workshops already exist in 17-21 October -- refusing to double-insert';
  end if;

  -- Lycée Français: Monday 19 and Tuesday 20 October, 90 min, imprejurimi.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, g.id,
         case when g.schedule_pattern like 'Monday%' then '2026-10-19'::date else '2026-10-20'::date end,
         '16:00', v_cat, 'planned', 90, 'imprejurimi'
  from public.groups g
  join public.clients c on c.id = g.client_id
  where g.organization_id = v_org and c.name like 'Școala Franceză%';

  -- Avenor: Wednesday 21 October, 45 min REAL, imprejurimi.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, '2026-10-21', x.st, v_cat, 'planned', 45, 'imprejurimi'
  from (values ('c1000000-0000-0000-0000-0000000000a1'::uuid, '15:15'::time),
               ('c1000000-0000-0000-0000-0000000000a2'::uuid, '16:15'::time)) x(gid, st);

  -- Scoala Germana: Wednesday 21 October, 50 min REAL, bucuresti, Lorina.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, '2026-10-21', x.st, v_lor, 'planned', 50, 'bucuresti'
  from (values ('c1000000-0000-0000-0000-0000000000b1'::uuid, '15:30'::time),
               ('c1000000-0000-0000-0000-0000000000b2'::uuid, '16:25'::time)) x(gid, st);

  -- ---- Assertions ----
  select count(*) into v_six
  from public.sessions
  where organization_id = v_org and session_date between '2026-10-17' and '2026-10-21';
  if v_six <> 6 then
    raise exception 'schedule: inserted % workshops in 17-21 October, expected 6', v_six;
  end if;

  -- THE ONE THAT MATTERS: none of them is confirmed, and none is cancelled.
  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date between '2026-10-17' and '2026-10-21'
      and (trainer_principal_confirmed_at is not null or trainer_secundar_confirmed_at is not null)
  ) then
    raise exception 'schedule: a workshop in 17-21 October is confirmed -- these must go in unconfirmed';
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date between '2026-10-17' and '2026-10-21'
      and status <> 'planned'
  ) then
    raise exception 'schedule: a workshop in 17-21 October is not planned';
  end if;

  -- Nothing in the holiday, and nothing beyond it.
  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date between '2026-10-24' and '2026-11-01'
  ) then
    raise exception 'schedule: a workshop falls inside the autumn holiday (24 Oct - 1 Nov 2026)';
  end if;

  if exists (select 1 from public.sessions where organization_id = v_org and session_date > '2026-10-21') then
    raise exception 'schedule: a workshop is dated after 21 October -- this migration stops there';
  end if;

  -- Real duration and tier per school, same assertion shape as the import.
  if exists (
    select 1 from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.clients c on c.id = g.client_id
    where s.organization_id = v_org and s.session_date between '2026-10-17' and '2026-10-21'
      and ((c.name like 'Școala Franceză%' and (s.duration_minutes <> 90 or s.location_tier <> 'imprejurimi' or s.trainer_principal_id <> v_cat))
        or (c.name = 'Scoala Avenor'      and (s.duration_minutes <> 45 or s.location_tier <> 'imprejurimi' or s.trainer_principal_id <> v_cat))
        or (c.name = 'Scoala Germana'     and (s.duration_minutes <> 50 or s.location_tier <> 'bucuresti'   or s.trainer_principal_id <> v_lor)))
  ) then
    raise exception 'schedule: a workshop has the wrong real duration, tier or trainer for its school';
  end if;

  -- They price correctly, which is what makes them meaningful as PENDING.
  select sum(p.amount) into v_value
  from public.calculate_org_session_pay(v_org, '2026-10-17', '2026-10-22') p;
  if v_value is distinct from 956.50 then
    raise exception 'schedule: the six are worth %, expected 956.50', v_value;
  end if;

  select count(*) into v_after from public.sessions where organization_id = v_org;
  if v_after <> 44 then
    raise exception 'schedule: AFTER is % sessions, expected 44', v_after;
  end if;

  raise notice 'schedule: AFTER -- % sessions (was %); 6 added for 19-21 October, all planned, NONE confirmed, worth 956.50 pending',
    v_after, v_before;
end $$;
