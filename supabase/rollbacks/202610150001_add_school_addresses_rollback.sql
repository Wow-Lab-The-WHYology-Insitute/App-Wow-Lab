-- Rollback for 202610150001. Clears address back to NULL on exactly the three
-- clients, matched by the same CUIs, and ONLY where the stored value is still
-- the one that migration wrote.
--
-- The value check is the point: if somebody has since corrected an address
-- through the app, this rollback must leave their value alone rather than
-- throw away a human edit to undo a machine one.
do $$
declare
  v_org uuid := (select id from public.organizations where name = 'WOW LAB');
  v_changed integer;
begin
  update public.clients set address = null
   where organization_id = v_org
     and (cui, address) in (
       ('RO37336710', 'Drumul Pădurea Pustnicu 125A, 014042 București'),
       ('18153988',   'Șoseaua București-Ploiești 160A, 015016 București'),
       ('44600473',   'Strada Coralilor 20G, 013328 București')
     );
  get diagnostics v_changed = row_count;
  raise notice 'cleared % of 3 addresses (any shortfall is a value edited since the migration, left untouched on purpose)', v_changed;
end $$;
