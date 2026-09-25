-- trainer_home_cities: a small table of its own, not a column on users.
--
-- Not users -- same placement reasoning docs/WOWLAB_SAD_Contracte_Trainer_
-- Furnizor.md Sec12.5 already gave for rejecting a home-city column there
-- (per-trainer fact, not identity), now applied to a table instead of a
-- column, and unlike trainer_grade_rates/trainer_grade_assignments this
-- is NOT the versioned-grid shape: a home city has no effective date the
-- way a grade does. A grade changes on a schedule tied to workshop
-- history that needs preserving; a home city is a current fact that gets
-- corrected, not superseded -- normal UPDATE, no row_history trigger, no
-- version table. One row per trainer.
--
-- RLS SELECT is deliberately broader than the pay grids
-- (202608310002's trainer_grade_rates etc., gated to finance.operations.*
-- / finance.reporting.* / owner only): those are financial rate tables
-- Finance audits. This is an operational fact Operations needs to READ
-- to do their job -- specifically, to pre-fill sessions.location_tier at
-- session creation (the trainer allocation moment), which is gated on
-- sessions.create, not any finance capability. Copying the finance-only
-- shape here would silently break the one feature this table exists
-- for. WRITE stays owner-only (org.settings.manage) -- these are Anca's
-- confirmed facts, matching how she's the one who confirmed every pay
-- grid figure this round; no UI edits this yet (see OPEN_ITEMS.md,
-- "where it is edited and by whom" reported, not built this round).

create table public.trainer_home_cities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  trainer_id uuid not null references public.users(id),
  -- Free text, not a closed vocabulary like location_tier/language_group
  -- -- unlike those, the set of real values isn't small and fixed (any
  -- city a trainer might live in), so a CHECK enum would need constant
  -- widening. Seeded without diacritics (Bucuresti/Cluj/Cernavoda), same
  -- convention item 42 already confirmed with Anca for names -- and
  -- "Bucuresti" here deliberately matches location_tier's own
  -- 'bucuresti' value spelling exactly, since the pre-fill heuristic
  -- compares this column's value against that vocabulary.
  city text not null,
  set_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trainer_home_cities_trainer_unique unique (trainer_id)
);

create trigger trainer_home_cities_set_updated_at
  before update on public.trainer_home_cities
  for each row execute function public.trigger_set_updated_at();

alter table public.trainer_home_cities enable row level security;

create policy "authenticated select trainer_home_cities" on public.trainer_home_cities
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or app.has_capability('sessions.create', organization_id)
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert trainer_home_cities" on public.trainer_home_cities
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
  );

create policy "authenticated update trainer_home_cities" on public.trainer_home_cities
  for update to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
  )
  with check (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
  );

grant select, insert, update on public.trainer_home_cities to authenticated;

-- ============================================================================
-- Seed: all 11 active trainers (the same 11 SAD Sec12.5 counted -- the ten
-- who got a grade in 202609240002, plus Luiza Mirt, who has no grade yet
-- but is not excluded from this fact -- home city isn't conditioned on
-- having delivered). Alexandra Nuțu and Viorel Toboșaru per Anca's two
-- confirmed exceptions; the other nine, Bucuresti.
-- ============================================================================
do $$
declare
  v_org uuid;
  v_anca uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'trainer_home_cities seed: no organization with slug=wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'trainer_home_cities seed: no user with email=anca.tanasescu@gmail.com';
  end if;

  insert into public.trainer_home_cities (organization_id, trainer_id, city, set_by)
  select v_org, u.id, g.city, v_anca
  from (values
    ('catalina_moale@yahoo.com', 'Bucuresti'),
    ('soniaganea05@gmail.com', 'Bucuresti'),
    ('irinaeremia160@gmail.com', 'Bucuresti'),
    ('elena.bacalum@gmail.com', 'Bucuresti'),
    ('merisanteodora@gmail.com', 'Bucuresti'),
    ('alexandra.nutu2010@gmail.com', 'Cluj'),
    ('v.tobosaru@yahoo.com', 'Cernavoda'),
    ('popar216@gmail.com', 'Bucuresti'),
    ('alina.garofil@outlook.com', 'Bucuresti'),
    ('rabalasov@gmail.com', 'Bucuresti'),
    ('luiza.mirt8@gmail.com', 'Bucuresti')
  ) as g(email, city)
  join public.users u on u.email = g.email;

  if (select count(*) from public.trainer_home_cities where organization_id = v_org) <> 11 then
    raise exception 'trainer_home_cities seed: expected 11 rows, got %. At least one email did not resolve to a public.users row.',
      (select count(*) from public.trainer_home_cities where organization_id = v_org);
  end if;
end $$;
