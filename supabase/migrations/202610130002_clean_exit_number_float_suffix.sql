-- ============================================================================
-- exit_number: strip the ".0" that Excel put there, on the 13 rows where the
-- whole value is digits followed by ".0" and nothing else.
-- ============================================================================
-- This is a DATA repair, not a cosmetic one. "83.0" is not what the contract
-- register says; it is what a spreadsheet did to `83` by reading the cell as a
-- float. A contract number has no decimal part, so the ".0" is damage with no
-- information in it, and leaving it means the app disagrees with the paper.
--
-- THE SAME DAMAGE WAS ALREADY CAUGHT ONCE, IN THE SAME SPREADSHEET. The
-- suppliers seed (202610070003) cleaned exactly this in `cui`:
-- "53213832.0" -> "53213832", and said so in its header. The contracts import
-- out of the same file two migrations later did not check `exit_number` for
-- it. See item 134 for the rule that follows.
--
-- The thirteen, before -> after:
--
--   ASISMART SRL                      8.0        -> 8
--   ASISMART SRL                      9.0        -> 9
--   ASISMART SRL                      4.0        -> 4
--   CENTRUL MEDICAL UNIREA SRL        155420.0   -> 155420
--   CERISEO SRL                       152.0      -> 152
--   EDUKIWI HUB S.R.L                 2626.0     -> 2626
--   FLEXIBLE OFFICE SPACE S.R.L.      5881.0     -> 5881
--   INTELLEMMI CONSULT S.R.L.         23.0       -> 23
--   POSITIVE PROJECTS SRL             112.0      -> 112
--   RALUCA MARGEAN                    83.0       -> 83
--   ROMAN V. ANDRA - CABINET AVOCAT   2388729.0  -> 2388729
--   SAGA SOFTWARE S.R.L.              1311175.0  -> 1311175
--   United Media Corporation S.R.L.   512.0      -> 512
--
-- ELEVEN ROWS ARE DELIBERATELY NOT TOUCHED, and the anchored pattern is what
-- protects them. Anything that is not digits-then-".0" end to end stays as it
-- is: 'N/A', 'ANEXA 2', '1/15.01.2026', '2388738/14.09.2025',
-- 'Act aditional 1', 'Act aditional 03 la contract 10/10/2022 din 10.10.2022',
-- 'ACT ADITIONAL 1/ 5881 din 01.07.2025', and Orange's 70-character sentence.
-- `~ '^[0-9]+\.0$'` and not `like '%.0'`: the second would have taken
-- '1/15.01.2026' apart, and a value with a REAL decimal (none here today, but
-- nothing stops one) is not damage and must survive.
--
-- The RENDERING is unchanged -- the screen still prints exit_number verbatim.
-- The value is what was wrong.
-- ============================================================================
do $$
declare
  v_expected integer;
  v_changed integer;
begin
  select count(*) into v_expected
    from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$';
  if v_expected <> 13 then
    raise exception 'expected 13 rows matching the float pattern, found % -- the data moved since this was written, re-read it before running', v_expected;
  end if;

  update public.supplier_contracts
     set exit_number = left(exit_number, length(exit_number) - 2)
   where exit_number ~ '^[0-9]+\.0$';
  get diagnostics v_changed = row_count;
  if v_changed <> 13 then
    raise exception 'expected to change 13 rows, changed %', v_changed;
  end if;

  -- Nothing may be left in the broken shape, including anything this UPDATE
  -- could in principle have created.
  select count(*) into v_expected
    from public.supplier_contracts where exit_number ~ '^[0-9]+\.0$';
  if v_expected <> 0 then
    raise exception '% rows still end in .0 after the update', v_expected;
  end if;
end $$;
