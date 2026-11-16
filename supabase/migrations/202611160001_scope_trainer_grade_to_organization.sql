-- 202611160001_scope_trainer_grade_to_organization.sql
--
-- A tenant-isolation breach, closed alone and first (Mihai, 2026-11-16,
-- OPEN_ITEMS item 198): app.resolve_trainer_grade selected a trainer's
-- grade by trainer_id and date only. trainer_grade_assignments carries
-- organization_id; the resolver never read it.
--
-- Induced 2026-11-16 on the real organization, rolled back (item 196, P5):
-- Test Org B's owner -- not a platform owner, not a wow-lab member --
-- inserted, through RLS on Org B's own capability, a grade-6 row for a
-- wow-lab trainer. Six confirmed wow-lab slots moved 762,00 -> 900,00 lei.
-- /payroll did not show it (SECURITY INVOKER, RLS hides the Org B row from
-- a wow-lab finance user); app.rpc_approve_session_pay, SECURITY DEFINER,
-- would have seen it and FROZEN the inflated amount. The breach is
-- laundered into an approved amount, which no path can change (item 186:
-- withdrawing an approval is not built).
--
-- THE FIX: the resolver takes the organization, first, like its five
-- siblings (resolve_trainer_grade_rate, _duration_multiplier,
-- _location_bonus, _language_bonus, resolve_grid_version), and filters on
-- it. The two-argument form is DROPPED, not left beside the new one: an
-- unscoped overload that still resolves is the breach kept available.
-- app.calculate_session_pay -- the only caller, measured over every
-- function in app/public -- passes the session's own organization. Its
-- body is otherwise byte-identical to the live one; its COMMENT survives
-- CREATE OR REPLACE.
--
-- What this does NOT close, named rather than implied (item 198): the
-- breach is one instance of a class. None of the 29 foreign keys between
-- org-scoped tables is composite with organization_id, and the INSERT
-- policies check only the new row's own organization. Induced the same
-- day: Org B wrote a band into wow-lab's live duration grid (Scoala
-- Altfel 30 min, 1.0 -> 9.0), and an Org B contract turned a wow-lab
-- client from prospect to active (public.client_effective_status). Those
-- are a separate decision; this migration is deliberately only the
-- resolver, before item 196's guard is built on top of it.
--
-- The reason_code classifier in app.calculate_org_session_pay matches
-- '%no trainer_grade_assignments row%'; the message below keeps that
-- phrase (db/tests/payroll_reason_code_coverage.sql asserts it).

drop function app.resolve_trainer_grade(uuid, date);

create function app.resolve_trainer_grade(p_organization_id uuid, p_trainer_id uuid, p_as_of date)
returns integer
language plpgsql
stable
set search_path to ''
as $function$
declare
  v_grade_level integer;
begin
  select grade_level into v_grade_level
  from public.trainer_grade_assignments
  where organization_id = p_organization_id
    and trainer_id = p_trainer_id
    and effective_from <= p_as_of
  order by effective_from desc
  limit 1;

  if v_grade_level is null then
    raise exception 'app.resolve_trainer_grade: no trainer_grade_assignments row for trainer % on or before % (org %)', p_trainer_id, p_as_of, p_organization_id;
  end if;

  return v_grade_level;
end;
$function$;

revoke all on function app.resolve_trainer_grade(uuid, uuid, date) from public;
grant execute on function app.resolve_trainer_grade(uuid, uuid, date) to authenticated, service_role;

comment on function app.resolve_trainer_grade(uuid, uuid, date) is
  'A trainer''s grade on a date, WITHIN ONE ORGANIZATION: the assignment with the latest effective_from on or before p_as_of (induced 2026-11-16, item 196). Organization-scoped since 202611160001 -- an assignment written in another organization never answers for this one (item 198). SECURITY INVOKER.';

CREATE OR REPLACE FUNCTION app.calculate_session_pay(p_session_id uuid, p_trainer_id uuid)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare
  v_org uuid;
  v_session_date date;
  v_duration_minutes integer;
  v_location_tier text;
  v_principal_id uuid;
  v_secundar_id uuid;
  v_group_id uuid;
  v_status text;
  v_cancellation_category text;
  v_delivery_format text;
  v_language_group text;
  v_grade integer;
  v_rate numeric;
  v_duration_multiplier numeric;
  v_location_bonus numeric;
  v_language_bonus numeric;
begin
  if p_trainer_id is null then
    raise exception 'app.calculate_session_pay: p_trainer_id must not be null';
  end if;

  select organization_id, session_date, duration_minutes, location_tier,
         trainer_principal_id, trainer_secundar_id, group_id, status, cancellation_category
    into v_org, v_session_date, v_duration_minutes, v_location_tier,
         v_principal_id, v_secundar_id, v_group_id, v_status, v_cancellation_category
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    raise exception 'app.calculate_session_pay: no session % ', p_session_id;
  end if;

  if p_trainer_id is distinct from v_principal_id and p_trainer_id is distinct from v_secundar_id then
    raise exception 'app.calculate_session_pay: trainer % is not the principal or secundar trainer on session %', p_trainer_id, p_session_id;
  end if;

  -- THE PAY RULE, and the only place it exists.
  --
  --     payable = confirmed OR (cancelled AND scoala_a_anulat_neanuntat)
  --
  -- A cancelled workshop that is NOT payable returns 0, deliberately rather
  -- than raising: nothing is missing, the answer is nothing. 0 is
  -- unambiguous because a calculable workshop cannot produce it. Returned
  -- BEFORE every input guard below, so a cancelled workshop with no
  -- duration recorded reads as a decided zero rather than as a gap -- which
  -- is the common case, since a workshop that never happened is exactly the
  -- one nobody finished filling in.
  if v_status = 'cancelled' and v_cancellation_category is distinct from 'scoala_a_anulat_neanuntat' then
    return 0;
  end if;

  if v_duration_minutes is null then
    raise exception 'app.calculate_session_pay: session % has no duration_minutes recorded', p_session_id;
  end if;

  if v_location_tier is null then
    raise exception 'app.calculate_session_pay: session % has no location_tier recorded', p_session_id;
  end if;

  select delivery_format, language_group into v_delivery_format, v_language_group
  from public.groups
  where id = v_group_id;

  if v_language_group is null then
    raise exception 'app.calculate_session_pay: group % has no language_group recorded', v_group_id;
  end if;

  v_grade := app.resolve_trainer_grade(v_org, p_trainer_id, v_session_date);
  v_rate := app.resolve_trainer_grade_rate(v_org, v_grade, v_session_date);
  v_duration_multiplier := app.resolve_duration_multiplier(v_org, v_duration_minutes, v_delivery_format, v_session_date);
  v_location_bonus := app.resolve_location_bonus(v_org, v_location_tier, v_session_date);
  v_language_bonus := app.resolve_language_bonus(v_org, v_language_group, v_session_date);

  return v_rate * v_duration_multiplier * (1 + v_location_bonus / 100 + v_language_bonus / 100);
end;
$function$
;

-- Self-test: the induced breach, re-run against the new resolver, inside a
-- subtransaction that is always rolled back. A grade written in Test Org B
-- for a wow-lab trainer must not answer for wow-lab, and must answer for
-- Test Org B (scoped, not a blanket deny).
do $$
declare
  v_org uuid := (select id from public.organizations where slug = 'wow-lab');
  v_orgb uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
  v_teo uuid := (select id from public.users where email = 'merisanteodora@gmail.com');
  v_bown uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
  v_before integer;
  v_after integer;
  v_in_b integer;
begin
  if v_org is null or v_orgb is null or v_teo is null or v_bown is null then
    raise notice '202611160001 self-test skipped: fixtures absent';
    return;
  end if;
  v_before := app.resolve_trainer_grade(v_org, v_teo, '2026-09-16');
  begin
    insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values (v_orgb, v_teo, 6, '2026-09-02', v_bown, 'manual');
    v_after := app.resolve_trainer_grade(v_org, v_teo, '2026-09-16');
    v_in_b := app.resolve_trainer_grade(v_orgb, v_teo, '2026-09-16');
    raise exception using errcode = 'P0W00';
  exception when sqlstate 'P0W00' then
    null;
  end;
  if v_after is distinct from v_before then
    raise exception '202611160001 self-test: an Org B assignment still changes wow-lab''s grade (% -> %)', v_before, v_after;
  end if;
  if v_in_b is distinct from 6 then
    raise exception '202611160001 self-test: the Org B assignment does not answer for Org B (got %)', v_in_b;
  end if;
end;
$$;
