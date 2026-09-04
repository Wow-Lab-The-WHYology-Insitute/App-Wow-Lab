-- 202609040002_backfill_remaining_test_account_flags_rollback.sql
-- Rolls back 202609040002: restores these same 17 rows to
-- is_test_account = false, their state immediately before the forward
-- migration. Explicit id list, same rows, same reasoning against a
-- pattern-based predicate.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

update public.users
set is_test_account = false
where id in (
  'eee47818-3105-4e73-95d9-638f8b5c4781', -- test+user-b@wowlab.dev
  '12754013-fbe2-4643-8ec4-3357de69d2af', -- maxdigitalro+master@gmail.com
  'b88ea8aa-b8af-4d09-86ea-efa6c035bf5e', -- maxdigitalro+ops@gmail.com
  '28e99549-0a50-43e5-9feb-881e2f7d7b1b', -- maxdigitalro+finops@gmail.com
  'dfbf1092-5cb9-444c-913c-328dd21ee456', -- maxdigitalro+finadmin@gmail.com
  '5ffb6cf5-2742-494b-89cd-e4eb8bf13a14', -- maxdigitalro+community@gmail.com
  'fa6e8566-aea6-4048-80e3-22a705a03899', -- maxdigitalro+inventory@gmail.com
  '186e33ce-762c-45c5-8d8e-de3f59337cc4', -- maxdigitalro+trainer@gmail.com
  'ea63166e-14d6-4179-891d-132de3595c76', -- test+ui-org-b@wowlab.dev
  'a1cc089a-3a02-4e01-86f8-ea8b49ce711d', -- test+cascade-check@wowlab.dev
  '901d6d66-a365-4744-8c23-b2dd37e0e0cf', -- test+trainer-b@wowlab.dev
  'fab9f77c-ac27-43f2-ac8f-a0c03f668880', -- maxdigitalro+trainerb1@gmail.com
  '82b99dfb-b938-41f5-850c-fbd9beb5b6e5', -- maxdigitalro+trainerb2@gmail.com
  'f30321ee-66bd-45bb-afe9-1592313101b0', -- maxdigitalro+trainerb3@gmail.com
  'e67e78a8-6ced-4123-b937-bd4ec4c2d28e', -- maxdigitalro+trainerb4@gmail.com
  '88c2d66b-64f3-4881-b2f2-a85ac3a060e5', -- maxdigitalro+trainerb5@gmail.com
  'b7bb9753-0523-4c44-ac31-c3acba3f6259'  -- maxdigitalro+trainerb6@gmail.com
);
