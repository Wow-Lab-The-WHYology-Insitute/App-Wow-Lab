-- Rollback of 202608200005_users_masked_view.sql.
--
-- Per the standing convention (docs/WOWLAB_SAD_Field_Masking.md §6.2):
-- lives in supabase/rollbacks/, never supabase/migrations/. Applying it
-- for real means copying it into supabase/migrations/ with a fresh
-- timestamp, pushing, then moving it back out.
--
-- Unlike contracts' rollback, this does NOT drop app_masking_owner --
-- that role is shared, pre-existing infrastructure (created for
-- contracts' masking, 202608190001/202608200003) that this migration
-- only added one grant and one owned function to. Dropping the role here
-- would also break contracts' masking. Only what THIS migration added is
-- undone: the view, the function, and the one column grant.
drop view public.users_masked;
drop function app.masked_user_contact_fields(uuid);
revoke select (id, email, phone) on public.users from app_masking_owner;
