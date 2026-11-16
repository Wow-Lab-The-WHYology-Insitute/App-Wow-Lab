-- 202611160002_composite_org_keys_wave1_pay.sql
--
-- Tenant isolation, wave 1 of 3 (OPEN_ITEMS item 198): every foreign key
-- whose CHILD is a pay table becomes composite with organization_id, so the
-- DATABASE refuses a row in one organization that points at a parent in
-- another. Decided by Mihai 2026-11-16; waves ordered by money (2: clients,
-- contracts, legal entities; 3: the rest).
--
-- WHY A STRUCTURAL REFUSAL AND NOT MORE FILTERS. The first audit of the 79
-- functions was a SCAN, not an audit: "does organization_id appear in the
-- statement" cannot tell FILTERS-on-organization from MENTIONS-organization.
-- app.resolve_grid_version is the proof -- filtered in its outer query, not
-- in the subquery that excludes corrected versions -- and the scan passed it.
-- No method of that kind can be validated as complete. A composite key makes
-- completeness irrelevant: whatever any function reads, a cross-org parent
-- cannot exist under it. This is DATABASE_CONVENTIONS section 26 applied to
-- isolation: not a rule written down, a state made impossible.
--
-- Induced before this migration, as Test Org B's owner through RLS (item
-- 198), and now permanent in db/tests/cross_org_write_isolation.sql, which was
-- written FIRST and run against the live schema failing: 15/15 cross-org
-- writes accepted; a confirmed wow-lab slot 127,00 -> 1.143,00 through an Org
-- B band; and an Org B "correction" left wow-lab with NO version in force on
-- all four pay grids.
--
-- ITEM 194'S GUARD IS REDONE HERE, by construction rather than by code. It
-- snapshots the organization of the row WRITTEN (new.organization_id) and was
-- blind to a row that moved another organization. With these keys a rates
-- row's organization IS its version's, and a correcting version's IS the
-- corrected one's, so the guard's premise becomes a database invariant
-- instead of an assumption. The guard's body is unchanged on purpose.
--
-- Plus the filter the scan missed: the corrected-version subquery in
-- app.resolve_grid_version is scoped to the organization, on all four
-- grids. Two independent layers; the test shows each holding alone, then
-- removes both and fails (points 4-6).
--
-- Measured before writing: 0 existing cross-org references across all 15
-- keys (real data, 2026-11-16), so nothing here can refuse to apply on data.
-- Delete rules are kept as they were: admin_rates cascades, the rest NO
-- ACTION. Nullable keys (corrects_version_id, groups.contract_id) stay
-- MATCH SIMPLE: a NULL parent is not checked, exactly as before.
--
-- OUT OF SCOPE BY DESIGN, written so it does not read as a miss: the 26
-- foreign keys to `users`. Users are global -- one person, many
-- organizations -- and `users` has no organization_id, so a composite key
-- against it cannot exist. Isolation there is the reader's job, filtering
-- on the row's own organization (202611160001 did that for grades).

-- 1. The parents: (id, organization_id) as a referenceable unique key.
alter table public.admin_rate_versions add constraint admin_rate_versions_id_organization_id_key unique (id, organization_id);
alter table public.contract_type_uplift_versions add constraint contract_type_uplift_versions_id_organization_id_key unique (id, organization_id);
alter table public.duration_multiplier_versions add constraint duration_multiplier_versions_id_organization_id_key unique (id, organization_id);
alter table public.language_bonus_versions add constraint language_bonus_versions_id_organization_id_key unique (id, organization_id);
alter table public.lesson_plan_rate_versions add constraint lesson_plan_rate_versions_id_organization_id_key unique (id, organization_id);
alter table public.location_bonus_versions add constraint location_bonus_versions_id_organization_id_key unique (id, organization_id);
alter table public.trainer_grade_versions add constraint trainer_grade_versions_id_organization_id_key unique (id, organization_id);
alter table public.groups add constraint groups_id_organization_id_key unique (id, organization_id);
alter table public.clients add constraint clients_id_organization_id_key unique (id, organization_id);
alter table public.contracts add constraint contracts_id_organization_id_key unique (id, organization_id);
alter table public.payroll_periods add constraint payroll_periods_id_organization_id_key unique (id, organization_id);

-- 2. The fifteen keys.
alter table public.admin_rates drop constraint admin_rates_version_id_fkey;
alter table public.admin_rates add constraint admin_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.admin_rate_versions (id, organization_id) on delete cascade;
alter table public.contract_type_uplift_rates drop constraint contract_type_uplift_rates_version_id_fkey;
alter table public.contract_type_uplift_rates add constraint contract_type_uplift_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.contract_type_uplift_versions (id, organization_id);
alter table public.duration_multiplier_rates drop constraint duration_multiplier_rates_version_id_fkey;
alter table public.duration_multiplier_rates add constraint duration_multiplier_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.duration_multiplier_versions (id, organization_id);
alter table public.language_bonus_rates drop constraint language_bonus_rates_version_id_fkey;
alter table public.language_bonus_rates add constraint language_bonus_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.language_bonus_versions (id, organization_id);
alter table public.lesson_plan_rates drop constraint lesson_plan_rates_version_id_fkey;
alter table public.lesson_plan_rates add constraint lesson_plan_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.lesson_plan_rate_versions (id, organization_id);
alter table public.location_bonus_rates drop constraint location_bonus_rates_version_id_fkey;
alter table public.location_bonus_rates add constraint location_bonus_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.location_bonus_versions (id, organization_id);
alter table public.trainer_grade_rates drop constraint trainer_grade_rates_version_id_fkey;
alter table public.trainer_grade_rates add constraint trainer_grade_rates_version_id_org_fkey
  foreign key (version_id, organization_id) references public.trainer_grade_versions (id, organization_id);
alter table public.duration_multiplier_versions drop constraint duration_multiplier_versions_corrects_version_id_fkey;
alter table public.duration_multiplier_versions add constraint duration_multiplier_versions_corrects_version_id_org_fkey
  foreign key (corrects_version_id, organization_id) references public.duration_multiplier_versions (id, organization_id);
alter table public.language_bonus_versions drop constraint language_bonus_versions_corrects_version_id_fkey;
alter table public.language_bonus_versions add constraint language_bonus_versions_corrects_version_id_org_fkey
  foreign key (corrects_version_id, organization_id) references public.language_bonus_versions (id, organization_id);
alter table public.location_bonus_versions drop constraint location_bonus_versions_corrects_version_id_fkey;
alter table public.location_bonus_versions add constraint location_bonus_versions_corrects_version_id_org_fkey
  foreign key (corrects_version_id, organization_id) references public.location_bonus_versions (id, organization_id);
alter table public.trainer_grade_versions drop constraint trainer_grade_versions_corrects_version_id_fkey;
alter table public.trainer_grade_versions add constraint trainer_grade_versions_corrects_version_id_org_fkey
  foreign key (corrects_version_id, organization_id) references public.trainer_grade_versions (id, organization_id);
alter table public.sessions drop constraint sessions_group_id_fkey;
alter table public.sessions add constraint sessions_group_id_org_fkey
  foreign key (group_id, organization_id) references public.groups (id, organization_id);
alter table public.groups drop constraint groups_client_id_fkey;
alter table public.groups add constraint groups_client_id_org_fkey
  foreign key (client_id, organization_id) references public.clients (id, organization_id);
alter table public.groups drop constraint groups_contract_id_fkey;
alter table public.groups add constraint groups_contract_id_org_fkey
  foreign key (contract_id, organization_id) references public.contracts (id, organization_id);
alter table public.payroll_period_totals drop constraint payroll_period_totals_payroll_period_id_fkey;
alter table public.payroll_period_totals add constraint payroll_period_totals_payroll_period_id_org_fkey
  foreign key (payroll_period_id, organization_id) references public.payroll_periods (id, organization_id);

-- 3. The subquery the scan missed: corrected versions excluded within the organization only.
CREATE OR REPLACE FUNCTION app.resolve_grid_version(p_organization_id uuid, p_grid text, p_as_of date)
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
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
        and id not in (select corrects_version_id from public.trainer_grade_versions where corrects_version_id is not null and organization_id = p_organization_id)
      order by effective_date desc limit 1;
    when 'location_bonus' then
      select id into v_version_id from public.location_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.location_bonus_versions where corrects_version_id is not null and organization_id = p_organization_id)
      order by effective_date desc limit 1;
    when 'language_bonus' then
      select id into v_version_id from public.language_bonus_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.language_bonus_versions where corrects_version_id is not null and organization_id = p_organization_id)
      order by effective_date desc limit 1;
    when 'duration_multiplier' then
      select id into v_version_id from public.duration_multiplier_versions
      where organization_id = p_organization_id and effective_date <= p_as_of
        and id not in (select corrects_version_id from public.duration_multiplier_versions where corrects_version_id is not null and organization_id = p_organization_id)
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
$function$;

-- 4. Self-test: every one of the fifteen is composite with organization_id,
-- and no plain single-column key to the same parent survives beside it.
do $$
declare
  v_missing text;
begin
  select string_agg(x.k, ', ') into v_missing
  from (values ('admin_rates.version_id'),
    ('contract_type_uplift_rates.version_id'),
    ('duration_multiplier_rates.version_id'),
    ('language_bonus_rates.version_id'),
    ('lesson_plan_rates.version_id'),
    ('location_bonus_rates.version_id'),
    ('trainer_grade_rates.version_id'),
    ('duration_multiplier_versions.corrects_version_id'),
    ('language_bonus_versions.corrects_version_id'),
    ('location_bonus_versions.corrects_version_id'),
    ('trainer_grade_versions.corrects_version_id'),
    ('sessions.group_id'),
    ('groups.client_id'),
    ('groups.contract_id'),
    ('payroll_period_totals.payroll_period_id')) x(k)
  where not exists (
    select 1 from pg_constraint con
    join pg_class cl on cl.oid = con.conrelid
    where con.contype = 'f' and cl.relname = split_part(x.k, '.', 1)
      and array_length(con.conkey, 1) = 2
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = any (con.conkey) and a.attname = split_part(x.k, '.', 2))
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = any (con.conkey) and a.attname = 'organization_id'))
  or exists (
    select 1 from pg_constraint con
    join pg_class cl on cl.oid = con.conrelid
    where con.contype = 'f' and cl.relname = split_part(x.k, '.', 1)
      and array_length(con.conkey, 1) = 1
      and exists (select 1 from pg_attribute a where a.attrelid = con.conrelid and a.attnum = con.conkey[1] and a.attname = split_part(x.k, '.', 2)));
  if v_missing is not null then
    raise exception '202611160002 self-test: not composite with organization_id, or a single-column key survives: %', v_missing;
  end if;
end;
$$;
