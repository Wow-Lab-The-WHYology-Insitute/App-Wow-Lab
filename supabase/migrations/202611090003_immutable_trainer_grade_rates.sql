-- 202611090003_immutable_trainer_grade_rates.sql
--
-- Item 187, point 2 (2026-11-09). Mihai, after accepting (b) for the 36
-- retroactively-exposed sessions (item 187 point 2): "(b) singura nu
-- inchide hazardul... trainer_grade_rates permite rescrierea unui rand in
-- loc. Inghetarea la aprobare protejeaza ce e aprobat; pana atunci nu
-- protejeaza nimic, si nici nu poate." The instruction: a rate becomes
-- IMMUTABLE the moment a session has resolved on it; a change is a NEW
-- version that corrects the old one, never an edit to the existing row --
-- "acelasi principiu decis azi dimineata pentru contracte
-- (amends_contract_id, 202611090001): Avenor n-a fost corectat prin
-- rescrierea contractului, ci prin nasterea unui predecesor."
--
-- ===========================================================================
-- MEASURED FIRST, PER EXPLICIT INSTRUCTION, BEFORE WRITING ANY OF THIS:
-- ===========================================================================
--
-- Q1: "exista deja vreun mecanism care impiedica UPDATE pe
-- trainer_grade_rates? (trigger, constraint, doar RLS?)"
-- A1: Doar GRANT. 202608310002 grants SELECT+INSERT only to `authenticated`
-- -- no UPDATE, no DELETE -- and says so explicitly in its own header
-- ("No UPDATE also means no updated_at column... a mistake gets corrected
-- by inserting a new version, full stop"). That intent was never enforced:
-- the only trigger on either table is `row_history_capture` (BEFORE
-- DELETE OR UPDATE), which CAPTURES a change, it does not BLOCK one. A
-- GRANT restricts `authenticated` only -- a migration (or any DO block
-- run by the table owner / a privileged role) was never restricted by it.
-- Proven, not argued: `202610200001_restate_trainer_grade_scale.sql` and
-- `202610300001_apply_the_11_percent_anca_confirmed.sql` both ran a plain
-- `update public.trainer_grade_rates ... where version_id = ...` and both
-- succeeded, live, on this project's real database -- row_history's own
-- captured old_values/new_values for both are the record of it.
--
-- Q2: "cite rinduri din trainer_grade_rates au cel putin o sesiune
-- rezolvata pe ele azi?"
-- A2: 3 of 6, for the real org's one live version (grades 2, 3, 6 --
-- Lorina/Teodora/Cătălina's confirmed sessions resolve to them). Grades
-- 1, 4, 5 have zero confirmed sessions resolving to them as of today and
-- remain genuinely editable under the rule this migration builds. This
-- migration's own assertion block below re-measures this live, the same
-- way it was first measured, rather than asserting a number that could
-- drift before this file is even applied.
--
-- Q3 (the one Mihai said matters most): "restate_trainer_grade_scale ar fi
-- fost REFUZATA de regula noua? Daca da, cum s-ar fi exprimat corect
-- aceeasi corectie?"
-- A3, measured against `row_history.changed_at` (the real timestamps both
-- restatements actually ran at), not assumed:
--   - 202610200001 (2026-10-20 10:49:57 UTC, all six grades): at that
--     exact moment, ZERO sessions had yet been confirmed against this
--     version, at any grade level -- the earliest confirmation on record
--     is 2026-10-20 12:24:11, over an hour LATER. This restatement would
--     NOT have been refused by this rule. It happened to land in the one
--     window where nothing had relied on the number yet.
--   - 202610300001 (2026-10-30 11:36:10 UTC, all six grades): by then,
--     grades 2, 3 and 6 already had confirmed sessions (from 2026-10-20
--     12:24 onward) -- exactly the three this migration's own measurement
--     finds locked today. This restatement WOULD have been partially
--     refused: 3 of its 6 row-level UPDATEs would have raised.
--   The correct expression, under this rule, for what 202610300001 did:
--   do not UPDATE the existing version's rows at all. INSERT a new
--   trainer_grade_versions row with corrects_version_id pointing at the
--   existing one (and the SAME effective_date, 2026-09-01 -- a correction,
--   not a new period), carrying all six corrected rates (111/119/127/
--   134/142/150) under the new version_id. The old (100/107/114/121/128/
--   135) rows stay exactly as they were, untouched and still true to what
--   they recorded -- they simply stop being the one the resolver returns,
--   because resolve_trainer_grade_version (below) excludes any version
--   something else's corrects_version_id already points at. This is a
--   rule that would have changed WHERE the correction landed, not whether
--   it could happen -- the thing Mihai named as the test that matters:
--   "o regula care ar fi blocat o corectie necesara fara sa ofere drumul
--   corect e o regula care va fi ocolita la prima urgenta." This one
--   offers the path.
--
-- ===========================================================================
-- WHAT THIS BUILDS
-- ===========================================================================
--
-- 1. trainer_grade_versions.corrects_version_id -- same shape as
--    contracts.amends_contract_id (202611090001): a self-referential FK
--    from the newer, correcting row back to the one it corrects. Not the
--    same DIRECTION of fact as amends_contract_id (that one chains
--    SEQUENTIAL periods backward in time; this one chains CORRECTIONS of
--    the SAME period forward) -- the shared principle is "a change is a
--    new row, never an edit," not the specific shape of the pointer.
-- 2. The uniqueness constraint on (organization_id, effective_date)
--    relaxed to apply only to HEAD versions (corrects_version_id is null)
--    -- a correction is allowed to share its target's effective_date,
--    which is the whole point.
-- 3. app.resolve_trainer_grade_version(org, as_of): the version-selection
--    half of resolve_trainer_grade_rate, pulled out so both the resolver
--    and the new lock-check below share one definition of "which version
--    applies," rather than two definitions that could silently disagree.
--    Excludes any version pointed at by another's corrects_version_id --
--    a corrected-away version becomes invisible to resolution without
--    ever being mutated.
-- 4. app.trainer_grade_rate_is_locked(version_id, grade_level): true iff
--    at least one CONFIRMED session (either slot) resolves, by trainer
--    grade and by date, to this exact (version_id, grade_level). Confirmed
--    is the bar, not approved -- item 187 point 2's whole premise is that
--    the exposure exists well before approval, from the moment a trainer's
--    own confirmation makes the number real to someone.
-- 5. Two BEFORE UPDATE triggers (named to fire before row_history_capture,
--    alphabetically, on each table) that RAISE when a locked row's rate
--    (trainer_grade_rates) or a locked version's effective_date/
--    organization_id/corrects_version_id (trainer_grade_versions) would
--    change. `note` stays editable always -- it is documentation, not a
--    financial fact. These fire for ANY role, including the one that ran
--    202610200001/202610300001 as plain UPDATEs -- the exact gap Q1 found.
--
-- NOT done here, named rather than silently skipped (§20): the other four
-- versioned grids (location_bonus, language_bonus, duration_multiplier,
-- contract_type_uplift) share the identical "GRANT-only, no block"
-- exposure and are NOT made immutable by this migration. Mihai named
-- trainer_grade_rates specifically; the other four are a known, matching
-- gap for a later, separate decision -- see OPEN_ITEMS item 187.

alter table public.trainer_grade_versions
  add column corrects_version_id uuid references public.trainer_grade_versions(id);

alter table public.trainer_grade_versions
  add constraint trainer_grade_versions_no_self_correct_check
  check (corrects_version_id is null or corrects_version_id <> id);

-- One correction per corrected version -- a deterministic chain, never a
-- tree with two heads both claiming to correct the same row.
alter table public.trainer_grade_versions
  add constraint trainer_grade_versions_corrects_unique unique (corrects_version_id);

create index trainer_grade_versions_corrects_idx
  on public.trainer_grade_versions (corrects_version_id)
  where corrects_version_id is not null;

alter table public.trainer_grade_versions
  drop constraint trainer_grade_versions_org_date_unique;

create unique index trainer_grade_versions_org_date_head_unique
  on public.trainer_grade_versions (organization_id, effective_date)
  where corrects_version_id is null;

comment on column public.trainer_grade_versions.corrects_version_id is
  'The version THIS ROW corrects, same effective_date, same shape as contracts.amends_contract_id (202611090001) applied to a correction instead of a succession. NULL means this is an original (head) version. A version pointed at by another row''s corrects_version_id is superseded -- resolve_trainer_grade_version excludes it, and app.trainer_grade_rates/_versions'' own update triggers refuse to let it be edited in place once any session has resolved on it (202611090003).';

-- ---------------------------------------------------------------------------
-- app.resolve_trainer_grade_version -- the version-selection logic,
-- extracted from resolve_trainer_grade_rate so the lock-check below shares
-- the exact same definition of "which version applies to this date,"
-- rather than a second copy that could drift from it. Non-raising (SQL,
-- not plpgsql) -- NULL means no version applies, same as before; the
-- caller still decides whether that is an error.
-- ---------------------------------------------------------------------------
create or replace function app.resolve_trainer_grade_version(p_organization_id uuid, p_as_of date)
returns uuid
language sql
stable
set search_path to ''
as $$
  select id
  from public.trainer_grade_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
    and id not in (
      select corrects_version_id
      from public.trainer_grade_versions
      where corrects_version_id is not null
    )
  order by effective_date desc
  limit 1;
$$;

revoke all on function app.resolve_trainer_grade_version(uuid, date) from public;
grant execute on function app.resolve_trainer_grade_version(uuid, date) to authenticated, service_role;

-- resolve_trainer_grade_rate: same signature, same raises, same return
-- value for any date this database has ever had a version for -- only the
-- version-selection half moved into the function above. Not a behaviour
-- change for existing data: with zero corrections in place today, "not in
-- (select corrects_version_id ... where not null)" excludes nothing.
create or replace function app.resolve_trainer_grade_rate(p_organization_id uuid, p_grade_level integer, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_rate numeric;
begin
  v_version_id := app.resolve_trainer_grade_version(p_organization_id, p_as_of);

  if v_version_id is null then
    raise exception 'app.resolve_trainer_grade_rate: no trainer_grade_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate
  from public.trainer_grade_rates
  where version_id = v_version_id
    and grade_level = p_grade_level;

  if v_rate is null then
    raise exception 'app.resolve_trainer_grade_rate: version % has no row for grade level % -- incomplete version', v_version_id, p_grade_level;
  end if;

  return v_rate;
end;
$$;

-- ---------------------------------------------------------------------------
-- app.trainer_grade_rate_is_locked -- true iff a confirmed session already
-- relies on this exact (version_id, grade_level). The grade-on-date lookup
-- is the same "latest assignment on or before this date" app.resolve_
-- trainer_grade already uses, inlined rather than called: that function
-- RAISES when a trainer has no assignment at all, which would abort this
-- check (and the triggers below) for the ordinary case of a session slot
-- with no grade history yet, not something a lock-check should ever do.
-- ---------------------------------------------------------------------------
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
      and app.resolve_trainer_grade_version(v.organization_id, s.session_date) = p_version_id
  );
$$;

revoke all on function app.trainer_grade_rate_is_locked(uuid, integer) from public;
grant execute on function app.trainer_grade_rate_is_locked(uuid, integer) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- The two triggers. Named to sort alphabetically BEFORE each table's own
-- _row_history trigger (both tables' before-update triggers fire in name
-- order; "block_locked_update" < "row_history"), so a refused update never
-- reaches row_history_capture at all -- there is nothing to capture, the
-- statement aborted.
-- ---------------------------------------------------------------------------
create or replace function app.trainer_grade_rates_block_locked_update()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.rate is distinct from old.rate
     and app.trainer_grade_rate_is_locked(old.version_id, old.grade_level) then
    raise exception 'trainer_grade_rates: grade % on version % already has a confirmed session resolved against it -- a rate cannot be edited in place once relied on. Insert a new trainer_grade_versions row with corrects_version_id = %, carrying the corrected rates, instead (202611090003).', old.grade_level, old.version_id, old.version_id;
  end if;
  return new;
end;
$$;

create trigger trainer_grade_rates_block_locked_update
  before update on public.trainer_grade_rates
  for each row execute function app.trainer_grade_rates_block_locked_update();

create or replace function app.trainer_grade_versions_block_locked_update()
returns trigger
language plpgsql
set search_path to ''
as $$
declare
  v_locked boolean;
begin
  -- note is documentation, never a financial fact -- always editable,
  -- locked or not. Every other column is checked together: once any rate
  -- under this version is locked, the version's own identity (which
  -- dates it covers, which org, which version it corrects) is locked too.
  if new.effective_date is distinct from old.effective_date
     or new.organization_id is distinct from old.organization_id
     or new.corrects_version_id is distinct from old.corrects_version_id
  then
    select exists (
      select 1
      from public.trainer_grade_rates r
      where r.version_id = old.id
        and app.trainer_grade_rate_is_locked(old.id, r.grade_level)
    ) into v_locked;

    if v_locked then
      raise exception 'trainer_grade_versions: version % already has a confirmed session resolved under it -- its effective_date, organization_id and corrects_version_id cannot change. Insert a new, correcting version instead (202611090003).', old.id;
    end if;
  end if;
  return new;
end;
$$;

create trigger trainer_grade_versions_block_locked_update
  before update on public.trainer_grade_versions
  for each row execute function app.trainer_grade_versions_block_locked_update();

-- ===========================================================================
-- ASSERTIONS -- re-measure live, the same way this migration's own header
-- was written, rather than assert a number that could already have moved.
-- ===========================================================================
do $$
declare
  v_org uuid;
  v_version uuid;
  v_raised boolean;
  v_rate numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'immutable_trainer_grade_rates: no organization with slug wow-lab';
  end if;

  select id into v_version
  from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2026-09-01' and corrects_version_id is null;
  if v_version is null then
    raise exception 'immutable_trainer_grade_rates: no head trainer_grade_versions row effective 2026-09-01 for org %', v_org;
  end if;

  -- Grade 2 is locked today (Lorina's confirmed sessions resolve to it).
  -- A direct rate UPDATE must be refused -- prove it, do not assume it.
  v_raised := false;
  begin
    update public.trainer_grade_rates set rate = rate + 1 where version_id = v_version and grade_level = 2;
  exception when others then
    v_raised := true;
  end;
  if not v_raised then
    raise exception 'immutable_trainer_grade_rates: grade 2 (locked) accepted a rate UPDATE -- the trigger is not blocking it';
  end if;

  -- Grade 1 has zero confirmed sessions resolving to it today and must
  -- remain genuinely editable -- changed and reverted in the same
  -- transaction, so this assertion leaves no residue either way.
  update public.trainer_grade_rates set rate = 999 where version_id = v_version and grade_level = 1;
  select rate into v_rate from public.trainer_grade_rates where version_id = v_version and grade_level = 1;
  if v_rate is distinct from 999 then
    raise exception 'immutable_trainer_grade_rates: grade 1 (unlocked today) was refused a rate UPDATE -- it should not be locked yet';
  end if;
  update public.trainer_grade_rates set rate = 111 where version_id = v_version and grade_level = 1;

  -- The version itself: effective_date is locked the same way (grade 2's
  -- lock covers the whole version), note is not.
  v_raised := false;
  begin
    update public.trainer_grade_versions set effective_date = '2026-09-02' where id = v_version;
  exception when others then
    v_raised := true;
  end;
  if not v_raised then
    raise exception 'immutable_trainer_grade_rates: the live version accepted an effective_date UPDATE -- the trigger is not blocking it';
  end if;

  update public.trainer_grade_versions set note = note || ' ' where id = v_version;
  update public.trainer_grade_versions set note = rtrim(note) where id = v_version;

  -- Regression check: the resolver's own answer for a live date/grade is
  -- unchanged by the refactor into resolve_trainer_grade_version.
  if app.resolve_trainer_grade_rate(v_org, 1, '2026-09-05') <> 111 then
    raise exception 'immutable_trainer_grade_rates: resolve_trainer_grade_rate(grade 1, 2026-09-05) changed -- expected 111';
  end if;

  raise notice 'immutable_trainer_grade_rates: grade 2 locked and refused, grade 1 unlocked and accepted (then reverted), version effective_date locked, note still editable, resolver regression-clean';
end $$;
