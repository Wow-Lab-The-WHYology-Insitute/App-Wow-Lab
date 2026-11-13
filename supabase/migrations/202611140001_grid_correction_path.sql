-- 202611140001_grid_correction_path.sql
-- OPEN_ITEMS.md item 195 -- the sanctioned exception to item 194's guard.
-- Mihai's decisions, 2026-11-13 and 2026-11-14.
--
-- WHY THIS EXISTS. 202611120001 refuses any write that re-prices a
-- confirmed, unapproved slot. A correction of a rate that was wrong when
-- sessions were confirmed against it IS such a re-pricing, by definition, so
-- it cannot be "guarded by the same rule": it is that rule's sanctioned
-- exception. What makes it sanctioned is that it makes visible and recorded
-- exactly what the guard refuses silently. Without it, (a) fails Mihai's own
-- test for §26: "o regula care ar fi blocat o corectie necesara fara sa
-- ofere drumul corect e o regula care va fi ocolita la prima urgenta."
--
-- WHAT A CORRECTION IS. A new version whose corrects_version_id points at
-- the version it replaces, with that version's own effective_date. The old
-- version is never edited; app.resolve_grid_version stops returning it.
--
-- ONE CALCULATION, NOT TWO (§22). The impact statement a person reads before
-- confirming, the guard's refusal (P0W01) and the guard's check of a
-- sanctioned correction are all app.grid_correction_declaration() over two
-- app.grid_confirmed_pay_snapshot() calls, i.e. over
-- app.calculate_org_session_pay. The refusal's summary IS the statement's
-- summary; they cannot diverge, because there is only one of them.
--
-- THE STATEMENT GOES STALE, MEASURED, NOT HYPOTHETICAL: Cătălina confirmed
-- 10 sessions in 5 minutes on 2026-11-12 (item 184). So the statement the
-- person confirmed is written with the correction (grid_corrections), and at
-- write time the guard recomputes it in the same transaction. Identical ->
-- the correction goes through. Different -> refused (P0W02) with the new
-- statement, to be read and confirmed again.
--
-- APPROVED SLOTS ARE NOT TOUCHED (Mihai, 2026-11-14, the mixed case). Their
-- amount was frozen at approval and stays frozen. The statement lists them
-- separately -- frozen at X, would be Y at the corrected rate -- and the
-- correction applies to the unapproved ones. Refusing the whole correction
-- because one approved slot is in range would block exactly the real case:
-- approvals accumulate on past months and corrections reach back over them.
-- Changing an approved amount needs withdrawing the approval first, which
-- does not exist (item 186, question 2 to Anca). 195 and that question touch.
--
-- CAPABILITY, PROVISIONAL: the same gate as app.rpc_approve_session_pay
-- (platform owner, org.settings.manage, finance.operations.*,
-- finance.approvals.approve). A correction that re-prices already-asserted
-- work is at least as serious as an approval. PROVISIONAL: if Anca's
-- four-eyes answer says otherwise, this gate changes with it.
--
-- ALSO HERE (Mihai, 2026-11-14, point 4): location_bonus and language_bonus
-- get corrects_version_id in the same step. 202611120001 made them immutable
-- over confirmed pay with NO correction path at all -- more locked than the
-- two grids that had one. Same shape as 202611090003/005.
--
-- NOT COVERED, named (§20): a migration can still write a grid_corrections
-- row itself (it is the table owner) and so sanction its own correction. It
-- is then a recorded, visible act, not a silent one. contract_type_uplift is
-- not a pay grid (202611090006) and has no correction path.

-- ---------------------------------------------------------------------------
-- 1. location_bonus / language_bonus: corrects_version_id, head-only date
--    uniqueness, same as trainer_grade (202611090003) and duration (005).
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array['location_bonus_versions', 'language_bonus_versions'] loop
    execute format('alter table public.%1$I add column corrects_version_id uuid references public.%1$I(id)', t);
    execute format('alter table public.%1$I add constraint %2$I check (corrects_version_id is null or corrects_version_id <> id)', t, t || '_no_self_correct_check');
    execute format('alter table public.%1$I add constraint %2$I unique (corrects_version_id)', t, t || '_corrects_unique');
    execute format('create index %2$I on public.%1$I (corrects_version_id) where corrects_version_id is not null', t, t || '_corrects_idx');
    execute format('alter table public.%1$I drop constraint %2$I', t, t || '_org_date_unique');
    execute format('create unique index %2$I on public.%1$I (organization_id, effective_date) where corrects_version_id is null', t, t || '_org_date_head_unique');
    execute format(
      'comment on column public.%I.corrects_version_id is %L', t,
      'The version THIS ROW corrects, same effective_date. NULL = an original (head) version. A version pointed at by another row''s corrects_version_id is superseded: app.resolve_grid_version excludes it. Written only through app.rpc_apply_grid_correction in practice (202611140001, item 195).'
    );
  end loop;
end $$;

create or replace function app.resolve_grid_version(p_organization_id uuid, p_grid text, p_as_of date)
returns uuid
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
begin
  -- A version pointed at by another row's corrects_version_id is superseded
  -- and never returned. Four of the five grids carry it now; only
  -- contract_type_uplift, which pay never reads, does not (202611140001).
  case p_grid
    when 'trainer_grade' then
      select id into v_version_id from public.trainer_grade_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.trainer_grade_versions where corrects_version_id is not null)
      order by effective_date desc limit 1;
    when 'location_bonus' then
      select id into v_version_id from public.location_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.location_bonus_versions where corrects_version_id is not null)
      order by effective_date desc limit 1;
    when 'language_bonus' then
      select id into v_version_id from public.language_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.language_bonus_versions where corrects_version_id is not null)
      order by effective_date desc limit 1;
    when 'duration_multiplier' then
      select id into v_version_id from public.duration_multiplier_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.duration_multiplier_versions where corrects_version_id is not null)
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
-- 2. The snapshot: every CONFIRMED slot from p_from on, approved or not,
--    priced by the production function. `ap` = approved, `f` = the frozen
--    amount in bani. Replaces grid_guard_confirmed_unapproved_pay, which saw
--    unapproved slots only and so could not say which approved ones a
--    correction would have moved.
-- ---------------------------------------------------------------------------
create or replace function app.grid_confirmed_pay_snapshot(p_organization_id uuid, p_from date)
returns jsonb
language sql
volatile
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(
           p.session_id::text || ':' || p.slot,
           jsonb_build_object(
             'a', p.amount,
             'r', p.reason_code,
             'd', s.session_date,
             'ap', case p.slot when 'principal' then s.trainer_principal_approved_at is not null
                               else s.trainer_secundar_approved_at is not null end,
             'f', case p.slot when 'principal' then s.trainer_principal_approved_amount_bani
                              else s.trainer_secundar_approved_amount_bani end
           )
         ), '{}'::jsonb)
  from app.calculate_org_session_pay(p_organization_id, p_from, date '2100-01-01') p
  join public.sessions s on s.id = p.session_id
  where (p.slot = 'principal' and s.trainer_principal_confirmed_at is not null)
     or (p.slot = 'secundar' and s.trainer_secundar_confirmed_at is not null);
$$;

revoke all on function app.grid_confirmed_pay_snapshot(uuid, date) from public;

-- ---------------------------------------------------------------------------
-- 3. The statement. Deterministic (every array ordered), so the one a person
--    confirmed and the one recomputed at write time compare with =.
--    affected: unapproved slots whose pay moves, before -> after.
--    frozen:   approved slots the corrected rate WOULD move, listed, not moved.
--    summary:  the same numbers the guard's refusal has always carried.
-- ---------------------------------------------------------------------------
create or replace function app.grid_correction_declaration(p_before jsonb, p_after jsonb)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with d as (
    select k,
           b.v as bv,
           a.v as av,
           split_part(k, ':', 1)::uuid as sid,
           split_part(k, ':', 2) as slot,
           coalesce((coalesce(a.v, b.v)->>'ap')::boolean, false) as ap,
           coalesce(a.v, b.v)->>'f' as f
    from jsonb_each(p_after) a(k, v)
    full join jsonb_each(p_before) b(k, v) using (k)
    where a.v is distinct from b.v
  ),
  e as (
    select d.sid, d.slot, d.ap, s.session_date,
           (d.bv->>'a')::numeric as before_amount,
           (d.av->>'a')::numeric as after_amount,
           case when d.f is null then null else round(d.f::numeric / 100, 2) end as frozen_amount,
           case d.slot when 'principal' then s.trainer_principal_id else s.trainer_secundar_id end as tid,
           case d.slot when 'principal' then s.trainer_principal_approved_at else s.trainer_secundar_approved_at end as approved_at,
           c.name as client
    from d
    join public.sessions s on s.id = d.sid
    left join public.groups g on g.id = s.group_id
    left join public.clients c on c.id = g.client_id
  ),
  f as (
    select e.*, u.full_name as trainer
    from e left join public.users u on u.id = e.tid
  )
  select jsonb_build_object(
    'affected', coalesce((
      select jsonb_agg(jsonb_build_object(
               'session_id', sid, 'slot', slot, 'date', session_date, 'trainer_id', tid,
               'trainer', trainer, 'client', client, 'before', before_amount, 'after', after_amount)
             order by session_date, trainer, sid, slot)
      from f where not ap), '[]'::jsonb),
    'frozen', coalesce((
      select jsonb_agg(jsonb_build_object(
               'session_id', sid, 'slot', slot, 'date', session_date, 'trainer_id', tid,
               'trainer', trainer, 'client', client, 'approved_at', approved_at,
               'frozen', frozen_amount, 'would_be', after_amount)
             order by session_date, trainer, sid, slot)
      from f where ap), '[]'::jsonb),
    'by_trainer_month', coalesce((
      select jsonb_agg(jsonb_build_object(
               'month', month, 'trainer_id', tid, 'trainer', trainer, 'slots', slots,
               'before', before_total, 'after', after_total)
             order by month, trainer, tid)
      from (
        select to_char(session_date, 'YYYY-MM') as month, tid, trainer, count(*) as slots,
               round(coalesce(sum(before_amount), 0), 2) as before_total,
               round(coalesce(sum(after_amount), 0), 2) as after_total
        from f where not ap
        group by to_char(session_date, 'YYYY-MM'), tid, trainer
      ) m), '[]'::jsonb),
    'summary', (
      select jsonb_build_object(
               'sessions', count(distinct sid),
               'slots', count(*),
               'unpriceable_slots', count(*) filter (where before_amount is null or after_amount is null),
               'months', coalesce(to_jsonb(array_agg(distinct to_char(session_date, 'YYYY-MM') order by to_char(session_date, 'YYYY-MM'))), '[]'::jsonb),
               'total_before', round(coalesce(sum(before_amount), 0), 2),
               'total_after', round(coalesce(sum(after_amount), 0), 2),
               'delta', round(coalesce(sum(after_amount), 0) - coalesce(sum(before_amount), 0), 2))
      from f where not ap),
    'frozen_summary', (
      select jsonb_build_object(
               'slots', count(*),
               'frozen_total', round(coalesce(sum(frozen_amount), 0), 2),
               'would_be_total', round(coalesce(sum(after_amount), 0), 2))
      from f where ap)
  );
$$;

revoke all on function app.grid_correction_declaration(jsonb, jsonb) from public;

-- ---------------------------------------------------------------------------
-- 4. The record: the CONFIRMED STATEMENT, and nothing the version chain and
--    row_history already hold.
-- ---------------------------------------------------------------------------
create table public.grid_corrections (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  grid text not null check (grid in ('trainer_grade', 'duration_multiplier', 'location_bonus', 'language_bonus')),
  version_id uuid not null unique,
  declaration jsonb not null check (jsonb_typeof(declaration) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.grid_corrections is
  'One row per sanctioned grid correction (item 195, 202611140001). Its ONE purpose is the CONFIRMED STATEMENT: the list of sessions and the amounts the person SAW and accepted before the correction was written -- affected (unapproved, re-priced, before -> after) and frozen (approved, listed as unaffected, with what the corrected rate would have computed). Who, when, the old version and the new one are NOT here and must never be added: the correcting version row (created_by, created_at, corrects_version_id, its own id = version_id here) and row_history already hold them. This table is not a second source of truth for pay: the pay is always app.calculate_org_session_pay, and an approved amount is always sessions.*_approved_amount_bani. created_at/updated_at are §4 row mechanics, equal by construction to the version''s own created_at (same transaction), not an independent "when". Written only by app.rpc_apply_grid_correction; app.grid_guard_confirmed_pay compares this statement with its own recomputation and lets the correction through only if they are identical.';
comment on column public.grid_corrections.version_id is 'The correcting version (in the *_versions table named by `grid`). Not a foreign key: four possible tables.';
comment on column public.grid_corrections.declaration is 'Exactly what app.grid_correction_declaration() returned and the person confirmed: {affected, frozen, by_trainer_month, summary, frozen_summary}.';

create trigger grid_corrections_set_updated_at
  before update on public.grid_corrections
  for each row execute function public.trigger_set_updated_at();

-- No app user can UPDATE or DELETE it (no grant). A migration can; §8 makes
-- that a recorded act rather than a silent one.
create trigger grid_corrections_row_history
  before update or delete on public.grid_corrections
  for each row execute function public.row_history_capture();

alter table public.grid_corrections enable row level security;

revoke all on public.grid_corrections from anon, authenticated;
grant select on public.grid_corrections to authenticated;

-- Same read gate as the pay grids and /payroll's sums: the statement carries
-- amounts per trainer.
create policy "authenticated select grid_corrections" on public.grid_corrections
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

-- ---------------------------------------------------------------------------
-- 5. The guard, rebuilt on the shared snapshot + statement. Behaviour for an
--    ordinary write is unchanged: refused (P0W01) when an unapproved
--    confirmed slot's pay moves. New: a correction carrying a confirmed
--    statement (a grid_corrections row for this version) passes iff the
--    statement recomputed here is identical; otherwise P0W02.
-- ---------------------------------------------------------------------------
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
    select declaration into v_confirmed from public.grid_corrections where version_id = v_version;
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
$$;

revoke all on function app.grid_guard_confirmed_pay() from public;

comment on function app.grid_guard_confirmed_pay() is
  'Deferred constraint trigger on the four pay grids'' *_versions/*_rates (INSERT, UPDATE). Builds app.grid_correction_declaration() from app.grid_confirmed_pay_snapshot() with and without the write. An ordinary write that moves any confirmed, unapproved slot''s pay is refused (P0W01, the statement''s summary in DETAIL). A correction whose version carries a grid_corrections row passes only if that confirmed statement equals the one recomputed here; otherwise P0W02 with the new statement in DETAIL. Protects the pay, not the row. 202611120001/002, 202611140001; items 194/195; DATABASE_CONVENTIONS §26.';

drop function app.grid_guard_confirmed_unapproved_pay(uuid, date);

-- ---------------------------------------------------------------------------
-- 5b. Running the guard NOW, and only the guard. Found by
--     db/tests/grid_correction.sql block 3: `set constraints all immediate`
--     (what 202611120001's RPC used) stays in force for the rest of the
--     transaction, so a SECOND grid write in the same transaction fired the
--     guard on its header row before its rates existed -- a version judged
--     with no rows. One RPC call per request never hit it; a migration or a
--     test calling twice does. These switch the eight guard triggers only,
--     and put them back to deferred after.
-- ---------------------------------------------------------------------------
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
    public.language_bonus_versions_guard_confirmed_pay, public.language_bonus_rates_guard_confirmed_pay
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
    public.language_bonus_versions_guard_confirmed_pay, public.language_bonus_rates_guard_confirmed_pay
  immediate;
  perform app.grid_guard_defer();
end;
$$;

revoke all on function app.grid_guard_defer() from public;
revoke all on function app.grid_guard_check_now() from public;
grant execute on function app.grid_guard_defer() to authenticated;
grant execute on function app.grid_guard_check_now() to authenticated;

-- rpc_create_grid_version, unchanged except for the two calls above in place
-- of `set constraints all immediate`.
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
    perform app.grid_guard_defer();
    execute format(
      'insert into public.%I (organization_id, effective_date, created_by, note) values ($1, $2, $3, $4) returning id',
      p_grid || '_versions'
    ) into v_id using p_organization_id, p_effective_date, auth.uid(), nullif(btrim(coalesce(p_note, '')), '');
    execute format(
      'insert into public.%I (organization_id, version_id, %s) select $1, $2, %s from jsonb_to_recordset($3) as x(%s)',
      p_grid || '_rates', v_names, v_names, v_defs
    ) using p_organization_id, v_id, p_rows;
    perform app.grid_guard_check_now();
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

-- ---------------------------------------------------------------------------
-- 6. The correction RPCs. One body, two modes:
--    preview -- write the correction inside a subtransaction, read the
--               statement, roll it back. Nothing is left behind.
--    apply   -- write the correction and the statement the person confirmed;
--               the guard then compares it with its own recomputation.
--    SECURITY DEFINER: grid_corrections has no INSERT grant for anyone, and
--    the gate is the approval gate, not the grids' INSERT policy.
-- ---------------------------------------------------------------------------
create or replace function app.grid_correction_write(
  p_grid text,
  p_corrects_version_id uuid,
  p_note text,
  p_rows jsonb,
  p_declaration jsonb,
  p_apply boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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

    insert into public.grid_corrections (organization_id, grid, version_id, declaration)
    values (v_org, p_grid, v_id, p_declaration);
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

revoke all on function app.grid_correction_write(text, uuid, text, jsonb, jsonb, boolean) from public;
-- The gate is inside it (above); app is not exposed through PostgREST.
grant execute on function app.grid_correction_write(text, uuid, text, jsonb, jsonb, boolean) to authenticated;

create or replace function app.rpc_preview_grid_correction(p_grid text, p_corrects_version_id uuid, p_note text, p_rows jsonb)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app.grid_correction_write(p_grid, p_corrects_version_id, p_note, p_rows, null, false);
$$;

create or replace function app.rpc_apply_grid_correction(p_grid text, p_corrects_version_id uuid, p_note text, p_rows jsonb, p_declaration jsonb)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app.grid_correction_write(p_grid, p_corrects_version_id, p_note, p_rows, p_declaration, true);
$$;

comment on function app.rpc_preview_grid_correction(text, uuid, text, jsonb) is
  'Item 195. Returns {ok:true, declaration} -- the impact statement of correcting version p_corrects_version_id with p_rows, computed by writing the correction inside a subtransaction and rolling it back -- or {ok:false, error: unknown_grid|not_found|forbidden|already_corrected|incomplete_form|missing_bands}. Writes nothing.';
comment on function app.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) is
  'Item 195. Writes the correction (a new version, corrects_version_id, the corrected version''s effective_date) and p_declaration, the statement the person confirmed, into grid_corrections. The guard recomputes the statement; if it differs: {ok:false, error:declaration_stale, declaration: <the new one>} and nothing is written. Gate PROVISIONAL: org.settings.manage / finance.operations.* / finance.approvals.approve, as rpc_approve_session_pay.';

revoke all on function app.rpc_preview_grid_correction(text, uuid, text, jsonb) from public;
revoke all on function app.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) from public;
grant execute on function app.rpc_preview_grid_correction(text, uuid, text, jsonb) to authenticated;
grant execute on function app.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) to authenticated;

create or replace function public.rpc_preview_grid_correction(p_grid text, p_corrects_version_id uuid, p_note text, p_rows jsonb)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_preview_grid_correction(p_grid, p_corrects_version_id, p_note, p_rows);
$$;

create or replace function public.rpc_apply_grid_correction(p_grid text, p_corrects_version_id uuid, p_note text, p_rows jsonb, p_declaration jsonb)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_apply_grid_correction(p_grid, p_corrects_version_id, p_note, p_rows, p_declaration);
$$;

comment on function public.rpc_preview_grid_correction(text, uuid, text, jsonb) is 'PostgREST-exposed wrapper around app.rpc_preview_grid_correction(). SECURITY INVOKER, forwarding only.';
comment on function public.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) is 'PostgREST-exposed wrapper around app.rpc_apply_grid_correction(). SECURITY INVOKER, forwarding only.';

revoke all on function public.rpc_preview_grid_correction(text, uuid, text, jsonb) from public;
revoke all on function public.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) from public;
grant execute on function public.rpc_preview_grid_correction(text, uuid, text, jsonb) to authenticated;
grant execute on function public.rpc_apply_grid_correction(text, uuid, text, jsonb, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Assertions, on real wow-lab data, every write undone: the ordinary
-- backdated write is still refused with the same summary shape, and the
-- shared resolver still answers for every grid.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_actor uuid;
  v_g uuid;
  v_new uuid;
  v_refused boolean := false;
  v_detail jsonb;
  v_text text;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_actor from public.users where email = 'anca.tanasescu@gmail.com';
  v_g := app.resolve_grid_version(v_org, 'trainer_grade', current_date);

  begin
    insert into public.trainer_grade_versions (organization_id, effective_date, created_by, note)
      select v_org, effective_date + 1, v_actor, '202611140001 self-test' from public.trainer_grade_versions where id = v_g
      returning id into v_new;
    insert into public.trainer_grade_rates (organization_id, version_id, grade_level, rate)
      select v_org, v_new, grade_level, case when grade_level = 3 then rate + 10 else rate end
      from public.trainer_grade_rates where version_id = v_g;
    set constraints all immediate;
  exception when sqlstate 'P0W01' then
    v_refused := true;
    get stacked diagnostics v_text = pg_exception_detail;
    v_detail := v_text::jsonb;
    raise notice 'grid_correction_path self-test, refusal: %', sqlerrm;
  end;
  set constraints all deferred;
  if not v_refused then
    raise exception 'grid_correction_path: an ordinary backdated version that re-prices confirmed sessions was NOT refused';
  end if;
  if not (v_detail ? 'grid' and v_detail ? 'sessions' and v_detail ? 'months' and v_detail ? 'total_before' and v_detail ? 'delta') then
    raise exception 'grid_correction_path: the refusal DETAIL lost its shape: %', v_detail;
  end if;
  if exists (select 1 from public.trainer_grade_versions where note = '202611140001 self-test') then
    raise exception 'grid_correction_path: self-test left a row behind';
  end if;
  if app.resolve_grid_version(v_org, 'location_bonus', current_date) is null
     or app.resolve_grid_version(v_org, 'language_bonus', current_date) is null then
    raise exception 'grid_correction_path: location/language resolution broke';
  end if;
end $$;
