-- Restores table-wide UPDATE on sessions, and the 3 contracts financial
-- columns + groups.children_confirmed, to authenticated -- reopening the
-- exact gap item 91 closed. Only roll back if the RPC-routed app code
-- (actions.ts) has ALSO been reverted to direct .update() calls first --
-- otherwise the app's own write paths break (they call functions this
-- rollback removes).

drop function if exists app.rpc_update_session_allocation(uuid, uuid, uuid);
drop function if exists app.rpc_update_session_attendance(uuid, int, text);
drop function if exists app.rpc_confirm_session_attendance(uuid, boolean);
drop function if exists app.rpc_correct_session_confirmation(uuid, boolean, boolean);
drop function if exists app.rpc_set_contract_financials(uuid, text, numeric, numeric);
drop function if exists app.rpc_set_group_children_confirmed(uuid, int);

grant update on public.sessions to authenticated;

grant update (billing_rule, estimated_value, previous_year_value) on public.contracts to authenticated;
grant insert (billing_rule, estimated_value, previous_year_value) on public.contracts to authenticated;
revoke update (billing_rule, estimated_value, previous_year_value) on public.contracts from app_write_owner;
revoke insert (billing_rule, estimated_value, previous_year_value) on public.contracts from app_write_owner;

grant update (children_confirmed) on public.groups to authenticated;
grant insert (children_confirmed) on public.groups to authenticated;
revoke update (children_confirmed) on public.groups from app_write_owner;
revoke insert (children_confirmed) on public.groups from app_write_owner;

revoke update on public.sessions from app_write_owner;

revoke usage on schema app from app_write_owner;
drop role if exists app_write_owner;
