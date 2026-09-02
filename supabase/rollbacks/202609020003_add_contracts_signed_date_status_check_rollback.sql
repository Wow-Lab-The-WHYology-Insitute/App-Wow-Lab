-- 202609020003_add_contracts_signed_date_status_check_rollback.sql
-- Reverts 202609020003. Per docs/WOWLAB_SAD_Field_Masking.md §6.2: lives
-- here, not in supabase/migrations/, so db push never auto-applies it.
--
-- To run for real: copy this file into supabase/migrations/ under a NEW
-- timestamp (not this one -- remote history already has this one), run
-- `supabase db push --linked`, then run `supabase migration repair
-- --status reverted <that-new-timestamp> --linked` immediately after --
-- §6.2 was missing that exact step until 2026-09-01 (commit `b7bbffb`);
-- skipping it leaves the next `db push`, for any reason, broken on the
-- mismatch. Then move this file back here.
--
-- Dropping this constraint on its own reopens item 10's defect (a
-- draft/sent contract could carry a signed_date again) even though
-- addContract no longer offers a path to set one directly -- other
-- write paths (updateContract, if it's ever extended to touch
-- signed_date per the open question in docs/OPEN_ITEMS.md) would regain
-- the same silent gap this constraint exists to close everywhere, not
-- just at create time.

alter table public.contracts
  drop constraint contracts_signed_date_status_check;
