-- "Which version is in force" becomes ONE function, and /payment-config asks
-- it instead of taking the first row of a list.
--
-- ===========================================================================
-- THIS IS NOT HYPOTHETICAL, AND THE ROW THAT BREAKS IT IS ONE WE PROMISED
-- ===========================================================================
-- /payment-config labels `versions[0]` -- the newest effective_date that
-- EXISTS -- as "current". Every pay resolver instead picks the newest with
-- `effective_date <= p_as_of`: the version in force ON THE WORKSHOP'S DATE.
--
-- Those two agree only while nothing is dated ahead. Item 147 is the
-- instruction that ends that:
--
--   the 111-150 scale is seeded WHEN A SIGNED CONTRACT WRITES IT, with that
--   contract's own start date.
--
-- If such a contract starts in January, the row lands in December and from
-- that moment the screen says 150 at grade 6 while payroll correctly pays
-- 135 until January. Anca reads 150 and hand-calculates on a number the
-- application is not using. **We wrote the rule that brings that row**, so
-- this is a scheduled collision, not a risk.
--
-- 202610200001 removed a back-dated version from this grid six days ago. The
-- next one goes the other way.
--
-- ===========================================================================
-- THE GENERAL FORM, which is the part worth keeping
-- ===========================================================================
--   A SCREEN THAT LABELS SOMETHING "CURRENT" ASKS THE SAME FUNCTION THE
--   ENGINE ASKS. Not `versions[0]`, not `order by ... limit 1` written again
--   in TypeScript -- the resolver itself.
--
--   A screen with its own notion of "the first one in the list" has its own
--   truth, and two truths about the same number disagree silently: both
--   queries are correct, they answer different questions, and nothing fails.
--
-- It applies to anything versioned and effective-dated, not just this grid:
-- the five pay grids here, and whatever later gets a `*_versions` table.
-- Written into DATABASE_CONVENTIONS.md §22 rather than only here.
--
-- ===========================================================================
-- WHY ALL FIVE RESOLVERS CHANGE, when only the screen was wrong
-- ===========================================================================
-- Because "the screen asks the same function" is only true if there IS one
-- function. The selection was written out five times, identically, in five
-- plpgsql bodies; adding a sixth copy for the screen would have been the
-- same bug with better manners.
--
-- So: app.resolve_grid_version() is extracted, the five resolvers call it,
-- and the screen reaches it through public.current_grid_versions(). One
-- query, five callers, one answer.
--
-- NOTHING ELSE ABOUT THE RESOLVERS MOVES. Same signatures, same STABLE, same
-- search_path, and -- deliberately -- THE SAME RAISE MESSAGES, character for
-- character. db/tests/payroll_reason_code_coverage.sql derives the raise
-- sites from pg_get_functiondef and matches them against the classifier's
-- branches; changing a word here would fail that test, which is exactly what
-- it is for.

-- ---------------------------------------------------------------------------
-- 1. The one function.
-- ---------------------------------------------------------------------------
create or replace function app.resolve_grid_version(
  p_organization_id uuid,
  p_grid text,
  p_as_of date
)
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  v_version_id uuid;
begin
  -- One branch per grid rather than dynamic SQL over a table name: the five
  -- tables are a closed set defined by migrations, and `execute format(...)`
  -- over a caller-supplied identifier is the shape that turns a typo into an
  -- injection surface. A new grid adds a branch here and fails loudly until
  -- it does.
  case p_grid
    when 'trainer_grade' then
      select id into v_version_id from public.trainer_grade_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'location_bonus' then
      select id into v_version_id from public.location_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'language_bonus' then
      select id into v_version_id from public.language_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'duration_multiplier' then
      select id into v_version_id from public.duration_multiplier_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    when 'contract_type_uplift' then
      select id into v_version_id from public.contract_type_uplift_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
      order by effective_date desc limit 1;
    else
      raise exception 'app.resolve_grid_version: unknown grid %', p_grid;
  end case;

  return v_version_id;
end;
$$;

comment on function app.resolve_grid_version(uuid, text, date) is
  'WHICH VERSION OF A PAY GRID IS IN FORCE on a given date: the newest with effective_date <= p_as_of, or null if none is. The single definition of that question -- the five pay resolvers call it, and /payment-config reaches it through public.current_grid_versions() so that the screen''s "current" cannot drift from the engine''s. Returns null rather than raising, because each resolver raises its own message naming its own table (and db/tests/payroll_reason_code_coverage.sql matches those messages). DATABASE_CONVENTIONS.md §22.';

revoke all on function app.resolve_grid_version(uuid, text, date) from public;
grant execute on function app.resolve_grid_version(uuid, text, date) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. The five resolvers, now asking it. Bodies otherwise untouched.
-- ---------------------------------------------------------------------------
create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_rate numeric;
begin
  v_version_id := app.resolve_grid_version(p_organization_id, 'trainer_grade', p_as_of);
  if v_version_id is null then
    raise exception 'app.resolve_trainer_grade_rate: no trainer_grade_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate from public.trainer_grade_rates
  where version_id = v_version_id and grade_level = p_grade_level;

  if v_rate is null then
    raise exception 'app.resolve_trainer_grade_rate: version % has no row for grade level % -- incomplete version', v_version_id, p_grade_level;
  end if;

  return v_rate;
end;
$$;

create or replace function app.resolve_location_bonus(p_organization_id uuid, p_location_tier text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_bonus numeric;
begin
  v_version_id := app.resolve_grid_version(p_organization_id, 'location_bonus', p_as_of);
  if v_version_id is null then
    raise exception 'app.resolve_location_bonus: no location_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select bonus_percent into v_bonus from public.location_bonus_rates
  where version_id = v_version_id and location_tier = p_location_tier;

  if v_bonus is null then
    raise exception 'app.resolve_location_bonus: version % has no row for tier % -- incomplete version', v_version_id, p_location_tier;
  end if;

  return v_bonus;
end;
$$;

create or replace function app.resolve_language_bonus(p_organization_id uuid, p_language_group text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_bonus numeric;
begin
  v_version_id := app.resolve_grid_version(p_organization_id, 'language_bonus', p_as_of);
  if v_version_id is null then
    raise exception 'app.resolve_language_bonus: no language_bonus_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select bonus_percent into v_bonus from public.language_bonus_rates
  where version_id = v_version_id and language_group = p_language_group;

  if v_bonus is null then
    raise exception 'app.resolve_language_bonus: version % has no row for language group % -- incomplete version', v_version_id, p_language_group;
  end if;

  return v_bonus;
end;
$$;

create or replace function app.resolve_contract_type_uplift(p_organization_id uuid, p_contract_type text, p_as_of date)
returns numeric language plpgsql stable set search_path = '' as $$
declare v_version_id uuid; v_uplift numeric;
begin
  v_version_id := app.resolve_grid_version(p_organization_id, 'contract_type_uplift', p_as_of);
  if v_version_id is null then
    raise exception 'app.resolve_contract_type_uplift: no contract_type_uplift_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select uplift_percent into v_uplift from public.contract_type_uplift_rates
  where version_id = v_version_id and contract_type = p_contract_type;

  if v_uplift is null then
    raise exception 'app.resolve_contract_type_uplift: version % has no row for contract type % -- incomplete version', v_version_id, p_contract_type;
  end if;

  return v_uplift;
end;
$$;

-- The band resolver, same change, everything else from 202610160004 intact
-- (the context mapping, the smallest-band-at-or-above lookup, and both of
-- its two distinct raise messages).
create or replace function app.resolve_duration_multiplier(
  p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date
)
returns numeric language plpgsql stable set search_path = '' as $$
declare
  v_context text;
  v_version_id uuid;
  v_multiplier numeric;
  v_top_band integer;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  v_version_id := app.resolve_grid_version(p_organization_id, 'duration_multiplier', p_as_of);
  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

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

  select max(r.duration_minutes) into v_top_band
  from public.duration_multiplier_rates r
  where r.version_id = v_version_id and r.delivery_context = v_context;

  if v_top_band is null then
    raise exception 'app.resolve_duration_multiplier: version % has no bands for context % -- incomplete version', v_version_id, v_context;
  end if;

  raise exception 'app.resolve_duration_multiplier: % minutes is longer than the longest band (% minutes) in version % / context %', p_duration_minutes, v_top_band, v_version_id, v_context;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. The screen's way in. One row per grid, the version in force today.
-- ---------------------------------------------------------------------------
-- SECURITY INVOKER: it reads the *_versions tables through the caller's own
-- RLS, exactly as /payment-config's existing reads do. It adds no visibility;
-- it adds an ANSWER the screen could not previously get without re-deriving
-- it.
create or replace function public.current_grid_versions(
  p_organization_id uuid,
  p_as_of date default current_date
)
returns table (grid text, version_id uuid)
language sql
security invoker
stable
set search_path = ''
as $$
  select g.grid, app.resolve_grid_version(p_organization_id, g.grid, p_as_of)
  from (values ('trainer_grade'), ('location_bonus'), ('language_bonus'),
               ('duration_multiplier'), ('contract_type_uplift')) g(grid);
$$;

comment on function public.current_grid_versions(uuid, date) is
  'Which version of each pay grid is IN FORCE on p_as_of (default today), as one row per grid. Exists so /payment-config can label a version "current" by asking the same function the pay engine asks, instead of taking the newest row that exists -- those two agree only while nothing is dated ahead, and item 147 schedules exactly such a row (the 111-150 scale, seeded with a signed contract''s own start date). version_id is null for a grid with no version in force yet. SECURITY INVOKER: no new visibility, only an answer. DATABASE_CONVENTIONS.md §22.';

revoke all on function public.current_grid_versions(uuid, date) from public;
grant execute on function public.current_grid_versions(uuid, date) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Assertions.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_n integer;
  v_rate numeric;
  v_future uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'grid-version: no organization with slug wow-lab'; end if;

  -- Five grids answered, FOUR of them with a version in force.
  select count(*) into v_n from public.current_grid_versions(v_org);
  if v_n <> 5 then
    raise exception 'grid-version: current_grid_versions returned % rows, expected 5', v_n;
  end if;

  -- The first draft of this assertion required all five to be non-null and
  -- the migration refused. The assertion was wrong, not the code:
  -- contract_type_uplift has ZERO VERSIONS ON PURPOSE (item 147 -- there is
  -- no uplift to apply, so the grid is deliberately empty rather than seeded
  -- with zeros). app.resolve_contract_type_uplift raising 'no
  -- contract_type_uplift_versions row effective on or before %' is that
  -- decision working, not a gap.
  --
  -- Asserted as FOUR-plus-one rather than relaxed to "at least one", so the
  -- deliberate absence stays a stated fact instead of becoming invisible
  -- (convention §20). If somebody seeds that grid, this fails and they have
  -- to come and read item 147 first.
  select count(*) into v_n from public.current_grid_versions(v_org) where version_id is not null;
  if v_n <> 4 then
    raise exception 'grid-version: % grids have a version in force, expected 4 (contract_type_uplift is deliberately empty -- item 147)', v_n;
  end if;
  if (select version_id from public.current_grid_versions(v_org) where grid = 'contract_type_uplift') is not null then
    raise exception 'grid-version: contract_type_uplift now has a version -- read item 147 before changing this assertion';
  end if;

  -- The resolver and the raw query agree on today's answer, which is the
  -- only state in which the OLD screen was also right.
  if (select version_id from public.current_grid_versions(v_org) where grid = 'trainer_grade')
     is distinct from (select id from public.trainer_grade_versions
                       where organization_id = v_org order by effective_date desc limit 1) then
    raise exception 'grid-version: today''s trainer_grade answer differs from the newest row -- something is already dated ahead';
  end if;

  -- Pay is unchanged. 202610200001's restated scale: grade 2 on 2026-09-30.
  v_rate := app.resolve_trainer_grade_rate(v_org, 2, '2026-09-30');
  if v_rate <> 107 then
    raise exception 'grid-version: grade 2 on 2026-09-30 resolves to %, expected 107', v_rate;
  end if;

  -- An unknown grid name raises rather than returning null, so a typo in a
  -- future caller fails loudly instead of reading as "nothing in force".
  begin
    perform app.resolve_grid_version(v_org, 'not_a_grid', current_date);
    raise exception 'grid-version: an unknown grid name did not raise';
  exception when others then
    if sqlerrm not like '%unknown grid%' then raise; end if;
  end;

  -- A date before any version is null, not an error, and not the newest row.
  v_future := app.resolve_grid_version(v_org, 'trainer_grade', '2020-01-01');
  if v_future is not null then
    raise exception 'grid-version: a date before every version returned a version';
  end if;

  raise notice 'grid-version: one resolver, five callers plus the screen; 4 of 5 grids have a version in force (contract_type_uplift empty by decision) and pay is unchanged';
end $$;
