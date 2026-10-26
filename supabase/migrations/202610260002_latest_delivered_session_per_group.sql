-- "The most recent session of this group" must mean the most recent one
-- HELD, not the furthest one scheduled -- and must not need every session
-- ever to answer it.
--
-- ===========================================================================
-- A RIGHT ANSWER FROM A WRONG MECHANISM, WHICH IS THE WORSE KIND
-- ===========================================================================
-- /groups resolves each row's trainer columns from the first session in a
-- `session_date DESC` ordering -- "the most recent session", true until
-- 202610200009 generated the school year. It now reads the trainer off
-- 23 June 2027 (Avenor) and 30 June 2027 (Deutsche Schule).
--
-- IT STILL DISPLAYS THE RIGHT NAME. 202610200009 templated every generated
-- workshop's trainer from the group's most recent non-cancelled session, so
-- the June 2027 rows happen to name the people teaching today. Nobody would
-- notice.
--
-- That is the problem rather than the reprieve. The first reallocation that
-- changes January onward and leaves June alone makes /groups show THE
-- OUTGOING TRAINER -- on the one screen somebody opens to see who teaches
-- what. And handovers are not hypothetical here either: Teodora handed the
-- Deutsche Schule to Lorina on 2026-09-30, six weeks ago. The next one would
-- be hidden by the screen you look at to find it.
--
-- ===========================================================================
-- AND THE TRUNCATION, IN THE SAME PASS
-- ===========================================================================
-- The old query also fetched EVERY session of EVERY group -- 223 rows for 6
-- groups today -- to keep one row each. PostgREST caps a response at
-- `max_rows = 1000` (supabase/config.toml) and truncates silently.
--
-- Because the ordering is DESC, the rows that fall off are the OLDEST. So
-- the first thing to break is not the trainer column on active groups: it is
-- groups whose last session is long past, which lose their row data
-- entirely while everything anyone is looking at still appears fine.
-- Dormant groups are exactly the ones nobody checks.
--
-- A view returning ONE ROW PER GROUP removes both faults at once: the
-- semantics, and a result set that is bounded by the number of groups rather
-- than the number of workshops.
--
-- ===========================================================================
-- WHY A VIEW, AND WHY security_invoker
-- ===========================================================================
-- security_invoker = true makes `sessions`' own RLS apply to the caller, not
-- to the view's owner. Without it this view would be a hole: a trainer would
-- read every group's latest session instead of their own, through a view
-- that looks innocuous. With it, the view is exactly as visible as the rows
-- underneath and adds no reach -- it adds an ANSWER.
--
-- DISTINCT ON over (session_date desc, start_time desc, id) rather than a
-- correlated subquery: one index-ordered pass, and `id` last so that two
-- workshops at the same time on the same day resolve deterministically
-- instead of by whichever the planner reached first.
--
-- CANCELLED SESSIONS ARE EXCLUDED. A workshop that did not happen says
-- nothing about who is teaching this group -- and 19-21 October gave the
-- six live groups a cancelled row each, so without this the exclusion would
-- already matter.

create or replace view public.group_latest_delivered_session
with (security_invoker = true) as
select distinct on (s.group_id)
  s.group_id,
  s.id                   as session_id,
  s.session_date,
  s.start_time,
  s.status,
  s.trainer_principal_id,
  s.trainer_secundar_id
from public.sessions s
where s.session_date <= current_date
  and s.status <> 'cancelled'
order by s.group_id, s.session_date desc, s.start_time desc nulls last, s.id;

comment on view public.group_latest_delivered_session is
  'One row per group: its most recent session that has actually HAPPENED (session_date <= current_date) and was not cancelled. Exists because "the latest session by date" stopped meaning "the most recent one held" when 202610200009 generated the school year -- /groups was reading each group''s trainer off June 2027, and displaying the right name only because the generator had propagated it, so the first reallocation would have been invisible on the one screen that exists to show it. Bounded by the number of GROUPS rather than the number of workshops, which also removes the silent PostgREST max_rows truncation the old unbounded read was five years from hitting. security_invoker = true: sessions'' own RLS applies to the caller, so this adds an answer and no visibility.';

grant select on public.group_latest_delivered_session to authenticated;

do $$
declare
  v_org uuid;
  v_rows integer;
  v_groups integer;
  v_max date;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'latest-session: no organization with slug wow-lab'; end if;

  select count(*) into v_groups from public.groups where organization_id = v_org;
  select count(*) into v_rows
  from public.group_latest_delivered_session v
  join public.groups g on g.id = v.group_id
  where g.organization_id = v_org;

  if v_rows <> v_groups then
    raise exception 'latest-session: % rows for % groups -- expected exactly one each', v_rows, v_groups;
  end if;

  -- THE ASSERTION THIS EXISTS FOR: nothing in the future, where the old
  -- query returned June 2027 for four of the six groups.
  select max(v.session_date) into v_max
  from public.group_latest_delivered_session v
  join public.groups g on g.id = v.group_id
  where g.organization_id = v_org;
  if v_max > current_date then
    raise exception 'latest-session: the latest HELD session is %, which is in the future', v_max;
  end if;

  if exists (
    select 1 from public.group_latest_delivered_session v
    join public.groups g on g.id = v.group_id
    where g.organization_id = v_org and v.status = 'cancelled'
  ) then
    raise exception 'latest-session: a cancelled workshop is being read as a group''s latest';
  end if;

  -- The six live groups each carry a cancelled row from 19-21 October, so
  -- the exclusion above is doing work rather than being decorative.
  if (select count(*) from public.sessions s
      join public.groups g on g.id = s.group_id
      where g.organization_id = v_org and s.status = 'cancelled') <> 6 then
    raise exception 'latest-session: expected the 6 cancelled workshops of 19-21 October to still be there';
  end if;

  raise notice 'latest-session: one row per group, latest held is % or earlier, cancelled rows excluded', v_max;
end $$;
