-- Rollback for 202610120006 -- drops the three routing functions and their
-- wrappers. Lossless: functions hold no data.
--
-- After this, session_lesson_plans has NO write path at all (authenticated
-- holds no INSERT/UPDATE grant on it), which is the correct resting state --
-- not a table that silently becomes writable by policy alone.

drop function if exists public.rpc_mark_session_lesson_plan_seen(uuid);
drop function if exists public.rpc_decide_session_lesson_plan(uuid, text, text);
drop function if exists public.rpc_propose_session_lesson_plan(uuid, uuid);

drop function if exists app.rpc_mark_session_lesson_plan_seen(uuid);
drop function if exists app.rpc_decide_session_lesson_plan(uuid, text, text);
drop function if exists app.rpc_propose_session_lesson_plan(uuid, uuid);
