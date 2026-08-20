-- 202608200002_backfill_trainer_display_names.sql
-- Fixes the population identified before starting the users field-masking
-- rollout (docs/WOWLAB_SAD_Field_Masking.md §2.3): /groups and /groups/[id]
-- render a trainer's email as a display-name fallback when first_name and
-- last_name are both null. Queried live before writing this: of the 27
-- users platform-wide with both null, only 4 hold Trainer/Senior Trainer
-- (the only roles those pages ever look up a name for) — and all 4 are
-- internal dev/QA accounts, not real trainers. Zero real production
-- trainers are affected; this closes the population entirely rather than
-- leaving a masking mechanism to paper over it.
--
-- first_name/last_name were added in 202608120001 and deliberately NOT
-- backfilled from full_name at the time (see that migration's comment on
-- users.first_name) — that's why these are null today despite full_name
-- already holding a value for 3 of the 4. This migration is that backfill,
-- scoped to exactly the 4 rows that matter for this fix, not a blanket
-- pass over all 27.
--
-- maxdigitalro+trainer@gmail.com is the one exception worth calling out:
-- its full_name is literally the raw email address — handle_new_auth_user
-- (202607130004) defaults full_name to `new.email` when no full_name is
-- supplied at invite time, and none was here. Fixed in the same statement
-- since it's the same underlying problem this migration exists to close.
--
-- Idempotent: plain UPDATE keyed on email (stable, unique), same inputs
-- always produce the same result — matches the established backfill style
-- (202608110003).

update public.users
set first_name = 'QA', last_name = 'Trainer', full_name = 'QA Trainer'
where email = 'maxdigitalro+trainer@gmail.com';

update public.users
set first_name = 'Test', last_name = 'Trainer A'
where email = 'test+trainer-a@wowlab.dev';

update public.users
set first_name = 'Test', last_name = 'Trainer B'
where email = 'test+trainer-b@wowlab.dev';

update public.users
set first_name = 'UI Validation', last_name = 'Trainer'
where email = 'test+ui-trainer@wowlab.dev';
