"""
Generates supabase/migrations/202610120004_import_lesson_plan_catalogue.sql from
the Centralizator workbook. Run by hand; the generated file is committed, so a
reviewer reads SQL rather than trusting this script.

Python, not TypeScript, for one reason: this repo has no xlsx reader in
package.json and openpyxl is already available. Every other hand-run script
here is .ts.

    python3 scripts/generate_lesson_plan_import.py \
        ~/Downloads/"Centralizator module WOW LAB 2023-2024-2025 (1).xlsx"

WHY THE COLUMN MAP IS EXPLICIT AND NOT SNIFFED FROM HEADERS. Three sheets put
their header row one column to the LEFT of their own data (`Modul WOW LAB MIX`'s
third block, `Modul CHEMISTRY FOR ME`, `Modul LIGHTS AND COLOURS`). A
header-driven parse reads MIX's third "Discutam despre" column as its plan
column and silently harvests 33 what-is-taught strings as plan references. That
already happened once, in the measurement recorded in OPEN_ITEMS item 103, and
the strings it produces look like prose rather than like a parse error.

IDs ARE DETERMINISTIC (uuid5 of the source key), so re-running this produces a
byte-identical file and the rollback can delete exactly what was inserted.
"""
import openpyxl, re, sys, unicodedata, uuid
from collections import Counter, defaultdict

NS = uuid.UUID("5f4d2c11-7e39-4b6a-9c52-8a1d0e7b3f44")  # fixed for this import

# (first data row index, [(ordinal, title, what_is_taught, plan) ...]) 0-indexed.
SHEETS = {
    " GAGA (Geology,Arheology,Geogra": ("gaga",          1, [(0, 1, 2, 3, None)]),
    "Modul GREEN ENERGY":             ("green_energy",   1, [(0, 1, 2, 3, None)]),
    "Modul WOW LAB MIX":              ("wow_mix",        2, [(1, 2, 3, 4, "level_beginner"),
                                                             (6, 7, 8, 9, "level_advanced"),
                                                             (11, 12, 13, 14, "copii_mici")]),
    "Modul TikTok Science":           ("tiktok",         1, [(0, 1, 2, 3, None)]),
    "Modul FOOD SCIENCE":             ("food_science",   1, [(0, 1, 2, 3, None)]),
    "Modul LOTIONS AND POTIONS":      ("lotions",        1, [(0, 1, 2, 4, None)]),
    "Modul MAGIC OF PHSYSICS":        ("magic_physics",  2, [(0, 1, 2, 3, None)]),
    "Modul CHEMISTRY FOR ME":         ("chem_me",        2, [(1, 2, 3, 4, None)]),
    "CHEMISTRY FOR HIGHSCHOOL":       ("chem_hs",        1, [(0, 1, 2, 4, None)]),
    "Modul LIGHTS AND COLOURS":       ("lights",         2, [(1, 2, 3, 4, None)]),
    "Modul DETECTIVE SCIENCE":        ("detective",      2, [(1, 2, 3, 4, None)]),
    "Modul ASTRONOMY":                ("astronomy",      2, [(0, 1, 2, 3, None)]),
    "Modul ANATOMY":                  ("anatomy",        2, [(1, 2, 3, 5, None)]),
    "I WANT TO BE A DOCTOR":          ("doctor",         1, [(0, 1, 2, 3, None)]),
    "I WANT TO BE A VET":             ("vet",            1, [(0, 1, 2, 3, None)]),
}
# `Modul MAGIC OF PHSYSICS` carries a SECOND plan in column E on one row
# (FIZ_LAVA LAMP_PD_2 and CHIM_LavaLamp_DC_8 on the same lesson). Treated as a
# second placement of the same lesson row, not as a separate lesson.
EXTRA_PLAN_COL = {"Modul MAGIC OF PHSYSICS": [4]}
EXCLUDED = {"CRACIUN": "no plan column at all (its column is `Link`, holding YouTube URLs), "
                       "zero plan filenames, a `feedback Cata` column and two seasonal banners. "
                       "An idea list, never one of the 15 modules (item 103)."}

FILENAME = re.compile(r".*_[A-Za-z&'\-. ]{1,25}[_.]\s*\d{1,3}\s*(\.xlsx)?$", re.I)
POINTER  = re.compile(r"^\s*\d{1,2}\s*\.\s+\S")
AUTHOR   = re.compile(r"_([A-Za-z]{1,3})[_.]\s*\d{1,3}\s*(?:\.xlsx)?$", re.I)


def norm(v):
    s = re.sub(r"\.xlsx$", "", str(v).strip(), flags=re.I)
    return re.sub(r"\s+", " ", s).strip().lower()


def pick(counter):
    """Most frequent; longest on a tie; deterministic on a further tie."""
    if not counter:
        return None
    best = max(counter.items(), key=lambda kv: (kv[1], len(kv[0]), kv[0]))
    return best[0]


def lit(v):
    return "null" if v is None else "'" + str(v).replace("'", "''") + "'"


def main(path):
    wb = openpyxl.load_workbook(path, data_only=True)
    plans = {}            # src_key -> dict
    titles = defaultdict(Counter)
    taught = defaultdict(Counter)
    placements = []       # (src_key, module, variant, ordinal, title_on_sheet)
    rejects = []          # (sheet, string, reason)
    seen_placement = set()
    excluded_rows = {}

    for ws in wb.worksheets:
        if ws.title in EXCLUDED:
            excluded_rows[ws.title] = sum(
                1 for r in ws.iter_rows(min_row=1, values_only=True) if any(c is not None for c in r))
            continue
        if ws.title not in SHEETS:
            rejects.append((ws.title, "", "sheet not in the column map -- not imported"))
            continue
        module, fd, blocks = SHEETS[ws.title]
        grid = list(ws.iter_rows(min_row=1, max_row=ws.max_row, values_only=True))
        for ri in range(fd, len(grid)):
            row = grid[ri]

            def g(c):
                if c is None or c >= len(row) or row[c] is None:
                    return None
                return str(row[c]).strip() or None

            for bi, (oc, tc, wc, pc, variant) in enumerate(blocks):
                title, taught_v, ordinal = g(tc), g(wc), g(oc)
                cells = [g(pc)]
                if bi == 0:
                    cells += [g(c) for c in EXTRA_PLAN_COL.get(ws.title, [])]
                for cell in [c for c in cells if c]:
                    if FILENAME.match(cell):
                        key = ("ref", norm(cell))
                        if key not in plans:
                            m = AUTHOR.search(cell)
                            plans[key] = dict(
                                plan_ref=norm(cell), plan_filename=cell, status="written",
                                author_initials=(m.group(1).upper() if m else None))
                    elif POINTER.match(cell):
                        key = ("ptr", norm(cell))
                        if key not in plans:
                            plans[key] = dict(plan_ref=None, plan_filename=cell,
                                              status="planned", author_initials=None)
                    else:
                        rejects.append((ws.title, cell, "matches neither the filename pattern nor "
                                                        "the chapter-pointer shape"))
                        continue
                    if title:
                        titles[key][title] += 1
                    if taught_v:
                        taught[key][taught_v] += 1
                    pk = (key, module, variant or "")
                    if pk in seen_placement:
                        rejects.append((ws.title, cell,
                                        "duplicate placement -- this plan already appears under "
                                        f"module `{module}`" + (f" variant `{variant}`" if variant else "")))
                        continue
                    seen_placement.add(pk)
                    try:
                        ordv = str(int(float(ordinal))) if ordinal else None
                    except ValueError:
                        ordv = None
                    placements.append((key, module, variant, ordv, title))

    for key, p in plans.items():
        p["id"] = str(uuid.uuid5(NS, f"{key[0]}:{key[1]}"))
        p["canonical_title"] = pick(titles[key]) or p["plan_filename"]
        p["what_is_taught"] = pick(taught[key])
        p["n_titles"] = len(titles[key])

    written = [p for p in plans.values() if p["status"] == "written"]
    planned = [p for p in plans.values() if p["status"] == "planned"]
    multi = [p for p in plans.values() if p["n_titles"] > 1]
    per_plan = Counter(k for k, _m, _v, _o, _t in placements)
    multi_module = sum(1 for k in plans if len({m for kk, m, _v, _o, _t in placements if kk == k}) > 1)

    out = []
    w = out.append
    w("-- ============================================================================")
    w("-- The catalogue itself. GENERATED by scripts/generate_lesson_plan_import.py")
    w("-- from `Centralizator module WOW LAB 2023-2024-2025 (1).xlsx` (the 2026-10-07")
    w("-- export, the one with I WANT TO BE A VET unhidden). Do not hand-edit: re-run")
    w("-- the generator, which is deterministic and will reproduce this file.")
    w("-- ============================================================================")
    w("-- Anca approved the catalogue 2026-10-12 and asked for it as a searchable")
    w("-- selector a trainer can find a plan in quickly (item 110).")
    w("--")
    w(f"-- {len(plans)} plans: {len(written)} written (a real plan filename) and")
    w(f"-- {len(planned)} planned (a chapter pointer, no plan written yet).")
    w(f"-- {len(placements)} placements across {len({m for _k, m, _v, _o, _t in placements})} modules.")
    w(f"-- {multi_module} plans appear under more than one module; {len(multi)} carry more than")
    w("-- one title in the source, which is why canonical_title is a CHOICE (most")
    w("-- frequent spelling, longest on a tie) and every per-sheet title is kept on")
    w("-- lesson_plan_modules.title_on_sheet.")
    w("--")
    w("-- The chapter pointers are deduplicated BY THEIR OWN TEXT, not per source row:")
    w("-- `1. Lungs` is one planned topic that both ANATOMY and DOCTOR point at, with")
    w("-- the same title (`Lung model`) on both sheets -- the same shape as a written")
    w("-- plan shared between modules. Note the limit honestly: plan_ref is null for")
    w("-- these, so the partial unique index does NOT cover them and the database")
    w("-- cannot stop a future duplicate. The guard below is what stops this import")
    w("-- from being the one that creates them.")
    w("--")
    w("-- EXCLUDED, recorded rather than silently dropped:")
    for s, why in EXCLUDED.items():
        w(f"--   * `{s}` ({excluded_rows.get(s, 0)} non-empty rows) -- {why}")
    w("--")
    w(f"-- REJECTED, {len(rejects)} strings, each listed so none is a silent loss:")
    for s, cell, why in rejects:
        w(f"--   * [{s}] {cell!r} -- {why}" if cell else f"--   * [{s}] {why}")
    w("")
    w("do $$")
    w("declare")
    w("  v_org uuid;")
    w("  v_plans int;")
    w("  v_placements int;")
    w("begin")
    w("  select id into v_org from public.organizations where slug = 'wow-lab';")
    w("  if v_org is null then")
    w("    raise exception 'lesson plan import: organization wow-lab not found';")
    w("  end if;")
    w("")
    w("  -- Same guard shape as 202610070003's supplier seed, for the same reason:")
    w("  -- refusing is the correct response to finding data already there, and the")
    w("  -- refusal names itself instead of failing on a constraint three statements")
    w("  -- later. 202610070003's own refusal is what surfaced item 113.")
    w("  if exists (select 1 from public.lesson_plans where organization_id = v_org) then")
    w("    raise exception 'lesson plan import: org wow-lab already has lesson_plans rows "
      "-- refusing to import on top of existing data';")
    w("  end if;")
    w("")
    w("  insert into public.lesson_plans")
    w("    (id, organization_id, plan_ref, plan_filename, canonical_title, what_is_taught, "
      "author_initials, status)")
    w("  values")
    rows = []
    for p in sorted(plans.values(), key=lambda p: (p["status"], p["canonical_title"].lower())):
        rows.append(f"    ('{p['id']}', v_org, {lit(p['plan_ref'])}, {lit(p['plan_filename'])}, "
                    f"{lit(p['canonical_title'])}, {lit(p['what_is_taught'])}, "
                    f"{lit(p['author_initials'])}, '{p['status']}')")
    w(",\n".join(rows) + ";")
    w("")
    w("  insert into public.lesson_plan_modules")
    w("    (organization_id, lesson_plan_id, module, variant, ordinal, title_on_sheet)")
    w("  values")
    rows = []
    for key, module, variant, ordinal, title in sorted(
            placements, key=lambda r: (r[1], r[2] or "", int(r[3]) if r[3] else 0)):
        rows.append(f"    (v_org, '{plans[key]['id']}', '{module}', {lit(variant)}, "
                    f"{ordinal if ordinal else 'null'}, {lit(title)})")
    w(",\n".join(rows) + ";")
    w("")
    w("  select count(*) into v_plans from public.lesson_plans where organization_id = v_org;")
    w("  select count(*) into v_placements from public.lesson_plan_modules "
      "where organization_id = v_org;")
    w(f"  if v_plans <> {len(plans)} then")
    w(f"    raise exception 'lesson plan import: expected {len(plans)} plans, found %', v_plans;")
    w("  end if;")
    w(f"  if v_placements <> {len(placements)} then")
    w(f"    raise exception 'lesson plan import: expected {len(placements)} placements, found %', "
      "v_placements;")
    w("  end if;")
    w("end $$;")
    w("")

    dest = "supabase/migrations/202610120004_import_lesson_plan_catalogue.sql"
    open(dest, "w", encoding="utf-8").write("\n".join(out))
    rb = "supabase/rollbacks/202610120004_import_lesson_plan_catalogue_rollback.sql"
    open(rb, "w", encoding="utf-8").write(
        "-- Rollback for 202610120004 -- removes the imported catalogue.\n"
        "--\n"
        "-- Scoped to wow-lab and to rows with no session link pointing at them. If a\n"
        "-- trainer has already proposed one of these plans, the delete FAILS LOUDLY on\n"
        "-- session_lesson_plans' foreign key rather than cascading -- deliberately: a\n"
        "-- proposal is a record of a real choice a real person made, and removing the\n"
        "-- catalogue under it is a human decision, not an automatic one.\n"
        "--\n"
        "-- Fully reproducible: re-running 202610120004 restores byte-identical rows,\n"
        "-- ids included (uuid5 of the source key).\n"
        "--\n"
        "-- To see what would block it first:\n"
        "--   select count(*) from public.session_lesson_plans;\n\n"
        "delete from public.lesson_plan_modules\n"
        " where organization_id = (select id from public.organizations where slug = 'wow-lab');\n\n"
        "delete from public.lesson_plans\n"
        " where organization_id = (select id from public.organizations where slug = 'wow-lab');\n")

    print(f"{dest}: {len(plans)} plans ({len(written)} written / {len(planned)} planned), "
          f"{len(placements)} placements, {len(rejects)} rejects")
    print(f"  multi-module plans: {multi_module} | multi-title plans: {len(multi)}")
    print(f"  placements per plan, top: {per_plan.most_common(3)}")


if __name__ == "__main__":
    main(sys.argv[1])
