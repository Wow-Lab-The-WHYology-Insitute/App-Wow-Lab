-- The rest of the school year, in one migration: every remaining workshop
-- from 2 November 2026 to each school's own last teaching day.
--
-- ===========================================================================
-- WHY THE WHOLE YEAR AND NOT WEEK BY WEEK
-- ===========================================================================
-- Mihai's reason, and it is an operational one rather than a tidiness one:
-- with everything in, THE SCHEDULE IS COMPLETE TO THE END OF THE YEAR. Anca
-- sees the year. The trainers see their work. Nobody has to remember to add
-- workshops, and "nobody remembered" is precisely how the six of 19-21
-- October came to sit in a holiday.
--
-- The thing that makes this safe now and would not have made it safe a week
-- ago is `app.rpc_cancel_session` (202610200003). If a school moves a day,
-- the row is repairable with a reason. Generating a year without a
-- cancellation path would have been writing 172 rows nobody could correct.
--
-- ===========================================================================
-- NOTHING IN THIS FILE IS A DATE
-- ===========================================================================
-- Not one workshop date is typed here. Every one is computed:
--
--   WHICH DAY     from `groups.schedule_pattern` ('Monday 16:00'), parsed --
--                 not from a hardcoded weekday per school.
--   HOW LONG      } from THE MOST RECENT EXISTING SESSION of that same
--   WHICH TIER    } group, which is a row that has already been delivered,
--   WHICH TRAINER } priced and checked. The generator inherits what is
--   WHICH TIME    } already proven instead of restating constants, and
--                 asserts the template is what we expect before using it.
--   WHICH WEEKS   from `public.school_calendar_closures` (202610200008),
--                 per school, `blocks_workshop` only.
--
-- INCLUDING THE END. There is no "last teaching day" typed per school: the
-- range runs to 31 August 2027 and each school's own summer closure cuts it
-- off. That is why Avenor stops on 23 June (30 June is its
-- `Early Dismissal for Students - 12:00`), the Deutsche Schule runs to 30
-- June, and the Lycee's Mondays and Tuesdays end on 28 and 29 June with
-- teaching continuing to Friday 2 July. Three different endings, none of
-- them chosen here.
--
-- ===========================================================================
-- §18: A SCHOOL WITH NO CALENDAR MAKES THIS REFUSE
-- ===========================================================================
-- The guard below raises if any group being generated for belongs to a
-- client with no `school_calendar_closures` rows for 2026-2027. It does NOT
-- fall back to the national structure, because there is nothing to fall back
-- to -- the national dates match none of these three schools on any
-- boundary. A fallback produces workshops that look exactly like correct
-- ones: right group, right trainer, right price, wrong week.
--
-- ===========================================================================
-- UNCONFIRMED, ALL 172 OF THEM
-- ===========================================================================
-- status = 'planned', no confirmation timestamps. A confirmation is a
-- person's assertion that they taught a class and nobody can make it in
-- advance -- 202610200004 refused to backdate one and this refuses to
-- forward-date 172. /payroll will show a large pending figure and that is
-- correct: it is the year's work, waiting for the people who will do it.
--
-- ===========================================================================
-- THE ASSERTION THAT MATTERS MOST
-- ===========================================================================
-- The last one below joins every generated session back to its school's
-- calendar and requires zero overlaps. It is derived from the TABLE, not
-- from a list of expected dates typed in this file -- an assertion against a
-- hand-written list only proves the typing was consistent with itself.

do $$
declare
  v_org uuid;
  v_from constant date := '2026-11-02';   -- the Monday after the Toussaint holiday
  v_to   constant date := '2027-08-31';   -- the school year's end (§16); closures cut it short
  v_group record;
  v_dow integer;
  v_n integer;
  v_total integer := 0;
  v_before integer;
  v_val numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'generate: no organization with slug wow-lab'; end if;

  select count(*) into v_before from public.sessions where organization_id = v_org;
  if v_before <> 48 then
    raise exception 'generate: expected 48 sessions (38 delivered + 6 cancelled + 4 planned), found % -- re-read before generating a year', v_before;
  end if;

  if exists (select 1 from public.sessions where organization_id = v_org and session_date >= v_from) then
    raise exception 'generate: workshops already exist on or after % -- refusing to double-generate', v_from;
  end if;

  -- §18: refuse rather than fall back.
  if exists (
    select 1 from public.groups g
    join public.organizations o on o.id = g.organization_id and o.id = v_org
    where not exists (
      select 1 from public.school_calendar_closures cl
      where cl.client_id = g.client_id and cl.school_year = '2026-2027'
    )
  ) then
    raise exception 'generate: a group belongs to a school with no 2026-2027 calendar loaded -- load it, do not fall back to the national structure (convention 18)';
  end if;

  for v_group in
    select g.id as group_id, g.client_id, g.schedule_pattern, c.name as school,
           t.duration_minutes, t.location_tier, t.trainer_principal_id, t.start_time
    from public.groups g
    join public.clients c on c.id = g.client_id
    join lateral (
      select s.duration_minutes, s.location_tier, s.trainer_principal_id, s.start_time
      from public.sessions s
      where s.group_id = g.id
        and s.status <> 'cancelled'   -- never template off a row that did not happen
      order by s.session_date desc, s.start_time desc
      limit 1
    ) t on true
    where g.organization_id = v_org
    order by c.name, g.schedule_pattern
  loop
    -- The template has to be complete, or the generator would spread a null
    -- across the whole year. item 144: location_tier has no prefill to fall
    -- back on, every group's address is null.
    if v_group.duration_minutes is null or v_group.location_tier is null
       or v_group.trainer_principal_id is null or v_group.start_time is null then
      raise exception 'generate: group % (%) has an incomplete template session', v_group.group_id, v_group.schedule_pattern;
    end if;

    v_dow := case split_part(v_group.schedule_pattern, ' ', 1)
               when 'Monday' then 1 when 'Tuesday' then 2 when 'Wednesday' then 3
               when 'Thursday' then 4 when 'Friday' then 5
             end;
    if v_dow is null then
      raise exception 'generate: cannot read a weekday from schedule_pattern %', v_group.schedule_pattern;
    end if;

    -- The pattern and the data must agree about the time, or one of them is
    -- stale and we are about to copy the stale one 30 times.
    if v_group.start_time <> split_part(v_group.schedule_pattern, ' ', 2)::time then
      raise exception 'generate: group % says % but its last session starts at %',
        v_group.schedule_pattern, split_part(v_group.schedule_pattern, ' ', 2), v_group.start_time;
    end if;

    insert into public.sessions (organization_id, group_id, session_date, start_time,
                                 trainer_principal_id, status, duration_minutes, location_tier)
    select v_org, v_group.group_id, d::date, v_group.start_time,
           v_group.trainer_principal_id, 'planned',
           v_group.duration_minutes, v_group.location_tier
    from generate_series(v_from, v_to, interval '1 day') d
    where extract(isodow from d) = v_dow
      and not exists (
        select 1 from public.school_calendar_closures cl
        where cl.client_id = v_group.client_id
          and cl.school_year = '2026-2027'
          and cl.blocks_workshop
          and d::date between cl.from_date and cl.to_date
      );

    get diagnostics v_n = row_count;
    v_total := v_total + v_n;
    raise notice 'generate: % / % -> % workshops', v_group.school, v_group.schedule_pattern, v_n;
  end loop;

  -- ---- Per group ----
  if (select count(*) from public.sessions s join public.groups g on g.id = s.group_id
      join public.clients c on c.id = g.client_id
      where s.organization_id = v_org and s.session_date >= v_from
        and c.name like 'Școala Franceză%' and g.schedule_pattern = 'Monday 16:00') <> 27
     or (select count(*) from public.sessions s join public.groups g on g.id = s.group_id
      join public.clients c on c.id = g.client_id
      where s.organization_id = v_org and s.session_date >= v_from
        and c.name like 'Școala Franceză%' and g.schedule_pattern = 'Tuesday 16:00') <> 27 then
    raise exception 'generate: the two Lycee groups are not 27 workshops each';
  end if;

  if (select count(*) from public.sessions s join public.groups g on g.id = s.group_id
      join public.clients c on c.id = g.client_id
      where s.organization_id = v_org and s.session_date >= v_from and c.name = 'Scoala Avenor'
      group by g.schedule_pattern having count(*) <> 29 limit 1) is not null then
    raise exception 'generate: an Avenor group is not 29 workshops (30 June is its early-dismissal day)';
  end if;

  if (select count(*) from public.sessions s join public.groups g on g.id = s.group_id
      join public.clients c on c.id = g.client_id
      where s.organization_id = v_org and s.session_date >= v_from and c.name = 'Scoala Germana'
      group by g.schedule_pattern having count(*) <> 30 limit 1) is not null then
    raise exception 'generate: a Scoala Germana group is not 30 workshops';
  end if;

  -- ---- The total ----
  if v_total <> 172 then
    raise exception 'generate: generated % workshops, expected 172 (27+27+29+29+30+30)', v_total;
  end if;

  -- ---- Nothing confirmed, nothing delivered, nothing cancelled ----
  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date >= v_from
      and (status <> 'planned' or trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null or cancellation_category is not null)
  ) then
    raise exception 'generate: a generated workshop is confirmed, cancelled or not planned';
  end if;

  -- ---- THE ONE DERIVED FROM THE CALENDAR, not from a list ----
  if exists (
    select 1
    from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.school_calendar_closures cl
      on cl.client_id = g.client_id
     and cl.school_year = '2026-2027'
     and cl.blocks_workshop
     and s.session_date between cl.from_date and cl.to_date
    where s.organization_id = v_org and s.session_date >= v_from
  ) then
    raise exception 'generate: a generated workshop falls on a day its own school marks as blocking';
  end if;

  -- Every generated date is really the group's weekday.
  if exists (
    select 1 from public.sessions s join public.groups g on g.id = s.group_id
    where s.organization_id = v_org and s.session_date >= v_from
      and extract(isodow from s.session_date) <> case split_part(g.schedule_pattern, ' ', 1)
            when 'Monday' then 1 when 'Tuesday' then 2 when 'Wednesday' then 3
            when 'Thursday' then 4 when 'Friday' then 5 end
  ) then
    raise exception 'generate: a workshop is not on its group''s weekday';
  end if;

  -- ---- Per trainer ----
  if (select round(sum(p.amount), 2)
      from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p
      join public.users u on u.id = p.trainer_id
      where u.email = 'catalina_moale@yahoo.com') <> 20722.50 then
    raise exception 'generate: Catalina does not total 20722.50';
  end if;
  if (select round(sum(p.amount), 2)
      from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p
      join public.users u on u.id = p.trainer_id
      where u.email = 'lorina.ciurusniuc@gmail.com') <> 6420.00 then
    raise exception 'generate: Lorina does not total 6420.00';
  end if;

  -- ---- Per legal entity ----
  if (select round(sum(p.amount), 2)
      from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p
      join public.sessions s on s.id = p.session_id
      join public.groups g on g.id = s.group_id
      join public.contracts ct on ct.id = g.contract_id
      join public.legal_entities le on le.id = ct.legal_entity_id
      where le.name = 'Brandine Advertising SRL') <> 20722.50 then
    raise exception 'generate: Brandine Advertising SRL does not total 20722.50';
  end if;
  if (select round(sum(p.amount), 2)
      from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p
      join public.sessions s on s.id = p.session_id
      join public.groups g on g.id = s.group_id
      join public.contracts ct on ct.id = g.contract_id
      join public.legal_entities le on le.id = ct.legal_entity_id
      where le.name = 'Experimente Wow SRL') <> 6420.00 then
    raise exception 'generate: Experimente Wow SRL does not total 6420.00';
  end if;

  -- ---- Everything prices, nothing raises ----
  select round(sum(p.amount), 2) into v_val
  from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p;
  if v_val is distinct from 27142.50 then
    raise exception 'generate: the year is worth %, expected 27142.50', v_val;
  end if;
  if exists (select 1 from public.calculate_org_session_pay(v_org, v_from, v_to + 1) p
             where p.reason_code is not null) then
    raise exception 'generate: a generated workshop cannot be priced -- it carries a reason_code';
  end if;

  if (select count(*) from public.sessions where organization_id = v_org) <> 220 then
    raise exception 'generate: AFTER is not 220 sessions (48 + 172)';
  end if;

  raise notice 'generate: 172 workshops to the end of the school year, all planned, NONE confirmed, worth 27142.50; last dates -- Avenor 23 June, Deutsche Schule 30 June, Lycee 28/29 June';
end $$;
