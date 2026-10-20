-- The four workshops of Wednesday 28 October that `202610200004` withheld on
-- a wrong reading of the calendar. Avenor and Deutsche Schule teach that
-- week; only the Lycee is still on holiday.
--
-- ===========================================================================
-- THE DECISION THIS IS WAITING ON
-- ===========================================================================
-- Mihai's, and it is a different decision from the cancellation beside it.
-- That one removes something known to be false. This one WRITES SOMETHING
-- FORWARD, on the authority of two published school calendars and nothing
-- else -- no timetable from Avenor, no message from the Deutsche Schule
-- saying "yes, 28 October, as usual".
--
-- The evidence says those two schools are open. It does not say our workshop
-- runs. Those are different facts, and only one of them is in evidence --
-- the same distinction 202610200004 drew for 19 and 20 October and then
-- failed to apply to its own omission.
--
-- So: separate file, separate decision, arm one without the other.
--
--
-- VERIFIED 2026-10-20, not applied: this file and its rollback were run
-- against the live database inside `begin; ... rollback;` -- forward,
-- then schedule_28_october, then both rollbacks -- and the state came back
-- to exactly 1/1/4 planned workshops with no category. Every assertion in
-- all four files held. Nothing was committed.
-- ===========================================================================
-- WHY THIS IS NOT "SIX MORE WORKSHOPS"
-- ===========================================================================
-- A naive weekly projection puts six on 26, 27 and 28 October: Lycee Monday,
-- Lycee Tuesday, Avenor x2 and Scoala Germana x2 on Wednesday. Two of those
-- six do not happen.
--
--   Lycee Francais  Vacances de la Toussaint runs to Sunday 1 November.
--                   Monday 26 and Tuesday 27 October are holiday. NOT
--                   INSERTED. The Lycee returns Monday 2 November.
--   Avenor          Holidays were 19-23 October only. 26-30 is a normal
--                   teaching week. Wednesday 28: two workshops.
--   DSBU            Herbstferien were 19-23 October only. Wednesday 28: two.
--
-- This is the per-school dimension of item 154 arriving as an actual
-- consequence rather than a design note: on the SAME Wednesday, one school's
-- calendar says teach and another's says holiday, and any single national
-- list would get at least one of the three wrong.
--
-- ===========================================================================
-- THE SAME GUARDS AS 202610200002 AND 202610200004
-- ===========================================================================
-- status = 'planned', NOTHING CONFIRMED -- 28 October has not happened.
-- Real durations: 45 Avenor, 50 Scoala Germana, never the band.
-- location_tier explicit (item 144: the prefill cannot fire, address is null
-- on every group). Trainers as they actually are: Avenor is Catalina's,
-- Scoala Germana is Lorina's since the 30 September handover.
--
-- No impersonation: this writes no confirmations, so there is no actor to
-- record and nothing to impersonate for.
--
-- ORDERING: this file assumes the six of 19-21 October have already been
-- cancelled, and asserts it. Arming this one alone would leave the app
-- showing a holiday week as pending pay next to a real teaching week, which
-- is worse than either repair on its own.

do $$
declare
  v_org uuid;
  v_cat uuid;
  v_lor uuid;
  v_before integer;
  v_four integer;
  v_value numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'schedule-28oct: no organization with slug wow-lab';
  end if;

  select id into v_cat from public.users where email = 'catalina_moale@yahoo.com';
  select id into v_lor from public.users where email = 'lorina.ciurusniuc@gmail.com';
  if v_cat is null or v_lor is null then
    raise exception 'schedule-28oct: missing Catalina or Lorina';
  end if;

  -- The cancellation must have run first, or this writes a teaching week
  -- next to a holiday week that still shows as pending.
  if (select count(*) from public.sessions
      where organization_id = v_org
        and session_date between '2026-10-19' and '2026-10-21'
        and status = 'cancelled' and cancellation_category = 'vacanta') <> 6 then
    raise exception 'schedule-28oct: the six workshops of 19-21 October are not cancelled as vacanta -- arm cancel_19_21_october_school_holidays.sql first';
  end if;

  select count(*) into v_before from public.sessions where organization_id = v_org;
  if v_before <> 44 then
    raise exception 'schedule-28oct: expected 44 sessions, found % -- re-read before adding more', v_before;
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date between '2026-10-26' and '2026-11-01'
  ) then
    raise exception 'schedule-28oct: workshops already exist in 26 October - 1 November -- refusing to double-insert';
  end if;

  -- Avenor: Wednesday 28 October, 45 min REAL, imprejurimi, Catalina.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, '2026-10-28', x.st, v_cat, 'planned', 45, 'imprejurimi'
  from (values ('c1000000-0000-0000-0000-0000000000a1'::uuid, '15:15'::time),
               ('c1000000-0000-0000-0000-0000000000a2'::uuid, '16:15'::time)) x(gid, st);

  -- Scoala Germana: Wednesday 28 October, 50 min REAL, bucuresti, Lorina.
  insert into public.sessions (organization_id, group_id, session_date, start_time,
                               trainer_principal_id, status, duration_minutes, location_tier)
  select v_org, x.gid, '2026-10-28', x.st, v_lor, 'planned', 50, 'bucuresti'
  from (values ('c1000000-0000-0000-0000-0000000000b1'::uuid, '15:30'::time),
               ('c1000000-0000-0000-0000-0000000000b2'::uuid, '16:25'::time)) x(gid, st);

  -- ---- Assertions ----
  select count(*) into v_four
  from public.sessions
  where organization_id = v_org and session_date between '2026-10-26' and '2026-11-01';
  if v_four <> 4 then
    raise exception 'schedule-28oct: inserted % workshops in 26 October - 1 November, expected 4', v_four;
  end if;

  -- THE ONE THAT MATTERS AGAIN: nothing confirmed, nothing delivered.
  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date = '2026-10-28'
      and (trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null
           or status <> 'planned')
  ) then
    raise exception 'schedule-28oct: a workshop on 28 October is confirmed or not planned';
  end if;

  -- THE LYCEE IS NOT HERE, and that is the whole argument of this file.
  if exists (
    select 1 from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.clients c on c.id = g.client_id
    where s.organization_id = v_org
      and s.session_date between '2026-10-26' and '2026-11-01'
      and c.name like 'Școala Franceză%'
  ) then
    raise exception 'schedule-28oct: a Lycee workshop is dated inside the Toussaint holiday (to 1 November)';
  end if;

  if exists (select 1 from public.sessions where organization_id = v_org and session_date > '2026-10-28') then
    raise exception 'schedule-28oct: a workshop is dated after 28 October -- this migration stops there';
  end if;

  -- Real duration, tier and trainer per school.
  if exists (
    select 1 from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.clients c on c.id = g.client_id
    where s.organization_id = v_org and s.session_date = '2026-10-28'
      and ((c.name = 'Scoala Avenor'  and (s.duration_minutes <> 45 or s.location_tier <> 'imprejurimi' or s.trainer_principal_id <> v_cat))
        or (c.name = 'Scoala Germana' and (s.duration_minutes <> 50 or s.location_tier <> 'bucuresti'   or s.trainer_principal_id <> v_lor)))
  ) then
    raise exception 'schedule-28oct: a workshop has the wrong real duration, tier or trainer for its school';
  end if;

  -- They price correctly: 168.75 x2 (Avenor) + 107.00 x2 (Germana).
  select sum(p.amount) into v_value
  from public.calculate_org_session_pay(v_org, '2026-10-28', '2026-10-29') p;
  if v_value is distinct from 551.50 then
    raise exception 'schedule-28oct: the four are worth %, expected 551.50', v_value;
  end if;

  if (select count(*) from public.sessions where organization_id = v_org) <> 48 then
    raise exception 'schedule-28oct: AFTER is not 48 sessions';
  end if;

  raise notice 'schedule-28oct: 4 workshops added for Wednesday 28 October, all planned, NONE confirmed, worth 551.50 pending; no Lycee row inside the Toussaint holiday';
end $$;
