-- Rollback for 202610130002. Puts ".0" back on EXACTLY the thirteen rows that
-- lost it, named one by one rather than matched by a pattern.
--
-- A pattern rollback (`where exit_number ~ '^[0-9]+$'`) would be wrong: it
-- would also hit any bare-integer exit_number that was always correct, or one
-- entered after the migration ran, and hand it damage it never had. Restoring
-- a value is only safe when you can name the value.
do $$
declare
  v_pairs text[][] := array[
    ['8','ASISMART SRL'], ['9','ASISMART SRL'], ['4','ASISMART SRL'],
    ['155420','CENTRUL MEDICAL UNIREA SRL'], ['152','CERISEO SRL'],
    ['2626','EDUKIWI HUB S.R.L'], ['5881','FLEXIBLE OFFICE SPACE S.R.L.'],
    ['23','INTELLEMMI CONSULT S.R.L.'], ['112','POSITIVE PROJECTS SRL'],
    ['83','RALUCA MARGEAN'], ['2388729','ROMAN V. ANDRA - CABINET AVOCAT'],
    ['1311175','SAGA SOFTWARE S.R.L.'], ['512','United Media Corporation S.R.L.']
  ];
  v_row text[];
  v_changed integer;
  v_total integer := 0;
begin
  foreach v_row slice 1 in array v_pairs loop
    update public.supplier_contracts sc
       set exit_number = v_row[1] || '.0'
      from public.suppliers s
     where s.id = sc.supplier_id
       and s.name = v_row[2]
       and sc.exit_number = v_row[1];
    get diagnostics v_changed = row_count;
    v_total := v_total + v_changed;
  end loop;

  if v_total <> 13 then
    raise exception 'rollback expected to restore 13 rows, restored % -- refusing to leave the table half-reverted', v_total;
  end if;
end $$;
