-- ROLLBACK IS LOSSY BY CONSTRUCTION -- READ BEFORE RUNNING.
--
-- This cannot recover whether a NULL status_override row was 'prospect'
-- or 'active' before the forward migration -- that distinction was
-- deliberately erased by the forward migration itself (both meant
-- exactly "no override" from the moment item 78 shipped, and which one a
-- row happened to hold was already an accident of write history, not
-- real information). Every row backfilled to NULL is restored here to
-- the literal string 'prospect' -- the schema's own original default,
-- not a recovered fact. If any of those rows was actually 'active'
-- before (the 3 real WOW LAB clients all were), running this rollback
-- moves them back to reading 'prospect' on the raw column -- a real
-- step backward for anyone reading the column directly, not a true undo.
--
-- What DOES survive exactly: paused/churned values, and every client's
-- EFFECTIVE status (public.client_effective_status() keeps deriving
-- correctly regardless, since it depends on signed-contract existence,
-- not on which of prospect/active the raw column says) -- the thing that
-- actually mattered continues to be correct. Only a raw read of the
-- column, post-rollback, loses fidelity for former-'active' rows.
--
-- Does NOT undo item 78 (202609210003) itself -- client_effective_status
-- keeps existing and keeps deriving from a signed contract; this only
-- reverses the rename layer this migration added on top of it.

alter table public.clients drop constraint clients_status_override_check;

alter table public.clients rename column status_override to status;

update public.clients set status = 'prospect' where status is null;

alter table public.clients alter column status set default 'prospect';
alter table public.clients alter column status set not null;

alter table public.clients
  add constraint clients_status_check
  check (status in ('prospect', 'active', 'paused', 'churned'));

comment on column public.clients.status is
  'Restored by rollback of 202609210005 -- NOT a true undo. Every row that held NULL (status_override, meaning "no override") was backfilled to the literal ''prospect'' here, which is lossy for any row that was actually ''active'' before the forward migration (all 3 real WOW LAB clients were). See the rollback file header before trusting this column''s value on any row that was ever touched by item 78/83.';

create or replace function public.client_effective_status(c public.clients)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when c.status in ('paused', 'churned') then c.status
    when exists (
      select 1 from public.contracts ct
      where ct.client_id = c.id and ct.status = 'signed'
    ) then 'active'
    else 'prospect'
  end;
$$;

comment on function public.client_effective_status(public.clients) is
  'Computed column (item 78): effective clients.status. paused/churned stored values always win; otherwise active iff a signed contract exists, else prospect. security definer -- bypasses contracts RLS deliberately for this one boolean, see migration header. Nothing writes literal ''active'' to clients.status going forward (changeClientStatus writes ''prospect'' as the reactivate sentinel); the 3 legacy rows that already hold it are treated identically to ''prospect'' here (fall through to the contract check).';
