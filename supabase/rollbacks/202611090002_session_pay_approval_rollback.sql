-- Rollback for 202611090002_session_pay_approval.sql.
--
-- Refuses if any session has actually been approved since -- rolling back
-- would silently delete a real authorization (who/when/what amount), not
-- just undo a schema change.

do $$
declare
  v_n integer;
begin
  select count(*) into v_n from public.sessions
  where trainer_principal_approved_at is not null or trainer_secundar_approved_at is not null;
  if v_n > 0 then
    raise exception 'rollback: % session(s) have a real approval recorded -- refusing to drop the columns that hold it. Decide what happens to that approval first.', v_n;
  end if;
end $$;

drop function if exists public.rpc_approve_session_pay(uuid[]);
drop function if exists app.rpc_approve_session_pay(uuid[]);

alter table public.sessions
  drop constraint if exists sessions_principal_approval_amount_paired_check,
  drop constraint if exists sessions_secundar_approval_amount_paired_check,
  drop constraint if exists sessions_principal_approval_needs_confirmation_check,
  drop constraint if exists sessions_secundar_approval_needs_confirmation_check,
  drop constraint if exists sessions_principal_approved_amount_nonnegative_check,
  drop constraint if exists sessions_secundar_approved_amount_nonnegative_check;

alter table public.sessions
  drop column if exists trainer_principal_approved_at,
  drop column if exists trainer_principal_approved_amount_bani,
  drop column if exists trainer_secundar_approved_at,
  drop column if exists trainer_secundar_approved_amount_bani;

delete from public.role_capabilities rc
using public.roles r, public.capabilities c
where rc.role_id = r.id and rc.capability_id = c.id
  and r.key = 'operations_manager' and c.key = 'finance.approvals.approve';

delete from public.capabilities where key = 'finance.approvals.approve';
