-- Rollback for 202610160006. Drops the range CHECK, returning
-- sessions.duration_minutes to accepting any integer at all -- including
-- negatives, zero, and values no form would ever produce.
--
-- If this is rolled back because a real workshop legitimately falls
-- outside 15..480, widen the bounds instead: the constraint exists to
-- catch typos on a column that became freely typeable in the same change,
-- and removing it entirely restores the state where nothing does.

alter table public.sessions
  drop constraint if exists sessions_duration_minutes_range_check;
