-- The trainer-principal bonus (B2, Anca 2026-10-29, verbatim):
--
--   "20 lei / zi / scoala" -- only for workshops where two trainers are
--   required. Her own examples:
--     4 consecutive hours at ARC in one day              -> 20 lei
--     1h at Tonitza + 1h at Scoala 79, one day            -> 40 lei
--     4h at ARC day 1 + 4h at ARC day 2                   -> 40 lei
--   Her own reasoning, which decides the shape below: the principal and
--   secundar's preparation/delivery responsibilities are IDENTICAL; the
--   principal's only extra is the school contact and reporting the
--   attendance count. This is pay for an extra TASK, not a rate
--   differential -- a fact per (trainer, day, school), not per workshop.
--
-- Accepted by Mihai 2026-10-30, including the mixed-day case: if, at one
-- school on one day, SOME of a trainer's workshops have a secundar and
-- some don't, the bonus still fires once for that (trainer, day, school)
-- -- the extra responsibility was real that day regardless of how many of
-- the day's workshops needed it.
--
-- ===========================================================================
-- WHY THIS IS ITS OWN FUNCTION, NOT A ROW GLUED ONTO A SESSION
-- ===========================================================================
-- app.calculate_session_pay returns one row per (session, trainer slot) --
-- it has no way to represent "one amount shared across six sessions,
-- because they're the same trainer, the same day, the same school." Forcing
-- it onto an arbitrary session in the group would make that session's own
-- figure stop meaning "this workshop's pay," which is the same mistake §13
-- warns against from the opposite direction. This is a second, independent
-- read over `sessions`, grouped by (trainer_principal_id, session_date,
-- client), never joined into the per-workshop figures.
--
-- ===========================================================================
-- PAYABILITY MIRRORS calculate_session_pay'S OWN RULE, NOT A NEW ONE
-- ===========================================================================
--     payable = NOT (cancelled AND NOT scoala_a_anulat_neanuntat)
-- The same rule, the same reason: a workshop cancelled for any reason OTHER
-- than "school cancelled without notice" never happened in the sense that
-- matters here either -- the principal did not actually carry the extra
-- responsibility that day for a workshop that was called off in advance or
-- for the trainer's own unavailability. A neanuntat cancellation still
-- counts, exactly as it still pays the base rate: the trainer showed up.
--
-- `trainer_secundar_id is not null` is a scheduling fact (a secundar was
-- staffed), not conditioned on the secundar's OWN confirmation -- the
-- principal's extra responsibility (coordinating with a staffed secundar)
-- existed the moment Operations put two names on the session, independent
-- of whether the secundar later confirms their own slot.
--
-- ===========================================================================
-- GROUPED BY CLIENT, NOT GROUP -- "scoala" in Anca's examples is ARC,
-- Tonitza, Scoala 79: one school can run more than one group/module on the
-- same day without that being two schools.
-- ===========================================================================
--
-- ===========================================================================
-- STABLE, SECURITY INVOKER (both default to this), same as
-- app.calculate_org_session_pay beside it -- the caller's own RLS on
-- `sessions`/`groups` is the gate; this function adds no authorization of
-- its own and asserts no amount a capable caller could not already derive
-- from the rows it reads.
--
-- NOTHING EXISTING CHANGES. This is a pure addition -- no column, no
-- write path, no change to app.calculate_session_pay or
-- app.calculate_org_session_pay.

create or replace function app.calculate_org_principal_bonus(
  p_organization_id uuid,
  p_from date,
  p_to_exclusive date
)
returns table (trainer_id uuid, bonus_date date, client_id uuid, amount numeric)
language sql
stable
set search_path = public, pg_temp
as $$
  select distinct
    s.trainer_principal_id as trainer_id,
    s.session_date as bonus_date,
    g.client_id as client_id,
    20.00::numeric as amount
  from public.sessions s
  join public.groups g on g.id = s.group_id
  where s.organization_id = p_organization_id
    and s.session_date >= p_from
    and s.session_date < p_to_exclusive
    and s.trainer_principal_id is not null
    and s.trainer_secundar_id is not null
    and not (s.status = 'cancelled' and s.cancellation_category is distinct from 'scoala_a_anulat_neanuntat');
$$;

comment on function app.calculate_org_principal_bonus(uuid, date, date) is
  'B2 (Anca, 2026-10-29): 20 lei per (trainer_principal_id, session_date, client_id) where that trainer held the principal slot on at least one workshop that day at that school WITH a secundar staffed -- flat per day per school, regardless of how many of that day''s workshops at that school had a secundar. Payability mirrors app.calculate_session_pay''s own rule (cancelled-and-not-neanuntat is excluded). Never merged into app.calculate_org_session_pay''s per-workshop rows -- a shared, day-and-school-level amount has no single session to attach to.';

create or replace function public.calculate_org_principal_bonus(
  p_organization_id uuid,
  p_from date,
  p_to_exclusive date
)
returns table (trainer_id uuid, bonus_date date, client_id uuid, amount numeric)
language sql
set search_path = ''
as $$
  select * from app.calculate_org_principal_bonus(p_organization_id, p_from, p_to_exclusive);
$$;

comment on function public.calculate_org_principal_bonus(uuid, date, date) is
  'PostgREST-exposed wrapper around app.calculate_org_principal_bonus() (B2, item 175). Forwarding only, same shape as public.calculate_org_session_pay.';

revoke all on function public.calculate_org_principal_bonus(uuid, date, date) from public;
grant execute on function public.calculate_org_principal_bonus(uuid, date, date) to authenticated;

-- ---------------------------------------------------------------------------
-- Assertion -- a negative result, recorded rather than assumed (§20).
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_secundar_sessions integer;
  v_bonus_rows integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'principal_bonus: no organization with slug wow-lab'; end if;

  select count(*) into v_secundar_sessions from public.sessions
  where organization_id = v_org and trainer_secundar_id is not null;
  if v_secundar_sessions <> 0 then
    raise exception 'principal_bonus: expected 0 real sessions with a secundar trainer in wow-lab, found %', v_secundar_sessions;
  end if;

  select count(*) into v_bonus_rows from app.calculate_org_principal_bonus(v_org, '2020-01-01', '2030-01-01');
  if v_bonus_rows <> 0 then
    raise exception 'principal_bonus: expected 0 bonus rows in wow-lab today (no real session has ever had a secundar), found %', v_bonus_rows;
  end if;

  if to_regprocedure('app.calculate_org_principal_bonus(uuid, date, date)') is null
     or to_regprocedure('public.calculate_org_principal_bonus(uuid, date, date)') is null then
    raise exception 'principal_bonus: a function signature did not take';
  end if;

  raise notice 'principal_bonus: both functions live. 0 real sessions have ever had a secundar trainer in wow-lab, so 0 bonus rows today -- a true negative, not a broken query (§20).';
end $$;
