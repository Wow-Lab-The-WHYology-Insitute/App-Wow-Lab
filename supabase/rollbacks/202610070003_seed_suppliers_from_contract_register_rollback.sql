-- 202610070003_seed_suppliers_from_contract_register_rollback.sql
--
-- Removes the 22 seeded supplier rows from the real org (slug `wow-lab`).
--
-- DELETE, not status='inactive'. The table's own convention is that a supplier
-- with contract history is retired rather than deleted (202608300001,
-- DATABASE_CONVENTIONS.md Sec12) -- that convention governs RETIRING A REAL
-- RELATIONSHIP, which is a business act. This is reversing a seed that should
-- not have run, which is a different thing: leaving 22 'inactive' rows behind
-- would mean the forward migration can never be re-applied (its own guard
-- refuses to seed on top of existing rows) and would misrepresent 22 live
-- relationships as ended.
--
-- Scoped to the 22 names this migration inserted, not `delete from suppliers
-- where organization_id = v_org`. If anyone has added a supplier through the
-- app since, a blanket delete would take it with them.
--
-- The row_history_capture() trigger fires BEFORE DELETE on this table, so each
-- removal is recorded in row history -- the deletion is auditable, which is
-- the point of that trigger. Expect 22 history rows after running this.
--
-- No supplier_contracts table exists yet, so nothing references these rows and
-- no FK can block the delete. If step 4 has since been built, run its rollback
-- first.

do $$
declare
  v_org     uuid;
  v_deleted int;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'supplier seed rollback: no organization with slug=wow-lab';
  end if;

  delete from public.suppliers
  where organization_id = v_org
    and name in (
      'ASISMART SRL',
      'RALUCA MARGEAN',
      'TRUȘAN FLORINA CĂTĂLINA PFA',
      'POPA C. RALUCA-MARIA-DIETETICIAN',
      'MERIȘAN IOANA-TEODORA PFA',
      'BEREA ALEXANDRU-VALENTIN',
      'BOLT',
      'CENTRUL MEDICAL UNIREA SRL',
      'CERISEO SRL',
      'EDUKIWI HUB S.R.L',
      'FLEXIBLE OFFICE SPACE S.R.L.',
      'INTELLEMMI CONSULT S.R.L.',
      'JOSAN SIMONA-CORINA PERSOANA FIZICA AUTORIZATA',
      'NEXT TOP INTERNATIONAL S.R.L.',
      'ORANGE ROMANIA S.A.',
      'PIDGIN HOST SRL',
      'POSITIVE PROJECTS SRL',
      'ROMAN V. ANDRA - CABINET AVOCAT',
      'S.C. WORDSPIN S.R.L.',
      'SAGA SOFTWARE S.R.L.',
      'STAR TAXI APP SRL',
      'United Media Corporation S.R.L.'
    );

  get diagnostics v_deleted = row_count;
  if v_deleted <> 22 then
    raise exception 'supplier seed rollback: expected to delete 22 rows, deleted % -- stopping so the discrepancy is looked at rather than committed', v_deleted;
  end if;
end $$;
