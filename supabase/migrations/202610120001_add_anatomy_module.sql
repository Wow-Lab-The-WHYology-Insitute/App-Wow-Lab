-- ============================================================================
-- Anatomy becomes module 15 -- Anca confirmed 2026-10-12. The taxonomy is now
-- complete: 15 of 15, the figure "13 din 15" has been pointing at since
-- August.
-- ============================================================================
-- The reason not to add it was never the row count. 202610070001 (vet) put it
-- plainly: "Adding it would duplicate content doctor already carries" -- 6 of
-- its 6 real plans sit on the doctor sheet too, so a 15th module looked like
-- the same lessons counted twice.
--
-- Anca closed that objection directly, not by overruling it: a module holds
-- several lesson plans AND the same plan belongs to several modules. Sharing
-- is the designed shape of this catalogue, not a symptom of one being carved
-- out of another. Measured across the whole workbook rather than taken on
-- faith: 113 of 288 distinct plans appear on more than one sheet, one of them
-- on five -- and that one is ANAT_SeeingDNA_DC_4, Anatomy's own. WOW LAB MIX
-- is the extreme case (80 distinct plans, 75 of them also on another sheet)
-- and nobody has ever proposed deleting MIX for it. Anatomy's six shared
-- plans are the same fact at a smaller scale.
--
-- Re-measured today against the current export, not carried over from item
-- 103's September figures:
--   * 23 rows, all 23 with a title and a "what is taught" value
--   * 6 carry a real plan filename (ANAT_*_DC_1..5, ANAT_Germes&Hygene_SG_18)
--   * all 6 also appear on I WANT TO BE A DOCTOR -- unchanged
--   * the other 17 are chapter pointers ("1. Lungs", "17. Immune system"),
--     and the DOCTOR sheet carries 23 of the same shape
-- Those 17 are now an import problem (what a lesson_plans loader does with a
-- row that names a topic and no plan) rather than a reason to withhold the
-- module. A trainer selecting Anatomy today gets a correctly-named module
-- with six written plans behind it -- the same bar vet was held to.
--
-- Anatomy's plan column is also the one header that is NOT "Plan de lectie":
-- the sheet calls it "Link/ resurse (optional)". It carries plan filenames
-- regardless. Recorded here because the catalogue import will meet it.
--
-- ============================================================================
-- TWO OBJECTS, NOT ONE -- same as vet, restated because it still holds
-- ============================================================================
-- public.groups.module is NOT a foreign key to public.modules. It is a CHECK
-- constraint with every key written inline (groups_module_check), and
-- public.modules is read by nothing outside its own creating migration
-- (202608160004) -- re-verified live before writing this, not assumed from
-- 202610070001's own check a week ago.
--
-- So adding a module means both:
--   1. a row in public.modules      (the documented taxonomy)
--   2. widening groups_module_check (the thing that would otherwise reject it)
-- Doing only (1) leaves the module unusable with no error until someone tries
-- to save a group. Doing only (2) leaves the taxonomy table lying.
--
-- Widening a CHECK cannot invalidate an existing row, so this is strictly
-- additive and rewrites no data -- same shape as 202610070001 (vet) and
-- 202609260001 (custom as the tenth workshop type).
--
-- The key: `anatomy`. ASCII snake_case, the word spelled out rather than the
-- `ANAT_` filename prefix -- the same choice `astronomy` already made over
-- `ASTRO_`. The label: 'Anatomy'. Its sheet is `Modul ANATOMY`, so it follows
-- `Modul ASTRONOMY` -> 'Astronomy', NOT its siblings doctor/vet, whose
-- "I Wanna Be a ..." labels come from their sheets being that phrase. The
-- shouted source form is not the house style, same rule as every label above
-- it.

insert into public.modules (key, display_label)
values ('anatomy', 'Anatomy');

alter table public.groups drop constraint groups_module_check;

alter table public.groups
  add constraint groups_module_check
  check (module in (
    'gaga',
    'green_energy',
    'wow_mix',
    'tiktok',
    'food_science',
    'lotions',
    'magic_physics',
    'chem_me',
    'chem_hs',
    'lights',
    'detective',
    'astronomy',
    'doctor',
    'vet',
    'anatomy'
  ));

comment on column public.groups.module is
  'One of the real curriculum modules, fifteen as of 2026-10-12 (item 110) -- the complete set, and the "13 din 15" this project could not account for until now: the thirteen confirmed in August, plus vet (2026-10-07, once its plans existed) and anatomy (2026-10-12). Validated by groups_module_check, NOT by a foreign key to public.modules -- that table documents the taxonomy and is read by nothing. Anatomy''s six plans being shared with doctor is correct and not a duplicate: Anca confirmed 2026-10-12 that a module holds several plans and a plan belongs to several modules (113 of 288 distinct plans sit on more than one sheet). CRACIUN is a sixteenth sheet and deliberately not a module: zero plan filenames, YouTube links, an idea list.';
