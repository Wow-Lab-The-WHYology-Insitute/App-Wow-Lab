-- 202611090005_immutable_duration_multiplier_rates.sql
--
-- §26 (docs/DATABASE_CONVENTIONS.md), extended to the second of the four
-- grids named as an open gap in item 187/§26 -- decided first, per
-- OPEN_ITEMS.md item 188: duration_multiplier before location_bonus or
-- language_bonus, not because its measured lei sensitivity is largest
-- (it is: doubling the busiest band moves 3.863,00 lei against 1.065,00
-- and 549,80 for the other two), but because it is the only one of the
-- four this project has already edited since real confirmed data existed
-- -- the other three hazards are hypothetical, this one has a precedent.
--
-- Same principle as 202611090003/4 (trainer_grade_rates) and
-- 202611090001 (contracts.amends_contract_id): a row something has
-- already relied on is never edited in place; a correction is a new row
-- pointing at the one it replaces. Routed through the shared
-- app.resolve_grid_version from the start this time -- 202611090003's own
-- same-day §22 violation (a separate app.resolve_trainer_grade_version)
-- is not repeated here; the correction-chain exclusion for
-- 'duration_multiplier' goes straight into resolve_grid_version's own
-- branch, alongside trainer_grade's.
--
-- ===========================================================================
-- MEASURED FIRST, exactly as asked (OPEN_ITEMS.md item 188 point 2 /
-- Mihai's message of 2026-11-09, second round), before anything below was
-- written:
-- ===========================================================================
--
-- Q1. Does any mechanism already block an in-place UPDATE on
--     duration_multiplier_rates? No -- only the same GRANT-only shape
--     202611090003 already found for trainer_grade_rates (authenticated
--     holds SELECT+INSERT, never UPDATE; a migration role, table owner,
--     was never restricted by that grant). Nothing specific to this
--     table was ever built, and nothing needed to be proven by sabotage
--     here beyond what 202611090003 already proved for the shape in
--     general.
--
-- Q2. How many rows have at least one confirmed session resolving to
--     them today? 2 of the live version's 7 rows (OPEN_ITEMS.md item
--     188): the 60-minute standard band (multiplier 1.0) carries 24 of
--     the org's 36 confirmed slots -- both real durations that round up
--     into it, 45 and 50 minutes, from Avenor and Scoala Germana. The
--     90-minute standard band (1.2) carries the other 12. The
--     30-minute standard band and all three scoala_altfel_saptamana_verde
--     bands (60/90/120) carry zero.
--
-- Q3. 202610160004 changed resolve_duration_multiplier from an EQUALITY
--     match to a nearest-band (>=) match -- did that change EDIT any
--     duration_multiplier_rates row in place, and if so, was any session
--     already confirmed at that moment? Two separate questions, and the
--     answer to the first makes the second moot, but both were measured:
--       - The rows were never touched. 202610160004's own header already
--         says so explicitly ("The four grid rows are untouched") -- only
--         the SQL inside the resolver function changed, from "duration_
--         minutes = x" to "duration_minutes >= x, smallest first". Checked
--         against the live schema rather than trusted on the header's
--         word alone: duration_multiplier_rates_minutes_check (30,60,90,120)
--         is unchanged since 202608310002, and no migration between the
--         two ever ran an UPDATE on this table.
--       - Checked anyway, because a function-logic change is its own kind
--         of silent retroactive mutation even when no row is touched -- the
--         SAME session, re-priced by a changed RULE rather than a changed
--         VALUE, is the identical hazard from the other side. Measured
--         directly against row_history/the live confirmed_at columns: the
--         EARLIEST confirmation of any kind, anywhere in this organization,
--         is 2026-10-20 12:24:11 -- a single bulk-import timestamp, shared
--         by all 24 of the 45/50-minute sessions this fix was written for.
--         202610160004 was applied 2026-10-16, four days earlier. Zero
--         sessions were confirmed at the moment the resolver's matching
--         logic changed. Nothing's price flipped under anyone -- the
--         function changed before there was anything confirmed for it to
--         change the price of.
--
-- ===========================================================================
--
-- corrects_version_id: same shape as trainer_grade_versions' own column
-- (202611090003) and contracts.amends_contract_id (202611090001) --
-- self-referential, same effective_date as the version it corrects, one
-- corrector per corrected version.
alter table public.duration_multiplier_versions
  add column corrects_version_id uuid references public.duration_multiplier_versions(id);

alter table public.duration_multiplier_versions
  add constraint duration_multiplier_versions_no_self_correct_check
  check (corrects_version_id is null or corrects_version_id <> id);

alter table public.duration_multiplier_versions
  add constraint duration_multiplier_versions_corrects_unique unique (corrects_version_id);

create index duration_multiplier_versions_corrects_idx
  on public.duration_multiplier_versions (corrects_version_id)
  where corrects_version_id is not null;

alter table public.duration_multiplier_versions
  drop constraint duration_multiplier_versions_org_date_unique;

create unique index duration_multiplier_versions_org_date_head_unique
  on public.duration_multiplier_versions (organization_id, effective_date)
  where corrects_version_id is null;

comment on column public.duration_multiplier_versions.corrects_version_id is
  'The version THIS ROW corrects, same effective_date, same shape as trainer_grade_versions.corrects_version_id (202611090003) and contracts.amends_contract_id (202611090001). NULL means this is an original (head) version. A version pointed at by another row''s corrects_version_id is superseded -- app.resolve_grid_version''s own duration_multiplier branch excludes it, and this table''s/this version table''s own update triggers refuse an in-place edit once any session has resolved on it (202611090005).';

-- ---------------------------------------------------------------------------
-- app.resolve_grid_version -- extend the duration_multiplier branch only.
-- The other four branches are copied verbatim from 202611090004; no new
-- standalone function this time (the §22 mistake made while building
-- 202611090003 is not repeated here).
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
  case p_grid
    when 'trainer_grade' then
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
      -- 202611090005 (item 188 point 2): a version pointed at by another
      -- row's corrects_version_id is superseded -- excluded here, the one
      -- place duration_multiplier's "in force" is decided, same shape as
      -- trainer_grade's branch above.
      select id into v_version_id from public.duration_multiplier_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (
          select corrects_version_id from public.duration_multiplier_versions
          where corrects_version_id is not null
        )
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

-- ---------------------------------------------------------------------------
-- app.duration_multiplier_rate_is_locked -- true iff a confirmed session's
-- own duration, under this exact version and delivery context, resolves
-- (by nearest-band, the same >= / order by asc / limit 1 shape 202610160004
-- put inside app.resolve_duration_multiplier) to THIS row. Unlike trainer_
-- grade's equality lock, a band's identity is its (duration_minutes,
-- delivery_context) pair, not a single key column -- both are checked
-- together, in the subquery and in the trigger below.
-- ---------------------------------------------------------------------------
create or replace function app.duration_multiplier_rate_is_locked(
  p_version_id uuid,
  p_duration_minutes integer,
  p_delivery_context text
)
returns boolean
language sql
stable
set search_path to ''
as $$
  select exists (
    select 1
    from public.duration_multiplier_versions v
    join public.sessions s on s.organization_id = v.organization_id
    join public.groups g on g.id = s.group_id
    cross join lateral (
      values
        (s.trainer_principal_id, s.trainer_principal_confirmed_at),
        (s.trainer_secundar_id, s.trainer_secundar_confirmed_at)
    ) as slot(trainer_id, confirmed_at)
    where v.id = p_version_id
      and slot.trainer_id is not null
      and slot.confirmed_at is not null
      and s.duration_minutes is not null
      and (
        case when g.delivery_format in ('scoala_altfel', 'saptamana_verde')
          then 'scoala_altfel_saptamana_verde'
          else 'standard'
        end
      ) = p_delivery_context
      and app.resolve_grid_version(v.organization_id, 'duration_multiplier', s.session_date) = p_version_id
      and p_duration_minutes = (
        select r.duration_minutes
        from public.duration_multiplier_rates r
        where r.version_id = p_version_id
          and r.delivery_context = p_delivery_context
          and r.duration_minutes >= s.duration_minutes
        order by r.duration_minutes asc
        limit 1
      )
  );
$$;

revoke all on function app.duration_multiplier_rate_is_locked(uuid, integer, text) from public;
grant execute on function app.duration_multiplier_rate_is_locked(uuid, integer, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- The two triggers. Named to sort alphabetically BEFORE each table's own
-- _row_history trigger, same reasoning as 202611090003: a refused update
-- never reaches row_history_capture.
--
-- All three columns that define a band's financial meaning -- multiplier,
-- duration_minutes, delivery_context -- are checked together. This is
-- wider than trainer_grade_rates_block_locked_update (which only checks
-- `rate`, since grade_level there is an identity column nobody edits in
-- practice): here, moving duration_minutes or delivery_context on a locked
-- row IS the same hazard as changing multiplier, since it moves the band
-- boundary that decides which sessions land on it. Checking only
-- `multiplier` would leave the lock a one-column fence around a
-- three-column room.
-- ---------------------------------------------------------------------------
create or replace function app.duration_multiplier_rates_block_locked_update()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if (new.multiplier is distinct from old.multiplier
      or new.duration_minutes is distinct from old.duration_minutes
      or new.delivery_context is distinct from old.delivery_context)
     and app.duration_multiplier_rate_is_locked(old.version_id, old.duration_minutes, old.delivery_context)
  then
    raise exception 'duration_multiplier_rates: the % / % band on version % already has a confirmed session resolved against it -- a band cannot be edited in place (multiplier, duration_minutes, or delivery_context) once relied on. Insert a new duration_multiplier_versions row with corrects_version_id = %, carrying the corrected bands, instead (202611090005).', old.duration_minutes, old.delivery_context, old.version_id, old.version_id;
  end if;
  return new;
end;
$$;

create trigger duration_multiplier_rates_block_locked_update
  before update on public.duration_multiplier_rates
  for each row execute function app.duration_multiplier_rates_block_locked_update();

create or replace function app.duration_multiplier_versions_block_locked_update()
returns trigger
language plpgsql
set search_path to ''
as $$
declare
  v_locked boolean;
begin
  -- note stays editable regardless of lock state, same as trainer_grade_
  -- versions: documentation, never a financial fact.
  if new.effective_date is distinct from old.effective_date
     or new.organization_id is distinct from old.organization_id
     or new.corrects_version_id is distinct from old.corrects_version_id
  then
    select exists (
      select 1
      from public.duration_multiplier_rates r
      where r.version_id = old.id
        and app.duration_multiplier_rate_is_locked(old.id, r.duration_minutes, r.delivery_context)
    ) into v_locked;

    if v_locked then
      raise exception 'duration_multiplier_versions: version % already has a confirmed session resolved under it -- its effective_date, organization_id and corrects_version_id cannot change. Insert a new, correcting version instead (202611090005).', old.id;
    end if;
  end if;
  return new;
end;
$$;

create trigger duration_multiplier_versions_block_locked_update
  before update on public.duration_multiplier_versions
  for each row execute function app.duration_multiplier_versions_block_locked_update();

-- ===========================================================================
-- ASSERTIONS -- re-measure live, same convention as 202611090003.
-- ===========================================================================
do $$
declare
  v_org uuid;
  v_version uuid;
  v_raised boolean;
  v_multiplier numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'immutable_duration_multiplier_rates: no organization with slug wow-lab';
  end if;

  v_version := app.resolve_grid_version(v_org, 'duration_multiplier', current_date);
  if v_version is null then
    raise exception 'immutable_duration_multiplier_rates: no live duration_multiplier version for org %', v_org;
  end if;

  -- The 60-minute standard band is locked today (24 of 36 confirmed slots
  -- resolve to it). A direct multiplier UPDATE must be refused.
  v_raised := false;
  begin
    update public.duration_multiplier_rates set multiplier = multiplier + 1
    where version_id = v_version and duration_minutes = 60 and delivery_context = 'standard';
  exception when others then
    v_raised := true;
  end;
  if not v_raised then
    raise exception 'immutable_duration_multiplier_rates: the 60-minute standard band (locked) accepted a multiplier UPDATE -- the trigger is not blocking it';
  end if;

  -- Moving the band boundary itself must be refused too, not only the
  -- multiplier -- the whole point of checking three columns together.
  v_raised := false;
  begin
    update public.duration_multiplier_rates set duration_minutes = 61
    where version_id = v_version and duration_minutes = 60 and delivery_context = 'standard';
  exception when others then
    v_raised := true;
  end;
  if not v_raised then
    raise exception 'immutable_duration_multiplier_rates: the 60-minute standard band (locked) accepted a duration_minutes UPDATE -- the trigger is not blocking band-boundary moves';
  end if;

  -- The 30-minute standard band has zero confirmed sessions today and must
  -- remain genuinely editable -- changed and reverted in the same
  -- transaction.
  update public.duration_multiplier_rates set multiplier = 9.99
  where version_id = v_version and duration_minutes = 30 and delivery_context = 'standard';
  select multiplier into v_multiplier
  from public.duration_multiplier_rates
  where version_id = v_version and duration_minutes = 30 and delivery_context = 'standard';
  if v_multiplier is distinct from 9.99 then
    raise exception 'immutable_duration_multiplier_rates: the 30-minute standard band (unlocked today) was refused a multiplier UPDATE -- it should not be locked yet';
  end if;
  update public.duration_multiplier_rates set multiplier = 1.0
  where version_id = v_version and duration_minutes = 30 and delivery_context = 'standard';

  -- The version itself: effective_date is locked the same way (the
  -- 60-minute band's lock covers the whole version), note is not.
  v_raised := false;
  begin
    update public.duration_multiplier_versions set effective_date = effective_date + 1 where id = v_version;
  exception when others then
    v_raised := true;
  end;
  if not v_raised then
    raise exception 'immutable_duration_multiplier_rates: the live version accepted an effective_date UPDATE -- the trigger is not blocking it';
  end if;

  update public.duration_multiplier_versions set note = coalesce(note, '') || ' ' where id = v_version;
  update public.duration_multiplier_versions set note = rtrim(coalesce(note, '')) where id = v_version;

  -- Regression check: a real, live, 45-minute session (rounds up to the
  -- 60-minute band) still resolves the same multiplier as before this
  -- migration.
  if app.resolve_duration_multiplier(v_org, 45, 'standard', current_date) <> 1.0 then
    raise exception 'immutable_duration_multiplier_rates: resolve_duration_multiplier(45, standard) changed -- expected 1.0 (the 60-minute band)';
  end if;

  raise notice 'immutable_duration_multiplier_rates: the 60-minute standard band locked and refused on both multiplier and duration_minutes, the 30-minute band unlocked and accepted (then reverted), version effective_date locked, note still editable, resolver regression-clean';
end $$;
