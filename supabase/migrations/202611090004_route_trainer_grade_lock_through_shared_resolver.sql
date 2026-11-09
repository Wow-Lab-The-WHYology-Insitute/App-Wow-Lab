-- 202611090004_route_trainer_grade_lock_through_shared_resolver.sql
--
-- Same-day correction of 202611090003's own mistake, caught by the RLS
-- suite it should have been run against before being reported: that
-- migration added a SEPARATE version-selection function
-- (app.resolve_trainer_grade_version) and rewired app.resolve_trainer_
-- grade_rate to call it instead of app.resolve_grid_version
-- (202610260001, DATABASE_CONVENTIONS.md §22 -- "A SCREEN THAT LABELS
-- SOMETHING CURRENT ASKS THE SAME FUNCTION THE ENGINE ASKS... adding a
-- sixth copy for the screen would have been the same bug with better
-- manners"). That migration exists specifically so there is ONE
-- definition of "which version is in force," shared by all five pay
-- resolvers and by /payment-config's own `current_grid_versions`.
-- 202611090003 wrote a second one anyway, for trainer_grade only --
-- exactly the mistake §22 was written to end, reintroduced the same day
-- it was reused for the first time (item 186's own §24/§25 note).
--
-- Caught by db/tests/grid_version_in_force.sql's own SABOTAGE block,
-- which replaces app.resolve_grid_version with a broken, date-ignoring
-- version and re-asserts that trainer-grade pay is still affected by
-- that replacement -- proving resolve_trainer_grade_rate actually goes
-- through the shared resolver rather than around it. It started failing
-- the moment 202611090003 made that no longer true, which is exactly
-- what that test is for.
--
-- THE FIX: the correction-chain exclusion (app.trainer_grade_versions.
-- corrects_version_id) moves INTO app.resolve_grid_version's own
-- trainer_grade branch -- the one and only place "which trainer_grade
-- version is in force" is decided. The other four branches are
-- untouched, copied verbatim from 202610260001. app.resolve_trainer_
-- grade_rate is restored to its 202610260001 body (calling app.resolve_
-- grid_version again, unchanged). app.resolve_trainer_grade_version is
-- dropped -- it was never needed; its one real job (exclude corrected-
-- away versions) now lives where every other grid's version-selection
-- already lived. app.trainer_grade_rate_is_locked is repointed at
-- app.resolve_grid_version for the same reason.
--
-- A useful instance of the thing §22 itself warns about: the one case
-- this project did NOT have two definitions quietly disagreeing (the
-- test caught it same-day, before it shipped to anyone) is exactly
-- because the shared resolver exists and is tested against sabotage --
-- the safety net worked on the person who built the net.

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
  case p_grid
    when 'trainer_grade' then
      -- 202611090003 (item 187 point 2): a version pointed at by another
      -- row's corrects_version_id is superseded -- excluded here, the one
      -- place trainer_grade's "in force" is decided, so the screen
      -- (current_grid_versions) and the pay engine see the correction the
      -- same way everything else in this function already guarantees.
      select id into v_version_id from public.trainer_grade_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (
          select corrects_version_id from public.trainer_grade_versions
          where corrects_version_id is not null
        )
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

-- Restored verbatim to its 202610260001 body -- calls the shared
-- resolver again, nothing of its own. The correction-exclusion lives in
-- resolve_grid_version now, invisibly to this function, exactly as the
-- 100-135-then-111-150 restatements were always invisible to it before
-- 202611090003 ever existed.
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

-- app.trainer_grade_rate_is_locked (202611090003): repointed at the
-- shared resolver, same reasoning, same signature, same callers.
create or replace function app.trainer_grade_rate_is_locked(p_version_id uuid, p_grade_level integer)
returns boolean
language sql
stable
set search_path to ''
as $$
  select exists (
    select 1
    from public.trainer_grade_versions v
    join public.sessions s on s.organization_id = v.organization_id
    cross join lateral (
      values
        (s.trainer_principal_id, s.trainer_principal_confirmed_at),
        (s.trainer_secundar_id, s.trainer_secundar_confirmed_at)
    ) as slot(trainer_id, confirmed_at)
    where v.id = p_version_id
      and slot.trainer_id is not null
      and slot.confirmed_at is not null
      and (
        select a.grade_level
        from public.trainer_grade_assignments a
        where a.trainer_id = slot.trainer_id
          and a.effective_from <= s.session_date
        order by a.effective_from desc
        limit 1
      ) = p_grade_level
      and app.resolve_grid_version(v.organization_id, 'trainer_grade', s.session_date) = p_version_id
  );
$$;

-- app.resolve_trainer_grade_version was never needed -- its one job now
-- lives inside app.resolve_grid_version's own trainer_grade branch.
drop function if exists app.resolve_trainer_grade_version(uuid, date);

do $$
declare
  v_org uuid;
  v_body text;
  v_rate numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';

  -- Static proof, not a live sabotage-and-revert: both functions' own
  -- compiled source must actually call app.resolve_grid_version. This is
  -- what db/tests/grid_version_in_force.sql's own SABOTAGE block checks
  -- dynamically (by replacing resolve_grid_version and re-running pay);
  -- checked here too so a migration push alone -- before that suite ever
  -- runs -- already fails loudly if the wiring regresses again.
  select pg_get_functiondef('app.resolve_trainer_grade_rate(uuid, integer, date)'::regprocedure) into v_body;
  if v_body not like '%resolve_grid_version%' then
    raise exception 'route_trainer_grade_lock_through_shared_resolver: resolve_trainer_grade_rate no longer calls app.resolve_grid_version -- the §22 shared resolver is bypassed again';
  end if;

  select pg_get_functiondef('app.trainer_grade_rate_is_locked(uuid, integer)'::regprocedure) into v_body;
  if v_body not like '%resolve_grid_version%' then
    raise exception 'route_trainer_grade_lock_through_shared_resolver: trainer_grade_rate_is_locked no longer calls app.resolve_grid_version';
  end if;

  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where p.proname = 'resolve_trainer_grade_version' and n.nspname = 'app'
  ) then
    raise exception 'route_trainer_grade_lock_through_shared_resolver: app.resolve_trainer_grade_version still exists -- it should have been dropped, its one job now lives inside resolve_grid_version';
  end if;

  -- Regression: the live grid (111-150 as of 202610300001) is unmoved by
  -- this refactor.
  v_rate := app.resolve_trainer_grade_rate(v_org, 2, '2026-09-30');
  if v_rate <> 119 then
    raise exception 'route_trainer_grade_lock_through_shared_resolver: grade 2 on 2026-09-30 resolves to %, expected 119 (the live 111-150 grid, unmoved)', v_rate;
  end if;

  raise notice 'route_trainer_grade_lock_through_shared_resolver: resolve_trainer_grade_rate and trainer_grade_rate_is_locked both route through app.resolve_grid_version again; the standalone function is gone; live grid regression-clean';
end $$;
