-- app.resolve_duration_multiplier stops matching the length exactly and
-- starts choosing the smallest BAND that covers it. The four grid rows are
-- untouched.
--
-- WHY THE ROWS WERE NOT THE PROBLEM. The 2026-2027 schedule has four
-- groups whose classes are 45 and 50 minutes (Avenor 15:15-16:00 and
-- 16:15-17:00; Scoala Germana 15:30-16:20 and 16:25-17:15), and this
-- function raised on all of them -- 26 of the 38 workshops already
-- delivered. The obvious fix was to add rows for 45 and 50. That is wrong,
-- and the grid's own numbers say why:
--
--     30 min -> 1.0   = 0.0333 per minute
--     60 min -> 1.0   = 0.0167 per minute
--     90 min -> 1.2   = 0.0133 per minute
--    120 min -> 1.5   = 0.0125 per minute
--
-- The scale is NOT proportional to time. If it paid for hours in the room,
-- 120 would be 2.0 against 60's 1.0; it is 1.5. These four numbers measure
-- the SHAPE OF THE JOB -- the travel, the setup, the packing down -- all of
-- which a 45-minute workshop incurs exactly as a 60-minute one does. So a
-- table of lengths read with an equality key was a band table being read
-- the wrong way, and adding 45 and 50 would have made Avenor work and
-- broken the next school that schedules 55 or 80 (Mihai's objection, and
-- it is the correct one).
--
-- This is also why the fix did not wait on Anca. The lookup and the rows
-- are independent decisions: if a 45-minute workshop is paid as a
-- 60-minute one it falls in the 60 band; if it ever earns its own rate,
-- someone adds a 45 band and it hits exactly, while 50 still lands on 60.
-- Her answer decides whether rows are added, not how they are found.
--
-- BANDS ARE READ FROM THE ROWS PRESENT, NEVER FROM A HARDCODED LIST.
-- The 'scoala_altfel_saptamana_verde' context has no 30-minute row (only
-- 60/90/120), so a hardcoded ladder would raise there for a band that was
-- never defined. Reading the ladder out of the version's own rows means a
-- 20-minute Scoala Altfel workshop lands on 60, which is the only sensible
-- answer, and it means a grid that gains or loses a band needs no code
-- change.
--
-- duration_multiplier_rates_minutes_check CHECK (duration_minutes = ANY
-- (ARRAY[30, 60, 90, 120])) is deliberately LEFT ALONE. Under the old
-- reading it was a list of permitted class lengths; under this one it is
-- the definition of the bands, which is what it always was.
--
-- A CONSEQUENCE WORTH STATING RATHER THAN DISCOVERING. Ceiling-from-rows
-- closes the live 30-minute Scoala Altfel gap as a side effect: 30 now
-- resolves up to the 60 band instead of raising. That gap was the fixture
-- item 136's raise-isolation test was built on, so that fixture moves to
-- the only unpayable length left -- one above the grid's own top band,
-- which is the grid's own ceiling rather than a case constructed to fail.
--
-- search_path is pinned back to '' . 202608310002 set it; 202609210006
-- dropped it when it rewrote this function for the nine workshop types.
-- Every reference in here is already schema-qualified, so pinning it costs
-- nothing and restores the convention the other six resolvers keep.

create or replace function app.resolve_duration_multiplier(
  p_organization_id uuid,
  p_duration_minutes integer,
  p_delivery_format text,
  p_as_of date
)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_context text;
  v_version_id uuid;
  v_multiplier numeric;
  v_top_band integer;
begin
  -- Unchanged from 202609210006: of the nine workshop types, only these two
  -- map to the special context; every other one resolves as standard.
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  select id into v_version_id
  from public.duration_multiplier_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  -- THE CHANGE: smallest band at or above the requested length, from the
  -- bands this version actually defines for this context.
  select r.multiplier into v_multiplier
  from public.duration_multiplier_rates r
  where r.version_id = v_version_id
    and r.delivery_context = v_context
    and r.duration_minutes >= p_duration_minutes
  order by r.duration_minutes asc
  limit 1;

  if v_multiplier is not null then
    return v_multiplier;
  end if;

  -- Nothing covered it. Two different faults, two different messages,
  -- because they need different fixes: a context with no bands at all is an
  -- incomplete grid version, while a length above the top band is a
  -- workshop longer than anything the grid prices.
  select max(r.duration_minutes) into v_top_band
  from public.duration_multiplier_rates r
  where r.version_id = v_version_id
    and r.delivery_context = v_context;

  if v_top_band is null then
    raise exception 'app.resolve_duration_multiplier: version % has no bands for context % -- incomplete version', v_version_id, v_context;
  end if;

  raise exception 'app.resolve_duration_multiplier: % minutes is longer than the longest band (% minutes) in version % / context %', p_duration_minutes, v_top_band, v_version_id, v_context;
end;
$$;

comment on function app.resolve_duration_multiplier(uuid, integer, text, date) is
  'The multiplier for the smallest band at or above p_duration_minutes, from the bands the effective version defines for this delivery context. Bands are read from the rows present, never hardcoded. Raises above the top band, and raises when the context defines no bands at all. The grid is a band table, not a per-minute rate: 120 min is 1.5 against 60 min''s 1.0, so the scale measures the shape of the job (travel, setup, packing down), not the minutes.';

-- The reason_code classifier must change in the SAME migration, because
-- the message it matched on no longer exists. '%minutes / context%' was
-- the old "no row for this exact length" raise; it is REMOVED rather than
-- kept alongside, because db/tests/payroll_reason_code_coverage.sql
-- asserts that every classifier branch is reachable by some raise site --
-- a branch matching nothing is a branch someone will later trust.
--
-- 'no_duration_row' is kept as the code for the above-the-top-band case:
-- after this change it is the only one of the two reachable through
-- /payroll, and reusing the code keeps the screen's existing wording and
-- its two-section split intact. 'no_duration_bands' is new, for the
-- incomplete-version case -- unreachable with today's data (both contexts
-- have bands in both orgs) but representable, and the derived coverage
-- test does not accept an unclassified raise on grounds of reachability.
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
          -- resolve_duration_multiplier (banded since 202610160004)
          when v_error like '%no duration_multiplier_versions row effective%' then 'no_duration_version'
          when v_error like '%has no bands for context%'                   then 'no_duration_bands'
          when v_error like '%is longer than the longest band%'             then 'no_duration_row'
          -- resolve_location_bonus
          when v_error like '%no location_bonus_versions row effective%'    then 'no_location_version'
          when v_error like '%has no row for tier%'                        then 'no_location_row'
          -- resolve_language_bonus
          when v_error like '%no language_bonus_versions row effective%'    then 'no_language_version'
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
  'One row per trainer slot per workshop in [p_from, p_to_exclusive): the pay amount rounded to 2 decimals, or a reason_code plus the raw error_text when app.calculate_session_pay raised. SECURITY INVOKER -- the caller''s own SELECT rights on the pay grids decide. Rounds per row: a trainer''s total is the sum of rounded rows. Range-scoped so the cost of rendering one month does not grow with the org''s history.';
