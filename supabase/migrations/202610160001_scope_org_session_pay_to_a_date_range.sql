-- app.calculate_org_session_pay takes a DATE RANGE instead of scanning the
-- whole organization. Replaces the single-argument version from
-- 202610150003, one day old and never deployed to a screen that shipped.
--
-- WHY, and the second reason is the one that matters later.
--
-- The immediate reason is a product one: the month now lives in /payroll's
-- URL rather than in client state, so Anca can send someone a link to a
-- specific month and the page survives a refresh. Once the month is a
-- server-side fact, asking for the whole org and filtering on the client
-- is just a scan nobody reads.
--
-- The reason in two years is arithmetic. The loop in here calls
-- app.calculate_session_pay once per trainer slot, and that function costs
-- roughly six indexed lookups (grade, grade rate, duration multiplier,
-- location bonus, language bonus, plus the session and group reads). At
-- WOW LAB's own volume -- a recurring club runs ~30 workshops a year and
-- there are several -- call it ~500 sessions a year, ~1,000 slots, ~6,000
-- lookups per page load, growing every year and never shrinking, to render
-- one month. Scoped to a month that is ~85 slots and ~500 lookups, flat
-- forever. The previous version was not wrong for an org with zero
-- sessions; it was wrong for the org this one becomes after the schedule
-- import.
--
-- p_to_exclusive IS EXCLUSIVE, and is named so rather than documented so.
-- The caller passes the first day of the month and the first day of the
-- NEXT month, which keeps month-end arithmetic (28/29/30/31) out of
-- TypeScript entirely -- the single most common way a date-range filter
-- quietly loses the 31st.
--
-- Everything else is unchanged from 202610150003 and its header still
-- carries the reasoning for all of it: SECURITY INVOKER (so the caller's
-- own SELECT rights on the pay grids are the gate and no caller can
-- reconstruct the grid from amounts), the per-slot exception block (a
-- raise aborts the statement, so one 30-minute Scoala Altfel workshop
-- would otherwise take the month's total down with it), the round() to 2
-- decimals per row (a trainer's total is the sum of rounded rows, because
-- Anca adds them up by hand off the screen), and the reason_code
-- classifier (kept next to the raises it matches, with error_text always
-- returned so no unmatched shape can render as silence).

drop function if exists public.calculate_org_session_pay(uuid);
drop function if exists app.calculate_org_session_pay(uuid);

create or replace function app.calculate_org_session_pay(
  p_organization_id uuid,
  p_from date,
  p_to_exclusive date
)
returns table (
  session_id uuid,
  trainer_id uuid,
  slot text,
  amount numeric,
  reason_code text,
  error_text text
)
language plpgsql
stable
set search_path to ''
as $$
declare
  v_session record;
  v_slot text;
  v_trainer uuid;
  v_amount numeric;
  v_reason text;
  v_error text;
begin
  if p_from is null or p_to_exclusive is null then
    raise exception 'app.calculate_org_session_pay: p_from and p_to_exclusive must not be null';
  end if;

  -- Refused rather than silently returning nothing: an inverted range is a
  -- caller bug, and zero rows is indistinguishable from "this month has no
  -- workshops" -- which on this screen reads as "nobody is owed anything".
  if p_to_exclusive <= p_from then
    raise exception 'app.calculate_org_session_pay: p_to_exclusive (%) must be after p_from (%)', p_to_exclusive, p_from;
  end if;

  for v_session in
    select s.id, s.trainer_principal_id, s.trainer_secundar_id
    from public.sessions s
    where s.organization_id = p_organization_id
      and s.session_date >= p_from
      and s.session_date < p_to_exclusive
    order by s.session_date, s.id
  loop
    -- The two named slots, iterated rather than written out twice, so the
    -- exception block below exists once. Never generalized to N slots:
    -- allocation in this schema is two fixed named columns and the
    -- sessions migration's own comment declined to generalize them.
    for v_slot, v_trainer in
      select *
      from (values ('principal', v_session.trainer_principal_id),
                   ('secundar', v_session.trainer_secundar_id)) as t(slot, trainer)
    loop
      if v_trainer is null then
        continue;
      end if;

      begin
        v_amount := round(app.calculate_session_pay(v_session.id, v_trainer), 2);
        v_reason := null;
        v_error := null;
      exception when others then
        v_amount := null;
        v_error := sqlerrm;
        -- Classified here, next to nothing, because the alternatives are
        -- worse in both directions: re-asking each of the five input
        -- questions in SQL would duplicate calculate_session_pay's own
        -- guards (the mirror /payroll already keeps, and which provably
        -- drifted -- it misses every grid gap below), and matching these
        -- substrings in TypeScript would put the match a repo away from
        -- the raise it matches. Every one of these messages is owned by
        -- this codebase: five by calculate_session_pay (202609250001),
        -- nine by the five resolvers (202608310002 / 202609210006).
        --
        -- error_text is returned alongside, always. An unmatched shape
        -- gets 'unknown' and the screen prints the raw message -- degraded
        -- and ugly, never silent, and never a wrong amount. No case can
        -- vanish by failing to match here, and
        -- db/tests/payroll_reason_code_coverage.sql derives the list of
        -- raises from the function sources and fails if one of them has no
        -- branch in this CASE -- so a raise added in six months breaks a
        -- test instead of quietly becoming 'unknown'.
        v_reason := case
          -- calculate_session_pay's own guards, before any resolver runs
          when v_error like '%p_trainer_id must not be null%'              then 'no_trainer'
          when v_error like '%has no duration_minutes recorded%'           then 'no_duration'
          when v_error like '%has no location_tier recorded%'              then 'no_location'
          when v_error like '%has no language_group recorded%'             then 'no_language'
          when v_error like '%not the principal or secundar trainer%'      then 'not_on_session'
          when v_error like '%no session %'                                then 'no_session'
          -- resolve_trainer_grade / resolve_trainer_grade_rate
          when v_error like '%no trainer_grade_assignments row%'           then 'no_grade'
          when v_error like '%no trainer_grade_versions row effective%'    then 'no_grade_version'
          when v_error like '%has no row for grade level%'                 then 'no_grade_rate_row'
          -- resolve_duration_multiplier: the second of these is the live
          -- gap -- 30 minutes exists for context 'standard' and not for
          -- 'scoala_altfel_saptamana_verde', and the duration select on
          -- the workshop form offers 30, so this is reachable today.
          when v_error like '%no duration_multiplier_versions row effective%' then 'no_duration_version'
          when v_error like '%minutes / context%'                         then 'no_duration_row'
          -- resolve_location_bonus
          when v_error like '%no location_bonus_versions row effective%'   then 'no_location_version'
          when v_error like '%has no row for tier%'                        then 'no_location_row'
          -- resolve_language_bonus
          when v_error like '%no language_bonus_versions row effective%'   then 'no_language_version'
          when v_error like '%has no row for language group%'              then 'no_language_row'
          else 'unknown'
        end;
      end;

      session_id := v_session.id;
      trainer_id := v_trainer;
      slot := v_slot;
      amount := v_amount;
      reason_code := v_reason;
      error_text := v_error;
      return next;
    end loop;
  end loop;
end;
$$;

comment on function app.calculate_org_session_pay(uuid, date, date) is
  'One row per trainer slot per workshop in [p_from, p_to_exclusive): the pay amount rounded to 2 decimals, or a reason_code plus the raw error_text when app.calculate_session_pay raised. SECURITY INVOKER -- the caller''s own SELECT rights on the pay grids decide, same as every resolver underneath. Rounds per row on purpose: a trainer''s total is the sum of rounded rows. Range-scoped rather than org-wide so the cost of rendering one month does not grow with the org''s history.';

revoke all on function app.calculate_org_session_pay(uuid, date, date) from public;
grant execute on function app.calculate_org_session_pay(uuid, date, date) to authenticated, service_role;

-- The PostgREST-exposed wrapper. The app schema is not in
-- supabase/config.toml's [api] schemas list, so .rpc() cannot reach
-- anything in it -- the same reason 202609220002 exists for the six
-- app.rpc_* write functions, and 202607130004 for public.has_capability.
create or replace function public.calculate_org_session_pay(
  p_organization_id uuid,
  p_from date,
  p_to_exclusive date
)
returns table (
  session_id uuid,
  trainer_id uuid,
  slot text,
  amount numeric,
  reason_code text,
  error_text text
)
language sql
security invoker
set search_path to ''
as $$
  select * from app.calculate_org_session_pay(p_organization_id, p_from, p_to_exclusive);
$$;

comment on function public.calculate_org_session_pay(uuid, date, date) is
  'PostgREST-exposed wrapper around app.calculate_org_session_pay() -- the app schema itself is not exposed via the Data API. SECURITY INVOKER, forwarding only.';

revoke all on function public.calculate_org_session_pay(uuid, date, date) from public;
grant execute on function public.calculate_org_session_pay(uuid, date, date) to authenticated;
