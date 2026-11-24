-- 202611240001_pay_input_delete_truncate_guard.sql
--
-- The missing verbs on the ten pay-input tables (OPEN_ITEMS item 208, form
-- confirmed by Mihai 2026-11-17). Items 194/196 guard INSERT and UPDATE on the
-- 8 grid tables, trainer_grade_assignments and groups' pay columns. DELETE and
-- TRUNCATE were not guarded at all: measured, a migration or service_role
-- DELETE of the grade-3 rate, or of Teodora's assignment, made 6 confirmed
-- slots (762,00 lei) unpriceable; the version in force deleted with its rates,
-- 46 slots (8.588,00 lei). Every guard was silent. App users hold no DELETE or
-- TRUNCATE grant on these tables (42501, and 202607100008); the writers left
-- are exactly the ones item 194 was first built against.
--
-- WHY CAPTURE, NOT SIMULATION -- the general reason, not only this case.
-- The INSERT/UPDATE guards judge a write by UNDOING it inside a rolled-back
-- subtransaction and comparing. A guard that judges by undo can guard only
-- operations that are reversible. A delete whose dependents are deleted in
-- the same transaction is not reversible BY DEFINITION, not by accident: the
-- undo of deleting a rate is re-inserting it, and its version may already be
-- gone -- measured, 23503. So for an irreversible operation the state before
-- it is CAPTURED, never simulated. Same principle as freezing the amount at
-- approval (item 186): the past is not recomputed, it is kept.
--
-- THE FORM:
--   * A row-level BEFORE DELETE trigger, on the first delete of the
--     transaction in each organization, stores that organization's snapshot
--     of ALL its confirmed slots (taken while every row still exists) in a
--     transaction-local setting, and counts the deletes.
--   * A deferred AFTER DELETE constraint trigger, at commit, snapshots again
--     and compares through grid_correction_declaration, the same computation
--     every other guard uses. A confirmed, not-yet-approved slot that moved,
--     including into "unpriceable", is refused with P0W01.
--   * No sanctioned path for DELETE, deliberately: a correction is a new
--     version (§26), a promotion a new assignment. The refusal names them.
--   * TRUNCATE: refused UNCONDITIONALLY by a statement-level BEFORE TRUNCATE
--     on all ten tables (P0W03; see the function for why unconditional).
--
-- KNOWN LIMITS, named so they are not found later as gaps:
--   * Only the slots confirmed BEFORE the first delete are compared: a
--     confirmation made after it, in the same transaction, is not the
--     delete's effect (test point 8; its SABOTAGE is point 17).
--   * Anything else that moves those slots in the same transaction after the
--     first delete -- a sanctioned correction, a withdrawn confirmation -- is
--     judged together with the delete and refused. That errs toward refusing;
--     such a migration splits its transactions.
--   * Any trigger-based guard can be removed by whoever owns the table:
--     ALTER TABLE ... DISABLE TRIGGER, DROP TRIGGER, setting
--     app.grid_guard_undoing by hand, or SET session_replication_role =
--     replica (measured 2026-11-24: allowed for the migration role, and it
--     silences every trigger, foreign keys included). These guards stop a
--     mistake, not a deliberate bypass, which is visible in the migration
--     that does it.
--   * Measured, both refused (2026-11-24): a re-pricing version inserted and
--     deleted again in one transaction is refused by THIS guard (net zero,
--     see the capture comment); a rate deleted and re-inserted identical is
--     refused by the INSERT guard, which judges its insert alone.
--   * DELETE on public.sessions is NOT guarded here: deleting a confirmed
--     session removes its pay outright, and service_role holds DELETE on it.
--     That is the sessions family (items 166, 199), named in item 208.
--
-- Test: db/tests/pay_input_delete_guard.sql, written first and run failing
-- against the live schema (7 probes accepted, 9 controls passing).

-- 1. Which slots a delete is judged on: those confirmed before it.
create or replace function app.pay_delete_guard_restrict(p_before jsonb, p_after jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(a.k, a.v), '{}'::jsonb)
  from jsonb_each(p_after) a(k, v)
  where p_before ? a.k;
$$;

-- 2. Transaction-local setting names, one set per organization.
create or replace function app.pay_delete_guard_setting(p_organization_id uuid, p_part text)
returns text
language sql
immutable
set search_path = ''
as $$
  select 'app.pay_delete_' || p_part || '_' || replace(p_organization_id::text, '-', '_');
$$;

-- 3. The capture, BEFORE each deleted row.
create or replace function app.pay_delete_guard_capture()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_n text := nullif(current_setting(app.pay_delete_guard_setting(old.organization_id, 'n'), true), '');
begin
  -- The INSERT/UPDATE guards' own undo deletes rows with this flag on, inside
  -- a subtransaction that is always rolled back; it is not a delete to judge.
  if current_setting('app.grid_guard_undoing', true) = 'on' then
    return old;
  end if;

  -- THE MOMENT OF CAPTURE is the transaction's first DELETE in this
  -- organization, so it sees the state AFTER any INSERT or UPDATE made
  -- earlier in the same transaction. That is not a gap. Each of those writes
  -- is judged by its own guard (194/196), which at commit undoes that write
  -- alone and compares; this guard judges what happens from its first delete
  -- on. Between them every change is judged once. Capturing earlier would
  -- judge the insert twice, once here as if it were the delete's effect.
  -- The one consequence, on the side of refusing: inserting a row that
  -- re-prices and then deleting it again in the same transaction is refused
  -- here even though the net effect is zero.
  if v_n is null then
    perform set_config(app.pay_delete_guard_setting(old.organization_id, 'before'),
                       app.grid_confirmed_pay_snapshot(old.organization_id, date '2000-01-01')::text, true);
    v_n := '0';
  end if;

  -- A counter, not a "checked" flag: a check forced earlier in the
  -- transaction (SET CONSTRAINTS ... IMMEDIATE) must not excuse a delete that
  -- comes after it (test point 7; SABOTAGE point 16).
  perform set_config(app.pay_delete_guard_setting(old.organization_id, 'n'), (v_n::int + 1)::text, true);
  return old;
end;
$$;

-- 4. The comparison, deferred to commit (or to SET CONSTRAINTS ... IMMEDIATE).
create or replace function app.pay_delete_guard_check()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid := old.organization_id;
  v_n text := nullif(current_setting(app.pay_delete_guard_setting(v_org, 'n'), true), '');
  v_before jsonb;
  v_decl jsonb;
  v_sum jsonb;
begin
  if current_setting('app.grid_guard_undoing', true) = 'on' then
    return null;
  end if;

  -- A delete with no capture behind it means the capture was bypassed:
  -- refuse rather than judge against nothing.
  if v_n is null then
    raise exception using
      errcode = 'P0W01',
      message = format('A DELETE on %s reached its pay check with no captured "before" state; refused rather than judged against nothing. (202611240001, OPEN_ITEMS item 208)', tg_table_name);
  end if;

  -- One comparison per organization per batch of deletes, not one per row.
  if v_n = coalesce(current_setting(app.pay_delete_guard_setting(v_org, 'ok'), true), '') then
    return null;
  end if;

  v_before := current_setting(app.pay_delete_guard_setting(v_org, 'before'))::jsonb;
  v_decl := app.grid_correction_declaration(
    v_before,
    app.pay_delete_guard_restrict(v_before, app.grid_confirmed_pay_snapshot(v_org, date '2000-01-01'))
  );
  v_sum := v_decl->'summary';

  if (v_sum->>'slots')::integer > 0 then
    raise exception using
      errcode = 'P0W01',
      message = format(
        'The DELETEs in this transaction (reaching %s) would change %s confirmed session(s) (%s pay slot(s)) in %s: %s -> %s lei (%s%s)%s. Confirmed, not-yet-approved pay is never changed by deleting what it rests on: a rate is corrected by a correcting version (app.rpc_apply_grid_correction), a grade by a new assignment (app.grade_assignment_write). (202611240001, OPEN_ITEMS item 208)',
        tg_table_name, v_sum->>'sessions', v_sum->>'slots',
        (select string_agg(m, ', ') from jsonb_array_elements_text(v_sum->'months') m),
        to_char((v_sum->>'total_before')::numeric, 'FM999999990.00'), to_char((v_sum->>'total_after')::numeric, 'FM999999990.00'),
        case when (v_sum->>'delta')::numeric >= 0 then '+' else '' end,
        to_char((v_sum->>'delta')::numeric, 'FM999999990.00'),
        case when (v_sum->>'unpriceable_slots')::integer > 0 then format('; %s slot(s) would become unpriceable', v_sum->>'unpriceable_slots') else '' end
      ),
      detail = (jsonb_build_object('verb', 'DELETE', 'table', tg_table_name) || v_sum)::text;
  end if;

  perform set_config(app.pay_delete_guard_setting(v_org, 'ok'), v_n, true);
  return null;
end;
$$;

-- 5. TRUNCATE.
create or replace function app.pay_truncate_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- UNCONDITIONAL (Mihai, 2026-11-17). The first proposal refused only while
  -- a confirmed, unapproved slot existed anywhere. That condition was copied
  -- from the DELETE guard's shape for symmetry, not kept for any test
  -- organization. Measured before dropping it: no test, script, seed or
  -- migration in this repository truncates any of these tables, and app
  -- roles have held no TRUNCATE grant since 202607100008. A TRUNCATE of a grid
  -- with no confirmed session is just as catastrophic -- the next confirmation
  -- is unpriceable -- and there is no legitimate case against refusing it.
  -- It sees no rows; TRUNCATE ... CASCADE fires it on every guarded table the
  -- cascade reaches (test point 12).
  raise exception using
    errcode = 'P0W03',
    message = format('TRUNCATE of %s is refused: it is a pay input, and emptying it is never a correction. Remove a row by its own path, or remove this trigger deliberately in a migration that says why. (202611240001, OPEN_ITEMS item 208)', tg_table_name);
end;
$$;

-- 6. The thirty triggers, ten per kind.
do $$
declare
  t text;
begin
  foreach t in array array[
    'trainer_grade_versions', 'trainer_grade_rates',
    'duration_multiplier_versions', 'duration_multiplier_rates',
    'location_bonus_versions', 'location_bonus_rates',
    'language_bonus_versions', 'language_bonus_rates',
    'trainer_grade_assignments', 'groups'
  ] loop
    execute format('create trigger %I before delete on public.%I for each row execute function app.pay_delete_guard_capture()',
                   t || '_guard_delete_capture', t);
    execute format('create constraint trigger %I after delete on public.%I deferrable initially deferred for each row execute function app.pay_delete_guard_check()',
                   t || '_guard_confirmed_pay_delete', t);
    execute format('create trigger %I before truncate on public.%I for each statement execute function app.pay_truncate_guard()',
                   t || '_guard_truncate', t);
  end loop;
end $$;

-- 7. "Running the guards now" covers the DELETE checks too.
create or replace function app.grid_guard_defer()
returns void
language plpgsql
set search_path = ''
as $$
begin
  set constraints
    public.trainer_grade_versions_guard_confirmed_pay, public.trainer_grade_rates_guard_confirmed_pay,
    public.duration_multiplier_versions_guard_confirmed_pay, public.duration_multiplier_rates_guard_confirmed_pay,
    public.location_bonus_versions_guard_confirmed_pay, public.location_bonus_rates_guard_confirmed_pay,
    public.language_bonus_versions_guard_confirmed_pay, public.language_bonus_rates_guard_confirmed_pay,
    public.trainer_grade_assignments_guard_confirmed_pay, public.groups_guard_confirmed_pay,
    public.trainer_grade_versions_guard_confirmed_pay_delete, public.trainer_grade_rates_guard_confirmed_pay_delete,
    public.duration_multiplier_versions_guard_confirmed_pay_delete, public.duration_multiplier_rates_guard_confirmed_pay_delete,
    public.location_bonus_versions_guard_confirmed_pay_delete, public.location_bonus_rates_guard_confirmed_pay_delete,
    public.language_bonus_versions_guard_confirmed_pay_delete, public.language_bonus_rates_guard_confirmed_pay_delete,
    public.trainer_grade_assignments_guard_confirmed_pay_delete, public.groups_guard_confirmed_pay_delete
  deferred;
end;
$$;

create or replace function app.grid_guard_check_now()
returns void
language plpgsql
set search_path = ''
as $$
begin
  set constraints
    public.trainer_grade_versions_guard_confirmed_pay, public.trainer_grade_rates_guard_confirmed_pay,
    public.duration_multiplier_versions_guard_confirmed_pay, public.duration_multiplier_rates_guard_confirmed_pay,
    public.location_bonus_versions_guard_confirmed_pay, public.location_bonus_rates_guard_confirmed_pay,
    public.language_bonus_versions_guard_confirmed_pay, public.language_bonus_rates_guard_confirmed_pay,
    public.trainer_grade_assignments_guard_confirmed_pay, public.groups_guard_confirmed_pay,
    public.trainer_grade_versions_guard_confirmed_pay_delete, public.trainer_grade_rates_guard_confirmed_pay_delete,
    public.duration_multiplier_versions_guard_confirmed_pay_delete, public.duration_multiplier_rates_guard_confirmed_pay_delete,
    public.location_bonus_versions_guard_confirmed_pay_delete, public.location_bonus_rates_guard_confirmed_pay_delete,
    public.language_bonus_versions_guard_confirmed_pay_delete, public.language_bonus_rates_guard_confirmed_pay_delete,
    public.trainer_grade_assignments_guard_confirmed_pay_delete, public.groups_guard_confirmed_pay_delete
  immediate;
  perform app.grid_guard_defer();
end;
$$;

revoke all on function app.pay_delete_guard_capture() from public;
revoke all on function app.pay_delete_guard_check() from public;
revoke all on function app.pay_truncate_guard() from public;

-- 8. Self-test: thirty triggers, of the right kind, on the right tables.
do $$
declare
  v_capture int; v_check int; v_truncate int;
begin
  select count(*) filter (where tgname like '%\_guard\_delete\_capture' and tgtype & 2 = 2 and tgtype & 8 = 8 and tgtype & 1 = 1),
         count(*) filter (where tgname like '%\_guard\_confirmed\_pay\_delete' and tgconstraint <> 0 and tgdeferrable and tginitdeferred and tgtype & 8 = 8),
         count(*) filter (where tgname like '%\_guard\_truncate' and tgtype & 2 = 2 and tgtype & 32 = 32 and tgtype & 1 = 0)
    into v_capture, v_check, v_truncate
  from pg_catalog.pg_trigger
  where not tgisinternal;
  if (v_capture, v_check, v_truncate) <> (10, 10, 10) then
    raise exception 'self-test: expected 10/10/10 capture/check/truncate triggers, found %/%/%', v_capture, v_check, v_truncate;
  end if;
end $$;
