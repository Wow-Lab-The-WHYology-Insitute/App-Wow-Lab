-- 202611120002_grid_guard_no_recursion_on_update_undo.sql
-- OPEN_ITEMS.md item 194. Fix to 202611120001, found by its own test
-- (db/tests/grid_confirmed_pay_guard.sql block 10) before anything relied
-- on it: for an UPDATE, the guard computes "before" by reverting the row
-- with an UPDATE inside a subtransaction. Under SET CONSTRAINTS IMMEDIATE
-- that revert fires the same constraint trigger again, which reverts again
-- -- "stack depth limit exceeded". INSERTs were unaffected (their undo is a
-- DELETE, which the trigger does not watch).
--
-- Fix: a transaction-local flag set inside the undo subtransaction; the
-- trigger returns at once while it is on. set_config(..., true) inside the
-- subtransaction is rolled back with it, so the flag never outlives the undo.

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
  -- This trigger's own undo (below) writes to the table it guards; with
  -- constraints IMMEDIATE that write would fire it again, without end.
  if current_setting('app.grid_guard_undoing', true) = 'on' then
    return null;
  end if;

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
    perform set_config('app.grid_guard_undoing', 'on', true);
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

