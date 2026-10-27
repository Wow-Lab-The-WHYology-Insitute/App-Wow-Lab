# WOW LAB OS — session entry point

Next.js 15 (App Router) + Supabase app for a Romanian STEM-workshop company. User communication
is in Romanian; code, comments, commits and this file are in English.

## Where a new session resumes context from, in this order

1. **`docs/OPEN_ITEMS.md`.** The single source of truth for what is open, what was decided, and
   what is in flight *right now*. Read the **"Readiness before invitation"** decision near the top
   first — it is Mihai's standing decision and outranks every item below it. Then read the
   **currently active items**, listed below. Do not start new work before reading this file; it
   has corrected its own past mistakes in place rather than hiding them, and the correction is
   usually the part that matters.
2. **`docs/DATABASE_CONVENTIONS.md`.** Every schema, RLS, and migration convention this project
   has settled on, numbered §1–§22 as of this writing. Check a new migration against it before
   writing one; conventions here are load-bearing, not style preferences.
3. **This file**, for how to run things. It does not restate decisions — those live in the two
   files above and go stale here the moment they do.

## Active items right now (update this list as items close or new ones open)

- **Item 163** — the trainer path to first login. Gated on Mihai's own four-condition phone check
  (see the standing decision), not on any calendar date — a date was written into this item once
  and had to be retracted (2026-10-27 correction inside the item itself). Check the item's current
  state before assuming an invitation has gone out.
- **Item 164** — process finding: human adoption steps ("a person tells two people") have no
  mechanism and no assertion anywhere in this codebase. Nothing is built for it. Read it before
  writing a date into any plan involving a person outside this session.
- **Items 159–162** — the school-calendar and schedule-generation work this week: three schools'
  real calendars replacing a wrong national-default assumption, the resulting cancel/generate
  migrations, and a `§17c` audit of five more screens whose correctness depends on an unwritten
  property of the data.
- **Items 147, 152, 157** — the pay-grid version model and the three instances of "who gets
  recorded as the actor" (§19). Read before touching anything in `trainer_grade_*`,
  `*_bonus_*`, `*_uplift_*`, or `cancelled_by`/`confirmed_by`-shaped columns.

If the above list looks stale (dates have passed, an item below has clearly moved), trust
`docs/OPEN_ITEMS.md` over this file and update this list to match.

## Running things

- `npm run dev` / `npm run build` — standard Next.js.
- `npx supabase db push --linked` — apply pending migrations to the linked remote project (there
  is no local Docker stack in this environment; `supabase db push` talks to the real database).
  Always check `npx supabase migration list --linked` for pending migrations before and after.
- `npx tsx scripts/run_rls_suite.ts` — the full RLS + business-logic test suite
  (`db/tests/*.sql`). Run after any migration touching `CREATE POLICY`/`ALTER POLICY`/
  `DROP POLICY`, or any migration renaming/dropping a column a policy or test reads. Takes several
  minutes; run in the background and poll rather than blocking on it.
- `npx tsx scripts/check_open_items_register.ts` — validates `docs/OPEN_ITEMS.md`'s own internal
  cross-references (an "item N above/below" pointing the wrong direction fails CI-style). Run
  after editing the register.

## Before ending a session

- `git status` clean (nothing uncommitted, nothing unpushed).
- `npx supabase migration list --linked` shows no pending migrations.
- The RLS suite is green.
- `docs/OPEN_ITEMS.md` reflects what is actually in flight, not just what was decided — a decision
  recorded without the week's real state (who's waiting on whom, what hasn't happened yet) is a
  session leaving its successor to ask "where was I."
