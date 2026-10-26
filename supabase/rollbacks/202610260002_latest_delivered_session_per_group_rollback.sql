-- Rollback for 202610260002_latest_delivered_session_per_group.sql.
--
-- Drops the view. /groups must be reverted to its own unbounded DESC read in
-- the same change, or it loses its trainer columns entirely.

drop view if exists public.group_latest_delivered_session;
