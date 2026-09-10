-- 202609100001_add_clients_business_line_check_rollback.sql
-- Reverts 202609100001. Per docs/WOWLAB_SAD_Field_Masking.md §6.2: lives
-- here, not in supabase/migrations/, so db push never auto-applies it.
--
-- To run for real: copy this file into supabase/migrations/ under a NEW
-- timestamp (not this one -- remote history already has this one), run
-- `supabase db push --linked`, then run `supabase migration repair
-- --status reverted <that-new-timestamp> --linked` immediately after.
-- Then move this file back here.
--
-- Drops the constraint and the column comment. Does NOT reverse the
-- backfill (`Scoli recurente` -> `recurring_private_schools` on
-- "Școala Franceză (Lycee Francais)") -- that was a real correction to a
-- real client's data, not a side effect of the constraint existing.
-- Reversing it would silently reintroduce free text nobody asked to get
-- back; if the backfill itself needs undoing, that is its own decision,
-- made explicitly, not a byproduct of rolling back the CHECK.

alter table public.clients
  drop constraint clients_business_line_check;

comment on column public.clients.business_line is null;
