-- Rollback for 202610300001. Restores 100/107/114/121/128/135 at
-- 2026-09-01, exactly as 202610200001 left it, including that migration's
-- own note. Only do this to undo a mistaken application -- rolling it back
-- re-introduces the exact gap Anca's 2026-10-29 message was written to
-- close.

do $$
declare
  v_org uuid;
  v_version uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_version from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2026-09-01';
  if v_version is null then
    raise exception 'rollback: no trainer_grade_versions row effective 2026-09-01';
  end if;

  update public.trainer_grade_rates r
  set rate = v.rate
  from (values (1, 100), (2, 107), (3, 114), (4, 121), (5, 128), (6, 135)) as v(grade_level, rate)
  where r.version_id = v_version and r.grade_level = v.grade_level;

  update public.trainer_grade_versions
  set note = 'Restated 2026-10-20 (202610200001). These are the rates ACTUALLY PAID in Sept-Oct 2026, read off the real payroll sheet: grade 2 = 107 on Lorina Ciurusniuc''s 30.09.2026 rows, grade 3 = 114 on Teodora Merisan''s 16/23.09.2026 rows and on Alexandra Nutu''s 12.10.2026 row (228,00 = 114 x 2.00 at Other cities). Supersedes the 111-150 values seeded by 202609240001, which were Anca''s 2026-09-24 figures ("vom avea direct 111 lei/ora tarif de baza junior" -- future tense) and had been backdated to 2026-09-01, a month in which the payment record shows the older scale still in force. Whether 111 is a gross of 100 or simply a higher rate is OPEN -- see OPEN_ITEMS item 147; this version takes no position on it.'
  where id = v_version;
end $$;
