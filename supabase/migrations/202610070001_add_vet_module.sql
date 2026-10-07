-- ============================================================================
-- Vet becomes module 14 -- Mihai confirmed 2026-10-07.
-- ============================================================================
-- Item 103 recorded Vet as "named, scoped, assigned to one author with zero
-- plans written, and its sheet deliberately hidden" -- the reason not to add
-- it was that a trainer could select it and find nothing behind it.
--
-- That reason is gone. Today's export of the Centralizator has the
-- I WANT TO BE A VET sheet UNHIDDEN with 6 real lesson rows, each carrying a
-- real plan filename (VET_*_GE_1 .. _6) and a what-is-taught cell. The six
-- titles match, one for one, the allocation block in "Module noi 2025 - idei
-- de lectii.xlsx" that assigned them to GABI -- so these are the planned
-- lessons, now written. Mihai's instruction: new plans appearing later is an
-- update, not a reason to wait.
--
-- Anatomy still waits, unchanged from item 103: 6 real plans of 23 rows, 17
-- chapter pointers, and 6 plans shared with `doctor`. Adding it would
-- duplicate content doctor already carries.
--
-- ============================================================================
-- TWO OBJECTS, NOT ONE -- and the second is the one that actually validates
-- ============================================================================
-- public.groups.module is NOT a foreign key to public.modules. It is a CHECK
-- constraint with all thirteen keys written inline (groups_module_check).
-- Verified before writing this, not assumed: public.modules is referenced
-- NOWHERE outside its own creating migration (202608160004) -- no app code
-- reads it, no test reads it, nothing joins to it. It is a reference table
-- that documents the taxonomy; the CHECK constraint is what enforces it.
--
-- So adding a module means both:
--   1. a row in public.modules      (the documented taxonomy)
--   2. widening groups_module_check (the thing that would otherwise reject it)
-- Doing only (1) leaves the module unusable with no error until someone tries
-- to save a group. Doing only (2) leaves the taxonomy table lying.
--
-- Widening a CHECK cannot invalidate an existing row, so this is strictly
-- additive and rewrites no data -- same shape as 202609260001 (custom as the
-- tenth workshop type).
--
-- The key: `vet`. ASCII snake_case, and deliberately the same shape as its
-- sibling `doctor` -- a single short word naming the role, not the phrase.
-- The label: 'I Wanna Be a Vet', matching `doctor`'s 'I Wanna Be a Doctor'.
-- The sheet's own 'I want to be a VET' is not used: every sheet in that file
-- shouts its module name (`Modul ASTRONOMY` -> 'Astronomy'), and the sibling
-- already establishes the house style.

insert into public.modules (key, display_label)
values ('vet', 'I Wanna Be a Vet');

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
    'vet'
  ));

comment on column public.groups.module is
  'One of the real curriculum modules, fourteen as of 2026-10-07 (item 105): the thirteen confirmed in August plus vet, added once its lesson plans existed. Validated by groups_module_check, NOT by a foreign key to public.modules -- that table documents the taxonomy and is read by nothing. Anatomy is deliberately absent: 17 of its 23 rows are chapter pointers rather than plans, and 6 of its 6 real plans are shared with doctor (item 103).';
