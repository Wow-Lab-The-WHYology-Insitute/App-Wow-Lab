-- Rollback for 202609240004. Drops the table outright -- unlike the
-- versioned pay grids, there is no "leave history in place" concern
-- here (this table has no version history to preserve), but this IS
-- lossy for any city correction entered after the seed (this table
-- allows real UPDATE, unlike the grids) -- confirm nothing has been
-- edited since seeding before running this.

drop table if exists public.trainer_home_cities;
