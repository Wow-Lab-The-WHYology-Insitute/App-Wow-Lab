-- ARMED 2026-10-20. Written and reviewed in supabase/proposed/ first
-- (see docs/DATABASE_CONVENTIONS.md §15), then moved here once Mihai
-- accepted the single-version variant: "Registrul de plati bate un citat."
--
-- The instruction this file originally argued against -- two versions, with
-- 111-150 starting 2026-09-24 -- was withdrawn on the same reasoning the
-- file gives: 2026-09-24 is the date Anca STATED the figure, not the date it
-- took effect. Row 36 of the feedback (July 2026) flags the rate change as
-- Blocant and "de confirmat explicit cu Anca + Laura inainte de codificare",
-- and the payment record shows it still unconfirmed on 2026-10-12.
--
-- ===========================================================================
-- WHAT THIS DOES: restates the 2026-09-01 trainer grade scale as 100-135,
-- the scale that was actually paid, and does NOT seed 111-150 at all.
-- ===========================================================================
--
-- THIS DIFFERS FROM THE INSTRUCTION, AND THE REASON IS IN THE INSTRUCTION'S
-- OWN DATA. The decision was two versions: 100-135 from 2026-09-01 and
-- 111-150 from 2026-09-24, that being "the only documented date". But two
-- of the five rows quoted in the same message post-date 2026-09-24 and
-- carry the OLD scale:
--
--     Lorina Ciurusniuc   grade 2   30.09.2026   DSBU   107,00
--     Alexandra Nuțu      grade 3   12.10.2026   Scoala Altfel   228,00
--                                                 (= 114 × 2.00, Other cities)
--
-- So the old scale was still being paid on 30 September and on 12 October.
-- A version starting 2026-09-24 would compute Lorina's two 30-September
-- workshops at 119 instead of the 107 she was paid, and Alexandra's
-- 12 October workshop at 127 × 2.00 = 254,00 instead of 228,00 — which is
-- the exact failure the import is meant to avoid: reproducing what *should*
-- be paid rather than what *was*.
--
-- 2026-09-24 is the date Anca STATED the figure ("vom avea direct 111
-- lei/ora" — future tense). It is not evidence of when it took effect, and
-- the payment record says it had not taken effect three weeks later.
--
-- So: one version, the scale that was paid. 111-150 are NOT seeded, not
-- because they are wrong but because **no date for them survives contact
-- with the payment record**. They are preserved in this comment and in
-- OPEN_ITEMS item 147; adding them later is one version row plus six rates,
-- once Anca gives a start date (or once a trainer contract exists that
-- states one — item 147 records that no trainer contract exists at all).
--
--     Anca's 2026-09-24 figures, parked pending an effective date:
--       1 Junior 111 | 2 Rising Star 119 | 3 Enthusiastic Mid 127
--       4 Experienced Mid 2 134 | 5 Magic Senior 1 142 | 6 Glowing Senior 2 150
--
-- AND IT DOES NOT CLAIM TO KNOW WHETHER 111 IS A GROSS OR A RAISE. That
-- question is open (item 147: an 11% raise and an 11% uplift produce
-- identical numbers, so the arithmetic cannot separate them, and no
-- artefact in this database states which). This migration deliberately
-- takes no position: it seeds the figures the timesheet paid and leaves the
-- interpretation to whatever evidence arrives. In particular it does NOT
-- add net_amount / is_uplift_applied to trainer_grade_rates — those columns
-- would assert an answer (retracted 2026-10-20).
--
-- 202609240001 is NOT edited. It is applied, and its version note records
-- what was believed on 2026-09-24. This supersedes its rate values and says
-- so in the new note.
--
-- REVERSIBILITY: the rollback restores 111-150 at 2026-09-01 exactly as
-- 202609240001 left it.

do $$
declare
  v_org uuid;
  v_anca uuid;
  v_version uuid;
  v_moved integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'restate_trainer_grade_scale: no organization with slug wow-lab';
  end if;

  select id into v_anca from public.users where email = 'anca.tanasescu@gmail.com';
  if v_anca is null then
    raise exception 'restate_trainer_grade_scale: no user anca.tanasescu@gmail.com';
  end if;

  select id into v_version
  from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2026-09-01';

  if v_version is null then
    raise exception 'restate_trainer_grade_scale: no trainer_grade_versions row effective 2026-09-01 -- expected the one seeded by 202609240001';
  end if;

  -- Refuse if the rates are not the six this migration expects to replace.
  -- A grid that has already been changed by someone else must not be
  -- silently overwritten by a migration written against the old state.
  if not exists (
    select 1 from public.trainer_grade_rates
    where version_id = v_version and grade_level = 1 and rate = 111
  ) then
    raise exception 'restate_trainer_grade_scale: grade 1 on the 2026-09-01 version is not 111 -- the grid has changed since this migration was written; re-read it before applying';
  end if;

  update public.trainer_grade_versions
  set note = 'Restated 2026-10-20 (202610200001). These are the rates ACTUALLY PAID in Sept-Oct 2026, read off the real payroll sheet: grade 2 = 107 on Lorina Ciurusniuc''s 30.09.2026 rows, grade 3 = 114 on Teodora Merisan''s 16/23.09.2026 rows and on Alexandra Nutu''s 12.10.2026 row (228,00 = 114 x 2.00 at Other cities). Supersedes the 111-150 values seeded by 202609240001, which were Anca''s 2026-09-24 figures ("vom avea direct 111 lei/ora tarif de baza junior" -- future tense) and had been backdated to 2026-09-01, a month in which the payment record shows the older scale still in force. Whether 111 is a gross of 100 or simply a higher rate is OPEN -- see OPEN_ITEMS item 147; this version takes no position on it.'
  where id = v_version;

  update public.trainer_grade_rates r
  set rate = v.rate
  from (values (1, 100), (2, 107), (3, 114), (4, 121), (5, 128), (6, 135)) as v(grade_level, rate)
  where r.version_id = v_version and r.grade_level = v.grade_level;

  get diagnostics v_moved = row_count;
  if v_moved <> 6 then
    raise exception 'restate_trainer_grade_scale: updated % rate rows, expected 6', v_moved;
  end if;

  -- Assert the result against the real payments, not against the literals
  -- just written -- the point of the change is that these three figures
  -- reproduce what was paid.
  if app.resolve_trainer_grade_rate(v_org, 2, '2026-09-30') <> 107 then
    raise exception 'restate_trainer_grade_scale: grade 2 on 2026-09-30 is not 107 (Lorina was paid 107)';
  end if;
  if app.resolve_trainer_grade_rate(v_org, 3, '2026-09-16') <> 114 then
    raise exception 'restate_trainer_grade_scale: grade 3 on 2026-09-16 is not 114 (Teodora was paid 114)';
  end if;
  if app.resolve_trainer_grade_rate(v_org, 3, '2026-10-12') <> 114 then
    raise exception 'restate_trainer_grade_scale: grade 3 on 2026-10-12 is not 114 (Alexandra''s 228,00 = 114 x 2.00)';
  end if;

  raise notice 'restate_trainer_grade_scale: 2026-09-01 scale restated to 100/107/114/121/128/135; 111-150 not seeded, pending an effective date';
end $$;
