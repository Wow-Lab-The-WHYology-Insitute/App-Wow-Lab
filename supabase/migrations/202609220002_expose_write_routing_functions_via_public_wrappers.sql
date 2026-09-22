-- schema `app` is not exposed via the Data API (202607090001's own
-- comment, restated in 202607130004: "PostgREST only auto-generates RPC
-- endpoints for functions in exposed schemas (public, per supabase/
-- config.toml [api] schemas)"). 202607130004 added exactly one
-- deliberate exception, public.has_capability, and said explicitly
-- "nothing else in app is exposed this way" -- that sentence describes
-- the state before this migration, not a rule this migration breaks:
-- the same reasoning applies here, not a new pattern. Six more, one per
-- app.rpc_* function from 202609220001, all SECURITY INVOKER (no
-- elevation of their own -- the underlying app.rpc_* functions are
-- already SECURITY DEFINER and authenticated already holds EXECUTE on
-- them directly), forwarding only.

create or replace function public.rpc_update_session_allocation(p_session_id uuid, p_trainer_principal_id uuid, p_trainer_secundar_id uuid)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_update_session_allocation(p_session_id, p_trainer_principal_id, p_trainer_secundar_id);
$$;
comment on function public.rpc_update_session_allocation(uuid, uuid, uuid) is 'PostgREST-exposed wrapper around app.rpc_update_session_allocation() (item 91) -- the app schema itself is not exposed via the Data API. SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_update_session_allocation(uuid, uuid, uuid) from public;
grant execute on function public.rpc_update_session_allocation(uuid, uuid, uuid) to authenticated;

create or replace function public.rpc_update_session_attendance(p_session_id uuid, p_attendance_count int, p_experiment_delivered text)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_update_session_attendance(p_session_id, p_attendance_count, p_experiment_delivered);
$$;
comment on function public.rpc_update_session_attendance(uuid, int, text) is 'PostgREST-exposed wrapper around app.rpc_update_session_attendance() (item 91). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_update_session_attendance(uuid, int, text) from public;
grant execute on function public.rpc_update_session_attendance(uuid, int, text) to authenticated;

create or replace function public.rpc_confirm_session_attendance(p_session_id uuid, p_confirmed boolean)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_confirm_session_attendance(p_session_id, p_confirmed);
$$;
comment on function public.rpc_confirm_session_attendance(uuid, boolean) is 'PostgREST-exposed wrapper around app.rpc_confirm_session_attendance() (item 91) -- the function this whole item exists for. SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_confirm_session_attendance(uuid, boolean) from public;
grant execute on function public.rpc_confirm_session_attendance(uuid, boolean) to authenticated;

create or replace function public.rpc_correct_session_confirmation(p_session_id uuid, p_principal_confirmed boolean, p_secundar_confirmed boolean)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_correct_session_confirmation(p_session_id, p_principal_confirmed, p_secundar_confirmed);
$$;
comment on function public.rpc_correct_session_confirmation(uuid, boolean, boolean) is 'PostgREST-exposed wrapper around app.rpc_correct_session_confirmation() (item 91). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_correct_session_confirmation(uuid, boolean, boolean) from public;
grant execute on function public.rpc_correct_session_confirmation(uuid, boolean, boolean) to authenticated;

create or replace function public.rpc_set_contract_financials(p_contract_id uuid, p_billing_rule text, p_estimated_value numeric, p_previous_year_value numeric)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_set_contract_financials(p_contract_id, p_billing_rule, p_estimated_value, p_previous_year_value);
$$;
comment on function public.rpc_set_contract_financials(uuid, text, numeric, numeric) is 'PostgREST-exposed wrapper around app.rpc_set_contract_financials() (item 91). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_set_contract_financials(uuid, text, numeric, numeric) from public;
grant execute on function public.rpc_set_contract_financials(uuid, text, numeric, numeric) to authenticated;

create or replace function public.rpc_set_group_children_confirmed(p_group_id uuid, p_children_confirmed int)
returns text
language sql
security invoker
set search_path = ''
as $$
  select app.rpc_set_group_children_confirmed(p_group_id, p_children_confirmed);
$$;
comment on function public.rpc_set_group_children_confirmed(uuid, int) is 'PostgREST-exposed wrapper around app.rpc_set_group_children_confirmed() (item 91). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_set_group_children_confirmed(uuid, int) from public;
grant execute on function public.rpc_set_group_children_confirmed(uuid, int) to authenticated;
