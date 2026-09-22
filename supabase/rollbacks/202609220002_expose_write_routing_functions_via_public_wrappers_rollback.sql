drop function if exists public.rpc_update_session_allocation(uuid, uuid, uuid);
drop function if exists public.rpc_update_session_attendance(uuid, int, text);
drop function if exists public.rpc_confirm_session_attendance(uuid, boolean);
drop function if exists public.rpc_correct_session_confirmation(uuid, boolean, boolean);
drop function if exists public.rpc_set_contract_financials(uuid, text, numeric, numeric);
drop function if exists public.rpc_set_group_children_confirmed(uuid, int);
