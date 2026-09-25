-- verify_clients_status_override_rename.sql
-- Dry-run of 202609210005 against the REAL live data (both orgs, all
-- real clients -- no fixtures, this is exactly the acceptance test asked
-- for): applies the exact DDL that migration contains, then asserts every
-- client's effective status is unchanged, all inside one transaction that
-- always rolls back. Run BEFORE the real `db push`.
-- Run with: supabase db query --linked --file scripts/verify_clients_status_override_rename.sql

begin;

-- ---- capture BEFORE, using the function as it exists right now ----
create temp table before_snapshot as
  select c.id, c.name, o.name as org, c.status as stored_before, public.client_effective_status(c) as effective_before
  from public.clients c
  join public.organizations o on o.id = c.organization_id;

-- ---- apply 202609210005's exact DDL ----
alter table public.clients alter column status drop not null;
alter table public.clients alter column status drop default;
update public.clients set status = null where status in ('prospect', 'active');
alter table public.clients drop constraint clients_status_check;
alter table public.clients rename column status to status_override;
alter table public.clients
  add constraint clients_status_override_check
  check (status_override is null or status_override in ('paused', 'churned'));

create or replace function public.client_effective_status(c public.clients)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when c.status_override is not null then c.status_override
    when exists (
      select 1 from public.contracts ct
      where ct.client_id = c.id and ct.status = 'signed'
    ) then 'active'
    else 'prospect'
  end;
$$;

-- ---- capture AFTER and compare, row by row ----
do $verify$
declare
  report text := '';
  v_mismatches int;
  v_total int;
  rec record;
begin
  select count(*) into v_total from before_snapshot;

  select count(*) into v_mismatches
  from before_snapshot b
  join public.clients c on c.id = b.id
  where b.effective_before is distinct from public.client_effective_status(c);

  if v_mismatches = 0 then
    report := report || format(E'\n1. PASS - all %s real client rows (both orgs) compute the IDENTICAL effective status before and after the rename', v_total);
  else
    report := report || format(E'\n1. FAIL - %s of %s rows changed effective status -- see per-row detail below', v_mismatches, v_total);
  end if;

  -- Per-row detail, always printed -- this IS the acceptance-test report, not just pass/fail.
  for rec in
    select b.org, b.name, b.stored_before, b.effective_before, c.status_override as stored_after, public.client_effective_status(c) as effective_after
    from before_snapshot b
    join public.clients c on c.id = b.id
    order by b.org, b.name
  loop
    report := report || format(
      E'\n   %s / %s: stored %L -> %L, effective %L -> %L',
      rec.org, rec.name, rec.stored_before, rec.stored_after, rec.effective_before, rec.effective_after
    );
  end loop;

  -- ---- sanity: the CHECK constraint now genuinely rejects a raw status word ----
  begin
    update public.clients set status_override = 'active' where id = (select id from before_snapshot limit 1);
    report := report || E'\n2. FAIL - the new constraint accepted the literal ''active'' -- it should be illegal now';
  exception when check_violation then
    report := report || E'\n2. PASS - writing the literal ''active'' to status_override is rejected by the new CHECK constraint';
  end;

  raise exception '%', report;
end;
$verify$;

rollback;
