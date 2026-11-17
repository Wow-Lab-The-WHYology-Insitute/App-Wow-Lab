-- 202611170001_pay_input_guard_and_statement_targets.sql
--
-- OPEN_ITEMS item 196, in the form Mihai decided (2026-11-16/17):
--   * item 194's guard extended to the two pay inputs it did not cover --
--     trainer_grade_assignments, and a group's pay columns (language_group,
--     delivery_format) -- refusing a write that re-prices confirmed,
--     not-yet-approved pay (P0W01), in both directions (a demotion is
--     refused exactly like a promotion; item 197 point 3);
--   * the SAME computation as the grid guard (app.grid_confirmed_pay_snapshot
--     + app.grid_correction_declaration, §22: one calculation), and the SAME
--     sanctioned form as item 195: a confirmed impact statement, recomputed
--     at write time, P0W02 if it moved;
--   * NO corrects_version_id: a retroactive promotion is a NEW FACT, not a
--     correction -- "3 from 01.09" stays true until the new row
--     (DATABASE_CONVENTIONS §26, "Succession or correction").
--
-- grid_corrections, OPTION (b) (Mihai, 2026-11-17). It held one polymorphic
-- version_id spanning four grids, consistent only because the one function
-- writing it was careful -- "integrity by promise". Item 196 would have taken
-- that promise from four targets to six. Instead: ONE COLUMN PER TARGET, a
-- CHECK that exactly one is set, and a composite key on each, like the 29
-- (item 198). More machinery than a polymorphic id -- but machinery the
-- DATABASE holds, not a function. Same reasoning as §26: a state made
-- impossible, not a rule written down. Done BEFORE the generalization, not
-- after: at 0 rows it costs nothing; later it would be a data migration.
-- The precondition is asserted below, at the moment of migrating, not
-- assumed from the morning's count.
--
-- Who and when are still NOT here (item 195's rule): the target row carries
-- them (a version's created_by/created_at, an assignment's set_by/created_at),
-- and row_history carries them for a group's update. `target` is a GENERATED
-- column, derived from which key is set -- never a second source of truth.
-- `written_xact` ties a statement to the transaction that wrote it: a group
-- is the one target that is not a new row, so "the statement for THIS
-- change" is the one written in the same transaction.
--
-- Found while building, included because it is the table being guarded:
-- trainer_grade_assignments' UNIQUE (trainer_id, effective_from) had no
-- organization. Users are global, so a row Org B writes for a shared person
-- on a date blocked wow-lab from writing that person on that date --
-- item 198's class, on a unique key (induced, db/tests/pay_input_guard.sql
-- point 9: 23505 before this migration). Now unique per organization.
--
-- Tests first, failing against the live schema: db/tests/pay_input_guard.sql.

-- 0. Precondition, at the moment of migrating: option (b) has no backfill.
do $$
declare n bigint;
begin
  select count(*) into n from public.grid_corrections;
  if n > 0 then
    raise exception '202611170001: grid_corrections has % row(s). Option (b) was decided on 0 rows and carries no backfill -- write one before applying this.', n;
  end if;
end;
$$;

-- 1. trainer_grade_assignments: unique per organization; referenceable with its organization.
alter table public.trainer_grade_assignments drop constraint trainer_grade_assignments_trainer_date_unique;
alter table public.trainer_grade_assignments add constraint trainer_grade_assignments_org_trainer_date_unique unique (organization_id, trainer_id, effective_from);
alter table public.trainer_grade_assignments add constraint trainer_grade_assignments_id_organization_id_key unique (id, organization_id);

-- 2. grid_corrections, option (b).
alter table public.grid_corrections drop column version_id, drop column grid;
alter table public.grid_corrections
  add column trainer_grade_version_id uuid,
  add column duration_multiplier_version_id uuid,
  add column location_bonus_version_id uuid,
  add column language_bonus_version_id uuid,
  add column trainer_grade_assignment_id uuid,
  add column group_id uuid,
  add column written_xact xid8 not null default pg_current_xact_id();
alter table public.grid_corrections add constraint grid_corrections_exactly_one_target
  check (num_nonnulls(trainer_grade_version_id, duration_multiplier_version_id, location_bonus_version_id, language_bonus_version_id, trainer_grade_assignment_id, group_id) = 1);
alter table public.grid_corrections add constraint grid_corrections_trainer_grade_version_id_org_fkey
  foreign key (trainer_grade_version_id, organization_id) references public.trainer_grade_versions (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_duration_multiplier_version_id_org_fkey
  foreign key (duration_multiplier_version_id, organization_id) references public.duration_multiplier_versions (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_location_bonus_version_id_org_fkey
  foreign key (location_bonus_version_id, organization_id) references public.location_bonus_versions (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_language_bonus_version_id_org_fkey
  foreign key (language_bonus_version_id, organization_id) references public.language_bonus_versions (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_trainer_grade_assignment_id_org_fkey
  foreign key (trainer_grade_assignment_id, organization_id) references public.trainer_grade_assignments (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_group_id_org_fkey
  foreign key (group_id, organization_id) references public.groups (id, organization_id)
  deferrable initially deferred;
alter table public.grid_corrections add constraint grid_corrections_trainer_grade_version_id_key unique (trainer_grade_version_id);
alter table public.grid_corrections add constraint grid_corrections_duration_multiplier_version_id_key unique (duration_multiplier_version_id);
alter table public.grid_corrections add constraint grid_corrections_location_bonus_version_id_key unique (location_bonus_version_id);
alter table public.grid_corrections add constraint grid_corrections_language_bonus_version_id_key unique (language_bonus_version_id);
alter table public.grid_corrections add constraint grid_corrections_trainer_grade_assignment_id_key unique (trainer_grade_assignment_id);
-- The six keys are DEFERRABLE INITIALLY DEFERRED, and that is load-bearing,
-- not a convenience. Every guard judges a write by UNDOING it inside a
-- subtransaction and recomputing; for a new version or a new assignment, the
-- undo is a DELETE of the very row the statement points at. An immediate key
-- would refuse that delete (found by the dry run, db/tests/pay_input_guard.sql
-- point 5). Deferred, the undo is never checked -- its subtransaction is
-- always rolled back -- and the key is checked at commit like any other.
create index grid_corrections_group_id_idx on public.grid_corrections (group_id) where group_id is not null;
alter table public.grid_corrections add column target text generated always as (
  case
    when trainer_grade_version_id is not null then 'trainer_grade'
    when duration_multiplier_version_id is not null then 'duration_multiplier'
    when location_bonus_version_id is not null then 'location_bonus'
    when language_bonus_version_id is not null then 'language_bonus'
    when trainer_grade_assignment_id is not null then 'trainer_grade_assignment'
    when group_id is not null then 'group_pay'
  end) stored;

comment on table public.grid_corrections is
  'One row per sanctioned change to a pay input (items 195, 196): the CONFIRMED STATEMENT -- the sessions and amounts the person SAW and accepted before the change was written. Exactly one target column is set (CHECK), each keyed with the organization (option (b), 202611170001): a grid version (a correction), a grade assignment (a new fact), or a group whose pay columns changed. Who and when are NOT here and must never be added: the target row and row_history hold them. Not a source of truth for pay: the pay is always app.calculate_org_session_pay. Written only by app.grid_correction_write, app.grade_assignment_write and app.group_pay_columns_write; the guards compare this statement with their own recomputation and let the write through only if identical.';
comment on column public.grid_corrections.target is 'Derived (GENERATED) from which target column is set. Never written, never a second truth.';
comment on column public.grid_corrections.written_xact is 'The transaction that wrote the statement. A group is not a new row, so the guard matches "the statement for THIS change" as the one written in the same transaction.';

-- 3. The grid guard: only its statement lookup changes, to the grid's own column.
CREATE OR REPLACE FUNCTION app.grid_guard_confirmed_pay()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  v_decl jsonb;
  v_sum jsonb;
  v_confirmed jsonb;
  v_sanctioned boolean := false;
begin
  -- This trigger's own undo (below) writes to the table it guards; with
  -- constraints IMMEDIATE that write would fire it again, without end
  -- (202611120002).
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
    execute format('select declaration from public.grid_corrections where %I = $1', v_base || '_version_id')
      into v_confirmed using v_version;
    v_sanctioned := v_confirmed is not null;
  end if;

  if not v_sanctioned and not exists (
    select 1 from public.sessions s
    where s.organization_id = v_org
      and s.session_date >= v_from
      and ((s.trainer_principal_id is not null and s.trainer_principal_confirmed_at is not null and s.trainer_principal_approved_at is null)
        or (s.trainer_secundar_id is not null and s.trainer_secundar_confirmed_at is not null and s.trainer_secundar_approved_at is null))
  ) then
    return null;
  end if;

  v_after := app.grid_confirmed_pay_snapshot(v_org, v_from);

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
    v_before := app.grid_confirmed_pay_snapshot(v_org, v_from);
    raise exception using errcode = 'P0W00';
  exception when sqlstate 'P0W00' then
    null;
  end;

  v_decl := app.grid_correction_declaration(v_before, v_after);

  if v_sanctioned then
    if v_decl = v_confirmed then
      return null;
    end if;
    raise exception using
      errcode = 'P0W02',
      message = format(
        'The impact statement confirmed for this %s correction no longer matches the pay it would change (confirmed: %s slot(s), %s -> %s lei; now: %s slot(s), %s -> %s lei). Something changed in between -- a confirmation, an approval, a session. Read the new statement and confirm it again. (202611140001, OPEN_ITEMS item 195)',
        v_base,
        v_confirmed->'summary'->>'slots', v_confirmed->'summary'->>'total_before', v_confirmed->'summary'->>'total_after',
        v_decl->'summary'->>'slots', v_decl->'summary'->>'total_before', v_decl->'summary'->>'total_after'
      ),
      detail = v_decl::text;
  end if;

  v_sum := v_decl->'summary';
  if (v_sum->>'slots')::integer > 0 then
    raise exception using
      errcode = 'P0W01',
      message = format(
        '%s confirmed session(s) (%s pay slot(s)) in %s would be re-priced by this %s change: %s -> %s lei (%s%s)%s. Confirmed, not-yet-approved pay is not changed retroactively; a version dated after every confirmed session is allowed, and a rate already used is corrected through app.rpc_apply_grid_correction. (202611120001/202611140001, OPEN_ITEMS items 194/195)',
        v_sum->>'sessions', v_sum->>'slots',
        (select string_agg(m, ', ') from jsonb_array_elements_text(v_sum->'months') m), v_base,
        to_char((v_sum->>'total_before')::numeric, 'FM999999990.00'), to_char((v_sum->>'total_after')::numeric, 'FM999999990.00'),
        case when (v_sum->>'delta')::numeric >= 0 then '+' else '' end,
        to_char((v_sum->>'delta')::numeric, 'FM999999990.00'),
        case when (v_sum->>'unpriceable_slots')::integer > 0 then format('; %s slot(s) would become unpriceable', v_sum->>'unpriceable_slots') else '' end
      ),
      detail = (jsonb_build_object('grid', v_base) || v_sum)::text;
  end if;

  return null;
end;
$function$;

-- 4. The guard for grade assignments and a group's pay columns. Same
--    computation, same undo-and-recompute, same statement, same codes.
create or replace function app.group_pay_guard_from(p_group_id uuid)
returns date
language sql
stable
set search_path = ''
as $$
  -- Where a group's pay statement starts: its first session, or today when it
  -- has none. ONE definition, used by the guard and the write path alike: the
  -- two statements are compared for equality, so they must start at the same
  -- date.
  select coalesce(min(s.session_date), current_date) from public.sessions s where s.group_id = p_group_id;
$$;
revoke all on function app.group_pay_guard_from(uuid) from public;

create or replace function app.pay_input_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid := new.organization_id;
  v_kind text;
  v_col text;
  v_from date;
  v_cols text;
  v_before jsonb;
  v_after jsonb;
  v_decl jsonb;
  v_sum jsonb;
  v_confirmed jsonb;
  v_sanctioned boolean;
  v_trainers uuid[];
begin
  if current_setting('app.grid_guard_undoing', true) = 'on' then
    return null;
  end if;
  if tg_op = 'UPDATE' and to_jsonb(new) = to_jsonb(old) then
    return null;
  end if;

  if tg_table_name = 'trainer_grade_assignments' then
    v_kind := 'trainer_grade_assignment';
    v_col := 'trainer_grade_assignment_id';
    -- Fields read through to_jsonb: one statement below serves both tables,
    -- and a groups row has no trainer_id/effective_from to name directly.
    v_from := new.effective_from;
    v_trainers := array[new.trainer_id];
    if tg_op = 'UPDATE' then
      v_from := least(v_from, (to_jsonb(old)->>'effective_from')::date);
      v_trainers := v_trainers || (to_jsonb(old)->>'trainer_id')::uuid;
    end if;
  elsif tg_table_name = 'groups' then
    if new.language_group is not distinct from old.language_group
       and new.delivery_format is not distinct from old.delivery_format then
      return null;
    end if;
    v_kind := 'group_pay';
    v_col := 'group_id';
    v_from := app.group_pay_guard_from(new.id);
  else
    raise exception 'app.pay_input_guard: not a guarded table: %', tg_table_name;
  end if;

  execute format('select declaration from public.grid_corrections where %I = $1 and written_xact = pg_current_xact_id()', v_col)
    into v_confirmed using new.id;
  v_sanctioned := v_confirmed is not null;

  if not v_sanctioned and not exists (
    select 1 from public.sessions s
    where s.organization_id = v_org
      and s.session_date >= v_from
      and (v_kind <> 'group_pay' or s.group_id = new.id)
      and ((s.trainer_principal_confirmed_at is not null and s.trainer_principal_approved_at is null
            and (v_trainers is null or s.trainer_principal_id = any (v_trainers)))
        or (s.trainer_secundar_confirmed_at is not null and s.trainer_secundar_approved_at is null
            and (v_trainers is null or s.trainer_secundar_id = any (v_trainers))))
  ) then
    return null;
  end if;

  v_after := app.grid_confirmed_pay_snapshot(v_org, v_from);
  begin
    perform set_config('app.grid_guard_undoing', 'on', true);
    if tg_op = 'INSERT' then
      execute format('delete from public.%I where id = $1', tg_table_name) using new.id;
    else
      select string_agg(quote_ident(attname), ', ' order by attnum) into v_cols
      from pg_catalog.pg_attribute
      where attrelid = format('public.%I', tg_table_name)::regclass
        and attnum > 0 and not attisdropped and attname <> 'id' and attgenerated = '';
      execute format(
        'update public.%1$I t set (%2$s) = (select %2$s from jsonb_populate_record(null::public.%1$I, $1)) where t.id = $2',
        tg_table_name, v_cols
      ) using to_jsonb(old), old.id;
    end if;
    v_before := app.grid_confirmed_pay_snapshot(v_org, v_from);
    raise exception using errcode = 'P0W00';
  exception when sqlstate 'P0W00' then
    null;
  end;

  v_decl := app.grid_correction_declaration(v_before, v_after);

  if v_sanctioned then
    if v_decl = v_confirmed then
      return null;
    end if;
    raise exception using
      errcode = 'P0W02',
      message = format(
        'The impact statement confirmed for this %s change no longer matches the pay it would change (confirmed: %s slot(s), %s -> %s lei; now: %s slot(s), %s -> %s lei). Read the new statement and confirm it again. (202611170001, OPEN_ITEMS item 196)',
        v_kind,
        v_confirmed->'summary'->>'slots', v_confirmed->'summary'->>'total_before', v_confirmed->'summary'->>'total_after',
        v_decl->'summary'->>'slots', v_decl->'summary'->>'total_before', v_decl->'summary'->>'total_after'
      ),
      detail = v_decl::text;
  end if;

  v_sum := v_decl->'summary';
  if (v_sum->>'slots')::integer > 0 then
    raise exception using
      errcode = 'P0W01',
      message = format(
        '%s confirmed session(s) (%s pay slot(s)) would be re-priced by this %s change: %s -> %s lei (%s%s). Confirmed, not-yet-approved pay is not changed without a confirmed impact statement: use app.grade_assignment_write / app.group_pay_columns_write. (202611170001, OPEN_ITEMS item 196)',
        v_sum->>'sessions', v_sum->>'slots', v_kind,
        to_char((v_sum->>'total_before')::numeric, 'FM999999990.00'), to_char((v_sum->>'total_after')::numeric, 'FM999999990.00'),
        case when (v_sum->>'delta')::numeric >= 0 then '+' else '' end,
        to_char((v_sum->>'delta')::numeric, 'FM999999990.00')
      ),
      detail = (jsonb_build_object('grid', v_kind) || v_sum)::text;
  end if;

  return null;
end;
$$;
revoke all on function app.pay_input_guard() from public;

create constraint trigger trainer_grade_assignments_guard_confirmed_pay
  after insert or update on public.trainer_grade_assignments
  deferrable initially deferred
  for each row execute function app.pay_input_guard();

create constraint trigger groups_guard_confirmed_pay
  after update of language_group, delivery_format on public.groups
  deferrable initially deferred
  for each row execute function app.pay_input_guard();

-- 5. Running the guards now, and only the guards: the ten triggers.
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
    public.trainer_grade_assignments_guard_confirmed_pay, public.groups_guard_confirmed_pay
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
    public.trainer_grade_assignments_guard_confirmed_pay, public.groups_guard_confirmed_pay
  immediate;
  perform app.grid_guard_defer();
end;
$$;

-- 6. The grid correction write: only its statement insert changes, to the grid's own column.
CREATE OR REPLACE FUNCTION app.grid_correction_write(p_grid text, p_corrects_version_id uuid, p_note text, p_rows jsonb, p_declaration jsonb, p_apply boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_defs text;
  v_names text;
  v_key text;
  v_org uuid;
  v_date date;
  v_id uuid := gen_random_uuid();
  v_exists boolean;
  v_incomplete boolean;
  v_missing text[];
  v_before jsonb;
  v_decl jsonb;
  v_detail text;
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
    else
      return jsonb_build_object('ok', false, 'error', 'unknown_grid');
  end case;

  execute format('select organization_id, effective_date from public.%I where id = $1', p_grid || '_versions')
    into v_org, v_date using p_corrects_version_id;
  if v_org is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- PROVISIONAL (item 195): the approval gate, exactly as
  -- app.rpc_approve_session_pay checks it. has_capability covers the
  -- platform owner.
  if not (app.has_capability('org.settings.manage', v_org)
          or app.has_capability('finance.operations.*', v_org)
          or app.has_capability('finance.approvals.approve', v_org)) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  execute format('select exists (select 1 from public.%I where corrects_version_id = $1)', p_grid || '_versions')
    into v_exists using p_corrects_version_id;
  if v_exists then
    return jsonb_build_object('ok', false, 'error', 'already_corrected');
  end if;

  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0
     or (p_apply and (p_declaration is null or jsonb_typeof(p_declaration) <> 'object')) then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;
  execute format('select exists (select 1 from jsonb_to_recordset($1) as x(%s) where not (x is not null))', v_defs)
    into v_incomplete using p_rows;
  if v_incomplete then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;

  -- A correction carries every band of the version it corrects (item 194).
  execute format(
    'select array_agg(k order by k) from (select %1$s as k from public.%2$I where version_id = $1 except select %1$s from jsonb_to_recordset($2) as x(%3$s)) m',
    v_key, p_grid || '_rates', v_defs
  ) into v_missing using p_corrects_version_id, p_rows;
  if v_missing is not null then
    return jsonb_build_object('ok', false, 'error', 'missing_bands', 'missing', to_jsonb(v_missing));
  end if;

  begin
    perform app.grid_guard_defer();
    if not p_apply then
      v_before := app.grid_confirmed_pay_snapshot(v_org, v_date);
    end if;

    execute format(
      'insert into public.%I (id, organization_id, effective_date, created_by, note, corrects_version_id) values ($1, $2, $3, $4, $5, $6)',
      p_grid || '_versions'
    ) using v_id, v_org, v_date, auth.uid(), nullif(btrim(coalesce(p_note, '')), ''), p_corrects_version_id;
    execute format(
      'insert into public.%I (organization_id, version_id, %s) select $1, $2, %s from jsonb_to_recordset($3) as x(%s)',
      p_grid || '_rates', v_names, v_names, v_defs
    ) using v_org, v_id, p_rows;

    if not p_apply then
      v_decl := app.grid_correction_declaration(v_before, app.grid_confirmed_pay_snapshot(v_org, v_date));
      raise exception using errcode = 'P0W00';
    end if;

    execute format('insert into public.grid_corrections (organization_id, %I, declaration) values ($1, $2, $3)', p_grid || '_version_id')
      using v_org, v_id, p_declaration;
    perform app.grid_guard_check_now();
  exception
    when sqlstate 'P0W00' then
      return jsonb_build_object('ok', true, 'declaration', v_decl);
    when sqlstate 'P0W02' then
      get stacked diagnostics v_detail = pg_exception_detail;
      return jsonb_build_object('ok', false, 'error', 'declaration_stale', 'declaration', v_detail::jsonb);
  end;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

-- 7. The sanctioned write paths. Same shape as app.grid_correction_write:
--    preview writes inside a subtransaction, reads the statement, rolls back;
--    apply writes the change and the statement the person confirmed, and
--    the guard compares them. Gate: PROVISIONAL, the same as item 195's
--    (org.settings.manage / finance.operations.* / finance.approvals.approve),
--    pending Anca's four-eyes answer.
create or replace function app.grade_assignment_write(
  p_organization_id uuid,
  p_trainer_id uuid,
  p_grade_level integer,
  p_effective_from date,
  p_declaration jsonb,
  p_apply boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := gen_random_uuid();
  v_before jsonb;
  v_decl jsonb;
  v_detail text;
begin
  if p_organization_id is null or p_trainer_id is null or p_grade_level is null or p_effective_from is null
     or (p_apply and (p_declaration is null or jsonb_typeof(p_declaration) <> 'object')) then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;
  if not (app.has_capability('org.settings.manage', p_organization_id)
          or app.has_capability('finance.operations.*', p_organization_id)
          or app.has_capability('finance.approvals.approve', p_organization_id)) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;
  -- Users are global; a grade belongs to a person IN an organization (item 198).
  if not exists (select 1 from public.user_org_roles where user_id = p_trainer_id and organization_id = p_organization_id) then
    return jsonb_build_object('ok', false, 'error', 'not_member');
  end if;
  if p_grade_level not between 1 and 6 then
    return jsonb_build_object('ok', false, 'error', 'invalid_grade');
  end if;
  if exists (select 1 from public.trainer_grade_assignments
             where organization_id = p_organization_id and trainer_id = p_trainer_id and effective_from = p_effective_from) then
    return jsonb_build_object('ok', false, 'error', 'date_taken');
  end if;

  begin
    perform app.grid_guard_defer();
    if not p_apply then
      v_before := app.grid_confirmed_pay_snapshot(p_organization_id, p_effective_from);
    end if;
    insert into public.trainer_grade_assignments (id, organization_id, trainer_id, grade_level, effective_from, set_by, source)
    values (v_id, p_organization_id, p_trainer_id, p_grade_level, p_effective_from, auth.uid(), 'manual');
    if not p_apply then
      v_decl := app.grid_correction_declaration(v_before, app.grid_confirmed_pay_snapshot(p_organization_id, p_effective_from));
      raise exception using errcode = 'P0W00';
    end if;
    insert into public.grid_corrections (organization_id, trainer_grade_assignment_id, declaration)
    values (p_organization_id, v_id, p_declaration);
    perform app.grid_guard_check_now();
  exception
    when sqlstate 'P0W00' then
      return jsonb_build_object('ok', true, 'declaration', v_decl);
    when sqlstate 'P0W02' then
      get stacked diagnostics v_detail = pg_exception_detail;
      return jsonb_build_object('ok', false, 'error', 'declaration_stale', 'declaration', v_detail::jsonb);
  end;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;
revoke all on function app.grade_assignment_write(uuid, uuid, integer, date, jsonb, boolean) from public;
grant execute on function app.grade_assignment_write(uuid, uuid, integer, date, jsonb, boolean) to authenticated;

create or replace function app.group_pay_columns_write(
  p_group_id uuid,
  p_language_group text,
  p_delivery_format text,
  p_declaration jsonb,
  p_apply boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_lang text;
  v_fmt text;
  v_from date;
  v_before jsonb;
  v_decl jsonb;
  v_detail text;
begin
  select organization_id, language_group, delivery_format into v_org, v_lang, v_fmt
  from public.groups where id = p_group_id;
  if v_org is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;
  if not (app.has_capability('org.settings.manage', v_org)
          or app.has_capability('finance.operations.*', v_org)
          or app.has_capability('finance.approvals.approve', v_org)) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;
  -- NULL means "leave as it is", not "clear it".
  if coalesce(p_language_group, v_lang) is not distinct from v_lang
     and coalesce(p_delivery_format, v_fmt) is not distinct from v_fmt then
    return jsonb_build_object('ok', false, 'error', 'no_change');
  end if;
  if p_apply and (p_declaration is null or jsonb_typeof(p_declaration) <> 'object') then
    return jsonb_build_object('ok', false, 'error', 'incomplete_form');
  end if;
  v_from := app.group_pay_guard_from(p_group_id);

  begin
    perform app.grid_guard_defer();
    if not p_apply then
      v_before := app.grid_confirmed_pay_snapshot(v_org, v_from);
    end if;
    update public.groups
    set language_group = coalesce(p_language_group, language_group),
        delivery_format = coalesce(p_delivery_format, delivery_format)
    where id = p_group_id;
    if not p_apply then
      v_decl := app.grid_correction_declaration(v_before, app.grid_confirmed_pay_snapshot(v_org, v_from));
      raise exception using errcode = 'P0W00';
    end if;
    insert into public.grid_corrections (organization_id, group_id, declaration)
    values (v_org, p_group_id, p_declaration);
    perform app.grid_guard_check_now();
  exception
    when sqlstate 'P0W00' then
      return jsonb_build_object('ok', true, 'declaration', v_decl);
    when sqlstate 'P0W02' then
      get stacked diagnostics v_detail = pg_exception_detail;
      return jsonb_build_object('ok', false, 'error', 'declaration_stale', 'declaration', v_detail::jsonb);
    when check_violation then
      return jsonb_build_object('ok', false, 'error', 'invalid_value');
  end;

  return jsonb_build_object('ok', true);
end;
$$;
revoke all on function app.group_pay_columns_write(uuid, text, text, jsonb, boolean) from public;
grant execute on function app.group_pay_columns_write(uuid, text, text, jsonb, boolean) to authenticated;

-- PostgREST-exposed wrappers. SECURITY INVOKER, forwarding only.
create or replace function public.rpc_preview_grade_assignment(p_organization_id uuid, p_trainer_id uuid, p_grade_level integer, p_effective_from date)
returns jsonb language sql security invoker set search_path = ''
as $$ select app.grade_assignment_write(p_organization_id, p_trainer_id, p_grade_level, p_effective_from, null, false); $$;
create or replace function public.rpc_apply_grade_assignment(p_organization_id uuid, p_trainer_id uuid, p_grade_level integer, p_effective_from date, p_declaration jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select app.grade_assignment_write(p_organization_id, p_trainer_id, p_grade_level, p_effective_from, p_declaration, true); $$;
create or replace function public.rpc_preview_group_pay_change(p_group_id uuid, p_language_group text, p_delivery_format text)
returns jsonb language sql security invoker set search_path = ''
as $$ select app.group_pay_columns_write(p_group_id, p_language_group, p_delivery_format, null, false); $$;
create or replace function public.rpc_apply_group_pay_change(p_group_id uuid, p_language_group text, p_delivery_format text, p_declaration jsonb)
returns jsonb language sql security invoker set search_path = ''
as $$ select app.group_pay_columns_write(p_group_id, p_language_group, p_delivery_format, p_declaration, true); $$;

revoke all on function public.rpc_preview_grade_assignment(uuid, uuid, integer, date) from public;
revoke all on function public.rpc_apply_grade_assignment(uuid, uuid, integer, date, jsonb) from public;
revoke all on function public.rpc_preview_group_pay_change(uuid, text, text) from public;
revoke all on function public.rpc_apply_group_pay_change(uuid, text, text, jsonb) from public;
grant execute on function public.rpc_preview_grade_assignment(uuid, uuid, integer, date) to authenticated;
grant execute on function public.rpc_apply_grade_assignment(uuid, uuid, integer, date, jsonb) to authenticated;
grant execute on function public.rpc_preview_group_pay_change(uuid, text, text) to authenticated;
grant execute on function public.rpc_apply_group_pay_change(uuid, text, text, jsonb) to authenticated;
