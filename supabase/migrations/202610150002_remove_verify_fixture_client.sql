-- ============================================================================
-- Delete the leftover fixture client `VERIFY 119-121 client` from Test Org B.
-- ============================================================================
-- Created 2026-10-12 by a verification script whose cleanup did not reach it.
-- It has no groups, no contracts and no contacts -- checked before writing
-- this, and checked again below so the delete cannot take anything with it.
--
-- Item 102 is this exact shape: a script that leaves a fixture behind in a
-- standing org, where it then looks like data. Test Org B is a test
-- organisation, so this was harmless; it is removed because a test org that
-- accumulates debris stops being a usable control.
--
-- Tolerates the row being absent (0 or 1), because any environment other than
-- this one never had it -- but refuses to run if it has acquired children,
-- since that would mean it is no longer the inert fixture this describes.
-- ============================================================================
do $$
declare
  v_id uuid;
  v_kids integer;
  v_deleted integer;
begin
  select c.id into v_id
    from public.clients c
    join public.organizations o on o.id = c.organization_id
   where o.name = 'WOW LAB Test Org B' and c.name = 'VERIFY 119-121 client';

  if v_id is null then
    raise notice 'fixture client not present -- nothing to do';
    return;
  end if;

  select (select count(*) from public.groups where client_id = v_id)
       + (select count(*) from public.contracts where client_id = v_id)
       + (select count(*) from public.client_contacts where client_id = v_id)
    into v_kids;
  if v_kids <> 0 then
    raise exception 'fixture client has % dependent row(s) -- not the inert leftover this migration describes, refusing to delete', v_kids;
  end if;

  delete from public.clients where id = v_id;
  get diagnostics v_deleted = row_count;
  raise notice 'deleted % fixture client', v_deleted;
end $$;
