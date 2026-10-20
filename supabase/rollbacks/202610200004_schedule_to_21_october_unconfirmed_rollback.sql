-- Rollback for 202610200004. Removes the six workshops of 19-21 October,
-- returning wow-lab to the 38 imported ones.
--
-- Safe in a way the import's rollback is not: these six were inserted
-- unconfirmed and nothing has been asserted about them, so deleting them
-- destroys no one's statement. If a trainer has confirmed one in the
-- meantime, that IS a statement, and this rollback refuses rather than
-- discarding it.

do $$
declare
  v_org uuid;
  v_confirmed integer;
  v_removed integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'rollback: no organization with slug wow-lab';
  end if;

  select count(*) into v_confirmed
  from public.sessions
  where organization_id = v_org
    and session_date between '2026-10-17' and '2026-10-21'
    and (trainer_principal_confirmed_at is not null or trainer_secundar_confirmed_at is not null);

  if v_confirmed > 0 then
    raise exception 'rollback: % of the six workshops have been confirmed by a trainer -- refusing to delete a confirmation. Decide what happens to those rows first.', v_confirmed;
  end if;

  delete from public.sessions
  where organization_id = v_org
    and session_date between '2026-10-17' and '2026-10-21';

  get diagnostics v_removed = row_count;
  raise notice 'rollback: removed % workshop(s) from 17-21 October', v_removed;
end $$;
