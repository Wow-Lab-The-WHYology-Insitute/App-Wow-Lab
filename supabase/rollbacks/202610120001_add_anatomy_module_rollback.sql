-- Rollback for 202610120001 -- removes anatomy, restoring the fourteen.
--
-- A true undo only while no group uses 'anatomy'. The forward migration
-- widened a CHECK and inserted one reference row; narrowing it again is
-- lossless for every group that does not use the key.
--
-- If a group HAS been created with 'anatomy', the constraint re-add below
-- FAILS LOUDLY rather than silently discarding or remapping that group's
-- module -- deliberately, same as 202610070001's rollback. A group classified
-- as Anatomy is a real record; the correct response to "rolling back would
-- invalidate it" is a human decision about that group, not an automatic
-- rewrite.
--
-- To force it, requalify those groups first and record what they became:
--   select id, client_id, notes from public.groups where module = 'anatomy';
--
-- The column comment is RESTORED to 202610070001's exact text, not set to
-- null: the comment is older than this migration, so dropping it would leave
-- the column undocumented rather than returning it to how it was found.

alter table public.groups drop constraint groups_module_check;

alter table public.groups
  add constraint groups_module_check
  check (module in (
    'gaga', 'green_energy', 'wow_mix', 'tiktok', 'food_science', 'lotions',
    'magic_physics', 'chem_me', 'chem_hs', 'lights', 'detective', 'astronomy',
    'doctor', 'vet'
  ));

delete from public.modules where key = 'anatomy';

comment on column public.groups.module is
  'One of the real curriculum modules, fourteen as of 2026-10-07 (item 105): the thirteen confirmed in August plus vet, added once its lesson plans existed. Validated by groups_module_check, NOT by a foreign key to public.modules -- that table documents the taxonomy and is read by nothing. Anatomy is deliberately absent: 17 of its 23 rows are chapter pointers rather than plans, and 6 of its 6 real plans are shared with doctor (item 103).';
