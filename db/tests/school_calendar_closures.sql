-- db/tests/school_calendar_closures.sql
-- WOW LAB OS: the three schools' calendars as data (202610200008), and the
-- property the whole table exists to hold -- that "the school is shut" and
-- "a workshop cannot run" are DIFFERENT PREDICATES.
--
-- Item 159's finding: Avenor's 30 June 2027 is an `Early Dismissal for
-- Students - 12:00`. The school is OPEN. The children leave at noon. The
-- workshops are at 15:15 and 16:15. A holidays-only calendar counts that day
-- as a normal Wednesday and puts two workshops into an empty building --
-- which is what the report of "174 workshops" did before this table existed.
--
-- Also covers convention 18's refusal rule and the table's own RLS, which
-- ships with a policy and therefore ships with a sabotage check.
--
-- Same pattern as the rest of this directory: resolve ids into GUCs while
-- privileged, switch identity, exercise the real table. Every block is
-- BEGIN/ROLLBACK.

-- ============================================================================
-- Point 1 -- the data, and the distinction that is not derivable from `kind`.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.ave', (select id::text from public.clients where organization_id = current_setting('app.org')::uuid and name = 'Scoala Avenor'), true);
  select set_config('app.lyc', (select id::text from public.clients where organization_id = current_setting('app.org')::uuid and name like 'Școala Franceză%'), true);
  select set_config('app.ger', (select id::text from public.clients where organization_id = current_setting('app.org')::uuid and name = 'Scoala Germana'), true);

  select 'all three schools carry a 2026-2027 calendar' as check_name,
    (select count(distinct client_id)::text from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and school_year = '2026-2027') as actual,
    '3' as expected,
    (select count(distinct client_id) from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and school_year = '2026-2027') = 3 as pass
  union all
  -- THE ROW THE TABLE WAS BUILT FOR.
  select 'Avenor 30 June 2027 is a BLOCKING short day, not a teaching day',
    (select kind || '/' || blocks_workshop::text from public.school_calendar_closures
     where client_id = current_setting('app.ave')::uuid and from_date = '2027-06-30'),
    'zi_scurta/true',
    (select kind = 'zi_scurta' and blocks_workshop from public.school_calendar_closures
     where client_id = current_setting('app.ave')::uuid and from_date = '2027-06-30')
  union all
  select 'and it carries the school''s own wording, not ours',
    (select label from public.school_calendar_closures
     where client_id = current_setting('app.ave')::uuid and from_date = '2027-06-30'),
    'Early Dismissal for Students - 12:00',
    (select label = 'Early Dismissal for Students - 12:00' from public.school_calendar_closures
     where client_id = current_setting('app.ave')::uuid and from_date = '2027-06-30')
  union all
  -- blocks_workshop is NOT a synonym for "school is shut": a Saturday
  -- management inset blocks nothing, an open-but-short day blocks.
  select 'a management inset day does NOT block -- recorded, and irrelevant',
    (select count(*) filter (where blocks_workshop)::text from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and kind = 'inset_management'),
    '0',
    (select count(*) filter (where blocks_workshop) = 0 from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and kind = 'inset_management')
  union all
  select 'non-blocking rows exist at all -- "checked and irrelevant" is not "never looked"',
    (select count(*)::text from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and not blocks_workshop),
    '3',
    (select count(*) = 3 from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and not blocks_workshop)
  union all
  -- The autumn that started all of this: three schools, three answers, and
  -- none of them is the national 24 October - 1 November.
  select 'three schools, three different autumn holidays, none of them national',
    (select string_agg(x.r, ' | ' order by x.r) from (
       select to_char(from_date,'DD Mon') || '-' || to_char(to_date,'DD Mon') as r
       from public.school_calendar_closures
       where school_year = '2026-2027' and kind = 'vacanta'
         and from_date = '2026-10-19') x),
    '19 Oct-01 Nov | 19 Oct-23 Oct | 19 Oct-23 Oct',
    (select count(*) = 3 and count(distinct to_date) = 2 and max(to_date) = '2026-11-01'
     from public.school_calendar_closures
     where school_year = '2026-2027' and kind = 'vacanta' and from_date = '2026-10-19')
  union all
  select 'no national-structure row exists to fall back to (convention 18)',
    (select count(*)::text from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid
       and (from_date = '2026-10-24' or to_date = '2027-01-10')),
    '0',
    (select count(*) = 0 from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid
       and (from_date = '2026-10-24' or to_date = '2027-01-10'))
  union all
  select 'every row names the URL it was read from',
    (select count(*)::text from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and coalesce(btrim(source_url),'') = ''),
    '0',
    (select count(*) = 0 from public.school_calendar_closures
     where organization_id = current_setting('app.org')::uuid and coalesce(btrim(source_url),'') = '');
rollback;

-- ============================================================================
-- Point 2 -- the generated schedule agrees with the calendar. Derived from
-- the table on both sides, never from a list of dates: this is the assertion
-- 202610200009 makes, re-run here so it keeps holding after the migration.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);

  select 'no scheduled workshop falls on a blocking day of its own school' as check_name,
    (select count(*)::text
     from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.school_calendar_closures cl
       on cl.client_id = g.client_id and cl.school_year = '2026-2027'
      and cl.blocks_workshop and s.session_date between cl.from_date and cl.to_date
     where s.organization_id = current_setting('app.org')::uuid
       and s.status <> 'cancelled') as actual,
    '0' as expected,
    (select count(*) = 0
     from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.school_calendar_closures cl
       on cl.client_id = g.client_id and cl.school_year = '2026-2027'
      and cl.blocks_workshop and s.session_date between cl.from_date and cl.to_date
     where s.organization_id = current_setting('app.org')::uuid
       and s.status <> 'cancelled') as pass
  union all
  -- The six that were cancelled ARE inside a blocking range -- the exception
  -- above excludes them, and this asserts they are exactly the exception.
  select 'the six cancelled workshops are precisely the ones inside a holiday',
    (select count(*)::text
     from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.school_calendar_closures cl
       on cl.client_id = g.client_id and cl.school_year = '2026-2027'
      and cl.blocks_workshop and s.session_date between cl.from_date and cl.to_date
     where s.organization_id = current_setting('app.org')::uuid),
    '6',
    (select count(*) = 6
     from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.school_calendar_closures cl
       on cl.client_id = g.client_id and cl.school_year = '2026-2027'
      and cl.blocks_workshop and s.session_date between cl.from_date and cl.to_date
     where s.organization_id = current_setting('app.org')::uuid)
  union all
  -- Avenor's last workshop is 23 June BECAUSE of the short day, not because
  -- anybody typed an end date. If the short day were missing it would be 30.
  select 'Avenor''s last workshop is 23 June -- the short day ends its year',
    (select max(s.session_date)::text from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.clients c on c.id = g.client_id
     where s.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Avenor'),
    '2027-06-23',
    (select max(s.session_date) = '2027-06-23' from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.clients c on c.id = g.client_id
     where s.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Avenor')
  union all
  select 'the Deutsche Schule runs a week longer -- 30 June, a full day for them',
    (select max(s.session_date)::text from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.clients c on c.id = g.client_id
     where s.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Germana'),
    '2027-06-30',
    (select max(s.session_date) = '2027-06-30' from public.sessions s
     join public.groups g on g.id = s.group_id
     join public.clients c on c.id = g.client_id
     where s.organization_id = current_setting('app.org')::uuid and c.name = 'Scoala Germana')
  union all
  select 'the year is 172 planned, unconfirmed workshops',
    (select count(*)::text from public.sessions
     where organization_id = current_setting('app.org')::uuid and session_date >= '2026-11-02'
       and status = 'planned' and trainer_principal_confirmed_at is null),
    '172',
    (select count(*) = 172 from public.sessions
     where organization_id = current_setting('app.org')::uuid and session_date >= '2026-11-02'
       and status = 'planned' and trainer_principal_confirmed_at is null);
rollback;

-- ============================================================================
-- Point 3 -- RLS. Readable inside the organization, including by a trainer;
-- invisible outside it. A trainer needs to know when their school is shut.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.trainer', (select id::text from public.users where email = 'lorina.ciurusniuc@gmail.com'), true);
  -- The outsider is `hello@maxdigital.ro`: a real row with NO roles in ANY
  -- organization (item 157). It is the cleanest possible negative case --
  -- app.belongs_to_org() is false for it everywhere, and nothing about the
  -- test depends on which other org a fixture user happens to sit in.
  select set_config('app.outsider', (select id::text from public.users where email = 'hello@maxdigital.ro'), true);

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.trainer')::text, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  select set_config('test.trainer_sees', (
    select count(*) from public.school_calendar_closures
    where organization_id = current_setting('app.org')::uuid)::text, true);

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.outsider')::text, 'role', 'authenticated')::text, true);
  select set_config('test.outsider_sees', (
    select count(*) from public.school_calendar_closures
    where organization_id = current_setting('app.org')::uuid)::text, true);

  select 'a trainer in the org reads all 58 rows -- they need to know when their school is shut' as check_name,
    current_setting('test.trainer_sees') as actual, '58' as expected,
    current_setting('test.trainer_sees')::integer = 58 as pass
  union all
  select 'a user with no role in the organization reads none',
    current_setting('test.outsider_sees'), '0',
    current_setting('test.outsider_sees')::integer = 0;
rollback;

-- ============================================================================
-- Point 4 -- SABOTAGE CHECK. Replaces the scoping policy with `using (true)`
-- and re-runs Point 3's outsider assertion VERBATIM. Under the widened policy
-- the outsider now reads all 58 rows, so `pass` must flip to false. If it
-- does not, Point 3 was not testing the policy.
-- ============================================================================
begin;
  select set_config('app.org', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.outsider', (select id::text from public.users where email = 'hello@maxdigital.ro'), true);

  drop policy "org members select school_calendar_closures" on public.school_calendar_closures;
  create policy "org members select school_calendar_closures"
    on public.school_calendar_closures for select to authenticated using (true);

  select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.outsider')::text, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  select set_config('test.outsider_sees', (
    select count(*) from public.school_calendar_closures
    where organization_id = current_setting('app.org')::uuid)::text, true);

  select 'SABOTAGE: a user with no role in the organization reads none, same assertion as point 3, policy replaced by using (true)' as check_name,
    current_setting('test.outsider_sees') as actual, '0' as expected,
    current_setting('test.outsider_sees')::integer = 0 as pass;
rollback;
