-- 202609100002_seed_test_org_b_legal_entities_rollback.sql
-- Reverts 202609100002. Per docs/WOWLAB_SAD_Field_Masking.md §6.2: lives
-- here, not in supabase/migrations/, so db push never auto-applies it.
--
-- To run for real: copy this file into supabase/migrations/ under a NEW
-- timestamp (not this one -- remote history already has this one), run
-- `supabase db push --linked`, then run `supabase migration repair
-- --status reverted <that-new-timestamp> --linked` immediately after.
-- Then move this file back here.
--
-- Deletes the two fictional rows by (organization_id, name), same
-- matching the forward migration used to insert them. Scoped this
-- precisely on purpose -- no WHERE clause broader than an exact org+name
-- match, matching this session's own standing rule (docs/OPEN_ITEMS.md
-- item 49's follow-up) that verification-related deletes only ever
-- match exact identity, never a pattern.

delete from public.legal_entities
where organization_id = '09098278-4abc-4de6-a21f-5dc044d15ec4'
  and name in ('Test Entity SRL', 'Test Association');
