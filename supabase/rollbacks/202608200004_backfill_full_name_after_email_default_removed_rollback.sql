-- Rollback of 202608200004_backfill_full_name_after_email_default_removed.sql.
--
-- Per the standing convention (docs/WOWLAB_SAD_Field_Masking.md §6.2):
-- lives in supabase/rollbacks/, never supabase/migrations/. Applying it
-- for real means copying it into supabase/migrations/ with a fresh
-- timestamp, pushing, then moving it back out.
--
-- Restores the exact literal values confirmed live before this migration
-- ran (all 9 rows had full_name = their own email).
update public.users
set full_name = email
where email in (
  'anca.tanasescu@gmail.com',
  'anka@asismart.ro',
  'maxdigitalro+community@gmail.com',
  'maxdigitalro+finadmin@gmail.com',
  'maxdigitalro+finops@gmail.com',
  'maxdigitalro+inventory@gmail.com',
  'maxdigitalro+master@gmail.com',
  'maxdigitalro+ops@gmail.com',
  'test+cascade-check@wowlab.dev'
);
