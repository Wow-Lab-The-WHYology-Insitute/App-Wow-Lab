-- Seeds trainer_grade_assignments (previously zero rows) for the ten
-- active trainers who have actually delivered, from their last recorded
-- workshop grade, per Anca 2026-09-24. source='manual' -- these are
-- read off her own record, not computed by any rule in this codebase
-- (the 'computed' half of the source vocabulary has no implementation
-- yet). effective_from = 2026-09-01, matching the pay grids seeded in
-- 202609240001.
--
-- Luiza Mirt gets no row: no workshop in Anca's file to read a grade
-- from, and Anca's own answer for her is conditional ("she starts at
-- grade 3 if she returns") -- not a fact to seed today, a rule to apply
-- if and when she does.
--
-- Every trainer_id below is looked up by email and the insert raises if
-- any one is missing, the same fail-loud discipline as the resolvers
-- themselves -- even though all ten were confirmed resolving to a real
-- account immediately before this migration was written.

do $$
declare
  v_org uuid;
  v_anca uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'trainer grade assignment seed: no organization with slug=wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'trainer grade assignment seed: no user with email=anca.tanasescu@gmail.com';
  end if;

  insert into public.trainer_grade_assignments (organization_id, trainer_id, grade_level, effective_from, set_by, source)
  select
    v_org,
    u.id,
    g.grade_level,
    '2026-09-01'::date,
    v_anca,
    'manual'
  from (values
    ('catalina_moale@yahoo.com', 6),   -- Cătălina Trușan
    ('soniaganea05@gmail.com', 6),     -- Sonia Ganea
    ('irinaeremia160@gmail.com', 6),   -- Andrada Eremia
    ('elena.bacalum@gmail.com', 4),    -- Elena Bacalum
    ('merisanteodora@gmail.com', 3),   -- Teodora Merișan
    ('alexandra.nutu2010@gmail.com', 2), -- Alexandra Nuțu
    ('v.tobosaru@yahoo.com', 2),       -- Viorel Toboșaru
    ('popar216@gmail.com', 1),         -- Raluca Popa
    ('alina.garofil@outlook.com', 1),  -- Alina Garofil
    ('rabalasov@gmail.com', 1)         -- Răzvan Alexandru Bălașov
  ) as g(email, grade_level)
  join public.users u on u.email = g.email;

  if (select count(*) from public.trainer_grade_assignments where organization_id = v_org and effective_from = '2026-09-01') <> 10 then
    raise exception 'trainer grade assignment seed: expected 10 rows for 2026-09-01, got %. At least one email did not resolve to a public.users row -- check which one before trusting this migration ran correctly.',
      (select count(*) from public.trainer_grade_assignments where organization_id = v_org and effective_from = '2026-09-01');
  end if;
end $$;
