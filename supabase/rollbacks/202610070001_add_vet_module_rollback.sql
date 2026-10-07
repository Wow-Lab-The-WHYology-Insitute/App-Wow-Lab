-- Rollback for 202610070001 -- removes vet, restoring the thirteen.
--
-- A true undo only while no group uses 'vet'. The forward migration widened a
-- CHECK and inserted one reference row; narrowing it again is lossless for
-- the three live groups (2x wow_mix, 1x green_energy -- none of them vet).
--
-- If a group HAS been created with 'vet', the constraint re-add below FAILS
-- LOUDLY rather than silently discarding or remapping that group's module --
-- deliberately. A group classified as Vet is a real record; the correct
-- response to "rolling back would invalidate it" is a human decision about
-- that group, not an automatic rewrite. Same principle as the forward
-- migration's constraint being the real safety net.
--
-- To force it, requalify those groups first and record what they became:
--   select id, client_id, notes from public.groups where module = 'vet';

alter table public.groups drop constraint groups_module_check;

alter table public.groups
  add constraint groups_module_check
  check (module in (
    'gaga', 'green_energy', 'wow_mix', 'tiktok', 'food_science', 'lotions',
    'magic_physics', 'chem_me', 'chem_hs', 'lights', 'detective', 'astronomy',
    'doctor'
  ));

delete from public.modules where key = 'vet';

comment on column public.groups.module is null;
