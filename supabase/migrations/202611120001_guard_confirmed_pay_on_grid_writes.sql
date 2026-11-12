-- 202611120001_guard_confirmed_pay_on_grid_writes.sql
-- OPEN_ITEMS.md item 194, variant (a), Mihai's decision 2026-11-12.
--
-- WHAT IS PROTECTED: the pay a CONFIRMED, NOT-YET-APPROVED session slot
-- resolves to -- not the grid row it resolved on. 202611090003/005 guarded
-- the row (UPDATE triggers); app users hold INSERT only on these tables, so
-- those triggers stopped exactly one actor, migrations, and no app user.
-- Item 194 induced the real gap: a NEW version dated before confirmed
-- sessions edits no row and still re-prices them (Test Org B 328,13 ->
-- 1.873,13 through the real screen; wow-lab +60,00 / +392,30 in a rollback).
--
-- THE RULE: any write to the four pay grids (trainer_grade,
-- duration_multiplier, location_bonus, language_bonus) -- a new version, a
-- row added to an existing version, a row or header updated -- is refused if
-- it changes app.calculate_org_session_pay's answer for any confirmed,
-- unapproved slot. By any writer: the screen, PostgREST, a migration.
-- * Approved slots are outside it on purpose: approval already froze their
--   amount (item 186). The exposed window is confirmation -> approval.
-- * Unconfirmed slots are outside it on purpose: nothing has been asserted
--   about them; re-pricing them is legitimate.
-- * A version dated after every confirmed session touches nothing and passes
--   without computing anything (fast path). So does a backdated version
--   whose values leave every confirmed slot's pay unchanged: the rule blocks
--   a retroactive change over an assertion, not a price change.
--
-- HOW "WOULD CHANGE" IS DECIDED: by calling the production function, twice
-- (§24) -- once on the state as written, once inside a subtransaction where
-- the write is undone, then rolled back. Nothing re-derives the price.
-- PL/pgSQL keeps local variables across the subtransaction's rollback, which
-- is what carries the "before" answer out.
--
-- WHEN: a DEFERRABLE INITIALLY DEFERRED constraint trigger, so a header and
-- its rows are judged together at commit (a migration) or at SET CONSTRAINTS
-- IMMEDIATE (the RPC below). A version created in the same transaction is
-- judged once, whole, by its header's event; its rows' events skip.
--
-- NOT COVERED, named rather than silent (§20): DELETE of grid rows or
-- headers. authenticated holds no DELETE grant, so only migrations and the
-- service role can take it. contract_type_uplift is not guarded:
-- calculate_session_pay never reads it (202611090006).
--
-- Also here: app.rpc_create_grid_version -- header + rows in ONE transaction,
-- replacing /payment-config's two client-composed inserts whose compensating
-- DELETE was refused (42501), leaving an orphan header (item 194 defect 2).
-- It refuses a version that drops a band the version it supersedes has
-- (defect 1: the duration form had 5 fields, the grid 7 rows).

create or replace function app.grid_guard_confirmed_unapproved_pay(p_organization_id uuid, p_from date)
returns jsonb
language sql
volatile
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(
           p.session_id::text || ':' || p.slot,
           jsonb_build_object('a', p.amount, 'r', p.reason_code, 'd', s.session_date)
         ), '{}'::jsonb)
  from app.calculate_org_session_pay(p_organization_id, p_from, date '2100-01-01') p
  join public.sessions s on s.id = p.session_id
  where (p.slot = 'principal' and s.trainer_principal_confirmed_at is not null and s.trainer_principal_approved_at is null)
     or (p.slot = 'secundar' and s.trainer_secundar_confirmed_at is not null and s.trainer_secundar_approved_at is null);
$$;

revoke all on function app.grid_guard_confirmed_unapproved_pay(uuid, date) from public;

create or replace function app.grid_guard_confirmed_pay()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_base text := regexp_replace(tg_table_name, '_(versions|rates)$', '');
  v_is_header boolean := tg_table_name ~ '_versions$';
  v_versions text := v_base || '_versions';
  v_rates text := v_base || '_rates';
  v_new_versions text := coalesce(current_setting('app.grid_guard_new_versions', true), '');
  v_version uuid;
  v_org uuid;
  v_from date;
  v_cols text;
  v_before jsonb;
  v_after jsonb;
  v_sessions integer;
  v_slots integer;
  v_unpriced integer;
  v_months text[];
  v_sum_before numeric;
  v_sum_after numeric;
begin
  if v_is_header then
    v_version := new.id;
  else
    v_version := new.version_id;
  end if;
  v_org := new.organization_id;

  if not (v_is_header and tg_op = 'INSERT')
     and v_version::text = any (string_to_array(v_new_versions, ',')) then
    return null;
  end if;

  if tg_op = 'UPDATE' and to_jsonb(new) = to_jsonb(old) then
    return null;
  end if;

  execute format('select effective_date from public.%I where id = $1', v_versions) into v_from using v_version;
  if v_is_header and tg_op = 'UPDATE' then
    v_from := least(old.effective_date, new.effective_date);
  end if;
  if v_from is null then
    return null;
  end if;

  if v_is_header and tg_op = 'INSERT' then
    perform set_config('app.grid_guard_new_versions', v_new_versions || ',' || v_version::text, true);
  end if;

  if not exists (
    select 1 from public.sessions s
    where s.organization_id = v_org
      and s.session_date >= v_from
      and ((s.trainer_principal_id is not null and s.trainer_principal_confirmed_at is not null and s.trainer_principal_approved_at is null)
        or (s.trainer_secundar_id is not null and s.trainer_secundar_confirmed_at is not null and s.trainer_secundar_approved_at is null))
  ) then
    return null;
  end if;

  v_after := app.grid_guard_confirmed_unapproved_pay(v_org, v_from);

  begin
    if v_is_header and tg_op = 'INSERT' then
      execute format('delete from public.%I where version_id = $1', v_rates) using v_version;
      execute format('delete from public.%I where id = $1', v_versions) using v_version;
    elsif tg_op = 'INSERT' then
      execute format('delete from public.%I where id = $1', v_rates) using new.id;
    else
      select string_agg(quote_ident(attname), ', ' order by attnum) into v_cols
      from pg_catalog.pg_attribute
      where attrelid = format('public.%I', tg_table_name)::regclass
        and attnum > 0 and not attisdropped and attname <> 'id';
      execute format(
        'update public.%1$I t set (%2$s) = (select %2$s from jsonb_populate_record(null::public.%1$I, $1)) where t.id = $2',
        tg_table_name, v_cols
      ) using to_jsonb(old), old.id;
    end if;
    v_before := app.grid_guard_confirmed_unapproved_pay(v_org, v_from);
    raise exception using errcode = 'P0W00';
  exception when sqlstate 'P0W00' then
    null;
  end;

  select count(distinct split_part(k, ':', 1)),
         count(*),
         count(*) filter (where av->>'a' is null or bv->>'a' is null),
         array_agg(distinct to_char((coalesce(av, bv)->>'d')::date, 'YYYY-MM') order by to_char((coalesce(av, bv)->>'d')::date, 'YYYY-MM')),
         coalesce(sum((bv->>'a')::numeric), 0),
         coalesce(sum((av->>'a')::numeric), 0)
    into v_sessions, v_slots, v_unpriced, v_months, v_sum_before, v_sum_after
  from jsonb_each(v_after) a(k, av)
  full join jsonb_each(v_before) b(k, bv) using (k)
  where av is distinct from bv;

  if v_slots > 0 then
    raise exception using
      errcode = 'P0W01',
      message = format(
        '%s confirmed session(s) (%s pay slot(s)) in %s would be re-priced by this %s change: %s -> %s lei (%s%s)%s. Confirmed, not-yet-approved pay is not changed retroactively; a version dated after every confirmed session is allowed. (202611120001, OPEN_ITEMS item 194)',
        v_sessions, v_slots, array_to_string(v_months, ', '), v_base,
        to_char(v_sum_before, 'FM999999990.00'), to_char(v_sum_after, 'FM999999990.00'),
        case when v_sum_after >= v_sum_before then '+' else '' end,
        to_char(v_sum_after - v_sum_before, 'FM999999990.00'),
        case when v_unpriced > 0 then format('; %s slot(s) would become unpriceable', v_unpriced) else '' end
      ),
      detail = jsonb_build_object(
        'grid', v_base,
        'sessions', v_sessions,
        'slots', v_slots,
        'unpriceable_slots', v_unpriced,
        'months', to_jsonb(v_months),
        'total_before', round(v_sum_before, 2),
        'total_after', round(v_sum_after, 2),
        'delta', round(v_sum_after - v_sum_before, 2)
      )::text;
  end if;

  return null;
end;
$$;

revoke all on function app.grid_guard_confirmed_pay() from public;

comment on function app.grid_guard_confirmed_pay() is
  'Deferred constraint trigger on the four pay grids'' *_versions/*_rates (INSERT, UPDATE). Refuses (SQLSTATE P0W01, JSON in DETAIL) any write that changes app.calculate_org_session_pay''s answer for a confirmed, unapproved slot, by comparing that function''s answer with and without the write. Protects the pay, not the row. 202611120001, OPEN_ITEMS item 194; DATABASE_CONVENTIONS §26.';

do $$
declare
  t text;
begin
  foreach t in array array[
    'trainer_grade_versions', 'trainer_grade_rates',
    'duration_multiplier_versions', 'duration_multiplier_rates',
    'location_bonus_versions', 'location_bonus_rates',
    'language_bonus_versions', 'language_bonus_rates'
  ] loop
    execute format(
      'create constraint trigger %I after insert or update on public.%I deferrable initially deferred for each row execute function app.grid_guard_confirmed_pay()',
      t || '_guard_confirmed_pay', t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- The one write path /payment-config uses. SECURITY INVOKER: the existing
-- INSERT policies (finance.operations.* / finance.reporting.* / platform
-- owner) stay the gate, unchanged, rather than a re-implemented check.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_create_grid_version(
  p_grid text,
  p_organization_id uuid,
  p_effective_date date,
  p_note text,
  p_rows jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_defs text;
  v_names text;
  v_key text;
  v_id uuid;
  v_prev uuid;
  v_incomplete boolean;
  v_missing text[];
  v_detail text;
  v_constraint text;
begin
  case p_grid
    when 'trainer_grade' then
      v_defs := 'grade_level integer, rate numeric'; v_names := 'grade_level, rate'; v_key := 'grade_level::text';
    when 'location_bonus' then
      v_defs := 'location_tier text, bonus_percent numeric'; v_names := 'location_tier, bonus_percent'; v_key := 'location_tier';
    when 'language_bonus' then
      v_defs := 'language_group text, bonus_percent numeric'; v_names := 'language_group, bonus_percent'; v_key := 'language_group';
    when 'duration_multiplier' then
      v_defs := 'duration_minutes integer, delivery_context text, multiplier numeric';
      v_names := 'duration_minutes, delivery_context, multiplier';
      v_key := 'duration_minutes::text || '':'' || delivery_context';
    when 'contract_type_uplift' then
      v_defs := 'contract_type text, uplift_percent numeric'; v_names := 'contract_type, uplift_percent'; v_key := 'contract_type';
    else
      raise exception 'app.rpc_create_grid_version: unknown grid %', p_grid;
  end case;

  if p_effective_date is null or p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0 then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;
  execute format('select exists (select 1 from jsonb_to_recordset($1) as x(%s) where not (x is not null))', v_defs)
    into v_incomplete using p_rows;
  if v_incomplete then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;

  -- Every band the superseded version has must be carried forward: a field
  -- missing from a form must never be able to delete a band (item 194).
  v_prev := app.resolve_grid_version(p_organization_id, p_grid, p_effective_date);
  if v_prev is not null then
    execute format(
      'select array_agg(k order by k) from (select %1$s as k from public.%2$I where version_id = $1 except select %1$s from jsonb_to_recordset($2) as x(%3$s)) m',
      v_key, p_grid || '_rates', v_defs
    ) into v_missing using v_prev, p_rows;
    if v_missing is not null then
      return jsonb_build_object('ok', false, 'error', 'missing_bands', 'missing', to_jsonb(v_missing));
    end if;
  end if;

  begin
    execute format(
      'insert into public.%I (organization_id, effective_date, created_by, note) values ($1, $2, $3, $4) returning id',
      p_grid || '_versions'
    ) into v_id using p_organization_id, p_effective_date, auth.uid(), nullif(btrim(coalesce(p_note, '')), '');
    execute format(
      'insert into public.%I (organization_id, version_id, %s) select $1, $2, %s from jsonb_to_recordset($3) as x(%s)',
      p_grid || '_rates', v_names, v_names, v_defs
    ) using p_organization_id, v_id, p_rows;
    set constraints all immediate;
  exception
    when sqlstate 'P0W01' then
      get stacked diagnostics v_detail = pg_exception_detail;
      return jsonb_build_object('ok', false, 'error', 'would_change_confirmed_pay', 'detail', v_detail::jsonb);
    when unique_violation then
      get stacked diagnostics v_constraint = constraint_name;
      if v_constraint ~ '_org_date_' then
        return jsonb_build_object('ok', false, 'error', 'date_taken');
      end if;
      raise;
  end;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

comment on function app.rpc_create_grid_version(text, uuid, date, text, jsonb) is
  'Creates one pay-grid version, header + rows, all or nothing. Returns {ok:true,id} or {ok:false,error:incomplete_form|missing_bands|date_taken|would_change_confirmed_pay,...}. Refuses a version that drops a key the version it supersedes has. Runs the confirmed-pay guard immediately so its refusal comes back as data, not as a commit-time error. SECURITY INVOKER: the grids'' INSERT policies are the gate. 202611120001, item 194.';

revoke all on function app.rpc_create_grid_version(text, uuid, date, text, jsonb) from public;
grant execute on function app.rpc_create_grid_version(text, uuid, date, text, jsonb) to authenticated;

create or replace function public.rpc_create_grid_version(
  p_grid text,
  p_organization_id uuid,
  p_effective_date date,
  p_note text,
  p_rows jsonb
)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_create_grid_version(p_grid, p_organization_id, p_effective_date, p_note, p_rows);
$$;

comment on function public.rpc_create_grid_version(text, uuid, date, text, jsonb) is
  'PostgREST-exposed wrapper around app.rpc_create_grid_version() -- the app schema is not exposed via the Data API. SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_create_grid_version(text, uuid, date, text, jsonb) from public;
grant execute on function public.rpc_create_grid_version(text, uuid, date, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Assertions, on real wow-lab data, every write undone.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_actor uuid;
  v_g uuid;
  v_new uuid;
  v_refused boolean;
  v_future_passed boolean;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_actor from public.users where email = 'anca.tanasescu@gmail.com';
  v_g := app.resolve_grid_version(v_org, 'trainer_grade', current_date);

  -- Migration-style write (no RPC): a version dated the day after the one in
  -- force, grade 3 + 10. 36 confirmed, unapproved sessions sit after it.
  v_refused := false;
  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
      select v_org, effective_date + 1, v_actor, '202611120001 self-test' from public.trainer_grade_versions where id = v_g
      returning id into v_new;
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
      select v_org, v_new, grade_level, case when grade_level = 3 then rate + 10 else rate end
      from public.trainer_grade_rates where version_id = v_g;
    set constraints all immediate;
  exception when sqlstate 'P0W01' then
    v_refused := true;
    raise notice 'guard_confirmed_pay self-test, refusal text: %', sqlerrm;
  end;
  set constraints all deferred;
  if not v_refused then
    raise exception 'guard_confirmed_pay: a backdated grade version that re-prices confirmed wow-lab sessions was NOT refused';
  end if;

  -- A version ten years ahead touches no confirmed session and must pass.
  v_future_passed := false;
  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
      values (v_org, current_date + 3650, v_actor, '202611120001 self-test') returning id into v_new;
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
      select v_org, v_new, grade_level, rate + 50 from public.trainer_grade_rates where version_id = v_g;
    set constraints all immediate;
    v_future_passed := true;
    raise exception using errcode = 'P0W00';
  exception when sqlstate 'P0W00' then
    null;
  end;
  set constraints all deferred;
  if not v_future_passed then
    raise exception 'guard_confirmed_pay: a future-dated version touching no confirmed session was refused';
  end if;

  if exists (select 1 from public.trainer_grade_versions where note = '202611120001 self-test') then
    raise exception 'guard_confirmed_pay: self-test left a row behind';
  end if;

  raise notice 'guard_confirmed_pay: backdated re-pricing refused, future-dated version passed, nothing left behind';
end $$;
