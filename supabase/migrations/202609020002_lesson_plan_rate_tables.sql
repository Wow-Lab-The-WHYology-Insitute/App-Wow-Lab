-- 202609020002_lesson_plan_rate_tables.sql
-- Lesson-plan pay (SAD §12.3) as its own versioned grid, sixth alongside
-- the five in 202608310002, not folded into trainer_grades -- §12.3 is
-- explicit that lesson plans are "un tip de lucru separat... nu o
-- treaptă suplimentară" on the grade scale.
--
-- Follows 202608310002 exactly, not a new shape: same predicate on both
-- tables (is_platform_owner() OR finance.operations.* OR
-- finance.reporting.*), SELECT+INSERT only (no UPDATE/DELETE to
-- authenticated -- a correction gets a new version, never an edit),
-- row_history attached to both even though nothing but service_role can
-- fire it, same versions+rates split as the other five even though this
-- grid's "rates" side only ever holds one row per version -- there is no
-- tier/grade/language key to enumerate, so lesson_plan_rates carries no
-- key column at all, just the rate, UNIQUE on version_id alone.
--
-- Chosen over a single non-versioned value on the SAD's own stated
-- reasoning (§12.9), not a new argument: versioning was applied
-- uniformly to all five grids "chiar și acolo unde dovada directă
-- lipsește" (even where direct evidence of change is missing) -- one
-- mechanism remembered once being safer than several individually
-- reasoned-about ones. §12.3 rules out lesson-plan pay varying by
-- trainer; it says nothing about the rate never changing over time, and
-- §12.9's own logic doesn't require evidence of change before choosing
-- to version something Finance administers. A single-value, UPDATE-based
-- table was also not actually available regardless: this migration
-- family's own rule is no UPDATE, ever, on a financial policy value --
-- corrections are a new version, full stop.
--
-- resolve_lesson_plan_rate(organization_id, as_of) matches its six
-- siblings' shape exactly: LANGUAGE plpgsql (not sql -- a plain SQL
-- function resolving zero rows returns NULL silently, wrong here, where
-- NULL must mean "no rate for this date" and stop the calculation, per
-- §12.9's fail-loud requirement), SECURITY INVOKER (no internal
-- authorization check of its own -- DEFINER here would let anyone
-- reconstruct the whole rate history regardless of their own SELECT
-- rights), STABLE, two-step resolution (version first, then the row
-- inside it) so a version missing its one row fails distinctly rather
-- than silently falling back to an older version's rate.

create table public.lesson_plan_rate_versions (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  effective_date    date not null,
  created_by        uuid not null references public.users(id),
  created_at        timestamptz not null default now(),
  note              text,
  constraint lesson_plan_rate_versions_org_date_unique unique (organization_id, effective_date)
);

create table public.lesson_plan_rates (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  version_id      uuid not null references public.lesson_plan_rate_versions(id),
  rate            numeric not null,
  constraint lesson_plan_rates_version_unique unique (version_id)
);

create trigger lesson_plan_rate_versions_row_history
  before delete or update on public.lesson_plan_rate_versions
  for each row execute function row_history_capture();

create trigger lesson_plan_rates_row_history
  before delete or update on public.lesson_plan_rates
  for each row execute function row_history_capture();

alter table public.lesson_plan_rate_versions enable row level security;
alter table public.lesson_plan_rates enable row level security;

create policy "authenticated select lesson_plan_rate_versions" on public.lesson_plan_rate_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert lesson_plan_rate_versions" on public.lesson_plan_rate_versions
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select lesson_plan_rates" on public.lesson_plan_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert lesson_plan_rates" on public.lesson_plan_rates
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert on public.lesson_plan_rate_versions to authenticated;
grant select, insert on public.lesson_plan_rates to authenticated;

create or replace function app.resolve_lesson_plan_rate(p_organization_id uuid, p_as_of date)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_version_id uuid;
  v_rate numeric;
begin
  select id into v_version_id
  from public.lesson_plan_rate_versions
  where organization_id = p_organization_id
    and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_lesson_plan_rate: no lesson_plan_rate_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select rate into v_rate
  from public.lesson_plan_rates
  where version_id = v_version_id;

  if v_rate is null then
    raise exception 'app.resolve_lesson_plan_rate: version % has no rate row -- incomplete version', v_version_id;
  end if;

  return v_rate;
end;
$$;

revoke all on function app.resolve_lesson_plan_rate(uuid, date) from public;
grant execute on function app.resolve_lesson_plan_rate(uuid, date) to authenticated, service_role;

-- ============================================================================
-- Seed: one version. Anca confirmed the rate has been 120 lei net per
-- plan since 2024 and has not changed -- not a placeholder, the actual
-- confirmed figure.
--
-- effective_date is 2024-01-01, not the date this migration runs.
-- Deliberate: resolve_lesson_plan_rate raises for any date before the
-- earliest version that exists. The 31 lesson plans already written
-- (31.08.2026 -- Răzvan Alexandru Bălașov 4, Raluca Popa 17, Teodora
-- Merișan 10) cannot be recorded yet regardless (see below), but WHEN
-- they can be, they need to resolve against this rate -- a version dated
-- today would make every plan written before today unresolvable, raising
-- instead of returning 120, for no reason connected to the actual facts
-- (the rate has not changed since 2024, so there is no earlier value it
-- would be wrong to also return). Dating this at the true effective date
-- Anca gave, not the migration date, is what makes that work.
-- ============================================================================

do $$
declare
  v_org uuid;
  v_anca uuid;
  v_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'lesson_plan_rate seed: no organization with slug=wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'lesson_plan_rate seed: no user with email=anca.tanasescu@gmail.com';
  end if;

  insert into public.lesson_plan_rate_versions (organization_id, effective_date, created_by, note)
  values (
    v_org,
    '2024-01-01',
    v_anca,
    'Confirmed by Anca: 120 lei net per plan, unchanged since 2024. Dated 2024-01-01 rather than the migration date so lesson plans written before this migration -- including the 31 from 31.08.2026 -- resolve correctly once they can be recorded, instead of raising for predating the earliest version.'
  )
  returning id into v_version;

  insert into public.lesson_plan_rates (organization_id, version_id, rate)
  values (v_org, v_version, 120);
end $$;
