"""
Generates supabase/migrations/202610120010_import_supplier_contracts.sql from
`Tabel contracte furnizori Wow Lab.xlsx` (sheet misnamed `Tabel Clienti Wow
Lab`; it holds suppliers). Run by hand; the generated SQL is committed so a
reviewer reads SQL rather than trusting this script.

    python3 scripts/generate_supplier_contract_import.py \
        ~/Downloads/"Tabel contracte furnizori Wow Lab.xlsx"

39 register rows: 9 are trainer contracts (Trușan x3, Popa x3, Merișan x3) and
belong in trainer_contracts, which does not exist yet and is blocked on a grade
nobody has supplied (item 105). The other 30 are these.

Python rather than TypeScript for the same reason as the lesson-plan importer:
no xlsx reader in package.json, openpyxl already present.

DETERMINISTIC IDS (uuid5 of the register row key), so re-running reproduces the
file byte for byte and amendment chains can reference parents by literal id
without a second pass.
"""
import datetime, openpyxl, re, sys, uuid

NS = uuid.UUID("b2c71d40-5e8a-4f31-9a6d-7c3e8b91f250")  # fixed for this import
ENTITY = {
    "experimente wow": "Experimente Wow SRL",
    "brandine advertising": "Brandine Advertising SRL",
    "asociatia stemplicity": "Asociatia STEMplicity",
}
TRAINER_MARKERS = ("TRUSAN", "TRUȘAN", "POPA C.", "MERISAN", "MERIȘAN")
OPEN_ENDED = {"nedeterminat"}
NOT_RECORDED = {"n/a"}


def lit(v):
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


def as_date(v):
    """A date, or None. The register mixes real dates with dd.mm.yyyy strings
    (three rows) and with words (`nedeterminat`, `N/A`, `1 AN`)."""
    if isinstance(v, datetime.datetime):
        return v.date().isoformat()
    if isinstance(v, datetime.date):
        return v.isoformat()
    if isinstance(v, str):
        m = re.match(r"^\s*(\d{2})\.(\d{2})\.(\d{4})\s*$", v)
        if m:
            return f"{m.group(3)}-{m.group(2)}-{m.group(1)}"
    return None


def clean_number(v):
    """Only a bare number. `1928 EUR` is rejected on purpose: nothing here
    carries a currency, so a value with one cannot share the column."""
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return float(v)
    return None


def main(path):
    ws = openpyxl.load_workbook(path, data_only=True)["Tabel Clienti Wow Lab"]
    rows = []
    for ri, r in enumerate(ws.iter_rows(min_row=2, values_only=True), 2):
        if r[1] is None:
            continue
        supplier = str(r[1]).strip()
        if any(m in supplier.upper() for m in TRAINER_MARKERS):
            continue  # trainer_contracts, not this table
        entity_raw = str(r[0] or "").strip()
        entity = ENTITY.get(entity_raw.lower())
        if entity is None:
            raise SystemExit(f"row {ri}: unmapped legal entity {entity_raw!r}")

        end_raw = r[7]
        end_date = as_date(end_raw)
        end_word = str(end_raw).strip().lower() if isinstance(end_raw, str) else ""
        open_ended = end_word in OPEN_ENDED
        # Anything that is neither a date, nor `nedeterminat`, nor `N/A`, nor
        # blank is a fact stated in prose (`1 AN`). It is preserved in notes
        # rather than turned into a date nobody wrote.
        unparsed_end = (
            end_word
            if end_word and not open_ended and end_word not in NOT_RECORDED and end_date is None
            else None
        )

        signed = as_date(r[5])
        notes = (str(r[16]).strip() if r[16] is not None else None)
        if unparsed_end:
            extra = f"Register states period_end as {str(end_raw).strip()!r} -- a duration in words, not a date; not derived."
            notes = f"{notes}\n{extra}" if notes else extra

        rows.append(dict(
            row=ri,
            supplier=supplier,
            entity=entity,
            entry_number=None if r[3] is None else str(r[3]).strip(),
            exit_number=None if r[4] is None else str(r[4]).strip(),
            signed_date=signed,
            period_start=as_date(r[6]),
            period_end=end_date,
            is_open_ended=open_ended,
            # A signing date requires a signed-ish status (the constraint);
            # a real contract whose date nobody recorded is still signed.
            status="signed",
            price_text=None if r[14] is None else str(r[14]).strip(),
            contract_value=clean_number(r[15]),
            drive_ref=None if r[9] is None else str(r[9]).strip(),
            notes=notes,
        ))
        rows[-1]["id"] = str(uuid.uuid5(NS, f"supplier_contract:{ri}"))

    # ---- amendment chains -------------------------------------------------
    # An amendment is a row whose supplier-side number says so. Its parent is
    # the row for the SAME supplier and SAME legal entity whose number the
    # amendment's own text references, or failing that the latest earlier row
    # for that pair. Resolved here, in Python, where it can be printed and
    # checked -- not in SQL where it would be a correlated subquery nobody
    # reads.
    AMEND = re.compile(r"act\s*adi(t|ț)ional|anexa", re.I)
    for r in rows:
        r["amends"] = None
        ex = r["exit_number"] or ""
        if not AMEND.search(ex) and not AMEND.search(r["notes"] or ""):
            continue
        siblings = [o for o in rows
                    if o is not r and o["supplier"] == r["supplier"] and o["entity"] == r["entity"]]
        # 1. the parent's number appears inside the amendment's own text
        named = [o for o in siblings
                 if o["exit_number"] and re.search(r"\b" + re.escape(o["exit_number"].rstrip(".0")) + r"\b", ex)]
        # 2. otherwise the latest sibling signed on or before this one
        if not named and r["signed_date"]:
            earlier = [o for o in siblings if o["signed_date"] and o["signed_date"] <= r["signed_date"]]
            named = sorted(earlier, key=lambda o: o["signed_date"])[-1:] if earlier else []
        if named:
            r["amends"] = named[-1]["id"]
            r["amends_row"] = named[-1]["row"]

    out = []
    w = out.append
    chains = [r for r in rows if r["amends"]]
    orphans = [r for r in rows
               if not r["amends"] and (AMEND.search(r["exit_number"] or "") or AMEND.search(r["notes"] or ""))]
    w("-- ============================================================================")
    w("-- The 30 non-trainer supplier contracts. GENERATED by")
    w("-- scripts/generate_supplier_contract_import.py from")
    w("-- `Tabel contracte furnizori Wow Lab.xlsx`. Do not hand-edit: re-run the")
    w("-- generator, which is deterministic and reproduces this file.")
    w("-- ============================================================================")
    w("-- SAD step 4. 39 register rows minus the 9 trainer contracts (Trusan x3,")
    w("-- Popa x3, Merisan x3), which belong in trainer_contracts -- still blocked on")
    w("-- a grade-at-signing nobody has supplied (item 105).")
    w("--")
    for ent in ("Experimente Wow SRL", "Brandine Advertising SRL", "Asociatia STEMplicity"):
        w(f"--   {ent}: {sum(1 for r in rows if r['entity'] == ent)} rows")
    w(f"--   open-ended (`nedeterminat`): {sum(1 for r in rows if r['is_open_ended'])}")
    w(f"--   period_end absent for another reason: {sum(1 for r in rows if not r['is_open_ended'] and not r['period_end'])}")
    w(f"--   contract_value populated: {sum(1 for r in rows if r['contract_value'] is not None)}")
    w(f"--   price_text populated: {sum(1 for r in rows if r['price_text'])}")
    w("--")
    w(f"-- AMENDMENT CHAINS RESOLVED ({len(chains)}):")
    for r in chains:
        w(f"--   row {r['row']} ({r['supplier']}, {r['exit_number']}) amends row {r['amends_row']}")
    w(f"-- AMENDMENT-SHAPED ROWS WITH NO PARENT IN THE REGISTER ({len(orphans)}):")
    for r in orphans:
        w(f"--   row {r['row']} ({r['supplier']}, {r['entity']}) -- {str(r['exit_number'])[:58]!r}")
    w("--   Their base contract was never entered. amends_contract_id stays null")
    w("--   rather than pointing at a guess; the reference survives in exit_number.")
    w("")
    w("do $$")
    w("declare")
    w("  v_org uuid;")
    w("  v_n int;")
    w("begin")
    w("  select id into v_org from public.organizations where slug = 'wow-lab';")
    w("  if v_org is null then")
    w("    raise exception 'supplier contract import: organization wow-lab not found';")
    w("  end if;")
    w("")
    w("  -- Same guard as 202610070003's supplier seed and 202610120004's catalogue:")
    w("  -- refusing names itself, instead of failing on a constraint later.")
    w("  if exists (select 1 from public.supplier_contracts where organization_id = v_org) then")
    w("    raise exception 'supplier contract import: org wow-lab already has supplier_contracts rows -- refusing to import on top of existing data';")
    w("  end if;")
    w("")
    w("  insert into public.supplier_contracts")
    w("    (id, organization_id, supplier_id, legal_entity_id, entry_number, exit_number,")
    w("     signed_date, period_start, period_end, is_open_ended, status, price_text,")
    w("     contract_value, drive_ref, notes)")
    w("  values")
    vals = []
    for r in sorted(rows, key=lambda r: r["row"]):
        vals.append(
            f"    -- register row {r['row']}\n"
            f"    ('{r['id']}', v_org,\n"
            f"     (select id from public.suppliers where organization_id = v_org and name = {lit(r['supplier'])}),\n"
            f"     (select id from public.legal_entities where organization_id = v_org and name = {lit(r['entity'])}),\n"
            f"     {lit(r['entry_number'])}, {lit(r['exit_number'])},\n"
            f"     {lit(r['signed_date'])}::date, {lit(r['period_start'])}::date, {lit(r['period_end'])}::date,\n"
            f"     {lit(r['is_open_ended'])}, {lit(r['status'])}, {lit(r['price_text'])},\n"
            f"     {lit(r['contract_value'])}, {lit(r['drive_ref'])}, {lit(r['notes'])})"
        )
    w(",\n".join(vals) + ";")
    w("")
    w("  -- The chains, in a second pass: a self-reference cannot be set in the same")
    w("  -- VALUES list that creates its target.")
    for r in chains:
        w(f"  update public.supplier_contracts set amends_contract_id = '{r['amends']}'")
        w(f"   where id = '{r['id']}';   -- register row {r['row']} amends row {r['amends_row']}")
    w("")
    w("  select count(*) into v_n from public.supplier_contracts where organization_id = v_org;")
    w(f"  if v_n <> {len(rows)} then")
    w(f"    raise exception 'supplier contract import: expected {len(rows)} rows, found %', v_n;")
    w("  end if;")
    w("  select count(*) into v_n from public.supplier_contracts")
    w("   where organization_id = v_org and supplier_id is null;")
    w("  if v_n <> 0 then")
    w("    raise exception 'supplier contract import: % row(s) failed to resolve a supplier', v_n;")
    w("  end if;")
    w("  select count(*) into v_n from public.supplier_contracts")
    w("   where organization_id = v_org and amends_contract_id is not null;")
    w(f"  if v_n <> {len(chains)} then")
    w(f"    raise exception 'supplier contract import: expected {len(chains)} amendment links, found %', v_n;")
    w("  end if;")
    w("end $$;")
    w("")

    open("supabase/migrations/202610120010_import_supplier_contracts.sql", "w", encoding="utf-8").write("\n".join(out))
    open("supabase/rollbacks/202610120010_import_supplier_contracts_rollback.sql", "w", encoding="utf-8").write(
        "-- Rollback for 202610120010 -- removes the 30 imported supplier contracts.\n"
        "--\n"
        "-- Scoped to wow-lab. Amendment links are cleared first so the self-referencing\n"
        "-- foreign key cannot block the delete, and because a half-deleted chain is a\n"
        "-- worse state than none.\n"
        "--\n"
        "-- Fully reproducible: re-running 202610120010 restores byte-identical rows,\n"
        "-- ids included (uuid5 of the register row number).\n"
        "--\n"
        "-- Anything Finance has edited by hand since the import is NOT reproducible --\n"
        "-- check public.row_history for table_name = 'supplier_contracts' before running\n"
        "-- this, and note those rows survive the delete.\n\n"
        "update public.supplier_contracts set amends_contract_id = null\n"
        " where organization_id = (select id from public.organizations where slug = 'wow-lab');\n\n"
        "delete from public.supplier_contracts\n"
        " where organization_id = (select id from public.organizations where slug = 'wow-lab');\n")

    print(f"30 expected / {len(rows)} written; {len(chains)} chains, {len(orphans)} orphan amendments")
    print(f"  entities: " + ", ".join(f"{e.split()[0]}={sum(1 for r in rows if r['entity']==e)}" for e in ENTITY.values()))
    print(f"  contract_value populated: {sum(1 for r in rows if r['contract_value'] is not None)}")
    print(f"  open_ended: {sum(1 for r in rows if r['is_open_ended'])}")
    for r in chains:
        print(f"  chain: row {r['row']} -> row {r['amends_row']}")
    for r in orphans:
        print(f"  orphan: row {r['row']} {r['supplier'][:28]}")


if __name__ == "__main__":
    main(sys.argv[1])
