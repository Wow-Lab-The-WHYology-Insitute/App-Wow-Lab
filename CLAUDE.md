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
- **Item 182, BUILT and CLOSED 2026-11-09 (`202611090001`) — Avenor's billing entity split by
  contract, not by session.** `contracts.amends_contract_id` (same shape already live on
  `supplier_contracts`) lets the existing Avenor contract (Brandine, from 2026-10-01) amend a new
  predecessor (Experimente Wow, September only). Entity-on-session was measured and rejected, not
  just judged more complex: every real school's entity history is sequential except Scoala Altfel,
  whose apparent concurrency is item 172's own CUI-identity problem, not a true need (§17 shape,
  named explicitly). Read-side change in the same commit: `app/(app)/payroll/page.tsx`'s
  `entityOfGroup` walks the amends chain by the SESSION'S OWN date. The 2026-10-01 changeover date,
  written as an assumption, is **confirmed by Anca** — migration header updated in place to say so.
- **Item 183, rule, 2026-11-09 — a match against the real timesheet confirms; a mismatch means
  "ask," never "the app is wrong."** The timesheet is delayed evidence (trainers file late, Anca
  corrects it after the fact), not a settled reference. Confirmed a second way the same day: Lycée
  has two real, `planned` sessions (2–3 Nov) past its own last timesheet row (13 Oct) — an app row
  with no timesheet row yet is not an app error, same asymmetry item 170 already named at the week
  grain. Read it before trusting any future timesheet-vs-app comparison either way.
- **Item 171's coverage is now TWO numbers, not one — 41 (upper bound: timesheet rows at schools the
  app knows about) vs. 40 (rows with an actual session/date/trainer correspondent, measured row by
  row).** The one gap is Scoala Germana's 14 October ambiguity (item 152). The old "avem 38" figure
  and the new 41 were answering different questions, not disagreeing — resolved, not a lingering
  discrepancy. "X of Y" coverage was never a threshold that reaches 100%; the denominator itself
  grows (Teodora alone went 7→20 rows in ten days).
- **Item 184, 2026-11-09, CORRECTED same day — zero real trainers have ever self-confirmed a
  session through the app, and this is still a real problem, not explained away.** Measured via
  `row_history`: every confirmation any of the three real trainers (Cătălina, Teodora, Lorina) has
  ever carried came from an import or a correction, never from the trainer tapping confirm. First
  read as "maybe the real process never needed trainers to confirm" — wrong, same error shape as
  item 182's own Scoala Altfel argument, in the other direction: two additive facts (confirmation
  is correct AND a separate approval step is missing) read as mutually exclusive. Anca's answer:
  both are true. The trainer screen is correct; zero self-confirmations stays unresolved. Lorina's
  own "27 octombrie" figure was also Mihai's own error, corrected in place to 19 Oct
  created/19 Oct confirmed/29 Oct last sign-in. `auth.audit_log_entries` is empty (0 rows)
  org-wide — known Supabase retention limit, not instrumented, since it only matters under the
  reading that's now closed.
- **Item 185, 2026-11-09 — measured, then item 186: no approval mechanism existed anywhere in this
  application before today.** No status/column resembled approval; `finance.operations.*`/
  `finance.reporting.*` unlocked nothing narrower than the whole month; nothing between
  confirmation and the payable figure was human. Anca's answer confirmed the exact missing shape
  (trainer confirms, Cătălina OR Anca approves, approval authorizes without recomputing) and gave
  the THIRD dated confirmation of the 111-150/11% uplift (2026-07-30, 2026-09-24, 2026-10-29/30,
  now reconfirmed 2026-11-09).
- **Item 186, BUILT 2026-11-09 (`202611090002`) — session-pay approval, capability-gated, amount
  frozen.** New capability `finance.approvals.approve`, granted to Operations Manager (how
  Cătălina — Trainer AND approver — gets it, proving approval is gated by capability, not role).
  Four new `sessions` columns (`trainer_{principal,secundar}_approved_at`/`_amount_bani`); who
  approved lives in `row_history`, not a new column (§19/§23). `app.rpc_approve_session_pay`,
  bulk by design. **Freezing the amount is required, not optional** — measured and proven in
  `db/tests/session_pay_approval.sql`: a grid restated in place (same shape as `202610300001`)
  moves a fresh calculation but never an already-approved amount. `/payroll` now has a third
  bucket (confirmed-unapproved, not payable) and an "Approve all" action gated on `canApprove`.
  `payroll_period_totals` (item 177) rebuilt to snapshot approved amounts, not confirmed ones.
  Full RLS suite re-run, 386/386 green. **Not built:** withdrawing an approval, a four-eyes rule —
  Mihai's open questions for Anca. **First live case prepared, not yet run:** Cătălina's own six
  past-unconfirmed sessions (Avenor ×4, Lycée ×2) — the only person who can test both halves.
- **Item 187, 2026-11-09 — closing the loop on item 186: three real gaps, two measured and
  reported, two repaired before the Cătălina test.** (1) Both already-closed months (September,
  real org and test org) snapshot at ZERO in `payroll_period_totals`, correctly — zero approvals
  exist anywhere yet, so the rebuilt snapshot (item 186) is reading an honest absence, not a bug.
  No on-screen explanation of that zero exists yet — reported, not built, Mihai's call on wording.
  (2) Measured further than the freeze question itself required: **36 real sessions, 6,563.00
  lei** (26 Sept / 10 Oct, 4,675.00 / 1,888.00 lei), confirmed before approval existed, hold no
  frozen amount at all and are retroactively exposed by the exact mechanism item 186's own
  freeze-measurement proved. Two ways to close it — retroactive freeze (needs Mihai's explicit
  instruction, §23-shaped, no human approver) or leave exposed-but-documented until a real
  approver clears them. **Neither built; his decision.** (3) `/my-work`'s five-row cap FIXED —
  it was capping the whole list including overdue debt, so a 6th real unconfirmed session could
  silently fall off the list the banner still counted; now only the future-preview rows are
  capped, debt never is. (4) `/payroll`'s approval backlog is month-scoped by screen but not by
  Anca's real process — one line ADDED (not a rewrite): "N de aprobat în alte luni," computed
  org-wide from confirmed-unapproved state, not from the whole sessions table.
- **`docs/DATABASE_CONVENTIONS.md` gained §24 and §25 this same day, both extracted from item 186
  as general method, not as one-off fixes:** §24 — prove a function's reproducibility by inducing
  the real mutation in a disposable transaction, never by reasoning about the schema alone (how
  the freeze decision was actually settled). §25 — a capability gate is verified by walking the
  real, named account through every gate between request and action, never by checking that each
  gate's own written list now mentions the right capability (how the missing `/payroll` page-gate
  branch was caught, same day, before asking Cătălina to test anything).

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
