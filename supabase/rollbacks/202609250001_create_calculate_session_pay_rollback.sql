-- Rollback for 202609250001. Drops the function outright -- nothing
-- calls it yet (no UI, no payroll screen), so there is no caller to
-- break and no data it owns to lose.

drop function if exists app.calculate_session_pay(uuid, uuid);
