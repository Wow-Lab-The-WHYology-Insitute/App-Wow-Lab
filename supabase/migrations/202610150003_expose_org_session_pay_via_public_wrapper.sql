-- app.calculate_org_session_pay + its public wrapper: what finally gives
-- app.calculate_session_pay (202609250001) a caller. That function has
-- been tested and uncalled since 2026-09-25 -- its own header says
-- "nothing calls this function yet (no UI, no payroll screen)" and that
-- the eventual caller is expected to be finance-facing. This is that
-- caller, and it is finance-facing: /payroll, gated on
-- finance.operations.* / org.settings.manage.
--
-- WHY A SET-RETURNING FUNCTION RATHER THAN THE TEN-LINE WRAPPER AROUND
-- calculate_session_pay(session, trainer) THAT THE SCOPE REPORT
-- PROMISED. Two reasons, both discovered while building:
--
--   1. A raise must not take the month down with it. Postgres aborts the
--      whole statement on an uncaught raise, and app.calculate_session_
--      pay raises on fourteen distinct shapes of missing input. Catching
--      per slot is only possible inside a plpgsql block -- there is no
--      way to ask PostgREST for "the amount, or the reason there isn't
--      one" per row. A per-slot wrapper would have meant one HTTP round
--      trip per trainer slot AND no isolation: one 30-minute
--      scoala_altfel workshop (a real, reachable grid gap -- see the
--      reason_code classifier below) would have turned the whole
--      month's total into a 500.
--   2. /payroll's month picker is plain client state, not navigation
--      (page.tsx's own comment says why), so the server component cannot
--      know which month to ask for. This returns the whole org for the
--      same reason page.tsx already fetches sessions org-wide and
--      filters on the client.
--
-- SECURITY INVOKER, deliberately, like every resolver underneath it and
-- like calculate_session_pay itself. The rate tables
-- (trainer_grade_rates, duration_multiplier_rates, location_bonus_rates,
-- language_bonus_rates) admit SELECT to finance.operations.* /
-- finance.reporting.* / platform owner only (202608310002). SECURITY
-- DEFINER here would let any caller reconstruct the entire pay grid row
-- by row from the amounts, which is exactly what calculate_session_pay's
-- own header refused to allow one level down. Verified before building:
-- every role that can open /payroll today (finance.operations.* or
-- org.settings.manage) also holds finance.operations.*, because
-- org.settings.manage is granted only to Organization Owner and Platform
-- Owner and both carry finance.operations.* as well -- so no live viewer
-- gets a wall of permission-shaped failures. page.tsx still guards for
-- the case anyway (item 123: an absence under RLS is not evidence).
--
-- ROUNDING IS DONE HERE, PER ROW, ON numeric -- NOT IN TYPESCRIPT.
-- The rule: every workshop row is rounded to 2 decimals, and a trainer's
-- total is the sum of the ROUNDED rows, never the unrounded sum rounded
-- at the end. Anca issues the invoice from this screen and will add the
-- rows up by hand; the total has to agree with a calculator. The two
-- differ for real: two slots at 276.225 each are 276.23 + 276.23 =
-- 552.46 to the reader, while rounding the 552.45 sum at the end gives
-- 552.45 -- a one-ban disagreement that makes the screen look wrong.
-- db/tests/payroll_org_session_pay.sql asserts exactly that pair.
-- Rounding in Postgres numeric rather than in JS is not a style choice:
-- 276.225 is not representable in binary floating point, so the
-- language doing the rounding decides the answer. numeric rounds half
-- away from zero, exactly once, here.
--
-- calculate_session_pay itself stays unrounded, on purpose -- its own
-- header explains why (444 of 1,456 real approved historical amounts
-- carry bani). The unrounded product remains the stored truth of the
-- calculation; this function is the display layer asking for 2 decimals.

create or replace function app.calculate_org_session_pay(p_organization_id uuid)
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
  for v_session in
    select s.id, s.trainer_principal_id, s.trainer_secundar_id
    from public.sessions s
    where s.organization_id = p_organization_id
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
        -- Classified here, next to nothing, because the alternative is
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
        -- vanish by failing to match here.
        v_reason := case
          -- calculate_session_pay's own guards, before any resolver runs
          when v_error like '%has no duration_minutes recorded%'          then 'no_duration'
          when v_error like '%has no location_tier recorded%'             then 'no_location'
          when v_error like '%has no language_group recorded%'            then 'no_language'
          when v_error like '%not the principal or secundar trainer%'     then 'not_on_session'
          -- resolve_trainer_grade / resolve_trainer_grade_rate
          when v_error like '%no trainer_grade_assignments row%'          then 'no_grade'
          when v_error like '%no trainer_grade_versions row effective%'   then 'no_grade_version'
          when v_error like '%has no row for grade level%'                then 'no_grade_rate_row'
          -- resolve_duration_multiplier: the second of these is the live
          -- gap -- 30 minutes exists for context 'standard' and not for
          -- 'scoala_altfel_saptamana_verde', and the duration select on
          -- the workshop form offers 30, so this is reachable today.
          when v_error like '%no duration_multiplier_versions row effective%' then 'no_duration_version'
          when v_error like '%minutes / context%'                        then 'no_duration_row'
          -- resolve_location_bonus
          when v_error like '%no location_bonus_versions row effective%'  then 'no_location_version'
          when v_error like '%has no row for tier%'                       then 'no_location_row'
          -- resolve_language_bonus
          when v_error like '%no language_bonus_versions row effective%'  then 'no_language_version'
          when v_error like '%has no row for language group%'             then 'no_language_row'
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

comment on function app.calculate_org_session_pay(uuid) is
  'One row per trainer slot per workshop for a whole organization: the pay amount rounded to 2 decimals, or a reason_code plus the raw error_text when app.calculate_session_pay raised. SECURITY INVOKER -- the caller''s own SELECT rights on the pay grids decide, same as every resolver underneath. Rounds per row on purpose: a trainer''s total is the sum of rounded rows (see the migration header).';

revoke all on function app.calculate_org_session_pay(uuid) from public;
grant execute on function app.calculate_org_session_pay(uuid) to authenticated, service_role;

-- The PostgREST-exposed wrapper. The app schema is not in
-- supabase/config.toml's [api] schemas list, so .rpc() cannot reach
-- anything in it -- the same reason 202609220002 exists for the six
-- app.rpc_* write functions, and 202607130004 for public.has_capability.
-- Not named rpc_*: that prefix belongs to the write-routing functions
-- (202609220001), which are SECURITY DEFINER with their own internal
-- authorization checks. This is a read with no elevation at all, so it
-- follows public.has_capability / public.resolve_landing_flags instead.
create or replace function public.calculate_org_session_pay(p_organization_id uuid)
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
  select * from app.calculate_org_session_pay(p_organization_id);
$$;

comment on function public.calculate_org_session_pay(uuid) is
  'PostgREST-exposed wrapper around app.calculate_org_session_pay() -- the app schema itself is not exposed via the Data API. SECURITY INVOKER, forwarding only.';

revoke all on function public.calculate_org_session_pay(uuid) from public;
grant execute on function public.calculate_org_session_pay(uuid) to authenticated;
