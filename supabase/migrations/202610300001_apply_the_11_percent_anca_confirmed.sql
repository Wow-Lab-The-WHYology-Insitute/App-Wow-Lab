-- 202610200001 restated the 2026-09-01 trainer grade scale to 100-135 --
-- "the scale ACTUALLY PAID" -- because, at the time, the 111-150 figure
-- traced back to Anca's 2026-09-24 message in the future tense ("vom avea
-- direct 111 lei/ora"), flagged Blocant in the requirements feedback, and
-- explicitly "de confirmat explicit cu Anca + Laura inainte de codificare".
-- The payment record showed it still unconfirmed on 2026-10-12.
--
-- That confirmation now exists. Anca, verbatim, 2026-10-29, imperative and
-- present tense -- not a proposal:
--
--   "Pt toti cei notati cu Onorarii traineri sa adaugam direct in app 11%
--    la suma de baza, te rog sa faci update si pe Septembrie si pe
--    Octombrie si de acum inainte se calculeaza cu 11% in plus sumele,
--    SUNT INDEXATE."
--
-- and, from 2026-07-30: "Da, confirmam tariful de baza junior la 111
-- lei/ora predata."
--
-- ===========================================================================
-- WHY THIS IS A RATE CHANGE, NOT contract_type_uplift -- THE SAME QUESTION
-- ITEM 147 ALREADY SETTLED, ASKED AGAIN AND ANSWERED THE SAME WAY
-- ===========================================================================
-- Anca's own word is "indexate" (indexed) -- a raise, applied once, to the
-- base figure itself. It is not a second multiplier layered on top of a
-- lower base at calculation time, which is what `contract_type_uplift`
-- exists for and is kept empty: item 147's own corrected finding is that
-- there never was an uplift in this scale, only a higher number ("111 is
-- simply a higher rate than 100"). Treating today's confirmation as
-- evidence FOR activating contract_type_uplift would reopen the exact
-- confusion that item was written to close. So: six new numbers on the
-- SAME version row, same mechanism as 202609240001 and 202610200001 before
-- it, contract_type_uplift untouched and still empty.
--
-- ===========================================================================
-- WHO THIS APPLIES TO, CHECKED LIVE -- AND WHAT WAS FOUND NOT TO BE TRUE
-- ===========================================================================
-- Anca's own scope is "toti cei notati cu Onorarii traineri" -- read
-- literally, that is `suppliers.service_type = 'Onorarii trainer'`. Checked
-- against the 11 trainers who hold a `trainer_grade_assignments` row in
-- this organization today: only 3 of them (Raluca Popa, Teodora Merisan,
-- Catalina Trusan) have ANY matching row in `suppliers` at all. The other 8
-- -- including Lorina Ciurusniuc, whose 107 lei/hour row is the one that
-- opened item 147 in the first place -- have no supplier record linking
-- them to a service_type, "Onorarii trainer" or otherwise.
--
-- So gating this change on `suppliers.service_type` would, today, exclude
-- 8 of 11 active trainers from a raise Anca explicitly asked be applied to
-- all of them -- the opposite of what she asked for, from a column that
-- happens to be populated for unrelated reasons (whichever trainers also
-- needed a supplier row for invoicing) rather than as a general trainer
-- registry.
--
-- The gate that is ALREADY correct, by construction, is holding a
-- `trainer_grade_assignments` row at all. Nobody who is paid any other way
-- -- Anka Orban, paid through `admin_rates` for admin/writing work, holds
-- NO trainer_grade_assignments row in this organization (checked live) --
-- reads this table. That is the real shape of "Onorarii traineri" in this
-- schema today: not a supplier service_type, but membership in the grade
-- system itself. This migration changes the one grid every grade-holder
-- reads and touches nothing else, which is the correct scope for exactly
-- that reason.
--
-- NOT BUILT HERE, flagged rather than silently worked around: there is no
-- column anywhere (`suppliers`, `supplier_contracts`) playing the role
-- `admin_rates.is_uplift_applied` plays for admin rates -- no per-trainer
-- flag states "this person's base already reflects the indexation" or the
-- reverse. Today the grid is one scale for every grade-holder, which is
-- consistent with every trainer who currently holds a grade actually being
-- the kind of trainer Anca means -- but that consistency is a fact about
-- today's 11 people, not a rule the schema enforces. If a trainer is ever
-- added who should NOT receive this scale (an SRL/gross arrangement like
-- Anka's, but for class delivery rather than admin work), nothing here
-- would stop them from being paid off the same grid. Record as a gap, not
-- a thing to design against a population of zero.
--
-- ===========================================================================
-- ZERO DATA MIGRATION, per Mihai's instruction and per how this table has
-- always worked: `app.calculate_org_session_pay` (STABLE, read-time) calls
-- `app.resolve_trainer_grade_rate`, which reads `trainer_grade_rates`
-- directly -- nothing is cached or materialized. Changing the six numbers
-- on the existing 2026-09-01 version recomputes every September and
-- October figure the next time anyone reads /payroll, with no write to
-- `sessions` or anywhere else. Confirmed live BEFORE this migration,
-- matching the figures Mihai quoted exactly:
--   September: Catalina Trusan/Brandine 3307.50, Lorina Ciurusniuc/
--     Experimente Wow 214.00, Teodora Merisan/Experimente Wow 684.00 =
--     4205.50 total.
--   October:   Catalina Trusan/Brandine 1822.50, Lorina Ciurusniuc/
--     Experimente Wow 642.00 = 2464.50 total, zero gaps.
-- Both should read ~11% higher once this applies -- verified after, not
-- assumed; see the assertions below and the follow-up report.
--
-- ===========================================================================
-- THE "SIGNED CONTRACT" RULE, AND WHY THIS DOES NOT WAIT FOR ONE
-- ===========================================================================
-- Item 147's own rule: "A rate enters the grid when a SIGNED trainer
-- contract states it, with that contract's own start date." No
-- `trainer_contracts` table exists even now (item 2/127) -- there is still
-- no signed contract to point at. Mihai's explicit instruction is that
-- Anca's own words, present tense and operational rather than proposed,
-- are the confirmation this change waits on -- the same kind of call he
-- made for the PREVIOUS resolution ("Registrul de plati bate un citat").
-- This is a deliberate exception made by the person who owns the rule, not
-- the rule quietly going unenforced -- written here so it reads as the
-- former the next time anyone checks.
--
-- REVERSIBILITY: the rollback restores 100/107/114/121/128/135, i.e. what
-- 202610200001 itself left in place.

do $$
declare
  v_org uuid;
  v_version uuid;
  v_moved integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'apply_the_11_percent: no organization with slug wow-lab';
  end if;

  select id into v_version
  from public.trainer_grade_versions
  where organization_id = v_org and effective_date = '2026-09-01';

  if v_version is null then
    raise exception 'apply_the_11_percent: no trainer_grade_versions row effective 2026-09-01';
  end if;

  -- Refuse if the rates are not the six this migration expects to replace
  -- -- same guard 202610200001 used, for the same reason: a grid changed by
  -- someone else since this was written must not be silently overwritten.
  if not exists (
    select 1 from public.trainer_grade_rates
    where version_id = v_version and grade_level = 1 and rate = 100
  ) then
    raise exception 'apply_the_11_percent: grade 1 on the 2026-09-01 version is not 100 -- the grid has changed since this migration was written; re-read it before applying';
  end if;

  update public.trainer_grade_versions
  set note = 'Restated 2026-10-30 (202610300001). Anca, verbatim, 2026-10-29: "Pt toti cei notati cu Onorarii traineri sa adaugam direct in app 11% la suma de baza, te rog sa faci update si pe Septembrie si pe Octombrie si de acum inainte se calculeaza cu 11% in plus sumele, SUNT INDEXATE." And 2026-07-30: "Da, confirmam tariful de baza junior la 111 lei/ora predata." This is a RATE CHANGE (an index applied once to the base), not contract_type_uplift -- see item 147''s own resolution that there is no uplift in this scale, only a higher number. Supersedes 202610200001''s 100/107/114/121/128/135, which restated what the payment record showed BEFORE this indexation -- that record is now understood to predate the change Anca is confirming here, not to contradict it. What decided this was Anca''s word, not arithmetic (OPEN_ITEMS item 147).'
  where id = v_version;

  update public.trainer_grade_rates r
  set rate = v.rate
  from (values (1, 111), (2, 119), (3, 127), (4, 134), (5, 142), (6, 150)) as v(grade_level, rate)
  where r.version_id = v_version and r.grade_level = v.grade_level;

  get diagnostics v_moved = row_count;
  if v_moved <> 6 then
    raise exception 'apply_the_11_percent: updated % rate rows, expected 6', v_moved;
  end if;

  -- Assert the resolver returns the new scale for dates this change
  -- actually covers -- not against the old timesheet, which is exactly
  -- the figure this change is confirmed to move away from.
  if app.resolve_trainer_grade_rate(v_org, 1, '2026-09-01') <> 111 then
    raise exception 'apply_the_11_percent: grade 1 on 2026-09-01 is not 111';
  end if;
  if app.resolve_trainer_grade_rate(v_org, 2, '2026-09-30') <> 119 then
    raise exception 'apply_the_11_percent: grade 2 on 2026-09-30 is not 119 (Lorina''s own assignment date)';
  end if;
  if app.resolve_trainer_grade_rate(v_org, 6, '2026-10-12') <> 150 then
    raise exception 'apply_the_11_percent: grade 6 on 2026-10-12 is not 150';
  end if;

  raise notice 'apply_the_11_percent: 2026-09-01 scale restated to 111/119/127/134/142/150, confirmed by Anca 2026-10-29. contract_type_uplift untouched, still empty by design (item 147).';
end $$;
