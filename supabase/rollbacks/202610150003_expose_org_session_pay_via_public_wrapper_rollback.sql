-- Rollback for 202610150003. Drops both functions.
--
-- Unlike 202609250001's rollback ("nothing calls it yet, so there is no
-- caller to break"), this one DOES have a caller: /payroll reads
-- public.calculate_org_session_pay to render the per-trainer sums.
-- Dropping these without reverting app/(app)/payroll/page.tsx leaves that
-- page's .rpc() call failing against a function that no longer exists --
-- the page's own guard renders the "sums not available" state rather than
-- crashing, so the screen degrades to what it showed before this round
-- (confirmations and the pre-close check, no money) instead of breaking.
-- Revert the page in the same step anyway; a screen that silently stops
-- showing money is worse than one that is obviously rolled back.
--
-- app.calculate_session_pay (202609250001) is deliberately NOT dropped
-- here -- it predates this migration, has its own rollback, and this one
-- only ever read it.

drop function if exists public.calculate_org_session_pay(uuid);
drop function if exists app.calculate_org_session_pay(uuid);
