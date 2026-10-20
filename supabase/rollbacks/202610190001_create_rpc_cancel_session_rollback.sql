-- Rollback for 202610190001. Drops the function pair, the two constraints
-- and the four columns, and restores sessions' table-wide INSERT grant.
--
-- WHAT ROLLING THIS BACK COSTS: the application goes back to being unable
-- to record that a workshop did not happen (item 139). Any workshop
-- already cancelled loses its reason, its actor and its timestamp when the
-- columns go -- and status = 'cancelled' then becomes unreachable again
-- while those rows keep that status with nothing explaining it. Check for
-- cancelled rows first:
--
--   select count(*) from public.sessions where status = 'cancelled';
--
-- If that is not zero, decide what happens to those rows before running
-- this; row_history holds the before-image of each cancellation, but the
-- category and note are only in the columns this drops.
--
-- The INSERT grant is restored at table level, which is how it stood
-- before -- re-opening the ability for a sessions.create holder to insert
-- an already-cancelled workshop with a fabricated cancelled_by. Moot once
-- the columns are gone, and correct to restore so the grant matches what
-- the rest of the schema expects.

drop function if exists public.rpc_cancel_session(uuid, text, text);
drop function if exists app.rpc_cancel_session(uuid, text, text);

alter table public.sessions
  drop constraint if exists sessions_cancellation_consistency_check,
  drop constraint if exists sessions_cancellation_category_check;

alter table public.sessions
  drop column if exists cancellation_note,
  drop column if exists cancellation_category,
  drop column if exists cancelled_by,
  drop column if exists cancelled_at;

revoke insert on public.sessions from authenticated;
grant insert on public.sessions to authenticated;
