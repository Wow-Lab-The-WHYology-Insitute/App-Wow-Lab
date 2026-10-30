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
   has settled on, numbered §1–§23 as of this writing. Check a new migration against it before
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
- **Items 165–166** — found 2026-10-29 on Mihai's own trainer-path walkthrough in Test Org B.
  Item 165 (the language switcher was unreachable from every screen a pure Trainer can open —
  **fixed**: moved to the shell, default now reads the browser) is closed. Item 166 (`sessions`
  INSERT can write an already-confirmed workshop on any date, through neither write-path guard —
  **not fixed**, a decided trigger) is open; read it before touching `sessions`' INSERT policy or
  grants, or before routing session creation through a new function.
- **Items 159–162** — the school-calendar and schedule-generation work this week: three schools'
  real calendars replacing a wrong national-default assumption, the resulting cancel/generate
  migrations, and a `§17c` audit of five more screens whose correctness depends on an unwritten
  property of the data.
- **Items 147, 152, 157** — the pay-grid version model and the three instances of "who gets
  recorded as the actor" (§19). Read before touching anything in `trainer_grade_*`,
  `*_bonus_*`, `*_uplift_*`, or `cancelled_by`/`confirmed_by`-shaped columns. **Item 147 itself
  resolved AGAIN 2026-10-30** — the grid is back to 111-150 (`202610300001`), this time on Anca's
  own present-tense confirmation, not arithmetic. Read its newest section before assuming the
  2026-10-20 100-135 restatement is still current.
- **Item 167** — a secundar trainer with no principal, closed with a CHECK constraint
  (`sessions_secundar_requires_principal_check`) rather than left as a report, because the
  trainer-principal bonus Anca asked for (2026-10-29, not yet a numbered item — see the proposal
  in conversation, not the register) depends on the two slots meaning something.
- **Items 168–174** — found 2026-10-30 from Anca's 14 observations plus a full read of the real
  payroll timesheet (10,950 rows): Avenor/Brandine confirmed a second time (168, don't revert);
  `legal_entity_id` answers "who invoices," not "who bears the trainer's cost" — breaks for
  Scoala Altfel specifically (169); a calendar week showing empty (the recurring clubs' own
  holiday) is not a week with no work in it (170); real coverage is 38 of 89 current-year rows,
  not "three schools" (171, with Scoala ARC's own CUI question to resolve before import); **no
  future import may create a client named "Scoala Altfel" or "Săptămâna Verde"** — the real school
  behind each of those 205+59 rows is lost in the source and has to be found separately (172); five
  more gaps a real user found by using the app (173); a whole propose/confirm trainer-allocation
  workflow, noted and not built (174).
- **A2 ("Choose an experiment doesn't work," Anca) is FIXED, not just investigated any more —
  see item 179.** The real gap was `sessions.experiment_delivered` being free text on three
  separate forms while 312 real `lesson_plans` and a working proposal/validation flow (item 117)
  sat unconnected beside it (also item 173 point 2 above). Mihai explicitly declined the other
  candidate fix (an Operations "propose on behalf of the trainer" path) — that was never built.
- **B2, the trainer-principal bonus is item 175, built** (`202610300003`). §20 applied to it
  explicitly, named as the first time that convention fired on this project's own finding rather
  than on something asked for.
- **Item 176, 2026-10-30 — four Scoala Germana sessions a trainer's own `/my-work` is currently
  showing as money, none of them real by the record that would know.** Two (14 October) were
  confirmed by item 152's import migration under a reason true for 36 rows and false for these 2;
  two (28 October) were never confirmed by anyone and are still priced, because
  `app.calculate_session_pay`'s own payability comment ("confirmed OR...") is not actually
  implemented in its code — only `/payroll`'s client-side `payableBani`/`pendingBani` split keeps
  an unconfirmed row out of the headline figure. **Also corrects this file's own prior reporting**:
  an earlier October total (714,00) summed payable and pending as one number; the real split is
  476,00 payable (half of which is the 14 October pair) / 238,00 pending. Nothing cancelled, nothing
  fixed — read it before touching `app.calculate_session_pay`, before closing October, or before
  reporting any payroll total without reading off the payable/pending split.
- **Item 177, built — the month-close snapshot (B2).** `payroll_period_totals`, one row per
  (period, trainer, entity), written once at close, never updated, read only for a "closed at X,
  now shows Y" drift banner on `/payroll` — never by any write path. The boundary against this
  becoming a ledger is written into the migration itself (`202610300004`); read it before adding
  any new read of this table. Includes the item-175 bonus in `amount_bani`, confirmed before
  building, not after.
- **Item 178 — names check run org-wide, exactly two contradictions found.** Cătălina's (fixed:
  `full_name` aligned to displayed "Cătălina Moale", `suppliers.legal_name` set to the real invoice
  name for the first time) and Răzvan's (reported only — a missing diacritic, no supplier row, a
  spelling question not a legal-name one). Read it before assuming any other user's `full_name` is
  trustworthy.
- **Item 179, built — `session_lesson_plans` is one-to-many now; `experiment_delivered` is
  retired.** This is what A2 above actually needed. New RPCs
  (`rpc_propose_session_lesson_plan` now ADDs rather than replaces, `rpc_remove_session_lesson_plan`,
  `rpc_update_session_lesson_plan_delivered`), a 3-column unique index replacing the old
  session+trainer one, `delivered` defaulting true with the reasoning written beside the column
  (`202610300007`). Tested, RLS suite re-run clean. Read it before touching
  `session_lesson_plans` or anything that used to read `sessions.experiment_delivered`.
- **Item 180 — per-child nominal attendance, NOT BUILT, register-only, 4th in queue.** Anca wants
  names, not just a count: "vor sa stie cine la ce ateliere au fost prezenti." Blocked on a
  personal-data-of-minors precondition (legal basis, school contract, retention/deletion) and
  three questions only Anca can answer (where names come from, Lycée-only or all groups, existing
  written agreement). Do not build any part of this without that precondition being met first.
- **Item 152's false confirmation on the two 14 October Scoala Germana sessions is withdrawn**
  (`202610300008`) — `trainer_principal_confirmed_at` cleared, status untouched, nothing cancelled.
  Deliberately unimpersonated: `row_history.actor_user_id = NULL` on both, by design, per the new
  **§23** convention (below). Lorina's October figure moved from 476,00 payable/238,00 pending to
  238,00 payable/476,00 pending, 714,00 total unchanged. The 28 October pair is untouched — nothing
  was ever asserted about it.
- **§23, new in `docs/DATABASE_CONVENTIONS.md`: a NULL `row_history.actor_user_id` is a documented
  state, not an absence.** Read it before writing any migration that corrects a record without a
  real human actor behind the correction — the migration's own header has to say so and why, the
  same way `202610300008` does.
- **Item 181, CORRECTED same day — `maxdigitalro@gmail.com` is a real, non-test, Organization
  Owner account that would have passed `rpc_correct_session_confirmation`'s gate; it just wasn't
  used.** First written as "no real account corresponds to Mihai's own authority," which was
  wrong — a premise never checked against item 157's own earlier record of the same account. The
  NULL in `202610300008` stays correct regardless (it records what actually happened); the only
  open question is whether a future correction Mihai directs personally should impersonate that
  account instead. Read it as the example of checking a conclusion against this register's own
  prior entries, not just against what's in front of you.

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
