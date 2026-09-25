-- verify_groups_delivery_format_nine_types_migration.sql
-- Dry-run of 202609210006 against the REAL live data (both orgs, all real
-- groups -- no fixtures, this is the acceptance test): applies the exact
-- DDL the migration contains, then reports every row's before/after, all
-- inside one transaction that always rolls back. Run BEFORE the real
-- `db push`.
-- Run with: supabase db query --linked --file scripts/verify_groups_delivery_format_nine_types_migration.sql

begin;

create temp table before_snapshot as
  select g.id, o.name as org, cl.name as client_name, g.module, g.delivery_format as before_value
  from public.groups g
  join public.organizations o on o.id = g.organization_id
  left join public.clients cl on cl.id = g.client_id;

alter table public.groups drop constraint groups_delivery_format_check;

update public.groups set delivery_format = 'scoli_private_recurente' where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558';
update public.groups set delivery_format = 'scoli_private_recurente' where id = 'efbe7e46-758e-4634-b9d8-57205ac45576';
update public.groups set delivery_format = 'parteneriate_companii'  where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95';

alter table public.groups
  add constraint groups_delivery_format_check
  check (delivery_format in (
    'scoala_altfel', 'saptamana_verde', 'wow_lab_party', 'parteneriate_companii',
    'cursuri_deschise', 'scoli_private_ocazionale', 'scoli_private_recurente',
    'evenimente_mall', 'party_companii'
  ));

do $verify$
declare
  report text := '';
  v_total int;
  v_unexpected int;
  rec record;
begin
  select count(*) into v_total from before_snapshot;

  -- Nothing unintended changed: every row is EITHER one of the 3 explicit
  -- rows above, OR its value is unchanged from before.
  select count(*) into v_unexpected
  from before_snapshot b
  join public.groups g on g.id = b.id
  where g.delivery_format is distinct from b.before_value
    and b.id not in ('de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558', 'efbe7e46-758e-4634-b9d8-57205ac45576', 'bda1f577-f381-4ced-a7f4-4d3399175e95');

  if v_unexpected = 0 then
    report := report || format(E'\n1. PASS - all %s rows accounted for; nothing outside the 3 explicit rows changed', v_total);
  else
    report := report || format(E'\n1. FAIL - %s row(s) outside the 3 explicit rows changed unexpectedly', v_unexpected);
  end if;

  for rec in
    select b.org, b.client_name, b.module, b.before_value, g.delivery_format as after_value
    from before_snapshot b
    join public.groups g on g.id = b.id
    order by b.org, b.client_name, b.module
  loop
    report := report || format(E'\n   %s / %s / %s: %L -> %L', rec.org, rec.client_name, rec.module, rec.before_value, rec.after_value);
  end loop;

  -- Sanity: an old-only value is now illegal.
  begin
    update public.groups set delivery_format = 'recurring' where id = (select id from before_snapshot limit 1);
    report := report || E'\n2. FAIL - the new constraint accepted the literal ''recurring'' -- it should be illegal now';
  exception when check_violation then
    report := report || E'\n2. PASS - writing the old literal ''recurring'' is rejected by the new constraint';
  end;

  raise exception '%', report;
end;
$verify$;

rollback;
