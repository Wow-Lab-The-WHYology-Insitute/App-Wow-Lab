# Open Items Register

A verified list of known-open work: threads not started, rollout gaps, standing
re-verification obligations, small confirmed defects, and infrastructure
constraints. Every item below was checked against the current codebase and/or
the live production database on 2026-08-26 — none of it is carried over from
memory or notes without a fresh check. Where a check corrected or narrowed the
original framing, the correction is written into the item itself, not hidden.
Item 20 was added 2026-08-31, checked live as of that date, not part of the
2026-08-26 pass. The "Seed data cannot be reliably distinguished from real
data" entry was resolved 2026-09-01, and items 21-22 were added the same
date, checked live as of then — neither part of the 2026-08-26 pass either.
"No scheduled execution mechanism" was decided (not built now, with a
stated reopen trigger) the same 2026-09-01 date, also freshly checked live,
not carried over from the 2026-08-26 pass. Item 20 was updated and item 23
added 2026-09-02, both freshly checked live/against the real workbook as of
that date. "Migration history was missing
3 applied migrations" was found, repaired, and its fix proven end-to-end
the same date — also not part of the 2026-08-26 pass. Item 10 was resolved
2026-09-02 across two rounds (a DB constraint + the create-path fix, then
`markContractSigned`'s new optional date), both live-verified the same date.
Item 14's `LOCALE_SWITCHER_ENABLED` claim was corrected and items 24-25
added 2026-09-02, all freshly checked live that date. Item 22 got a second
addendum and item 30 was added 2026-09-03, both freshly checked live that
date. Item 27's `is_test_account` half was resolved 2026-09-04, verified
live except for the one caveat recorded in the item itself (no Docker, so
the reset-order claim is reasoned, not executed end to end). Item 22 got a
third addendum the same date: the two pending roles assigned, all eight
real accounts invited, and a zero-role account's invisibility in
`/admin/users` found and recorded — all freshly checked live. Also
2026-09-04: item 22 and item 23 each got one more confirmed-by-Anca note
(Cătălina's address; Școala Altfel bonuses vs. Happy Face), item 31
was added (Anka's 11 roles, confirmed deliberate), the zero-role gap in
item 22 was resolved the same date (see item 22 itself), and item 32 was
added (email OTP expiry raised to 24h, plus an unrelated live redirect-
URL drift found and corrected during the same push). Items 33-34 were
added 2026-09-07 (the 30 May roster compared against Appendix A rather
than assumed superseded; Anca's current active roster, cross-referenced
against both), and item 23's ~20-people note was corrected the same date
after that roster showed five of those people are active today. Item 33
got a same-date update (grades 5/6 confirmed as separately named in
Anca's pay grid, unresolved in the roster's own naming). Item 35 was
added the same date: the "Laura Moale" surname's actual provenance,
checked against git history rather than accepted from a working
hypothesis that was itself a month off, pending Anca's confirmation.
Updated 2026-09-08: item 35 resolved ("Moale" confirmed correct by
Anca; this item's own contamination hypothesis was the thing that was
wrong, not the surname) with a new forward-looking note (Cătălina's
future surname change); item 31 got Anka's actual substantive reason
(covering Laura's maternity leave); item 34's 14-unaccounted-for names
were closed by Anca (former collaborators, possible reactivation); and
item 36 was added (permanent-group count, pending one confirmation). Item 37 was added the same
date: the contracts write-side finance exclusion, investigated then removed on Anca's explicit
decision, verified live as the real users afterward. Item 34's blocking note was resolved the same
date: the five accounts it named were already created and already invited earlier in this session,
found by checking the live database rather than assumed from the request that asked for them again.
Item 38 was added the same date: `groups.children_billed`'s masking question, left open by the SAD
and closed by omission rather than by an actual decision — recorded alongside `updateGroup`
(`contract_id`/`notes`), the two `groups` gaps built this round that didn't depend on Anca first.
Item 38 was resolved later the same date: Anca answered, opposite to the SAD's own guess (counts
visible to everyone, the invoiceable amount hidden, not the reverse). Item 39 was added the same
date with the full decision record: `children_billed` decided derived-not-stored, not built;
`children_confirmed` writable in principle but blocked on an RLS gap; the real blocker named —
nobody can currently record session attendance, trainers included, on any layer; the masking rule
written into `WOWLAB_SAD_Field_Masking.md` §2.7 as a constraint on the not-yet-built billing
generator; and `delivery_format` gating confirmed for four formats, with `custom` left open rather
than guessed. Item 40 was added 2026-09-09, RESOLVED the same date: the three create forms'
disabled-submit guards over `clientId`/`legalEntityId`/`module`/`deliveryFormat`/`clientType` either
existed and could never fire, or (client type) never existed at all, because every one of those
selects was pre-filled from `options[0]` with no empty value reachable in the UI — found and fixed
the same session, alongside adding the missing `clientType`/`type` gates. Item 41 was added the same
date, also RESOLVED: the operator procedure this fix made half-wrong had never lived anywhere
checkable (an Asana message), so it moved into `docs/` with a manifest table and
`scripts/check_operator_guide.ts` — whose first real run caught one genuine mismatch in the
freshly-rewritten guide (`create_contract`'s button text), fixed before it reached Anca.
Item 41's own "data-entry gap" framing for `Asociatia STEMplicity` was itself corrected 2026-09-10:
item 42 was added the same date, RESOLVED — Anca confirmed names are written without diacritics in
this system by convention, on her own name specifically, making the STEMplicity spelling correct as
recorded, not a typo; the second time a plausible-looking fix would have broken correct data, after
item 35's "Laura Moale." The diacritics audit that surfaced that question also produced a real,
separate fix the same date: five search boxes' `.toLowerCase().includes()` matching, which does not
fold diacritics and missed matches in both directions, now goes through one shared
`lib/search.ts` helper on both sides of every comparison, verified against ten cases (`ș`/`ț`
specifically) and live in the browser with two throwaway fixtures, cleaned up after. Items 43 and 44
were added the same date, recorded with no action taken: `localeCompare()` with no locale in three
sort call sites (cosmetic), and `contracts.exit_number`'s uniqueness constraint being byte-exact
with no Unicode normalization anywhere in the app (narrow, real, unmitigated). Item 45 was added
2026-09-10: the trainer end-of-session screen Anca described, mapped across five parts before any
of it is built — two ready to build (trainer-written `attendance_count`/`experiment_delivered`;
`children_confirmed` now unconditional on `delivery_format`, per Anca), two blocked on work this
session didn't scope (an experiment-level catalog; whether OD-7 covers peer trainer feedback, Anca's
call), and the load-bearing one underneath all of them: nothing in the database records that a
specific trainer delivered a specific session, which is the fact §12's pay model actually counts.
Part 5's shape was decided the same date, not built: two nullable timestamp columns,
`trainer_principal_confirmed_at`/`trainer_secundar_confirmed_at`, matching the two allocation slots
that already exist — a `sessions.status` transition and a separate confirmation table were both
argued against and rejected, on this codebase's own precedent (item 8's second-write-path warning;
the sessions migration's own high bar for a new entity). `sessions.status` stays Operations'
scheduling field; the pay count reads the confirmation timestamps directly, never `status`. Left
open with Anca: correction rights, and whether a month's confirmations freeze — flagged against
AD-10's frozen-statements commitment, which this session could not find documented anywhere in
this repo. Found the following session, 2026-09-10: `WOW_LAB_OS_Solution_Architecture_Document.md`
(`~/Downloads`, never in the repo) is where AD-10 and fourteen siblings actually live, status DRAFT,
never approved. Copied verbatim into `docs/`, with a separate reconciliation file
(`WOW_LAB_OS_AD_Reconciliation.md`) checking all fifteen against the real schema, and item 46 added
recording the cost of the gap: AD-3 contradicted by what was built, AD-11/AD-15 the same decision
made twice, and AD-4 independently re-argued from scratch one day before this discovery, reaching
the same conclusion item 45 part 5 had just reached a month later. Item 47 was added and resolved
the same date: the fifty unpushed commits themselves, published through `develop` (Preview verified
first) then `main` (Production verified directly against `app.wowlab.ro`, by eye, not inferred),
with the two causes named plainly — commit and push treated as one act when they aren't, and nine
days of `localhost`-only verification that proved the code worked without ever proving it reached
anyone. Item 48 was added the same date: "business_line is Anca's own term" was wrong — checked, and
the phrase traces to Mihai's own 2026-05-27 analysis and a 2026-07-15 mockup card, two weeks before
her feedback repeated it into a column the source file itself labels a summary, not a quote. Recorded
alongside item 35 and item 46 as the third instance this week of a sourced-sounding detail that
wasn't, all three caught only by checking. Item 49 was added the same date: a remembered
"delete-anything, restricted to Anca, typed-DELETE confirmation" requirement — the fourth instance
this week, checked against every doc, the full git history, every mockup variant, and the analysis
PDFs, found nowhere. Alongside it: Anca's actual permission state corrected (platform_owner and
sales_manager, not organization_owner; `is_platform_owner` false), the real scope of "any entry"
(30 tables, 2 with a delete policy, all 55 foreign keys NO ACTION), and a direct conflict with the
already-closed decision against hard-delete on `clients`. Item 50 was added and resolved the same
date: the actual cause of the three test-data purges was no reachable route into `wow-lab-test-b`
(Mihai's account single-org, no switcher, zero `legal_entities` there) — fixed, not just recorded,
by seeding two fictional legal entities and inviting a second, single-org account for him into the
test org, then verifying the full client → contract → group flow end to end under it. Item 51 was
added 2026-09-11: the `client_contacts` half of item 37's fix, left open on purpose pending Anca's
own answer, arrived — the same write-side finance exclusion removed the same way, verified live and
browser-tested end to end in `wow-lab-test-b` using item 50's own newly-unblocked path. Item 52 was
added the same date: Anca's planning-fields spec, principal/secondary PDF, and feedback-form
questions describe a one-off workshop as a first-class thing this schema doesn't model — it models
recurring clubs instead — mapped field by field against the live schema, recorded as a domain
question for Anca, not a column list, with no document found anywhere stating one-off-vs-recurring
volume to help judge which shape is the exception. Item 53 was added the same date: a trainers
screen would show almost nothing real (name, email, phone, role — nothing else); the mockup's own
version carries eight unbacked claims, one a false statement about a named person (Cătălina does
not hold a Trainer role); a stated premise about criteria-matrix visibility turned out to be my own
error, corrected against item 23 (the seventh instance this week of something asserted as recorded
that wasn't); and "ten of eleven trainers never signed in" was checked against `auth.users`, not
recorded as given — 8 of the 10 show a real sign-in timestamp, only 2 show none, though which of the
8 are genuine trainer logins versus this session's own testing cannot be fully separated with the
audit data this project retains. Item 21 got a 2026-09-11 addendum recording that limit precisely
where the derive-from-`last_sign_in_at` decision itself lives: `auth.audit_log_entries` is empty
project-wide, not just for one account, so the column still answers "has this account ever
authenticated" correctly but cannot answer "has this person used the app" — the decision stands,
the limit is now written down beside it. Item 54 was added the same date: the ten trainers'
invitations are all expired, left that way on purpose since nothing trainer-facing exists yet for a
resend to lead anywhere — resend when that screen ships, not before. Items 55-56 were added
2026-09-11: four more mockup screens claiming per-trainer filtering they don't perform, found while
investigating the trainer's own screen rather than the management directory, and five of the
trainer's six real capabilities with no route behind them at all. Item 57 was added and resolved the
same date: the sessions trainer-write policy this session itself shipped a day earlier
(`202609110003`) was a bare row match with no capability check — correct reasoning about a
*narrower* capability not existing was used to justify dropping the *existing, coarser* one
(`mywork.*`) that the sibling SELECT policy already paired with the same row match, leaving a
revoked trainer's write access to a session outstanding indefinitely. Found by re-reading the
shipped policy against its own sibling, not by the feature's own 5/5-passing assertion suite, which
tested every allowed case and none of the revoked-role one. Corrected by `202609110004`. Item 58 was
added the same date: three dependency advisories (`next`, `sharp`, `postcss`) found by `npm audit`,
`next`'s two RCE advisories patched (`15.5.23` → `15.5.24`, `develop` only as of that date — not yet
on `main`), the other two confirmed unreachable by this app's own code paths rather than left
unaddressed. Item 59 was added 2026-09-12: the first real create-a-group attempt on that `develop`
build, 22 hours after the upgrade, hit a platform-level 504 — confirmed live (zero rows) before
anything was retried, cause later identified as a cold function, unrelated to the upgrade. Recorded
for the failure shape, not the cold start: a raw "Gateway Timeout" in this app's own error banner is
never this app's own text, and its presence is itself the signal that a platform-level failure
reached the browser above this app's error handling entirely.

This register does not replace the SAD documents — several items below are
already tracked there in more depth, and this entry says so and points at the
section rather than duplicating it. Its job is to be the one place that lists
everything open, across domains, so nothing here has to be rediscovered.

Update this file as items close or new ones are confirmed. Don't add a
candidate item without checking it against the current code/DB first — that
is the entire reason this file exists instead of being a wishlist.

**`scripts/check_open_items_register.ts`** checks this file against itself and against the live
repo — every `item N above/below` cross-reference points the direction its target actually sits
in, every referenced item number has a matching `### N.` heading, and every cited migration/rollback
filename exists on disk (or is named in the script's own short exceptions list, for the rare case
where a cited file's absence is the point of the entry, not a staleness bug). Run by hand, same as
`scripts/check_operator_guide.ts` and for the same reason — no CI exists in this repo to run it
automatically. Run it after any pass that edits several items at once, the way this one did:

```
npx tsx scripts/check_open_items_register.ts
```

It does not and cannot check the harder kind of staleness item 71 below is about — a blocker
cleared by adjacent work leaves grammatically and structurally correct text behind; nothing short
of re-deriving the investigation catches that. It only catches the mechanical kind: a direction
word, a number, or a filename that no longer matches this file's own structure or the repo's own
state. **2026-09-18: fifteen real errors found and corrected across the pass that led to this
script existing** — nine found by hand, before this script existed (two in text written that same
session, seven left for a follow-up pass); one more found by hand while fixing those seven; five
more the script itself caught on its very first run, including one in text written earlier that
same day. The script's own share of that total — five, on one run, with zero setup beyond writing
it — is the concrete answer to whether this kind of thing is worth checking for: yes, cheaply, and
it does not have to be a repeat performance to find something real.

**`scripts/run_rls_suite.ts`** runs every file in `db/tests/` against the live linked database and
prints pass/fail per assertion, distinguishing a genuine sabotage-check pass (the check correctly
flips to false under a deliberately broken policy) from a real failure. Exits non-zero if anything
fails or errors — a broken suite cannot read as passing. **Run this after any migration that touches
`CREATE POLICY`/`DROP POLICY`/`ALTER POLICY`, or that renames or drops a column any policy or test
reads** — the exact two things that silently broke this suite on 2026-08-18 and 2026-08-21 (item 86
below), with nothing running it in between to notice:

```
npx tsx scripts/run_rls_suite.ts
```

**`scripts/check_deploy_status.ts`** polls GitHub's commit-status API for the real Vercel outcome of
a commit — `git push` succeeding only confirms the git operation, never the build. Exits 0 on
`success`, 1 on anything else including a timeout still `pending`. **Run this after any push meant to
reach `app.wowlab.ro`, before trusting any verification done there** — the exact gap that let main
fail to deploy for 25h8m unnoticed (item 94 below), during which every push in the window reported
success on its own terms:

```
npx tsx scripts/check_deploy_status.ts        # checks HEAD
npx tsx scripts/check_deploy_status.ts <sha>   # checks a specific commit
```

**`scripts/check_operator_guide.ts`** diffs the operator guide's manifest —
`docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md`, the procedure Anka and Cătălina actually
follow — against the live i18n dictionaries it names, so a button label or dropdown option that
changed in code surfaces as a claim the guide can no longer make. **Run this after any change to
`clients`/`contracts`/`groups` `i18n.ts`, `*-client.tsx` or `actions.ts`, and after any migration
that changes a vocabulary those screens render** — `delivery_format`, `module`, `client_type`,
`business_line`, `contract_type`:

```
npx tsx scripts/check_operator_guide.ts
```

**The migration half of that trigger is the half nothing named, and it is the half that cost three
weeks.** The guide carries its own maintenance obligation ("Obligație de întreținere"), kept
deliberately where it is — a second reminder behind the door costs nothing — but on its own it was
insufficient for two reasons, both real: it names **UI files only**, and it lives **inside the
document it protects**, so the only person it reaches is one already reading the guide.
`202609210006` replaced `delivery_format`'s six values with Anca's nine plus `custom`, the i18n edit
rode along in the same commit, and neither author had any reason to open the guide. For three weeks
it told the two people doing data entry to pick three formats that no longer existed (item 114
below). This block is the trigger moved in front of the actor, where the other three already were.

**What a green run does not mean, stated here so nobody reads 38/38 as "the guide is correct."** The
manifest holds only claims that are literal i18n strings, and it checks that a claim **matches** the
dictionary — not that the dictionary is right. Three things are outside it:

- **Behavioural claims and counts of what the database holds.** The same stale section carried one:
  *"cele 13 module"*, wrong since vet and wronger after anatomy, which **no trigger would have
  caught**, because no trigger can. The guide's three legal entities, named by hand in Pasul 2, are
  the same class.
- **Whether the Romanian is grammatical.** The 2026-10-12 session→workshop rename (item 120 below)
  broke **eleven** agreements — `atelier` is neuter where `ședință` and `sesiune` are feminine, so
  *"nicio atelier alocată"* and *"durata atelierei"* became wrong the instant the noun changed. This
  checker passed **38/38 before and after**, correctly: every claim still matched its string. A
  cross-language find-and-replace is safe in English, which has no gender, and unsafe in Romanian,
  and nothing in this repo's tooling knows the difference.
- **Whether a string that renders is a sentence worth reading.** Item 122 below is the live case: a
  message that interpolates a name renders "Unknown has no grade effective on this date" for a viewer
  who cannot read that name, and no dictionary check can see it.

So: this checker covers what can be checked mechanically, and **when a vocabulary changes, someone
still has to re-read the guide — and, if the change touched Romanian, read every changed string** —
see item 115 below for the full accounting of that bound.

---

## Readiness before invitation — Mihai's standing decision, 2026-10-27, above every item below

**Nobody is invited into this application in order to find out what is broken.** That is the
decision, stated once, permanently, and it outranks every item in this register: no item's
"blocked on nothing" or "ready to build" licenses sending a real person a sign-in link. A person's
first login is not a test environment — it is an account that will land wrong, read a lying
number, or get stuck, in front of someone whose job is not to debug this application.

**The threshold is finite and stated so it can be checked, not felt.** For ONE trainer, on their
own phone:

1. **They see their own workshops, without asking anyone where they are.**
2. **They confirm the correct one, without mis-tapping on the phone.**
3. **They can repair a mistake themselves — not through Operations.**
4. **Nothing on the screen states something false.**

Four conditions, each independently checkable against the live application by opening it and
trying. **The bar is not "everything is good."** It is narrower and it is the right bar:
**nothing on the screen lies, and nothing stops the person who is trying to do the right thing.**
A screen can be ugly, slow, or missing a feature and still clear this; a screen that shows a
number computed against the wrong assumption, or a control with no way back from a mistake, does
not — regardless of how much else works.

Every item in this register that touches a screen a trainer will actually open is read against
this threshold before it is read as "done." Items 159–164 are the ones that currently define it
in practice; a session resuming this work checks those four conditions against the live app
**before** treating any invitation date as real, no matter what the register's own narrative
elsewhere implies about timing.

---

## No scheduled execution mechanism — decided, not built now

**Decision, 2026-09-01: no scheduling mechanism is being built.** Nothing on this stack runs on a
timer, and nothing will until the trigger condition below fires. Confirmed live the same day as
this decision: `pg_cron` is **not enabled** but **is available** — `pg_available_extensions` lists
it (version 1.6.4, `installed_version` NULL) — and Supabase has already pre-wired the grant
plumbing for it (`extensions.grant_pg_cron_access()`, a dormant event trigger, not authored by this
project, that fires the moment the extension is created; the `cron` schema itself doesn't exist
yet). `vercel.json` is `{"framework": "nextjs"}` — no `crons` key, no `vercel.ts` either. No
`supabase/functions/` directory exists. No `.github` directory exists — no scheduled GitHub Action
either. Vercel Cron's actual plan entitlement on this project **could not be verified** — no CLI
auth available in this environment (`vercel whoami` → "Not authorized"); same specific gap already
recorded in item 16 below, for a different check. Not assumed either way.

**Only one requirement genuinely needs a clock: anonymizing stored personal data at 36 months**
(`docs/DATABASE_CONVENTIONS.md` §9). It mutates a row nobody asked it to change — overwriting a
real person's name has no read-time equivalent. **It cannot be built yet, independent of the
scheduling decision above:** `client_contacts` holds zero rows in production today; no per-child
table exists, by deliberate design (`docs/WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md`'s
numeric-first attendance model, `attendance_count` only); no `candidates` table exists at all
(recruitment is mockup/plan-stage only, `docs/phase1-development-plan.md` §3). There is no data to
anonymize and no confirmed row shape to write a job against yet — building the mechanism now would
mean building it blind.

**Everything else that looked temporal is read-time math, and two working precedents already exist
in this codebase.** `TermBar`/`getTermStatus()` (`app/(app)/contracts/term-bar.tsx`) computes
contract renewal pressure live from `period_end` and `now`, recomputed on every render, never
stored. The five payment-config resolvers (`app.resolve_*`,
`supabase/migrations/202608310002_payment_config_tables.sql`) resolve whichever version is valid
at a given date the same way, on every read. **Contract expiry stays derived, on purpose:**
`contracts.status` never needs to physically become `'expired'`, because nothing that asks "is this
contract still current" reads the stored column for that fact — the one place that shows renewal
pressure today (the `/contracts` overdue banner) already derives it live, matching `TermBar`'s own
math exactly so the two can never silently disagree.

**Separate note, not a scheduling gap — record this on its own:** the `contracts.status` CHECK
constraint permits `'expired'` and `'renewed'` as values, but **no code path in this application
ever writes either one.** `markContractSigned` (`app/(app)/contracts/actions.ts`) is the only place
`status` is written after creation, and it only ever writes `'signed'`. Confirmed live: zero
contracts anywhere carry `status = 'expired'` or `'renewed'` today. This is a dead branch in the
enum regardless of whether a scheduled job is ever built — even a job would need this write path
built first, and today it doesn't exist at all, manual or automatic.

**Trigger condition — when this reopens:** the first real personal-data row entering production,
which is the 14-school import. Not before.

**Noted 2026-09-21, not fired yet:** item 77 below built the first real feature that gives this
trigger an actual path to fire outside the 14-school import specifically — a one-off workshop's
on-site contact, linked to a real `client_contacts` row. `client_contacts` still holds zero rows in
production as of this note; building the feature doesn't fire this trigger, the first real
Operations use of it (linking a real contact for a real workshop) does. Re-check this item the day
that happens, from whichever direction it happens first.

**Prerequisite to decide at that reopening, not now:** a scheduled write has no JWT to read, by
construction, so `row_history` would record `actor_user_id = NULL` for it. Confirmed empirically
this session, not inferred: every one of the 24 rows deleted by this session's own service-role
purge scripts (`scripts/purge_tier1_seed_data.ts`, `scripts/purge_tier2_seed_data.ts`) recorded
`actor_user_id = NULL` in `row_history`, with zero exceptions across all six affected tables.
**The `202608260001` fix cannot solve this** — that fix corrected `row_history_capture()` reading a
GUC nothing ever set; a scheduled job (`pg_cron` running as `postgres`, or a service-role-
authenticated write from anywhere else) has no `request.jwt.claims` at all for `auth.uid()` to
read, no matter how the trigger is written. Giving a job a resolvable, non-null attribution would
need a system-actor identity in `public.users` to point `actor_user_id` at — **no such concept
exists anywhere in this schema today** (checked: zero matches for
`system_user`/`automation_user`/`service_account`/anything similar). Not designed here — flagged so
it gets decided deliberately when the anonymization job is actually built, not discovered as a
surprise gap after the fact.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §9; `docs/mockup/wow_lab_os_mockup.html` line 1109
(corrected this pass — the two false badges now read "planned," `b-slate`, not "on," `b-teal`);
`supabase/migrations/202609010001_correct_client_contacts_retention_comment.sql` (corrects the one
live `COMMENT ON` that carried the false claim — `202608270001`'s equivalent claim is entirely
inside `--` file comments, never reached the database, left as-is, applied migration file
unedited); `app/(app)/contracts/term-bar.tsx`; `app/(app)/contracts/actions.ts`
(`markContractSigned`); `supabase/migrations/202608260001_fix_row_history_actor_user_id.sql`; item
16 below (Vercel plan, same unverifiable-in-this-environment gap).

---

## Seed data cannot be reliably distinguished from real data — RESOLVED

**Resolved 2026-09-01, by removal, not by marking.** This entry originally described 24 rows in
`wow-lab` with no reliable seed-vs-real signal: 5 demo clients, their 5 demo contracts and 1 client
contact, the 4 Cambridge groups and their 6 sessions, the Maxdigital client and its 1 contract, and
1 test supplier row. All 24 were purged, across two dependency-ordered tiers: **Tier 1, 13 rows**
(1 supplier, 6 sessions, 4 groups, the Maxdigital contract, the Maxdigital client — commit
`4ba0a65`) and **Tier 2, 11 rows** (the 5 demo contracts, 1 client contact, the 5 demo clients —
commit `2f609b6`). A full pre-delete backup — every column, all 24 rows — lives at
`scripts/purge_backup_2026-09-01.json`; the investigation, evidence, and dependency-order reasoning
that preceded execution lives at `docs/WOWLAB_Purge_Plan_Seed_Data.md`. Every deletion is
independently confirmed captured in `row_history` (`old_values` populated, exactly one entry per
row, verified by fresh query against the live database, not the deletion scripts' own output) —
the rows are gone from the live tables, not from the record.

**No structural marker was added, and none is needed while production holds no seed rows.** The
original framing of this entry treated the missing marker as the gap to close. It wasn't — the gap
was that verification work ran against the production `wow-lab` org at all. The rule that replaces
the marker: verification runs in `wow-lab-test-b`, which already exists, already carries
`organizations.is_test = true`, and was confirmed this session to be fully isolated from `wow-lab`
— zero rows in any business table, no user shared between the two orgs, no FK or other reference
from either org into the other. The 24 purged rows entered production because verification
happened in the production org, not because a column was missing to mark them once they did.

**Standing caution, recorded once here rather than as three separate bugs.** Three fields were read
as evidence during this investigation and none of them meant what they appeared to mean: the
`contracts.notes` "Example seed record" string (`isDemoRecord()`'s only signal — a plain,
uncapability-gated, editable text field, not a structural marker), `users.is_test_account` (set
once by one migration's static backfill list, never revisited — item 18 below already found it
missing the `maxdigitalro+*` accounts it exists to catch), and `users.status` (see item 21 below —
stored at creation, never updated after, doesn't mean what "invited" vs "active" implies it means).
All three share the same shape: written once, at creation time, by a migration or a one-time
script, never maintained afterward, and easy to mistake for a live, enforced signal because they
look like one. Read any of these three fields, anywhere they show up again, as "what a migration or
script wrote once" — not as current state.

**Lives in:** `docs/WOWLAB_Purge_Plan_Seed_Data.md`; `scripts/purge_backup_2026-09-01.json`;
commits `4ba0a65` (Tier 1), `2f609b6` (Tier 2).

---

## Contracts past `period_end` stay `signed`

**What it is:** confirmed live, 4 of the 5 signed contracts in production today are already past
their `period_end` — all four `2025-09-01 → 2026-06-30` school-year contracts, each 57 days
overdue as of this check. None has moved to `expired` or `renewed`. Re-checked fresh rather than
reused from the dashboard-inventory pass earlier this session, per this file's own rule.

**Correction, checked when asked to confirm these were real before shipping a banner on them:**
all four are seed data, not real contracts. `notes` on all four literally reads "Example seed
record — see migration header, not a verified real contract," all four created in the same batch
(`created_at = 2026-08-10 15:00:25`, identical to the second). **There are zero real overdue
contracts in production today.** The architectural finding below (no mechanism exists to catch
this when it does happen for real) stands regardless — that's a fact about the code, not about
today's data — but the count itself was never a real business problem to act on, and the banner
built from it (`feat: surface overdue contracts on the contracts list`) was corrected in the same
round to exclude demo-flagged rows (`isDemoRecord()`, the same helper already used for the "Demo
data" badge on this page) before it reached a real viewer's attention as a false actionable
finding. Only `Maxdigital` (created `2026-08-13`, this session's own real verification work) is a
real signed contract today, and it isn't overdue or critical.

**Both halves of why, recorded separately on purpose:**
1. **The missing mechanism.** No scheduled job exists to notice a contract's term ended and act on
   it — this is a direct symptom of "No scheduled execution mechanism — decided, not built now"
   above, not an independent gap. Nothing in this codebase currently runs "for every signed
   contract where `period_end < today`, do X," and per that entry's decision, nothing will until
   its trigger condition (the 14-school import) fires.
2. **The design question, decided as part of that same 2026-09-01 decision: derived, not
   stored.** `expired` stays a **derived-on-read** state — every reader computes
   `is_expired = status = 'signed' AND period_end < today` at query time, the same way `TermBar`
   already computes `isPast`, and `contracts.status` itself never changes until a human acts. This
   was chosen specifically *because* no scheduled write mechanism exists or is being built — a
   stored status would need one. Residual consequence, still true and still worth stating plainly:
   `contracts.status = 'signed'` alone is **not** sufficient to answer "is this contract still
   current" anywhere it's checked (RLS policies, the dashboard, `contracts-client.tsx`'s own status
   badge) — every one of those has to derive it the same way `TermBar` does, not trust the column.

**Confirmed not caught by the existing render logic:** `TermBar`'s `isRenewalCritical` requires
`!isPast` — an already-ended contract renders in muted gray ("ended N months ago"), not flagged.
The dashboard inventory (this session) found 0 contracts in `TermBar`'s own "critical" 85% window
and 4 past end entirely — the existing UI's one piece of renewal-pressure signal doesn't surface
the more urgent bucket at all today.

**Blocked on:** nothing left to decide for this half — derived-on-read is the decision. Still
blocked on the scheduling entry's own trigger condition for the unrelated "notice and act on it"
mechanism (e.g. a future notification), if that's ever wanted.
**Lives in:** `app/(app)/contracts/term-bar.tsx` (`isRenewalCritical`, `isPast`);
`app/(app)/contracts/actions.ts` (`markContractSigned` — the only place `status` is written after
creation, per item 8 below).

---

## Migration history was missing 3 applied migrations — RESOLVED

**Found while correcting the false retention claim above, not by going looking for it.**
Applying `202609010001` (the `client_contacts` comment fix) via `supabase db push --linked`
failed — not on that migration, but on `202608310001`, with `column "location_tier" of relation
"sessions" already exists (SQLSTATE 42701)`. Investigated before repairing anything: `supabase
migration list --linked` showed `202608310001` and `202608310002` present as files with **no
remote entry at all** — `"remote":""`. Confirmed live, both directions, that these were the only
two: `supabase_migrations.schema_migrations` held 54 rows against 57 files, and the diff was clean
in the direction that would have been more alarming (zero recorded entries with no matching file —
nothing was ever silently deleted from the migrations directory after being applied).

**Confirmed these had actually run, not merely gone missing from history — a materially different,
lower-severity problem.** Checked every object each migration should have created, live: both
`sessions.location_tier`/`language_group` columns and their `CHECK` constraints existed exactly as
`202608310001` specifies; all 11 payment-config tables and all 6 `app.resolve_*` functions existed
exactly as `202608310002` specifies. Both had clearly been applied through some path other than
`db push` in an earlier session — there is no audit trail for schema DDL the way `row_history`
tracks row-level DML, so which exact mechanism (most likely an ad-hoc `supabase db query --linked
--file` run, the same shape as what happened with `202609010001` below) cannot be proven after the
fact, only inferred as the most likely explanation given the pattern.

**`db push` was unusable for anything, for anyone, while this lasted — not a narrow gap.**
`db push` always applies the oldest not-yet-recorded migration first. With `202608310001` stuck at
the front of that list, **every** `db push`, regardless of what it was actually meant to deliver,
would hit the same `42701` error and abort before reaching anything else — reproduced directly, not
inferred. This included the project's own documented disaster-recovery mechanism: §6.2 of
`docs/WOWLAB_SAD_Field_Masking.md` describes rolling back a migration by copying its rollback file
from `supabase/rollbacks/` into `supabase/migrations/` under a new timestamp and running `db push`.
A rollback copied in today would sort *after* the three stuck entries — the push would still die on
`202608310001` first, and the actual rollback would never be reached. **The documented recovery
path was non-functional for as long as this gap existed**, confirmed by walking through exactly
what would have happened, not assumed.

**`202609010001` was applied through `db query --linked --file`, not `db push` — the exact ad-hoc-
SQL-on-production pattern §6.4 of the same document warns against, forced by this gap rather than
chosen.** §6.4's own stated reason: a direct `db query` connection carries no `auth.uid()`, so
writes through it land in `row_history` with `actor_user_id: null` — unattributed, which the
document calls a compliance concern for a platform that will hold data about children. Checked
precisely for this specific instance: `COMMENT ON TABLE` is DDL against `pg_description`, not row-
level DML, so it never fires a `row_history` trigger at all — this particular workaround left no
unattributed audit row behind. That is incidental to *this* statement, not a property of the
workaround itself: had `db push` still been broken when a real data-writing migration needed to
ship, the same forced detour through `db query` would have produced exactly the `actor_user_id:
null` rows §6.4 warns about, on whichever table that migration touched.

**Repair:** `supabase migration repair --status applied <version> --linked` for all three versions
— the CLI's purpose-built mechanism for this exact state, confirmed via `--help` to update only the
history bookkeeping, execute no SQL. Verified independently after running it, not from the
command's own output: `schema_migrations` holds 57 rows matching the 57 files exactly, both
directions; `db push --dry-run` reports "Remote database is up to date"; all three objects
(`sessions` columns/constraints, all 11 payment-config tables, the `client_contacts` comment)
spot-checked byte-identical to before the repair — pure bookkeeping, no schema mutation, as the
mechanism promises.

**Recovery path proven end-to-end, not just declared fixed.** A throwaway migration
(`202609010002`, a single empty table, `public._migration_history_recovery_drill`) was pushed for
real — landed and recorded, confirmed by fresh query, not `db push`'s own success message. Then
rolled back through §6.2's documented procedure exactly: its rollback file, already sitting in
`supabase/rollbacks/`, was copied into `supabase/migrations/` under a new timestamp
(`202609010003`), pushed, and the copy removed from `supabase/migrations/` once applied (the
original in `supabase/rollbacks/` was never touched, so it stays reusable under a stable name —
equivalent in effect to §6.2's literal "move it back," cleaner in practice since nothing has to be
renamed back afterward). Confirmed after: the table is gone, and both `202609010002` and
`202609010003` are recorded in `schema_migrations`.

**§6.2's own documented procedure is missing its actual last step — found only by executing it for
real, apparently for the first time.** Its text ends at "run `db push`, then move it back into
`supabase/rollbacks/`." Doing exactly that left `db push --dry-run` broken again, immediately: the
remote history still had a permanent row for `202609010003` (the rollback, once pushed, is a real
applied migration and stays in history forever — rollbacks aren't undone from `schema_migrations`,
they're recorded as their own forward entry), but the file was gone from
`supabase/migrations/` per that same "move it back" instruction. `db push --dry-run` immediately
reported `Remote migration versions not found in local migrations directory` and named the exact
fix itself: `supabase migration repair --status reverted 202609010003`. Confirmed the table has no
`status` column (`version`, `name`, `statements` only) — `--status reverted` works by removing the
row entirely, the only way "not applied" can be represented in a table where presence is the only
signal. Ran it, verified independently after: the `202609010003` row is gone, `schema_migrations`
holds 58 rows (57 original + the permanent `202609010002` create) matching 58 files exactly, and
`db push --dry-run` reports "Remote database is up to date" again. **This is very likely the first
time this project's rollback procedure has ever been executed for real** — every other file in
`supabase/rollbacks/` looks like a written-but-never-invoked safety net — which is exactly why this
gap in the procedure's own text had never surfaced before.

**§6.2 does need amending, one sentence: its "move it back" step should say to also run `supabase
migration repair --status reverted <new-timestamp>` immediately after**, or the next `db push` for
any reason breaks again the same way this whole investigation started. Separately, a smaller,
genuinely cosmetic wrinkle: the copied rollback file's internal header comment still names its
original filename after being pushed under a different timestamp — §6.2 only instructs changing
the filename on copy, not editing content, so this is an expected byproduct, not a deviation;
worth a one-line note but not load-bearing the way the missing repair step is.

**Final state, confirmed independently after the extra repair, not assumed:** `schema_migrations`
holds 58 rows matching 58 files exactly, both directions; `db push --dry-run` reports "Remote
database is up to date"; the drill table is gone. Both `db push` and the §6.2 rollback procedure
are genuinely working now — proven by running the full cycle twice in effect, once naively per the
written text and once with the fix the drill itself surfaced.

**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §6.2, §6.4; `supabase/migrations/202609010002_migration_history_recovery_drill.sql`; `supabase/rollbacks/202609010002_migration_history_recovery_drill_rollback.sql`; `supabase_migrations.schema_migrations` (live, not file-tracked).

---

## Questions waiting on Anca — the batch, in one place

Every open question that only she can answer, collected here because until 2026-10-12 they existed
only as `**Blocked on:** Anca` lines scattered across the file, findable by grep and by nothing else.
**This section holds the questions; the items hold the reasoning.** Each one is phrased as it would
be sent to her — in Romanian, in her own vocabulary, without schema words — because a question
translated into column names comes back answering something else.

Added, closed or re-asked here as items move. Nothing goes in without an item number beside it.

---

**1. Orele de administrare și entitatea juridică** — item 112 below. **ANSWERED 2026-10-12: persoana
alege entitatea de fiecare dată, iar Financiar se alege ca oricare alta.** Kept with its question
text, because the answer retired four pieces of design and the question is why they were never
built.

> Ai spus că fiecare oră lucrată se atribuie unei entități, în funcție de proiect și de contractul cu
> clientul. Dar cele trei categorii ale tale nu se comportă la fel: **Ateliere** se leagă clar de un
> proiect; **Admin** uneori da, uneori nu; **Financiar** e contabilitate pentru toate trei
> deodată.
>
> Deci: vrei ca fiecare oră de administrare să poarte un proiect, din care rezultă entitatea — sau
> vrei ca persoana să aleagă entitatea de fiecare dată când își trece orele?
>
> Și, oricare dintre cele două: la **Financiar**, ce se alege?

Why it could not be guessed, in hindsight more than in prospect: the two answers are different
screens, and **the one she chose is the one that needs less** — no project reference, no second
resolver, no default for business-wide work. Guessing would plausibly have produced the
project-derived shape and all three.

---

**2. Tarifele Cătălinei pe categorii** — item 130 below. **ANSWERED 2026-10-12: doar Admin. Nu face
Ateliere sau Financiar**, deci absența celor două tarife e corectă, nu o lipsă.

> Cătălina are un tarif de administrare doar pentru **Admin** (72 net / 79.92 facturat). Pentru
> **Ateliere** și **Financiar** nu are niciun tarif.
>
> Ar trebui să aibă și pentru acestea două, sau pur și simplu nu face acel tip de muncă?

Why it was asked rather than filled in: she does not do that work, so the absence is correct and the
resolver raising on it is the right behaviour. Copying 79.92 across would have invented two rates
nobody agreed — the exact outcome asking avoided.

---

**3. Notițele de pe grupă** — item 116 below. **CLOSED 2026-10-12** — she confirmed the current
behaviour: an allocated trainer reads them. Kept here so the batch shows what was asked and
answered, not only what is outstanding.

---

**9. Munca Ralucăi Margean — intră în aplicație sau nu?** — item 73 below. *New 2026-10-12.*

> Raluca nu lucrează pe ore. E plătită pe articol și pe newsletter, prin drepturi de autor, nu pe
> factură. Ecranul de ore nu are cum să o cuprindă.
>
> Vrei ca munca ei să intre în aplicație — cineva înregistrează fiecare articol cu numărul de
> cuvinte, și tariful rezultă din asta — sau rămâne în afară, așa cum e și sistemul celor care scriu
> planurile de lecție?

Why it is hers to answer: it decides whether a second table exists at all. `admin_hours` cannot hold
her work, and `admin_rates` already splits her into `per_article`/`per_newsletter` rows because her
unit is not an hour. **Context worth sending with it:** her July request grouped Raluca with Anka
and Laura as *"echipa admin-only"*, and that grouping has now turned out wrong for the second time —
item 22 below records the first, where the same grouping was the evidence that correctly refuted
calling her a trainer.

---

**4. Grila de evaluare a performanței** — item 23 below. Six points with no confirmed design.

**5. Cele cinci sume rămase din grile** — item 20 below.

**6. Validarea experimentelor: stările** — item 117 below. Whether `changes_requested` is a state
she wants, and whether `/my-work` becomes the trainer's landing page. Mihai's call as much as hers.

**7. Cifrele din august, reconfirmate** — item 86 below.

**8. Fluxul, verificat contra schemei reale** — item 52 below.

---

## Threads not started

### 1. CEO dashboard

No `/dashboard` route exists — `app/(app)` has only `admin`, `clients`,
`contracts`, `groups`, `profile`. `/profile` is confirmed live as the
post-login landing spot: `app/auth/callback/route.ts` defaults the `next`
redirect param to `/profile`, with its own comment calling this "S2's
diagnostic landing spot... Phase 1 will change this once there's a real
post-login destination."

There is no separate "analysis doc" for this — the flow is described inside
`docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §5 and §7: a diagram
showing `contract → groups → sessions/attendance → cod facturare → factura
fiscală (SmartBill/SAGA) → balanță lunară → Dashboard CEO`. That diagram
places the monthly balance and the CEO dashboard **downstream of and outside
SmartBill/SAGA**, not something this schema produces directly. §8 confirms
the fiscal invoice itself is explicitly out of scope for V1 ("rămâne în
SmartBill/SAGA").

What's actually computable from the current schema: contract counts and
values (`estimated_value`, `previous_year_value`, `billing_rule`) grouped by
status, client type, or legal entity, for a session that holds the unmask
capability. What is **not** computable at all: profit margins. There is no
cost data anywhere in the schema — no trainer-payment table, no supplier-cost
table, nothing under `cost`/`payment`/`invoice` in `information_schema.tables`
except `contracts_billing_masked` itself. A margin needs a cost side that
doesn't exist yet.

**The trap, confirmed structurally:** `contracts_billing_masked` (see
`app.masked_contract_financials()`) returns `NULL` for `billing_rule`/
`estimated_value`/`previous_year_value` when the caller lacks the unmask
capability — not an error. Separately, the base `contracts` SELECT policy
splits `finance.operations.*` (sees only `private_school`/`parent_b2c`
contracts) from `finance.reporting.*` (sees everything else) — confirmed live
via `pg_policies`. A `SUM(estimated_value)` run under either single finance
role's session will silently total only that role's client-type segment, or
return `NULL` if the caller has no unmask capability at all — no error either
way, no indication anything was excluded, and a syntactically identical query
returns a different, equally plausible-looking number depending entirely on
who runs it. Anyone building a dashboard has to run it as a role that clears
both filters (platform owner or `org.settings.manage`, confirmed to bypass
the client-type split), or aggregate the two segments explicitly and add
them.

**Blocked on:** no cost/payment data model exists; the true "monthly balance"
lives in SmartBill/SAGA, outside this platform's data.
**Lives in:** `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §5, §7, §8;
`app/(app)/contracts/[id]/page.tsx` for the existing masked-read pattern to
reuse; `app/auth/callback/route.ts` for the current landing-page default.

**Decision (this session): investigated, not built.** A follow-up block
proposal identified two candidate blocks that would show a genuinely new,
non-redundant, honest-for-every-viewer number: contract health (overdue +
renewal-pressure counts) and pending invites. Both were checked against a
capability-shape inventory of all 14 roles and a redundancy check against
existing pages. The conclusion: a dashboard page carrying one real block and
five empty states (for the roles whose domains — curriculum, evaluations,
inventory, community, candidates — this page has nothing for) is worse than
no page. **No `/dashboard` route was built.** Instead:
- **Contract health shipped as a banner on `/contracts`** — `feat: surface
  overdue contracts on the contracts list`. It's where someone can act on
  the number, needs no new route, no empty states, and no role matrix.
  Corrected in the same round, before this reached a real viewer: the count
  must exclude `isDemoRecord()` rows — checked when asked to confirm the
  banner's own numbers were real, and they weren't (see "Contracts past
  `period_end` stay `signed`" above). See
  `app/(app)/contracts/contracts-client.tsx` and the `getTermStatus` export
  now shared with `TermBar` in `app/(app)/contracts/term-bar.tsx`.
- **Pending invites was cut**, not shipped — see its own note directly
  below.

**Do not treat the absence of a nav entry as the reason this doesn't
exist.** There never was one — `app/(app)/layout.tsx`'s nav groups have no
"Dashboard" entry today, before or after this decision, so a future reader
finding no nav link should not read that as evidence of a removed feature.
The absence is this recorded decision, not a silent deprecation.

**Re-verify when:** attendance data, `groups.children_billed`/
`children_confirmed`, or a second finance-visible aggregate exist for real —
any of those would give a redundancy-checked block something non-redundant
to show, which is the reason nothing beyond the banner shipped this round.

**Related, separately fixed:** `app/page.tsx` (the root `/` route) used to
render a stale S0/S1 placeholder — factually wrong (it claimed the real app
shell "lands in S3"; S3 shipped) and carried the one ungated `Link` in the
whole app (to `/admin/users`, no capability check). Replaced with a plain
redirect to `/profile`, the actual landing surface. **That redirect target
is correct only as long as `/profile` remains the landing surface** — if a
dashboard is ever built per this item, `/` should redirect there instead,
not to `/profile`. This note and this item are the same decision from two
directions; check both if either changes.

### 64. A status screen for owners, proposed again — declined again, same precedent

2026-09-16. The payroll walkthrough fixes this round surfaced two more domains that looked
incomplete to an outside eye — payment configuration's empty grids, trainers' unrouted
capabilities — and raised the same question this item's own August entry already answered: does
any of this belong on a dedicated status screen for owners. Re-asked deliberately rather than
assumed still-settled, since the two candidates are new. Answer: still no, on the same reasoning,
plus one more piece of evidence this project already had lying around.

**Second piece of evidence, independent of item 1's own investigation:** `docs/progress.md`'s
"Snapshot status" table (lines 18-36) is exactly the artifact a status screen would become. It
exists to summarize this project's state across domains at a glance — the same job a status
screen would do — and its own author's note directly above it (line 8) already warns readers away
from it: *"tabelul „Snapshot status" de mai jos (rămas ca istoric WS-B, nu mai e actualizat)"* —
kept as WS-B history, no longer updated. Its own rows haven't caught up either: line 36 still
marks WS-D "🔶 în curs (D0 done, D1 next)" though WS-D, all of Phase 0, and all of Phase 1 have
long since shipped. Nobody's job was ever to keep that table current once writing it stopped being
the active task — the exact failure mode item 1's investigated-and-rejected dashboard predicted in
the abstract, now visible as a concrete two-month-old artifact instead of a hypothetical one.

**Candidate (a), payment configuration — checked, cleared the bar, shipped.** "Five of six grids
empty" (item 20) is real and derivable live: a plain `count(*)` per version table. Confirmed
unchanged today, both orgs — `WOW LAB` (production) and `WOW LAB Test Org B` each hold zero rows
across all five grids that have a section on `/payment-config` (`trainer_grade_versions`,
`location_bonus_versions`, `language_bonus_versions`, `duration_multiplier_versions`,
`contract_type_uplift_versions`; the sixth grid, `lesson_plan_rate_versions`, is seeded per item 20
and has no section on this page at all, so it's outside what a page-scoped banner here could
sensibly reference). Non-redundant: before this, noticing the state required opening all five
sections one at a time — each already says "No version exists yet." individually (item 20), but
nothing summarized that at a glance. Actionable: Finance/Anca can now see in one place exactly
which grids still need real numbers, which matters now specifically because payroll math will
depend on them once they're filled in.

Shipped as a banner at the top of `/payment-config`, same shape as the overdue-contracts banner
item 1 already produced: absent entirely when nothing is missing (not a suppressed, empty version
of the same colored box — computed from the same `versions` arrays the five sections already
render from, no new query), present and naming every missing grid by its own section title when at
least one is. Confirmed live in `wow-lab-test-b` as `test+ui-contract-admin-b@wowlab.dev`
(`finance_operations`): renders "5 of 5 grids below have no version yet" listing all five by name,
matching the live count exactly.

**Candidate (b), trainers — argued, not just accepted, and still declined.** Item 56's finding (five
of six trainer capabilities have no consuming route) is a fact about what this codebase has and
hasn't built, not about any data condition that changes while the app runs. Two reasons that's
disqualifying on its own, not merely "matches my reading":

1. **It only changes at deploy time.** Nothing an owner or a trainer does in the app moves this
   number — it moves only when a developer ships a new route, which is a code event the register
   (this file) already tracks. A screen that re-displays a fact whose only trigger is "someone
   shipped code" is reporting on the codebase to people who read it through the codebase's own
   commits and this file already, not a live signal for someone using the app.
2. **No page already owns this fact.** `/contracts` owning contract health, and now
   `/payment-config` owning its own grids' completeness, both work because the signal lives on the
   page whose data it's actually about. There is no trainers-facing screen at all yet (item 53/54)
   for this to attach to — building one just to show "five things aren't built yet" would be item
   1's exact one-real-block-plus-empty-states shape, relocated from an owner's dashboard to a
   trainer's screen instead of avoided.

Stays exactly where item 56 already filed it: the register, not the app. Not built.

**Survey of every other domain for a signal clearing the same bar (real, derivable live,
non-redundant, actionable) — done deliberately without inventing one to fill the shape, since
that was the explicit risk to avoid.** `clients` and `suppliers` were both checked against their
own create-table migrations: neither carries a date/term field a signal could be computed from —
only a `status` enum, no equivalent of `contracts.period_end` to be overdue against. Pending
invites was already investigated and correctly cut for its own, different reason (item 18: the
count is test residue, not signal) — not resurrected here. The one domain that does clear the bar
today is `/payroll`'s own unconfirmed-sessions-before-close summary — real, live, non-redundant,
and directly actionable (Anca can chase a confirmation before it's too late to matter) — but it
was already required and built in this same round for its own reasons, not found by this survey,
so it's noted here rather than claimed as a new result of it.

**What shipped from this round: one banner, on the one page it belongs to.** Nothing else — the
conclusion drawn from the survey above is that most domains still have nothing worth saying, same
as item 1 originally found.

**Lives in:** item 1 above (the precedent this revisits); item 18 (pending invites, still
correctly cut); item 20 (payment-config grid state, re-confirmed unchanged here); item 56 (trainers'
unrouted capabilities, the reasoning for why it stays out of the app); `docs/progress.md` lines
6-8, 18-36 (the stale Snapshot status table and its own author's warning about it);
`app/(app)/payment-config/payment-config-client.tsx`, `app/(app)/payment-config/i18n.ts` (the
banner itself).

---

### 65. The payroll summary can show "Unknown" for a client name, for a structural reason distinct from the walkthrough's trainer-name gap — found while building, not fixed the same way, currently inert

Building the pre-close payroll summary (naming each unconfirmed session, per the payroll
walkthrough findings below) requires joining `sessions → groups → clients` to label a session by
its client. Checked `clients`' own SELECT policy before assuming this would just work, given the
same round's trainer-name fix (see the payroll walkthrough entry below) was exactly this shape of
bug: `clients` splits `finance.operations.*` (sees only `private_school`/`parent_b2c`) from
`finance.reporting.*` (sees the rest) — the same deliberate segregation already known from
`contracts` (SAD §6, "record-level RLS segregates finance_operations... from
finance_admin_reporting"). A `finance.operations.*`-only closer (Laura's capability set, per item
20) would see "Unknown" for any session's client outside those two types, even though
`sessions.read`/`org.settings.manage` already gives payroll-closing roles full org-wide session
visibility — the same shape as the trainer-name gap, a join that outruns what the joined table's
own RLS grants the viewer.

**Deliberately not fixed the way the trainer-name gap was.** That gap was a plain oversight on
`users` — no capability implied any name visibility at all. This one intersects a *documented,
deliberate* business boundary: which finance role bills which client segment. Whether
payroll-closing should see every client's name regardless of billing segment is a real policy
question, not a bug to silently patch by grafting on another RLS branch — unlike the trainer-name
fix, widening this one isn't obviously safe by the same "still narrower than everyone" reasoning.

**Why not fixed now regardless: currently inert.** `sessions` holds zero rows in the real `WOW LAB`
org today (confirmed live, matches item 53's own finding) — no client-type mix exists yet for this
to bite on. The summary degrades the same way every other name-lookup miss in this app already
does: falls back to "Unknown" per session, not an error.

~~**Blocked on:** a decision on whether payroll-closing needs cross-segment client visibility, or
should stay scoped to whoever already holds `finance.reporting.*` too (sidestepping the question
by construction) -- not a technical blocker.~~
~~**Re-verify when:** real sessions exist across more than one client-type segment and someone holding
only `finance.operations.*` is the one closing payroll.~~
**Both struck 2026-10-12 and replaced at the end of this entry** — the question they state is
broader than the facts support, and they rest on this entry naming the wrong person.

**VERIFIED AND NARROWED 2026-10-12, against the live policies rather than the role names — see item
110 below for the full round this came from.** Anca's correction: **Anka closes the month, not
Laura.** This entry named Laura.

- **Who reaches `/payroll` today:** exactly three accounts. The gate is `finance.operations.*` **OR**
  `org.settings.manage` (`payroll/page.tsx`, matching `closePayrollPeriod`'s own gate) — **Anka**,
  **Laura Moale**, **Mihai**. Nobody else holds either; Cătălina's `operations_manager` set carries
  no finance capability at all.
- **The segment this entry describes is the other one.** `finance.operations.*` sees
  **`private_school` + `parent_b2c`** — *not* corporate and grants. So a private-school client reads
  as its name to that holder, and it is **corporate and grant** clients that read `Unknown`. Easy to
  get backwards, and worth stating in the direction the policy is written.
- **Anka cannot hit this at all.** She holds **both** `finance.operations.*` and
  `finance.reporting.*`, and the two branches are exact complements (`client_type = ANY (...)` /
  `client_type <> ALL (...)`), so together they cover every client type. Her `clients.read` is
  neutralised by that branch's own `not finance.operations.* and not finance.reporting.*` guard and
  it makes no difference. **The one person who actually closes the month is the one person who can
  never see "Unknown".** The "sidestep by construction" option this entry proposed is therefore
  already the live state for the only closer there is.
- **Laura is the whole exposure, and the only account in that state:** `finance.operations.*` with no
  `finance.reporting.*`.
- **Still inert, now for two reasons instead of one.** This entry's reason (zero sessions in
  `wow-lab`) still holds, and additionally **all four real `wow-lab` clients are `private_school`**,
  which Laura can see. The three sessions that do exist are in Test Org B on a `corporate` client —
  the exact mix that would trigger it, in the one org where it does not matter.

**CLOSED 2026-10-12 — ACCEPTED, not resolved.** Anca: not a concern. Her reasoning is the
measurement above, reached independently — **Anka closes the month and holds both finance branches,
so it cannot arise.** Nothing is built and nothing changes; the `"Unknown"` fallback stays as it is.

**The distinction between accepted and resolved is why this entry is not deleted.** The defect is
still in the code: a `finance.operations.*`-only viewer still reads `"Unknown"` for a client outside
`private_school`/`parent_b2c`. What makes it a non-concern is **who holds which capability today** —
four role assignments — and not any property of the join, the policy, or the fallback. That is the
weakest kind of guarantee this project has: nothing in the schema enforces it, no constraint would
fail if it changed, and `/payroll`'s own gate (`finance.operations.*` OR `org.settings.manage`)
admits exactly the state that reopens it.

**Reopens if:** **someone holding only `finance.operations.*` becomes the person who closes the
month.** Today that is Laura Moale and only Laura — she already reaches `/payroll` and already lacks
`finance.reporting.*`, so the reopen condition is one change of habit away, not one change of
schema. It would also reopen on a new account provisioned with `finance_operations` alone, which is
how Laura got there.
**Blocked on:** nothing — closed as accepted.
**Re-verify when:** the reopen condition above fires, i.e. before any month-close performed by
anyone other than Anka or Mihai.
**Lives in:** the payroll walkthrough fixes entry below (the trainer-name gap this parallels);
item 20 (Laura's `finance.operations.*`-only capability set); item 110 below (the 2026-10-12
verification that narrowed this, with the capability tables); `app/(app)/payroll/page.tsx` (the gate,
the join, and the `"Unknown"` fallback); the `clients` table's own SELECT policy (its client-type
segregation branch).

---

### 66. A trainer's own group detail page showed the raw client UUID, not the name — RESOLVED 2026-09-17, a scoped `mywork.*` branch added to `clients`

Re-walking the payroll fixes as a trainer fixture (`maxdigitalro+trainerb1@gmail.com`) surfaced
this live: `/groups/[id]`'s header and its "Client" row both read
`78e6b320-ed9e-46d2-9d84-f3fed73abfc3` instead of the client's name, for a session the trainer is
legitimately assigned to and allowed to view. Confirmed pre-existing, not a regression from that
round's edits -- `git diff` on `app/(app)/groups/[id]/page.tsx` showed the one line responsible,
`const clientName = clientRow?.name ?? group.client_id;`, untouched by any of the five fixes.

**Root cause, checked against `clients`' own SELECT policy (item 65 above quotes the same
policy):** `is_platform_owner() OR org.settings.manage OR (clients.read AND not
finance.operations.* AND not finance.reporting.*) OR (finance.operations.* AND client_type in
(...)) OR (finance.reporting.* AND client_type not in (...))`. No branch admitted `mywork.*` at all
-- a `trainer`/`senior_trainer` viewer could not see any row in `clients`, ever, regardless of
whether they were allocated to a session for that client. `clientRow` came back `null`, and the
existing fallback silently printed the id instead of erroring or saying "Unknown." This was RLS
correctly refusing, not a display bug on its own -- `clients`' finance segregation was doing
exactly what it was built to do; it had just never been asked to cover the trainer's own screen.
The display code compounded it by treating a null lookup as "print the id," which is the part that
was a bug regardless of the access answer.

**Decision, argued, not just accepted: a trainer should see the name.** A trainer delivering a
session already knows which client (school/venue) they're at -- withholding the name protects
nothing they don't already have. Checked for a hidden cost before agreeing: `clients` carries no
financial columns (`billing_rule` and friends live on `contracts`, already separately masked);
its other columns (`client_type`, `business_line`, `status`, `external_crm_ref`, `notes`) are
internal CRM bookkeeping already exposed row-wide to every other non-finance internal role via the
existing `clients.read` branch -- nothing new rides along with the name. Against that, a raw UUID
protects nothing either; it just reads as broken.

**Fix, as an RLS branch, not a lookup workaround (`202609170001`):** a `mywork.*` branch on
`clients`' SELECT policy, scoped to "a client with a group the viewer has an allocated session
in" -- exactly the shape flagged as likely-correct when this item was first opened. Structurally
mirrors `groups`' own existing `mywork.*` branch (nested nothing new), which matters per item 68's
lesson directly above: the nested reads on `public.groups`/`public.sessions` use the identical
condition those tables' own `mywork.*` branches already use for this exact viewer/capability pair,
so nothing here can be silently narrowed to false the way `202609160001`'s `finance.operations.*`
branch was -- confirmed, not just reasoned, per the dry run below.

**A UUID must never render as a name, independent of the RLS answer.** `page.tsx`'s `clientName`
now falls back to `null`, never to `group.client_id`. `GroupHeader`/`GroupInfoSection` (both `"use
client"`, but still SSR'd on first load) render a translated placeholder --
`t("client_hidden")`, "Not visible to your role" / "Nevizibil pentru rolul tău" -- the same
`contract_hidden` shape this file already used for a masked contract link. Checked which roles
could still hit the placeholder today: every role holding `groups.read` (`operations_manager`,
`finance_operations`, `finance_admin_reporting`) also holds `clients.read` or a finance branch
(confirmed against `seed.sql`'s grants), so nothing reachable today actually shows it -- it exists
for correctness, not because a live gap remains.

**Verified, in order:** (1) a transaction-scoped dry run
(`scripts/verify_clients_mywork_visibility.sql`) applying the exact policy DDL then asserting,
rolled back -- 4/4: principal sees the client, secundar sees the same client, an unrelated trainer
(no session on the group) does not, the principal does not see a second, unrelated client. (2) the
real migration pushed live (`db push --linked`). (3) the actual rendered page, not just the
policy: a real `verifyOtp` sign-in as `maxdigitalro+trainerb1@gmail.com` in WOW LAB Test Org B,
carried as an `@supabase/ssr` cookie into a plain HTTP GET of `/groups/[id]` against a local `next
dev` server (no headless browser available in this environment) --
`scripts/verify_group_detail_client_name_render_test_org_b.ts` confirms the real client name is
the visible text in both the `<h1>` and the "Client" row, and that the raw id never appears as
element text content (it still legitimately appears once, in the hydration payload, as
`GroupInfoSection`'s own `clientId` prop -- used by the edit form's contract filtering, not
displayed). (4) since `WOW LAB` (the real org, not Test Org B) holds zero `sessions` rows today
(confirmed live, same finding as item 65) -- nothing in production exercises this branch yet --
the identical branch was independently re-verified against `WOW LAB`'s own organization id via pure
SQL impersonation, insert-then-rollback, no Auth API call and no `last_sign_in_at` touch
(`scripts/verify_clients_mywork_visibility_wowlab_prod_org.sql`): PASS. (5) after deploy, the same
real-rendered-page check from (3) was re-run directly against `https://app.wowlab.ro`, real WOW LAB
org, using `maxdigitalro+trainer@gmail.com` (a fixture account, not a named teammate --
`test+trainer-a@wowlab.dev` was tried first and has no `auth.users` row at all, the same gap
Cătălina/`test+user-b@wowlab.dev` had per item 22/DATABASE_CONVENTIONS.md §11, noted below as item
70, not fixed here): 3/3, identical result to Test Org B. Fixture rows created and deleted by the
script; `WOW LAB`'s own group/session/client counts confirmed unchanged (2/0/3) before and after.

**Full RO/EN i18n:** `client_hidden` added to `groups/i18n.ts`.

**Lives in:** `supabase/migrations/202609170001_add_clients_mywork_visibility_branch.sql` and its
rollback; `scripts/verify_clients_mywork_visibility.sql`,
`scripts/verify_clients_mywork_visibility_wowlab_prod_org.sql`,
`scripts/verify_group_detail_client_name_render_test_org_b.ts`; `app/(app)/groups/[id]/page.tsx`
(`clientName`'s new `null` fallback), `group-header.tsx`, `group-info-section.tsx` (the translated
placeholder), `groups/i18n.ts` (`client_hidden`); item 65 above (payroll's parallel, separate gap,
still open, still inert); item 68 below (the general lesson this fix was checked against before
being written).

---

### 67. The five payroll walkthrough findings, fixed and re-verified live

2026-09-16/17. Follow-up to the payroll walkthrough (its own six-step live walk of the close flow,
fixture-verified, cleaned up afterward) -- five findings, fixed in the order given, each verified
live in `wow-lab-test-b` afterward by re-walking the same scenario (one session, one trainer
confirmed, one not), then confirmed again on `app.wowlab.ro`.

1. **`/payroll` told Anka nothing before she closed.** Added a pre-close summary on `/payroll`,
   computed from one org-wide `sessions` fetch (`page.tsx`) already reacting to the month `<input>`'s
   own client state: session count, trainer-slot count, and -- prominently, by name -- every
   unconfirmed trainer/session pair. Confirmed live: renders "1 of 2 trainer slots are not
   confirmed" with "Test Trainer B2 -- WALKTHROUGH RE-VERIFY client · 17 Sept" listed underneath.
   The confirm step's own copy now states the pay consequence directly when any slot is
   unconfirmed ("a trainer is not paid for a session they haven't confirmed"), not just the
   write-access one it said before. Two real bugs caught only by looking at the rendered page, not
   by reading the diff: both "nothing to flag" copy strings (`summary_all_confirmed`,
   `summary_sessions_count`) referenced `{{month}}` in their template without the call site ever
   passing it, so the page literally printed `{{month}}` until caught live and fixed twice.

   **What the screen says when nothing is unconfirmed, so it doesn't become a warning people learn
   to click past:** plain, uncolored text -- no box, no border, same weight as `history_empty`
   elsewhere on this page -- either "No sessions in {{month}}." or "{{n}} sessions this month. All
   {{total}} trainer slots are confirmed." Structurally different from the orange box, not a
   suppressed copy of it: the box itself is absent from the DOM in this state, not present-but-empty.
   Confirmed live in both states -- the has-unconfirmed box before correcting Test Trainer B2's
   confirmation, the plain "all confirmed" line immediately after.

2. **Anka had no correction UI at all.** `correctSessionConfirmation` existed and worked; no screen
   called it. Added as a third case to `ConfirmationControl` on `/groups/[id]` -- the same screen
   the session already lives on, not a new page -- gated on `org.settings.manage OR
   finance.operations.*`, matching the action's own check exactly (`canCorrectConfirmation`,
   threaded from `page.tsx`). Checked in this priority order, and it matters: the row-matched
   trainer's own toggle (respects the month-close gate) is checked *before* the correction path
   (which doesn't), so a viewer holding both never bypasses their own gate through the correction
   control. Confirmed live: as the finance fixture, toggled Test Trainer B2's box from unconfirmed
   to confirmed on the group page -- the other slot (Test Trainer B1, already confirmed) stayed
   confirmed, not reset -- then confirmed the same correction control still worked identically after
   the month was closed for real.

3. **`updateSessionAttendance`'s closed-month error was always "not the assigned trainer," even
   for a trainer who was.** Rewritten to pre-check the same way `confirmSessionAttendance` already
   does: read the session, compare the caller against both trainer slots (not assigned -> reuses
   `SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR`, correct wording for either write), then check
   `payroll_periods` for the session's month (closed -> new `SESSION_ATTENDANCE_MONTH_CLOSED_ERROR`,
   translated RO/EN as `attendance_month_closed_error`). Confirmed live: Test Trainer B1 (the actual
   assigned, confirmed principal), attempting to edit attendance on a session in a month just
   closed for real, now sees "This month is closed. You can no longer change attendance for this
   session." -- not the old, false "requires being the assigned trainer" text.

4. **Trainer names rendered as "Unknown."** Traced before fixing: `public.users`' own SELECT
   policy had no branch for `finance.operations.*` or `mywork.*` at all -- confirmed live against
   `role_capabilities` that neither implies `org.members.read`, the only branch that existed.
   Two new branches added (`202609160001`, plus a same-day correctness fix, `202609160002` --
   see below), each scoped to exactly the case that needed it, per the explicit "must not hand
   anyone names they should not see" constraint: (a) a `finance.operations.*` holder sees the name
   of anyone holding `trainer`/`senior_trainer` in the same org, nothing broader; (b) a `mywork.*`
   holder sees a co-trainer's name only on a session they're both allocated to, not org-wide.
   Verified live via direct impersonation (not just "the UI looked right"): finance sees a
   trainer's name but not a non-trainer's; a trainer sees their co-trainer's name but not an
   unrelated trainer's they share no session with.

   **`202609160002`, a real bug in the first migration, caught by the live verification script
   before this was reported done, not after:** the `finance.operations.*` branch read
   `public.user_org_roles` directly inside the policy -- but that read is itself subject to
   `user_org_roles`' own SELECT policy (`is_platform_owner() OR user_id = current_user_id() OR
   has_capability('org.members.read', ...)`), which a `finance.operations.*` holder doesn't satisfy.
   The branch was structurally dead for the one role it was written for, despite
   `app.has_capability('finance.operations.*', ...)` alone returning true when called directly.
   Fixed by moving the read inside a new `SECURITY DEFINER` helper
   (`app.viewer_sees_trainer_via_finance_ops`), the same way `has_capability()` itself already
   bypasses `user_org_roles`' RLS to do its own lookup. The `mywork.*` branch didn't have this bug
   -- it reads `sessions`, and the exact row it filters for is provably already visible to the
   viewer under `sessions`' own RLS, confirmed by the two co-trainer assertions passing on the
   first attempt.

   Two related, adjacent findings caught while building this fix, deliberately **not** patched the
   same way -- both recorded separately (items 65, 66 above) rather than folded in here, since both
   intersect `clients`' deliberate client-type segregation rather than being plain oversights:
   the payroll summary can still show "Unknown" for a client name to a `finance.operations.*`-only
   closer outside their billing segment (currently inert, zero real sessions org-wide); a trainer's
   own group detail page shows the raw client UUID instead of a name, for the same underlying
   reason from the opposite direction (`mywork.*` has no branch on `clients` at all).

5. **The dead zone on confirm, attendance save, and payroll close never got the `pendingCreate`
   fix the create forms did.** Extended the same shape -- a small pending-state object set only on
   a confirmed server success, cleared by an effect that watches the real revalidated prop for the
   expected value to actually land, 15s timeout as a safety net, not the signal -- to three more
   spots, not a second pattern: `pendingConfirmation`/`pendingAttendance` in
   `group-detail-client.tsx` (covers both the trainer's own toggle and Anka's correction, since
   both wait on the same `sessions` prop), and `pendingClose` in `payroll-client.tsx`. Each renders
   "Saving…" (translated) in place of the checkbox/value/button for exactly that window. Confirmed
   correct by code parity with the already-proven create-form pattern and by the write itself
   landing correctly end-to-end (the correction in finding 2 above resolved to the right final
   state); the millisecond-scale dead-zone window itself was not caught on camera -- local dev's
   own round trip is fast enough that reproducing the gap on screen would need artificial network
   throttling, judged not worth building for this round.

**Full RO/EN i18n**, including every string this round added: `attendance_month_closed_error`,
`saving_confirmation`, `saving_attendance` (`groups/i18n.ts`); `summary_no_sessions`,
`summary_all_confirmed`, `summary_sessions_count`, `summary_unconfirmed_heading`,
`summary_unconfirmed_list_heading`, `confirm_prompt_with_unconfirmed`, `closing_month`
(`payroll/i18n.ts`).

**Lives in:** `app/(app)/payroll/page.tsx`, `payroll-client.tsx`, `i18n.ts`;
`app/(app)/groups/[id]/group-detail-client.tsx`, `page.tsx`; `app/(app)/groups/actions.ts`,
`i18n.ts`; `app/(app)/groups/session-write-errors.ts` (renamed from
`session-confirmation-errors.ts`); `supabase/migrations/202609160001_add_users_trainer_name_visibility_branches.sql`,
`202609160002_fix_finance_ops_trainer_visibility_uor_rls.sql` and their rollbacks;
`scripts/verify_users_trainer_name_visibility.sql`; items 65, 66 above (the two related gaps found
and deliberately deferred, not folded into finding 4).

---

### 68. An RLS branch that queries another RLS-gated table inherits that table's restrictions — the general form behind `202609160002`

The specific bug (finding 4 in item 67 above): `202609160001`'s `finance.operations.*` branch on
`public.users` read `public.user_org_roles` directly inside its `USING` expression --
`exists (select 1 from public.user_org_roles target_uor join public.roles ... where
target_uor.user_id = users.id and ... and app.has_capability('finance.operations.*', ...))`. That
`select` is not exempt from `user_org_roles`' own SELECT policy just because it sits inside a
different table's policy -- it runs as whatever role is executing the outer query, subject to
every RLS policy that role is subject to, everywhere. `user_org_roles`' own policy is `is_platform_
owner() OR user_id = current_user_id() OR has_capability('org.members.read', ...)` -- a
`finance.operations.*` holder satisfies none of those three, so the inner read returned zero rows
for that viewer regardless of what `has_capability('finance.operations.*', ...)` would separately
say. The branch was live, syntactically valid, applied cleanly on `db push`, and evaluated to
`false` for every caller it was written for, unconditionally.

**The general form, not just this one branch:** any RLS policy that queries a second table --
directly, not through a `SECURITY DEFINER` function -- is silently narrowed to the intersection of
"what this branch's own logic says" and "what the querying role may see in that second table
anyway." When the two happen to align (the same capability gates both, as in `202607100002`'s
original `org.members.read` branch -- entering that branch already requires the capability that
also makes the `user_org_roles` row visible), the bug never surfaces and the pattern looks safe.
When they don't align -- a different capability, a different table, a different role -- the
branch can be dead on arrival, and nothing distinguishes that from a branch that's merely narrow
by design. `app.has_capability()` and `app.is_platform_owner()` already avoid this themselves by
being `SECURITY DEFINER` (confirmed live, `pg_get_functiondef`) -- they bypass RLS on
`user_org_roles`/`role_capabilities`/`users` deliberately, which is exactly why calling them
directly returned the right answer in this same investigation while the raw subquery, right next
to them in the same policy, did not.

**Why the build's own signals didn't catch it:** the migration applied without error (a policy
predicate that's always false is not a syntax or permission error, it's a semantically empty one),
and nothing short of impersonating the exact viewer/row pair and reading the *result* -- not the
*definition* -- distinguishes "correct and narrow" from "silently dead." `scripts/verify_users_
trainer_name_visibility.sql` did this by impersonating both the finance viewer and the trainer via
`set_config('request.jwt.claims', ...)` inside a rolled-back transaction and asserting on what
came back, not on whether the migration applied. Postgres itself has no warning, lint, or planner
notice for a `USING`/`WITH CHECK` expression that can never be satisfied by anyone -- this is
purely a semantic property of the policy against the *other* policies it happens to reference.

**Worth auditing elsewhere on the same basis, not assumed clean by analogy:** every other RLS
policy in this schema that reads a second table inline rather than through a `SECURITY DEFINER`
helper is a candidate for the same silent-narrowing failure, whether or not it happens to work
today by the same "capability coincidence" `202607100002`'s original branch relied on. The general
rule to check any of them against: a cross-table read inside a policy is exactly as visible to the
querying role as a top-level query would be -- if that role couldn't `select` the referenced table
directly, the branch that reads it can't either, no matter what else the branch's own logic says.
**Lives in:** item 67 above, finding 4 (the concrete instance); `supabase/migrations/
202609160001_add_users_trainer_name_visibility_branches.sql` (the branch that shipped dead),
`202609160002_fix_finance_ops_trainer_visibility_uor_rls.sql` (the `SECURITY DEFINER` fix);
`app.has_capability()`/`app.is_platform_owner()` (the existing functions whose own `SECURITY
DEFINER` shape this fix now matches); `scripts/verify_users_trainer_name_visibility.sql` (what
actually caught it).

---

### 69. Working note: `pkill -f "next dev"` is not scoped to this project

Used to stop a local dev server started for this session's verification. `pkill -f` matches
against the full command line of every process on the machine, not this project's own process --
it killed a second, unrelated `next dev` (another of Mihai's projects, `maxdigital-dashboard`,
running since before this session started) in the same stroke, because its command line also
contained the literal string "next dev". Disclosed to Mihai directly when found; his own dev
server was not restarted by this session, since it wasn't this session's to restart.

**Use a port- or PID-scoped stop instead of a name/command-line match** when a background dev
server needs to be stopped: kill the exact PID returned when the process was started (`kill
<pid>`), or resolve by the port it's actually bound to (`lsof -ti:3001 | xargs kill`) rather than by
matching on a command string that every same-framework project on the machine shares.

**Paired note, 2026-10-08 — item 109 below**, and the same unrelated project, `maxdigital-dashboard`,
is involved again. There the problem was a command matching too widely; here it was a command
running in the wrong directory: three `git push`es executed inside that repo instead of this one,
succeeded on their own terms, and landed nothing here. Same family — a command whose scope is
implicit (a process name, the current directory) succeeds against the wrong target without
complaint.

---

### 70. Working note: `test+trainer-a@wowlab.dev` and `test+trainer-b@wowlab.dev` (WOW LAB) have no `auth.users` row

Found verifying item 66's fix against the real `WOW LAB` org: `generateLink` for
`test+trainer-a@wowlab.dev` failed with an empty error object. Checked live, not assumed: both
`test+trainer-a@wowlab.dev` and `test+trainer-b@wowlab.dev` have a `public.users` row but no
matching `auth.users` row -- the same gap `test+catalina@wowlab.dev`/`test+user-b@wowlab.dev` had
(item 22, fixed per DATABASE_CONVENTIONS.md §11's `admin.auth.admin.createUser({id, ...})`
procedure), just never hit before because nothing needed to sign in as either fixture until now.

**Not fixed here** -- out of scope for the task that found it, and neither account was blocking
anything: `maxdigitalro+trainer@gmail.com` (a real WOW LAB trainer fixture that does have an auth
identity) was used instead for that verification. Same §11 procedure would fix these two if a
future task needs to sign in as either.
**Lives in:** item 22 (the same historical gap, other accounts); `DATABASE_CONVENTIONS.md` §11 (the
fix procedure).

---

### 71. A cleared blocker leaves no trace when the item describing it isn't revisited — the general form behind items 19, 39, and 45's corrections below

2026-09-18. Three items above went stale the same way, within days of being written: item 19 said a
migration hadn't been applied after it had; item 39 (findings 2, 3) and item 45 (part 1) said a
capability gap was blocking real work, three days before a migration and an action closed exactly
that gap. In every case, the blocker cleared as a side effect of *other* work — done for its own
stated reason, correctly, and verified against its own goal — that happened to also satisfy a
sentence sitting in a different, unrelated part of this file. Nobody writing that other work
cross-checked it against the register; nobody re-reading the register afterward cross-checked it
against the code. Named, when this correction was requested, as this shape's fourth appearance —
counting across the register's whole history, not just this correction pass. The clearest prior
instance on record is item 29: the register describing its own trigger condition as unmet after the
code had already met it. This entry is a variant of that same failure, not a repeat of it — item 29
was the register lagging *itself*; this is the register lagging work that had no reason to know an
open item existed at all.

**Why nothing catches it on its own.** The blocked-on claim and the code that clears it are not
mechanically connected in any way — the only place a migration and an `OPEN_ITEMS.md` paragraph
about it are ever in the same field of view is a human's head, at the moment one of them is
written, and that connection decays the instant attention moves elsewhere. Nothing fails: the
thing the item said was blocked (`children_billed`'s derivation, in this case) was never built, so
there's no broken code anywhere to surface an error. Nothing warns: `db push` succeeding, `tsc`
passing, and a migration's own dry-run script going green all test whether the *new* code does what
it was written to do — none of them know or care that a sentence in a markdown file was describing
the state they just changed. And a stale paragraph is typographically identical to a current one —
bold headers, checked-live citations, dated commits — so a reader has no visual signal that this
particular one needs re-verifying before being trusted.

**Proposed, not built — three different strengths of catch, honestly rated:**

1. **A narrow, mechanical check for claims that are already a single checkable fact.** Item 19's
   "not yet applied to production" is exactly this shape — a script could extract every migration
   filename `OPEN_ITEMS.md` cites as unapplied/pending and diff it against `supabase migration
   list --linked`'s own output, flagging any mismatch. Cheap, close to free to run, and would have
   caught item 19 specifically. It would **not** have caught items 39/45 — "nobody can record
   session attendance on any layer" isn't a single fact with an existence check; it's a claim about
   the current wiring of RLS, a capability grant, and an action's own column scope, considered
   together. A narrower version of this same idea — grepping for whether a function/action name an
   item names as *missing* has since appeared anywhere in `app/` or `supabase/migrations/` — is a
   plausible partial catch for the 39/45 shape specifically, but it's a heuristic, not a proof: it
   would flag `updateSessionAttendance` appearing after item 39 named the gap it fills, but it
   can't tell a real fix from a same-named decoy, and it says nothing about claims that never named
   a function at all.
2. **A discipline, not a tool: whoever ships something that touches a table/action/RLS policy
   already cited in an open item's "Lives in" list greps this file for that name before merging.**
   This would have caught both — `202609110002`'s own migration comment already quotes item 39's
   reasoning back nearly verbatim, which means whoever wrote it *had* item 39's finding in view at
   the moment of the fix and simply didn't complete the loop back into this file. The gap wasn't
   not-knowing; it was not-closing-the-loop. This is real and cheap when it happens, but it depends
   entirely on someone remembering to do the second half of a two-part habit under time pressure —
   which is the identical failure mode that produced the gap in the first place, just one level up.
3. **Periodic re-reading of the whole register against live code — what actually caught all three
   instances above, and what item 64 already established is nobody's standing job once the writing
   stops.** This is the honest floor, not a fallback: for a claim like finding 2's ("nobody can
   record attendance, on any layer"), confirming or refuting it requires re-deriving the same
   cross-cutting investigation (RLS policy, capability grant, action, UI) that produced it in the
   first place. A mechanical check for that claim would have to reimplement that investigation, on
   a schedule, against a moving target — which is not meaningfully different from a person doing
   it, just automated. **Said plainly, since it was asked for plainly: for claims narrower than
   "does this specific named thing exist," the honest answer is nothing automatic — only
   re-reading, by someone or something willing to re-derive the investigation, not just re-parse
   the prose.**

**No mechanism proposed here is being built** — recorded as a decision surface for whoever next
decides this is worth the cost, the same way item 26 and item 49 record real gaps without
proposing fixes to them.

**Lives in:** item 19, item 39, item 45 below (the three corrections this generalizes — later in
file order, earlier in item number, an artifact of this file's own convention of adding new items
near the top of its most-recent block rather than renumbering); item 29 below (the closest prior
instance, from the opposite direction — the register's own trigger condition, not a blocker cleared
by someone else's unrelated work); item 68 above (a different member of the same family — silent
RLS narrowing — also caught only by re-deriving the investigation, not by any test that passed).

---

### 72. The WS-D developer-review gate — two documents disagree on whether it's open, and neither was ever told about the other

2026-09-18. Real school data entered production this month — three signed contracts, two real
groups. Two documents make claims about what that was supposed to require, and they don't agree.

**`docs/ws-d-plan.md`, quoted in full, the relevant lines:** line 3 — *"Poarta de review de
developer e **amânată** (nu avem developer acum) → WS-D **nu** se declară „sigur" doar pe baza
testelor; construim cu grijă și etichetăm riscul."* Line 100 — *"RLS pică **în tăcere**: o politică
subtil greșită trece toate testele dacă și testul e subtil greșit. Fără review de developer, WS-D e
„construit cu grijă și testat", **nu** „garantat etanș". Mergem înainte pe fazele de construcție,
dar **înainte de a pune date reale de școli/copii în producție**, poarta asta trebuie trecută."*
Unconditional, present tense, no date, never edited since.

**`docs/phase1-development-plan.md` §4 / row 15, quoted in full — what the closure actually rested
on:** *"Decizie finală (2026-08-07): gate-ul formal de review extern de developer NU se mai face —
Mihai a ales conștient să meargă mai departe fără el, pe baza a ce există deja: suita de teste RLS
(12/12 + 8/8 asertări, cu test de sabotaj funcțional), plus cele 3 descoperiri de mai sus găsite
organic, cu dovadă live, nu ipotetic. Rândul #15 din tabelul de mai sus e închis oficial cu acest
raționament, nu doar amânat."* The "3 descoperiri," named in full just above that sentence in the
same document: the Members table reading empty (a PostgREST foreign-key ambiguity, never previously
verified as an error) — fixed; every DELETE on the 4 audited tables being silently cancelled by an
old trigger bug, meaning the "remove a role" action in `/admin/users` had never once worked
correctly — fixed, checked twice independently, including a historical audit confirming no real
user had ever actually been affected by it; invited-but-unconfirmed users being structurally unable
to sign in through the public form (`disable_signup`, not rate-limiting) — fixed by direct
reinvitation. Plus a separate end-to-end pass across all 7 real accounts at the time (role, nav,
capabilities, RPC spot-checks, 7/7, confirmed manually by Mihai).

**The timeline, checked precisely, not assumed close.** The closure is dated 2026-08-07. The
earliest real client in production today, Lycée Français, is dated 2026-09-10 — roughly five weeks
later. The decision was made *before* the condition `ws-d-plan.md` names, not in response to it.
`ws-d-plan.md` itself carries no date anywhere in the file and was never edited to reference the
closure. This item is the first place the two documents have ever been read against each other.

**Neither document was ever told about the other, and neither is referenced anywhere else in this
register.** `phase1-development-plan.md` is itself last verified 2026-08-10, its own staleness
addressed separately below — written and closed before virtually all of the domain-specific RLS
this register now tracks existed (Clients & Contracts, Groups & Sessions, payment-config, payroll
all shipped after it).

**Corrected 2026-09-18 — the failure mode has happened three times, not two, and the earliest of
the three predates both items already cited here by weeks.** Checked directly, not assumed from
memory of items 57/68 alone: `202608120002`'s avatar-read Storage policy, shipped 2026-08-12 — five
days after the closure — read `public.user_org_roles` inline for `app.belongs_to_org()`, subject to
that table's own RLS, and denied every non-platform-owner caller outright. Its own fix
(`202608120003`) states the cause plainly: *"found via live testing (not assumed) immediately after
applying it"* — a person clicking around, not the cited test suite, not any suite. This instance
was never recorded anywhere in this register until now. Together with item 57 (a row match shipped
without its paired capability check, 2026-09-10/11) and item 68 (a branch that "applied cleanly on
`db push`, and evaluated to `false` for every caller it was written for, unconditionally,"
2026-09-16/17) — three confirmed instances, spanning the full five weeks since the closure, the
first one five days after it, none caught by the suite the closure cites, all caught by a person
reading a specific policy by hand, once, after the fact.

**The cited test suite, checked directly rather than trusted by name.** `db/tests/rls_ws_d_read.sql`
and `db/tests/rls_ws_d_write.sql` are the "12/12 + 8/8" suite — their own header comments name the
exact two July migrations they test, and counting their own assertion blocks lines up with those
figures. Git history: one commit each, both 2026-07-10, never touched again — not once, through all
22 migrations that have touched `CREATE POLICY`/`DROP POLICY` since the closure. They know nothing
of `clients`, `contracts`, `groups`, `sessions`, payment-config, or payroll, none of which existed
when they were written. `db/tests/rls_clients_contracts.sql` (created 2026-08-10/11) and
`db/tests/rls_groups_sessions.sql` (created 2026-08-13) each got commits only during their own
construction week and never again — six more migrations to `clients`/`contracts`/`client_contacts`
policies and five more to `groups`/`sessions` policies have shipped since, none reflected in either
file. `suppliers`, payment-config, and payroll have no test file in `db/tests/` at all, ever; every
verification of `users`' own repeatedly-revised visibility policy was a one-off `scripts/verify_*.sql`,
run once by hand. No runner exists anywhere for `db/tests/` — every file's own header says "run
block-by-block in the SQL Editor." The suite the closure names has not run against anything built
since, and nothing has stood in for it as a maintained, re-run mechanism.

**What a real review would examine today that nothing currently does — audited, not assumed, by
searching every `CREATE POLICY` for an inline cross-table read (the exact shape all three known
bugs share) instead of a `SECURITY DEFINER` helper call.** Two live, currently-unverified candidates
beyond the three already-fixed instances:
- `contracts` and `client_contacts`'s own SELECT policies (`202608100003`, `202608250001`) each
  have a `finance.operations.*`/`finance.reporting.*` branch reading `public.clients.client_type`
  inline, checking `client_type in ('private_school', 'parent_b2c')`. Safe today only because that
  exact two-value list is hand-written separately in three places — those two policies and
  `clients`' own — with nothing keeping them in sync but discipline. A single edit to any one of the
  three, without the other two, goes silently wrong in whichever direction the drift runs.
- `users`' own UPDATE policy (`202607100004`, unedited since July) has an `org.members.manage`
  branch reading `user_org_roles` inline, which itself needs `org.members.read` to return anything.
  Safe today only because `org.members.manage` is never granted to any role except
  `organization_owner`, who holds `org.members.read` too — via the same dynamic "all capabilities"
  grant, not because the two are related. A future role holding `org.members.manage` alone (a
  plausible want: "can edit membership, not browse the whole roster") would silently lose the
  ability to edit anyone, the identical shape as the avatar bug above.

One checked and ruled out: `sessions`' UPDATE policy reads `payroll_periods` inline for its
month-close check (`202609150002`) — deliberately safe, not coincidentally. `payroll_periods`' own
SELECT policy explicitly grants `mywork.*` read, with a comment stating exactly why. The one place
in the schema this risk was reasoned about at write time, not discovered after.

**Whether the 2026-08-07 reasoning still holds — sharper than "arguments on both sides," reported,
not decided.** The decision was explicitly a judgment about *the state of the work* — its own text
never mentions data timing or "revisit once real data arrives," only "pe baza a ce există deja"
(on the basis of what already exists): the test suite's pass count and three caught bugs, offered as
proof the real-user-testing discipline works. That framing was meant to be durable, not a stopgap —
which is exactly what makes the finding above load-bearing: the specific evidence it cited has been
directly contradicted on its own terms, three times, the earliest five days after the ink dried,
none caught by the suite named as the reason. Re-run today, that suite still passes 12/12 + 8/8 —
nothing in it changed — so in the narrowest sense the cited evidence is still true. **CORRECTED
2026-09-22 — that "re-run" was not actually re-run carefully enough; the claim above was wrong on its
own terms, left as written rather than silently edited (same discipline this entry already applies to
`ws-d-plan.md`).** Asked directly to run every `db/tests/` and `scripts/verify_*.sql` file for real
and report pass/fail rather than trust either file's own claim, not just this entry's: `rls_clients_
contracts.sql` could not run AT ALL since 2026-08-18 (`contract_number`, dropped in `202608180002` —
eleven days after the 2026-08-07 closure, not five; see item 86 below for the full audit) — the
"8/8" figure this paragraph names is `rls_ws_d_write.sql` specifically, which DID run, but not
honestly: three of its blocks resolve a second fixture user's id by email AFTER switching role to
`authenticated`, which lost SELECT on `users.email` on 2026-08-21
(`202608210001_users_field_masking_grants.sql`) — inside a `BEGIN/EXCEPTION WHEN insufficient_
privilege` block written to catch the WRITE POLICY's own expected denial. The lookup's failure and
the policy's denial are the same SQLSTATE, indistinguishable to that handler — every affected
assertion kept reading `pass = true` regardless of what the actual policy did. **This includes the
suite's own sabotage self-check** ("does this suite have teeth"), whose own comment says `pass` is
supposed to flip to FALSE when the policy is deliberately broken. It didn't — the assertion was never
reaching the sabotaged policy at all. The one piece of evidence this closure cites as proof the suite
"has teeth" had none, silently, three days before this paragraph was first written, and this entry
said "still true" without checking closely enough to notice. Both files fixed 2026-09-22 (item 86
below) — re-verified for real: `rls_clients_contracts.sql` 8 points + sabotage, all correct;
`rls_ws_d_write.sql` 6 blocks + sabotage, all correct, sabotage now correctly reads `pass = false`
under a broken policy. The conclusion drawn from the ORIGINAL evidence is not: "this discipline
catches what a developer review exists to catch" is the part three dated, real, previously-uncounted
instances (now four, item 86 below) contradict — and the evidence itself was weaker than claimed
even before that, only nobody had checked. Separately, and independent of
that: the decision's other framing — "review vs. no review, because no developer exists to run one"
(`ws-d-plan.md`'s own *"nu avem developer acum"*) — turns on a fact only Mihai has, not something
checkable from this repo. If that constraint is unchanged, the choice architecture is unchanged
regardless of the RLS surface's growth; if it isn't, this decision was never re-weighed against the
option it originally had none of.

**This is Mihai's decision, and possibly Anca's — not resolved by this entry.** What this entry
fixes is that the register was silent about the contradiction, and undercounted the evidence, until
now. It does not pick a side. `ws-d-plan.md` is left unedited — the same standing choice this repo
already made for `202608270001`'s comment on the retention job in the top entry of this file, where
a document with a false live claim was corrected by a new entry rather than by rewriting the
original.

**2026-09-22 — closing statement, the timeline stated once, plainly, for whoever makes this call.**
The 2026-08-07 closure cited a test suite's pass count and a functional sabotage check as the reason
external developer review wasn't needed. That suite's sabotage check read `pass = true` for a
deliberately broken policy from 2026-08-21 onward — fourteen days after the closure — and stayed that
way, unnoticed, until today. A second file the same closure implicitly rested on (`rls_clients_
contracts.sql`, C1's own suite) could not run at all from 2026-08-18, eleven days after. **The state
the closure's reasoning described had already ended within two weeks of the closure itself being
written.** Neither of the two RLS defects found this September (item 68, item 77) was ever covered by
anything in `db/tests/` before today (item 88 below) — the suite could not have caught either even
while it was running correctly. Whether to reopen the external developer review the closure declined
is Mihai's decision, unchanged by this entry. What changes: as of today (item 86, item 88 below), the
suite genuinely is what the closure described — a suite that passes, with a sabotage check that
actually has teeth, now additionally covering both defects found since. That decision can now rest on
real, current evidence, whichever way it's made.

**2026-09-22 — a fourth instance, the one that names what a review is actually for.** Column
narrowing — which fields a caller may change on a row RLS already admits them into — lived only in
server action TypeScript across this entire codebase, while `authenticated` held a table-wide UPDATE
grant on every column of `sessions` (and an equally unrestricted one on the three finance columns of
`contracts` and `groups.children_confirmed`). Confirmed live, not assumed: a trainer, using nothing
but the public anon key and their own real session cookie (non-httpOnly by `@supabase/ssr`'s own
default, unoverridden here), issued a raw `PATCH` to `/rest/v1/sessions` and successfully confirmed a
**colleague's** attendance directly — the field pay is keyed on (`202609150002`'s own header: "Pay
follows this timestamp") — with zero involvement from the server action written specifically to
prevent exactly that. Items 57/68/the avatar policy (this entry's earlier three) were each a single
RLS branch, subtle and narrow. This one was a structural pattern repeated across every write action in
the codebase, for as long as the codebase has had write actions — not a policy someone wrote
carelessly once, a whole *category* of check nobody had verified could not be walked around. **This is
exactly the shape an external review exists to catch, and it was caught by an internal one instead —
roughly six weeks after the 2026-08-07 closure declined to hold one.** Fixed same day (item 91 below):
every affected write routed through a `SECURITY DEFINER` function, the direct grant revoked, a
permanent sabotage-proven regression test added. The reopen-review decision remains Mihai's — this
paragraph adds a fourth, larger data point to it, not a recommendation.

**Lives in:** `docs/ws-d-plan.md` (lines 3, 100 — unedited); `docs/phase1-development-plan.md` §4,
row 15 (the closure, unedited); `db/tests/rls_ws_d_read.sql`, `rls_ws_d_write.sql` (the cited suite,
frozen since 2026-07-10), `rls_clients_contracts.sql`, `rls_groups_sessions.sql` (the two
domain suites, each frozen at its own construction week); `supabase/migrations/202608120002_org_scope_avatar_read_policy.sql`,
`202608120003_fix_avatar_read_policy_via_shares_org_helper.sql` (the third, earliest instance, newly
recorded here); `supabase/migrations/202608100003_add_clients_contracts_rls_policies.sql`,
`202608250001_client_contacts_row_filters_and_notes_grant.sql`, `202607100004_add_write_policies_ws_d_d1b.sql`
(the two live unverified candidates); `202609150002_add_sessions_confirmation_columns_and_rls.sql`
(the one checked and ruled safe); item 57 below (the second instance); item 68 above (the third
instance); item 86 below (the 2026-09-22 correction — the suite's own claimed pass count was itself
wrong, and the audit that found it), item 88 below (the rebuild that makes the closing statement
above true), item 91 below (the fourth instance and its fix); `phase1-development-plan.md`'s own
broader staleness, addressed separately below — this closure's isolation from the rest of this
register is one symptom of it, not the whole of it.

---

### 73. Costuri Admin (admin overhead cost tracking) — a real gap `phase1-development-plan.md` was the only place tracking, folded in from its row 6

**What it is:** an admin-overhead cost-tracking module for Anka/Laura/Raluca, named in
`docs/phase1-development-plan.md` row 6. Per that document (last touched 2026-08-10, its status now
superseded — see item 75 below): rates were confirmed by Anca and applied to the mockup
(`progress.md` #42-43, including a correction to Anka's own figures), with the row's own note
reading *"Rămâne: construcție reală în Phase 1, confirmare că task-ul Asana chiar există."*
("Remaining: real construction in Phase 1, confirm the Asana task actually exists.") Never built.

**Checked live, not assumed from the old doc's status:** no table anywhere in `public` matches
`%cost%` — `information_schema.tables` returns zero rows for any name resembling an admin-costs
schema. Nothing exists for this today, not even a skeleton.

**Not simply buildable, and not simply blocked on Anca either — a staleness question first.** The
rates this row cites as "confirmed" were confirmed against the mockup-era cost model, over five
weeks before the real Phase 1 domain rebuild (Clients & Contracts, Groups & Sessions, payment-config,
payroll) replaced almost everything else that document described. Whether those specific figures,
or the shape they'd have been entered in, still match what Anca would say today is unconfirmed —
this item does not assume they're still current just because a prior document once said so, the
same caution items 35/42/48 already established for old "confirmed" claims that turned out to need
re-checking. Re-confirm before building, not because the answer is expected to differ, but because
nothing here has checked.

**Blocked on:** a re-confirmation with Anca that the 2026-08 figures (or a fresh set) still apply,
then ordinary construction — no design blocker beyond that.

---

**UPDATED 2026-10-12. The rates now exist (item 128 below). Three things about the screen itself,
none of which was visible when this entry was written.**

**1. The grouping in the first line of this entry is wrong, and it is the SECOND time.**
*"an admin-overhead cost-tracking module for Anka/Laura/Raluca"* comes from Anca's July request
(`docs/progress.md` #128: *"echipa admin-only: Anka, Laura, Raluca Margean"*). **Raluca Margean is
not admin overhead.** She is a content supplier: paid per article and per newsletter, through
`drepturi de autor` rather than an invoice, with a `CONTRACT DE CESIUNE A DREPTURILOR DE AUTOR` in
the supplier register — and this app already models her that way, with a `suppliers` row and three
`supplier_contracts` rows (item 127 below).

**The first time was item 22 below, and the two mistakes are linked in a way worth seeing.** Item 22
records that the proposal to give her a `trainer` role *"was directly contradicted"* by the
evidence — and the evidence used to refute it was **this very grouping**: she was *"grupată explicit
ca «echipa admin-only», absentă din rosterul de traineri"*. So the admin-only grouping was the
argument that correctly rejected "trainer", and it is now itself wrong. **She has been mis-filed
twice, and the second mis-filing is what justified rejecting the first** — which is why the right
response to "she is not X" is not "therefore Y", and why item 22's own decision (give her no role at
all rather than guess one) was better than either label. That decision now reads as the only one of
the three that has held.

**What follows for the schema: `admin_hours` has no shape that holds her work.** Hours × a category
× a rate does not describe an article with a word count, and `admin_rates` already splits her into
`per_article`/`per_newsletter` rows precisely because her unit is not an hour (item 128 below). So
either something records each article with its word count and the tier follows, or her work stays
outside the app the way the lesson-plan writers' payments do. **That is a question for Anca —
question 9 in "Questions waiting on Anca" above** — and it is hers rather than ours because it
decides whether a second table exists at all.

**2. Who the screen is actually for — for us to know, not to ask.** Of the three people this module
was framed around, **two will not use it**: Anka works through Toggl plus a monthly PDF to Anca for
approval (`progress.md` #128), and Anca herself is salaried (`progress.md` #128: *"Anca-salariat"*).
Raluca is question 9. **So the first real users are Laura Moale, Teodora Merișan and Alexandra
Nuțu** — the three people on the 50 → 55.50 uplifted rate (item 128 below), none of whom is named
in the original request.

**Does that change the screen, or only who to ask about it?** Mostly the second, and the distinction
matters:

- **It does not change the shape.** All three are on a single hourly rate in one category (`admin`),
  so the row is the same row: person, date, minutes, category, a required `legal_entity_id`
  (item 112 below), a note.
- **It does change who to design it with.** The request was framed around Anka, whose workflow is
  Toggl-shaped — detailed tracking elsewhere, a monthly summary for approval. Designing for that and
  handing it to three people who have no Toggl habit is how a screen gets built for the wrong
  motion. Laura, Teodora and Alexandra should be asked how they record hours today, before layout.
- **And it changes the volume assumption.** Three occasional admin contributors generate far fewer
  rows than one full-time administrator, which makes the simplest possible form adequate for longer
  than the original framing implied.
- **One thing it does change about the shape, slightly:** Anka remains the likeliest person to need
  the `ateliere` and `financiar` categories, and she is the one who will not use the screen. So the
  category select will, in practice, offer `admin` only to everyone who actually types into it. Worth
  not over-building the category dimension for a population that has one.

**3. The month-close gate is a DECISION, not an inheritance.** Trainer hours lock when payroll
closes — `app.rpc_update_session_attendance` refuses on a closed month, and
`202609150002` extended the same branch to confirmations because *"a trainer cannot modify anything
afterwards"* is unqualified. **Admin hours sit next to that code and must not acquire the gate by
proximity.** That exact failure nearly happened in the other direction: item 117 below's validator
function was written beside the month-gated one and had to be given an explicit comment saying *do
not copy the `payroll_periods` lookup into this function*, because validation precedes delivery and
feeds no pay figure.

**DECIDED 2026-10-12, Mihai: admin hours LOCK when the payroll month closes.** Same month, same
invoice, same reason as the trainer gate — these hours are billed by the same people through the
same monthly cycle, and an hour added after the month closed either misses its invoice or forces a
correction to one already sent. That is precisely what the trainer gate prevents, and the reason
transfers unchanged.

**Written as a decision rather than inherited, and that distinction is the point of recording it.**
The two functions will sit in the same file and the `payroll_periods` lookup is three lines, so the
gate would have arrived by copy-paste whether or not anyone had thought about it. **Proximity is not
an argument in either direction** — item 117 below's validator is the counter-example on the same
file: it sits beside the month-gated function, needed the opposite answer, and carries an explicit
*"do not copy the `payroll_periods` lookup into this function"* for exactly that reason. Two
functions, adjacent, opposite answers, both correct — and neither derivable from where it sits.

So when the hours-entry write path is built, its month-close refusal is implemented **because of
this decision**, cited here, and not because the function above it has one.

**Blocked on:** question 9 for Raluca's half; nothing for the Laura/Teodora/Alexandra half beyond a
deployment (item 126 below).

**BUILD ORDER once the Git link is repaired, decided 2026-10-12** — recorded because by then the
reasons will have gone quiet:

1. **The admin hours screen**, and *designed with Laura, Teodora and Alexandra* rather than for a
   Toggl-shaped workflow. The request was framed around Anka, who will not use it; the three who
   will have no Toggl habit, and building for the wrong motion is the specific risk this ordering
   exists to avoid. Ask them how they record hours today, before layout.
2. **The supplier contracts view** — 30 rows live since today with no screen (item 127 below).
3. **The lesson-plan selector's next iteration** (item 110 below).

First because it is the one with a decided shape, a decided gate and no open question for the people
who will use it. Third because the selector already works and iterating it is improvement rather
than absence.
**Lives in:** `docs/phase1-development-plan.md` row 6 (superseded, see item 75 below);
`docs/progress.md` #42-43 (the original rate confirmation and correction) and #128 (the July request,
the Toggl workflow and *"Anca-salariat"*); item 128 below (the rates); item 112 below (the required
legal entity); item 130 below (the hour must carry its own kind); item 22 below (the first
mis-filing); item 127 below (where she is modelled correctly, as a supplier).

---

### 74. Recruitment → Academy → Evaluation pipeline — the recruit/onboard/academy half is untracked anywhere; the evaluation half is item 23

**What it is:** `docs/phase1-development-plan.md` row 7 names a full pipeline Anca drew herself
(with ChatGPT, two diagrams) and had applied to the mockup: a candidate portal using real stage
names (handover Anca→Cătălina, assisting, a test lesson, final decision), an onboarding tracker
(contract, module allocation, resource access, quiz, certification), WLab Academy (real modules —
Chemistry for Me, Detective Science, Green Week — with four states: allocated → access → quiz →
certified), and a trainers "needs action" panel. §2 of that document also names offboarding as a
real, acknowledged gap inside this same flow (*"nu atinge deloc ce se întâmplă când un trainer
renunță"* — doesn't touch what happens when a trainer quits — a procedure Anca herself called
"in progress" at the time, later answered per that document's own 2026-08-10 update: checklist,
exit interview, access revocation, an "on pause" state, applied to the mockup only).

**Distinct from item 23, checked precisely, not assumed to overlap.** Item 23 is the *evaluation*
domain specifically — Happy Face bonuses, the LP writers' separate criteria matrix, replacement-rate
reconciliation — and is already tracked, already blocked on Anca. This row is everything upstream of
that: recruiting a candidate, onboarding them, and running them through the Academy's own
module/quiz/certification flow. The two are adjacent, not the same — item 23 assumes a trainer
already exists; this item is about how one comes to exist on the roster at all.

**Checked live: none of it is modeled as a real table.** No `candidates` table exists anywhere
(confirmed independently by the scheduled-execution mechanism entry above, for an unrelated reason —
it needed to know whether any personal data existed to anonymize, and found none because this
domain was never built). `candidate` and `community_people` are seeded capabilities
(`supabase/seed.sql`) with no route behind either, the same shape item 56 already found for five of
the trainer's own six capabilities. Everything Anca drew exists today only as mockup screens with
static demo data.

**Blocked on Anca, with a caveat this item states plainly rather than assumes past.** The flow
itself is substantially designed already — unlike item 52's workshop gap, this isn't starting from
nothing — but it was drawn before the real Phase 1 domain model existed (no `users`/`user_org_roles`
shape to onboard *into*, at the time), and applied only to the mockup, never reconciled against the
schema that actually shipped since. Building against the 2026-08 flow unchecked risks the same
"described a workshop, schema models a group" mismatch item 52 found elsewhere — confirm the flow
still matches before treating it as ready-to-build.

**Blocked on:** Anca, to reconfirm the flow against the real schema before construction — not a
fresh design question, a staleness check on an old one.
**Lives in:** `docs/phase1-development-plan.md` row 7, §2, §3 (superseded, see item 75 below);
`docs/progress.md` #37, #42; item 23 below (the adjacent, already-tracked evaluation domain); item
56 below (the same unrouted-capability shape, on the trainer's own six); the scheduled-execution
entry above (independent confirmation no `candidates` table exists).

---

### 75. `phase1-development-plan.md` checked row by row against the live codebase — marked superseded, not annotated row by row

2026-09-18. Last verified 2026-08-10 by its own header — over five weeks before the real Phase 1
domain rebuild (Clients & Contracts, Groups & Sessions, payment-config, payroll, this whole
register) existed. Checked every row of its status table against the current codebase, the same
pass `WOW_LAB_OS_AD_Reconciliation.md` already applied to the fifteen architecture decisions (item
46 below).

| # | Row | Verdict |
|---|---|---|
| 1 | Anka's financial visibility | Superseded — the mockup version this row describes is moot; the real RLS-based mechanism (`contracts_billing_masked`, `finance.reporting.*`) replaced it with something structurally different, not just a later copy. |
| 2 | Flat 111 lei/oră base rate, editable in Settings | Superseded by something different in shape, not the same thing built for real — the actual system is six versioned, grade-based rate grids (item 20), not one flat editable number. |
| 3 | Sales Manager billing-rule visibility + "client ONG" | Half superseded, half unconfirmed — billing-rule visibility for `clients.create` holders is real and live (`202608100006`). "Client ONG" has no trace in the live `client_type` enum (`private_school`, `state_school`, `corporate`, `parent_b2c`, `special_project`) — `special_project` is the closest plausible fit, not a confirmed mapping. Not chased further here. |
| 4 | Franchise / Platform Owner cross-org stats | Never started, still accurately so — `is_platform_owner()` exists as the cross-org mechanism (item 27), but no stats surface was ever built. Same substance as item 1's cost-model gap, not a separate blocker. |
| 5 | Trainer payment table structure | Superseded — carried forward into the real, far more developed payment-config schema (item 20), not a leftover gap. |
| 6 | Costuri Admin | Real gap, untracked until now — folded in as item 73 above. |
| 7 | Recruitment → Academy → Evaluation | Real gap (recruit/onboard/academy half), untracked until now — folded in as item 74 above. The evaluation half is item 23, already tracked. |
| 8 | Trainer Profile & Performance | Superseded by a later, more thorough investigation — item 53 checked this exact ground in far more depth (found the mockup's own "Zone" column explicitly rejected in writing, hours sourced externally from Toggl, no certifications table despite seeded grants) and is the current source, not this row. |
| 9 | Lesson-plan taxonomy / "Tip Atelier" | Split — the 13-module taxonomy this row describes was carried forward for real (`public.modules`, confirmed live at exactly 13 rows). The ~300-real-plan lesson catalog this row also references was never modeled as a table and remains mockup-only — the still-open half is item 45 part 3, not a new gap. |
| 10 | Trainer principal/secundar per group | Implemented as described, and then some — `sessions.trainer_principal_id`/`trainer_secundar_id` are live and load-bearing across items 45, 57, 67; the real per-workshop role-assignment process is now also documented (`docs/WOWLAB_Spec_Trainer_Principal_Secundar.md`). The row marked this 🔴 with no Asana task; it shipped anyway. |
| 11 | Billing-code generator / trainer pay, separated | Split — "Plată traineri" (pay execution: confirmation, month close) is built (item 45). "Generator cod facturare" is not — still open, still correctly cited from item 39 finding 4, unaffected by this entry. |
| 12 | S3 brand shell | Implemented as described, still standing — foundational UI work, unrelated to and untouched by anything since. |
| 13 | Favicon | Done, contrary to this row's "⚪ unconfirmed" — `public/wow-lab-fav.png` exists and is wired into `app/layout.tsx`'s real metadata, confirmed live. |
| 14 | `/auth/callback` anti-scanner confirmation page | Never started, still open, no longer hypothetical — item 28's own investigation later found a real, plausible instance of exactly the failure this row was hedging against (a mail client prefetching and consuming a single-use link), without proposing this row's own mitigation. Not folded into a new item — small enough to note directly against item 28 instead. |
| 15 | Developer security review gate | Covered in full by item 72 above — not repeated here. |
| 16 | Repo visibility, return to private | Already tracked as item 16, which didn't carry this row's own two-part reopening trigger (Vercel Pro upgrade AND a more mature app stage) — folded into item 16 directly rather than duplicated here. |

**The argued verdict: mark the document superseded, don't annotate every row in place.** Fourteen of
sixteen rows are either done (1, 2, 3's billing-rule half, 5, 9's module half, 10, 12, 13), already
tracked under their own `OPEN_ITEMS.md` number (4's substance folds into item 1, 15 → item 72, 16 →
item 16), or superseded by later, more thorough work in this same register (8 → item 53, 9's
lesson-plan half → item 45 part 3, 11 → items 39/45 split). Only two rows (6, 7) named a real gap
this register didn't already carry, and both are now items 73 and 74. Annotating all sixteen rows
in place, inside a document whose own organizing frame (a mockup-era Phase 1 plan, pre-dating the
domain-by-domain rebuild this register tracks) no longer matches how work here actually gets
recorded, would mean maintaining two registers doing the same job — exactly the failure item 64
already found in `progress.md`'s own abandoned Snapshot table, and the reason that table was left
as marked history rather than kept current. A short superseded banner, added to the top of
`phase1-development-plan.md` without editing anything below it (the file's own stated convention —
*"Când se închide, se marchează ✅ și rămâne ca istoric — nu se șterge"*, close and keep as history,
don't delete), does the same job at a fraction of the maintenance cost, and points at exactly one
place — this file — for anyone who needs current status going forward.

**Small enrichments made alongside this, not separate items:** item 16 gained row 16's own
reopening trigger; item 28 gained a short note on row 14's proposed mitigation.

**Lives in:** `docs/phase1-development-plan.md` (superseded banner, top of file); item 46 below (the
AD reconciliation this pass mirrors); items 73, 74 above (the two rows that survived); item 16, item
28 (the two small enrichments); item 20, item 23, item 39, item 45, item 53, item 72 (the items that
absorbed the rest).

---

### 76. `clients.status` stuck at Prospect under signed contracts — not a stale field, a specified trigger with no code path

2026-09-18/21. Mihai noticed all three real clients (Scoala Germana, Scoala Avenor, Lycée Français)
reading "Prospect" while each held a signed contract, and asked why. Not a contradiction between two
fields, checked directly, not assumed: `changeClientStatus` (`app/(app)/clients/actions.ts`) is the
only write path to `clients.status` after creation — `addClient` hardcodes `status: "prospect"` on
every insert, no trigger touches the column, and `markContractSigned`
(`app/(app)/contracts/actions.ts`) never references `clients` at all. Signing a contract has zero
effect on the client row it belongs to, by construction, not by omission. A status nothing has ever
moved, not a status disagreeing with a contract. Mihai moved all three to `active` by hand on
2026-09-17, through the one existing manual path (below), before this item was written.

**The SAD names the trigger, and it is not the contract — checked, not assumed to be a documentation
gap.** `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §5's own lifecycle diagram:

```
[ActiveCampaign]                         [WOW LAB OS]
 lead → prospect → deal  ── Won ──▶  client (active) ──▶ contract ──▶ groups ──▶ sessions/attendance
```

— with its own text directly under it: *"Predarea e un singur punct: **Won → client activ.**"*
("The handoff is a single point: Won → active client.") Contract creation is drawn *downstream* of
the client already being active, not upstream of it. Line 76 of the same document: *"`prospect`
există ca status doar pentru clienții pre-contract care au ajuns deja în platformă"* — prospect
exists only for pre-contract clients. By the SAD's own stated logic, a client holding a signed
contract should never still read prospect at all — the three real ones doing exactly that aren't a
surprise the SAD failed to anticipate; they're the direct, predictable consequence of its own named
mechanism never being wired up.

**The mechanism was never built — checked, not inferred from its absence.** `clients.external_crm_ref`
exists (`202608100001`) and is wired to no live webhook — the same finding item 1/52 already
recorded from the opposite direction (no ActiveCampaign integration exists anywhere in this
codebase). Nothing fires on "Won." The only path that exists is the manual one: `ClientStatusControl`
(`client-header.tsx`, `/clients/[id]`), gated on `clients.convert` (held only by `sales_manager` in
`supabase/seed.sql`), driving `changeClientStatus` against a fixed transition table
(`app/(app)/clients/status.ts`): `prospect → active`, `active → paused|churned`,
`paused → active|churned`, `churned → active`. That path existed the whole time; nobody had used it
for these three until Mihai did, by hand, once asked why not.

**Worth recording as its own shape, distinct from this register's usual stale-field pattern
(items 19/21/38/40, item 71's general form).** Those are all cases where a field's *meaning* drifted
silently — a default nobody revisited, a column nothing reads, a guard nothing can trigger. This is
different: the field's meaning was written down, precisely, by the SAD, with a named trigger --
the trigger just has no code behind it anywhere, and the one fallback that does exist went unused.
**The field is not wrong. It's waiting for a mechanism that was specified and never built** -- closer
to item 2's "designed, not started" shape than to a value silently gone stale.

**Contract-driven automation was considered and rejected here, not left unconsidered.** Three
reasons, each independently sufficient:
1. **Wrong capability for the actor.** `changeClientStatus` requires `clients.convert`
   (`sales_manager` only). `markContractSigned` checks `finance.operations.* OR
   finance.reporting.* OR clients.create` -- a materially different role set. A Contract
   Administrator marking a contract signed does not hold `clients.convert` today; an automatic
   status write from that action would hand them, silently, a status change the system's own rules
   deny them directly.
2. **`CLIENT_STATUS_TRANSITIONS` would have to be duplicated or bypassed.** Duplicated means two
   places now define what a valid transition is, with nothing keeping them in sync. Bypassed is how
   a signed contract on an already-`churned` client's record could reactivate them through a path
   that never checks whether `churned → active` even makes sense in that context -- silently, with
   no guard the deliberate manual path already has.
3. **The identical second-write-path shape already named twice in this register, not a new
   concern.** `changeClientStatus`'s own comment states it directly: *"this is the only write path
   to the column today... a second write path appearing is the point to reconsider that"* -- the
   same load-bearing warning item 8 already carries for `contracts.status`, and the same shape item
   45 part 5 rejected outright for `sessions.status` (a trainer-driven transition would have given
   that column a second write path a single caller no longer reliably owns).

**Argued both ways, not settled here.** For automating `prospect → active` on contract-signed: the
SAD's actual named trigger (Won) will likely stay unbuilt for a long time -- no webhook work is
scoped anywhere in this register -- and a signed contract is the strongest already-tracked fact this
platform has that a prospect became real; a July-signed, September-starting contract sitting
labeled "Prospect" for two months is a real, visible cost, not a hypothetical one. Against it: the
SAD's own diagram places `active` at commitment (Won), not delivery, which if anything argues for
moving the trigger *earlier* than contract-signing, not *onto* it; and half-automating one of four
transitions while leaving `paused`/`churned`/reactivation fully manual is an odd middle state that
doesn't obviously beat today's fully-manual one. A status nothing ever needs by hand is exactly the
"field that says nothing" shape this register keeps finding elsewhere -- automating the one edge
that's easy to automate risks producing a milder version of that same thing, not fixing it.

**Blocked on Anca — a business decision about what "active" is supposed to mean, not a technical
one:** signature, first delivery, or the Won handoff exactly as the SAD already specifies. Whichever
she picks decides whether the fix is finishing the SAD's own designed mechanism (a real ActiveCampaign
webhook, unscoped, large), wiring a new one onto contract-signing (small, but a deliberate departure
from the SAD, not an implementation of it), or leaving the manual path as the only path and treating
today's finding as a one-time data catch-up, not a gap to close.

**Lives in:** `app/(app)/clients/actions.ts` (`changeClientStatus`, `addClient`, `markContractSigned`
in `app/(app)/contracts/actions.ts` — the confirmed absence of any link); `app/(app)/clients/status.ts`
(`CLIENT_STATUS_TRANSITIONS`); `app/(app)/clients/[id]/client-header.tsx`,
`client-status-control.tsx`; `supabase/seed.sql` (`clients.convert` → `sales_manager` only);
`docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §5 (the diagram and its "Won → client activ"
line), line 76 (`prospect`'s own definition); item 1 above, item 52 below (the same unwired
ActiveCampaign-webhook finding, from two other directions); item 8 below, item 45 below (the two
prior instances of the second-write-path shape this decision would repeat).

---

### 77. Item 52's three extension fields built — time range, address, on-site contact

2026-09-21. Item 52's closed fork (recurring stays primary, one-off workshops get the fields they
were missing as an extension) built out for the first three: time range, address, on-site contact.
Design argued before building, not decided silently — six sub-questions, each closed on its own
reasoning, one real RLS correction found and fixed along the way.

**Time range — `sessions.start_time`, nothing else stored.** `time`, nullable. End is derived at
read time (`start_time + duration_minutes`, both present or the range shows start alone) — same
precedent as contract expiry and `children_billed` (item 39): store one fact, never two that could
disagree. Not defaulted from `groups.schedule_pattern` — confirmed live that column is free text
with no enforced grammar, nothing parses it, and guessing a time out of it would silently
mis-populate real sessions. A pattern change on the group has zero retroactive effect on sessions
already created, which is correct: a session that happened at 16:00 stays recorded at 16:00 even if
the club's slot moves next term.

**Address — `clients.address` (default), `groups.address` (override), nothing on `sessions`.**
Argued directly against item 52's own volume finding: at ~4:1 recurring and widening, the dominant
case is one client address shared by every session of every group at that client — the ratio is the
argument against session-level storage, not a detail beside it. Group-level override exists for the
minority the nine-value type list names (a mall event, an off-site occasional collaboration). Both
columns plain free text, no structured parts — matches `schedule_pattern`/`age_range`'s own already-
established "no stricter shape enforced" treatment on the same tables. Resolved with
`groups.address ?? clients.address` at read time, not backfilled.

**On-site contact — `groups.on_site_contact_id → client_contacts(id)`, link only, never free text.**
Validated in the action exactly like `contract_id` already is: re-fetched, rejected if the contact's
`client_id` doesn't match the group's own — a raw FK can't express that constraint by itself.

*A real RLS gap found and corrected before this shipped, not assumed fine because a comment once
said so.* `202608250001`'s `mywork.*` branch on `client_contacts` was a bare `contact_purpose =
'trainer_facing'` row match with no session scoping at all — its own comment had already flagged it
as unverified ("re-verify the day a trainer-facing read capability is added... currently
unreachable... a paper check, not a live one"). This was that day. `202609210002` narrows it to the
identical session-scoped shape already proven twice in this codebase (`202609160001` on `users`,
`202609170001` on `clients`, item 66) — a viewer sees the contact only through a group with a
session they're actually allocated to. Checked against item 68's lesson before writing it: the
nested reads align exactly with `groups`'/`sessions`' own `mywork.*` branches for this same
viewer/capability pair, so nothing here can be silently narrowed to false the way `202609160001`'s
original `finance.operations.*` branch was.

Deliberately kept independent: linking a contact as on-site does **not** by itself make them
trainer-visible. `contact_purpose = 'trainer_facing'` is still required on top of the link — a
5th dry-run assertion (`scripts/verify_client_contacts_trainer_facing_scoping.sql`) proved this
specifically, and caught its own bug on the first run (the test update ran while still impersonating
the trainer, who holds no write capability on `client_contacts` — silently affected 0 rows; fixed by
resetting role before the write, not by weakening the assertion).

**A real capability mismatch, named, not routed around.** `client_contacts` INSERT requires
`clients.create` or `contracts.*` — Operations (`operations_manager`, who actually creates sessions)
holds neither. Since the table is empty in production, the first real one-off workshop will usually
need a brand-new contact Operations cannot create. Scoped the group/session action to **link only**
— a dropdown of the client's existing contacts — leaving contact creation exactly where it already
lives (`/clients/[id]`). Consequence stated plainly in the UI (`no_contacts_for_client_hint`) and
here: for a new one-off client with no contacts yet, someone holding `clients.create`/`contracts.*`
has to add the contact first.

**Not resolved, named instead:** the row-level grant on `client_contacts` includes `email` alongside
`phone` — no column-masking exists on this table beyond `notes`. A trainer who clears the (now
narrowed) row check sees the full contact card, not just name and phone. Left as-is, matching the
table's existing row-level convention.

**The GDPR trigger — the scheduled-execution item above got a forward pointer, not fired.**
`client_contacts` holds zero rows in production. Building this feature doesn't fire that item's own
"first real personal-data row" trigger; the first real Operations use of it will. Not reopened here.

**Verified live, in order.** Dry-run of the RLS narrowing (5/5, including the caught test bug) run
against the schema before applying. Migrations applied (`202609210001` schema, `202609210002` RLS).
`tsc --noEmit` and `next build` clean. End-to-end against `wow-lab-test-b`, real sessions, real
rendered pages (`scripts/verify_one_off_workshop_extension_fields_test_org_b.ts`, 9/9): the org
owner and an allocated trainer both see the client's default address, the linked contact's name and
phone, and the derived 16:00–17:30 time range on the same session; an unrelated trainer with no
allocation sees none of it. Fixture rows (client, contact, group, session) created and deleted by
the script each run — confirmed back to baseline after. Deployed, then the same script re-run live
against `https://app.wowlab.ro`, real `WOW LAB` org, `test+ui-owner@wowlab.dev` and
`maxdigitalro+trainer@gmail.com` (fixtures, not named teammates): 8/8 (assertion 9, the unrelated-
trainer isolation check, skipped rather than faked — no second WOW LAB trainer fixture with a
working auth identity was available, per item 70; that exact isolation is what Test Org B's own 9/9
already proved). `WOW LAB`'s own counts (3 clients, 2 groups, 0 sessions, 0 `client_contacts`)
confirmed unchanged before and after — `client_contacts` is still genuinely zero, so the
scheduled-execution trigger noted above has still not fired.

**Scope cut, stated rather than silently dropped:** address override and on-site contact are
edit-only on `groups` — not offered on the group *create* form (`groups-client.tsx`), only via
`group-info-section.tsx`'s existing edit flow, to avoid fetching every client's contacts org-wide
into the groups list page for a field most groups won't set at creation. `schedule_pattern` shown as
inline hint text next to the new start-time field was planned in the design pass and cut for the
same reason — not built.

**Lives in:** `supabase/migrations/202609210001_add_one_off_workshop_extension_fields.sql`,
`202609210002_narrow_client_contacts_trainer_facing_branch.sql`, and their rollbacks;
`scripts/verify_client_contacts_trainer_facing_scoping.sql`,
`scripts/verify_one_off_workshop_extension_fields_test_org_b.ts`; `app/(app)/groups/actions.ts`
(`updateGroup`, `addSession`), `app/(app)/clients/actions.ts` (`addClient`, `updateClient`);
`app/(app)/groups/[id]/page.tsx`, `group-info-section.tsx`, `group-detail-client.tsx`;
`app/(app)/clients/[id]/page.tsx`, `client-info-client.tsx`, `clients-client.tsx`;
`app/(app)/groups/i18n.ts`, `app/(app)/clients/i18n.ts`; item 52 below (the closed fork this
extends); item 66, item 68 above (the RLS precedent and the lesson checked against); item 39 below
(the derived-not-stored precedent for time range).

---

### 78. Item 76 resolved — a client is active once it has a signed contract, derived not stored

2026-09-21. Anca's decision, closing item 76's "blocked on Anca" fork: a client is active once it
has a signed contract. Built as a derivation, not a write from `markContractSigned` — argued both
shapes before building, chose derived, reported to Mihai before writing any code.

**Why derived, not stored.** Three reasons: (1) `markContractSigned` is gated `contracts.*` /
`finance.operations.*` / `finance.reporting.*` / `clients.create` — **not** `clients.convert`
(`sales_manager`-only, `seed.sql`). Checked live: `contract_administrator` holds `contracts.*` but
not `clients.convert`. A direct write from `markContractSigned` would hand a Contract Administrator
a status change the capability model reserves for Sales — the identical wrong-capability-for-the-
actor shape item 76 itself already named. (2) A stored write forces an undecided sub-question
(should a contract signed on an already-`churned` client silently reactivate them?) that the derived
shape never has to answer — an override always wins, full stop. (3) `changeClientStatus`'s own
comment already states this column has exactly one write path and flags a second one appearing as
the point to reconsider — the same shape item 8 (`contracts.status`) and item 45 part 5
(`sessions.status`, rejected) both already carry.

**Built:** `public.client_effective_status(clients)` — a `security definer` SQL function exposed as
a PostgREST computed column (`202609210003`). `paused`/`churned` stored values always win as manual
overrides; every other stored value (including the 3 real clients' legacy literal `'active'`, set by
Mihai's 2026-09-17 manual move) falls through to `exists(signed contract) ? 'active' : 'prospect'`.
`security definer`, not a plain RLS-scoped join — checked against item 68's lesson first: `clients`'
own SELECT policy (`202609170001`) has a `mywork.*` branch (session-scoped trainer visibility) that
`contracts`' SELECT policy has no equivalent of at all, so a plain embed would have silently shown
"Prospect" to a trainer regardless of truth. `markContractSigned` remains untouched — still never
references `clients`, confirmed by inspection after the change, not just before.

`CLIENT_STATUS_TRANSITIONS` (`app/(app)/clients/status.ts`) lost its `prospect: [active]` edge —
that transition is automatic now, not a button, so a true prospect shows zero action buttons (proven
live, assertion 3 below). `paused`/`churned → active` ("reactivate") writes the literal sentinel
`'prospect'`, not `'active'` — `changeClientStatus` translates `newStatus === "active"` to
`writeValue = "prospect"` before writing. Always correct on every reachable path: `paused`/`churned`
can only be reached from derived-active, which required a signed contract, and nothing in this
system ever un-signs one (item 8's own dead-branch finding), so reactivate always re-derives to
Active in practice — proven live, assertions 9–10 below.

**Left the 3 real clients correct, confirmed before and after, not assumed.** Live query before
building: all 3 (Scoala Avenor, Scoala Germana, Lycée Français) hold stored `status = 'active'` and
each has a `contracts.status = 'signed'` row — both facts checked directly. The derivation treats a
legacy stored `'active'` identically to `'prospect'` (neither is an override), falling through to
the same signed-contract check — same displayed answer, no migration/backfill needed or done.

**Verified live, not just dry-run.** SQL dry run (rolled back): paused-override-wins-over-signed-
contract, real-prospect-stays-prospect, legacy-active-value-falls-through-correctly — 3/3. End-to-end
against real rendered pages in WOW LAB Test Org B, first on local dev, then unchanged and re-run
against the actual deployed production code at `app.wowlab.ro`
(`VERIFY_SITE_URL=https://app.wowlab.ro`, `scripts/verify_client_effective_status_test_org_b.ts`) —
10/10 both times: prospect shows no action buttons, adding a signed contract flips list+detail to
Active with zero writes to `clients.status`, pausing overrides the still-signed contract, reactivating
writes the literal `'prospect'` sentinel yet re-renders Active. This closes the deploy-timing gap a
purely read-only production check against the 3 real WOW LAB clients couldn't: those 3 rows render
identically under old and new code (both already said Active), so passing there didn't prove the new
code path was live — disposable fixtures in WOW LAB itself to force a real distinguishing case were
correctly refused by the permission system as a shared-resource write; WOW LAB Test Org B against the
real production deployment is the same code path with none of that risk, and is what closes it.
Confirmed separately, read-only, against the 3 real WOW LAB clients too: `/clients` and all 3 detail
pages render Active, no regression.

**i18n:** none needed. Same 4 status labels (`status_prospect/active/paused/churned`) and 3 action-
button labels (`status_action_active/paused/churned`) already in `clientsDict` — this changes how the
value is computed, not any user-facing string.

**Lives in:** `supabase/migrations/202609210003_add_client_effective_status_derivation.sql` and its
rollback; `app/(app)/clients/status.ts` (`CLIENT_STATUS_TRANSITIONS`), `actions.ts`
(`changeClientStatus`), `page.tsx` and `[id]/page.tsx` (both aliasing `status:client_effective_status`);
`scripts/verify_client_effective_status_test_org_b.ts`; item 76 above (the finding this resolves);
item 8 below, item 45 below (the second-write-path precedent); item 68 above (the RLS lesson checked
against).

---

### 79. `delivery_format` → nine-value list — mapped, not migrated (Anca's instruction) — BUILT 2026-09-21, see item 85

2026-09-21. Anca decided the nine workshop types item 52 below already verified from source
(`Fielduri pentru planificare ateliere.xlsx`), corrected — **Săptămâna Verde**, not the source's
literal "Scoala Verde"; **Wow Lab Party** as the single deduplicated value item 52 already derived
from the raw ten-line dropdown — replace `delivery_format`'s six values. Investigation only, reported
to Mihai, nothing built or migrated, exactly as instructed.

**Every current reader, found by grep across the whole codebase:**
- Display labels (`groups-client.tsx`, `group-info-section.tsx`) — one `format_${value}` i18n key per
  exact value.
- Resources caption (`trainer-resources-section.tsx`) — **binary only**: `deliveryFormat !== "recurring"`,
  not per-value.
- Duration multiplier (SAD §12.6/12.7, `app.resolve_duration_multiplier`, `202608310002`) — SQL
  `case when p_delivery_format in ('scoala_altfel','saptamana_verde') then ... ×2 else ×1.5`. **No app
  code calls this function anywhere** — checked directly, the only hits outside its own migration are
  `scripts/verify_payment_config_tables.sql`. Fully specified, never wired to payroll.
- Payroll (`app/(app)/payroll/*`) — **nothing**. Zero references to `delivery_format` anywhere.
- Masking (`docs/WOWLAB_SAD_Field_Masking.md`) — **nothing**. Zero mentions.
- `business_line` — its own `state_schools` i18n label already reads *"(Școala Altfel / Săptămâna
  Verde)"*, a pre-existing redundancy with `delivery_format` at a coarser grain, unaffected either way.

**Live rows, checked directly, both orgs:** WOW LAB has 2 groups, both `recurring` (Lycée Français).
WOW LAB Test Org B has 1 group, `corporate` (client "MAX," a test fixture). **`custom`: zero rows,
anywhere, ever** — confirms the task's own prediction. No `scoala_altfel`/`saptamana_verde`/`party`
rows exist live either.

**Mapping the 6 onto the 9:**
- **Clean 1:1** — `scoala_altfel` → *Scoala Altfel*; `saptamana_verde` → *Săptămâna Verde* (the exact
  pair item 52 flagged "close enough, not confirmed" — now confirmed).
- **Clean by observed data, not enforced** — `recurring` → *Scoli private (colaborări recurente)*.
  True for both live rows, but nothing in the schema stops a `recurring` group at a state school,
  which this specific target has no room for.
- **Splits, no single target** — `party` → *Wow Lab Party* or *Party in companii* (venue not captured
  today). `corporate` → *Parteneriate cu companii*, *Party in companii*, or arguably *Evenimente/
  prezentari la mall* (nature of engagement not captured). The one live `corporate` row is a test
  fixture, not a real ambiguity.
- **No home** — `custom`: the nine-value list has no catch-all. Zero live rows, so no live-data cost,
  but the overflow bucket disappears structurally.
- **Nothing maps in** — 3 of the 9 have no current equivalent: *Cursuri deschise*, *Scoli private
  (colaborări ocazionale)*, *Evenimente/prezentari la mall*. Today these would all be forced into
  `corporate` or `custom`.

**What a migration would do to live data:** the 2 real production rows map cleanly and unambiguously.
The 1 ambiguous row is test-org fixture data, not a real record needing a decision. Migrating today
costs zero real ambiguity. **Does any rule change meaning:** only the ×2 duration multiplier is keyed
on these values, and it's keyed on exactly the two values that map 1:1 — relabeling its `case when`
preserves meaning exactly, and it has no live caller today, so even that edit is currently zero-risk.
The resources caption's binary check also survives unchanged, since "recurring" still maps to exactly
one target value.

**Still Anca's, not settled here:** whether/when to actually migrate. This item records the mapping
so that decision, whenever made, isn't also a research task.

**Lives in:** item 52 below (the verified nine-value source and the volume fork this extends);
`app/(app)/groups/i18n.ts`, `groups-client.tsx`, `group-info-section.tsx`, `trainer-resources-section.tsx`;
`supabase/migrations/202608130001_create_groups_sessions_domain_tables.sql` (the live 6-value CHECK
constraint, untouched), `202608310002_payment_config_tables.sql` (`app.resolve_duration_multiplier`);
`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12.6/12.7.

---

### 80. Catalina (operations_manager) can now create and edit client contacts

2026-09-21. Anca's decision: Catalina should be able to create client contacts. Confirmed live before
building: `operations_manager` holds `operations.*`, `clients.read`, `contracts.read`,
`trainers.allocate`/`substitute`, `calendars.*`, `groups.create`, `sessions.create` — not
`clients.create` or `contracts.*`, the two capabilities that gated `client_contacts` INSERT/UPDATE/
DELETE (`202609110001`) — so she genuinely could not, before this.

**Capability granted: `operations.*`** — not a new grant, already held by `operations_manager` alone
(confirmed live, no other role holds it in `seed.sql`), added as a fourth alternative to the existing
INSERT/UPDATE predicate (`clients.create OR contracts.* OR operations.*`, plus owner/platform owner).

**EDIT: yes**, for the named real need (correcting a phone typo) — bundled with INSERT, same
granularity this table's other capability branches already use. **DELETE: deliberately not granted** —
no argued need beyond what EDIT already covers; stays with the existing owners (Sales/Contract
Administrator/org owner). This required splitting the page's single `canManage` flag (previously
covering create+edit+delete identically, because all three policies shared one predicate) into
`canEditContacts`/`canDeleteContacts` — getting this wrong would have shown Catalina a Delete button
RLS silently rejects, a broken affordance rather than a hole.

**Finance segregation confirmed unweakened, by construction and by a live negative test, not just by
argument.** Only the INSERT/UPDATE policies were touched; the SELECT policy (where the finance
client-type segregation actually lives, `202608250001`) was not edited at all. Verified live in WOW
LAB Test Org B against a fixture holding BOTH `contracts.*`/`clients.read` (which would otherwise
satisfy the broader non-finance SELECT branch) AND `finance.operations.*` (which excludes them from
it) — confirmed they still cannot see a `corporate`-type client's contact, despite the broader
capabilities this migration also touches.

**Verified live.** SQL dry run (rolled back), `scripts/verify_operations_client_contacts_write.sql`:
operations_manager can INSERT and UPDATE, cannot DELETE; a trainer cannot INSERT; finance segregation
holds for a user who also holds `contracts.*` — 6/6. Rendered-page proof in WOW LAB Test Org B, first
on local dev, then unchanged and re-run against the actual deployed production code at `app.wowlab.ro`
(`NEXT_PUBLIC_SITE_URL=https://app.wowlab.ro`, `scripts/verify_operations_client_contacts_ui_test_org_b.ts`)
— 6/6 both times: the create button and an edit action render for the operations manager, no delete
action renders; a trainer with no allocated session at the client sees neither the client nor its
contacts. The production run is what actually proves this code path is live, not just that WOW LAB's
3 real client pages didn't regress (separately smoke-checked, also clean) — same reasoning as item 78's
own production-verification note.

**i18n:** none needed — the same create/edit/delete controls and labels already exist; this changes
which roles reach them, not any string.

**Lives in:** `supabase/migrations/202609210004_grant_operations_client_contacts_write.sql` and its
rollback; `app/(app)/clients/[id]/page.tsx` (`canEditContacts`, `canDeleteContacts`, replacing the
single `canManageContacts`), `client-contacts-client.tsx` (`canEdit`/`canDelete` props),
`actions.ts` comment; `scripts/verify_operations_client_contacts_write.sql`,
`verify_operations_client_contacts_ui_test_org_b.ts`; item 37 below, `202609110001`,
`202608250001` (the write/read policy history this extends).

---

### 81. Open question for Anca — should payroll-closing see a client's name regardless of finance segment?

2026-09-21. Recorded as still open, not answered by this round's work — item 65 above found it,
argued it, and deliberately left it: a `finance.operations.*`-only closer (Laura's shape) sees
"Unknown" instead of a client's name for any session outside `private_school`/`parent_b2c`, because
`clients`' own SELECT policy segregates by the same client-type split `finance.reporting.*` uses on
the other side. This intersects a documented, deliberate business boundary (which finance role bills
which segment) — not a bug to patch by grafting on another RLS branch the way the trainer-name gap
(item 66 above) was. **Currently inert**, unchanged since item 65: `sessions` still holds zero rows
in `WOW LAB` (re-confirmed live during this round's Part 2 investigation, item 79 above), so no
client-type mix exists yet for this to actually bite on.
**The question, for Anca directly:** should whoever closes payroll see every client's name regardless
of billing segment, or should payroll-closing stay scoped to someone who already holds
`finance.reporting.*` too (sidestepping the question by construction)?
**Lives in:** item 65 above (the full finding and its own "blocked on" note, unchanged); item 20 below
(Laura's `finance.operations.*`-only capability set); `app/(app)/payroll/page.tsx`.

---

### 82. Open question for Anca — are corrections allowed after an invoice has already been issued?

2026-09-21. Recorded as still open, not answered by this round's work. Item 45 below (part 5) already
named this precisely, in passing, while resolving a different, narrower question (who can correct a
session confirmation before/after month-close): Anca's answer there means "closed" means closed to
the *trainer*, not frozen — the record stays open to Laura/Anka indefinitely, and the invoice, by her
own description, is issued from a month that can still change afterward if a correction happens. That
is a real, deliberate difference from AD-10's frozen-snapshot model (`docs/AD10...`, never in the
repo, item 46 below) — she was not asked to approve AD-10 and did not.
**The question, for Anca directly, is more specific than the one already answered:** if a correction
happens *after* an invoice has actually gone out (not just after the month closes), does anything
special need to happen — a new adjustment line on the next period with reason/approver, matching
AD-10's own audit-trail concern, or does today's open-indefinitely-to-Laura/Anka shape already cover
it? Item 45 named this gap; it does not resolve it.
**Lives in:** item 45 below (the exact passage this restates as a standalone question, part 5's
`correctSessionConfirmation`/`finance.operations.*` finding); item 46 below (AD-10's own
frozen-statements/adjustment-line model, for comparison).

---

### 83. Item 78's `'prospect'` sentinel means "no override," not what the column's name says — RESOLVED 2026-09-21: renamed to `status_override`

2026-09-21. Mihai's own objection to item 78, checked exhaustively before arguing anything: after
that item's derivation, `clients.status` can hold the literal string `'prospect'` for a client that
computes as Active. Worse than the report below first assumed — it isn't only `'prospect'` that's
compromised. `client_effective_status()`'s own case expression (`202609210003`) treats exactly two
values as real, trustworthy overrides — `'paused'`, `'churned'` — and **everything else** falls
through to the contract check, `'active'` included. The 3 real rows still hold the literal string
`'active'` today; that happens to produce the right answer, by coincidence of which write came last,
not because the value carries meaning. Of the 4 values the CHECK constraint still permits, only 2
retain any literal meaning. The other 2 are indistinguishable synonyms for "no override" — which
one a row happens to hold is historical accident, not signal.

**Every reader of the raw column, found by exhaustive grep, not sampled:**
- **App code** — every `clients` select in `app/`, enumerated (15 call sites across
  clients/contracts/groups/payroll). Exactly two select the `status` column at all: the two page.tsx
  queries item 78 already aliased to `status:client_effective_status` (correct — they read the
  computed value, not the raw one), and `changeClientStatus`'s own read, which selects raw `status`
  only to feed the `.eq("status", current.status)` optimistic-concurrency guard on its own write — it
  never treats that value as "the" status; `CLIENT_STATUS_TRANSITIONS` is looked up by
  `effective_status` already, per item 78's own design. No other call site selects `status` at all
  (confirmed by reading each of the other 13). **App code is not wrong today** — checked, not assumed.
- **RLS policies, every table** — grepped for `clients.status`/`cl.status`/any status-keyed subquery
  against `clients` across every migration. None. No policy anywhere reads this column.
- **Views** — the only `c.status` hits found are `contracts_billing_masked`'s family of migrations,
  where `c` aliases `public.contracts`, not `clients` — confirmed by reading the view's own `FROM`
  clause, not assumed from the alias letter. No view selects `clients.status`.
- **Filters / the `/clients` status dropdown** — `clients-client.tsx`'s filter operates on
  `client.status`, which arrives from page.tsx already carrying the computed value (same alias as
  above) — correct. The dropdown's own option list (`CLIENT_STATUSES`, minus `prospect`) is a static
  local literal, unaffected either way.
- **`db/tests/`, `scripts/*.sql`** — grepped for any assertion keyed on `clients.status`'s raw value.
  None found.
- **Not asked for, found anyway, and the real risk:** anyone with direct database access — Supabase
  Studio's Table Editor, `supabase db query --linked`, any future ad hoc report or export — sees the
  literal stored value with nothing distinguishing it from a genuine status. This is not fixable by
  code discipline, because it isn't code: a person looking at the table, or a script written by
  someone who doesn't know `client_effective_status()` exists, reads `'prospect'` and reasonably
  believes it. **This is the actual failure mode item 78 introduced** — not a bug in the app today,
  a trap for the first reader who reasonably assumes a column means what it's named.
- **Documentation:** `docs/DATABASE_CONVENTIONS.md` §12 cites `clients.status = 'churned'` as its
  worked example of the status-replaces-delete convention — still accurate; `'churned'` is one of the
  two values that kept its literal meaning. `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`'s own
  description of `prospect` (quoted in item 76 above: *"prospect exists as status only for pre-
  contract clients"*) is now stale for a raw reader of the column, for the reason this item names.

**The redesign, argued.** Two shapes were on the table.
1. *Keep the name, make the raw column unreachable except through the computed one* (e.g. `REVOKE
   SELECT` on `status` from `authenticated`, matching the precedent already used for
   `client_contacts.notes`, `202608250001`). **Rejected.** It only protects PostgREST/`authenticated`
   sessions — the actual risk named above is Supabase Studio and `supabase db query`, both of which
   connect as a privileged role that a table-level `REVOKE` from `authenticated` does not touch. It
   would fix the reader that was never actually wrong (app code, already routed through the computed
   column) and leave the one that is wrong (direct database access) completely unprotected.
2. **Chosen: rename the column to what it now holds, and make illegal what it no longer means.**
   `status` → `status_override` (exact name TBD, open to a better one), nullable, `CHECK
   (status_override IS NULL OR status_override IN ('paused', 'churned'))` — `'prospect'`/`'active'`
   stop being legal values for this column at all, because they were never a real value here, only a
   sentinel for "nothing." `NULL` replaces item 78's own `'prospect'`-as-sentinel trick outright — a
   genuine simplification, not just a rename: `changeClientStatus`'s reactivate edge would write a
   literal `NULL` instead of the borrowed string `'prospect'`, closing the exact "writes prospect,
   displays Active" indirection item 78's own text already flagged as the one non-obvious edge.
   `client_effective_status()`'s case expression becomes `status_override IS NOT NULL → status_override
   ELSE (signed contract ? active : prospect)` — clearer, not just relabeled. A rename protects every
   reader uniformly — Table Editor, `psql`, `service_role`, `authenticated`, all see the same renamed
   column, so nobody can mistake it for "the status" by habit, the same way a differently-named
   column already protects `billing_rule`/`estimated_value` from being read as public data without
   anyone needing to remember a grant exists. Blast radius is small and already mapped by the audit
   above: 3 app-code call sites, the computed-column function, one migration (rename + constraint +
   backfill the 3 real rows' literal `'active'` to `NULL` — no behavior change, since `NULL` and
   `'active'` already compute identically under item 78's derivation).

Matches this register's own most-repeated pattern by name, not by coincidence — a stored value whose
name no longer matches what it holds (item 21, `users.status`; item 76, `clients.status` before item
78; now `clients.status` again, introduced by the very fix that closed item 76). Recorded as its own
general item, 84 below.

**Built exactly as recommended (`202609210005`).** `clients.status` → `clients.status_override`,
nullable, `CHECK (status_override IS NULL OR status_override IN ('paused', 'churned'))` — `'prospect'`
and `'active'` are no longer legal values anywhere on this column, confirmed live: writing the literal
`'active'` to `status_override` is now rejected by the constraint (assertion 2 of the dry-run script
below). `client_effective_status()` (item 78) updated in place, same shape, new column name.

**Acceptance test: every real row's effective status, before and after, all 4 rows, both orgs — not
sampled.** Captured live before the migration, re-derived live after:

| Org | Client | Stored before → after | Effective before → after |
|---|---|---|---|
| WOW LAB | Scoala Avenor | `'active'` → `NULL` | active → active |
| WOW LAB | Scoala Germana | `'active'` → `NULL` | active → active |
| WOW LAB | Lycée Français | `'active'` → `NULL` | active → active |
| WOW LAB Test Org B | MAX | `'prospect'` → `NULL` | prospect → prospect |

No paused/churned rows existed live anywhere at migration time. Every row's effective status is
byte-identical before and after — the rename changed no visible status anywhere, which was the whole
acceptance test, not a side observation.

**`changeClientStatus` (`app/(app)/clients/actions.ts`) rewritten, not patched.** Reads
`status_override` (only to guard its own write against a race, never as "the" status — unchanged from
item 78's own discipline). Writes: `'paused'`/`'churned'` pass through; the reactivate edge
(paused/churned → active) now writes literal `NULL` — item 78's `'prospect'`-as-sentinel indirection
is gone outright, not renamed. The optimistic-concurrency guard is NULL-safe: `.eq(col, null)` builds
`= NULL`, which SQL never matches, even against an actually-NULL row — the guard branches to `.is()`
when the current value is `NULL`, `.eq()` otherwise. `addClient` no longer writes any override on
create — the column has no default now (an explicit design choice: NULL, "no override," is what a new
client should start with, matching the old default's own meaning exactly, just honestly this time).
`CLIENT_STATUS_TRANSITIONS` (`status.ts`) unchanged in shape (still keyed by effective status, for the
button-set lookup) — its comment now says plainly that its *values* describe override targets, not
statuses, since `status_override` itself can never hold `'prospect'`/`'active'`.

**`row_history` note, in the migration header, not just here:** entries with `changed_at` before this
migration carry the key `"status"` with one of the 4 original literal values (including Mihai's
2026-09-17 manual moves to `'active'`) — entries after carry `"status_override"` instead, `'paused'`/
`'churned'`/`null`. No single query reads both sides uniformly; filter by `changed_at` and read the
correct key per side.

**Rollback is explicitly lossy, stated in its own header, not silently approximate.** It cannot recover
whether a `NULL` row was `'prospect'` or `'active'` before — that distinction was deliberately erased
by the forward migration itself. Rolling back backfills every `NULL` to `'prospect'` (the schema's
original default, not a recovered fact) — for the 3 real WOW LAB rows, which were actually `'active'`,
running the rollback would be a real step backward on the raw column, said plainly in the rollback file
so nobody trusts it as a true undo. What survives exactly: `paused`/`churned` values, and every
client's derived status, since `client_effective_status()` never depended on which of prospect/active
the raw column said.

**Verified live, both dry-run and end-to-end, then on the real deployment.** Dry run
(`scripts/verify_clients_status_override_rename.sql`, rolled back) against the real data above — 1/1
(all 4 rows identical) + 1/1 (the new constraint rejects `'active'`). End-to-end against all 5 named
cases — prospect, signed-contract (active), paused, churned, reactivated — in WOW LAB Test Org B,
checking BOTH the rendered page AND the raw `status_override` value directly at every step
(`scripts/verify_clients_status_override_rename_test_org_b.ts`): 10/10 on local dev, then unchanged and
re-run against the actual deployed code at `app.wowlab.ro` — 10/10 again, same discipline items 78/80
already established for closing the deploy-timing gap. At every one of the 5 steps, `status_override`
held either `NULL` or a real override — never a status word.

**i18n:** none needed — same 4 display labels, same 3 action-button labels; this only changes storage.

**Lives in:** item 78 above (the derivation this corrects); item 21 below, item 76 above, item 84
below (the named pattern this repeats, now recorded generally);
`supabase/migrations/202609210005_rename_clients_status_to_status_override.sql` and its rollback;
`app/(app)/clients/status.ts`, `actions.ts` (`changeClientStatus`, `addClient`), `clients-client.tsx`
(`CLIENT_STATUSES` comment); `scripts/verify_clients_status_override_rename.sql`,
`verify_clients_status_override_rename_test_org_b.ts`; `docs/DATABASE_CONVENTIONS.md` §12 (the
`clients.status = 'churned'` reference, confirmed still accurate — `'churned'` never stopped meaning
what it says).

---

### 84. General lesson — a stored value that stopped meaning its name is fixed by renaming it, not by guarding it, because the misreading happens outside the app

2026-09-21. The general form behind item 83's fix, recorded on its own so the next instance of this
shape gets recognized faster than this one was. This register's single most-repeated failure family
(item 21, `users.status`; item 76, `clients.status` before item 78; item 83, `clients.status` again,
introduced by the very fix that closed item 76) has one recurring cause: a column keeps its original
name after a change makes some of its legal values stop meaning what the name says, and every reader
*inside* the app gets updated to route around that — while the column itself still looks, to anyone
who hasn't read the fix, like it means what it always meant.

**The fix that doesn't work: gate the column, keep the name.** Item 83 considered and rejected this —
`REVOKE SELECT` on the raw column from `authenticated`, or an equivalent grant-based lockout, protects
only sessions going through that grant (PostgREST/the app). It does nothing for Supabase Studio's Table
Editor, `supabase db query`, or any future script connecting with a privileged role — which is where
the actual misreading happens, because a person or a script assumes a column named `status` holds a
status. **No code-layer discipline reaches a human looking directly at the schema.**

**The fix that works: rename the column to what it now holds.** A rename is visible to every reader
uniformly — Table Editor, `psql`, `service_role`, `authenticated`, all see the identical renamed
column, so nobody can mistake it for its old meaning by habit. This is the same principle
`billing_rule`/`estimated_value` already rely on (protected from being read as public data by living
behind a masking view, not by a grant someone has to remember exists) — applied here to a column's own
*name* rather than its access path.

**When this applies:** any time a fix changes what a stored value means without changing what it's
called — a derivation added on top of a column that used to be the literal answer (item 78's own
shape), a status value redefined to serve two purposes, a flag whose true/false stopped mapping to
what the field name implies. The test: would a person with raw database access, who has not read the
migration that changed this, draw the wrong conclusion from the column's current name and value? If
yes, gating access is not the fix — renaming is, because the reader that matters is the one no grant
or app-layer check can reach.

**Lives in:** item 83 above (the concrete instance this generalizes); item 21 below, item 76 above
(the two prior instances of the same shape, both left as gate-or-ignore rather than renamed at the
time); item 71 above (a different general form — a cleared blocker leaving no trace — worth
distinguishing: that one is about a register entry going stale, this one is about a *column* going
stale while its entry stays accurate).

---

### 85. Item 79's mapping built — `delivery_format` migrated to Anca's nine workshop types

2026-09-21. Anca decided; item 79 above did the investigation and found it lower-risk than it
looked (no live caller on the duration multiplier, payroll/masking read nothing from this field,
`custom` has zero live rows) — this item is the build.

**The nine, keys ASCII snake_case (Mihai's instruction), labels carrying the diacritics in
`app/(app)/groups/i18n.ts`, RO and EN:** `scoala_altfel` (Școala Altfel), `saptamana_verde`
(Săptămâna Verde — Anca's own naming, matching the schema's existing key, not the source
spreadsheet's literal "Scoala Verde" item 52 originally quoted), `wow_lab_party` (Wow Lab Party),
`parteneriate_companii` (Parteneriate cu companii), `cursuri_deschise` (Cursuri deschise),
`scoli_private_ocazionale` (Școli private, colaborări ocazionale), `scoli_private_recurente` (Școli
private, colaborări recurente), `evenimente_mall` (Evenimente/prezentări la mall), `party_companii`
(Party în companii). `scoala_altfel`/`saptamana_verde` keep their exact prior literal strings — same
program, same key, only the surrounding list was confirmed (same reasoning item 83 used for
`paused`/`churned` surviving the status rename unchanged).

**Every existing row, reported before the migration was written, not defaulted:** exactly 3 rows
exist across both orgs, confirmed live immediately before writing the migration.

| Org | Client | Module | Old value | New value |
|---|---|---|---|---|
| WOW LAB | Școala Franceză (Lycée Français, `private_school`) | wow_mix | `recurring` | `scoli_private_recurente` — clean, not just by the general rule: this row's own client is a private school with an ongoing relationship |
| WOW LAB | same client | wow_mix | `recurring` | `scoli_private_recurente` — same reasoning |
| WOW LAB Test Org B | MAX (`corporate`) | green_energy | `corporate` | **splits three ways** — `parteneriate_companii` / `party_companii` / `evenimente_mall`, nothing on the row distinguishes them |

**The split, flagged before building, resolved by Mihai, not defaulted.** Asked directly rather than
guessing: chose `parteneriate_companii`. No `scoala_altfel`, `saptamana_verde`, `party`, or `custom`
rows exist live anywhere, so those three old values had nothing to migrate.

**Recurring, confirmed: `scoli_private_recurente` only.** Matches Mihai's own reading exactly — none
of the other eight (including `scoala_altfel`/`saptamana_verde`, which were never "recurring" in this
sense even under the old six-value list). Updated both places this distinction lives:
`app/(app)/groups/[id]/trainer-resources-section.tsx` (`isOneOff`, the feedback-form caption) and
`groups-client.tsx` (`isRecurring`, the create form's schedule-pattern shape — day+time vs.
date+time). Found and fixed a real staleness while updating the caption itself:
`resources_feedback_form_optional`'s own text hardcoded example values ("Școala Altfel, Săptămâna
Verde, corporate, parties") that no longer exist under the new vocabulary — rewritten around the
actual rule ("required for one-off workshops — optional only for recurring private-school
collaborations") instead of an example list that would drift again the next time the vocabulary does.

**Duration multiplier: re-keyed, not silently orphaned.** `app.resolve_duration_multiplier`
(`202608310002`) still has no live caller anywhere in app code — reconfirmed fresh, unchanged since
item 79. The two literal strings it matches (`scoala_altfel`, `saptamana_verde`) are unchanged by this
migration, so its `case when` didn't need new values — but it was still `CREATE OR REPLACE`'d with an
explicit comment recording that re-confirmation, so the day a payroll calculation finally calls it,
whoever's reading finds the check already done, not a silent assumption. Instruction: "re-verify this
comment the day a payroll calculation actually calls this function for the first time."

**`business_line` overlap, reported, not reconciled — both decisions stand, they answer different
questions.** `business_line`'s own `state_schools` value is labeled *"(Școala Altfel / Săptămâna
Verde)"* — a coarser-grained version of exactly the new list's first two entries.
`business_line_recurring_private_schools` overlaps `scoli_private_recurente`.
`business_line_corporate_events` overlaps the remaining company/event-flavored values
(`wow_lab_party`, `parteneriate_companii`, `evenimente_mall`, `party_companii`) as a group, not 1:1.
This redundancy already existed between `business_line` and the old `delivery_format` (nothing ever
enforced they agree); the new vocabulary doesn't create it or fix it, just changes which words sit on
the more granular side. Not reconciled — Anca decided both fields for different reasons, and this
item doesn't second-guess either.

**No catch-all value.** Item 79 already flagged `custom`'s old escape-hatch role as having no
equivalent in the nine — not invented here either. Anca's decision was "these nine replace the six,"
not "these nine plus a fallback." A workshop that genuinely fits none of the nine is now a real gap
to surface, not silently absorbed.

**Acceptance test: every row, before and after, nothing unintended changed — same discipline as item
83's status rename.** Dry run against the real live data
(`scripts/verify_groups_delivery_format_nine_types_migration.sql`, rolled back): all 3 rows mapped
exactly as the table above states, zero rows outside those 3 touched, and writing the old literal
`'recurring'` is rejected by the new constraint — 2/2. Applied for real, then re-queried live: matches
the dry run exactly, byte for byte.

**Found and fixed while verifying, not part of the original scope but left broken would defeat the
point of touching the file at all.** `db/tests/rls_groups_sessions.sql`'s own header claims "safe to
re-run at any time" — its `delivery_format` fixture literals (`'recurring'`, `'party'`, `'custom'`)
would have silently broken that claim the moment this migration shipped, so they're updated
(`'recurring'` → `scoli_private_recurente`, `'party'` → `wow_lab_party`, `'custom'` → an arbitrary
valid replacement, `cursuri_deschise` — these points don't test format-specific behavior). Discovered
in the same pass, unrelated to this migration but blocking its own sanity check: both
`db/tests/rls_groups_sessions.sql` and `rls_clients_contracts.sql` still inserted a bare `status`
column into `public.clients`, broken since item 83 renamed it to `status_override` — fixed (the column
is simply omitted now, same as `addClient`'s own fix in item 83, since none of these fixtures test
status semantics). A THIRD, older staleness was found and left alone, out of scope for both this task
and item 83: `db/tests/rls_clients_contracts.sql` also references `contracts.contract_number`, dropped
in favor of `entry_number`/`exit_number` back in `202608180002` — predates both this item and item 83,
not fixed here, named so it isn't mistaken for something this round already covered.

**Verified live, local dev then the real deployment, same discipline as items 78/80/83.**
`scripts/verify_groups_delivery_format_nine_types_test_org_b.ts` against WOW LAB Test Org B: the real
migrated MAX/green_energy row renders "Company partnerships," a fresh `scoli_private_recurente` group
shows the optional caption, a fresh `wow_lab_party` group shows the required caption (proving the
split is keyed on `scoli_private_recurente` specifically, not a substring check), the list page
renders the new label — 7/7 on local dev, 7/7 again against the real `app.wowlab.ro` deployment.

**i18n:** `format_*` keys fully replaced (6 → 9, `app/(app)/groups/i18n.ts`); one caption rewritten
(`resources_feedback_form_optional`, the stale-example fix above). Both RO and EN.

**Lives in:** item 79 above (the investigation and mapping this builds);
`supabase/migrations/202609210006_migrate_groups_delivery_format_to_nine_workshop_types.sql` and its
rollback (a true undo this time — 3 known rows by id, no lossy backfill, unlike item 83's);
`app/(app)/groups/i18n.ts`, `groups-client.tsx` (`FORMAT_KEYS`, `isRecurring`),
`[id]/trainer-resources-section.tsx` (`isOneOff`); `scripts/verify_groups_delivery_format_nine_types_migration.sql`,
`verify_groups_delivery_format_nine_types_test_org_b.ts`; `db/tests/rls_groups_sessions.sql`,
`rls_clients_contracts.sql` (the incidental `status`→`status_override` fix); item 83 above (the same
acceptance-test discipline, and the second write path that broke `db/tests` unnoticed until now).

---

### 86. Every `db/tests/` and `scripts/verify_*.sql` file, actually run — a fourth and fifth instance found, two fixed, none of the rest touched

2026-09-22. Mihai's own finding: `rls_clients_contracts.sql` inserts `contracts.contract_number`,
dropped 2026-08-18 — it cannot have run successfully since. Asked to run every file in both
directories for real and report pass/fail, not what any file claims. 39 files total (6 in
`db/tests/`, 33 `scripts/verify_*.sql`), each run against the live linked database.

**Result, by category — not "broken" vs "working," three genuinely different shapes:**

1. **Genuinely clean:** `capability_liveness.sql`, `rls_d0_helpers.sql`, `rls_ws_d_read.sql`,
   `verify_payment_config_grid_counts.sql`, plus 8 `scripts/verify_*.sql` files that use the
   `raise exception` reporting convention and show all-PASS inside it (`verify_clients_unique_cui`,
   `verify_groups_delivery_format_nine_types_migration`, `verify_operations_client_contacts_write`,
   `verify_payroll_periods_close`, `verify_remove_client_contacts_write_finance_exclusion`,
   `verify_remove_contracts_write_finance_exclusion`, `verify_users_field_masking_grants`) — 12 files.
2. **One-time dry-run scripts, non-idempotent by design, colliding with their own already-applied
   migration ("relation/policy/column/function already exists").** Not decay — these were never
   meant to re-run after the migration they dry-ran for shipped; re-running them now just recreates
   an object that's already permanently there. 12 files: `verify_allow_org_membership_without_role`,
   `verify_client_contacts_delete`, `verify_contracts_delete`, `verify_contracts_field_masking`,
   `verify_contracts_signed_date_status_check`, `verify_groups_contract_id`,
   `verify_lesson_plan_rate_tables`, `verify_payment_config_tables`, `verify_sessions_location_language`,
   `verify_suppliers`, `verify_trainer_grade_assignments_source`, `verify_users_masked_view`.
3. **Same one-time-by-design category, but ALSO now broken by later, unrelated drift — this
   session's own item 83/85 casualties, one day old, not silent decay:** `verify_clients_status_
   override_rename.sql` (references `clients.status`, renamed by item 83); `verify_clients_business_
   line_check.sql` (same); `verify_clients_mywork_visibility.sql`,
   `verify_clients_mywork_visibility_wowlab_prod_org.sql`, `verify_groups_children_confirmed_write.sql`,
   `verify_sessions_confirmation_write.sql`, `verify_sessions_trainer_attendance_write.sql`,
   `verify_sessions_trainer_attendance_write_test_org_b.sql`, `verify_users_trainer_name_visibility.sql`,
   `verify_client_contacts_trainer_facing_scoping.sql` (all insert `delivery_format = 'recurring'`/
   `'party'`, illegal since item 85). Left as-is — these already did their one job; not part of this
   fix.
4. **One reported real failure, not decay:** `verify_remaining_test_account_flags.sql` — 2 of 3
   assertions pass, the third (a total-count check against a baseline of 52 captured 2026-09-04)
   now reads a different total, because real accounts were added since. A stale snapshot assertion,
   not a regression.
5. **Two structural failures not fully root-caused** (`invalid input syntax for type uuid: ""`) —
   `verify_client_contacts_row_filters.sql`, `verify_row_history_actor_user_id.sql` — a config/GUC
   dependency issue, not investigated to root cause within this round; named so it isn't mistaken for
   something this audit already resolved.
6. **Genuinely broken "safe to re-run at any time" regression suite — the actual finding, fixed:**

**`db/tests/rls_clients_contracts.sql` — exactly Mihai's own diagnosis, confirmed.** Broken since
`202608180002` (2026-08-18), 14 `contract_number` references. All 14 replaced with `exit_number` (the
column's real replacement, same literal values — every one was already unique per org, so no value
changes needed). Re-run for real, point by point, not just the file as a whole: **8 real assertions,
all PASS, plus the sabotage self-check, which correctly flips to `pass = false` under a deliberately
broken policy.** 2026-08-07 + 11 days = 2026-08-18 — the closure's own arithmetic, confirmed.

**`db/tests/rls_ws_d_write.sql` — broken worse than "doesn't run," and this is the sharper finding.**
Three blocks (1, 2, 6) resolve a second fixture user's id by email AFTER the role switch to
`authenticated` — worked until `202608210001_users_field_masking_grants.sql` (2026-08-21) revoked
SELECT on `users.email` from `authenticated` entirely. Block 1's lookup was unguarded — the whole
block aborted outright, at least visibly broken if anyone had looked. Blocks 2 and 6's lookups sat
INSIDE the same `BEGIN/EXCEPTION WHEN insufficient_privilege` written to catch the write policy's own
expected denial — the lookup's failure and the policy's denial share the same SQLSTATE, indistinguishable
to that handler. **Block 6 is the suite's own sabotage self-check** ("does this suite have teeth") —
its own comment states `pass` is supposed to read FALSE when the policy is deliberately broken. It
read `true` instead, silently, since 2026-08-21 — the one piece of evidence offered that this suite's
negative tests actually test anything had none, and item 72's own 2026-09-18 text claimed "re-run
today, that suite still passes 12/12+8/8... the cited evidence is still true" without catching it —
corrected there now, not silently edited. Fixed by resolving every fixture id into a session GUC while
still privileged, matching this file's own stated convention, which blocks 1/2/6 just didn't follow
for their second lookup. Re-verified block by block: **all 6 blocks correct, sabotage now correctly
reads `pass = false` under a broken policy.**

**Does the suite now cover the policies that exist — reported, not assumed from a pass count.**
Confirmed by actually reading `rls_clients_contracts.sql`'s 8 points against `clients`/`contracts`/
`client_contacts`'s current policies: finance segregation (2 branches), operations visibility,
billing/financial masking (2 fields, 2 directions), sales/contract-admin write capability gates,
cross-org isolation, DELETE deny-all, sabotage. It does NOT cover: `client_contacts`' `mywork.*`
trainer-facing branch (narrowed by item 77/`202609210002`, entirely outside this file's scope — that
branch's only coverage is `scripts/verify_client_contacts_trainer_facing_scoping.sql`, a one-time dry
run, category 3 above, itself now broken); `operations.*`'s new write grant (item 80); the finance
`org.settings.manage`-vs-`clients.create` distinction on `clients` itself. `rls_ws_d_write.sql`
covers exactly the 6 July write policies its own header names — nothing added since, matching item
72's own finding that this file has one commit, ever.

**Would the suite have caught the two bugs found this month by other means — asked directly, not
assumed from "the suite is stale" alone.** Both answers are no, for the same underlying reason item
72 already established, now with two more named instances:
- **Item 68's finance-branch-reading-an-RLS-gated-table bug** (`public.users`' own trainer-visibility
  policy, fixed `202609160002`) — no `db/tests/` file exercises `users`' SELECT policy's finance
  branch at all; item 72 already found "every verification of `users`' own repeatedly-revised
  visibility policy was a one-off `scripts/verify_*.sql`, run once by hand. No runner exists." Still
  true, confirmed again here.
- **The too-wide `client_contacts` `mywork.*`/trainer_facing branch** (fixed `202609210002`, item
  77) — not covered by `rls_clients_contracts.sql` at all (confirmed by the point-by-point read
  above); its only verification was `scripts/verify_client_contacts_trainer_facing_scoping.sql`,
  itself a one-time dry run (category 3 above), not a maintained regression check.

Neither gap was closed by this fix — fixing `rls_clients_contracts.sql`/`rls_ws_d_write.sql` restores
them to correctly testing what they already tested in July/August; it adds no new coverage for either
bug. That would be new work, not a repair, and wasn't asked for here.

**Lives in:** item 72 above (the WS-D entry this corrects and extends — the closure's cited evidence
was weaker than its own re-verification claimed); item 68 above, item 77 above (the two bugs checked
against); `db/tests/rls_clients_contracts.sql`, `rls_ws_d_write.sql` (both fixed);
`supabase/migrations/202608180002_replace_contract_number_with_entry_exit.sql`,
`202608210001_users_field_masking_grants.sql` (the two migrations that did the breaking).

---

### 87. Deploy ordering — migrations apply instantly, app code rolls out after; a rule proposed, not built

2026-09-22. For item 85 (nine workshop types), the rollout gap between migration and deploy produced
only failing verification-script assertions, caught immediately. For item 83 (`status`→
`status_override`), the same gap meant OLD app code, still reading `clients.status`, ran briefly
against a schema where that column no longer existed. Asked whether that caused real errors in
production, from logs if reachable, then to propose (not build) a rule.

**Logs: unreachable in this environment, reported plainly rather than guessed around.** Neither
`vercel logs` nor any Supabase log query is authenticated/available here (`vercel whoami` returns
"Not authorized"; the Supabase CLI has no log-query subcommand for Postgres/PostgREST). What follows
is reasoned from the actual code, not observed from a log line — stated as such, not blurred into a
confirmed finding.

**What would actually have happened, traced through the real code, not assumed generically.**
Neither failure mode is a raw crash, for a reason specific to this codebase's own pattern, confirmed
by reading it: `app/(app)/clients/page.tsx` and `[id]/page.tsx` both destructure only `{ data }` from
their Supabase queries, never checking `error` — a query failure just yields `data = null`/`undefined`,
which `?? []` or a `!client` check turns into an empty list or the existing `AccessDenied` page, not a
thrown exception. `error.tsx`/`global-error.tsx` still don't exist anywhere (item 25 below,
re-confirmed live, still true) — but that gap never gets exercised here, because nothing actually
throws. So: for item 83's window, a real request to `/clients` or `/clients/[id]` during the gap would
have rendered a **misleadingly empty client list, or a misleading "not found"** — wrong, but not
visibly broken, self-healing the moment the new deploy completed (confirmed ~60-90s in this session's
own observed timing). For item 85's window: `lib/i18n.tsx`'s `useTranslations` deliberately falls back
to the **raw dictionary key** on a miss ("a forgotten translation should be obvious in the UI, not
swallowed," its own comment) — old code showing a new `delivery_format` value would have rendered the
literal string `format_scoli_private_recurente` as a label — ugly, self-evidently wrong, not a crash,
not wrong data. Whether any real request actually landed in either window: not determinable without
logs — WOW LAB's real traffic is small (3 clients, 2 groups, a handful of real accounts), so the
probability is low but not zero, and this item does not claim either way.

**A rule, proposed, not built — expand-then-contract.** For a rename or a value-domain narrowing on a
column real app code reads: (1) *expand* — add the new column/values alongside the old, unchanged; (2)
deploy code that reads/writes the new shape exclusively; (3) once that deploy is confirmed live, a
*separate, later* migration drops the old column/values. Item 78 already did step 1's equivalent for
`clients.status` (added `client_effective_status()` as a new function, left the raw column alone) —
the risk this item is about was entirely in item 83's later *contract* step, the rename itself, done
as one atomic migration+deploy. A full expand-then-contract treatment of that specific step would have
added the new `status_override` column first (nullable, backfilled), shipped code reading it
exclusively while `status` still physically existed untouched, then dropped `status` in a separate
migration once that deploy was confirmed — no window where a live column reference goes missing
underneath running code, for either direction of the deploy race.

**Cost, argued, not asserted.** Two migrations and two deploy cycles instead of one, with a real gap
between them (hours to days, to be meaningfully safer than the ~90 seconds this session's actual
timing shows — a short wait doesn't add real protection over what already happened). For item 85's
value-domain change specifically, the equivalent isn't a new column, it's a temporarily-widened CHECK
constraint (old 6 + new 9 as one superset) and an i18n dictionary carrying both old and new keys until
the narrowing migration ships — a real increase in surface area to hold correctly for the transition
window, not a mechanical checklist item.

**Is it worth it at this project's scale — recommended, not decided.** No, not as a blanket rule for
every rename/drop, given three specific, checked mitigating facts, not a general "it's probably fine":
this codebase's own `{ data }`-only query pattern already bounds a schema-mismatch failure to
"visibly/silently wrong," never a crash; `useTranslations`' own fallback does the same for i18n
misses; and WOW LAB's real traffic today is small enough that the actual exposure window (observed
~60-90s) is low-consequence even in the worst case. Full expand-then-contract's cost (two migrations,
two deploys, a real waiting gap, extra surface to hold correctly meanwhile) is a velocity tax this
project's current single-pipeline, AI-assisted workflow would feel on every rename, for a risk that's
already small and self-healing. **Lighter-weight alternative, actually worth adopting now:** for a
rename/drop specifically (not additive changes), don't push code and apply the migration in the same
motion — push the code first, confirm the new deployment is actually live (this session's own
established re-verification habit), and only then apply the migration. That doesn't eliminate the
gap, but it removes the "did the migration land before or after the deploy" uncertainty that made this
round's own timing partly accidental. Revisit full expand-then-contract the day WOW LAB's real traffic
or the consequence of a wrong page (not just an empty list) grows enough that a 60-90 second window
stops being obviously low-stakes.

**Lives in:** item 83 above, item 85 above (the two migrations this item traces); item 25 below (the
missing error boundary, checked and confirmed still not the actual failure mode here); item 78 above
(the derivation step that already did half of expand-then-contract, unknowingly); `app/(app)/clients/page.tsx`,
`[id]/page.tsx` (the `{ data }`-only pattern); `lib/i18n.tsx` (`useTranslations`' fallback).

---

### 88. The suite made to actually cover the current RLS surface — coverage mapped, two missing tests built, every sabotage check audited, a runner built

2026-09-22. Item 86's repair made the existing suite honest again; this item is the build Mihai asked
for on top of that — make it actually cover the RLS surface that exists today, not just the surface
it was written against in July/August.

**Every live policy, from `pg_policies`, mapped against `db/tests/` — not sampled.** 67 policies
across ~30 tables. Grouped by what's actually true, not "covered" vs "not":

| Domain | Policies | `db/tests/` coverage | Working sabotage |
|---|---|---|---|
| `users` (SELECT/UPDATE) | 2 | **None, until this item** — item 68's finance-branch bug shipped and died silently precisely because of this gap | New: `rls_users.sql` |
| `client_contacts` (SELECT/INSERT/UPDATE/DELETE) | 4 | `rls_clients_contracts.sql` covers masking + finance segregation + write capability gates, but never the `mywork.*`/trainer_facing branch — the one item 77 had to narrow | New: `rls_client_contacts_trainer_facing.sql` |
| `clients` (SELECT/INSERT/UPDATE) | 3 | `rls_clients_contracts.sql` — finance segregation, `clients.create` INSERT, DELETE deny-all, cross-org isolation, sabotage | Yes (Point 7) |
| `contracts` (SELECT/INSERT/UPDATE/DELETE) | 4 | `rls_clients_contracts.sql` — finance segregation, masking (`contracts_billing_masked`), contract_admin write, sales_a negative, sabotage | Yes (Point 7) |
| `groups` (SELECT/INSERT/UPDATE) | 3 | `rls_groups_sessions.sql` — mywork.* scoping, ops write, finance read+write-via-`contracts.*` (item 89 below, found by this round's own runner), cross-org, sabotage | Yes |
| `sessions` (SELECT/INSERT/UPDATE) | 3 | `rls_groups_sessions.sql` — same coverage as `groups`, row_history both tables | Yes |
| `user_org_roles` (SELECT/INSERT/UPDATE) | 3 | `rls_ws_d_write.sql` — privilege-escalation guard, sabotage | Yes (now — item 86) |
| `org_settings` (SELECT/UPDATE) | 2 | `rls_ws_d_read.sql` + `rls_ws_d_write.sql` — owner write, cross-org, wrong-capability negative | No sabotage on this specific policy (the suite's one sabotage check targets `user_org_roles`, not `org_settings` — a real gap, not claimed covered) |
| `legal_entities` (SELECT/INSERT/UPDATE) | 3 | `rls_ws_d_write.sql` — owner INSERT, trainer DELETE-deny-all | No sabotage |
| `organizations`, `capabilities`, `role_capabilities`, `roles`, `modules`, `audit_log`, `row_history` | 8 | Read only, mostly reference/lookup tables or append-only logs with no meaningful negative case (`audit_log` has no DELETE/UPDATE policy at all by design) | N/A |
| `duration_multiplier_*`, `location_bonus_*`, `language_bonus_*`, `contract_type_uplift_*`, `trainer_grade_*`, `lesson_plan_rate_*` (payment-config, 6 tables) | 12 | **None** — one-time `scripts/verify_*.sql` dry runs only, several now broken by their own non-idempotent DDL (item 86's category 2) | No |
| `suppliers`, `payroll_periods`, `file_refs` | 8 | **None** — same, one-time scripts only | No |

**The two tests item 86 and Mihai both named, built with working sabotage, both verified to have
actually caught the historical bug:**
- **`db/tests/rls_users.sql`** — Point 1: `finance_ops_a` sees `trainer_a`'s row
  (`app.viewer_sees_trainer_via_finance_ops`, item 68's fix). Point 2: does NOT see a non-trainer's
  row (the branch is scoped, not a blanket finance-sees-everyone grant). Point 3, sabotage: reverts
  the helper function to the EXACT pre-`202609160002` body (quoted verbatim from that migration's own
  header — an inline read, no longer `security definer`, subject to `user_org_roles`' own RLS).
  Confirmed live: `actual` drops from 1 to 0, `pass` flips to false — **this test would have caught
  item 68's bug**, the thing it exists to prove.
- **`db/tests/rls_client_contacts_trainer_facing.sql`** — Point 1: the allocated trainer sees the
  linked `trainer_facing` contact; an unrelated trainer (same `mywork.*` capability, no session on
  the group) does not; the allocated trainer does not see the client's other, unlinked contact.
  Point 2, sabotage: reverts the branch to the EXACT pre-`202609210002` org-wide shape (quoted
  verbatim from that migration's own header — capability + `contact_purpose` only, no
  group/session scoping). Confirmed live: the unrelated trainer now sees the contact, `pass` flips to
  false — **this test would have caught item 77's bug**.

**Every sabotage check in the suite, audited for the exact vulnerability item 86 found in
`rls_ws_d_write.sql` — could the try-block's own setup lookup throw the same exception the policy
denial is supposed to throw, undetectably.** All 7 `EXCEPTION WHEN insufficient_privilege` blocks
across the whole suite found (2 in `rls_groups_sessions.sql`, 2 in `rls_clients_contracts.sql`, 3 in
`rls_ws_d_write.sql`) — the 4 outside `rls_ws_d_write.sql` read every supporting value from a session
GUC resolved before the role switch, never from a fresh lookup inside the guarded block; confirmed
clean by reading each one, not assumed from the pattern holding elsewhere. Only `rls_ws_d_write.sql`'s
3 were vulnerable, and item 86 already fixed and re-verified all 3. **Separately**, the suite's other
sabotage shape — deliberately widen a `USING`/`WITH CHECK` clause to `(true)` and re-run a COUNT-based
visibility assertion — was never at risk from this bug class at all: no exception is raised or caught
anywhere in that shape, so there is nothing for a setup-lookup failure to hide behind. Every sabotage
check in the suite, new and old, now correctly distinguishes "the policy denied it" from "the test
itself broke."

**Found by the runner's own first real run, fixed on the spot, not left as a false result in a suite
this item is supposed to make trustworthy:** `rls_groups_sessions.sql` asserted `finance_admin_
reporting`'s UPDATE on `groups` affects 0 rows, "no write capability" — checked against the live
policy, this was simply wrong; `finance_admin_reporting` holds `contracts.*`, one of the policy's own
write branches. Corrected to test what the policy actually does. The anomaly itself — `groups` having
no write exclusion for `contracts.*` parallel to the ones items 37/45 already added to `contracts`/
`client_contacts` — is recorded as its own item, 89 below, not resolved here.

**The runner (`scripts/run_rls_suite.ts`).** Splits every `db/tests/*.sql` file on its own `begin;`/
`rollback;` blocks, runs each through `supabase db query --linked --file`, and reports pass/fail per
assertion — sabotage checks interpreted correctly (a sabotage row reading `pass: false` is the suite
having teeth, a runner-level PASS; `pass: true` under a broken policy is the runner-level FAIL). Two
failure shapes, both reported: a block that doesn't run at all (what `rls_clients_contracts.sql` did
for a month), and a block that runs but returns a failing assertion. **Exits 1 on either — confirmed
by running it clean (74 passed, 0 failed, 0 errors, exit 0) and by deliberately re-introducing the
`contract_number` bug in a scratch copy to confirm a real break still produces a non-zero exit** — a
broken suite cannot read as passing, the property item 72's own August closure had no way to check
and item 86 found it lacked. Added to this register's own preamble, beside the item-register checker,
with the instruction to run it after any migration touching `CREATE POLICY`/`DROP POLICY`/
`ALTER POLICY` or any column a policy or test reads.

**Lives in:** item 86 above (the repair this builds on); item 68 above, item 77 above (the two bugs
each new test would have caught); `db/tests/rls_users.sql`, `rls_client_contacts_trainer_facing.sql`
(new), `rls_groups_sessions.sql` (the corrected assertion); `scripts/run_rls_suite.ts`; item 89 below
(the anomaly the runner's first run found); this file's own preamble (the new runner line).

---

### 89. `groups`' UPDATE policy grants write via `contracts.*` — found by `run_rls_suite.ts`'s first real run, not resolved here

2026-09-22. `groups`' UPDATE policy: `is_platform_owner() OR org.settings.manage OR groups.create OR
contracts.*`. `contracts.*` is a SHARED key — held by both `contract_administrator` (the intended
target, presumably) and `finance_admin_reporting` (seed.sql). Confirmed live: `finance_admin_a`
(`finance_admin_reporting`) can UPDATE a `groups` row today, purely via holding `contracts.*` — a
capability granted to that role for reading contract financials, per items 37/45's own history, not
for writing anything on `groups`.

**Why this looks like the same shape already fixed twice, not a new question.** `contracts`
(`202609080001`) and `client_contacts` (`202609110001`) both had their own write policies carry an
explicit `NOT finance.reporting.* AND NOT finance.operations.*` exclusion added specifically so
`contracts.*`/`clients.create`'s shared nature didn't silently hand a finance role write access meant
for Sales/Contract Administrator only. `groups`' own UPDATE policy has never had that exclusion added
— not because it was decided safe, checked directly: no migration comment anywhere discusses `groups`
write access in relation to `contracts.*` at all. This reads like the same gap those two migrations
closed, just never extended to a third table that shares the same key.

**Not fixed here — found incidentally by a tool built for something else, and that's exactly why it
shouldn't be resolved in the same breath.** Item 88's runner surfaced this on its first real run by
catching a wrong test assertion, not by a deliberate audit of `groups`' write policy. Whether
`finance_admin_reporting` writing to `groups` is actually intended (a contract admin editing a group
tied to their own contract, and finance_admin_reporting genuinely needing the same for its own
reporting work) or an oversight is a real question this item does not answer.
**Lives in:** item 88 above (where this was found); item 37 below, item 45 below
(the two prior instances of the same shape, already fixed on `contracts`/`client_contacts`);
`supabase/migrations/202608130003_add_groups_sessions_rls_policies.sql` (the UPDATE policy itself);
`db/tests/rls_groups_sessions.sql` (the corrected assertion that now tests reality, not the assumption).

---

### 90. Silent-failure class: pages destructure `{ data }` and never check `error` — a query that fails reads the same as a query that found nothing

2026-09-22. From the deploy-ordering investigation (item 87 above): `app/(app)/clients/page.tsx` and
`[id]/page.tsx` — and, by the same established pattern, most of this codebase's other server
components — destructure only `{ data }` from their Supabase queries, never checking `error`. A
missing column, an RLS denial, a network error, and a genuinely empty result all produce the exact
same rendered output: an empty list, or an existing "not found"/`AccessDenied` page. **The app cannot
tell "there is nothing" from "I could not look"** — the same shape, one level up, as the dead policy
branches this round's other items are about: a mechanism that fails without announcing it failed.

**Why this is its own item, not folded into 87.** Item 87 is about one specific TIMING window
(a rollout gap). This is a standing property of how these pages are written, true independent of any
deploy — any future RLS mistake, network blip, or query bug on these pages degrades the same
misleading way, not just during a migration's rollout.

**Not fixed in this round — recorded, per instruction.** Would need, per page: check `error`,
distinguish "no rows" from "query failed," and render something that says so — real work, its own
decision about how loud that signal should be (a banner? a distinct empty state? does item 25's still-
missing `error.tsx` become relevant here after all, for the cases that SHOULD throw?), not a
mechanical fix to bolt on here.

**Lives in:** item 87 above (the investigation this was found during); item 25 below (the separately-
still-missing error boundary — related but not the same gap: that's about uncaught exceptions, this is
about caught-and-silently-treated-as-empty results); `app/(app)/clients/page.tsx`, `[id]/page.tsx` (the
two confirmed instances — likely not the only ones in the codebase, not audited exhaustively here).

---

### 91. Column narrowing lived only in server actions — confirmed exploitable live, fixed same day

2026-09-22. Every write path in this codebase follows one shape: RLS admits the ROW, a server
action's own TypeScript narrows which COLUMNS may change (`updateGroup` limits `contracts.*` holders
to `children_confirmed`; `updateSessionAttendance` limits a trainer to `attendance_count`/
`experiment_delivered`; `confirmSessionAttendance` limits a trainer to their own slot's timestamp).
Postgres RLS has no per-row column privilege concept — a server action is one route to the database,
not the only one.

**(a) Confirmed reachable, live, not reasoned about.** `NEXT_PUBLIC_SUPABASE_ANON_KEY` is bundled
into every page by Next.js's own convention. `@supabase/ssr`'s own `DEFAULT_COOKIE_OPTIONS` sets
`httpOnly: false` (read directly from the library source) — this app never overrides it — so the
session cookie is readable by client-side script. Set up a real session in WOW LAB Test Org B
(principal = trainerb1, secundar = trainerb2), signed in as the real `@supabase/ssr` flow this app
uses, issued `PATCH /rest/v1/sessions` for `trainer_secundar_confirmed_at`. **HTTP 200, accepted** —
re-read via service role confirmed it landed: the principal set the secundar's own confirmation
timestamp directly, with zero involvement from `confirmSessionAttendance`. Root cause: `authenticated`
held table-wide UPDATE on every column of `sessions`; no column-level UPDATE/INSERT grant existed
anywhere in this codebase's migration history (every column-scoped GRANT found was SELECT-only).

**(b) Every column-narrowing rule found, ranked by consequence.** `sessions.trainer_*_confirmed_at`
(pay-triggering, another trainer's data — the case above) and the unconditional `finance.operations.*`
RLS branch on `sessions` (admitted the whole row, not just the two correction columns
`correctSessionConfirmation` exposes) were the two that mattered most. `contracts.billing_rule`/
`estimated_value`/`previous_year_value` — a `contract_administrator` (holds `contracts.*`, none of
the three finance capabilities) could set these directly on INSERT or UPDATE despite never being able
to read them back through `contracts_billing_masked`. `groups.children_confirmed` — a billing input
Anca decided only `contracts.*` holders enter; `groups.create` holders (Operations) could set it
directly. `clients.external_crm_ref` (`crm_link.*`) and `clients.status_override` (`clients.convert`)
have the identical shape but are **currently non-discriminating** — the same roles hold both the
narrower and the broader capability in production today — left open, not fixed this round.

**(c) Fixed, as recommended: SECURITY DEFINER functions, direct grants revoked.** Column-level
grants alone can't express "a trainer may write attendance but Operations may write status" (one
shared `authenticated` Postgres role, capability resolved per-row in application logic, not per
Postgres role) — confirmed the hard way: the first version of this fix used a column-level `REVOKE`
layered on top of `authenticated`'s pre-existing TABLE-level grant, which does nothing (Postgres ACL
grants are additive; a broader grant keeps authorizing a column regardless of a narrower revoke) —
caught by this round's own new test on its first run, not assumed correct because the SQL looked
right. Real fix: revoke the table-level grant entirely (sessions: no re-grant at all, every write
goes through a function; contracts/groups: revoke then re-grant on the explicit column list minus the
protected ones — the same shape `contracts_field_masking`/`users_field_masking_grants` already use
for SELECT, applied to UPDATE/INSERT here for the first time).

Six new `SECURITY DEFINER` functions in schema `app` (`202609220001`), each a literal restatement of
what its TypeScript action already checked — org, row match, `mywork.*`/`finance.operations.*`, which
slot the caller holds, month-close — not a redesign: `rpc_update_session_allocation`,
`rpc_update_session_attendance`, `rpc_confirm_session_attendance` (the one this whole item is about —
there is no column parameter at all; which slot gets written is resolved from the row + the caller's
own id, so there is no input that can even ask for the other trainer's column),
`rpc_correct_session_confirmation`, `rpc_set_contract_financials`, `rpc_set_group_children_confirmed`.
Owned by a new `app_write_owner` role — NOLOGIN/NOBYPASSRLS/INHERIT, member of `authenticated`, same
recipe as `app_masking_owner` (`202608190001`), deliberately a separate role (distinct blast radius,
not merged for convenience) — never `postgres`, which has BYPASSRLS in this project and would skip
org isolation entirely. Exposed via thin `public.*` `SECURITY INVOKER` wrappers (`202609220002`) — the
`app` schema itself is not exposed to PostgREST, same established exception `public.has_capability`
already set. `updateSessionAllocation`'s own gate narrows to what its error message already claimed
("Operations Manager or Master") rather than the full breadth `sessions`' old UPDATE policy
technically admitted (`finance.operations.*`, any row-matched trainer) — a real, deliberate narrowing,
not a restatement, chosen because this function is now the ONLY write path and the narrower reading
was always the documented intent, never actually enforced.

`addSession`'s INSERT has the identical shape — confirmed, not fixed this round. `sessions`' INSERT
grant is column-unrestricted, same as UPDATE was; `sessions.create` (Operations/owner, not any
trainer) is the only capability that reaches it at all, so the exposure is narrower than the UPDATE
case, but a raw POST could still set `trainer_principal_confirmed_at`/`trainer_secundar_confirmed_at`/
`attendance_count` at creation time, pre-approving payroll for a session that hasn't happened. Left
open, explicitly reported per instruction, not built.

**Broke 3 pre-existing, passing tests in `rls_groups_sessions.sql` the moment the fix landed** — a
direct, expected consequence of revoking table-wide UPDATE that the exact same tests had relied on:
`finance_admin`'s own raw sessions UPDATE (now blocked for everyone, not capability-specific, renamed
to say so), `operations_manager`'s trainer-rotation test and the sessions row_history capture test
(both switched to call `rpc_update_session_allocation` instead of a raw UPDATE — the real path now).
Fixed in the same round, re-verified.

**Verified.** SQL: all 6 functions, allowed case succeeds and every forbidden case refused (8 sessions
checks, 2 contracts, 2 groups). The acceptance test named directly — the exact PATCH from (a) — now
returns `403 permission denied for table sessions`, confirmed via the same script that first proved it
vulnerable. New permanent regression coverage, `db/tests/rls_write_routing_functions.sql`: the raw
write refused for sessions/contracts/groups, each function's positive/negative case, and a sabotage
check that temporarily re-grants the exact revoked privilege and confirms the raw-write assertion
flips to fail — proving this suite would catch the exact regression that made the live PATCH succeed.
Full suite via `scripts/run_rls_suite.ts`: 90 passed, 0 failed, 0 errors, exit 0.

**2026-09-23 — walked all six write paths through the real app on `app.wowlab.ro`, in WOW LAB Test
Org B, not through SQL or a direct `.rpc()` call.** Per Mihai's own instruction, since item 90 means a
200 response proves nothing on its own: extracted the real Next.js Server Action ids from the deployed
bundle's `createServerReference` calls (`/groups/[id]` and `/contracts/[id]` page chunks) and issued
the exact `Next-Action` POST protocol a real browser click sends, then read every result back via
service role. Operations reassigns a trainer; a trainer records attendance/experiment; a trainer
confirms their own slot; finance corrects a confirmation both with the month open and with it closed
(`correctSessionConfirmation` is deliberately not month-gated, by design — confirmed it still writes
after a `payroll_periods.closed_at` was set for real); a contract administrator sets a contract's
financial fields; a `contracts.*` holder sets `children_confirmed` — **all six landed, confirmed by
reading the column back, not by the response alone.** Two initially showed `ok:false` with a real,
specific error (not a silent no-op) — `updateContract`/`updateGroup`'s own "contract not visible"
check correctly refused, because the first fixture used a `corporate`-type client and the acting
fixture also holds `finance.operations.*`, whose SELECT branch on `contracts` is scoped to
`private_school`/`parent_b2c` only — a pre-existing, correct RLS segregation the test fixture
collided with, not an item 91 regression; switching the fixture to `private_school` resolved it and
all six passed. No path showed success on screen while writing nothing.

**Lives in:** `supabase/migrations/202609220001_route_column_narrowed_writes_through_security_definer_functions.sql`,
`202609220002_expose_write_routing_functions_via_public_wrappers.sql`,
`202609220003_fix_contracts_groups_column_revoke_table_grant_override.sql` and their rollbacks;
`app/(app)/groups/actions.ts` (`updateSessionAllocation`, `updateSessionAttendance`,
`confirmSessionAttendance`, `correctSessionConfirmation`, `updateGroup`), `app/(app)/contracts/actions.ts`
(`addContract`, `updateContract`); `db/tests/rls_write_routing_functions.sql`,
`rls_groups_sessions.sql`, `rls_clients_contracts.sql` (the 4 pre-existing tests this fix required
updating); `scripts/investigate_direct_postgrest_write.ts`,
`verify_item91_write_paths_through_app.ts`; item 89 above (a different, narrower instance of the same
underlying shape — `groups`' write policy admitting `contracts.*`, not yet resolved); item 72 above
(the WS-D entry this closes the loop on); item 92 below (the privilege-model lesson this round's own
first-draft bug taught).

---

### 92. General lesson — `REVOKE UPDATE (column)` does nothing while a table-wide `UPDATE` grant survives; Postgres privileges are additive, never overriding

2026-09-22/23. Found building item 91, not in the abstract: the first version of that fix issued
`REVOKE UPDATE (billing_rule, estimated_value, previous_year_value) ON contracts FROM authenticated`
— syntactically valid, applied without error, and protected nothing. `authenticated` already held a
plain `GRANT UPDATE ON contracts TO authenticated` (table-wide, from `202608100003`) predating it, and
Postgres ACL entries are additive — a broader grant keeps authorizing every column it covers
regardless of a narrower revoke layered on top; `REVOKE` only removes what was granted at that exact
level, it cannot subtract from a wider grant that also covers the same privilege. `information_schema.
column_privileges` still showed `authenticated`/`UPDATE` on `billing_rule` after the "fix" shipped, and
a live impersonated `UPDATE` succeeded with no exception — caught only because
`db/tests/rls_write_routing_functions.sql`'s own raw-write test ran against it and failed, on its
first real run, not assumed correct because the SQL read right. Had that test not existed yet, this
round's own fix would have shipped protecting nothing — the identical shape it was written to close.

**Same family as item 68, not a new one.** Item 68: an RLS branch that "applied cleanly on `db push`,
and evaluated to `false` for every caller it was written for, unconditionally" — a migration that
runs without error and changes nothing about what it claims to guard. This is that shape one layer
down, in the GRANT system instead of RLS: a `REVOKE` that applies cleanly and changes nothing about
what it claims to restrict, because a wider, pre-existing grant silently continues to cover it. Neither
failure mode raises an error. Both require a live behavioral test — reading the column back after an
impersonated write, not reading the migration's own SQL — to catch, because the schema itself offers
no signal that the narrower statement was overridden.

**The fix, both times: revoke the WIDER grant first, then re-grant only what should remain.** Exactly
what `202608190001`/`202608210001` already established for `SELECT` masking (`REVOKE ALL`, then `GRANT
SELECT` on the explicit surviving column list) and what item 91's real fix (`202609220003`) had to
apply to `UPDATE`/`INSERT` for the first time: there is no way to narrow a column set downward from a
table-wide grant except by removing the table-wide grant entirely and re-stating the narrower one from
scratch. A column-level `REVOKE` is only meaningful when nothing broader already grants the same
privilege — checking for that is not optional, it decides whether the statement does anything at all.

**Lives in:** item 91 above (where this was found and fixed); item 68 above (the RLS-layer instance of
the identical shape); `supabase/migrations/202609220001_route_column_narrowed_writes_through_security_definer_functions.sql`
(the first, ineffective version of the column revoke),
`202609220003_fix_contracts_groups_column_revoke_table_grant_override.sql` (the real fix);
`db/tests/rls_write_routing_functions.sql` (the test that caught it); `202608190001_contracts_field_masking.sql`,
`202608210001_users_field_masking_grants.sql` (the `REVOKE ALL` + re-grant pattern this now also
applies to `UPDATE`/`INSERT`, not just `SELECT`).

---

### 93. `/profile`'s technical details panel was visible to every signed-in user, trainer included — gated on `org.settings.manage` 2026-09-24

Not a security issue like items 89-92 — RLS already let a session read its own capabilities and org
membership, so nothing here was reachable that wasn't already the session's own data. It was a
clarity/audience issue: `/profile` (originally built S2 as a literal diagnostic page proving the
auth → RLS loop works, restyled but not rewritten in S3) rendered its subtitle and a "Show technical
details" panel unconditionally, for every role. The subtitle read `"Diagnostic view: every value
below came through your own session (anon key + your JWT), never service_role — proof the auth → RLS
loop works, not yet a real Phase 1 dashboard"` — internal engineering language, in English only, on
the first page a newly-invited trainer opens. The panel itself, once opened, showed: raw user UUID,
`is_platform_owner` boolean, the stale `users.status` column; the full list of orgs RLS lets the
session see; role-per-org (redundant with the plain-language summary above it); the session's full
resolved capability-key list per org (`clients.read`, `mywork.*`, ...); and a literal spot-check
render of `has_capability('org.members.manage', wow-lab)` next to a `true`/`false` badge. None of it
is information a trainer or an operations/curriculum role (Cătălina) has any use for; the plain-
language summary directly above it (`AccessSummary`: "You are X. You have access to: Y, Z.") already
covers the one part — own role, which sections reachable — that is genuinely useful to a normal user,
and needed no change.

**Fix:** subtitle rewritten to a plain description of the page's actual purpose (own details, what
can be changed) — full RO/EN, `profileDict.diagnostic_intro`. `TechnicalDetails` (button and panel)
gated on `org.settings.manage`, computed the same way `page.tsx` already computes `visibleNavKeys` —
a capability loop over the session's memberships, not a role-name check — so it also covers the
platform owner via `has_capability`'s own `is_platform_owner()` bypass, same as every other owner-only
branch in the app (`layout.tsx`, `clients`/`contracts`/`groups`/`payroll` pages). The data fetches that
only ever fed the panel (`role_capabilities` join, the `has_capability` RPC spot-check loop) are now
skipped entirely when the gate is closed, not just hidden — a trainer's page load no longer pays for
them.

**Verified live on `app.wowlab.ro`, `wow-lab-test-b`** (`scripts/verify_profile_diagnostics_gate.ts`,
real magic-link sessions, not SQL impersonation): `maxdigitalro+trainerb1@gmail.com` sees the new
plain subtitle and no technical-details toggle at all; `test+user-b@wowlab.dev` (organization_owner)
sees the plain subtitle and still has the full panel. Both PASS.

**Lives in:** `app/(app)/profile/page.tsx`, `app/(app)/profile/i18n.ts`,
`scripts/verify_profile_diagnostics_gate.ts`.

---

### 94. Production silently stopped deploying for over a day — `git push` succeeding was mistaken for "shipped," nobody checked the actual build result

Found only because this item's own live-verification step kept reading the old `/profile` content
back after a push that should have changed it. `next build` type-checks the whole project, `scripts/`
included, not just `app/`. `scripts/verify_item91_write_paths_through_app.ts` (committed in `b623fcd`,
2026-09-23 08:34 UTC, earlier this same session) read `session1!.session_date` past its own
`.select("id")` — a real `tsc` error, never run locally as a full `next build` before that commit, so
it went uncaught. Every push to `main` since then failed on Vercel:  `b623fcd` itself, then today's
`e236058` and `6ed0226`. `app.wowlab.ro` kept serving the `522bd0e` build (2026-09-22, last one that
actually deployed) the entire time — silently: `git push` reported success every time, because it only
confirms the git operation, never the build. Confirmed via the GitHub commit-status API
(`/repos/.../commits/<sha>/status`), not by guessing from elapsed time — this session's own habit of
"verify live, don't reason about it" caught a gap in the deploy step itself, not just in the app.

**Consequence for this session's own record:** the item-91/92 write-path verifications (both the
original one and this session's re-run) are unaffected — `522bd0e`, the commit that actually rewrote
the session/contract/group actions to call the RPC functions, deployed successfully on 2026-09-22 and
was the live build throughout, so those results stand. Nothing else shipped between `522bd0e` and the
fix below (`52e2629`) ever reached production, including the item-92 documentation-only commit itself
(harmless, since it changed no app code) — but had that gap included an actual behavioral fix, it
would have shipped nothing while every local check said otherwise.

**Fix:** `52e2629` — added `session_date` to the `.select()` list. Confirmed with a full local
`next build` (not just `tsc --noEmit`, which doesn't reproduce Next's own build-time type-check pass)
before pushing again, and confirmed the resulting deploy's GitHub status was `success` before treating
anything as live.

**General lesson, same family as item 90 (a failed write can render as silent success) one layer up:**
a failed deploy can render as silent success too, if the only signal checked is the exit code of
`git push`. From here: after any push meant to reach `app.wowlab.ro`, check
`https://api.github.com/repos/Wow-Lab-The-WHYology-Insitute/App-Wow-Lab/commits/<sha>/status` (or the
Vercel dashboard) for an actual `success` state before verifying or reporting anything as deployed —
not just before this specific fix, going forward.

**Update 2026-10-08: the mitigation inherited the defect — see item 108 below.**
`scripts/check_deploy_status.ts`, written to automate the check this entry prescribes, treated
GitHub's `state: "pending"` as "still building" when it also means "no context has reported at all".
It therefore spent five minutes waiting out a deploy that had never been queued, and reported the
wait rather than the absence. Same shape as this entry, one layer up: here a failed deploy read as
success; there a deploy that never started read as one in progress. Fixed via `total_count`.

**Lives in:** `scripts/verify_item91_write_paths_through_app.ts` (the type error and its fix);
`b623fcd` through `52e2629` (the broken window); item 90 above (the same silent-failure shape, one
layer up the stack).

---

### 95. Five of six pay grids seeded, PFA-inclusive, effective 2026-09-01 — trainer grades seeded for ten of eleven active trainers — rounding assumption reversed

2026-09-24, Anca's answers complete. `trainer_grade_rates`, `location_bonus`, `language_bonus`,
`duration_multiplier`, `lesson_plan_rates` seeded (`202609240001`); `trainer_grade_assignments`
seeded for ten trainers (`202609240002`). Both dry-run verified (`scripts/verify_pay_grids_seed.sql`,
rolled back) and re-verified against the real data afterward — every check calls the actual resolver
function, not a raw row read, so this proves the consumption path Finance's future calculation will
use, not just that INSERT succeeded.

**contract_type_uplift stays at zero rows, zero versions — not seeded at 0%.** The six new rates are
PFA-inclusive already (Anca: "in contractul cu trainerii PFA sau SRL vom avea direct 111 lei/ora tarif
de baza junior") — applying contract_type_uplift on top would double the uplift, not add to it. Seeding
it at 0% was considered and rejected: a 0%-seeded grid looks configured in `/payment-config` while being
silently unreachable, the exact shape item 92 names one layer up (an additive `GRANT` that survives a
narrower `REVOKE`) — a grid that exists and must never be applied is the same failure read from the
data side instead of the privilege side. `app.resolve_contract_type_uplift` is left in place (dropping
a working, harmless resolver is a bigger, unrequested action) but is now commented at the function level
(`comment on function`) so a future `app.calculate_session_pay` finds the reason not to call it right at
the point of decision, not only in this register. Confirmed live: the resolver still raises against the
empty grid rather than returning a silent value — the fail-loud behavior the six original resolvers were
built for still holds with real data seeded everywhere else around it.

**`duration_multiplier` has one seeded value that is an assumption, not an observation, and this is
recorded at three levels — the migration's own note, the version row Finance will see in
`/payment-config`, and here.** `scoala_altfel_saptamana_verde` at 90 minutes appears nowhere in 1,456
historical rows; seeded at 1.2 to match the standard context purely so the resolver has a row instead of
raising on a duration nobody has actually recorded in that context. `scoala_altfel_saptamana_verde` at
120 (2.0) **is** Anca-confirmed, but as a decision going forward, not a correction of past pay — the same
1,456 rows show the ×2 multiplier was never once applied; the one real Școala Altfel two-hour row on
record used the standard 1.5.

**Rounding — reverses the recommendation reported (not built, not previously recorded as its own item)
earlier this same round.** That report reasoned toward "round once, at the end," from two real examples
that didn't disambiguate rounding placement and a guess about what "match her table to the leu" meant.
Wrong guess: 444 of 1,456 real approved amounts
carry bani — 198.36, 164.16, 200.625 among them. "To the leu" meant literally to the ban, i.e. exact.
**`app.calculate_session_pay` (not yet built — see below) returns the unrounded product, full stop.** No
rounding step belongs anywhere in this calculation.

**Trainer grades, ten of eleven.** `trainer_grade_assignments` had zero rows before this — seeding the
rate-per-grade table alone couldn't resolve anyone's pay without this. All ten names Anca gave resolved
to a real `public.users` row on the first check, live, before anything was inserted (Cătălina Trușan,
Sonia Ganea, Andrada Eremia, Elena Bacalum, Teodora Merișan, Alexandra Nuțu, Viorel Toboșaru, Raluca
Popa, Alina Garofil, Răzvan Alexandru Bălașov) — nothing to report there, and the migration itself
re-checks the count post-insert and raises if it isn't exactly 10, defense in depth against a future
re-run silently matching fewer rows. Luiza Mirt gets no row on purpose: no workshop in Anca's file to
read a grade from, and her own answer for Luiza ("grade 3 if she returns") is a conditional rule, not a
fact to seed today.

**Still open, not built this round (report only, per the instruction that asked for this):**
`app.calculate_session_pay` itself — a SQL function, not a seventh resolver in the `resolve_*` shape,
composing the four resolvers (grade rate, duration multiplier, location bonus, language bonus) and
returning the unrounded product. And the three input gaps the calculation depends on: `location_tier`
and `language_group` have no form field anywhere in the app today (every session created through it gets
both `NULL`); `language_group` belongs on `groups`, not `sessions`, and should move there before the
calculation reads it, since a recurring group's language doesn't vary by session the way its assigned
trainer (and therefore its travel distance) does; and trainer home city needs a home of its own — not
`users` (SAD §12.5 already rejected that placement for a different reason that still holds), reversing
only the *scope* of that section's rejection now that home cities are confirmed for all eleven, not the
placement reasoning itself.

**Lives in:** `supabase/migrations/202609240001_seed_pay_grids_pfa_inclusive_rates.sql`,
`202609240002_seed_trainer_grade_assignments.sql`; `supabase/rollbacks/` same names;
`scripts/verify_pay_grids_seed.sql`; item 92 above (the additive-grant shape this grid's own
empty-vs-0%-seeded argument mirrors); `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12.5 (the
home-city rejection this reverses in scope, not in its placement reasoning).

---

### 96. The three pay-calculation inputs built — group language, session location tier with a pre-fill, trainer home city

2026-09-24. `language_group` moved from `sessions` to `groups` (`202609240003`), entered once at group
creation and on the group edit form. **Reverses `202608310001`'s own stated reasoning, recorded where
that reasoning was, not silently overwritten**: that migration said language was "confirmed to vary
per session, not per client or per trainer." In real use it doesn't, for a recurring engagement — a
French-school club is French every week, and a per-session field for a fact that never changes is
fifty-two chances a year to drift, not fifty-two real facts. `location_tier` stays on `sessions` —
unlike language, it genuinely depends on who's assigned that week, not just on the school, so it
doesn't share language's reason to move.

**No data lost, checked, not assumed**: the one real session in the whole database (a fixture,
`wow-lab-test-b`) had `language_group = NULL`, and so did every session that ever existed — no UI ever
wrote to the column (confirmed by grep before dropping it). **Also not inferred for any existing
group, on purpose, even the one where it's obvious**: "Școala Franceză (Lycee Francais)" is a real WOW
LAB client with two real groups, unmistakably French-medium by name. Left `NULL` anyway — guessing is
not the same as knowing, same discipline the original column's own "no backfill" comment already
applied to historical sessions, now applied to a group whose language isn't historical, just not yet
confirmed by Anca.

`location_tier` got its first form field ever, on session creation, at the trainer-allocation moment —
same person, same screen. Entered, not derived: checked live before building anything, every WOW LAB
client's `address` is `NULL` today, so a school-side derivation has no structured data to read even in
principle, on top of the trainer-dependency reason above. Pre-fills `bucuresti` only when the assigned
trainer's known home city **and** the group's resolved address (group override, then client default —
the same resolution `GroupInfoSection` already renders, not a second concept) both say Bucharest;
either missing leaves the field genuinely unset, reading as "choose one," not a default that looks
chosen. Stops re-computing the instant a human touches the field, even if they change the trainer
again afterward, so it can never silently overwrite a real choice.

`trainer_home_cities` (`202609240004`): a small table, not a column on `users` (SAD §12.5's placement
reasoning still holds) and not the versioned-grid shape either — a home city has no effective date the
way a grade does, so it's a plain table with real `UPDATE`, no version history, no `row_history`
trigger. Seeded for all 11 active trainers (the same 11 SAD §12.5 counted): Alexandra Nuțu → Cluj,
Viorel Toboșaru → Cernavodă, the other nine (including Luiza Mirt, who has no grade yet but isn't
excluded from this fact) → Bucuresti. SELECT is deliberately broader than the pay grids' own
finance-only gate (`org.settings.manage`/`sessions.create`/`finance.operations.*`/
`finance.reporting.*`) — copying the finance-only shape would have silently broken the one feature
this table exists for, since Operations (who creates sessions) doesn't necessarily hold any finance
capability. WRITE stays owner-only; **where it's edited and by whom is reported, not built this
round** — no UI exists yet, matching `trainer_grade_assignments`' own precedent (seeded via migration,
still no edit screen). Recommendation: `/admin/users`, gated the same as the rest of that page
(`org.members.manage`), not `/payment-config` — this is a per-person admin fact, not a rate grid.

**SAD §12.5 addendum, dated 2026-09-24** (in Romanian, matching the document): records the reversal
precisely — the column was rejected because only 2 of 11 cities were confirmed and no general rule
existed for the rest; Anca has now given all 11, so that premise is gone. The placement conclusion
(not on `users`) is explicitly unchanged, and the addendum says why it still holds even though the
count changed: the *other* half of any derivation — the school's own city — still isn't structured
data, so `trainer_home_cities` enables a suggestion, not the automatic resolution the original section
rejected.

**Verified live on `app.wowlab.ro`, `wow-lab-test-b`** (`scripts/verify_pay_inputs_through_app.ts`,
real Next-Action POSTs through the deployed app, not SQL impersonation): `addGroup` with a language,
then `updateGroup` changing it and adding a Bucharest-looking address, both land; a session for a
Bucharest-based trainer with `location_tier='bucuresti'` (what a confirmed pre-fill would submit)
lands; a session for a Cluj-based trainer with the field left blank lands as `NULL`, not coerced into
a guess. The pre-fill's own boolean condition, evaluated against the real fetched data, is `true` for
the Bucharest trainer and `false` for the Cluj one. The page's RSC payload was confirmed to actually
carry the trainer-home-city and address data the client needs. All five resolvers the future
calculation will call — grade, grade rate, duration multiplier, location bonus, language bonus —
return a value rather than raising, checked via `app.resolve_*` directly (no `public.*` wrapper exists
for these, so `.rpc()` can't reach them — same discovery item 6 of the original payment-config build
made, re-confirmed here) against minimal fixture rates this script seeded into `wow-lab-test-b` for the
purpose and tore down afterward, independently re-confirmed removed (fixture rows: 0; the one
pre-existing 6-row `trainer_grade_assignments` set in that org, dated 2026-09-02, predates this script
and is unrelated to it).

**One honest limit, stated plainly rather than glossed over**: point 3 above (the pre-fill condition)
evaluates the same expression `NewSessionForm` uses, against real data — it does not observe an actual
browser render the form and run the real React effect. No browser-automation tool is available in this
environment. The data the effect depends on (home cities, resolved address) was confirmed to reach the
client correctly (RSC payload check) and the effect's own logic was confirmed correct in isolation; the
two were never observed running together in a live browser.

**Lives in:** `supabase/migrations/202609240003_move_language_group_to_groups.sql`,
`202609240004_create_trainer_home_cities.sql`; `app/(app)/groups/actions.ts`,
`groups-client.tsx`, `[id]/group-detail-client.tsx`, `[id]/group-info-section.tsx`, `[id]/page.tsx`,
`i18n.ts`; `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12.5 (the addendum);
`scripts/verify_pay_inputs_through_app.ts`; item 95 above (the pay grids these inputs feed).

---

### 97. Three findings from walking the trainer view — colleague visibility (already correct), the confirmation control's wording (fixed), start_time on old sessions (recorded, not fixed)

2026-09-24, from Mihai's own manual walkthrough of the trainer-view fixture (item 93).

**1. A trainer's own colleague-visibility — investigated, could not reproduce, and the design question
argued regardless of whether it reproduces.** Read `ConfirmationControl` and the two places that call
it (the desktop `<table>` row and the mobile card) — both already gate the colleague's slot on
`!isOwnSlot && !canCorrect` and, in that branch, render the *state* as a plain read-only label,
confirmed or not. Fetched the real rendered HTML as both trainer fixtures, live, against every session
that existed in `wow-lab-test-b` at the time (two), in both directions (B1 viewing B2, B2 viewing B1),
in both the desktop and mobile markup: all eight combinations showed the colleague's status as text,
never nothing. Could not reproduce "shows the name alone, with nothing underneath" through any request
this session can make. The one thing this can't rule out, stated plainly rather than glossed over: a
client-side-only defect that only shows up after the browser hydrates and React takes over — no
browser-automation tool is available in this environment, so every check here is against the initial
server-rendered HTML, not a live DOM after hydration.

**The design question stands regardless, and the reading is right — argued, not just accepted.** The
confirmation state is a fact about a shared event (the same workshop, worked by both trainers), not a
private fact about the person who set it — the asymmetry that belongs is over the *control*
(confirming is a first-person act: only the assigned trainer can assert "I delivered this," and only
finance/owner can correct it after the fact), not over who can *read* the resulting state. An
unconfirmed colleague, going into month close, is exactly the thing a trainer in that session would
want to notice and flag — hiding it would remove signal from the one person best positioned to catch
it early. No comment, migration, or design doc anywhere in this codebase gives a reason to hide it, and
the code, both before and after today's confirmation-control change, already doesn't. Nothing to build
here; if Mihai still sees this live, it needs a repro he can hand back (device, exact click sequence),
since neither the code nor a live re-test finds the gap.

**2. The confirmation control's wording — fixed.** Read the control's five actual render shapes before
changing anything (not the "four" as first framed — read-only and correction are distinct audiences
with different requirements, see below):

| Viewer | State | Before | After |
|---|---|---|---|
| Read-only (colleague) | unconfirmed | plain "Not confirmed" | unchanged |
| Read-only (colleague) | confirmed | plain "Confirmed" | unchanged |
| Own slot | unconfirmed | empty checkbox + "Not confirmed" | empty checkbox + **"Check to confirm"** |
| Own slot | confirmed | checked checkbox + "Confirmed" | **plain "Confirmed" label, checkbox removed** |
| Correction (finance/owner) | either | checkbox (reflects state) + state-swapped text | checkbox (reflects state) + **constant "Confirmed"** |

The old shape put a checkbox and a state word in the same widget, and let the word swap between
"Confirmed"/"Not confirmed" while the checkbox's own checked attribute *also* carried the state — two
signals for one fact, and an empty box beside "Not confirmed" reads as if the box itself is asserting
that, not offering to change it. New rule, applied everywhere: a checkbox never sits next to text
naming the state it's already in. Own-slot confirming is a one-way action in this control now — once
confirmed, self-unchecking isn't offered; reversing a mistake is finance/owner's correction path, which
was always the intended fix mechanism for a wrong confirmation, not a second way to do the same thing.
Correction stays genuinely bidirectional (fixing either direction is the whole point) but the label no
longer swaps — the checkbox's own on/off state is the only thing that changes, the word beside it just
names what's being toggled.

Consulted the frontend-design skill on visual treatment before building: for a control this small and
this frequent, inline in a dense table, the checkbox element itself (already `accent-brand-pink`) is
sufficient interactive affordance — no additional color/underline treatment was added for the two
click-to-act shapes.

**Verified live on `app.wowlab.ro`, `wow-lab-test-b`**
(`scripts/verify_confirmation_control_through_app.ts`, real Next-Action POSTs, a fresh isolated
group+session so the render check couldn't accidentally match one of the standing fixture sessions'
rows instead): as B1, own unconfirmed slot renders the empty checkbox + "Check to confirm"; as B2
viewing B1's same still-unconfirmed slot, plain "Not confirmed" text, no checkbox — reconfirming finding
1's conclusion from the opposite direction. B1 then actually confirms (a real write, checked via
read-back); afterward B1's own slot renders "Confirmed" with the checkbox gone, and B2 viewing that
same slot sees plain "Confirmed" text. As `test+ui-contract-admin-b@wowlab.dev` (holds
`finance_operations`, satisfying the correction gate): both slots render an interactive checkbox
labeled the constant "Confirmed" — checked for B1 (actually confirmed), unchecked for B2 (never
confirmed in this fixture) — confirming the label never swaps to "Not confirmed" even when unchecked.
All fixtures (session, group, client) deleted afterward.

**3. `start_time` on sessions that predate it — recorded, not fixed, as asked.** `formatTimeRange`
returns `null` when `start_time` is absent, and the caller gates the whole span on that (`{...&&
(<span>...)}`) — so a session with no recorded start time shows nothing at all next to its date, not
even a placeholder dash the way other optional fields (duration, attendance) show "—". Checked live:
exactly one session in the entire database has `start_time = NULL` today (the item-93 trainer-view
fixture, created directly by a service-role script that left it blank, not a genuine historical row —
`sessions` holds only two rows total, both created this week, both after `start_time` already existed
as a column since item 77). So there is no real historical backlog behind this today, but the general
case is real and will recur: `start_time` is optional on the create form, so any future session where
it's left blank will render the same way — no fix requested, and none made; this is the record Mihai
asked for.

**Lives in:** `app/(app)/groups/[id]/group-detail-client.tsx` (`ConfirmationControl`,
`formatTimeRange`); `app/(app)/groups/i18n.ts`; `scripts/verify_confirmation_control_through_app.ts`;
item 93 above (the trainer-view fixture this walkthrough used).

---

### 98. `sessions.location_tier` made visible to trainers, `start_time` always shows its second line — and a known limitation recorded, not fixed: one tier value per session, not per trainer slot

2026-09-25. Two visibility gaps closed, argued before building (report-only pass, previous entry in
this file): `location_tier` was captured on the session form (item 96) but read nowhere afterward —
write-only, invisible to the trainer whose travel it records. No masking precedent applies (the only
financial fields this codebase hides are `contracts.billing_rule`/`estimated_value`, hidden for
commercial secrecy — a fact a trainer already knows about their own trip isn't that kind of secret),
and nothing in RLS or grants blocked it either; the gap was purely an unfinished read side from item
96's own build. Now shown between Duration and Present in the sessions table (mobile: a `Location:`
line after `Duration:`), using the same translated tier labels already built for the entry form,
`—` when unset — the categorical fact, not a bonus percentage (the calculation still doesn't exist).
`language_group` was NOT duplicated onto each session row — it already has a home
(`GroupInfoSection`, always visible, not literally `GroupHeader` as first framed — corrected in the
report), and repeating a value that's constant across a group's sessions would only add clutter and
partially undo the reason it moved off `sessions` in the first place (item 96).

The date cell's second line (`formatTimeRange`) used to render nothing at all when `start_time` was
absent, unlike every other optional value on the same row (Duration, Present), which fall back to
`—`. Now always renders, `formatTimeRange(...) ?? "—"` — in both the desktop table and the mobile
card, which had the identical gap inline next to the date rather than as a separate line.

**Recorded, not acted on, per the explicit instruction: `sessions.location_tier` is one column per
session, not one per trainer slot.** If a session's principal and secundar have different home
cities, the single stored value can only be right for one of them — it was computed (by the pre-fill,
when it fires) or entered against one trainer's travel, but reads as if it describes the session
itself once shown, including to the trainer it wasn't computed for. Today this rarely bites: nine of
the eleven active trainers are Bucharest-based (item 96), so most principal/secundar pairings share a
home city and the single value happens to be right for both. **The trigger to watch for**: a session
where Alexandra Nuțu (Cluj) or Viorel Toboșaru (Cernavodă) co-delivers with a Bucharest-based
colleague — the stored tier will be correct for at most one of the two, and the pay calculation
(`app.calculate_session_pay`, still not built) will read this column directly, so whichever trainer
it's wrong for gets the wrong location bonus with nothing in the schema to catch it. Not a defect to
fix now — recorded here so it's found by its trigger condition, not by a wrong paycheck.

**Verified live on `app.wowlab.ro`, `wow-lab-test-b`**, as a trainer fixture (B1): the session with a
recorded `location_tier` shows its translated label; the one without shows `—`; the time line renders
on both — the session with a `start_time` shows the actual range, the one without shows `—` instead
of nothing.

**Lives in:** `app/(app)/groups/[id]/group-detail-client.tsx`, `[id]/page.tsx`, `i18n.ts`; item 96
above (`location_tier`'s own entry point and the single-column shape this limitation is about); item
97 above (the same walkthrough this continues).

---

### 99. `app.calculate_session_pay` built — the first function in this domain that computes, not just looks up

2026-09-25, as designed in the earlier report. Composes five resolver calls (grade, grade rate,
duration multiplier, location bonus, language bonus) into `rate × duration_multiplier × (1 +
location_bonus/100 + language_bonus/100)`, unrounded — `bonus_percent` columns store whole percent
(25, not 0.25), divided by 100 the one place this shape actually multiplies anything. Named and
shaped deliberately unlike the seven `resolve_*` functions it calls: those are pure lookups, this
composes and does arithmetic, and gets a different name to say so rather than the resolver shape
stretched to cover something it wasn't built for.

**Per trainer, not per session — and refuses when the trainer isn't on it.** Takes `p_session_id` and
`p_trainer_id`; raises if `p_trainer_id` is neither the session's principal nor secundar. A pay figure
for someone with no part in the session isn't a cautious answer, it's a wrong one — same reasoning as
every fail-loud choice in this function.

**Never calls `app.resolve_contract_type_uplift`, with the reason recorded right where the four (five)
resolvers are composed**, not only in the migration's own header: the PFA-inclusive rates already carry
the uplift (item 95 above), calling it here would double it, and `contract_type_uplift` stays at zero
rows for exactly that reason. **This line said "the 11.1% uplift" until 2026-10-12; it is 11% —
corrected per item 128 below, which measured it.**

**delivery_context comes from the group, never the session** — sessions carry no format of their own.
Confirmed, not assumed, by reading `app.resolve_duration_multiplier`'s own case statement (not by
re-deriving the nine-format list from memory): of the nine workshop types, only `scoala_altfel` and
`saptamana_verde` map to `scoala_altfel_saptamana_verde`; the other seven (`wow_lab_party`,
`parteneriate_companii`, `cursuri_deschise`, `scoli_private_ocazionale`, `scoli_private_recurente`,
`evenimente_mall`, `party_companii`) resolve as `standard`. Matches the reading in the design report
exactly.

**Missing-input behavior, reported as asked:** session-or-group-level facts that were simply never
entered (`duration_minutes`, `location_tier`, the group's `language_group`) now raise a message from
`calculate_session_pay` itself, naming the specific field and row — added deliberately rather than
letting a `NULL` flow into a resolver's own `WHERE tier = p_location_tier` clause, which would still
raise (no row matches `NULL`) but with a vaguer "no row for [blank]" message. Genuine grid gaps (no
rate for this grade, no multiplier for this exact duration) are raised by the resolver itself, whose
own message already names the input and organization precisely — not caught or rewrapped here, so the
caller sees exactly which resolver failed.

**SECURITY INVOKER, matching all seven resolvers' own reasoning — with a consequence worth stating
plainly:** this function has no authorization check of its own, so today only a caller who already
holds read access to `trainer_grade_rates` etc. (`finance.operations.*`/`finance.reporting.*`/owner)
can successfully call it; a plain trainer's own session cannot, even to compute their own pay. Not
fixed — nothing calls this function yet, and the eventual caller is expected to be finance-facing,
matching every other pay-grid read in this codebase. Revisit only if a trainer-facing caller is ever
proposed.

**Tests, `db/tests/calculate_session_pay.sql`, run by `run_rls_suite.ts`** (not `rls_`-prefixed, no
authorization branch of its own to test — same naming choice as `capability_liveness.sql`): the known
case (grade 3/Teodora, 90min standard, imprejurimi, fr_de_es) asserted to equal `220.98` exactly; a
missing grade assignment (Luiza Mirt, who still has none — item 95) raises rather than returning
zero/null; a trainer not on the session is refused, with the raised message asserted to actually name
"principal or secundar," not just any exception; `scoala_altfel` at 120 minutes computes through to
`368.30` (the 2.0 multiplier) against a `parteneriate_companii` group's `276.225` (1.5) built from
otherwise-identical fixtures, so the only variable proven to matter is the group's own delivery format;
a sabotage block temporarily redefines the function to round its own result and confirms the exact-
equality assertion in the known case actually fails against that regression — the one this function
was explicitly built to never have (item 95's own reversed rounding assumption). All fixtures live
inside transactions that always roll back, using WOW LAB's real seeded rates rather than synthetic
numbers, so the "known case" is checked against the same figures Anca actually confirmed. Full suite:
96 passed, 0 failed, 0 block errors across 10 files (up from 91 before this file).

**Verified by hand against the real historical row.** The report two rounds ago verified `114 × 1.2 ×
1.45 = 198.36` was a real approved payment under the OLD net rates; recomputing the identical shape on
the new PFA-inclusive rate (grade 3 = 127, same 1.2/1.45) gives `127 × 1.2 × 1.45 = 220.98` — exactly
what `db/tests/calculate_session_pay.sql`'s known-case check asserts, confirmed both by hand and by the
function.

**Nothing calls this function yet — no UI, no payroll screen change, by design.** That's the next round.

**Lives in:** `supabase/migrations/202609250001_create_calculate_session_pay.sql`,
`supabase/rollbacks/202609250001_create_calculate_session_pay_rollback.sql`,
`db/tests/calculate_session_pay.sql`; item 95 above (the pay grids this composes and the rounding
reversal); item 96 above (`location_tier`/`language_group`'s own entry points, the inputs this reads).

---

### 100. A team directory was built and reverted — its RLS branch blinded an existing sabotage check; plus four reusable probe methodology errors

2026-09-25. A `/team` directory (name + role per person, no contact fields) was built, its RLS branch
applied live, and then reverted in full before anything was committed. Nothing shipped; the database
is back to its pre-change state, migration record included (`db push` had recorded migration 202609250002 as
applied while the effects were hand-reverted — history and schema disagreed until that row was
deleted), and the suite re-verified at 96 passed / 0 failed with the original sabotage check flipping
correctly again.

**Why it was reverted — the second reason, not the first, is what decided it.** The branch said: any
member of an organization may read any other member's `users` row and `user_org_roles` row. That
(a) overrode `202609160001`'s deliberately narrow scoping — that migration's own comment states "the
fix must not hand anyone names they should not see, so neither branch is 'finance/trainers can see
everyone'" — and the suite caught it immediately (`finance_ops_a: does NOT see sales_a's user row`,
actual="1", expected="0"). More seriously, (b) **it blinded an existing sabotage check**:
`rls_users.sql`'s guard, which exists to detect breakage in `app.viewer_sees_trainer_via_finance_ops`,
could no longer fail, because the new broad branch covered whatever that helper stopped doing. The
runner reported it exactly: "sabotage did NOT flip to false — this check has no teeth."

**Third instance of the same shape** — a change that applies cleanly, errors nowhere, and removes a
safeguard's ability to detect a regression. Item 68 (an RLS branch that applied and evaluated to false
for every caller it was written for), item 92 (`REVOKE UPDATE (column)` silently overridden by a
surviving table-wide grant), and now this: not a wrong result, but a guard that can no longer report
one. The first two were caught by a test that existed; this one was caught by a test that existed and
was about to be silently disabled. Worth stating as the pattern's sharpest form so far: **the failure
mode isn't only "my change is wrong," it's "my change makes an existing check unable to tell anyone
that something else is wrong."**

**Four probe methodology errors, recorded because they are reusable and each cost real time.** The
first three are RLS-probe errors from the directory work; the fourth came from a through-app
verification a day later (item 101) and is recorded here because it belongs with them, and because its
general form is different from theirs:

1. **An ad-hoc probe that sets `request.jwt.claims` without also issuing `set local role authenticated`
   measures nothing.** `supabase db query --linked` connects as a superuser, which holds BYPASSRLS —
   the JWT claim changes what `app.current_user_id()` returns while RLS is never enforced at all. Such
   a probe returns identical results whether the policy under test works or not. The first version of
   this round's verification "passed" four of five checks this way, and the one that "failed" produced
   a false cross-org-leak alarm that cost a full diagnostic detour. The existing `db/tests/` suites do
   this correctly; the mistake was in ad-hoc SQL written alongside them.
2. **A probe against `public.users` must identify people by `id`, never by `email`.** `authenticated`
   holds no table-level SELECT on that table (202608200005 step 3 revoked it) — only column-level
   grants that exclude `email`/`phone`. A `where email = '...'` probe fails with "permission denied for
   table users" regardless of RLS, which reads like a policy result and isn't one.
3. **A probe must use a subject who does not already satisfy some other branch, or the branch under
   test is masked.** The first "same org, no shared session" check used trainer b1, who *does* share
   sessions with the viewer — the pre-existing shared-session branch would have carried it whether the
   new branch worked or not. Trainer b3 (same org, genuinely no shared session) was the honest subject.
   This is the probe-design equivalent of a sabotage check: choose a subject where only the thing under
   test can produce the result.
4. **Two assertions that can only ever agree are not two pieces of evidence.** Verifying `/my-work`
   through the deployed app, a regex holding a literal apostrophe was matched against a page that
   renders `aren&#x27;t`. On one fixture it reported the unconfirmed warning **missing** when it was
   plainly present; on the other it reported **no warning present**, which was the expected answer.
   The two read as mutually confirming — one positive, one negative, consistent with each other — and
   both measured nothing, because neither regex could match either page. The probe now decodes entities
   before matching. **The general form differs from the three above, which are all "this probe measures
   nothing": a failing assertion announces itself, but a pair of assertions that can only ever agree
   looks like corroboration.** Two checks are not independent evidence if they share a defect — the
   agreement is a property of the shared defect, not of the thing under test. The pairing that makes
   this dangerous is exactly the one that feels most rigorous: assert the thing is present where it
   should be, assert it is absent where it should not be. Both halves must be able to fail *for
   different reasons*, or the mirror is one assertion wearing two hats.

**Found while reverting, and it decides what a no-migration directory can actually show:** under the
unchanged policies, a trainer sees **two** `users` rows (themselves and a co-trainer from a shared
session) but exactly **one** `user_org_roles` row — their own. The shared-session branch exposes a
co-trainer's name and nothing else. So a directory built without any migration can show a trainer
names, but cannot show those colleagues' roles at all — not "they have no role," but "you may not read
that row." A two-column Name/Role screen would have one structurally-always-blank column for the
largest group of users in the system.

**Built, evaluated, and dropped before shipping — not because the data was missing, but because of what
the screen would assert.** Only **4 of 14 roles** hold `org.members.read` (`organization_owner`,
`platform_owner`, `operations_manager`, `finance_admin_reporting`) — that capability is what makes
another person's `user_org_roles` row readable. For the other **10**, including every Trainer and
Senior Trainer and Laura (who holds `contract_administrator` + `finance_operations`, neither of which
carries it), the Role column is blank for everyone but themselves. **A blank cell reads as "this person
has no role"; the truth is "you may not read that row."** Replacing blanks with this codebase's
existing "not visible for your role" placeholder (the `client_hidden`/`contract_hidden` shape) is the
honest rendering — and makes the screen, for 10 of 14 roles, a list of names beside a column of
permission notices. Item 1's shape exactly: one real column and one structurally empty one, for the
majority of viewers.

**Unlike the overdue-contracts precedent, nothing needed rehoming.** That decision moved a real signal
onto the page that owned it. Here there is no orphaned signal: a trainer's actual need — knowing who
they deliver a workshop with — is already answered on the session row, which names both trainers.

**The one gap it would have closed, recorded unserved:** `operations_manager` and
`finance_admin_reporting` — Cătălina's roles among them — *may* read the full roster and have no screen
that shows it. `/admin/users` is gated on `org.members.manage`, which neither holds. That is a real
want for two roles, and a different screen from the one asked for. Not built. **Trigger: someone
actually needing it and saying so** — not the mere fact that the data is available to them.

**Open, for Anca — a product question, not a technical one: should every member of an organization see
every other member's name and role?** Today they do not. That is not an oversight: it follows from a
decision taken 2026-09-16 (`202609160001`) that deliberately scoped people-visibility narrowly, for a
different purpose entirely (making trainer names resolve on payroll and co-trainer views without
handing anyone a general roster). A full directory reverses that decision. It is defensible to reverse
— knowing who your colleagues are is ordinary — but it needs to be reversed *deliberately*, with the
two tests that encode the current boundary rewritten as a recorded reversal and that sabotage check
rebuilt so it still has teeth against something, not quietly overwritten to match new behavior.

**Lives in:** `202609160001_add_users_trainer_name_visibility_branches.sql` (the scoping this would
reverse); `db/tests/rls_users.sql` (the two checks that caught it, including the blinded sabotage);
item 68 above and item 92 above (the first two instances of this shape); item 21 below
(`users.status`, for why live checks beat stored columns generally).

---

### 101. The trainer's own work page — five figures that are honest once data exists, and one that isn't built because it can't be

2026-09-25. `/my-work`, gated on `mywork.*` so it appears for exactly Trainer and Senior Trainer —
one screen for both, as asked. **Deliberately not called "Dashboard"**: item 1 declined an org-wide
dashboard, and reusing the word for a trainer-scoped page would read to a future editor as that
decision being reversed.

**Every figure was confirmed readable by a trainer before anything was built** — checked against the
live policies, not assumed, because two of them looked finance-gated and weren't:
`trainer_grade_assignments` has `trainer_id = app.current_user_id()` as its *first* branch, so a
trainer reads their own grade holding no finance capability; and `payroll_periods` lists `mywork.*`
as an explicit branch, so a trainer can genuinely read whether their own month is closed. That second
one is what makes the warning below actionable instead of merely alarming. **No schema change was
needed for any of it** — in contrast to item 100's directory, this page sits entirely inside
boundaries that already exist.

**Counted by confirmation, never by `sessions.status`.** These already disagree in every row that
exists: both live sessions are `status='planned'` with both trainers' confirmations set. `status` also
carries its own separate value literally called `confirmed`, so three different things could be read
as "confirmed" and two of them are Operations' scheduling state rather than the trainer's own
assertion. Pay follows the timestamp (`202609150002`: "Pay follows this timestamp, not
attendance_count or status"). What "delivered" ought to mean stays **open for Anca** — and this page
deliberately does not settle it by quietly picking a column.

**The unconfirmed warning is one sentence, not two figures**, because the month's close state changes
what the person can still *do*, not just a number beside it: "1 of your sessions aren't confirmed yet.
September 2026 is still open — confirm them and the pay for them stands" versus "…already closed — you
can no longer confirm them yourself. Ask Operations to correct them." At zero it degrades to a quiet
muted line, not a green success banner: confirming your own sessions is ordinary, not an achievement.
It counts only sessions already in the past — a workshop next week isn't late, and counting it would
turn a normal state into a warning.

**Hours carries its caveat at normal size under the number, not as a footnote**, being the figure most
likely to be misread as pay — which it isn't: pay counts two hours as 1.5×, and the grade rule counts a
two-hour workshop as one workshop. Exact wording shipped, EN: "Hours in front of a class this month" /
"Time taught — not your pay. Pay counts a two-hour workshop as 1.5×, and your grade counts it as one
workshop." RO: "Ore la clasă luna aceasta" / "Timp predat — nu este plata ta. Plata socotește un atelier
de două ore ca 1,5×, iar gradul îl numără ca un singur atelier." It also declares when sessions lack a
recorded length rather than silently undercounting.

**Grade is shown; distance to the next threshold is not.** The rule is fully specified and
Anca-confirmed (`grad = min(6, floor(workshops / 36) + 1)`), but the workshop counts behind the seeded
grades live in Anca's own file, not this database — counting live would return 0 for every real trainer
and contradict the seeded grade for nine of ten. **Certifications to renew was not built at all**: no
table, no domain, nothing to compute; it could only have been a hardcoded number or a permanent dash.

**Empty state: one plain sentence, not a grid of five zeros.** Five zeros read as a broken page; one
line reads as a true one. The grade still shows when set, since it's true regardless of allocation —
verified live against Test Trainer B3, who has a grade and no sessions at all.

**Verified live on `app.wowlab.ro`, `wow-lab-test-b`** (`scripts/verify_my_work_through_app.ts`): as
Test Trainer B1, set up with one confirmed and one unconfirmed session — warning present naming the
month and its open state, confirmed count correct, hours caveat present, grade shown, empty state
correctly not triggered; as Test Trainer B3 — the one-line empty state, no zero-figure grid, grade
still shown. B1's confirmation was restored to its original value afterward; the standing fixtures are
as they were found.

**The first run of that verification was wrong in both directions at once** — an HTML-entity mismatch
that made a mirror pair of assertions agree with each other while neither could match anything.
Recorded in full as item 100's fourth probe error, not duplicated here.

**Where it lives — reported, not changed.** It sits beside `/profile`, and `app/page.tsx` still
redirects everyone to `/profile` after login. Making `/my-work` the post-login destination for
`mywork.*` holders is the obvious next step and is deliberately *not* taken yet: today every real WOW
LAB trainer has zero allocated sessions, so that redirect would land all of them on the empty state as
their first impression of the app. The right trigger is real allocations existing — at which point the
redirect is a two-line change in `app/page.tsx`, gated the same way the nav item already is.

**Lives in:** `app/(app)/my-work/page.tsx`, `my-work-client.tsx`, `i18n.ts`; `app/(app)/layout.tsx`
(the `mywork.*` nav gate); `scripts/verify_my_work_through_app.ts`; item 1 above (the bar this was
measured against, and the name this deliberately avoids); item 100 above (which holds all four probe
methodology errors, the fourth of them found here).

---

### 102. Custom restored as a tenth workshop type — plus what was quietly edited out of Anca's list at seed time

2026-09-25. `custom` returns to `groups.delivery_format` as a tenth value (`202609260001`), four days
after `202609210006` removed it. The removal was correct at the time and said so in writing: *"Anca's
decision was 'these nine replace the six,' not 'these nine plus a fallback.' Not invented here; if a
workshop genuinely doesn't fit any of the nine, that is now a real gap to surface, not silently
absorbed."* **The gap was surfaced exactly as intended, and the person it was deferred to answered
it.** This is that answer, not a reversal taken on our own authority.

**Strictly additive, unlike its predecessor.** Widening a `CHECK` constraint cannot invalidate an
existing row, so no data was rewritten — where `202609210006` remapped three live rows by id, this
migration touches none.

**Nothing behavioural needed changing, and that is a finding rather than an omission.** Both places
this app branches on `delivery_format` are **positive** tests against explicit values, never negative
or substring tests, so `custom` lands on the correct side of each by construction:
- `app.resolve_duration_multiplier` — `case when p_delivery_format in ('scoala_altfel',
  'saptamana_verde') then ... else 'standard' end`. `custom` → `standard`, which is right on two
  independent grounds. Semantically, that context exists because those two **named national
  programmes** pay ×2.0 at 120 minutes instead of ×1.5 — it is keyed to a programme schedule, not to
  "bespoke," and `custom` is by definition neither programme. Structurally, `standard` is seeded with
  a 30-minute row and `scoala_altfel_saptamana_verde` is **not**, so a 30-minute custom workshop
  mapped to the programme context would raise *"no row for 30 minutes … incomplete version"*.
  Standard is both correct and the only complete option.
- The "recurring" distinction (`trainer-resources-section.tsx`, `groups-client.tsx`) — both are
  `=== "scoli_private_recurente"`. `custom` is one-off on both, correctly: it has no recurring
  schedule pattern. `202609210006`'s own comment already committed to this — *"means
  scoli_private_recurente ONLY … not by a 'recurring' substring check"* — and `custom` is exactly the
  case that rule was written to survive.

**This is now a pay-affecting path, which it was not on 2026-09-21.** Item 79 measured
`resolve_duration_multiplier` as having no caller anywhere. `app.calculate_session_pay`
(`202609250001`) now calls it. Nothing calls `calculate_session_pay` yet, so no pay moves today — but
the duration context stopped being dormant, which is why `db/tests/custom_workshop_type.sql` asserts
`custom → standard` **by value** (1.5 at 120 minutes, against the real seeded WOW LAB grids) with the
two programmes checked alongside as controls. Asserting behaviour this migration does *not* change is
the point: it is the behaviour most likely to be broken later by someone who reads the ten-value list
and assumes `custom` is special.

**Three of Anca's own explanatory examples were dropped at seed time and exist nowhere else — recorded
here verbatim, as meaning rather than as labels.** Her source dropdown in `Fielduri pentru planificare
ateliere.xlsx` appended a worked example to three of the nine lines. None survived into the RO or EN
labels, into the schema, or into this register until now. They are hers, and they say what each type
means in practice better than the label does:

| Type | Her line, verbatim |
|---|---|
| `cursuri_deschise` | `Cursuri deschise - Exemplu Cursuri de chimie` |
| `scoli_private_ocazionale` | `Scoli private (colaborări ocazionale) - Exemplu Science Week la IBSB` |
| `evenimente_mall` | `Evenimente/prezentari la mall - Exemplu Barlad Value Center` |

They are **not** proposed as labels — a dropdown value should not carry a worked example. They are
recorded so that the question "what did Anca actually mean by *Cursuri deschise*?" has an answer that
is hers, not a later reconstruction.

**The Romanian labels are her words with orthography repaired, not her words verbatim — stated plainly
so nobody later reads "exactly as Anca wrote them" literally and concludes the labels are wrong.**
Two separate edits sit between her source file and the shipped strings:
1. **Diacritics were added by us.** Her dropdown reads `Scoala Altfel`, `Scoala Verde`,
   `Evenimente/prezentari la mall`, `Party in companii` — no diacritics anywhere in the file. The
   labels restore them (`Școala Altfel`, `Evenimente/prezentări la mall`, `Party în companii`).
2. **`Scoala Verde` → `Săptămâna Verde` was her own later correction**, made on 2026-09-21, not a
   transcription by us — `202609210006` records it as such. The key stayed `saptamana_verde`
   throughout.

Anyone diffing the shipped labels against `Fielduri pentru planificare ateliere.xlsx` will find
mismatches on both counts. Both are intentional; neither is drift.

**English labels, and the one that changed.** `party_companii` was `"Company parties"` and is now
`"Wow Lab Party at a company"`. Anca's Romanian uses the English loanword *party* deliberately: this
is the **same product** as `wow_lab_party` delivered at a company rather than for a child's birthday.
The old label severed that link — an English reader saw *Company partnerships* / *Company parties* as
the matched pair and *Wow Lab Party* as unrelated, which is backwards. `custom` is `"Custom"` in both
languages: the word Anca confirmed, already a Romanian loanword, and the same label the pre-2026-09-21
six-value list carried. *"Other"* would be clearer English and is not what she said.

**`Școala Altfel` and `Săptămâna Verde` stay Romanian in the English UI, deliberately.** They are
Ministry of Education national programmes — proper nouns, not descriptions. *"School Differently"* and
*"Green Week"* would name nothing a user could look up, would not match the name on the school's own
calendar or contract, and read as two variants of one thing when they are two distinct programmes the
pay grid already treats as one shared ×2.0 context. **This is not a new rule: it is the rule the
thirteen `module_*` labels already follow, in mirror** — those are English-origin proper nouns kept
untranslated in the *Romanian* UI (`module_chem_me: { en: "Chemistry for Me", ro: "Chemistry for Me" }`).
A proper noun has one name. An English-only gloss (`"Școala Altfel (national school programme)"`) was
considered and rejected: it helps a first-time reader once, then pads a table cell and a filter
dropdown forever, and would be the only explanatory text in a dictionary of ~100 labels.

**Two unexplained rows in `wow-lab-test-b`, found while verifying this — and the first explanation
recorded here was WRONG. Corrected 2026-09-28, in place, with the error left visible:**

**What was originally written here:** that both were leftovers from an interrupted
`scripts/verify_item91_write_paths_through_app.ts` run, on the strength of the payroll period's
`closed_by` being null — that script inserts a closed period without a `closed_by`, and registers a
cleanup that evidently had not run.

**`closed_by` was never null.** It is `3a228d95-ac3f-4b73-81d5-d57e1065f0f3` —
`maxdigitalro+testorg@gmail.com`, an `organization_owner` of Test Org B. The original query selected
`u.full_name` through a `left join public.users u on u.id = p.closed_by`, and that user's `full_name`
column is itself null, so the result set showed `closed_by: null` for a row whose `closed_by` is a
real uuid. **A joined column was read as if it were the base column.** Same family as item 100's four:
the probe measured something other than what its result was labelled.

**And it reached a committed register entry before anyone checked it.** This is the part worth keeping.
The wrong claim was not a passing remark in conversation — it was written into this file, with a named
script as its cause, committed, and pushed, on the strength of a single query whose output was never
re-read against the column it claimed to show. **Nothing in this project's discipline caught it; the
only reason it surfaced was that the next instruction was to act on it** (delete the rows), and acting
required re-reading the row. Had the instruction been "leave them," the false attribution would still
be sitting here, blaming a script that did nothing. **A committed register entry carries more
authority than the evidence behind it, and this file has no mechanism that distinguishes the two** —
`check_open_items_register.ts` validates cross-references and filenames, not claims.

**What the evidence actually says, re-checked directly:**
- `app.closePayrollPeriod` (`app/(app)/payroll/actions.ts`) is the **only** path that writes
  `closed_by`, and it writes the signed-in `user.id`. `verify_item91` inserts `{organization_id,
  period, closed_at}` with no `closed_by` at all. A non-null `closed_by` therefore **excludes** the
  script and **requires** a real signed-in session.
- **No script anywhere in `scripts/` references `maxdigitalro+testorg@gmail.com`, and none calls
  `closePayrollPeriod`.** Checked by grep across the whole directory.
- `verify_item91`'s group fixture is `gaga` / `wow_lab_party` under a client named *"DRYRUN item91
  through-app client"* — **not** the fourth group, which is `doctor` / `party_companii` under the
  standing `MAX` client. No script in the repo creates that combination.
- The group was created 2026-09-25 10:50:16Z, **3m48s after** the period was closed at 10:46:28Z, by
  which time a person was demonstrably signed in and acting in that org.
- `addGroup` writes `notes.trim() || null`, so a null `notes` is exactly what the create form produces
  when the field is left empty — it is evidence of app use, not of script use.

**Conclusion: both rows are deliberate human actions in the test org, not drift. Neither was deleted.**

**No trail existed to check this against** — the absence of a `row_history` row for the fourth group
proves nothing, because that trigger never fires on INSERT. Recorded separately as **item 104 below**,
since it is a general limit of this database rather than a fact about these two rows.

**The suite's hidden dependency on this fixture — FIXED 2026-10-02, in the suite, not the fixture.**
Two checks (`confirmSessionAttendance: own slot succeeds`, `updateSessionAttendance: own row
succeeds`) were failing with `actual="month_closed"` because Test Org B's September period is closed
**on purpose**. The fixture was correct; the suite was wrong to assume anything about it.

**It then self-healed on 2026-10-01, which is the more alarming half.** The fixture session was dated
`current_date`, and both RPCs gate on the session's *own* month (`202609220001`: `pp.period =
date_trunc('month', v_session_date)`). When the calendar rolled into October — a month with no closing
row — the checks began passing again with no change to any code. **A check whose result depends on
which month it is run in is not a check**, and for one week it was reporting green for a reason
unrelated to what it tested.

Both halves of the fix were needed because they remove different dependencies:
1. **A pinned `session_date` (`2020-01-15`)** replaces `current_date`, so the block exercises the same
   month on every run, forever — this is the "assert against a month it controls" shape.
2. **A `delete from public.payroll_periods` for that pinned month inside the transaction** turns "this
   month is open" from an assumption into an *enforced precondition*, so closing any month can never
   break the block again. Isolated by the block's own rollback, and against a month that far from real
   activity it will essentially never match a row — a guard, not a mutation.

**The gate itself had no coverage anywhere in `db/tests/` and now does (Point 2b, 3 new checks).**
Nothing asserted that the RPCs return `month_closed` when the month *is* closed. The gate has existed
since `202609220001` and could have been deleted outright without one check noticing — Mihai closing
September was, by accident, the first thing ever to exercise it. The new block closes the pinned month
*inside* its transaction and asserts both refusals, plus a control that
`rpc_correct_session_confirmation` is deliberately **not** month-gated (item 91 — Finance correcting a
closed month is that path's whole purpose), which is what would catch a blanket gate added across all
four. **This pairing is item 100's fourth probe error applied deliberately rather than tripped over:**
Point 2's two `ok` checks pass both when the gate works and when it does not exist; paired with Point
2b the two halves can only fail for different reasons.

**Proven independent of the fixture, not argued.** A temporary block closed **both** the current month
and September inside a rolled-back transaction and re-ran Point 2's two assertions — both still
returned `ok`. Under the previous version, closing the current month is precisely what broke them.
`public.payroll_periods` was re-read afterwards and still holds exactly the one real September row.
Suite: **111 passed / 0 failed** (108 + 3), with September closed, and with the current month closed
too.

**One error on the way, and it was also one of item 100's four.** The first version of Point 2b looked
up the finance fixture's id with `where email = '...'` *after* `set local role authenticated`, and the
block died on `permission denied for table users` — `authenticated` holds no table-level SELECT on
`public.users` (202608200005 step 3), only column grants excluding `email`. That is probe error #2,
recorded in item 100 by me, reproduced by me, eleven days later. The id is now resolved in the
superuser phase with the other fixtures.

**Lives in:** `supabase/migrations/202609260001_add_custom_workshop_type.sql` +
`supabase/rollbacks/202609260001_add_custom_workshop_type_rollback.sql`;
`db/tests/custom_workshop_type.sql`; `app/(app)/groups/i18n.ts`, `groups-client.tsx` (`FORMAT_KEYS`);
item 79 and item 85 above (the mapping and the nine-value migration this extends); item 92 above (the
last time a constraint/grant looked applied and was not); item 103 below (the three-axis model this
vocabulary sits inside).

---

### 103. Three axes, not three competing lists — the eight-week-old "Tip atelier" question answered, and the one it leaves open

2026-09-28. Two curriculum spreadsheets and a Phase 1 epic proposing a 19-value "Tip atelier" list
were investigated together. **The headline: the epic does not supersede Anca's 2026-09-21 decision. It
predates it by 52 days, and no live data was changed on a stale decision.**

**The three lists are not three versions of one thing. Two are axes; the third is those two flattened
into one field.**

| | `groups.module` | `delivery_format` (the nine, +custom) | The epic's 19 |
|---|---|---|---|
| Question it answers | **what is taught** | **how / to whom it is sold** | both at once |
| Source | `Centralizator module WOW LAB 2023-2024-2025.xlsx` | `Fielduri pentru planificare ateliere.xlsx`, the `Tip Atelier` dropdown | Anca's Phase 1 feedback |
| Live | **13 keys** | 10 values, 3 real rows | nothing |

A third axis exists below both and is **entirely unmodelled**: the **lesson plan** — which specific
experiment was run. Today that is `sessions.experiment_delivered`, free text a trainer types.

**The date, git-verified, because this was the load-bearing question:** the mockup commit `edfab8a`
(**2026-07-31**, the file's first commit, `--diff-filter=A`) already carries the banner *"Feedback-ul
Ancăi (Phase 1) cere … o taxonomie nouă «Tip atelier» pe module — de reconciliat înainte de
construcția reală, nu taxonomie finală."* The feedback it names is dated **2026-07-30**. Anca's
nine-value decision is **2026-09-21**. The epic is the older input; the decision is the newer one.

**And the epic's commercial half is the vocabulary she replaced.** Its five non-module values
(Săptămâna Altfel, Săptămâna Verde, Party, Custom, Corporate) are *exactly* the pre-decision
`DELIVERY_FORMAT` object minus `recurring` (`wow_lab_os_mockup.html` line 434: `recurring`, `sa`
Școala Altfel, `sv` Săptămâna Verde, `party`, `corporate`, `custom`). **Adopting the epic literally
would be a rollback**, collapsing `scoli_private_ocazionale`, `scoli_private_recurente`,
`cursuri_deschise`, `evenimente_mall`, `parteneriate_companii` and `party_companii` back into
`Corporate`/`Party`. Its naming drift confirms the direction of travel: it says *Săptămâna* Altfel;
the programme is *Școala* Altfel in the mockup and in Anca's own spec — a conflation of two programme
names, i.e. a drafting-stage error, not a considered revision.

**The strongest argument for keeping her nine is that they are not a new scheme at all — they match
the historical billing codes one to one.** The mockup's `TIPS` object holds the codes the work has
actually been invoiced under (`SP`, `SPCO`, `SA`, `SV`, `COM`, `EPC`, `EP`, `CD`, `WLP`), and the nine
map onto them 1:1. Her list is a description of how this business already bills, written down. The
epic's five are a coarser vocabulary that no invoice uses.

**Two arithmetic/consistency facts worth keeping, because each is evidence about what the 19-value
list is:**
- **14 + 6 = 20, not 19.** The count closes only if `Chimie liceu` is one of the 14 — and it is:
  `chem_hs`, "Chemistry for Highschool", already a module. **One value is simultaneously a curriculum
  module and a commercial format**, which is the clearest possible demonstration that the list
  flattens two axes.
- **"Disciplină," the field the epic proposes to replace, does not exist.** Zero hits across the whole
  codebase, and all 44 shared strings of `Fielduri pentru planificare ateliere.xlsx` were read
  directly: 28 fields, `Tip Atelier` present at index 8, **no `Disciplină`**.

**The question was asked for in writing three times and never actually asked.** `wow_lab_os_mockup.html`
line 952 (*"de reconciliat înainte de construcția reală"*), line 767 (*"nu unul combinat «tip
atelier», cum s-a sugerat inițial"*), and the `MODULES` comment from `d06e3a4` (*"interpretare de
confirmat cu Anca, nu decizie finală"*). `202609210006`'s own column comment says the same from the
other side: *"The module+delivery_format SPLIT itself (vs. a single 'Tip atelier' field) remains
Mihai's own interpretation, unconfirmed by this decision — only the delivery_format vocabulary was
decided."* **Anca settled the vocabulary of one axis. Whether there should be two axes at all has
never been put to her.** That is the open question this entry closes the investigation on but does not
resolve.

**Caveat, stated because the conclusion rests on it:** the epic itself is not in this repo and was
never read. The date bound does **not** depend on that — it rests on the mockup banner and its commit
— but identifying "the banner's ask" with "the epic in hand" is an inference from a close shape match
(both: replace one field with "Tip atelier", values are the modules). **The epic's created-date in
Asana settles it in one minute** and is worth checking before anything is said to Anca.

---

**Genuinely open, and separable from the taxonomy argument entirely: do Anatomy and Vet become modules
14 and 15?** This half of the epic is *not* superseded by anything, and the curriculum file
corroborates it independently. It resolves the long-unexplained "13 din 15": 13 confirmed + Vet +
Anatomy = 15. Crăciun is a third extra sheet and was never one of them — it holds **zero** lesson-plan
filenames, no plan column at all, YouTube links under a `Link` header, a `feedback Cata` column, and
two seasonal banners (`B1='Christmas /  Winter science experiments'`, `K1='Halloween themed
experiements'`). It is an idea list, not a module.

- **Anatomy — real, but being carved out of `doctor` mid-flight.** Only **6 of its 23** rows carry a
  real filename; the other 17 are chapter pointers (`1. Lungs`, `17. Immune system`). **6 plans sit on
  both sheets** — `ANAT_TourThroughTheCellCity_DC_1`, `TheInvisibleArmy_DC_2`,
  `BuildingBlocksOfLife_DC_3`, `SeeingDNA_DC_4`, `MrBones_DC_5`, and `ANAT_Germes&Hygene_SG_18.xlsx`.
  Two authors (DC, RP) split it. Adding it as a 14th value today would duplicate content that
  `doctor` already carries.
- **Vet — named, scoped, assigned, and empty.** The sheet has **0 non-empty cells** (`A1:A1`) and is
  **the only hidden sheet in the workbook** — someone deliberately took it out of view. Yet file 2's
  `Veterinar` sheet holds an allocation block headed `I WANT TO BE A VET` with 6 named lessons (Cow
  digestive system, Ears and sounds, Vaccination, Birds, Animals nutrition, Animals in urban areas),
  **all assigned to one person, `GABI`**, with not one plan written. Adding it to `public.modules`
  today creates a module a trainer can select and find nothing behind.

**The authorship reconciliation — the key the register has been missing.** Item 45 part 3 records 31
plans Anca reported on 31.08.2026 with no way to attribute them. `Module noi 2025 - idei de
lectii.xlsx` is that record: an `Alocare planuri de lectie` assignment register plus 10 per-person
sheets carrying **author, lesson, module, completion date, review state, and whether it was paid and
in which month**. **The two files join on author-initials + module-prefix + sequence number**, and the
31 tie out exactly:

| Person | Reported | Measured |
|---|---|---|
| Raluca Popa | 17 | her sheet numbers **1–17 contiguous**, plus 3 deliberately unnumbered |
| Răzvan Bălașov | 4 | `GRE_`/`GGA_` are `RB_1..7`; `ASTRO_RB_8,9,10,11` — **exactly 4 astronomy plans** |
| Teodora Merișan | 10 | her sheet numbers to **10** (with duplicate 5s, 7s, 9s across 14 rows) |

**The join key is (prefix, initials, number), not (initials, number)** — measured, not assumed:
`(initials, number)` collides for **51 of 225 keys (22.7%)**, `(prefix, initials, number)` for **4 of
272 (1.5%)**. Author DC alone runs two parallel sequences both starting at 1 (`ANAT_*_DC_1..5` and
`ASTRO_*_DC_1..12`).

**But the attribution it supplies mostly points nowhere.** 18 distinct sets of initials appear across
455 parsed filenames. **The two highest-volume authors resolve to no account in this system at all:
`GS` with 118 plans and `DC` with 66** — together 184 plans, 40% of the catalogue, by two people the
platform has never heard of. `RB` (Răzvan Bălașov) has no account either, which item 45 part 3 already
records. `LM` is **ambiguous between two real users** — Laura Moale and Luiza Mirt. So the files close
the "which plan did who write" gap and open a "who are these people" gap in its place; the data exists
now, the accounts do not.

**One more measurement that constrains any future import:** the `460` figure in circulation is an
**occurrence count, not a plan count**. Measured strictly: **518 lesson rows, 500 carrying a plan
reference, 515 plan-column strings, 455 matching the filename pattern, resolving to 276 distinct
plans.** **115 of those 276 (41.7%) appear on more than one sheet**, one on five — and `Modul WOW LAB
MIX` holds 85 distinct plans of which 80 also sit on another module sheet. **MIX is a curated re-cut
of the other modules, not a module with its own content**, so a naive row-per-sheet import would
multiply-count roughly half the catalogue.

**Lives in:** `docs/mockup/wow_lab_os_mockup.html` (lines 434, 767, 952 — the three asks and the
pre-decision vocabulary); commit `edfab8a` (2026-07-31, the date bound) and `d06e3a4` (2026-08-07, the
split); `supabase/migrations/202609210006_migrate_groups_delivery_format_to_nine_workshop_types.sql`
(its column comment states the split is unconfirmed); item 52, item 79 and item 85 above (the
nine-value list's provenance and migration); item 102 above (the tenth value); item 45 part 3 below
(the 31 plans this reconciles); `~/Downloads/Centralizator module WOW LAB 2023-2024-2025.xlsx` and
`Module noi 2025 - idei de lectii.xlsx` (exports of a Google Sheet Mihai holds; **not in this repo**).

---

**CLOSED 2026-10-12 — both halves, by Anca, in item 110 below.** The headline open question ("Anca
settled the vocabulary of one axis. Whether there should be two axes at all has never been put to
her") was put to her and answered: **three** axes, `module` and `delivery_format` separate, the plan
a third below both. And the separable half ("do Anatomy and Vet become modules 14 and 15?") is done —
Vet 2026-10-07 (`202610070001`), Anatomy 2026-10-12 (`202610120001`), so this entry's "13 confirmed +
Vet + Anatomy = 15" reading of "13 din 15" is now the live taxonomy. Crăciun stays out, for the
reasons this entry gives.

**Two things in this entry are now superseded rather than merely old.** First, its objection to
Anatomy — "adding it as a 14th value today would duplicate content that `doctor` already carries" —
is answered by her, not overruled: a plan belonging to several modules is the design. Second, **its
measurements are superseded by a re-measurement against the newer export** (518/515/455/276/115
→ 540/512/461/288/113; see item 110 below for the table and the two causes, one of which is a
parsing error in this entry's own figures — `Modul WOW LAB MIX`'s third header row sits one column
left of its data).

---

### 104. This database cannot answer "who inserted this row" — for any table

2026-10-02. Found incidentally while establishing the provenance of two rows in `wow-lab-test-b`
(item 102 above). **Not a defect to fix now — a limit to know about, because the next provenance
question will hit it too, and the last one produced a wrong answer that was committed.**

**Two mechanisms exist, and neither covers INSERT:**

1. **`row_history` fires on UPDATE and DELETE only.** Verified against `pg_trigger` directly rather
   than read from a migration: `groups_row_history` has `tgtype` resolving to **`UPDATE DELETE`**, no
   INSERT. Confirmed from the data as well — every `row_history` row for `table_name = 'groups'` has
   `old_values is not null`, i.e. **not one is an insert record**, across every group the table has
   ever held. So a row that is inserted and never touched again leaves no history at all, and *the
   absence of a history row says nothing about where it came from.* That absence was briefly treated as
   evidence in item 102; it is not.
2. **`audit_log` stopped being written on 2026-09-10**, holds 62 rows across 7 event types, and
   **never covered group creation at all** — `addGroup` writes no audit row. Its emptiness for any
   given window is therefore also not evidence.

**What this means in practice.** For every table whose rows are created and then left alone —
`groups`, `clients`, `sessions`, `payroll_periods`, the pay-grid `*_versions`/`*_rates` — the questions
*"who made this row"* and *"when, and through what"* have **no answer in the database.** They can
sometimes be reconstructed from side-channels, which is what item 102 ended up doing: `created_at`
timestamps, a `closed_by` on the one table that happens to carry one, the shape of the row compared
against what each code path writes (`addGroup` writing `notes.trim() || null`), and grepping
`scripts/` for anything that could have produced it. **That reconstruction worked, but only because
`payroll_periods` carries `closed_by`.** Remove that one column and the same investigation would have
had nothing.

**Why it is worth knowing rather than fixing today.** Nothing in the product needs it yet, and the
cost is not trivial — an INSERT branch on the existing trigger would start recording a full `new_values`
snapshot for every row created, on tables that currently pay nothing for history. The trigger
infrastructure already exists, so the change is small; the data-volume and GDPR questions are not
(`row_history` would begin holding personal data at insert time for `users`-adjacent tables, which
`WOWLAB_SAD_Field_Masking.md`'s model has never been applied to).

**The trigger to build it:** the next time a provenance question is asked and cannot be answered — or
the first time a real-org row's origin is disputed. Test-org rows are cheap to be wrong about; a
`wow-lab` row is not.

**Lives in:** item 102 above (the investigation that found this, and the wrong answer it first
produced); item 100 above (the probe-methodology errors this belongs beside); `row_history` /
`audit_log`; `docs/WOWLAB_SAD_Field_Masking.md` (the model an INSERT branch would need to respect).

---

### 105. The supplier→user link did not exist — five identity matches were made by reading emails; plus what still blocks `trainer_contracts`, and one principle

2026-10-07. Mihai's correction opened this: the three trainer PFAs in the supplier contract register
**are** suppliers, because they invoice Wow Lab. The SAD's `trainer_contracts` / `supplier_contracts`
split decides *which table a contract row lives on*; it does not decide *who counts as a supplier*.
An earlier reply in this session read the first as settling the second — it does not.

**Status, stated precisely because the two halves differ.** Both migrations are written, each with a
matching rollback in `supabase/rollbacks/`.

- **`202610070002_add_suppliers_user_id_and_self_read.sql` — APPLIED 2026-10-07**, by Mihai in the
  SQL Editor, and verified: `user_id` uuid nullable, `suppliers_user_id_idx` present, exactly three
  policies, the three-branch SELECT predicate ending `user_id = app.current_user_id()`, and
  INSERT/UPDATE unchanged at two branches on both `qual` and `with_check`. Behaviour then verified
  by impersonation in `wow-lab-test-b` — see the table further down.
- **`202610070003_seed_suppliers_from_contract_register.sql` — APPLIED 2026-10-08**, by Mihai in
  the SQL Editor, and verified: **22 suppliers, 5 with `user_id`, 3 with a null `cui`**; the two
  withheld CNPs and Pidgin Host's absent value read differently in `notes`, as intended; all five
  links resolve to the right accounts; `groups` 4 and `contracts` 3, untouched.

The app-side change that depends on the applied column (`user_id` in the supplier edit form,
`app/(app)/suppliers/`) is **deployed and verified, 2026-10-08.** `773f69f` reached `origin/main`
only on the third attempt — the first two `git push`es ran in a different repo, see item 109 below —
and `scripts/check_deploy_status.ts` then confirmed `success` on `ab7d6fd`.

`scripts/verify_suppliers_user_id_form_test_org_b.ts` passes all nine assertions against
`app.wowlab.ro` in Test Org B. **Six are rendering or the real RLS write path; three are shipment
only**, and the distinction is not cosmetic: the edit form sits behind `isEditing` React state, so
no server fetch ever renders the `<select>`. Shipment means its inputs reached the client, not that
it drew. Specifically — rendering: the "Linked person" row, the Edit control, the persisted link
resolving to a name, and no raw uuid in rendered text. Real RLS path (stronger than rendering): the
link saved, and cleared back to NULL, through the signed-in owner's own session rather than the
service role. Shipment: `memberOptions` in the RSC payload, and the EN and RO option labels in the
deployed client chunks.

**One assertion was wrong before it was right, and the fix was to the test.** The label check first
grepped the page HTML and reported a false MISS. Props and module constants ship differently:
`memberOptions` is a server→client prop and lands in the flight payload, but `suppliersDict` is a
module-level constant inside a `"use client"` file, so its strings compile into the JS chunk and
appear in HTML only if something renders them — and `linked_user_none` is used only inside the
unrendered edit form. Confirmed by fetching the page's own `<script src>` list: all four labels
present in `page-8b68bc9ce036a943.js`, both languages. The script now checks the chunks, which is a
stronger proof than a payload grep, and asserts the RO side too.

**Numbering collision, flagged rather than silently resolved.** Two commits from 2026-10-07
(`c37901d`, `7dc5af2`) and the header of `scripts/verify_vet_module_test_org_b.ts` all cite
"item 105" for the **Vet / module 14** work, which has no entry of its own — its findings live in
**item 103**. This entry took 105 before that was noticed. Not renumbered, deliberately: the number
is baked into `202610070002`, which is **already applied**, and this repo's own practice is not to
edit an applied migration (§9 of `DATABASE_CONVENTIONS.md` was corrected in the document rather
than in the applied migration that stated it; same reasoning). So a reader following those three
Vet references to "item 105" lands here — and should read item 103 instead. Renumbering remains
Mihai's call; it would mean an `UPDATE` to two live DB object comments as well as the files.

**1. What the `user_id` column fixes — the matches were an observation, not a fact the schema held.**

`public.suppliers` (`202608300001`) has no link to `public.users`. The register
(`Tabel contracte furnizori Wow Lab.xlsx`, `~/Downloads`, sheet misnamed `Tabel Clienti Wow Lab`;
39 contracts → 22 suppliers) contains five counterparties who are already people in this app. They
were identified **by reading the spreadsheet's `Adresa de email` column against `users.email` by
eye** — all five are exact matches, confirmed live:

| Register supplier | Email | `public.users` |
|---|---|---|
| ASISMART SRL (rows 2–4) | `anka@asismart.ro` | Anka Orban |
| RALUCA MARGEAN (26–28) | `ralucamargean@yahoo.com` | Raluca Margean |
| TRUȘAN FLORINA CĂTĂLINA PFA (32–34) | `catalina_moale@yahoo.com` | Cătălina Trușan |
| POPA C. RALUCA-MARIA-DIETETICIAN (35–37) | `popar216@gmail.com` | Raluca Popa |
| MERIȘAN IOANA-TEODORA PFA (38–40) | `merisanteodora@gmail.com` | Teodora Merișan |

Nothing in the schema recorded, enforced, or could re-derive those five. **That is the gap**: a
one-off eyeball match, repeated by hand every time someone needs it, with nothing to catch a renamed
PFA or a second similarly-named one. A nullable `suppliers.user_id` turns it into a stored fact.

**It also fixes something that was not merely unbuilt but unexpressible.** The "own row" SELECT
branch this codebase has already built twice (`users_masked`, `client_contacts`) and that
`WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §5 recommends for `trainer_contracts` (`tc.user_id =
app.current_user_id()`) had **no supplier-side equivalent available**: `app.current_user_id()`
returns a `users.id`, and neither `suppliers` nor (per §3.3) the future `supplier_contracts` had any
column to compare it against. Confirmed live: `suppliers`' three policies (SELECT/INSERT/UPDATE) all
carry the identical predicate `app.is_platform_owner() OR app.has_capability('finance.reporting.*',
organization_id)`, and that capability is held by exactly three roles — `finance_admin_reporting`,
`organization_owner`, `platform_owner` — i.e. three accounts today. **Cătălina Trușan holds
`curriculum_manager`, `evaluator`, `operations_manager` and none of them**, so once her PFA exists as
a supplier row she could not see the row that *is* her. Not her contract — her identity record.
Laura Moale is also excluded (she holds `finance_operations`), which is deliberate and matches §5.

**2. `trainer_contracts` cannot take its nine rows even once the table is built.** `initial_grade_level`
is `NOT NULL` and constrained 1–6 (§3.2), and **the register carries no grade for anyone.** The nine
rows — Trușan ×3, Popa ×3, Merișan ×3, one per legal entity, all `2026-09-01 → 2027-06-30` — are
blocked on a grade-at-signing per person, which only Anca or Cătălina can supply. Building the table
does not unblock the import. Related and confirmed: all nine rows carry **no price at all** (both
the price and `Valoarea Contract` columns are empty), which is correct per §3.2's "Tariful nu e pe
acest rând" — the rate resolves through the versioned grid, which is seeded live at 111/119/127/134/142/150
RON/hour for grades 1–6.

**3. A contract and a role are unrelated — recorded as a principle, not a discrepancy.** Cătălina
invoices as a trainer (three rows noted `Onorarii trainer`) and holds **no** `trainer` role, and
**that is correct**: she does not record her own sessions. An earlier reply in this session called
this "worth reconciling before she holds a trainer contract" — that inference is wrong and is
withdrawn. **Do not treat a contract type as evidence of what roles someone should hold.** The two
describe different things: what someone invoices for, and what the application lets them do. The
same principle cuts the other way for Anka Orban, who holds eleven roles and whose supplier contract
says only "asistență administrativă".

**The CNP decision (Mihai, 2026-10-07).** Two individual suppliers carry a 13-digit CNP — a national
identity number — in the register's `CUI` column: BEREA ALEXANDRU-VALENTIN and RALUCA MARGEAN. Every
other identifier there is a 7–8-digit company CUI. **Decided: not imported, `cui` left NULL, reason
recorded on the row.** Nothing in this app computes from a CNP, nothing joins on it, no screen shows
it; its only use is invoicing, which happens in SmartBill. Importing it would add the most sensitive
identifier a person holds to a table three accounts can read, for no capability. The alternatives —
import plus masking rules, or a separate classified column — were rejected: masking protects values
that have a legitimate reader, and this one has none, while a dedicated column would make the schema
assert that storing CNPs is intended.

**A third row has a NULL `cui` for an unrelated reason, and the two must not be conflated.**
PIDGIN HOST SRL (register row 18) has an **empty** CUI cell in the source. That one is missing data
and may be filled later; the withheld pair must not be. So the acceptance test is **three** null
`cui`, not two — two withheld, one absent — and the migration asserts exactly that.

**Confirmed live, and it closes a question before it was asked: `service_type` has no CHECK
constraint.** `public.suppliers` carries exactly three constraints — the primary key, the
`organization_id` FK, and `suppliers_status_check` (`active` | `inactive`). So the 17 distinct Note
values the register supplies are all accepted by definition. They are taken verbatim, with two
deliberate substitutions where the source note names a *document* rather than a service (ROMAN V.
ANDRA's "ACT ADITIONAL LA CONTRACTUL DE ASISTENȚĂ JURIDICĂ" → `Asistenta juridica`; RALUCA MARGEAN's
"CONTRACT DE CESIUNE A DREPTURILOR DE AUTOR" → `Cesiune drepturi de autor`), and four NULLs where the
register has no note at all (BOLT, CENTRUL MEDICAL UNIREA, PIDGIN HOST, POSITIVE PROJECTS) rather
than a service guessed from the company name. Casing is left inconsistent on purpose — there is no
consumer and no constraint, so normalising would mean inventing a taxonomy nobody has asked for.

**One deviation from the instruction, flagged rather than done quietly:** `legal_name` is left NULL
for all 22. The register carries exactly one name per supplier, and for 20 of 22 that name is already
the registered legal form; copying it into both columns would assert a trade-name/legal-name
distinction the source does not make, and deriving a short trade name would be invention. The two
that genuinely *are* trade names (`BOLT`, probably `PIDGIN HOST SRL`) are the two whose legal name we
do not have. One `UPDATE` reverses this if a second source appears.

**CORRECTION, 2026-10-07: there IS a supplier screen, and it is complete.** This session asserted
twice that there was none — carried forward from the prompt's own premise and never checked against
the repo. Wrong. `app/(app)/suppliers/` (list + create form, `page.tsx` + `suppliers-client.tsx`)
and `app/(app)/suppliers/[id]/` (detail + edit, `supplier-info-client.tsx`) are committed and live,
dated 2026-08-27 and 2026-09-09, with a nav entry in `layout.tsx` gated on `finance.reporting.*`.
**`updateSupplier` (`app/(app)/suppliers/actions.ts`) edits name, legal_name, cui, service_type,
status and notes** — every column the seed populates except `user_id`.

**So the correction path for a loaded row is: Anka, in the app, today.** Not a follow-up migration,
not a hand-written production write. Holders of `finance.reporting.*` — `finance_admin_reporting`
(Anka Orban), `organization_owner` (`maxdigitalro@gmail.com`), `platform_owner` (Anca Tanasescu) —
can read, create and edit. **Laura Moale cannot** (she holds `finance_operations`), which is
deliberate and matches SAD §5. And `suppliers_row_history` fires `BEFORE UPDATE OR DELETE`
(confirmed live via `pg_trigger`), so every correction is captured with `old_values` — it is only
the INSERT that is not.

**Consequence for the self-read branch, also corrected:** `202610070002` was justified in part as
"a policy branch with no reader costs nothing". It has a reader the moment `user_id` is populated.
`suppliers/page.tsx` guards only that a user is signed in; its capability check computes the create
form and the edit gate, **not read access**, which is left to RLS. So Cătălina Trușan visiting
`/suppliers` by URL will see a one-row list — herself — with no create form and no edit button. The
nav link is gated so she is not led there. That is the branch working as intended, recorded here so
the one-row list is never mistaken for a leak.

**The self-read branch was verified live in `wow-lab-test-b` on 2026-10-07, by impersonation, and
one measured property is worth knowing: it crosses org boundaries by design.** Cătălina is not a
member of `wow-lab-test-b`, so the fixture was `test+ui-ops-manager-b@wowlab.dev` — `operations_manager`
only, which is the one of her three roles that matters and which lacks `finance.reporting.*` exactly
as she does. All assertions ran as role `authenticated` (necessary, not cosmetic: `suppliers` has
`relrowsecurity = true` but `relforcerowsecurity = false` and is owned by `postgres`, so the
service connection bypasses RLS entirely and an unimpersonated test proves nothing). Everything was
transaction-scoped and rolled back; both orgs verified back to zero rows afterwards.

| Viewer | Sees | Why |
|---|---|---|
| ops manager, linked | her own row **and** a `wow-lab` row linked to her | self-read branch, **no org guard** |
| ops manager | *not* the unlinked test-b supplier | no `finance.reporting.*` (confirmed false) |
| plain test-b trainer | nothing | neither branch matches |
| test-b `organization_owner` | both test-b rows, **not** the `wow-lab` one | capability branch is org-scoped |
| ops manager, UPDATE on her own row | **0 rows changed**, value unchanged | UPDATE policy deliberately not widened |

**The cross-org read is intended, and now has its own entry — see item 107 below**, which records
the property, its trigger (the first time a second real organization records a supplier linked to a
non-member), the one-clause fix, and the fact that the same property holds unexamined on
`trainer_contracts`. Zero exposure today: one real org, and all five links point at its own members.

**The five values the import freezes, by name, so they are a list to ask about rather than a gap to
discover.** The register does not carry them and we do not know them:

| Supplier | Missing |
|---|---|
| BOLT | `service_type` |
| CENTRUL MEDICAL UNIREA SRL | `service_type` |
| PIDGIN HOST SRL | `service_type` **and** `cui` (source cell empty) |
| POSITIVE PROJECTS SRL | `service_type` |

All five are editable in the app by Anka, so these are closeable gaps, not wrong values. PIDGIN
HOST's empty `cui` must not be confused with the two deliberately withheld CNPs — different reason,
different resolution.

**This seed will be the only provenance record for its 22 rows — item 104 biting on real data for
the first time.** `suppliers_row_history` does not fire on INSERT, and `audit_log` stopped being
written on 2026-09-10 and never covered this table. So "where did this supplier row come from" has
exactly one answer — `202610070003` — and the **absence** of a history row for any of the 22 is not
evidence about their origin. That is precisely the inference item 104 records as having already
produced one wrong answer that got committed (item 102). First real-org instance; the 22 rows are
also exactly the kind of row item 104 predicted would hit this: created once and then left alone.

**STILL OPEN — the whole list, so the next session does not rediscover it.** Step 2 of SAD §10 is
done: 22 suppliers, five linked, screen deployed and verified. Nothing below is buildable today, and
each is blocked on a decision rather than on effort.

1. **`supplier_contracts` — the 30 non-trainer rows have no table.** Blocked on the rate-vs-value
   decision, not on writing the migration: §3.3 specifies `contract_value numeric` with **no**
   `rate`/`rate_unit`, on the reasoning that "un contract de servicii are valoare, nu tarif orar" —
   but most priced rows in the register carry a *rate* (`80 RON/ORA`, `400 euro/luna`,
   `1000 ron/trimestru`, `14.08 Euro/Ora`, `10099.87 ron/curs`), not a value. The spec's assumption
   is contradicted by the source it was written for. Precedent if the answer is "keep it as text":
   `contracts.billing_rule` already holds exactly this shape (`770 RON + TVA/ grupă/ ședință`).
2. **`trainer_contracts` — the 9 rows (Trușan ×3, Popa ×3, Merișan ×3)** — blocked twice over.
   `initial_grade_level` is `NOT NULL`, constrained 1–6, and **the register carries no grade for
   anyone**, so building the table does not unblock the import; only Anca or Cătălina can supply
   grade-at-signing. And the own-row predicate shape from **item 107 below** has to be decided here
   rather than inherited — `trainer_contracts` will be the second table with an org-scoped row
   carrying a bare pointer to a person, and the row it would leak cross-org carries
   `initial_grade_level`, which §5 treats as being as sensitive as a rate.
3. **Five frozen values Anka can close in the form, no engineering needed** — `service_type` for
   **BOLT**, **CENTRUL MEDICAL UNIREA SRL**, **PIDGIN HOST SRL**, **POSITIVE PROJECTS SRL**, and
   `cui` for **PIDGIN HOST SRL**. The register has none of them. Pidgin Host's empty `cui` must not
   be confused with the two deliberately withheld CNPs (Berea, Raluca Margean) — different reason,
   different resolution, and the `notes` on each row say which.

~~Open but not supplier-shaped, carried from the register for whoever picks up admin pay: Raluca
Margean's newsletter rate (the contract lists article tiers only) and whether her article tiers
survived two amendments; and which of Anka's three task types maps to 80, 80 and 90.~~
**ANSWERED 2026-10-12 by Anca — all three, now item 111 below.** Her newsletter rate is 150 RON
each. Her article tiers did not need to survive the two amendments: hers are newer and **supersede**
the supplier contract's three tiers. Anka's mapping is Admin 80 (everything administrative but not
financial), Ateliere 80 (workshop organisation, sales, ActiveCampaign), Financiar 90 (accounting and
financial statements) — all three FINAL, no 11% on top. One new fact that was in no earlier record:
**Cătălina also has an admin rate**, 72 net / 79.92 invoiced, and hers *is* uplifted.

**Lives in:** `supabase/migrations/202610070002`, `202610070003` and their rollbacks (both applied);
`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §3.2/§3.3/§5/§10 (the trainer/supplier split, the
own-row branch, the four-step order); `202608300001_suppliers.sql` (the table and the policy this
changes); `docs/WOWLAB_SAD_Field_Masking.md` (the model the CNP decision declines to extend); item
107 below (the cross-org property of the branch this added); item 20 below (the pay grids the
trainer rate resolves through); item 23 below (the per-article writing still with no table on either
side); `docs/progress.md` §128/§230 (the admin rate structures and Anca's 2026-08-10 "80/80/90 is
final" correction).

---

### 106. Two conventions out of step with practice — one written rule that no longer describes what we do, and one habit I kept citing as a rule

2026-10-07. Both surfaced while writing the supplier seed (item 105 above). Neither is a defect in
any migration — the practice in both cases is settled and reasonable. The gap is in the documents.

**1. `DATABASE_CONVENTIONS.md` §10 does not describe how real data is actually seeded.**

What it says, verbatim: *"Schema changes live in ordered migration files under
`supabase/migrations/`. Seed data lives separately (`supabase/seed.sql`) and must be idempotent —
re-running it must not create duplicates or otherwise change the outcome of a prior run."*

What we do, in three precedents:

| Migration | Seeds | Re-run behaviour |
|---|---|---|
| `202609240001_seed_pay_grids_pfa_inclusive_rates` | the real pay-grid rates | guarded |
| `202609240002_seed_trainer_grade_assignments` | ten trainers' grades from Anca's record | guarded, raises on missing user |
| `202610070003_seed_suppliers_from_contract_register` (written, not applied) | 22 real suppliers | raises if the org already has rows |

All three put **real production data in a migration, not in `seed.sql`**, and all three **raise on
re-run rather than being idempotent no-ops.**

**The practice is right and the document should change — agreed, and the reason is stronger than
"three precedents".** `seed.sql` is for fixtures: §11 of the same document records that its users
cannot even authenticate, because they exist in `public.users` with no `auth.users` row. It is a
local-development convenience, re-run freely against a throwaway database. Real production
reference data has the opposite requirements — it needs to be ordered relative to the schema it
depends on, applied exactly once, reviewable in a diff, and attached to the reasoning for every
judgement in it. That is a migration. And for such data **idempotency is the wrong property**:
silently doing nothing on a second apply hides that someone tried to load it twice, which for 22
real suppliers is something you want to hear about, not absorb. Raising is the safer default, and
it is what all three do.

**What to change:** §10 should distinguish *fixtures* (`seed.sql`, idempotent, non-authenticating,
local) from *real reference data* (an ordered migration, applied once, guarded so a re-apply fails
loudly, with a matching rollback). Not done in this pass — recorded so it is a deliberate edit to
that document rather than a drift nobody wrote down.

**2. There is no written prohibition on ad-hoc production writes. I cited one repeatedly as though
there were.**

Searched `DATABASE_CONVENTIONS.md` and `docs/` for it: nothing. §10 constrains *where schema and
seed data live*; it says nothing about writing to production by hand. What actually exists is a
**habit**, visible in `docs/ws-d-plan.md` §2 and §3: Claude writes the `.sql` into the repo, Mihai
runs it block-by-block in the SQL Editor and reports the results — described there as *"automatizat
(fișier versionat) + rulat manual de tine"*. That is a workflow for RLS verification, which got
generalised in conversation into a rule about production writes that was never stated anywhere.

**Worth writing down, because it is a good rule being followed for good reasons:** every write to
`wow-lab` that is not a user action through the app should exist as a versioned file with a rollback
before it runs, so that what happened is reconstructible afterwards. Item 104 is exactly why this
matters — `row_history` does not capture INSERT, so for a seeded row the migration file is the only
provenance that will ever exist (see item 105, where that lands on 22 real rows for the first time).
An unversioned hand-written INSERT against production leaves **no** trace anywhere, not even a bad
one.

**Why it is being recorded rather than fixed here:** both are edits to `DATABASE_CONVENTIONS.md`,
and that document has been wrong in a load-bearing way once already — §9's claim that 36-month
anonymization "is automatic and scheduled" was false and had to be corrected *in the document*
after the migration asserting it had already been applied (noted in §9 itself, and in item 3). A
convention document that gets edited casually is how that happens. These two edits should be made
deliberately, together, by someone who has read both sections.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §9 (the precedent for a convention doc stating
something untrue), §10 (the rule to split), §11 (why `seed.sql` is fixtures-only);
`docs/ws-d-plan.md` §2/§3 (the habit worth promoting to a rule); item 104 above (why the versioned
file is the only provenance for a seeded row); item 105 above (the seed that surfaced both).

---

### 107. The "own row" RLS branch crosses organization boundaries — measured on `suppliers`, which turns out to be the only table with the property; `trainer_contracts` will be the second

2026-10-08. A deliberate, specified property that had never been measured. Recorded with its trigger
and its fix so that whoever hits it does not re-derive either.

**The property.** A policy branch of the form `user_id = app.current_user_id()`, standing alone with
no org guard, lets a user read a row **in an organization they are not a member of**, provided the
row points at them. The org check in these predicates lives only on the *capability* branch; the
own-row branch is unqualified by design — "the row is yours because it is yours."

**Measured live, 2026-10-07, in `wow-lab-test-b`, by impersonation as role `authenticated`.** The
fixture was `test+ui-ops-manager-b@wowlab.dev` (`operations_manager` only, no `finance.reporting.*`).
Three supplier rows were inserted: one in test-b linked to her, one in test-b linked to nobody, and
one in **`wow-lab`** linked to her. She saw **two** — her test-b row *and* the `wow-lab` row, in an
org where she holds no membership at all. A plain test-b trainer saw nothing; the test-b
`organization_owner` saw both test-b rows and **not** the `wow-lab` one, confirming the capability
branch is correctly org-scoped and that only the own-row branch crosses. All transaction-scoped and
rolled back; both orgs verified back to zero rows.

The impersonation was necessary rather than ceremonial — but **the mechanism first recorded here was
wrong, corrected 2026-10-08.** It said the bypass came from `suppliers` having
`relforcerowsecurity = false`. The real cause is broader: the connection runs as **`postgres`, which
has `rolbypassrls = true`** (so does `service_role`), and `BYPASSRLS` overrides `FORCE`. Measured:
`users` and `client_contacts` both have `relforcerowsecurity = true` and are bypassed by this
connection just the same. So **impersonation is mandatory for every RLS probe on this database, on
every table, regardless of FORCE** — not a quirk of one table. An unimpersonated query against any
of them proves nothing. (`suppliers` being the only one of the four without `FORCE` is still true and
still worth tidying one day; it just isn't why the probe needed a role switch.)

**Exposure today: zero.** There is one real organization (`wow-lab`), `wow-lab-test-b` is a test
org, and all five `suppliers.user_id` links point at `wow-lab`'s own members. No one can currently
reach a row they could not otherwise reach.

**THE TRIGGER — the first time a second real organization records a supplier linked to someone who
is not its member.** That person will see a row belonging to an org they do not belong to. Nothing
will warn anyone; the query simply returns an extra row. This is the moment to come back to this
entry, and it has nothing to do with suppliers specifically — any second real tenant does it.

**THE FIX, one clause**, if the tenancy boundary should hold absolutely instead:

```sql
or (user_id = app.current_user_id() and app.belongs_to_org(organization_id))
```

on `suppliers`' SELECT policy (currently `202610070002`'s third branch). Note what this costs: it
**diverges from `WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §5**, which specifies the unqualified
form. Divergence may well be right — but it should be a decision taken against the SAD, not a patch
that quietly contradicts it.

**The same property holds on `trainer_contracts`, by identical reasoning, and has never been
measured** — because the table does not exist yet. SAD §5 specifies its predicate as:

```sql
when tc.user_id = app.current_user_id()                       -- propriul contract
  or (app.belongs_to_org(tc.organization_id) and (... capabilities ...))
```

`belongs_to_org` appears on the capability branch and **not** on the own-row branch — the same shape
`suppliers` now demonstrably has. So a trainer with a contract recorded by an org they are not a
member of would read it, including its masked `initial_grade_level`, which §5 treats as being as
sensitive as a rate. That is a sharper consequence than the supplier case: a supplier row is
identity (name, CUI, notes), while a trainer contract carries a grade. **Whoever builds
`trainer_contracts` (step 3 of §10) should decide this explicitly rather than copying the predicate
and inheriting the property unexamined** — and can now cite a measurement rather than a hypothesis,
since `suppliers` proves the branch behaves exactly as written.

**The two precedents were then probed, 2026-10-08, and NEITHER has the property. `suppliers` is
alone.** §5 names `users_masked` and `client_contacts` as the precedent for the own-row branch, so
the natural assumption was that all three shared it. Measured, impersonated, transaction-scoped,
rolled back (test-b left verified at 0 contacts and 12 memberships afterwards):

**`users_masked` — does not cross, and structurally cannot.** It is a view with
`security_invoker = true` over `public.users`, so `users`' own RLS applies to the invoker. Its
own-row branch is `id = app.current_user_id()`, and **`public.users` has no `organization_id` column
at all** — there is no org for the branch to cross. Every *other* branch is org-scoped: the
`org.members.read` branch requires the target to hold a role in an org where the viewer has the
capability; `app.viewer_sees_trainer_via_finance_ops` checks `finance.operations.*` in the *target's*
own org; the shared-session branch checks `mywork.*` in that session's org. Measured: the test-b
owner sees 11 users — her own org — and **0** rows for a `wow-lab`-only user. A user with **zero**
memberships (`hello@maxdigital.ro`) sees **exactly 1 row: themselves**, which isolates the own-row
branch and confirms it is self-only.

**The dual-org case, measured rather than reasoned about, because it is the normal case this app
expects.** Sonia Ganea (a `wow-lab` trainer) was given a test-b membership inside the transaction.
The test-b owner's visible users went 11 → 12 and she saw `Sonia Ganea`. That is correct by design,
not a leak: Sonia is now a member of her org, and what becomes visible is Sonia's *global* identity
— name and email — with nothing about `wow-lab` disclosed. The semantics of a non-org-scoped `users`
table are that joining an org makes your identity visible to that org's members. Worth having
measured, since "a person in two orgs" will stop being hypothetical.

**`client_contacts` — does not cross, because its equivalent branch is org-guarded.** The branch §5
points at is the trainer-facing one, and its *first conjunct* is
`app.has_capability('mywork.*', organization_id)` on the row's own org — which requires membership.
No live row could exercise it (all 4 contacts are `wow-lab`, all `contact_purpose = 'general'`), so
the linkage was constructed: a test-b trainer-facing contact, set as a test-b group's
`on_site_contact_id`, with a session whose **principal** trainer is Sonia (not a test-b member) and
whose **secundar** is Test Trainer B1 (a test-b member). Result: Sonia, the principal trainer on that
very session, has `mywork.*` in test-b = **false** and sees **0** contacts. Trainer B1 sees
`ZZ PROBE trainer-facing contact`. The positive control is what makes it conclusive — the branch
works, and the *only* thing excluding Sonia is org membership.

**So this is one decision about one predicate, not three patches.** The difference is structural and
worth stating precisely: on `users` the own-row branch points at a row that has no org; on
`client_contacts` the "connected to me" branch is ANDed with an org-scoped capability. `suppliers` is
the first table where a row **is** org-scoped **and** carries a direct pointer to a person, with
nothing org-scoped in the same conjunct. `trainer_contracts` (§3.2) will be the second, by the same
shape — which is why the decision belongs at step 3 and not in a patch to `suppliers` alone.

**Lives in:** `supabase/migrations/202610070002_add_suppliers_user_id_and_self_read.sql` (the branch,
and its own comment on why the guard is absent); `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §5
(the specified predicate, for both tables); item 105 above (the column and seed that made this
measurable); `app.belongs_to_org` / `app.current_user_id` (`docs/ws-d-plan.md` D0).

---

### 108. The script written to catch item 94 had item 94's own failure mode inside it — "pending" meant two different things, and only one was worth waiting for

2026-10-08. Found by using it, not by reading it.

**What happened.** `scripts/check_deploy_status.ts` was run after a push and reported `pending`
thirty times over five minutes, then exited 1 with "Still pending after 30 checks — not confirmed,
treat as not deployed." The verdict was right. The reasoning behind it was not: there was no build
to wait for. GitHub's `/commits/<sha>/status` returned **`state: "pending"` with `total_count: 0`**
the whole time — meaning **no status context had reported at all.** Compared across commits, the
picture was unambiguous:

| commit | state | contexts |
|---|---|---|
| `311cddc`, `773f69f` (2026-10-08) | pending | **0 — nothing reported** |
| `7dc5af2`, `c37901d` (2026-10-07) | success | 1 |
| `28842d8` (2026-10-02) | success | 1 |

Nothing was queued; nothing was going to resolve. Five minutes of polling was spent on a condition
that is permanent by nature.

**THE FIRST DIAGNOSIS OF *WHY* WAS WRONG, and the correction is the more useful half of this entry.**
From that table I concluded the Vercel↔GitHub integration had stopped posting — a plausible reading,
and this project has had that exact desync before. It was not what happened. `git ls-remote origin
refs/heads/main` showed the remote tip of `main` still at **`7dc5af2`**, yesterday's commit, and
`git branch -r --contains 311cddc` returned nothing: **both commits were on no remote branch. They
had never been pushed.** No deployment was queued because there was no deployable commit. The
integration was fine — confirmed afterwards: once `ab7d6fd` actually reached `origin/main`, this
script reported `pending (1 context reporting)` and then `success` in 21s. **Why the pushes did not
land is item 109 below: they ran in a different repo.**

**What made that mistake available: GitHub's endpoint does not distinguish the two cases.** It
answers **200 with `total_count: 0` for a well-formed 40-char sha it has never seen**, byte-identical
to its answer for a pushed commit nothing reported on. (It *does* 404 on an abbreviated sha — which
is how the full-vs-short behaviour below first looked like a contradiction.) So "zero contexts" was
read as "pushed but unreported" when it equally meant "not pushed". A remote-state question was
answered with a status-API call, which cannot answer it.

**Why this is item 94 recursing.** Item 94's lesson was that **a failed deploy can read as silent
success** when the only signal checked is `git push`'s exit code, and this script was written as the
mitigation. The mitigation then carried a variant of the same defect: **a deploy that never started
read as a deploy in progress.** The null result wore the costume of patience. Item 94's general
lesson — "a failed X can render as silent success one layer up" — applies to its own fix, which is
the part worth remembering: a check is a piece of code and can be wrong in the same shape as the
thing it checks.

**The discriminator, and the fix — now two of them.** `total_count` separates a running build from
no build: **a real pending build has at least one context.** Zero contexts then exits non-zero in
~30s instead of ~5min. And because zero contexts has the two causes above, the script now settles
which by asking **git** rather than GitHub: it fetches, runs `git branch -r --contains <sha>`, and
reports either `commit is NOT on the remote -- it was never pushed` (with `git push` as the action)
or `no deployment reported -- check the Vercel integration`, naming the remote branches it did find.
If the fetch fails it says it could not tell, rather than guessing — the mistake this entry records
was precisely a guess presented as a finding.

**Not literally immediate, deliberately.** Run within seconds of a push, Vercel legitimately has not
posted yet, so failing on the first observation would cry wolf on every fast run.
`ZERO_CONTEXT_GRACE_ATTEMPTS = 3` (~30s) allows for the first status to appear and no longer. The
instruction was "exit immediately"; three checks is the smallest window that does not manufacture
false alarms, and the deviation is named in the code rather than silently taken.

**A second blind spot, found while testing the first.** The script's own usage line documents
`check_deploy_status.ts <sha>`, and **GitHub's status endpoint 404s on an abbreviated sha** —
verified directly: `/commits/311cddc/status` → 404, `/commits/311cddc1a9d…e/status` → 200. So anyone
pasting the short form from `git log --oneline` got `GitHub API returned HTTP 404`, which reads as
"that commit does not exist" rather than "use the full sha". The no-argument path never hit it,
because `git rev-parse HEAD` already returns the long form — which is exactly why it survived
unnoticed. Fixed by routing every input through `git rev-parse`, which also accepts a branch or tag.

**Verified after the change**, all three paths: zero-context commit → the new message, exit 1, **31s**;
known-good commit (`7dc5af2`) → `success`, exit 0; unknown revision → `not a revision this repo
knows`, exit 1. `npx tsc --noEmit` clean.

**Still open: nothing is pushed, so nothing is deployed.** As of 2026-10-08 the remote tip of `main`
is `7dc5af2` and four local commits sit ahead of it, so the app-side supplier change (`user_id` in
the edit form) is **not deployed**. Confirmed independently of any git reasoning by
`scripts/verify_suppliers_user_id_form_test_org_b.ts`, whose four UI assertions all failed while its
four database-path assertions all passed — the migration is live, the app code is not. That split is
the strongest evidence in this entry, and it is the one piece that never depended on reading the
status API correctly.

**The lesson worth keeping, separate from the script.** Two independent signals agreed that the
change was not live (the status API and the app probe), and that agreement made a *third* claim — the
reason why — feel equally established when it had never been checked at all. "Not deployed" was
verified twice; "because the integration stopped posting" was verified zero times and asserted in
the same breath. Same family as item 104's warning that the absence of a history row is not evidence
of origin: a confirmed symptom licenses no particular cause.

**Lives in:** `scripts/check_deploy_status.ts` (the fix, and the reasoning in its header); item 94
above (the original failure and this script's reason for existing); item 90 (the same
"failure renders as success" family, one layer down, on writes); item 105 above (the supplier change
still waiting on a deploy).

---

### 109. Working note: a command that succeeds in the wrong directory reports success — three `git push`es ran in `maxdigital-dashboard`, not this repo

2026-10-08. Pairs with item 69 above, and involves **the same unrelated project**:
`maxdigital-dashboard`. There, a `pkill -f "next dev"` matched beyond this repo's process; here,
`git push origin main` ran *inside* that repo instead of this one.

**What happened.** "Pushed" was reported three times across this session. Twice nothing landed:
`git ls-remote origin refs/heads/main` stayed at `7dc5af2` while five commits sat ahead of it
locally. The push itself did not fail — it ran in a different working directory
(`maxdigital-dashboard`), where it was a legitimate no-op or a push of that project's own state, and
reported success on its own terms. `git` has no way to know it was the wrong repo; there is nothing
to warn about.

**Why it cost two wrong reports, not just a delay.** The missing deploy was real and confirmed twice
over — by `check_deploy_status.ts` and independently by the app probe's four failing UI assertions —
so the symptom was never in doubt. The *cause* was, and I asserted one anyway: that the
Vercel↔GitHub integration had stopped posting statuses (item 108). It had not. The actual cause was
that GitHub had never seen the commits, because the push had happened somewhere else. A confirmed
symptom plus a plausible mechanism is still a guess, and this is the second shape of that mistake
recorded this session — see item 108's own closing note and item 104's "absence of a history row is
not evidence of origin".

**What makes this class of error quiet.** A wrong-directory command does not error, does not warn,
and often produces output indistinguishable from the intended one — `Everything up-to-date` from a
no-op push reads exactly like a successful re-push of already-pushed work. The same is true of
`npm install`, `supabase db push`, `git status` and anything else driven by cwd.

**What actually caught it:** asking the remote rather than trusting a local or reported state —
`git ls-remote origin refs/heads/main`, which queries the server and ignores stale tracking refs.
`git branch -r --contains <sha>` confirmed the same from the other direction. Both are now wired
into `scripts/check_deploy_status.ts`, which reports "commit is NOT on the remote -- it was never
pushed" rather than waiting out a build that was never queued.

**For next time, two habits rather than one rule.** Before trusting a push: `git ls-remote origin
refs/heads/<branch>` and compare to the sha you intended — one command, no inference. And when a
command's effect is expected somewhere specific, have it print where it ran (`pwd`, or
`git rev-parse --show-toplevel`) in the same breath, so "it succeeded" and "it succeeded *here*" are
the same observation. `git -C <path> push` makes the directory explicit and immune to cwd drift.

**Also worth knowing, found while diagnosing this:** GitHub's two endpoints disagree about unknown
commits, and only one of them is a usable existence check. `/commits/<sha>/status` returns **200
with `total_count: 0`** for a sha it has never seen — identical to its answer for a pushed commit
nothing reported on. `/commits/<sha>` returns **422**. The status endpoint cannot tell you whether a
commit exists; the commit endpoint can.

---

### 110. Anca's 2026-10-12 answers — the eight-week-old two-axes question closed by her, Anatomy shipped as module 15, and two answers that don't resolve what they were asked

2026-10-12. Her round of answers, with one correction she supplied herself (her 2026-08-10 message
correcting her 2026-08-07 one — see item 111 below). Everything in this entry was either checked
live the same date or is a direct quote of hers; nothing is carried from notes.

**The central question item 103 above left open is closed, by her, directly.** That entry ended:
*"Anca settled the vocabulary of one axis. Whether there should be two axes at all has never been
put to her."* It has now been put to her, and the answer is **three** axes:

| Axis | Her words | Where it lives today |
|---|---|---|
| **what is taught** | "a module contains several lesson plans" | `groups.module` — 15 keys as of today |
| **which plan** | "the same plan can belong to several modules" | **nothing.** `sessions.experiment_delivered`, free text |
| **where it is delivered** | "Săptămâna Verde, Școala Altfel, Corporate" | `groups.delivery_format` — Anca's nine + `custom` |

So `module` and `delivery_format` stay **separate fields**, and the epic's 19-value "Tip atelier"
flattening is dead on her own authority rather than on item 103's date argument. That argument still
stands and is still why no live data was changed on a stale decision — it is simply no longer the
load-bearing one. One consequence worth naming: **`202609210006`'s own column comment is now out of
date** where it says *"the module+delivery_format SPLIT itself (vs. a single 'Tip atelier' field)
remains Mihai's own interpretation, unconfirmed by this decision."* It is confirmed. An applied
migration is not rewritten, so that comment stays as the record of what was true when it was
written; this entry is the correction, and `groups.module`'s own comment (rewritten by
`202610120001`) now carries the current state.

**She wants lesson plans in the app, as a searchable selector so a trainer finds one quickly.** That
makes the catalogue the largest buildable thing on this register. Its shape was reported 2026-10-12
and deliberately **not built** — see "the catalogue, measured" below for the numbers that report
rests on, which correct item 103's.

---

#### Built, applied and verified live the same date

**Anatomy is module 15 (`202610120001`).** The taxonomy is complete: the figure "13 din 15" has an
account for the first time — thirteen confirmed in August, plus `vet` (2026-10-07) and `anatomy`.
CRACIUN remains a sixteenth sheet and deliberately not a module.

**Her reason closed the standing objection rather than overruling it.** `202610070001` (vet) refused
Anatomy because *"adding it would duplicate content doctor already carries"* — 6 of its 6 real plans
also sit on the doctor sheet. Her answer makes that the designed shape of the catalogue, not a
defect: a plan on several modules is correct. Measured rather than accepted: **113 of 288 distinct
plans sit on more than one sheet, one of them on five — and that one is Anatomy's own
`ANAT_SeeingDNA_DC_4`.** `Modul WOW LAB MIX` is the same fact at ten times the scale (80 distinct
plans, 75 of them also on another sheet) and nobody has ever proposed deleting MIX for it.

**Her 2026-10-12 "da" confirms what was already built, and the count was checked rather than
assumed.** She was asked again the same day and said yes to Anatomy as module 15 — but it had been
built that morning on her earlier answer, so the risk was a second row rather than a missing one.
Verified live: `public.modules` holds **15 rows and 15 distinct keys**, exactly **one** with
`key = 'anatomy'`, and `groups_module_check` contains `'anatomy'` once. **Nothing was added twice,
and the count is 15, not 16.** A confirmation arriving after the work is a reason to check for a
duplicate, not a reason to repeat it.

Key and label were **reported before being written**, as asked: key `anatomy`, label `Anatomy`,
identical in EN and RO. The precedent splits and this one follows `astronomy`, not its siblings —
`Modul ANATOMY` → `Anatomy` is the same rule as `Modul ASTRONOMY` → `Astronomy`; `doctor`/`vet` got
"I Wanna Be a …" because their sheets literally are that phrase. The key is the word spelled out,
not the `ANAT_` filename prefix — the same choice `astronomy` already made over `ASTRO_`.

Four objects, the same four vet needed: the `public.modules` row, the widened `groups_module_check`
(`groups.module` is **not** an FK — re-verified live, not inherited from `202610070001`'s check a
week earlier), `MODULE_KEYS` in `groups-client.tsx`, and the `module_anatomy` i18n entry with both
sides. The `groups.module` comment no longer says Anatomy is deliberately absent.

Verified after the push, never from `db push`'s own exit code: 15 rows in `public.modules`,
`'anatomy'` inside the constraint, exactly one constraint by that name, the new comment live, a real
`anatomy` group accepted in Test Org B and a bogus key still rejected (both rolled back). Then end
to end against the real deployment — `scripts/verify_anatomy_module_test_org_b.ts`, the same shape
as vet's: "Anatomy" renders in `/groups`, the raw key never reaches the user, the shouted sheet form
is absent, the full `{en, ro}` entry ships in the client bundle, `"anatomy"` is in the create-form
key list, cleanup ran and said so. **Its first run reported two CONTROL failures that were the
script's fault, not the build's**, and the fix is written into the script so the next person does not
repeat it: the module list on `/groups` is data-driven (`moduleOptions` from the groups that exist),
so controls naming `Astronomy` and `I Wanna Be a Vet` — neither of which has a group in Test Org B —
were asking the page to render labels it correctly does not. The control has to be a module with a
real group behind it (`doctor`), and the Astronomy label is checked in the shipped dictionary
instead.

**Lycée Français is taught in English, not French (`202610120002`).** Both its groups now carry
`language_group = 'ro_en'`, the **0%** branch. This closes the one case `202609240003` named and
deliberately refused to guess: *"'Școala Franceză (Lycee Francais)' … is obviously a French-medium
school by name. Guessing is not the same as knowing … Both of its groups' language_group stays NULL
until she says so."*

**The obvious guess was wrong, and the cost of having made it is measurable.** `fr_de_es` carries
20% (Anca 2026-09-24, item 95 above); `ro_en` carries 0. Inferring the language from the school's
name would have overpaid every session in both groups by 20% for as long as nobody re-asked. This is
the **third** time in this project that a plausible-looking inference would have corrupted correct
data — after "Laura Moale" (item 35 below) and the `Asociatia STEMplicity` spelling (item 42 below). **A
fourth followed on 2026-10-13: Școala Germană is taught in Romanian and English, not German** (item
132 below). Four for four — every time this project has had a name that implied a fact, the name was
wrong. The rule that falls out of it is not "ask about schools with foreign names"; it is that **a
name is never evidence about anything except what to call the thing**.
The migration raises unless exactly 2 rows change. Verified live: both groups read `ro_en`, and
`groups_row_history` holds two rows for the write with `actor_user_id = NULL` on both — a migration
carries no JWT, `app.current_user_id()` reads one, and the actor was **not** faked by setting a
claim. The migration file is the provenance record instead. That is item 104 above's exact shape,
chosen on purpose this time rather than discovered after the fact.

**Supplier-contract access stays as it is.** Closed by her, no change. The question is off the list.

---

#### Verified, with an answer the asking party should see

**School addresses: both fields are editable by the two people who will enter them.** Mihai and Anka
will do the data entry; checked against the live policies and the live capability rows rather than
reasoned from role names:

| | Who can write it | Anka | Mihai |
|---|---|---|---|
| `clients.address` | `is_platform_owner()` OR `org.settings.manage` OR **`clients.create`** | ✅ `clients.create` | ✅ `org.settings.manage` |
| `groups.address` | `is_platform_owner()` OR `org.settings.manage` OR **`groups.create`** (`updateGroup`'s `canManageGroupFields`) | ✅ `groups.create` | ✅ `org.settings.manage` |

Anka holds 40 capabilities across seven roles, `clients.create` and `groups.create` among them.
Column-level `UPDATE` grants exist on both columns for `authenticated` (checked in
`information_schema.column_privileges` — neither was caught by item 91 above's narrowing). **Nothing
to report as broken.** One adjacent fact, not a blocker: all four real `wow-lab` clients currently
have `address = NULL`, and so do both groups, which is consistent with "they will enter them" and not
with a write path that silently fails.

**Group notes — the field does exist, and her own screenshot is the proof.** Her answer says she sees
no Notes field in production. It is there: the **last row of Group info**, rendered unconditionally
for anyone who can see the group at all (`group-info-section.tsx`, `<Kv label={t("kv_notes")}
value={notes || "—"} />`). It reads `—` because every real group's `notes` is `NULL` — all four of
them, checked live. An empty field and an absent field look identical in a read view, which is
exactly what happened here.

**And the question behind it now has a measured answer: yes, the allocated trainer sees it.** Proven
against the live policies, not read off the render code —
`scripts/verify_group_notes_trainer_visibility.sql`, five assertions, all passing:

1. an `operations_manager` (Cătălina's role) writes `groups.notes` — 1 row updated
2. the allocated `trainer_principal` reads the note back **verbatim**
3. the allocated `trainer_secundar` reads it back verbatim too
4. a trainer with **no** session in that group sees no row at all, so no note
5. the allocated trainer **cannot** write it — 0 rows updated

Run in Test Org B for the reason the real org cannot answer it: **`wow-lab` holds zero sessions**, so
no trainer is allocated to anything there and `groups`' `mywork.*` branch cannot be exercised. Test
Org B carries the same role keys against the same policies. The mechanism is row-level: `groups`'
SELECT policy admits `mywork.*` scoped to the viewer's own sessions, RLS restricts rows and not
columns, and `notes` has an ordinary column-level SELECT grant.

**So the re-ask is not "does the field exist" but a policy question — carried as its own standing
entry, item 116 below, so it is findable by someone asking "what do group notes do" rather than
buried in a dated round:** a note Cătălina writes on a
group is visible, verbatim, to every trainer allocated to a session in it, and to nobody else. That
is current behaviour, not a proposal. If it is what she wants, nothing needs building. If notes are
meant to be internal to Operations, the fix is a column-narrowed read (a masked column or a
trainer-facing split), which is a build and needs her answer first.

**Payroll "Unknown" (item 65 above) — she is right about the person and the hypothesis in the
question was inverted.** Anka closes the month, not Laura; item 65 named Laura. Verified against the
policies, as asked, not from role names:

- **Who reaches `/payroll` today:** exactly three accounts. The gate is `finance.operations.*` **OR**
  `org.settings.manage` (`payroll/page.tsx`, matching `closePayrollPeriod`'s own gate). That is
  **Anka** and **Laura Moale** via `finance.operations.*`, and **Mihai** via `org.settings.manage`.
  Nobody else holds either — **Cătălina holds three roles** (`curriculum_manager`, `evaluator`,
  `operations_manager`, 22 capabilities between them), and **none of the three carries any finance
  capability**, so she cannot reach `/payroll`. An earlier draft of this line listed six capabilities
  and named one role: that was the output of a query filtered to the prefixes this question needed,
  mistaken for her whole set, and corrected 2026-10-12 — see item 117 below. The conclusion it
  supports is unchanged, re-checked against all three roles.
- **Which client segment that capability covers:** `finance.operations.*` sees
  **`private_school` + `parent_b2c`** on `clients` — **not** corporate and grants. The question had
  it the other way round, and the inversion matters: a private-school client like Lycée Français is
  precisely what a `finance.operations.*` holder **can** see. It is corporate/grant clients that read
  `Unknown` to them.
- **And Anka specifically cannot hit this at all.** She holds **both** `finance.operations.*` and
  `finance.reporting.*`. The two branches are complements (`client_type in (...)` /
  `client_type not in (...)`), so together they cover every client type. Her `clients.read` is
  neutralised by that branch's own `not finance.operations.* and not finance.reporting.*` guard, and
  it does not matter — she sees every client either way. **The closer named in the question is the
  one person who can never see "Unknown".**
- **Laura is the real exposure, and only Laura:** `finance.operations.*` with no
  `finance.reporting.*`. She is the only account in that state.
- **Still inert, for a different reason than item 65 gave.** That entry said `sessions` holds zero
  rows in `wow-lab`; still true today, and additionally **all four real `wow-lab` clients are
  `private_school`**, which Laura can see. Both conditions would have to change before this bites.
  The three sessions that do exist live are in Test Org B, on a `corporate` client — the exact mix
  that would trigger it, in the one org where it does not matter.

**What that leaves open is narrower than item 65 stated:** not "should payroll-closing see every
client's name", but "should a `finance.operations.*`-only closer see corporate and grant clients'
names on the payroll screen." Anka's own access makes the question moot for today's closer; it
becomes real the moment Laura closes a month in which a corporate session exists.

---

#### The catalogue, measured — these numbers correct item 103 above

Re-measured 2026-10-12 against the **current** export (`Centralizator module WOW LAB
2023-2024-2025 (1).xlsx`, 2026-10-07 — the one with VET unhidden), with an explicit per-sheet column
map rather than a header-sniffing heuristic. Item 103's figures came from the 2026-09-25 export and a
looser parse; both drifts are real and this is the current set:

| | item 103 (2026-09-25) | measured 2026-10-12 |
|---|---|---|
| sheets | 16 | 16 |
| lesson rows | 518 | **540** |
| plan-column strings | 515 | **512** |
| matching the filename pattern | 455 | **461** |
| distinct plans | 276 | **288** |
| on more than one sheet | 115 | **113** |
| MIX distinct / also elsewhere | 85 / 80 | **80 / 75** |

Two causes, both identifiable: VET's six rows are now visible and parse (+6 plans), and item 103's
parse picked up `Modul WOW LAB MIX`'s third block one column off — that sheet's **third header row
sits one column to the left of its own data**, so a header-driven parse reads its "Discutam despre"
column as the plan column and silently harvests 33 what-is-taught strings as plan references. **Any
importer has to handle that, and it will not announce itself** — the strings it produces look like
prose, not like filenames, which is how they survived one measurement.

Facts that did **not** drift and that the design rests on:

- **The four reliable columns are reliable across 15 of 16 sheets** — module (from the sheet),
  ordinal, title, what-is-taught. `CRACIUN` is the sixteenth and has none of them in that form
  (`No` / `Name of the experiment` / `Observations` / `Science behind`).
- **The plan-filename column is absent as such from two sheets.** `Modul ANATOMY` calls it
  `Link/ resurse (optional)` (and it carries real `ANAT_*` filenames regardless); `CRACIUN` has only
  `Link`, holding YouTube URLs.
- **What-is-taught is present as a column but not as a value:** 467 of 523 non-CRACIUN rows carry one
  (89%). `Modul CHEMISTRY FOR ME` has it on 16 of 32 rows, `MAGIC OF PHSYSICS` on 40 of 55. It cannot
  be `NOT NULL`.
- **Ordinal is per-sheet, not per-plan** — measured, not assumed: `TicTok_Rainbow vulcano_GS_28` is
  №1 on GAGA, №12 on TikTok Science and №17 on MIX. It belongs on the join row, never on the plan.
- **51 plan strings do not match the filename pattern, and 40 of them are chapter pointers** —
  17 on `Modul ANATOMY`, 23 on `I WANT TO BE A DOCTOR` (`1. Lungs`, `17. Immune system`). The other
  11 are a different problem each: a repeated title used as a plan (`Floating Soda Cans` ×3), the
  literal word `plan` ×2, `Lesson plan template - Oobleck` ×2, `Harry potter` (a *Poveste* value in
  the plan column), an author's note (`acelasi continut si acelasi tip de experiment cu PD_7`), and
  one `education.com` URL.
- **Anatomy: 23 rows, 6 distinct plans, all 6 also on the doctor sheet** — unchanged from item 103,
  and the exact six it names. **Doctor: 15 distinct plans. Vet: 6.**
- **`CRACIUN` carries zero plan filenames** and is an idea list with a `feedback Cata` column.

**Lives in:** `supabase/migrations/202610120001_add_anatomy_module.sql`,
`202610120002_set_lycee_francais_language_group.sql` and both rollbacks (all applied 2026-10-12);
`scripts/verify_anatomy_module_test_org_b.ts`; `scripts/verify_group_notes_trainer_visibility.sql`;
`app/(app)/groups/groups-client.tsx` (`MODULE_KEYS`), `app/(app)/groups/i18n.ts`
(`module_anatomy`); `app/(app)/groups/[id]/group-info-section.tsx` (the Notes `Kv` her screenshot
shows); `app/(app)/payroll/page.tsx` (the gate and the `"Unknown"` fallback);
`docs/WOWLAB_Spec_Trainer_Principal_Secundar.md` (two experiments, one owner each — the constraint
the session↔plan link has to carry); item 103 above (the three-axis question this closes and the
figures this corrects); item 65 above (the payroll gap this narrows); item 95 above (the language
bonus percentages); item 105 above (the admin-rate questions this round also answered, now item 111
below); item 116 below (group notes carried forward as current behaviour plus the one policy
question left); item 65 above (whose Blocked-on question this round replaced); commits `1bb1826`,
`83ad84e`.

---

### 111. Admin rates, complete — and the distinction a single rate column would destroy

2026-10-12, from Anca's 2026-08-07 message **as corrected by her 2026-08-10 one**. This closes the
two questions item 105 above carried for whoever picked up admin pay ("which of Anka's three task
types maps to 80, 80 and 90", and Raluca Margean's article tiers). Nothing here is built — there is
no admin-hours table on either side yet (item 23 below has the per-article half with no table
either).

**Two kinds of rate, and they must not be stored as one kind.** Four rates carry the 11% PFA/SRL
uplift (**this entry said 11.1% until 2026-10-12 — see item 128 below, which measured it against the
figures: 50 → 55.50, 72 → 79.92 and the trainer grid's 100 → 111 are all exact at ×1.11 and none is
exact at ×1.111**); five do not, because they are already the invoiced amount.

**FINAL — the invoiced amount. No 11% is added to either:**

| Person | Category | RON |
|---|---|---|
| Anka | Admin | 80 /hour |
| Anka | Ateliere | 80 /hour |
| Anka | Financiar | 90 /hour |
| Raluca Margean | article, 500–1000 words | 100 |
| Raluca Margean | article, 1000–2000 words | 150 |
| Raluca Margean | article, 2000–4000 words | 250 |
| Raluca Margean | article, over 4000 words | 350 |
| Raluca Margean | internal newsletter | 150 each |

**UPLIFTED — net, highlighted in her table, +11%** (not 11.1%; corrected 2026-10-12, item 128
below)**:**

| Person | Net | Invoiced |
|---|---|---|
| Laura | 50 | **55.50** |
| Teodora Merișan | 50 | **55.50** |
| Alexandra Nuțu | 50 | **55.50** |
| Cătălina Trușan | 72 | **79.92** |

**Why the distinction has to be in the schema and not only here.** A single `rate numeric` column
with no note loses which kind each number is, and the failure is directional and silent: someone
later adds 11% to Anka's 80 and invoices 88.80. **This is the same shape the trainer grid already
solved and recorded** — `trainer_grade_rates`' six values (111–150) are PFA-inclusive *already*, and
`contract_type_uplift` is kept at **zero rows, deliberately not seeded at 0%**, precisely so nothing
can apply the uplift twice (item 95 above, and `app.resolve_contract_type_uplift`'s own
`comment on function`). Whatever holds admin rates needs the same property: the uplift state is an
attribute of the stored rate, not an assumption of the reader.

**Anka's three categories, in her words — the task-type mapping item 105 above left open:**

- **Admin** — everything administrative but not financial
- **Ateliere** — workshop organisation, plus sales and ActiveCampaign
- **Financiar** — accounting and financial statements

**Cătălina's admin rate is new.** 72 net / 79.92 invoiced appears in no earlier record in this
project. She already has a trainer grade seeded (`202609240002`), so she is the first person on
record with **both** a trainer rate and an admin rate — which means an admin-hours table cannot key
pay on the person alone.

**Her article tiers supersede the supplier contract's three tiers.** Hers are newer and post-date
both amendments.

**RECONFIRMED 2026-10-12, by searching rather than by taking "verifică" at face value.** She said
*"am confirmat azi, verifică"*. Searched for anything dated today that confirms or changes the
figures, and found **nothing newer anywhere**:

| searched | result |
|---|---|
| `docs/progress.md` | **zero** occurrences of `2026-10-12`; the file was not touched today at all. Its only Margean content is the original Phase-1 requirement (line 128), which describes *"tarif per-articol variabil"* and states **no figures** |
| `docs/OPEN_ITEMS.md` | her figures appear only in this item, written today **from** her August message |
| `docs/` files modified today | three, all edited by this session |
| `~/Downloads` source files modified today | three PDFs, none a rate document |
| commits today | all from this working tree |

**So the August 2026-08-07 set is what she means, and the seeded values already are it** — 100 /
150 / 250 / 350 plus 150 per newsletter, verified in `admin_rates` as `100/150/250/350/150` across
five rows. **No new version is needed and the seeded rates were not touched**, which was the
instruction and is also the right call: a reconfirmation of existing figures is not a rate change,
and versioning it would create a second version identical to the first and imply a change that did
not happen.

**One honest limit on that conclusion:** this searched the repository and the local source files. Her
2026-10-12 message itself is not in either — it reached this session as a relay. If she sent new
numbers in a channel the repo does not hold, nothing here would show it, and the only way to know is
to read that message. What can be said positively: **no artifact anywhere in this project carries a
set of article tiers other than the August one.** Item 105 above asked "whether her article tiers survived two amendments" — they did
not need to: these replace them. The newsletter rate (150 each) is the figure item 105 recorded as
missing from the contract entirely.

**Admins enter their hours in the app, as trainers do.** Confirmed by her. No screen exists.

**Lives in:** item 105 above (the two questions this closes, and the supplier contract whose tiers
these supersede); item 95 above (the PFA-inclusive precedent and why `contract_type_uplift` is empty);
item 20 below (the six pay grids, none of which is an admin grid); item 23 below (per-article
writing, still with no table on either side); item 112 below (the entity attribution every one of
these hours also needs); `docs/progress.md` §128/§230 (the admin rate structures and her 2026-08-10
"80/80/90 is final" correction).

---

### 112. Every hour worked is attributed to a legal entity — a requirement nobody had, and admin hours have no path to one

2026-10-12, from Anca. New, and not derivable from anything already recorded: **every hour worked —
trainer or admin — is attributed to one of the three legal entities, depending on the project and the
client contract, and the invoice is received by the entity that ran the project.**

**Sessions already have a path to an entity; admin hours have none.** A session resolves one by
following `sessions → groups → contracts → legal_entity`, which is how `/payroll` and
`app.calculate_session_pay` already work — the entity is a property of the engagement, inherited, not
stored per hour. An admin hour has no engagement to inherit from: Anka reconciling a bank statement
or running ActiveCampaign is not attached to a group, a contract, or a client. The three categories
in item 111 above make this sharper rather than softer — **Ateliere** is workshop organisation and
plausibly resolvable per project, **Financiar** is accounting for the whole business and plausibly
not.

**What this means for the admin-hours design, reported rather than decided:**

1. **`legal_entity_id` cannot be derived on admin hours the way it is on sessions.** It has to be
   either stored per row (the entry form asks) or derived from a project link the row carries. Those
   are different screens, not different column defaults.
2. **If it is stored per row, it is a required field, and the form has to make the three entities
   choosable** — which means an admin entering time needs to know, per hour, which entity the work
   belonged to. That is a real question to put to Anka and Anka specifically, since she is both the
   person entering most of these hours and the person who knows the answer.
3. **If it is derived, something has to carry the link** — an optional project/client reference on the
   admin-hours row, which then has to resolve to an entity by the same contract path sessions use,
   and has to fail loudly when it cannot rather than defaulting. This project's resolvers already
   have that habit (`app.resolve_*` raise on an unknown rather than returning a silent value); an
   entity that silently defaults is a wrong invoice, not a smaller one.
4. **The "Financiar" category probably has no project at all**, so whichever shape is chosen needs a
   defensible answer for business-wide work — a nominated default entity, a split rule, or an explicit
   "not project-attributable" value. Guessing this is how an invoice goes to the wrong entity.
5. **Both of item 111 above's rate kinds have to survive the attribution**, i.e. the entity is
   orthogonal to the uplift question: Cătălina's 79.92 is 79.92 whichever entity ran the project.

**Not a blocker on the trainer side.** Sessions already resolve an entity, so this requirement
describes existing behaviour there and does not reopen anything built. It is purely a constraint on
the admin-hours screen that does not exist yet.

---

**RE-EXAMINED 2026-10-12, per side, now that the rate tables exist (item 128 below). The two halves
are not the same problem, and only one of them is a question for Anca.**

**The trainer half is already answerable, and this is checkable rather than asserted.** A session
reaches an entity by `sessions → groups.contract_id → contracts.legal_entity_id`, and every link in
that chain exists today: `groups.contract_id` was added by `202608290001`, `contracts.legal_entity_id`
is `NOT NULL`, and the three real `wow-lab` groups all carry a non-null `contract_id` pointing at a
signed contract (item 71's own correction records that). `app.calculate_session_pay` already walks
part of this path for `delivery_format`. **So the trainer half needs no column and no decision — it
needs a function that follows the path, plus one honest failure case: a group with
`contract_id` null has no entity, and the correct behaviour is to raise rather than to pick one.**
That is the same fail-loud discipline the six resolvers already use, and `groups.contract_id` is
nullable on purpose (a group can exist before its contract is signed), so the case is real rather
than theoretical.

**The admin half is a question for Anca, and a column cannot answer it.** Anka's hour spent on sales
belongs to an entity by a rule nobody has written down. The three task categories make the shape of
the problem visible:

| category | is it project-attributable? |
|---|---|
| **Ateliere** (workshop organisation, sales, ActiveCampaign) | plausibly yes — a workshop belongs to a group, which reaches an entity the same way a session does |
| **Admin** (everything administrative but not financial) | sometimes. Some of it is per-project, some is the business as a whole |
| **Financiar** (accounting, financial statements) | **almost certainly not.** Accounting for three entities is work for all three |

**So the answer is BOTH a question and a column, in that order.** The question first, because it
decides which column: if she attributes by project, the admin-hours row carries an optional
project/group reference and derives the entity the way a session does — and must raise, not default,
when the reference is absent. If she attributes directly, the row carries `legal_entity_id` as a
required field and the entry form asks her every time. **Those are different screens, not different
defaults**, which is why building either before asking would be a guess dressed as a schema.

**And whichever shape wins, `Financiar` needs its own answer.** Business-wide work has no project to
inherit from, so it needs a nominated default entity, a split rule, or an explicit
"not project-attributable" value. **An entity that silently defaults is a wrong invoice, not a
smaller one** — the same reasoning that keeps `contract_type_uplift` at zero rows rather than seeded
at 0% (item 95 above).

**The question to put to her, in one sentence:** *when you spend an hour on sales, or on the monthly
accounts, which of the three entities does it belong to — and do you decide that per hour, per
project, or by a standing rule per kind of work?*

---

**ANSWERED 2026-10-12 — the admin half is settled, and she chose the simpler of the two shapes.**
**The person picks the legal entity each time.** Not derived from a project, not inferred from
anything. So the admin-hours row carries a **required `legal_entity_id`**, asked at entry, and there
is no project reference on it at all.

**And `Financiar` is picked like any other category, not special-cased.** That is the part worth
recording loudest, because the analysis above treated it as the hard case — accounting for three
entities looked like work with no single owner, needing a default, a split rule or a
"not attributable" value. **None of those is needed.** Under her answer the question "which entity
does this hour belong to" is always answered by the person entering it, and `Financiar` is simply one
more hour where they answer it. The three categories stop differing in how they attribute; they
differ only in what the work is.

**What this retires:** the optional project/group reference, the second resolver that would have
walked `group → contract → entity` for admin hours, the raise-on-absent-project failure case, and
the nominated-default decision for business-wide work. Four pieces of design that her one-sentence
answer makes unnecessary — and the reason to have asked rather than guessed, since guessing would
plausibly have produced the project-derived shape and all four.

**The trainer half is unchanged and still buildable without her:**
`sessions → groups.contract_id → contracts.legal_entity_id`, every link present, needing a function
and one honest failure case (a group with a null `contract_id` has no entity, and the right
behaviour is to raise).

**Blocked on:** nothing on the admin side. The trainer-side function is unblocked and unbuilt.
**Lives in (addendum):** item 130 below (the other thing the same hour carries — its kind);
`public.legal_entities` (the three rows the entry form will offer).
**Lives in (addendum):** item 128 below (the rates these hours will price); item 130 below (the
other thing the same hour needs — its kind); `202608290001` (`groups.contract_id`, the trainer-side
path); `app.calculate_session_pay` (which already walks part of it).

**Lives in:** item 111 above (the rates these hours carry, and Anka's three categories); item 20
below (the pay grids, which hold no entity dimension); `public.legal_entities` (the three rows);
`app/(app)/payroll/page.tsx` and `supabase/migrations/202609250001_create_calculate_session_pay.sql`
(the inherited-entity path admin hours have no equivalent of).

---

### 113. An applied migration was missing from the remote history again — caught this time by the migration's own guard, not by a confusing failure

2026-10-12, found by running `db push` for item 110 above's two migrations and watching it try to
apply **`202610070003`** (the 22-supplier seed) first. Same class as the
"Migration history was missing 3 applied migrations — RESOLVED" entry above, five weeks later, one
file instead of three.

**It did not fail confusingly, because that seed was written to refuse.** `db push` reported
`supplier seed: org wow-lab already has 22 supplier row(s) -- refusing to seed on top of existing
data (SQLSTATE P0001)`. The earlier incident surfaced as `column "location_tier" … already exists`,
a generic 42701 three migrations away from the one being pushed. **The guard turned an alarming
failure into a self-describing one** — the migration said, in its own words, that its work was
already done.

**Confirmed it had actually run before repairing anything**, the same discipline the earlier entry
established: all three of `202610070003`'s own post-insert assertions hold live — 22 suppliers in
`wow-lab`, 5 with `user_id`, 3 with `cui is null` (2 withheld CNPs + Pidgin Host's absent one).
`supabase migration list --linked` showed exactly one local file with `"remote":""`, and the diff was
clean in the more alarming direction — **zero remote entries without a local file**, so nothing was
deleted from `supabase/migrations/` after being applied. `schema_migrations` held 95 rows against 98
files (95 + the 1 unrecorded + the 2 new = 98).

**Which path applied it cannot be proven after the fact** — there is no audit trail for DDL/seed
execution the way `row_history` covers DML — but item 105 above records `202610070002` and
`202610070003` as "both applied" on 2026-10-07, and `202610070002` **is** in the remote history. So
the two were applied by different mechanisms in that session, and only the second one's bookkeeping
was lost. Most likely a `db query --linked --file` run, the same shape the earlier entry inferred.

**Repair and verification:** `supabase migration repair --status applied 202610070003 --linked`,
then `db push`, then an independent live read — not `db push`'s exit code. `schema_migrations` now
holds **98 rows matching 98 files**, and both new migrations' effects were verified by querying for
them (15 modules, `'anatomy'` in the constraint, both Lycée groups at `ro_en`).

**Worth keeping because the frequency is the finding.** Twice in six weeks, an applied migration has
gone unrecorded, and both times `db push` was unusable for *anything* until it was repaired — it
always applies the oldest unrecorded file first, so one stale entry blocks every unrelated push
behind it, including the §6.2 rollback procedure. A cheap standing check: `supabase migration list
--linked` before any push, looking for `"remote":""` on a file that is older than what you are about
to send.

**Lives in:** the "Migration history was missing 3 applied migrations — RESOLVED" entry above (the
first instance, and the repair mechanism's own verification); item 105 above (which records
`202610070003` as applied, correctly — only the bookkeeping was missing);
`docs/WOWLAB_SAD_Field_Masking.md` §6.2/§6.4; `supabase_migrations.schema_migrations` (live, not
file-tracked).

---

### 114. The operator guide has been telling Anka and Cătălina to pick three workshop formats that no longer exist — for three weeks, and its own checker has been failing all along — FIXED 2026-10-12

2026-10-12, found incidentally: `scripts/check_operator_guide.ts` was run while confirming item 110
above's address question, and reported **3 of 34 manifest claims failing** — `groupsDict.
format_recurring`, `format_party` and `format_corporate` "does not exist or has no `ro` value."

**They do not exist, and they have not since 2026-09-21.** `202609210006` migrated
`groups.delivery_format` to Anca's nine workshop types (items 79/85 above), and commit `e0e8a1e`
removed those three keys from `app/(app)/groups/i18n.ts` in the same change. Verified against git,
not assumed: at `d526f4a` (the commit before today's work) `format_corporate` has **zero**
occurrences in that file, and `git log -S` puts its removal in `e0e8a1e`. **Nothing in today's work
touched `FORMAT_KEYS` or any `format_*` label** — this is pre-existing, three weeks old.

**The failing manifest rows are the smaller half. The guide's actual instruction to the operator is
wrong.** `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md` line 110 reads:
*"Formatul — Recurent (club școlar), Școala Altfel, Săptămâna Verde, Party, Corporate sau Custom"* —
the pre-decision six-value list. The live create-group form offers Anca's nine plus `custom`.
Mapped option by option rather than counted:

- **"Recurent (club școlar)"** — gone. The live pair is *Școli private (colaborări recurente)* and
  *Școli private (colaborări ocazionale)*; an operator looking for "Recurent" does not find it.
- **"Corporate"** — gone, and it **split in two**: *Parteneriate cu companii* and *Party în
  companii*.
- **"Party"** — no longer identifies one option. It now reads as either *Wow Lab Party* (the
  birthday product) or *Party în companii* (the same product at a company), which
  `format_party_companii`'s own comment says are deliberately the same product in two places. A
  guide that says "Party" tells the operator to guess between them.
- **Three names are still correct**: Școala Altfel, Săptămâna Verde, Custom.
- **Six live options are absent from the list entirely**: *Parteneriate cu companii*, *Cursuri
  deschise*, *Școli private (colaborări ocazionale)*, *Școli private (colaborări recurente)*,
  *Evenimente/prezentări la mall*, *Party în companii*.

**This is exactly the failure item 41 below was written to prevent, and the checker it built did
catch it — nobody ran it.** That entry's own reasoning for not wiring it into CI was that no CI
exists in this repo; the cost of that choice is now measured at three weeks. It is the same shape as
item 86 above (the RLS suite silently broken by a migration, with nothing running it in between) and
the same shape the register's own `scripts/check_open_items_register.ts` header warns about.

**Why it was not fixed on sight.** Renaming three labels is not the fix: the nine formats are not
renames of the six (`Corporate` split into `parteneriate_companii` and `party_companii`; `Recurent`
became `scoli_private_recurente` alongside a new `scoli_private_ocazionale`), so rewriting line 110
is a decision about what the operator should be told to pick for which engagement — procedure, not
wording. It was reported with that mapping laid out, Mihai decided it, and the fix below is his
mapping, not a reconstruction of it.

**FIXED 2026-10-12, same session.** Mihai supplied the six-to-ten mapping as a decision, so the
rewrite stopped being a guess. Pasul 3 now lists all ten formats with one line each saying when to
pick it, in Romanian, and carries a short old→new note for the two people who learned the list of
six. **Anca's own three worked examples, recorded in item 102 above and dropped at seed time, are
used as the explanation of the three options nobody had a reference for** — *cursuri de chimie*
(Cursuri deschise), *Science Week la IBSB* (Școli private ocazionale), *Barlad Value Center*
(Evenimente la mall), quoted as she wrote them. **Two further stale claims in the same section were
found and fixed while rewriting it**, neither of them machine-checkable: *"cele 13 module"* (now 15,
and this session's own `202610120001` is what made it staler), and *"pentru recurent: ziua și ora"*,
where "recurent" no longer names one option — corrected to *Școli private (colaborări recurente)*,
which `groups-client.tsx`'s `isRecurring` check confirms is the only format that takes a day-and-hour
schedule. **The manifest grew from 34 rows to 38**, not back to 34: the three dead rows were replaced
with all ten real formats, so the whole list in Pasul 3 is verifiable rather than half of it.
`check_operator_guide.ts`: **38/38**.

**Why nobody ran it for three weeks is recorded separately, in item 115 below** — the checker has no
trigger anywhere a person would meet it, unlike the other three.

**Blocked on:** nothing — fixed.
**Re-verify when:** any `format_*` or `module_*` label changes again — run
`npx tsx scripts/check_operator_guide.ts`.
**Lives in:** `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md` — the "Manifest" table (whose
three dead rows became ten) and "Pasul 3 — Grupele" (the wrong instruction); cited by section rather
than by line number, since this entry's own fix moved every line below it;
`scripts/check_operator_guide.ts`; commit `e0e8a1e` and
`supabase/migrations/202609210006_migrate_groups_delivery_format_to_nine_workshop_types.sql` (the
change that invalidated it); item 41 below (the entry that created both guide and checker);
item 102 above (`custom` as the tenth value, **and the three Anca examples this fix finally puts in
front of an operator**); item 86 above (the same "a checker nobody runs" shape, one layer down);
item 115 below (why three weeks passed).

---

### 115. The operator-guide checker had no trigger — the only one of the four without one, and the trigger it did have was written where the wrong person reads it — TRIGGER ADOPTED 2026-10-12

2026-10-12, recorded separately from the fix (item 114 above) because the fix is three weeks of wrong
instructions and this is why nobody noticed. The checker **worked**: it caught all three dead format
keys on its first run after `202609210006`, and would have caught them on any run in between. It was
not run for three weeks, and when it finally was, it was by accident — while confirming something
else entirely.

**Four hand-run checkers, and only one of them has nowhere to say when to run it.** Measured against
this file's own preamble, not asserted:

| Checker | Named in the preamble | Trigger stated there |
|---|---|---|
| `check_open_items_register.ts` | own block | "after any pass that edits several items at once" |
| `run_rls_suite.ts` | own block | "after any migration that touches `CREATE POLICY`/`DROP POLICY`/`ALTER POLICY`, or that renames or drops a column any policy or test reads" |
| `check_deploy_status.ts` | own block | "after any push meant to reach `app.wowlab.ro`, before trusting any verification done there" |
| **`check_operator_guide.ts`** | **one passing clause inside another checker's block** | **none** — until 2026-10-12; it now has its own block, see "Adopted" below |

Its only mention in this register is the half-sentence *"Run by hand, same as
`scripts/check_operator_guide.ts` and for the same reason — no CI exists in this repo to run it
automatically"* — which says how it runs and why it isn't automated, and never says when.

**It does have a trigger. It is written on the artifact being protected, which only the person
already reading that artifact will see.** `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md`'s own
"Obligație de întreținere" section is explicit: *"Orice schimbare la `clients-client.tsx`,
`contracts-client.tsx`, `groups-client.tsx`, la `actions.ts`-urile lor, sau la `i18n.ts`-urile lor
trebuie verificată împotriva acestui ghid — inclusiv manifestul de mai jos — înainte de a fi
integrată."* That is exactly the change `e0e8a1e` made. **The obligation was already correct and
already named the right files; the person making the change had no reason to open the document that
carries it.** The other three checkers put their trigger in front of the actor — in the register
everyone editing this register reads, next to the push, next to the migration. This one put it behind
the door it was guarding.

**And the obligation's wording would have missed it anyway, for a second reason.** It names UI files
only. The change that invalidated the guide was a **migration** (`202609210006`) that replaced a
CHECK-constrained vocabulary; the i18n edit rode along in the same commit. Someone who had read the
obligation and was writing a migration would not have seen themselves in it.

**ADOPTED 2026-10-12, same session, on Mihai's decision — the fourth preamble block now exists, above.**
What was proposed, and what went in verbatim: a block with the condition phrased as an action rather
than as a document's self-defence:

> **`scripts/check_operator_guide.ts`** diffs the operator guide's manifest against the live i18n
> dictionaries. **Run it after any change to `clients`/`contracts`/`groups` `i18n.ts`,
> `*-client.tsx` or `actions.ts`, and after any migration that changes a vocabulary those screens
> render** — `delivery_format`, `module`, `client_type`, `business_line`, `contract_type`. The
> migration half is the one that was missing: `202609210006` changed `delivery_format`'s nine values
> and left the guide naming three that no longer existed, for three weeks (item 114 above).

Two things deliberately **not** proposed. **CI**: this project has declined it on purpose, twice in
writing, and one stale document in three weeks does not overturn that — a trigger the author reads is
cheaper and this failure was an absence of prompting, not an absence of automation. **Folding it into
`check_open_items_register.ts`**: they check different things for different reasons, and a checker
that runs other checkers hides which one failed.

**The limit of any trigger here, stated because it bounds the fix.** The same section of the guide
carried a *second* wrong claim — *"Modulul — cele 13 module"*, stale since `202610070001` added vet
and staler after `202610120001` added anatomy — and **no trigger would have caught it**. The
manifest covers only literal i18n strings; the guide's own preamble says behavioural claims like
"cele 13 module" are excluded by design and verified by hand. So one section held two defects of the
same age, one machine-checkable and one not. Both were fixed in item 114 above's pass; only the first
one could ever have been caught by running something.

**A second bound, found the same way the first was — by a change sailing past a green run.** The
2026-10-12 rename (item 120 below) rewrote 47 dictionary lines and broke **eleven Romanian
agreements** doing it, because `atelier` is neuter where `ședință` and `sesiune` were feminine. This
checker reported **38/38 both before and after**, and was right to: it compares each manifest claim
against the live dictionary string, so a claim and a string that are equally ungrammatical agree
perfectly. **It checks that the guide matches the code, never that either is correct Romanian.**
That is not a defect to fix here — a grammar checker for two languages is far outside what a
manifest diff should attempt — but it is the second thing a green run does not mean, and it belongs
beside the first. The practical rule it implies: **a find-and-replace across both languages needs
every changed RO line read by a human; the EN side does not, because English nouns carry no gender.**

**And the excluded class had a third instance, in the sentence that defines the exclusion.** The
guide's manifest preamble lists *"cele 13 module"* as its own worked example of a claim the checker
does not cover — and that example was itself stale, with the same wrong number, three weeks after
vet. Found 2026-10-12 by scanning the guide for every count rather than by trusting that fixing the
one in Pasul 3 had fixed "the module count". Both now read 15, **verified against `public.modules`
directly rather than against the migration that changed it**: 15 rows, and `groups_module_check`
carries the same 15 keys — the two objects `202610070001` warned can drift are in step. The guide's
exclusion sentence now also names counts-of-database-contents explicitly, so the next reader does not
have to infer that a number is unverifiable from the fact that it is not a dictionary string.

**One divergence found by the same scan — reported first, then fixed in the direction that was
decided.** Pasul 2 names the three legal entities by hand and wrote **"Asociația STEMplicity"** with
a diacritic; the live row in `public.legal_entities` is **"Asociatia STEMplicity"** without one,
which item 42 below established is correct by convention here and not a typo (Anca confirmed it on
her own name). So the operator read one spelling and saw another on screen. It was reported rather
than applied, because the two possible fixes point in opposite directions and "correct the thing that
looks wrong" is the exact shape items 35 and 42 below record as having nearly corrupted correct data
twice. **Mihai decided it the same day: the document moves, the data does not** — the guide's job is
telling someone what to click, so it names what is on screen. **The reasoning is written into the
guide beside the word**, not only here, so the next person to notice the missing diacritic finds out
why before "fixing" it back.

**The org-scoped count trap, recorded because it will catch someone.** `legal_entities` holds **five
rows across all organizations** — 3 real in `wow-lab`, 2 test fixtures in Test Org B. The guide's
"three" is right **because it is scoped to `wow-lab`**, not because the table holds three rows. A
bare `select count(*) from public.legal_entities` returns 5, reads as a discrepancy against the
guide, and is not one — anyone verifying that line has to filter by organization. Also stated in the
guide itself, next to the three names, for the same reason the diacritic note is: the person who will
run that count is reading the guide, not this register.

**The quoted half-sentence above is left in the preamble unchanged, on purpose.** It is still true —
both checkers are hand-run for the same reason — and it is this entry's own evidence. Rewriting it to
point at the new block would have made the quote above a misquote, which is the failure mode this
register's own checker exists to catch one level down.

**Blocked on:** nothing — done.
**Re-verify when:** the next migration changes a rendered vocabulary. **If the guide goes stale again
with the trigger in place, the trigger is the wrong shape and CI becomes the honest answer** — that
is the test this block has to pass, and it has not passed it yet; one adoption is not evidence.
**Lives in:** item 114 above (the three weeks of wrong instruction this explains); this file's
preamble (now four checker blocks, the fourth added by this entry); item 42 below (the
diacritic-free-names convention the Pasul 2 divergence sits on top of);
`docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md` ("Obligație de întreținere", the trigger in the
wrong place); `scripts/check_operator_guide.ts`; item 86 above (a checker silently broken by a
migration with nothing running it in between — the same shape one layer down).

---

### 116. Group notes are visible, verbatim, to every allocated trainer — CLOSED 2026-10-12: Anca confirmed the current behaviour, nothing to build

2026-10-12. Recorded on its own because the question that produced it was asked as "is there a Notes
field", and the answer to *that* is yes — her own screenshot shows it. The question worth asking is
the one underneath, and it is already answered in code: **a note Cătălina writes on a group is read
back verbatim by every trainer allocated to a session in that group, and by nobody else.**

**Current behaviour, all five halves proven against the live policies** — not read off the render
code — by `scripts/verify_group_notes_trainer_visibility.sql`:

1. an `operations_manager` (Cătălina's role) **can write** `groups.notes` — 1 row updated
2. the allocated `trainer_principal` **reads it back verbatim**
3. the allocated `trainer_secundar` **reads it back verbatim**
4. a trainer with **no** session in that group sees **no row at all**, so no note
5. the allocated trainer **cannot write** it — 0 rows updated, read-only to them

The mechanism, so nobody re-derives it: `groups`' SELECT policy carries a `mywork.*` branch scoped to
the viewer's own sessions; **RLS restricts rows, not columns**, and `notes` has an ordinary
column-level SELECT grant to `authenticated`. There is no masking layer on this column and never
was — so trainer visibility is not a feature that was built for notes, it is what any `groups` column
gets once the row is visible. `groups`' UPDATE policy admits no `mywork.*` branch at all, which is
why (5) holds.

**Run in Test Org B, because the real org cannot answer it.** `wow-lab` holds **zero sessions**, so no
trainer is allocated to anything there and the `mywork.*` branch is unreachable. Test Org B carries
the same role keys against the same policies. Also measured: all four real `wow-lab` groups have
`notes = NULL`, which is why the field renders `—` and reads as absent.

**The open part is a policy question for Anca, not an engineering one.** If trainer-visible notes are
what she wants, nothing needs building — this is already the behaviour. If notes are meant to be
internal to Operations, the fix is a column-narrowed read (a masked column, or a trainer-facing
split the way `client_contacts` got one in `202609210002`), and that is a real build that needs her
answer first. **Nothing should be built either way until she answers**, because the two outcomes are
"no change" and "a new masking surface", and guessing between them is how `children_billed` ended up
settled by accident on the read side (item 39 below).

**CLOSED 2026-10-12 — Anca confirmed it, the same day it was measured.** Group notes stay visible to
allocated trainers. The behaviour above is the intended behaviour, not a gap that happened to be
convenient: **nothing is built, nothing is narrowed, no masking surface is added.** The
`client_contacts`-style trainer-facing split named below as the precedent is explicitly *not* taken.

This closes as **confirmed**, which is a different and stronger outcome than either of the two it
could have had: not "resolved" (nothing was broken) and not "accepted" (she did not tolerate a known
gap). What made that possible was the question reaching her as *"this is what happens today, is it
what you want"* rather than as *"is there a Notes field"*, which is what her first answer had been
asked.

**Blocked on:** nothing — closed.
**Re-verify when:** any change to `groups`' SELECT policy or to column-level grants on
`groups.notes` — the confirmation is of today's behaviour, so it stops applying if that behaviour
changes underneath it.
**Lives in:** item 110 above (the round this came from, and the screenshot contradiction);
`scripts/verify_group_notes_trainer_visibility.sql`;
`app/(app)/groups/[id]/group-info-section.tsx` (the Notes `Kv`, last row of Group info);
`app/(app)/groups/actions.ts` (`updateGroup` — `notes` gated on `groups.create`);
`supabase/migrations/202609210002_narrow_client_contacts_trainer_facing_branch.sql` (the
trainer-facing split that is the precedent if the answer is "hide it"); item 39 below (the adjacent
field settled by omission, the outcome this entry is written to avoid).

---

### 117. Experiment validation moves out of WhatsApp and into the app — Anca's decision, plus the capability that already exists for it and the predicate that would have locked her out

2026-10-12, Anca. Recorded as a decision with its measured preconditions; **nothing built**, and the
two designs it implies were reported the same date rather than written (see "Reported, not built"
below).

**The decision, in four parts:**

1. **The trainer picks a lesson plan in the app.** Which is the selector she asked for in item 110
   above — the same screen, now with a second job.
2. **Cătălina approves it in the app**, not on WhatsApp.
3. **The trainer is told.**
4. **"Told" means a notification the trainer meets on entering the app, which can be marked seen** —
   explicitly more than a line on `/my-work`. **Email later, if at all**, and only once it is clear
   people are not opening the app often enough. So email is conditional on an observation nobody has
   made yet, not scheduled.

**What this replaces, from the responsibilities document rather than from a description of it.**
`docs/WOWLAB_Spec_Trainer_Principal_Secundar.md` sets out the real process, and the app version
collapses one step of it:

| When | Who | What the document says |
|---|---|---|
| min. 8–10 days before | each trainer | *"Alege experimentul pe care îl va susține"* — the secundar also *"Comunică propunerea Trainerului Principal"* |
| min. 7 days before | **principal** | *"Trimite Cătălinei propunerile de experimente ale ambilor traineri. Obține validarea celor două experimente. Transmite confirmarea Trainerului Secundar."* |
| min. 7 days before | **secundar** | *"Primește confirmarea validării experimentului de la Trainerul Principal. **Face eventualele modificări solicitate.**"* |

**The principal's courier role disappears if each trainer is told directly** — *"Trimite Cătălinei
propunerile ... ale ambilor traineri"* and *"Transmite confirmarea Trainerului Secundar"* are both
message-passing that an app with per-trainer rows does not need. Anca's decision implies that but
does not say it, so it is flagged rather than assumed settled.

**`curriculum.validate` already exists, and the four people who hold it are the four who should.**
Measured live, not proposed: the capability is defined (`"Validate curriculum content."`), carried by
the roles `curriculum_manager`, `organization_owner` and `platform_owner`, and held today by exactly
**Anca Tanasescu, Anka Orban, Cătălina Trușan and Mihai** — nobody else, no trainer, no finance role.
**No new capability and no role change is needed for the approval gate.**

**And the predicate most policies in this schema reach for first would have locked Anca out of her
own app.** `app.is_platform_owner()` reads the `users.is_platform_owner` **column**, not the
`platform_owner` **role** — and for Anca that column is **`false`**, despite her holding the role.
Her access comes entirely through `app.has_capability(...)`. So an approval policy written as
`app.is_platform_owner() OR app.has_capability('curriculum.validate', organization_id)` works by
accident of the second clause, and one written on the owner predicate alone would admit Mihai and
refuse Anca. Stated here because this register has already recorded the inverse surprise once (the
preamble's own correction: *"Anca's actual permission state corrected (platform_owner and
sales_manager, not organization_owner; `is_platform_owner` false)"*), and it is the kind of thing a
policy author re-derives wrongly at speed.

**Cătălina holds three roles, not one** — `curriculum_manager`, `evaluator`, `operations_manager`,
22 distinct capabilities. Worth stating because item 110 above describes her as `operations_manager`
and lists six capabilities: that list came from a capability query filtered to the finance/clients/
groups/sessions prefixes the payroll question needed, and reads as her whole set when it is not.
**The payroll conclusion it supports is unaffected** — re-checked against all three roles, none of
them carries `finance.operations.*`, `finance.reporting.*` or `org.settings.manage`, so she still
cannot reach `/payroll`. Corrected in place in item 110 above as well.

**BUILT, DEPLOYED AND VERIFIED END TO END 2026-10-12.** Five migrations applied (`202610120003`-`202610120007`): the catalogue
(312 plans, 498 placements), `session_lesson_plans` with the three states and `decision_seen_at`,
three SECURITY DEFINER routing functions with their wrappers, and `sessions.experiment_delivered`'s
comment restated. `db/tests/lesson_plan_catalogue.sql` adds 52 assertions including a sabotage check
that replaces the SELECT policy's scoping clause with `using (true)` and confirms the
unrelated-trainer assertion flips; the suite runs **171 passed, 0 failed**. UI: a searchable
selector and Catalina's validate/request-changes controls on the group page, the notification on
`/my-work`, and `lib/landing.ts` resolving the post-login destination for both entry points.

**Verified against the real deployment**, not only locally:
`scripts/verify_lesson_plan_flow_test_org_b.ts` walks the whole loop on `app.wowlab.ro` as the real
accounts -- the trainer sees the section and the chooser and NOT the validate controls; proposes
through the real RPC; is refused when trying to validate their own plan (`not_permitted`); the
`curriculum.validate` holder sees the proposal, is refused a blank change-request (`note_required`),
and requests changes; the trainer meets the notification on `/my-work` with the note on it, marks it
seen, and it is gone on the next load. RO verified by shipment in the client bundle, which is the
weaker claim and labelled as one. All expectations held; cleanup ran and said so. The deploy itself
was briefly misreported as never having happened -- item 118 below.

**Two things in the preceding report were wrong and are corrected in the code's own comments.**
(1) The link is `unique (session_id, trainer_id)` -- ONE row per trainer per session -- not the
`(session, trainer, plan)` triple that report recommended: update-in-place with the history in
`row_history` needs a stable address for "this trainer's experiment", and the triple is not one.
The document's own wording ("propriul experiment", singular) is the evidence; the two-hour-workshop
case was speculation. (2) A finance-only account **does** see proposals, because `finance_operations`
holds `sessions.read` -- the branch the policy keys on. The test asserted otherwise and failed; the
policy was right and the assertion was wrong, since finance already reads that session's trainers,
duration and location tier as pay inputs. Both recorded where they will be read.

**Reported, not built — two designs, 2026-10-12.** (a) the approval state on `session_lesson_plans`
(which states, who moves between them, who may approve, and what happens to a session delivered
without approval); (b) the in-app notification (whether it needs a table of its own, and where it
appears). **Where they meet is the one thing that has to be settled in the same pass as the
catalogue:** the approval row is itself the notification, so the "seen" marker is one more nullable
timestamp on `session_lesson_plans` rather than a notifications table — free to add while that table
does not exist, and a backfill across live link rows once it does. Both were reported for decision;
neither is recorded here as decided, deliberately.

**Blocked on:** Mihai/Anca — the two reported designs, in particular whether `changes_requested` is
a state (the document's *"Face eventualele modificări solicitate"* argues it is) and whether
`/my-work` becomes the trainer's landing surface.
**Re-verify when:** before writing `session_lesson_plans` — re-check `curriculum.validate`'s holders,
since the whole gate rests on four role assignments that nothing prevents from changing.
**Lives in:** `docs/WOWLAB_Spec_Trainer_Principal_Secundar.md` (the process this replaces, quoted
above); item 110 above (the catalogue and the selector this attaches to, and the session↔plan↔trainer
link it needs); item 116 above (closed the same day, the other half of this round);
`app/(app)/my-work/page.tsx` (where the notification would surface); `app/page.tsx` and
`app/auth/callback/route.ts` (the two `/profile` defaults, only one of which real sign-ins pass
through); `public.capabilities` / `public.role_capabilities` (where `curriculum.validate` already
sits); `app.is_platform_owner()` (the predicate that excludes Anca).

---

### 118. `check_deploy_status.ts` gives up before a slow first status arrives — and I explained the same observation wrongly twice before measuring it out

2026-10-12. For the catalogue commit `18dec06` the script reported:

> `IS on the remote (origin/main) but GitHub has ZERO status contexts for it after 3 checks -- so it
> was pushed and nothing reported, which is a permanent condition, not a build in progress. Treat as
> NOT deployed.`

**It deployed. The conclusion was wrong, and so were my first two explanations of it.** What
actually happened, measured rather than reasoned:

Measured afterwards from GitHub's own status timestamps, so the window is a number rather than an
impression — and the two slow ones are the two that were pushed within two minutes of each other:

| commit | committed (UTC) | Vercel `success` | first-status lag |
|---|---|---|---|
| `4df31c5` | 09:01:09 | 09:02:03 | 54s |
| `3c86f80` (fra1) | 09:41:30 | 09:44:55 | **3m25s** |
| `18dec06` (catalogue) | 09:43:30 | 09:47:07 | **3m37s** |
| `519b114` | 09:46:53 | 09:48:18 | 85s |
| `c4fbb0b` | 09:53:16 | 09:54:28 | 72s |

**So the script's patience (~30s) is shorter than this project's own normal first-status lag on a
busy minute, by a factor of four.** A parallel session measured `3c86f80` independently and got the
same ~2.5-3 minutes.

**The finding is the give-up window, not the discriminator.** Item 108 above added `total_count` to
tell "genuinely building" from "nothing reported", and that distinction is still right -- a pending
build does have a context. What it cannot tell is *not yet reported* from *never will be*, because
both read as zero, and the script resolves that ambiguity by waiting only ~30 seconds. On a day when
the first status took minutes, 30 seconds of silence became "permanent condition" and
"Treat as NOT deployed."

**Two wrong explanations, both written down before being checked, recorded because the pattern is
the point.** First: "queued behind the commit before it" -- which fit the one observation in front of
me (`3c86f80` pending with 1 context, mine with 0) and died when `3c86f80` succeeded while mine
stayed at zero. Second: "Vercel never built it" -- which fit the next observation and died when the
status arrived minutes later. Each time the symptom was real, each time a mechanism that fit the
latest single reading got written as the cause. **That is item 109 above's lesson verbatim** ("a
confirmed symptom plus a plausible mechanism is still a guess"), now with three data points instead
of one: `4df31c5` success, `3c86f80` success, `18dec06` success-but-late. A parallel session
reporting the same symptom from the other side is what forced the first re-check; its own reading
(that the one context might be Supabase's rather than Vercel's) was also wrong, and asking produced
the table that settled it.

**The fix, proposed and deliberately not applied: the asymmetry is backwards, and the discriminator
it should key on is one the script already computes.** Zero contexts means two different things, and
the script can already tell them apart -- it checks `/commits/<sha>` (422 for a commit GitHub has
never seen) separately from `/commits/<sha>/status`, which is how its own message can say
"IS on the remote." Today that knowledge only reaches the error text; it does not reach the polling
decision. It should:

- **Present on the remote, zero contexts → keep polling, the full thirty.** A commit GitHub
  confirms it has is a commit a build is owed for. This is the case that gets three polls today and
  deserves the patience.
- **Absent from the remote → stop immediately, zero polls.** Nothing will ever report on a commit
  that was never pushed; waiting thirty cycles for it is the useless half of the current behaviour,
  and it is the half that currently gets all the patience. Item 109 above is exactly this case (a
  push that ran in the wrong directory), and it wants a fast, specific failure: "not on the remote",
  not thirty polls ending in an ambiguous verdict.
- **Report the third state honestly:** "on the remote, no status after N minutes" is not
  "NOT deployed". The verdict should name what was observed and what was not.

Held for its own pass regardless of how small it is: this is the one script that tells truth from
silence about deploys, it has now been wrong in three different directions (item 94 above: failure
read as success; item 108 above: non-report read as build-in-progress; this: slow report read as
no-report), and every fix so far was written while chasing something else -- which is how a script
accumulates three failure modes.

**A FOURTH state, found 2026-10-13, that the proposed fix above still does not cover: GitHub
reachable but refusing.** The script queries GitHub's commit-status API **unauthenticated**, which
is 60 requests an hour, and this project's own polling loops exhausted that budget on 2026-10-12 —
after which every call returned `403` and `fetchStatus` threw `GitHub API returned HTTP 403` for
every commit, valid or not. **So in exactly the situation it exists for — a day when deployments
were failing and nothing else could tell truth from silence — the script could not answer at all.**
The two-branch fix proposed above keys on *present on the remote* versus *absent from the remote*;
both branches assume the status endpoint answers. A 403 belongs to neither, and the script's current
behaviour is to raise and exit non-zero, which is indistinguishable from "failed to deploy".

**The answer came from the Vercel API instead, queried directly by sha**, and that is the deeper
point: **Vercel is the source and GitHub is only the intermediary.** The commit status is something
Vercel *posts to* GitHub after the fact; the deployment record is the thing itself. Querying Vercel
answers the question directly, carries `errorCode` and build duration, needs no second system to be
healthy, and is authenticated — so it has a real rate limit instead of 60 anonymous calls shared
with whatever else is running:

```
curl -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v6/deployments?projectId=<proj>&teamId=<team>&sha=$(git rev-parse HEAD)&limit=1"
```

Zero deployments for the sha is unambiguous in a way GitHub's `total_count: 0` never was: it means
Vercel has no record of that commit, which is item 126 below's state 2 exactly. **So the fix to this
script is larger than the two-branch change proposed above — it should ask Vercel, not GitHub.** The
`VERCEL_TOKEN` already lives in `.env.local`, and the project and team ids in `.vercel/project.json`,
so the dependency is one the repo already carries. The one thing GitHub is still needed for is the
*absent from the remote* branch, which `git branch -r --contains` already answers locally without
any API at all.

**Interim workaround, used today:** `until [ "$(…/status | total_count)" != "0" ]; do sleep 10; done`
before running the script. Crude and correct.

**Blocked on:** nothing — but the change is no longer the scoped one first proposed here. Switching
the source from GitHub to Vercel is a rewrite of what the script asks, not an adjustment of how long
it waits.
**Re-verify when:** that change lands. **Four** assertions to write now, one per state: a commit
present on the remote with no status yet keeps being polled and reports "no status yet", never
"not deployed"; a commit absent from the remote exits immediately saying so, without polling; a
commit with a deployment reports that deployment's `errorCode` and duration; and **a commit with no
deployment record at all is reported as "Vercel has no record of this sha" rather than as a
failure** — that is item 126 below's state 2 and the script has never had a name for it.
**Lives in:** `scripts/check_deploy_status.ts`; item 108 above (the `total_count` discriminator this
refines rather than replaces); item 94 above (the 25h8m silent failure these scripts exist for);
item 109 above (the mistake class this entry repeated twice); item 117 above (the work this briefly
reported as undeployed, since verified live); item 126 below (the outage during which this script
could not be used, and the fourth state it exposed).

### 119. Functions ran in Washington, the database is in Frankfurt — moved to fra1 2026-10-12, measured with controls, and every production timing before 09:44:55Z carries the distance

2026-10-12. Mihai: the app feels slower than it should. Measured on app.wowlab.ro before optimising
anything, signed in as wow-lab-test-b fixtures (`test+user-b@wowlab.dev`, organization_owner;
`maxdigitalro+trainerb1@gmail.com`, trainer).

**The cause was distance, not work.** Every response carried `x-vercel-id: fra1::iad1` — entering
at Frankfurt, executing in Washington (`iad1`, Vercel's default for new projects) — while the
database is in `eu-central-1`. Each Supabase call from a page function crossed the Atlantic:
**103–107 ms p50 origin time per call** (Supabase edge logs, colo IAD, ~2,775 calls across the
measurement windows; p90 114–229 ms, the tail being fresh connections). Pages make **15–27 calls**,
most of them in sequence (9–17 of them `has_capability`). The SQL itself was never the cost:
`has_capability` executes in 1.25 ms mean over 19,199 calls, the heaviest page query in 16–21 ms.

**The change:** `"regions": ["fra1"]` in `vercel.json`, commit `3c86f80`. Hobby allows exactly one
function region, chosen freely; set in `vercel.json` rather than the dashboard so it is visible in
review. Vercel `success` at 09:44:55Z (item 118 above's table); last `iad1` response observed
09:44:54Z, first `fra1::fra1` response 09:45:25Z. **Per-call origin time after: 11–14 ms p50**
(colo FRA, ~2,850 calls; p90 21–36 ms).

**What a call costs in wall time is a different number, and both are true.** Origin time is measured
inside Supabase's edge. Seen from the function, a sequential call costs **~30–35 ms** in fra1 —
measured on `/auth/callback`, where each added call can be counted from the logs (11 extra calls
added ~350 ms; 3 added ~100 ms). Re-cost any "N fewer calls" proposal at ~30–35 ms per call, not 12.

**Four pages untouched by anything else that shipped today** (warm median of five, same harness both
sides; `18dec06` went live mid-measurement at 09:47:12Z but changes none of these four or the
layout):

| page | first byte before | first byte after (run 1 / run 2) | first paint before | first paint after (run 1 / run 2) |
|---|---|---|---|---|
| /clients | 1.86 s | 0.46 / 0.69 s | 1.88 s | 0.88 / 0.68 s |
| /contracts | 1.85 s | 0.44 / 0.52 s | 2.95 s | 0.73 / 0.90 s |
| /groups | 1.74 s | 0.42 / 0.52 s | 2.45 s | 0.77 / 0.78 s |
| /suppliers | 1.65 s | 0.44 / 0.40 s | 2.28 s | 0.72 / 0.71 s |

"Before" is the 09:35Z run; first paint is headless Chrome, cold cache per run. The projection had
been 0.3–0.5 s. First byte landed at 0.40–0.69 s; first paint at 0.68–0.90 s, because the browser's
own CSS/font/JS work (~100–250 ms) now shows where it used to overlap the long server wait.

**The controls — what makes this a measurement rather than a before-and-after:**

- **Things that do not run in the page function did not move.** Static file 37–41 ms → 36–40 ms.
  The middleware sign-in check, which already ran in Frankfurt: 17 → 14 ms p50, 35 → 24 ms p90, with
  the same request volume (314 vs 305). Response headers in the browser: ~89–143 ms → ~90–95 ms.
- **The one thing that runs in the function without touching the database fell by about the round
  trip:** `/login` 170–181 ms → 77–88 ms. (It was treated as a network floor in the first report; it
  was itself paying the hop to Washington.)
- **The distributions do not overlap.** Fastest before-run on the four pages: 1.60 s. Slowest
  after-run: 0.98 s in run 1, 1.55 s in run 2 — run 2 was noisier, with a single /groups outlier,
  and still did not cross.
- **The baseline was taken twice, twenty minutes apart, and agreed** (09:15Z and 09:35Z: /clients
  1.86 / 1.86 s, /contracts 1.82 / 1.85 s, /groups 1.77 / 1.74 s, /suppliers 1.64 / 1.65 s).

**Re-baseline, as of 10:05Z (`18dec06` live), for the next change on these two pages:**

| page | first byte | first paint |
|---|---|---|
| /groups/[id], owner | 0.71 s (run 1: 1.00 s) | 1.32 s (run 1: 1.11 s) |
| /groups/[id], trainer | 0.59 s (0.63 s) | 1.06 s (1.12 s) |
| /my-work, owner | 0.43 s (0.41 s) | 0.82 s (0.74 s) |
| /my-work, trainer | 0.48 s (0.57 s) | 0.75 s (0.77 s) |

`/groups/[id]` is now the slowest page by about 2× (owner HTML 37.7 KB, up from 33.0 KB with item
117 above's catalogue).

**What this means for every timing taken before today.** Any production timing measured before
09:44:55Z carries a transatlantic round trip per database call — roughly 100–300 ms each, times the
number of sequential calls on the path. **The dead-zone figure behind the `pendingCreate` banner is
in that category.** Commit `38fe153` (2026-09-10) measured "the create form closes at ~0.7s, the new
row appears at ~2.4s" and concluded "Not something to make faster — the fix is showing the wait."
The ~1.7 s between the two is the revalidated list page re-rendering on the server, and that render
took 1.74–1.86 s under `iad1` against 0.40–0.69 s now. So the 2.4 s was most likely mostly distance,
not work — **an inference, not a re-measurement**: nobody has timed that create flow in fra1. The
closest measured thing, a save on the group detail screen through the UI (owner, wow-lab-test-b),
landed in 0.86–1.60 s.

**Item 118 above, from this side.** Its premise was wrong twice today ("queued behind the previous
commit", then "Vercel never built it"), and the defect that stands is the one it now names: the
script gives up after ~30 s when no status has appeared, against a first-status lag measured at
54 s–3 m 37 s that day (its own table) — 2× to 7× longer than the window. `3c86f80` is one of its
data points: the script reported "Treat as NOT deployed" at ~30 s, and the first Vercel status
appeared ~2.5–3.5 min after the push. The fix is held for its own pass, as item 118 above says.

**Not changed in this pass, and re-costed rather than built:** batching the 7–17 capability checks
per page into one call (~1–1.5 s saved under `iad1`, now roughly 0.2–0.4 s at ~30–35 ms per call);
running each page's independent queries in parallel (now roughly 0.1–0.2 s); loading skeletons.

**Blocked on:** nothing.
**Re-verify when:** anything moves the functions or the database (a second region, a Supabase
region change, a plan change), or before quoting any pre-09:44:55Z production timing as current —
re-measure it instead.
**Lives in:** `vercel.json`; commit `3c86f80`; commit `38fe153` (the 2.4 s figure); item 118 above
(the deploy-status window); item 117 above (the `18dec06` change that confounds `/groups/[id]` and
`/my-work`).

---

### 119. A date picker that produced nothing — `groups.schedule_pattern` labelled, made editable, and given the option to create the first workshop

2026-10-12, built and verified live. Mihai added a group, gave it a date and a time, and expected a
first workshop. Nothing appeared.

**The field: `groups.schedule_pattern text null`, no column comment, referenced by ZERO functions.**
Nothing parsed it, nothing generated from it. `addSession` already said so in a comment that
predates the question: *"Not defaulted from `groups.schedule_pattern` — free text, no enforced
grammar, nothing here parses it."*

**And it was not only a recurring pattern — it held two different kinds of value**, decided by the
format, with the form choosing which:

| `delivery_format` | What the form showed | What was stored |
|---|---|---|
| `scoli_private_recurente` | day-of-week select + time | `"Tuesday 16:00"` |
| **the other nine** | **a native `<input type="date">` + time, UNLABELLED** | `"2026-09-30 14:00"` |

**The misreading is still in the data, and is the best evidence of the defect:** the group created
2026-09-25 holds `schedule_pattern = '2026-09-26 15:52'` and **zero workshops**, then and now.
Picking a date out of a date picker and expecting a dated thing to exist is the only reasonable
reading of that control; the field name that contradicts it appeared nowhere in the UI.

**Built, in the order the problem has:**

1. **Both branches labelled**, with one line saying what they do. Recurring: *"The day and time this
   club runs each week. It describes the rhythm only — it does not create workshops."* / *"Descrie
   doar ritmul — nu creează ateliere."*
2. **The date picker STAYS for the nine one-off formats**, and now creates something. Replacing it
   with a text pattern field was the alternative and is wrong: those nine are one-off workshops, the
   date is a fact rather than a rhythm, and a date field that produced nothing was the bug — not the
   date field itself.
3. **An opt-in checkbox**, *"Also create the first workshop on this date"* — rendered only for the
   nine, defaulted **on** there (the user has just picked a date), **not rendered at all** for
   recurring. Never silent in either direction, and the form says afterwards which happened.
4. **ONE workshop, never a series.** A club runs ~30 a year; generating those needs term dates, a
   holiday calendar and an end date, none of which exist here. `addGroup` parses the pattern and
   requires an ISO date, so `"Tuesday 16:00"` creates nothing and says so rather than inventing "the
   next Tuesday" — which would be a guess about when term starts. A failed workshop insert never
   discards the group: a group without its first workshop is recoverable by hand, a lost group is not.
5. **The new workshop is deliberately incomplete.** `duration_minutes` and `location_tier` stay null,
   because location depends on which trainer is assigned and nobody is assigned at scheduling time.
   Their absence surfaces in item 121 below, not here.
6. **`schedule_pattern` is editable for the first time.** The column has had an `UPDATE` grant since
   the table was created and simply had no control after creation — a mistyped schedule could only be
   corrected with direct SQL. Kept as **free text** in the edit form on purpose: the live values are
   in two different shapes, and a widget that could not represent one of them would silently destroy
   it on the next save.
7. **The group info panel says what the field is where it is read**, not only where it is typed.

**The four existing groups are untouched, and not backfilled.** Two hold a weekday pattern
(`Tuesday 16:00`, `Monday 16:00` — Lycée Français, correct as they are) and two hold a date
(`2026-09-30 14:00`, which has 3 workshops created separately, and `2026-09-26 15:52`, which has
none). **Mihai's September group is his to decide about** — creating a workshop under it now would
be this change guessing at an intent from three weeks ago.

**Verified live** (`scripts/verify_schedule_rename_precheck_test_org_b.ts`): the labels and the
checkbox ship in both languages, an ISO date parses to a workshop date, a weekday pattern parses to
nothing, and the info panel carries its hint. The form's own strings are asserted **by shipment, not
by rendering** — the create form sits behind "+ New group" and is in no server-rendered fetch, which
the script's first run got wrong and reported as four failures of the build.

**Lives in:** `app/(app)/groups/groups-client.tsx` (the labelled control and the checkbox);
`app/(app)/groups/actions.ts` (`addGroup`'s date parse, `updateGroup`'s new field);
`app/(app)/groups/[id]/group-info-section.tsx` (the read hint and the edit field);
`app/(app)/groups/i18n.ts`; item 121 below (where the new workshop's missing inputs surface);
item 52 below (the one-off-vs-recurring modelling question this sits on top of).

---

### 120. The interface says workshop / atelier — and a blind substitution produced eleven Romanian agreement errors

2026-10-12. Renamed user-facing only, RO **atelier**, EN **workshop**.

**The codebase had already half-answered it, inconsistently**, which is why no decision about "which
language Mihai meant" was needed: both languages already leaned the same way.

| | Before | |
|---|---|---|
| RO `atelier` | 6 strings | my-work ×2, contracts ×1, groups ×3 |
| RO `sesiune` | **1 string** | — and it also said *atelier*, for the same thing, in the same sentence |
| RO `ședință` | 2 strings | one of them quoting a contract |
| EN `workshop` | 6 strings | one of them in that same mixed sentence |

Both mixed-vocabulary strings are fixed. Anca's responsibilities document uses *atelier* throughout,
which is the tiebreaker it never needed.

**Scope: 47 dictionary lines across 4 files, plus 8 hardcoded strings in 2.** Three deliberate
exceptions:

1. **Dict KEYS untouched** (`new_session_button`, `sessions_heading`, 14 in all) — invisible to
   users, and renaming them touches every call site plus the operator guide's manifest for no
   user-visible gain.
2. **The billing-rule example keeps `ședință`**, because live contracts say
   `105 lei/copil/ședință` and `770 RON + TVA/ grupă/ ședință`. The hint has to agree with the paper,
   not with the menu. Written into the operator guide as its own line so the next sweep does not
   "fix" it.
3. **`public.sessions` and everything keyed on it untouched**, with one comment in
   `groups/actions.ts` where someone would wonder why the same function says *workshop* to users and
   *sessions* to the database: its own RLS policies, four `SECURITY DEFINER` routing functions,
   `row_history` rows already written under that `table_name`, `app.calculate_session_pay` and its
   five resolvers, and 13 suite files all name it — and history rows would then disagree with the
   table they describe.

**ELEVEN agreement errors the substitution created, and the general lesson.** `atelier` is **neuter**
in Romanian — masculine agreement in the singular, feminine in the plural — where `ședință` and
`sesiune` are feminine throughout. So every article and adjective left behind disagreed the moment
the noun changed: *"nicio atelier alocată"*, *"durata atelierei"*, *"această atelier"*, *"acestei
ateliere"*, *"o atelier neconfirmată"*, *"Creează ateliera"*. All eleven fixed, and the verification
script asserts the broken forms **do not ship**.

**A find-and-replace across two languages is safe in exactly one of them.** English nouns carry no
gender, so the EN side needed no review; the RO side needed every changed line read. Nothing in this
project's tooling catches this — `check_operator_guide.ts` compares the guide against the
dictionaries and passed 38/38 both before and after, because it checks that claims MATCH, not that
they are grammatical.

**2026-10-13, two more agreement errors found in the same rename — and both say something the
eleven above did not.**

`new_session_button` and `new_session_title` shipped as **"Atelier nouă"**, feminine, for a day.
The first is the primary action on every group page, so it was on screen every time anyone opened a
group. Fixed to "Atelier nou".

**First: the verification written for this rename missed the error the rename introduced.** The
script asserts six anticipated broken forms do not ship — *"nicio atelier"*, *"Nicio atelier"*,
*"atelierei"*, *"acestei ateliere"*, *"o atelier neconfirmată"*, *"Creează ateliera"* — and it was
written in **the same commit** (`ba5bac9`) that introduced a seventh. It could not have contained
it. **A denylist catches only what occurred to its author**, so adding "Atelier nouă" to it closes
one case and does not close the pattern. The form was added anyway, because one closed case is worth
having; it is just not a guard.

**Second, and the more general one: neither error was a mis-converted string.** The eleven above
were genuine conversion residue — a feminine article left standing when the noun under it changed.
These two were **written from scratch in the rename commit**, as new keys, with the feminine form
chosen fresh. Nobody substituted anything; the old gender was simply still in the writer's head
while typing new text. **So "review every line the substitution touched" would not have caught
either of them** — they are not lines the substitution touched. The risk is not conversion residue,
it is that **a vocabulary change leaves the old gender active in whoever is writing the next string**,
and it recurs at every vocabulary change, not just this one.

**Checked at the same time:** all 47 RO strings mentioning `atelier`/`ateliere`, read and swept
mechanically for the compound forms (`niciun/nicio`, `acest/această`, `acestui/acestei`,
`alocat/alocată`, `confirmat/confirmată`, `nou/nouă`). The other 45 are correct. Three unrelated
agreement errors surfaced in the same sweep and were fixed with them — `my-work` page_subtitle's
*"gradul tale"* (wrong since `33126a3`, i.e. **before** this rename, so not residue of it),
and `payment-config`'s *"cine o introduce"* (the referent `nivelul` is masculine) and
*"120 de minute are"* (plural subject).

**Lives in:** `app/(app)/{groups,my-work,payroll,payment-config}/i18n.ts`;
`app/(app)/groups/actions.ts` and `session-write-errors.ts` (the hardcoded strings and the
table-name comment); `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md` (the `ședință`
exception); item 14 below (the i18n coverage gap these two EN-only files still sit in).

---

### 121. `/payroll` now says which workshops cannot be priced — and said "Unknown has no grade" until its own verification caught it

2026-10-12. Not required fields at creation: a check before the month closes, beside the
unconfirmed-slot warning that already existed.

**The five inputs, read from `app.calculate_session_pay` rather than from intuition.** Every resolver
**raises** — none returns null — but the calculation guards the first three itself, with its own
named messages, before any resolver is reached:

| Input | Read from | On missing |
|---|---|---|
| `duration_minutes` | the workshop | `raise` *"has no duration_minutes recorded"* |
| `location_tier` | the workshop | `raise` *"has no location_tier recorded"* |
| `language_group` | **the group** | `raise` *"group % has no language_group recorded"* |
| a trainer in the slot | the workshop | `raise` *"p_trainer_id must not be null"* |
| **a grade effective on that date** | `trainer_grade_assignments` | `raise` *"no trainer_grade_assignments row for trainer % on or before %"* |

**Why not required at creation.** Requiring duration and location would invert the real order:
`location_tier` depends on which trainer is assigned (the form pre-fills it from their home city),
allocation happens *after* scheduling in the responsibilities document's own sequence, and
`trainers.substitute` exists as a capability because the slot changes after the date is fixed.
Pencilling in a date before anyone is assigned is how scheduling starts here.

**What the screen says when nothing is missing: nothing.** The block renders only when at least one
workshop in the displayed month cannot be priced. Deliberate, and a deliberate difference from the
unconfirmed-slot block directly above it, which *does* show a positive line
(`summary_all_confirmed`): confirmation is a thing the closer is actively waiting for, while an
unpriceable workshop is an exception, and a line that is always there becomes a line nobody reads.

**The grade message names the person, not the column** — *"Luiza Mirt has no grade effective on this
date"*, not *"trainer_grade_assignments is missing a row"*. Luiza is the live instance, with no grade
by Anca's own conditional answer (*"grade 3 if she returns"*, item 95 above), and the actionable half
is the person.

**It said "Unknown has no grade effective on this date" until the verification script rendered it.**
A workshop slot is a plain FK to `users` with no role requirement, and `users`' SELECT policy admits
**trainer** names to finance/ops viewers (`202609160001`) — so anyone allocated who is not a trainer
resolves to no name at all. The sentence that produced names nobody and is **strictly less
actionable than naming the column it was written to avoid naming.** Fixed: the name when it is
readable, and when it is not, a sentence saying what is known and why the name is missing. Never
"Unknown". That is item 66 above's rule — a UUID must never render as a name — applied to a message
rather than to a header, and it was caught by rendering the page rather than by reasoning about it.

**One guard worth more than the check it protects.** `trainer_grade_assignments`' SELECT policy is
*narrower* than `/payroll`'s own gate: the table admits `finance.operations.*` /
`finance.reporting.*` / own row / the platform-owner flag, while the page admits
`finance.operations.*` **or `org.settings.manage`**. For a viewer holding only the latter the grade
read comes back empty — so **zero readable grade rows means the question goes unasked, not answered
no.** Without that, the screen would accuse every trainer of having no grade, on data the viewer
simply cannot see. Same shape as item 65 above (a join that outruns the joined table's RLS), caught
before shipping rather than after.

**Verified live, all five cases, in Test Org B.** Two faults in the verification script's own
fixtures are recorded in it: it assumed Test Org B had no grades (it has six, B1–B6 from
2026-09-02), and its fixture's `source` value violated a CHECK constrained to `computed|manual`,
came back null, turned the grade question silently off and **crashed cleanup, leaving a client and
two groups behind** — item 102 above's standing-fixture failure, reproduced by a script written to
avoid it. Cleanup now deletes by marker rather than by ids captured along the way.

**Lives in:** `app/(app)/payroll/page.tsx` (the five questions and the readability guard),
`payroll-client.tsx` (the block), `payroll/i18n.ts` (the wording);
`supabase/migrations/202609250001_create_calculate_session_pay.sql` (the five raises this mirrors);
`scripts/verify_schedule_rename_precheck_test_org_b.ts`; item 95 above (Luiza's deliberate absence
of a grade); item 65 above (the same RLS-outrunning-a-join shape); item 66 above (the never-print-an-
id rule this applies to a sentence).

---

### 122. A message written to avoid naming a column ended up naming nobody — and three more `?? "Unknown"` fallbacks reach user-facing text on the same screen

2026-10-12, found by rendering the page rather than by reading the code. Item 121 above's
pre-close check names the person who has no grade, because the person is the actionable half. Its
first live run rendered:

> **"Unknown has no grade effective on this date"**

**A sentence written specifically to avoid naming a database column instead named nobody**, which is
strictly worse: `trainer_grade_assignments is missing a row` at least tells you where to look.

**The mechanism, which generalises past this one message.** A workshop slot is a plain foreign key
to `public.users` with **no role requirement** — nothing stops an operations manager, an evaluator or
anyone else being put in one. But `users`' own SELECT policy admits **trainer** names to finance and
operations viewers (`202609160001`), not names in general. So the moment an allocated person is not a
trainer, the name lookup returns nothing and every message built around that name degrades.

**The general rule:** *user-facing text that interpolates a name needs a no-name branch, because the
name comes from a table with its own RLS and the row it describes may be about someone the viewer
cannot see.* A `?? "Unknown"` is not that branch — it satisfies the type and destroys the sentence.
Item 66 above established this for a header (a UUID must never render as a name); this is the same
rule for a sentence, and the sentence case is worse because the surrounding grammar makes the
placeholder read as a real answer.

**Fixed in item 121 above's message**: the name when readable, and otherwise a sentence that says
what IS known and why the name is missing.

**Three more on the same screen, found while fixing it, NOT fixed here.** All in
`app/(app)/payroll/page.tsx`:

| Fallback | Where it renders | How bad |
|---|---|---|
| trainer slot names (lines 197, 203) | the **unconfirmed-slot list** — the block directly above item 121's | **The worst of the three.** This is the list the closer is meant to act on, and the name is the actionable column; the row still carries client + date, so the workshop is identifiable, but "who hasn't confirmed" reads as "Unknown". |
| `closedByName` (line 186) | "closed by …" on a past period | Degraded audit line. Not actionable either way, but it asserts a fact about a person. |
| `clientName` (lines 174, 190) | both lists | **Already recorded as item 65 above**, which is where its decision lives — not a new finding. |

**Not fixed in this pass on purpose.** The first is a pre-existing defect in a block this round only
sat beside, the second is cosmetic, and both want the same decision — what a name-less row should say
— made once rather than three times in a hurry. The fix shape is known and is the one item 121 above
now uses.

**Blocked on:** nothing technical — a decision on the wording for a name-less row, then the same
two-branch treatment in three places.
**Re-verify when:** any new user-facing message interpolates a name from a `users` lookup. The test
is not "does it compile" but "render it as a viewer who cannot read that name."
**Lives in:** `app/(app)/payroll/page.tsx` (all four fallbacks), `payroll-client.tsx` (where they
render); item 121 above (the instance that was fixed); item 66 above (the same rule for a header);
item 65 above (the `clientName` case, with its own decision); `202609160001` (the policy that admits
trainer names and not names in general).

---

### 123. An absence under RLS is not evidence — the general form, after a check nearly accused every trainer on data its viewer could not see

2026-10-12. Item 121 above's pre-close check asks whether each allocated person has a pay grade
effective on the workshop's date. The obvious implementation reads
`trainer_grade_assignments`, finds no row, and reports "no grade".

**It would have been wrong for a whole class of viewer.** That table's SELECT policy admits
`finance.operations.*` / `finance.reporting.*` / the person's own row / the platform-owner flag.
`/payroll`'s own gate is **wider**: `finance.operations.*` **OR `org.settings.manage`**. A viewer
holding only the second reads **zero grade rows** — not because nobody has a grade, but because the
table will not show them any. A check that treats that silence as an answer **accuses every trainer
of having no grade, on data the viewer cannot see**, and names them while doing it (item 122 above).

**The guard, and the general form it is an instance of:**

> **Under RLS, "I read no rows" and "there are no rows" are different facts, and only one of them is
> about the world.** A check built on a filtered read must establish that it can see *something*
> before it is entitled to conclude *nothing*. Zero rows means the question goes unasked, not
> answered no.

In item 121 above that is one boolean: the grade question is only asked when at least one grade row
came back, which proves read access without needing to know the viewer's capabilities.

**Same family as item 104 above** ("the absence of a history row is not evidence about a row's
origin"), and worth stating as a family rather than two coincidences. The pattern recurs wherever a
*privileged* read is used to make a *negative* claim:

- item 104 above — `row_history` has no INSERT trigger, so a missing history row proves nothing
  about provenance. Already produced one wrong answer that got committed (item 102 above).
- item 65 above — a `clients` join outruns the viewer's own segment, so a missing client name is an
  RLS boundary and not a missing client.
- this — a missing grade row is a policy boundary before it is a fact about a trainer.

**The asymmetry that makes it a trap:** a filtered read is perfectly safe for a *positive* claim
("these rows exist"), and silently wrong for the negative one ("therefore those don't"). The code
looks identical in both cases, the types are the same, and the failure only appears for viewers the
author is not.

**Re-verify when:** any screen computes a count, a completeness check or a "nobody has X" claim from
a table whose policy is narrower than that screen's own gate. The specific comparison worth making
is exactly that one: *is this table's SELECT policy narrower than the gate on the page reading it?*
If yes, the negative claim needs a can-I-see-anything guard.
**Lives in:** `app/(app)/payroll/page.tsx` (`gradesReadable`); item 121 above (the check it
protects); item 104 above (the same family, about provenance); item 65 above (the same family, about
a join); item 102 above (the committed wrong answer item 104 records).

---

### 124. A verification script written to avoid item 102's standing-fixture problem reproduced it — and the fix that generalises is cleanup by marker, not by captured ids

2026-10-12. Item 102 above records two standing fixtures left mutated by verification runs whose
silent `finally` never fired, which is why every script since announces whether cleanup ran. Item
117 above's script does. **It still left a client and two groups behind in Test Org B.**

**The chain, because no single link was the bug:**

1. The fixture inserted a `trainer_grade_assignments` row with `source: "VERIFY 121 fixture"`.
2. `source` is CHECK-constrained to `'computed' | 'manual'`. The insert was rejected.
3. The script did not check the error, so `grade` was **null** — and `grade` was only ever read as
   `grade!.id`, a non-null assertion that compiles and lies.
4. The missing row **silently disabled the feature under test**: with zero grade rows readable, item
   123 above's guard correctly declined to ask the grade question, so the assertion failed for a
   reason unrelated to the code it was testing.
5. `cleanup()` ran, hit `grade!.id` on a null, **threw**, and every delete after that line never
   executed. The "CLEANUP: ... Test Org B is as it was found" line never printed, which is the one
   part that worked.

**The fix that generalises is not "check the insert error."** That fixes this script. The fix is in
how cleanup identifies what to remove:

> **Cleanup deletes by MARKER, not by ids captured along the way.** Every fixture carries a
> recognisable marker in a column that is already there (`notes like 'VERIFY 119-121%'`, `name like
> 'VERIFY%'`), and cleanup deletes everything bearing it. A half-built fixture set then cleans up
> exactly as well as a complete one, because cleanup never depends on a variable the build populated.

Captured ids are the fragile part: they encode an assumption that every step before them succeeded,
and they turn one failed insert into an orphaned fixture plus a crash. A marker encodes nothing.

**Applied to item 117 above's script**; item 121 above's own script was written the same way from the
start. The leftover client and two groups were removed by hand the same session, and the absence
re-verified (`0 remaining`, `0 orphan sessions`).

**Two smaller lessons from the same run, recorded because each cost a cycle:**
- **The script asserted the create form's labels by RENDERING.** That form sits behind a "+ New
  group" button and appears in no server-rendered fetch, so four assertions came back false and
  reported the build as broken. The honest claim for a control that only exists after a click is
  **shipment in the client bundle**, which is what the script now asserts — the same distinction its
  siblings already draw for RO strings.
- **The fixture assumed Test Org B had no grades.** It has six, B1 through B6, all effective
  2026-09-02. The assumption was never checked, and the right instrument turned out to need no
  fixture at all: a real account that genuinely has no grade, put in a workshop slot — which a slot
  permits, since it is a plain FK with no role requirement (item 122 above).

**Re-verify when:** writing any new `scripts/verify_*` that creates fixtures. The question to ask is
not "does cleanup run" — item 102 above already fixed that — but **"does cleanup still work if the
third insert fails?"**
**Lives in:** `scripts/verify_lesson_plan_flow_test_org_b.ts` and
`scripts/verify_schedule_rename_precheck_test_org_b.ts` (both now marker-based); item 102 above (the
original standing-fixture failure and the announce-cleanup rule); item 121 above (the feature whose
test this was); item 123 above (the guard that made the failure silent rather than loud).

---

### 125. The landing path cost nine round trips; it now costs one — halving the sign-in redirect, once a deploy outage unrelated to it was cleared

2026-10-12. The post-sign-in destination (the rule in item 114 above's sibling, `lib/landing.ts`)
resolved by looking up the caller's memberships and then calling `has_capability` once per
capability, sequentially, over the network.

**Measured before building, warm median of five, against the real deployment**
(`scripts/measure_landing_path.ts`, new — times `/auth/callback` with `redirect: "manual"`, so the
destination page's own render is excluded):

| account | before | destination | why |
|---|---|---|---|
| **trainer** | **660 ms** | `/my-work` | the only account that cannot short-circuit: `mywork.*` matches, then **all eight** "beyond own work" keys must come back false |
| owner | 295 ms | `/profile` | exits on the first beyond-key |
| ops manager | 274 ms | `/profile` | exits immediately — no `mywork.*` at all |

**Built: two functions, and the rules do not change.** Both call the existing `app.has_capability`
once per key, deliberately rather than expressing the same thing as one widened `IN` list —
`app.has_capability` is where the wildcard rule and the `is_platform_owner` OR live, and a second
query shaped like it would be a second definition of "has" that can drift from the first.

- **`app.has_any_capability(caps[], org)`** — the primitive. Fails closed on a null array, an empty
  array, a null organization and an unknown key, each asserted.
- **`app.resolve_landing_flags(mywork_cap, beyond_caps)`** — both answers across **every**
  organization the caller belongs to, which is what also removes the app's own `user_org_roles`
  lookup. **It takes no user parameter**, and that is the security property: it is `SECURITY
  DEFINER`, so a user-id argument would let any signed-in caller ask where somebody else lands and
  probe another person's capabilities one array at a time. The subject is always
  `app.current_user_id()`; with no session both answers are false and the app sends the caller to
  `/profile`, the fail-closed direction.

**The capability list stays in `lib/landing.ts` and is passed in**, rather than copied into SQL. It
belongs beside the comment that says it must grow when a nav group is added — item 114 above's
shape — and a copy in the database would be a second place to forget.

**The callback's second `getUser` is gone.** `verifyOtp` already returns the user it just
authenticated; the previous version asked the network again for an answer it was holding.

**Verified, and precisely what is NOT.**

- `db/tests/landing_flags.sql`: **13 assertions** over the three real account shapes and every
  degenerate input, **with a sabotage that grants `clients.read` to the `trainer` role** and
  confirms the trainer's "beyond" answer flips. Without it, "the trainer answers false" would pass
  identically if the function ignored its argument and hardcoded false. Suite: **184 passed, 0
  failed**.
- Through PostgREST, with real magic-link tokens, as all three accounts: trainer
  `{has_mywork: true, has_beyond: false}` → `/my-work`; owner `{true, true}` → `/profile`; ops
  manager `{false, true}` → `/profile`. One round trip each.
- **NOT verified: anything about the deployed app, and the after-measurement.**

**The deploy failed, and this entry does not pretend otherwise.** Commit `767a479` built cleanly
locally **twice**, including once from a deleted `.next`, and `check_deploy_status.ts` reported
`failure` for deployment `dpl_CvmttRcMW8cVfcAnz4iGt7PXdmsi`. The two commits immediately before it
(`8b85510`, `674b238`) both succeeded minutes earlier. The only check-run on the commit is
`Supabase Preview / skipped`, which is not a cause. **The Vercel build log cannot be read from this
session** — the CLI is not logged in and the Vercel MCP server is unauthenticated here — so every
hypothesis about why is a guess, and item 118 above records what happens when one of those gets
written down as a cause.

**The after-numbers taken while that was true were void, and are kept here only so nobody mistakes
them for the result above.** `app.wowlab.ro` was still serving the previous build, so the 588 /
237 / 212 ms observed are the OLD code path: 588 ms for the trainer sits inside the before-run's own
spread (534–967). **No improvement has been measured. The function is proven; the path through it
is not.**

**RESOLVED 2026-10-12: the deploy outage was `git_info_fail` and had nothing to do with this change
(item 126 below). After the fix, measured properly, with a control arm on the same build:**

| account | before (per-capability loop) | after (one RPC) | end to end | landing's own cost, after |
|---|---|---|---|---|
| **trainer** | 660 ms | **320 ms** | **−340 ms (−52%)** | 198 ms over a 122 ms floor |
| owner | 295 ms | **142 ms** | **−153 ms (−52%)** | 31 ms over 111 ms |
| ops manager | 274 ms | **141 ms** | **−133 ms (−49%)** | 47 ms over 94 ms |

Warm median of five per arm, and all three land where the rule says they should (`/my-work`,
`/profile`, `/profile`), which is also the three-account verification this entry was waiting on.

**The control arm is new and worth keeping.** `scripts/measure_landing_path.ts` now measures each
account twice on the SAME build: once normally, and once with an explicit `next=/profile`, which
short-circuits the callback before it resolves a landing path at all. That holds everything constant
— the build, `verifyOtp`, the platform's mood that minute — so "landing costs 198 ms" is a
subtraction rather than a comparison against a different deployment on a different afternoon. The
earlier before-numbers have no such control, so the end-to-end column is the weaker of the two
claims and is labelled as such.

**What the remaining 198 ms is, because it is not round trips any more.** The trainer is still the
expensive case for the same reason as before: theirs is the one account where all nine capability
checks must actually run, since `mywork.*` matches and then every one of the eight beyond-keys has to
come back false. Those nine calls now happen inside one round trip instead of across nine, which is
the whole saving — but they are still nine queries. Making them cheaper would mean not calling
`app.has_capability` nine times, i.e. re-implementing the authorization rule in a single query, which
is exactly what this migration refused to do. **198 ms of in-database work is the deliberate price of
one definition of "has".**

**It failed twice, deterministically, and in TEN SECONDS — which ruled out the whole class of cause
I would otherwise have guessed at.** Measured from GitHub's own timestamps:

| commit | push → verdict | outcome |
|---|---|---|
| `674b238` | **63 s** | success — a real build of this app takes about a minute |
| `767a479` | **10 s** | failure |
| `d6883f3` | **~10 s** | failure (a docs-only commit, so not this change's code at all) |

A build that compiles this app takes ~60 seconds; one that fails in 10 has not reached TypeScript or
ESLint. **So the failure is not in the code being compiled** — which is independently corroborated
by `d6883f3` failing identically while touching nothing but `docs/OPEN_ITEMS.md`, and by two clean
local builds including one from a deleted `.next`. Something rejects the deployment before or very
early in the build.

**What it is remains unnamed on purpose.** A quota, a plan limit, a project setting and a billing
state would all look exactly like this from here, and today saw an unusually high number of
deployments — which is circumstantial and nothing more. Item 118 above is the entry about writing
down a cause that fit the evidence in front of me and then watching it die twice; the 10-second
figure is evidence, "therefore it is the daily deployment cap" would be a guess.

**Blocked on:** nothing — deployed, measured and verified 2026-10-12 after item 126 below's fix.
**Lives in:** `supabase/migrations/202610120008_add_has_any_capability_and_landing_flags.sql` and its
rollback (applied); `lib/landing.ts`; `app/auth/callback/route.ts`; `app/page.tsx`;
`db/tests/landing_flags.sql`; `scripts/measure_landing_path.ts`; item 114 above (the stale-list shape
the capability list is commented against); item 118 above (the deploy-reporting entry, and the
warning against naming a cause you cannot see).

---

### 126. The Git integration broke in three distinct states — RESOLVED 2026-10-13 by disconnecting the repository and re-linking it from zero, which is NOT what the Reconnect button does

**RESOLVED 2026-10-13 07:50:21Z.** Vercel support was never needed. The repair, the three-state
signature and the one piece of evidence that pointed at the repair before it was tried are at the
end of this entry, under **THE REPAIR**; everything between here and there is the diagnostic record
written while it was still broken, kept because the next occurrence will present identically and the
dead ends are most of the value. The sentences below that say "not repaired" and "next step is
Vercel support" were true when written and are left standing rather than edited away.


2026-10-12, from 11:49Z and **still recurring**. Production deployments fail with
`errorCode: 'git_info_fail'` and the cause is neither the code, nor a quota, nor the `fra1` region
move. **Vercel's GitHub App returns 403 when fetching the repository**, which the project's Git
settings showed as `GitHub fetch error - status: 403` on the connected repository.

**Reconnect was pressed, the 403 disappeared from the settings page, and the very next deployment
failed the same way.** Recorded as intermittent rather than resolved, because the first version of
this entry said "Pressing Reconnect fixed it" on the evidence of one successful deployment, and the
one after it falsified that within six minutes:

| time | commit | outcome | duration |
|---|---|---|---|
| 11:49:33Z | `674b238` | READY | 56.5 s |
| 11:59:54Z | `767a479` | **ERROR `git_info_fail`** | 8.3 s |
| 12:03:54Z | `d6883f3` | **ERROR `git_info_fail`** | 8.8 s (docs-only) |
| 12:05:03Z | `6e0fd00` | **ERROR `git_info_fail`** | 6.6 s |
| — | — | **Reconnect pressed, 403 cleared from the settings page** | — |
| 13:00:31Z | `949e6ef` | READY | 49.9 s |
| 13:06:55Z | `f055448` | **ERROR `git_info_fail`** | 4.4 s (docs-only) |
| 13:08:43Z | `728391c` | READY | 48.4 s (docs-only — so it was already intermittent, success/fail/success, not monotonic; I missed this one at first by checking the failed sha and not the next) |

**So Reconnect is a retry, not a repair.** It restores the link long enough for one deployment and
the failure returns.

**Then the GitHub App was uninstalled from the organization, reinstalled, and the project
reconnected — and the symptom CHANGED rather than cleared.** Two consecutive pushes after the
reinstall produced **no deployment at all**:

| time | commit | what Vercel created |
|---|---|---|
| ~13:20Z | `97e10b8` | **nothing** — still no deployment after 15 minutes of polling |
| ~13:35Z | `ebac07b` | **nothing** — no deployment after 5 minutes |

Both are on `origin/main` (confirmed with `git ls-remote`), and the project's link record is
structurally intact — `type: github`, `Wow-Lab-The-WHYology-Insitute / App-Wow-Lab`,
`repoId: 1271387260`, `productionBranch: main`, `createdAt` ≈ 2026-08-10, matching the
`Connected Aug 10` the settings page shows.

**THREE distinct failure states have now been observed on this project in one afternoon**, and
telling them apart is the first thing to do on any future occurrence:

| state | deployment created? | duration | build log | `errorCode` |
|---|---|---|---|---|
| **healthy** | yes | 43–61 s | normal | — |
| **`git_info_fail`** | yes | 4–9 s | **empty**, `builds: []` | `git_info_fail` |
| **webhook dead** (after the reinstall) | **no** | — | — | — |

The third is the worst to diagnose, because nothing anywhere reports a failure: `git push` succeeds,
GitHub holds the commit, no deployment record exists to carry an error, and the only signal is an
absence. It is also exactly the condition item 108 above describes and `check_deploy_status.ts`
exists for — but see the caveat below about that script today.

**Verdict, plainly: not repaired.** Reconnect bought one deployment; the uninstall/reinstall bought
none and traded a loud failure for a silent one. **The next step is Vercel support, not another
thing to press.** Intermittent `git_info_fail` with intact GitHub-side permissions, followed by
webhooks that create no deployment, is visible in their logs and not in ours.

**What to hand them, so the ticket does not need a second round:**
- project `prj_0qQGJwev5UT936X2KFnl9fVJWwNF`, team `team_jc5JPRPiybFWLSHA05B3BAKi`, repo
  `Wow-Lab-The-WHYology-Insitute/App-Wow-Lab`, `repoId 1271387260`
- the three `git_info_fail` deployments: `dpl_CvmttRcMW8cVfcAnz4iGt7PXdmsi`,
  `dpl_4wxyweE73kJVCfbRV2EoTPRWXzG3`, `dpl_F239xTLVW4hmJkF5dbp1utjT5QGo`
- the two commits that produced no deployment at all: `97e10b8`, `ebac07b`
- the fact that the GitHub App's own permissions were all-repositories, read and write, throughout

**`check_deploy_status.ts` could not be used for this verification, for a reason worth knowing.** It
queries GitHub's commit-status API **unauthenticated**, which is rate-limited to 60 requests an hour
— and this session's own polling loops exhausted it, after which the script fails with
`GitHub API returned HTTP 403` for every commit. The Vercel API (with a token in `.env.local`) is
the better instrument regardless: it reports `errorCode` and build duration directly, and it can
distinguish "no deployment exists" from "no status yet", which is precisely the ambiguity item 118
above is about.

**One consequence worth carrying into every later entry: "verified live" now needs a deployment
check in front of it.** Item 125 above's measurement is valid precisely because it ran against
`949e6ef`, which did deploy and does contain the change — checked before measuring, not assumed. The
docs commit that failed afterwards changes no behaviour, so production is behind on this register's
own text and nothing else.

**THE SIGNATURE, which is the whole value of this entry.** Recognise it from two numbers and stop
investigating anything else:

> **An empty build log plus a sub-10-second failure means the build never started, so the cause is
> the GitHub link and not anything in the repository.**

Measured, both sides of the boundary:

| | duration | `errorCode` | build log |
|---|---|---|---|
| eleven deployments, 08:56Z–11:49Z | **43–61 s** | — | normal |
| three deployments, 11:59Z–12:05Z | **6–9 s** | **`git_info_fail`** | **`[ ]` — zero events, `builds: []`** |
| one after Reconnect, 13:00Z | **49.9 s** | — | normal |
| the next one, 13:06Z | **4.4 s** | **`git_info_fail`** | **`[ ]` again** |

A build that compiles this app costs about a minute. One that ends in under ten seconds has not
reached `npm ci`, let alone TypeScript or ESLint — and the API confirms it rather than implying it:
the events endpoint returns an empty array, and `builds` is empty, because there was nothing to
build. The deployment record carries `errorCode: 'git_info_fail'` and **no** `errorMessage`,
`errorStep` or `errorLink`; that code is the entirety of what Vercel recorded.

**The decisive control was a docs-only commit.** `d6883f3` changed nothing but
`docs/OPEN_ITEMS.md` and failed identically to the commit before it. That rules the repository
contents out completely, and it is the cheapest possible test — if a commit that touches only a
markdown file fails the same way, stop reading diffs.

**The GitHub App's own permissions were intact the entire time — all repositories, read and write
(checked by Mihai on GitHub's side).** This is the most useful negative in the entry: **checking
GitHub first costs time and settles nothing.** The 403 was Vercel's side of the link, not a
permission GitHub had withdrawn, so the installation page looks perfectly healthy while every
deployment fails. Go to the Vercel project's Git settings and look for the fetch error there.

**Why the webhook still fired, which is what makes this confusing.** A deployment was created for
every push, with the correct `ref`, `sha` and commit metadata — so from GitHub's side and from
`git push`'s side everything looked normal, and the commit status even appeared (as `failure`). The
push notification and the repository read are different paths; the first kept working while the
second returned 403. **"The deployment exists" is therefore not evidence that Vercel can read the
repo.**

**Second occurrence of this class in this project, and the first time Reconnect has not held.** The
Vercel↔GitHub integration desynced once before and was repaired by disconnect/reconnect, recorded in
the session memory for this repo rather than here. That precedent is what made "Reconnect fixed it"
so easy to believe on one data point.

**What this cost, and the three dead hypotheses, recorded because each one looked right at the
time:** a compile error (ruled out by two clean local builds, one from a deleted `.next`, and then
conclusively by the docs-only commit); a deployment quota (fits "deterministic failures late in a
busy day" and nothing else — a cap does not produce a git-specific code); and the `fra1` region
change in `3c86f80` (ruled out by the eight deployments that succeeded after it). Item 118 above is
this session's record of writing one such hypothesis down as a cause and watching it die; this entry
is what it looks like when the actual answer finally arrives from a log.

**Production is NOT stranded, which is the one piece of good news.** The last successful deployment,
`728391c` at 13:08:43Z, is an ancestor of `main` and carries every code change — everything pushed
since is documentation. So the app is current; only this register's own text is behind.

---

**THE REPAIR, and the three states to tell apart first.**

**THE THREE STATES. Recognise which one you are in before doing anything, because two of them look
like "the deploy is broken" and they want opposite actions.**

| | state 1 — `git_info_fail` | state 2 — webhook dead | state 3 — healthy |
|---|---|---|---|
| deployment created? | **yes** | **no** | yes |
| appears in the deployments list? | yes, **red** | **not at all** | yes |
| duration | 4–10 s | — | 36–61 s |
| build log | **empty**, `builds: []` | — | normal |
| `errorCode` | **`git_info_fail`** | — | — |
| what it means | Vercel got the webhook but **could not read the repo** | the webhook **stopped firing** | — |

**State 1 was intermittent — roughly one deployment in four got through.** That is what made it so
easy to misread: a success after a failure looks like a repair and is not.

**State 2 is not a continuation of state 1, it is a different failure**, and the distinction is the
one that cost the most time. In state 1 there is a red row in the deployments list carrying an error
code. In state 2 there is **nothing to look at** — `git push` succeeds, GitHub holds the commit, and
no deployment record exists to carry any error. It lasted **18h41m**: the last deployment created
was `728391c` at 13:08:43Z on 2026-10-12, the next was `2b34c5a` at 07:49:43Z on 2026-10-13. Two
pushes fell inside that window and produced nothing at all — `33a6b6b` (committed 16:03:04Z, a
commit made specifically to test the webhook) and `3369706` (the motion/UI pass, pushed the
following morning).

**State 3, after the repair:** `2b34c5a` → `dpl_376hXKcSef6zpVxW71KxJdqsurpz`, created 07:49:43Z,
**four seconds after the commit**, building at 07:49:45Z, READY at 07:50:21Z. **36 s of build.** A
normal build for this app, with a normal log.

**What actually repaired it, and the distinction that cost ~19 hours.**

**Disconnect the repository explicitly, then link it again from zero — Settings → Git.**

**NOT the Reconnect button.** Reconnect only re-confirms the link record that already exists. It was
pressed several times across 2026-10-12 and the GitHub App was uninstalled from the organization and
reinstalled, and *none of it rewrote the link object*. After the disconnect and fresh link, the
settings page read **"Connected just now"** instead of "Connected Aug 10".

**The evidence that identified this before it was tried**, which is the transferable part:

```
link.type              github
link.repo              Wow-Lab-The-WHYology-Insitute/App-Wow-Lab
link.productionBranch  main
link.createdAt         2026-08-10 12:07:33
link.updatedAt         2026-08-10 12:07:33   ← identical
```

`link.updatedAt` was **byte-identical to `link.createdAt`**, three months old, after an afternoon of
pressing Reconnect and a full App uninstall/reinstall. That is a direct statement from Vercel's own
API that **every intervention tried so far had left the link record untouched** — so the thing to do
was not to press the same button again but to destroy the record and make a new one. Read from:

```
curl -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/<projectId>?teamId=<teamId>" | jq .link
```

**On any future recurrence, read `link.updatedAt` first.** If it has not moved since the last thing
you pressed, that thing did nothing.

**Re-linking does NOT itself trigger a build, and this nearly hid the repair.** `3369706` was
already on `main` when the repository was re-linked, so there was no new push for the restored
webhook to fire on, and the project sat there looking exactly as dead as before. **An empty commit
is required to find out whether the repair worked:**
`git commit --allow-empty -m "trigger" && git push`. That is also why `949e6ef` appears earlier in
this entry — the same technique, used on the repair that did not hold.

**Blocked on:** nothing — resolved.
**Re-verify when:** any deployment fails in under ~15 seconds, **or any push produces no deployment
at all**. Those are states 1 and 2 above and they need different next moves. Read the deployment
record's `errorCode` and the length of its events array for state 1; for state 2 there is no record
to read, so go straight to `link.updatedAt` on the project:
`curl -H "Authorization: Bearer $VERCEL_TOKEN" "https://api.vercel.com/v13/deployments/<dpl>?teamId=<team>"`
and
`curl -H "Authorization: Bearer $VERCEL_TOKEN" "https://api.vercel.com/v9/projects/<proj>?teamId=<team>"`.
The project and team ids live in `.vercel/project.json`.
**Lives in:** `.vercel/project.json` (project `prj_0qQGJwev5UT936X2KFnl9fVJWwNF`, team
`team_jc5JPRPiybFWLSHA05B3BAKi`); commit `2b34c5a` and deployment `dpl_376hXKcSef6zpVxW71KxJdqsurpz`
(the empty commit and the 36 s build that proved the repair); commit `949e6ef` (the earlier empty
commit, which proved a repair that did not hold — the reason one green deployment is not evidence);
item 125 above (the work this blocked, and its measurement once unblocked); item 118 above (the
deploy-reporting entry, which this occurrence adds a fourth uncovered state to);
`scripts/check_deploy_status.ts` (which could not be used at all today — see item 118 above).

---

### 127. `supplier_contracts` — SAD step 4 built, with §3.3's price assumption overruled by §3.3's own source

2026-10-12. Item 105 above recorded this as "blocked on the rate-vs-value decision, not on writing
the migration". The decision is taken, and both halves are applied and verified live:
`202610120009` (schema) and `202610120010` (the 30 rows).

**THE DEVIATION FROM §3.3, which is the substance of the entry.** §3.3 specifies
`contract_value numeric` and **no** `rate`/`rate_unit`, reasoning *"un contract de servicii are
valoare, nu tarif orar"*. Measured against the register the spec was written for, that does not
hold: most priced rows carry a **rate** (`80 RON/ORA`, `400 euro/luna`, `1000 ron/trimestru`,
`14.08 Euro/Ora`, `10099.87 ron/curs`, `12 Eur/luna`, `80 EUR/ORA`, `75 eur/ora`), and **two cannot
be structured at all** — ASISMART carries `80 RON/ORA, 90 RON/ORA`, two rates with no stated rule
for which applies when, and Raluca Margean carries three word-count tiers in one cell as a bulleted
list. `180 EURO +TVA` adds a tax qualifier and Margean's tiers are stated `net`; a numeric parse
loses the +TVA, the net, the tiering and the unit, which are the parts that decide what gets paid.

So **price is free text in one column (`price_text`), verbatim**, with
`contracts.billing_rule` as the precedent — it holds exactly this shape for client contracts
(`105 lei/copil/ședință`, `770 RON + TVA/ grupă/ ședință`) and is read by people, parsed by nothing.

**`contract_value` is kept for the TEN rows with a clean bare number — not eleven.** United Media's
`1928 EUR` is excluded on purpose: none of the ten carries a currency, so they are implicitly RON,
and coercing a euro figure into a unitless column leaves nothing able to tell them apart. It stays
in `price_text`, where the currency survives.

**`is_open_ended` beside a nullable `period_end`, because the register states two facts a null
collapses** — five rows say `nedeterminat` (open-ended by agreement), three say `N/A` (not
recorded). **A fourth shape turned up that the brief did not list:** CENTRUL MEDICAL UNIREA says
`1 AN`, a duration in words. It imports as unknown with the words preserved in `notes`, because
deriving 2024-09-28 from prose is inventing a date. Three more rows are blank. So: 5 open-ended,
7 end-dateless for three different reasons, 18 real dates.

**`amends_contract_id` — FIVE chains resolve, not the two expected:**

| amendment | chains to | effect |
|---|---|---|
| CERISEO `ANEXA 2` | CERISEO `152` | expiry 2026-07-02 → 2027-09-17 |
| FLEXIBLE `ACT ADITIONAL 1/ 5881…` | FLEXIBLE `5881` | the text names its own parent |
| ROMAN `2388729/05.01.2026` | ROMAN `2388729` | **the amendment sits above its base in the file** |
| RALUCA `Act aditional 1` | RALUCA `83` | → 2026-06-30 |
| RALUCA `Act aditional 2` | `Act aditional 1` | → **2026-12-31** |

**Four amendment-shaped rows name a base contract that was never entered** (FLEXIBLE ×2, ORANGE,
ROMAN/Brandine) and keep the link null rather than pointing at a guess; the reference survives in
`exit_number`. **And Roman V. Andra is base + ONE amendment, not three rows like Margean** — his
third row is under a different legal entity whose base contract is absent.

**Validity-in-months is not imported.** The register's formula errors (`#VALUE!`) on 8 rows and
silently reads `0` on 5 more, and the silent zeros are the worse half: a 0 looks like an answer. It
is derivable from the two dates whenever both exist.

**RLS: `finance.reporting.*` and the platform owner. NOT `finance.operations.*`** — §5 and §7 are
explicit that Laura does not see supplier contracts at all, so not their values either.

**NO own-row branch from `suppliers.user_id`, argued rather than skipped** (the symmetry with
`trainer_contracts` makes its absence look like an oversight, so the reasons live in the policy's
own comment): Anca closed supplier-contract access 2026-10-12 (item 110 above); it would be the
second instance of item 107 above's measured cross-org leak and here the leaked row carries the
masked `contract_value`, which §5 itself flags as needing an explicit decision; §5's trainer
argument does not transfer, since a supplier holds their own countersigned copy and `drive_ref`
points at it; and 5 of 22 suppliers have a `user_id` at all, none of whom has asked. If ever wanted,
it ships with `and app.belongs_to_org(...)` on that branch from the first line.

**Verified live: 30 rows, 22/5/3 by entity, 5 chains, Margean's expiry at 2026-12-31, 5 open-ended,
10 values, 3 signed-with-no-date.** 25 suite assertions including a sabotage that adds
`finance.operations.*` to the policy and flips Laura's "reads nothing" — plus two controls proving
the fixture account really holds `finance.operations.*` and really lacks `finance.reporting.*`,
without which "sees zero" could be a mis-specified fixture rather than a working boundary.

**Still blocked, unchanged:** `trainer_contracts` and its 9 rows. `initial_grade_level` is NOT NULL
and the register carries no grade for anyone (item 105 above).

**RE-ASSESSED 2026-10-20 — the blocker is two-thirds gone, and the remaining third is a date, not a
grade.** `initial_grade_level` records *the grade at signing* (SAD §12: a plain constrained 1-6
value, deliberately not an FK to a versioned grid row). The register still carries no grade — but the
real timesheet now supplies the grade on any date, so the grade at signing is **derivable** rather
than missing. Timelines built from workshop rows only (grade-7 lesson-plan rows excluded):

| trainer | grade timeline in the timesheet |
|---|---|
| Cătălina Trușan | grade 6 @ 135, **unchanged** 2024-08-07 .. 2026-09-30 (328 rows) |
| Raluca Popa | grade 1 @ 100, **unchanged** 2026-03-09 .. 2026-09-08 (20 rows) |
| Teodora Merișan | grade 1 @ 100 (2025-04-24 .. 2026-01-29), grade 2 @ 107 (2026-02-03 .. 2026-04-29), grade 3 @ 114 (2026-05-05 .. 2026-09-23) |

**So six of the nine contracts have an unambiguous `initial_grade_level` whatever their signing
date** — Cătălina's three are 6 and Raluca Popa's three are 1, because neither grade ever moved in
the covered period. Only **Teodora's three** depend on when each was signed, and her transitions are
dated to the day, so each resolves the moment the register's `signed_date` is read.

**What is genuinely still missing** is therefore not a grade but the nine signing dates, which live
in the source register (`Tabel contracte furnizori Wow Lab.xlsx`) and not in this database. That is a
read, not a decision — and it is the same read the import needs anyway.

**And this is why item 147 below spent a week unresolved.** The gross-versus-raise question had no
artefact in this database capable of settling it, because **the one table that records what a trainer
agreed to was never built.** `supplier_contracts` answered it for Anka in one line
(`price_text = '80 RON/ORA, 90 RON/ORA'`); for the three trainer PFAs there was nothing to read.
Item 147's rule — *a rate enters the grid when a signed contract states it* — is unenforceable until
this table exists.
**Lives in:** `supabase/migrations/202610120009`, `202610120010` and both rollbacks;
`scripts/generate_supplier_contract_import.py`; `db/tests/supplier_contracts.sql`;
`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §3.3 (deviated from), §4, §5, §7; item 105 above
(the blocker this clears, and the five frozen `service_type` values still open); item 107 above (the
cross-org branch not replicated); item 110 above (Anca closing supplier-contract access).

---

### 128. Admin rates built — and the uplift is 11%, not the 11.1% this project has been writing down

2026-10-12. `202610120011` (two tables and a resolver) and `202610120012` (the 12 rates), applied
and verified. Closes the figures half of item 111 above.

**THE ARITHMETIC FINDING, because it corrects several places at once.** Asked to set a tolerance on
a CHECK that verifies the uplift, the obvious answer was "wide enough for both rows". Measured
instead, in exact decimal:

| net | ×1.11 (11%) | ×1.111 (11.1%) | stored |
|---|---|---|---|
| 50 | **55.50 — exact** | 55.550 | 55.50 |
| 72 | **79.92 — exact** | 79.992 | 79.92 |
| 100 | **111.00 — exact** | 111.100 | 111 (item 95 above's trainer grade 1) |

**Three independent rate sets land on ×1.11 exactly and none lands on ×1.111.** So the uplift is
**11%**, the two rows do **not** imply different rounding, and **the tolerance is zero** — a slack
allowance would only stop the constraint catching what it exists for.

**This project has been calling it 11.1% in writing since August** — and tracing exactly where is
the useful part, because **item 95 above never said it.** Item 95 quotes only Anca's own words,
*"in contractul cu trainerii PFA sau SRL vom avea direct 111 lei/ora tarif de baza junior"* — a
figure that *supports* 11% and states no percentage at all. The four places that do state it:

| where | what it says | status |
|---|---|---|
| item 99 above | *"the PFA-inclusive rates already carry the 11.1% uplift (item 95)"* | **corrected in place** — and note it attributes the number to item 95, which does not contain it |
| item 111 above | *"the 11.1% PFA/SRL uplift"*, *"+11.1%"* | **corrected in place** |
| `202609240001` | three mentions in comments | left as written |
| `202609250001` | one mention | left as written |

**So the label was not mis-sourced — it was UNsourced.** It entered at item 99 as a precise-looking
figure attached to a citation whose target held no figure, and three later writers inherited it from
there. The migrations are deliberately not rewritten: they record what was believed when written,
and a migration edited after the fact stops being evidence. **Anyone reading "11.1%" in those two
files should read 11%.** The general form of how this survived two months is item 131 below.

**Shape: ONE table with a discriminator, under one versioned header** — not one flat table, and not
two tables. The two shapes are keyed differently rather than merely shaped differently (Anka's by
`(person, task_category)`, Margean's by `(person, word band)`), so a flat table with both keys
nullable admits four states of which two are meaningless — SAD §4's own objection to a polymorphic
discriminator on `contracts`, at smaller scale. Two tables was the runner-up and would have cost two
versioning headers, two resolvers and two policies that must stay identical. `rate_kind`
(`hourly | per_article | per_newsletter`) plus a shape CHECK makes the wrong combinations
**unrepresentable**.

**The FINAL-vs-uplifted distinction is in the data, not a comment — three columns and two CHECKs:**

| | `amount` (invoiced) | `net_amount` | `is_uplift_applied` |
|---|---|---|---|
| Anka: admin / ateliere / financiar | 80 / 80 / 90 | **null** | false |
| Margean: 4 bands + newsletter | 100 / 150 / 250 / 350 / 150 | **null** | false |
| Laura, Teodora, Alexandra | 55.50 | 50 | true |
| Cătălina | 79.92 | 72 | true |

`amount` is always the invoiced figure. `net_amount` is populated **only** where an uplift applied,
which makes `is_uplift_applied` redundant by construction and therefore checkable:
`is_uplift_applied = (net_amount is not null)` and `amount = round(net_amount * 1.11, 2)`.
**That is what stops someone adding 11% to Anka's 80: her row has no net figure to uplift from, and
a row claiming an uplift that does not reconcile is rejected.** Asserted both ways in the suite —
`50 → 55.55` is refused, `50 → 55.50` accepted — with a sabotage that drops the reconcile CHECK and
flips the refusal.

The resolver returns the **invoiced** figure and never the net, so a caller cannot uplift by
accident. Two-step like the six pay-grid resolvers, raising on an incomplete version instead of
falling back to an older value. `SELECT`/`INSERT` grants only, no `UPDATE`: a correction is a new
version.

**Anka's three categories, her words, in the column comment:** admin = everything administrative but
not financial; ateliere = workshop organisation plus sales and ActiveCampaign; financiar =
accounting and financial statements. That is the mapping item 105 above recorded as open.

**One miscount worth keeping:** the seed's own guard refused the first run — *"expected 13 rates,
found 12"* — because 3 + 4 + 1 + 4 = 12 and the assertion said 13. The data was right and the
assertion wrong, which is the guard doing its job on the migration that contains it.

**Not built, deliberately:** the hours-entry screen. Rates first.
**Lives in:** `supabase/migrations/202610120011`, `202610120012` and both rollbacks;
`db/tests/admin_rates.sql`; `app.resolve_admin_rate`; item 111 above (the figures and their
provenance); item 95 above (the trainer grid this mirrors — which quotes her "111 lei/ora" and
never states a percentage); item 99 above and item 131 below (where the wrong label entered, and why
it lasted);
item 112 above (the entity attribution these hours will also need); item 130 below (why the
hours-entry screen cannot key pay on the person).

---

### 130. Cătălina is the first person with both a trainer grade and an admin rate — the hours-entry screen cannot key pay on the person

2026-10-12, found while seeding item 128 above's rates and recorded rather than solved.

**She has both.** A trainer grade since `202609240002` (one of the ten Anca supplied), and now an
admin rate of 72 net / 79.92 invoiced — a figure that appears in no earlier record in this project
(item 111 above). Nobody else is in both tables: the other three uplifted admins hold no trainer
grade, and the ten graded trainers hold no admin rate.

**So "what is this person paid" has no answer, and that is the constraint on the screen that does
not exist yet.** An hours-entry form that resolves pay from the person alone would, for her, pick
one of two correct rates arbitrarily — and the two resolvers disagree by design:
`app.resolve_trainer_grade_rate` answers through her grade and `app.resolve_admin_rate` through her
task category. **The hour has to carry its own kind**, and the rate resolves from the kind rather
than from who worked it.

Two further things that follow, so the shape is not rediscovered:

- **Her admin rate is `task_category = 'admin'` only — CONFIRMED 2026-10-12 as correct, not a gap.**
  Anca: Cătălina keeps only the Admin category; no Ateliere rate, no Financiar rate. So
  `app.resolve_admin_rate` raising for either of those two **is the intended behaviour**, and the
  absence is an answer rather than missing data. **Nobody should fill it by copying 79.92 across** —
  that would invent two rates she does not hold and silently price work she does not do. If an
  `ateliere` or `financiar` hour is ever entered for her, the correct outcome is the raise, and the
  correct response is to ask her again rather than to seed a third rate.
- **The same hour also needs a legal entity** (item 112 above), and the entity question is
  independent of the kind question. A screen that solves one and not the other produces a priced
  hour nobody can invoice.

**Blocked on:** nothing — both halves closed. The dual-rate constraint stands as a constraint on the
hours-entry screen (the hour carries its own kind), and the category question is answered: Admin
only, deliberately.
**Re-verify when:** that screen is designed. The test to write first is Cătălina's: two hours, one
trainer and one admin, on the same day, priced differently and correctly.
**Lives in:** item 128 above (her admin rate); item 95 above (her trainer grade, seeded with nine
others); item 111 above (the rate's provenance and the FINAL-vs-uplifted split); item 112 above (the
entity half of the same hour); `app.resolve_admin_rate` and `app.resolve_trainer_grade_rate` (the
two answers).

---

### 131. A label repeated often enough reads as sourced — "11.1%" survived two months because nothing ever multiplied it

2026-10-12. The general form behind item 128 above, recorded because this register keeps finding it
and this instance has an unusually clean mechanism.

**What happened.** An uplift percentage entered the written record at item 99 above as *"the 11.1%
uplift (item 95)"*. **Item 95 contains no percentage.** It quotes Anca's own words — *"vom avea
direct 111 lei/ora tarif de baza junior"* — a base of 100 and a result of 111, which is 11%. The
citation supplied authority the target never had, and three later writers (item 111 and two
migrations) inherited the figure from the citation rather than from the arithmetic.

**Nothing in two months multiplied it by anything.** The number appeared only in prose: in comments
explaining why `contract_type_uplift` must stay empty, in an entry describing which rates are
FINAL, in a register item about admin pay. Every one of those sentences is *true at 11% as well*,
because none of them computes — they all say "the uplift is already included, do not add it again",
which holds whatever the percentage is. **A wrong number that is never used produces no wrong
answer, which is exactly why it survives.**

**It surfaced only when a CHECK needed a tolerance, and only because the tolerance was set from the
arithmetic rather than from the data.** Writing
`check (amount = round(net_amount * 1.11, 2))` required knowing the multiplier, and the honest way to
pick it was to ask which multiplier the stored figures actually imply. The lazy way was available
and would have hidden it permanently: set the tolerance wide enough for 55.50 and 79.92 to pass
under ×1.111, note that "Anca's numbers don't reconcile exactly", and move on. **That version
passes, ships, and encodes the wrong rate forever** — and the CHECK becomes decorative, which is
worse than no CHECK because it looks like verification.

**The three recurring shapes this is an instance of, now visible together:**

| shape | instances |
|---|---|
| a citation acquiring a figure its source never contained | this; item 62 below (a recommendation remembered as delivered) |
| a plausible mechanism written down as a cause | item 118 above (three times in one hour), item 104 above, item 109 above |
| a check whose threshold was fitted to the data it was meant to test | **this is the first recorded instance** |

**The third one is the one worth naming**, because it is the only one of the three that is invisible
after the fact: a tolerance fitted to make the current data pass leaves no trace, reports green
forever, and cannot be distinguished from a correct threshold by reading the code. **The rule it
implies: a numeric constraint's threshold comes from the arithmetic that explains the data, never
from the data itself. If the two disagree, the data is telling you the arithmetic is wrong — which
is precisely what happened here, in the other direction.**

**And a cheap habit that would have caught it earlier:** any percentage in prose should be written
with the pair that produces it, once — "11% (100 → 111)". The figure then carries its own test, and
a reader who multiplies finds the error in seconds rather than in two months.

**Re-verify when:** nothing — this is a lesson, not a defect with a state. But the next numeric
CHECK written in this repo should name, in its own comment, which figures its threshold was derived
from. `admin_rates_uplift_reconciles_check` does (item 128 above).
**Lives in:** item 128 above (the instance, with the measurement); item 99 above (where the label
entered); item 111 above (where it was inherited); `202609240001` and `202609250001` (the two
migrations left uncorrected on purpose); item 118 above and item 104 above (the adjacent shape, a
mechanism mistaken for a cause).

---

### 132. Anca's 2026-10-13 answers — a fourth name-based inference refuted, Raluca's tier boundary closed, and one gap that is a gap rather than a decision

2026-10-13. Three answers, and they are three different kinds of thing: one correction to data, one
decision that closes an ambiguity, and one admission that nobody has thought about something yet.
Recording them the same way would lose what matters about the third.

#### 1. Școala Germană is taught in Romanian and English — and it is a STATE, not a property

Anca: the groups run in Romanian and English **at least this year**, because the trainer who speaks
German is not available. So this is not a fact about the school; it is a fact about this year's
staffing. **If that trainer comes back, it changes.** That sentence is the whole value of the answer
and it is why `language_group` must never be back-filled from anything about the client.

`language_group = 'ro_en'` is therefore the right value, carrying the **0%** branch rather than
`fr_de_es`'s 20% (item 95 above).

**BLOCKED, and the blocker is not a permission — there is nothing to write to.** Școala Germană
exists as a *client* and has a signed contract (205), but **it has no group**. `language_group` lives
on `public.groups` and nowhere else; `public.clients` has no such column (checked, not assumed). The
whole table holds four groups: two for Lycée Français and two in Test Org B. So a migration for this
would have updated **zero rows** while its comment asserted a fact — a migration that passes and
means nothing, which is worse than no migration, because the next person reads the comment and
believes the data carries it.

**What to do instead, when the group is created:** set `ro_en` at creation, and put Anca's reason in
the group's notes, not just in a migration comment — the reason has an expiry date and the migration
file does not.

**The fourth name-based inference refuted in this project**, and item 110 above now carries the
count. German school, not taught in German; French school, taught in English; a surname "corrected"
that was already right; an association's spelling "fixed" to the wrong one. The useful form is not a
warning about schools with foreign names: **a name is evidence about what to call a thing and about
nothing else.**

#### 2. Raluca's per-article tiers — the boundary, and what was actually wrong

Anca settled the boundary in one sentence: **the upper bound belongs to the lower tier.**

| words | RON |
|---|---|
| 500 – 1000 | 100 |
| 1001 – 2000 | 150 |
| 2001 – 4000 | 250 |
| over 4000 | 350 |
| internal newsletter | 150 each |

**The thresholds were not missing. They were overlapping, which is worse.** `202610120012` seeded
`tier_min_words`/`tier_max_words` for all four tiers as 500–1000, **1000**–2000, **2000**–4000,
**4000**–null. Every row was individually well-formed and three word counts belonged to two tiers at
once, so a lookup written against them **returns an answer and the answer depends on row order**. A
1000-word article was worth either 100 or 150 RON depending on which row Postgres happened to read
first. An absent threshold fails loudly; an overlapping one pays the wrong amount quietly.

`202610130001` moves the three minimums up by one and relabels to match. **The amounts are
untouched** — those were already right and were never what was being asked.

**Below 500 there is no tier, deliberately.** Anca confirmed it does not happen. So the hours-entry
screen, when it is built, **rejects** a word count under 500; it does not round up into the first
tier. Rounding up is how this same defect would be re-created at a different boundary.

**Two things the fix surfaced that were not visible before it:**

- **`app.resolve_admin_rate` keys on the tier LABEL**, taking `'2000-4000'` as a string parameter.
  So relabelling a tier is a change to that function's contract, not a cosmetic edit — the suite
  failed on the first run after the migration with *"incomplete version"*, which is the resolver
  correctly refusing a tier it no longer has. The only caller in the repo was the test. **A resolver
  that takes a word count instead of a label is the shape this wants**, and it is the same point as
  §3 below; not built, because no screen calls it yet.
- **A CHECK constraint cannot catch what went wrong**, because it sees one row and every row was
  well-formed on its own. The guard is in `db/tests/admin_rates.sql` instead: a walk over 499, 500,
  1000, 1001, 2000, 2001, 4000, 4001 and 999999 requiring each to resolve to exactly one tier — and
  499 to **zero**, so that an assertion of "exactly one" cannot be satisfied by quietly widening the
  first tier down to 0. A sabotage block re-creates the overlap and requires the walk to notice.

#### 3. Who counts the words — a GAP, not a decision

Raluca declares the word count; nobody verifies it. Asked who checks, Anca's answer was **"nu m-am
gândit până acum"**.

**That is recorded here as an observed gap and not as a confirmed decision**, because the difference
matters later: a decision is something to build against, and a gap is something that will be
answered differently once someone thinks about it. Writing "no verification step — confirmed" would
hand a future reader a policy nobody set.

**What the application can do without adding an approval step**, which is a smaller and more useful
question than "who approves":

- the **word count is a field on the row**, entered once by the person doing the work;
- the **tier is computed from that number**, never chosen from a dropdown.

That is all. No validation of whether the number is true, no second person, no approval state. The
only thing it buys is that **the declared number and the tier it was paid at cannot diverge** — the
number stays on the record, and the band is a function of it rather than a parallel claim. If Anca
later wants a check, it has something to check against; if she does not, nothing was built that
needs unbuilding.

**Blocked on:** §1 needs a group to exist for Școala Germană. §3 needs nothing — it is a note for
whoever builds the hours-entry screen (item 73 above), and it is not a decision waiting on Anca
unless she raises it.
**Re-verify when:** a group is created for Școala Germană — set `ro_en` and record the reason with
its expiry ("while the German-speaking trainer is unavailable") in the group's notes. And when the
hours-entry screen is built: the word count is a field, the tier is derived, and a count under 500 is
rejected rather than rounded.
**Lives in:** `supabase/migrations/202610130001_admin_rate_tier_boundaries.sql`;
`db/tests/admin_rates.sql` blocks 5 and 6 (the boundary walk and its sabotage);
`supabase/migrations/202610120012_seed_admin_rates.sql` (the overlapping seed this corrects);
item 110 above (the name-inference count, now four); item 95 above (the 20% / 0% language branch);
item 73 above (the hours-entry screen §3 is a note for); item 130 above (the other constraint on
that screen).

---
### 133. The supplier-contract screen — built, and the first thing it shows is a 2025 price that contradicts the current grid. That is correct.

2026-10-13. The 30 rows imported into `supplier_contracts` on 2026-10-12 had no screen; they do
now, as a section on the supplier sheet rather than a list of its own.

**A contract register shows what the contract said, not what is paid today — and the screen must
not be "corrected" to hide that.** Raluca Mărgean's March 2025 contract carries its own tier table
in `price_text`:

> ● Pentru un articol mai mare de 2000 de cuvinte 170 RON net
> ● Pentru un articol intre 1001-2000 cuvinte 120 RON net si
> ● Pentru un articol intre 500-1000 cuvinte 100 RON net

`admin_rates`, confirmed by Anca on 2026-10-13, says 100 / 150 / 250 / 350 (item 132 above). **These
do not conflict.** The contract ran 2025-03-01 → 2025-09-01 and was replaced by two amendments whose
dates are on the same screen, directly beneath it; the grid is from August 2026. A historical price
beside a current rate is what a register is for. **No question goes to Anca about this**, and if
someone later reads the two numbers as a contradiction, the chain and its dates already answer it.

**It also corroborates item 132's boundary rule from a signed document rather than a recollection:**
the 2025 contract already wrote *"intre 1001-2000"*, i.e. the upper bound belonging to the lower
tier, a year and a half before Anca was asked to settle it.

**Two things the screen surfaced on its first run, both data rather than code:**

- **FLEXIBLE OFFICE SPACE shows "Contracts (3)" over four rows, and two of those three roots are
  called `Act aditional 03 la contract 10/10/2022` and `... 18/11/2022` in `exit_number` while
  `amends_contract_id` is null on both.** So the source register names them as amendments to
  contracts from 2022 that **are not in the register at all**. The app is right to treat them as
  roots — it has no parent to attach them to — and the screen makes the gap visible, which is the
  point. Not fixed: inventing a parent row would be worse than showing the truth.
- **`exit_number` holds values like `83.0` and `5881.0`** — numbers that passed through a float on
  the way in. Rendered verbatim, because this column is the contract's identifier and quietly
  trimming `.0` would make the screen disagree with the register it mirrors.

**Decisions, for whoever changes this later:**

| | |
|---|---|
| Where | A section on the supplier sheet. Not a list page: every row belongs to one supplier, at most 4 on any of them, and an amendment chain only means anything inside one supplier — a flat sortable list breaks a contract and its two amendments into three equal rows. A list page becomes right when there is an expiry/renewal workflow; `status` is `signed` on all 30 today, so there is none. |
| Laura | The section renders for **every** viewer, with a lock instead of contracts for anyone without `finance.reporting.*` — **including on the three suppliers that have no contracts**. Rendering it only where rows exist would make its presence the signal, and the lock would announce exactly what it withholds. |
| The count column on `/suppliers` | **Stricter than the lock.** For a viewer without the capability the column does not exist, is not offered in the Columns dropdown, and the counts are never sent to that browser — they are computed server-side. A count is information: "3" tells Laura precisely what the lock refuses to. |
| Capability | Checked server-side, **never** from `rows.length`. Three suppliers genuinely have zero contracts and must not render as a refusal. |
| Price | **One field**, not a value column beside a price column. 10 rows carry `contract_value` and on 9 of those `price_text` is the same number as a string; 14 have only text the number cannot hold (`80 RON/ORA, 90 RON/ORA`, `180 EURO +TVA`, `1000 ron/trimestru`); 6 have neither. Text wins when it says more than the bare number — EDUKIWI's unit (`10099.87 ron/curs`) lives only there. **No total**: the migration states the ten are implicitly RON and that United Media's `1928 EUR` was deliberately excluded, so a sum would add euros to lei. |
| Periods | **Three** states. A date; the **word** "nedeterminat" for `is_open_ended`; and the muted dash for `period_end` null with `is_open_ended` false. That third case is **7 rows against 5** — the bigger half, not the exception. `period_start` is null on 4 rows and takes the same dash. |
| Chains | Rendered **recursively**. Raluca's is already two deep — the original is amended by one act and that act by a second — so one level of grouping would have put the third as a sibling of the first. `Contracts (N)` counts **contracts**; an amendment is never one of its own. |

**Corrected while building, against the numbers in the request:** 6 of the 22 suppliers have more
than one contract (not 9), and only 19 of 22 have any at all; the 5 amendments belong to 4 suppliers
(not 5). The 5 open-ended rows and the 10 with a numeric value were right.

**Also fixed, because this screen made it visible:** `/suppliers/[id]`'s own `Kv` was still the old
`justify-between` one — the third sheet, missed when `/clients/[id]` and `/groups/[id]` were
converted. Its Notes row rendered *"NoteRegister rows 26-28: ..."* as one run-on word. Same
two-column treatment as its siblings now, and the page moved from `max-w-2xl` to `max-w-4xl` to
match the client sheet — invisible while it held one card, obvious the moment it held two.

**Blocked on:** nothing.
**Re-verify when:** `supplier_contracts` gains a currency column — the no-total rule above exists
only because there isn't one. And when a renewal workflow appears, at which point the list-page
question is worth re-asking.
**Lives in:** `app/(app)/suppliers/[id]/supplier-contracts-section.tsx`;
`app/(app)/suppliers/[id]/page.tsx`; `app/(app)/suppliers/page.tsx` and `suppliers-client.tsx` (the
opt-in count column); `supabase/migrations/202610120009_create_supplier_contracts.sql` (the RLS
policy and the implicit-RON note); item 132 above (the current grid, and the boundary rule this
contract corroborates); item 73 above (the hours screen that will read that grid).

---
### 134. The same float damage was cleaned in one column and missed in another, from the same spreadsheet, two migrations apart

2026-10-13. Thirteen of the thirty `supplier_contracts.exit_number` values arrived as `83.0`,
`5881.0`, `155420.0` — Excel reading a contract number as a float. A contract number has no decimal
part, so the `.0` is damage carrying no information, and until `202610130002` the app disagreed with
the paper register it mirrors.

**The point of this entry is not the thirteen rows. It is that this exact transformation was CAUGHT
in the same source file, five days earlier, in a different column.** `202610070003`, the suppliers
seed, cleaned `cui` of precisely this and wrote it into its own header:

> `cui` — cleaned, not transformed. Two cleanings applied: the spreadsheet's float artifact
> (`53213832.0` -> `53213832`, from numeric cells) …

Then `202610120010` imported the contracts **out of the same workbook** and did not look at
`exit_number` for it. Nobody skipped a step: the person cleaning `cui` was looking at `cui`.

**The rule: when one column in a file is found to have gone through a float, every column from that
file is suspect, including the ones where the damage is invisible.** It is invisible in exactly the
columns that matter — `83.0` looks like a number someone typed, where a mangled date or name would
have been obvious on sight. The check is mechanical and takes one query per text column:
`select … where col ~ '^[0-9]+\.0$'`.

**What made it finally visible was a screen**, not a review: `exit_number` had no renderer until
item 133 above, and the first screenshot of the supplier sheet put `83.0` on the page as a contract
number. Data that nothing displays is data nobody checks.

**The cleanup is anchored, and the anchor is the safety.** `~ '^[0-9]+\.0$'` and never
`like '%.0'`: eleven values were deliberately left alone, and the second pattern would have
truncated `1/15.01.2026` and `2388738/14.09.2025` into something that looks plausible and is wrong.
A value with a genuine decimal — none today, nothing stopping one — is not damage and must survive.

**The rollback names the thirteen one by one rather than matching a pattern.** A pattern rollback
(`where exit_number ~ '^[0-9]+$'`) would also hit a bare-integer number that was always correct, or
one entered after the migration, and hand it damage it never had. Restoring a value is only safe
when you can name the value.

**Rendering was NOT changed.** The screen still prints `exit_number` verbatim; it was the value that
was wrong, and a renderer that trimmed `.0` would have hidden the defect instead of fixing it — and
would then have disagreed with any export or query that did not.

**Blocked on:** nothing.
**Re-verify when:** any further import from `Tabel contracte furnizori Wow Lab.xlsx` or a sibling
workbook. Run the pattern across every text column of the new rows before anything renders them.
**Lives in:** `supabase/migrations/202610130002_clean_exit_number_float_suffix.sql` and its rollback;
`db/tests/supplier_contracts.sql` blocks 5 and 6; `supabase/migrations/202610070003` (where the same
damage was caught, in `cui`); `supabase/migrations/202610120010` (where it was missed);
item 133 above (the screen that exposed it); item 127 above (the import).

---
### 135. Two defects a real iPhone found and our screenshots could not — one of them is not a defect at all

2026-10-13, both reported from Safari on an iPhone against `app.wowlab.ro`.

#### 1. "Application error: a client-side exception has occurred" on `/suppliers` — NOT a code defect

First visit after a deploy showed a white page with Next.js's client error-boundary message; a
reload fixed it. **It is stale HTML asking for assets the new build no longer has, and the evidence
is a 404 rather than a plausible story:**

```
/_next/static/css/87c5d91ee3bbfa6d.css   (build 2028604)  -> app.wowlab.ro  HTTP 404
/_next/static/css/fa3509c0036b48d4.css   (build 23e33a3)  -> app.wowlab.ro  HTTP 200
```

A superseded build's hashed assets are **not** retained on the production domain. The CSS hash
changed between `2028604` and `23e33a3`, and `23e33a3` went READY at **14:55:54Z**, minutes before
the phone was used. A page held from before that deploy requests files that have since stopped
existing, the client runtime cannot load them, and the error boundary renders. A reload fetches
fresh HTML with current hashes, which is exactly the "worked on reload" that was reported.

**The code hypothesis was tested and refuted, not merely doubted.** `/suppliers`,
`/suppliers/[id]` and `/groups` were loaded on production with an iPhone user-agent, a cleared
cache and `Network.setCacheDisabled`, with `Runtime.exceptionThrown`, `consoleAPICalled` and
`loadingFailed` all recorded: **no exception, no error, no warning, no failed asset.** Separately,
the specific suspicion about the new supplier-contracts section cannot produce this —
`usePersistedColumns` sets state to its default and reads `localStorage` in `useEffect` after mount
precisely so it cannot mismatch, the chain renderer is pure, and the counts are computed on the
server and passed as props. And a hydration mismatch would have reproduced on the reload.

**So nothing in the code is to be "fixed", and changing anything here would be the mistake this
project made twice today.** What exists is a platform setting, currently off:

```
skewProtectionMaxAge:     (not set)
skewProtectionBoundaryAt: (not set)
```

Vercel's Skew Protection keeps a previous deployment's assets resolvable for a configured window,
which is the actual remedy for a client holding older HTML. **Not enabled here, and not enabled by
this entry** — it is a deployment-settings decision, recorded so the next person meeting this white
page does not go looking through React.

**How to tell this apart from a real crash, next time, in one step:** if a reload fixes it, it is
not the code. A code defect reproduces.

#### 2. The Columns menu opened off the left edge of the screen — a real defect, on all four lists

Measured before touching anything, by opening the panel in a browser and reading its box:

```
  page         viewport   button        panel            verdict
  /groups      320        [57,150]      [-74, 150]       74px outside the window
  /clients     320        [57,150]      [-74, 150]       same
  /contracts   320        [57,150]      [-74, 150]       same
  /suppliers   320        [57,150]      [-74, 150]       same
  (and the same at 390; 768 and 1280 were fine)
```

The panel is `absolute right-0 w-56`. At phone widths the toolbar wraps and the button lands near
the LEFT, so hanging a 224px panel from its right edge (x=150) starts it at x=-74. Anchored `left-0`
below `sm:` and `right-0` from `sm:` up, plus a `max-w-[calc(100vw-1rem)]` clamp for a future
toolbar that moves the button. Re-measured across 4 pages x 4 widths x 2 languages, 32 combinations,
all inside the window.

#### The lesson, which is the part worth keeping

**Our screenshot verification renders the server's HTML. It has never contained anything that only
exists after a click — and it has been treated as though it did.** This panel lives in React state
behind a `<details>`; no capture we have ever taken could have held it, on any width, in either
language. The same blind spot was named once before, about the create-group form, and then not acted
on.

**So a screenshot pass is evidence about the page as delivered, and about nothing that opens.**
Anything behind a click — this dropdown, the create forms, the expanded table row, the locale
switcher's effect, the mobile drawer — needs the panel actually opened in a browser and, better,
its box measured, which is what caught this one and what will catch the next one at a width nobody
photographed.

**Blocked on:** nothing. §1 needs a decision about Skew Protection, which is a settings change
rather than work.
**Re-verify when:** a white page is reported after a deploy — check whether a reload clears it
before reading any code. And whenever a new control opens on click: measure its box at 320, not just
photograph the page behind it.
**Lives in:** `components/ui/data-table.tsx` (`ColumnsDropdown`); item 133 above (the deploy whose
asset-hash change this coincided with); item 109 above (naming a cause before verifying it, the
mistake §1 exists to avoid).

---

### 136. `/payroll` shows money — a year after the function that computes it was written and left uncalled, and the rounding rule is the part that had to be decided rather than discovered

2026-10-15. `app.calculate_session_pay` (item 99, `202609250001`) had been tested and **uncalled**
since 2026-09-25 — its own header said so: *"nothing calls this function yet (no UI, no payroll
screen)"*. `/payroll` showed confirmation state and the pre-close check (item 121) and **no money
at all**, so Anka closed the month without seeing what she was closing. This is the caller.

**What it is: one set-returning function, not the ten-line wrapper the scope report promised.** The
report said `public.calculate_session_pay(session, trainer)`, ~10 lines, forwarding only. Two
things found while building made that wrong:

1. **A raise aborts the statement.** `calculate_session_pay` raises on fourteen distinct shapes of
   missing input, and PostgREST gives no way to ask for "the amount, or the reason there isn't
   one". Catching per slot is only possible inside plpgsql. A per-slot wrapper would have meant one
   round trip per trainer slot **and no isolation** — one 30-minute Școala Altfel workshop would
   have turned the whole month's total into a 500.
2. **The month picker is client state**, not navigation (`page.tsx`'s own comment says why), so the
   server component cannot know which month to ask about. The function returns the whole org, for
   the same reason the sessions fetch above it already does.

Still `SECURITY INVOKER`, like every resolver underneath and like `calculate_session_pay` itself.
`SECURITY DEFINER` would let any caller reconstruct the whole pay grid row by row from the amounts
— exactly what that function's own header refused one level down.

**THE ROUNDING RULE, which is a decision and not a detail.** Every workshop row rounds to 2
decimals; a trainer's total is the sum of the **rounded** rows, never the unrounded sum rounded
once at the end. Mihai's reason, and it is the right one: *Anca emite factura din ecranul asta și va
aduna rândurile de mână; totalul trebuie să dea cu calculatorul.*

The two rules differ for real, and the suite asserts the discriminating pair:

> Two slots at **276.225** each → `276.23 + 276.23 = **552.46**`, while rounding the `552.45` sum at
> the end gives **552.45**. One ban apart, and the second makes the screen look wrong to the person
> adding it up.

**Rounded in Postgres `numeric`, never in JS** — 276.225 is not representable in binary floating
point, so the language doing the rounding decides the answer. `numeric` rounds half away from zero,
exactly once, in the function. TypeScript then converts each already-rounded amount to **integer
bani** and sums integers: `276.23 + 276.23` in float64 is `552.4599999999999`. The only float
arithmetic left in the pay path is the single division by 100 at render.

`calculate_session_pay` itself stays **unrounded**, deliberately — item 95's finding (444 of 1,456
real approved historical amounts carry bani) is unchanged. The unrounded product is still the
calculation's truth; this round added a display layer that asks for two decimals.

**A raise costs its own row and nothing else.** The row shows the reason, the trainer keeps the
total from their other workshops, and the month total says explicitly that it excludes N workshops —
counted by distinct **workshop**, not by slot, because two bad slots on one workshop are one thing
to go and look at. The caveat sits on the total rather than only in the rows: a total that quietly
omits workshops is the one number on this screen that must never read as complete when it isn't.

**Reasons in plain language, classified in SQL next to nothing.** The fourteen raise shapes map to a
`reason_code`, matched on substrings **in the function**, because the two alternatives are both
worse: re-asking the five input questions in SQL duplicates `calculate_session_pay`'s own guards
(the mirror item 121 keeps, which **provably drifted** — it misses every grid gap), and matching in
TypeScript would put the match a repo away from the raise it matches. `error_text` is returned
alongside, always: an unmatched shape gets `'unknown'` and the screen prints the raw message —
degraded and ugly, never silent, and never a wrong amount.

**Confirmed and unconfirmed are never summed.** Anca's rule, 2026-09-11: a trainer who did not
confirm is not paid for that workshop. So per trainer there are two figures, and the close prompt
(`confirm_prompt_with_unconfirmed`) already said as much — one number mixing them would contradict
the sentence on the button directly below it.

**Per trainer, because the unit of payment is the trainer.** Anca, 2026-09-11: *the timesheet closes
at month end and the invoice is issued from it* — per person (PFA/SRL). Per workshop alone would
leave Anka adding rows up by hand, which is the spreadsheet work this replaces; a single month total
could not be checked against anything. Grouped by trainer **id**, not name: two people can share a
display name and a sum is the last place to merge two of them.

**Test Org B had no pay grid at all — a hole, not an obstacle.** Zero rows in all four rate tables,
while holding the only three sessions in the database and six graded trainers. `scripts/
verify_pay_inputs_through_app.ts` had seeded grids exactly like these **as fixtures and deleted
them in cleanup**, which is why the org had none. A grid is not a fixture: it is the standing
configuration that makes a test org a test org. Now seeded (`202610150004`), with deliberately
synthetic values that are **not** WOW LAB's, so a test cannot pass by reading production numbers.
Two deliberate choices in it: **grade 2 is 175**, an odd rate, because the rounding rule is only
testable against a value that produces a third decimal; and **30 minutes is absent for the
Școala Altfel context**, mirroring production's real gap so the raise-isolation case is reproducible
there instead of only against production data.

**`groups.language_group` filled on the MAX group** — the one existing row this round changed. A
fill, not a correction, guarded on `is null` so a real value set later is never overwritten. Without
it all three of Test Org B's sessions failed on the third guard before any grid was consulted.

**Three mistakes of mine, each caught by running the thing rather than reading it:**
- **The test asserted `no_grade_version` where the data can only produce `no_grade`.**
  `calculate_session_pay` calls `resolve_trainer_grade` **before**
  `resolve_trainer_grade_rate`, so a date before the grids is also a date before any assignment and
  the grade fails first. An earlier live probe had called the rate resolver *directly*, which
  bypasses that order — the probe was right about the resolver and wrong about the path. Corollary
  worth keeping: **`no_grade_version` is unreachable with today's real data**, because every grade
  assignment and all four grid versions are effective 2026-09-01; it becomes reachable the moment a
  grid version is added with an effective date after an existing assignment. The suite now reaches
  it with a fixture that gives one trainer an earlier grade.
- **The verification script called the function as `service_role`** and died on *permission denied*
  — the right failure for the wrong call. `service_role` bypasses RLS, so it would have proved
  nothing about whether a real finance viewer can get a number out of a `SECURITY INVOKER`
  function. It now signs in and calls as the Org Owner.
- **It asserted the screen renders `656.26` with one confirmed and one unconfirmed workshop.** It
  does not, and correctly so — the two buckets are never summed. Two workshops have to be in the
  **same** bucket for the sum of rounded rows to appear at all. The fixture is now four sessions:
  two confirmed (the visible 656.26), one unconfirmed, one that raises.

**The readability guard, carried forward from item 123.** The rate tables admit SELECT to
`finance.operations.*` / `finance.reporting.*` / platform owner, while `/payroll` **also** admits
`org.settings.manage`. For a viewer holding only the latter every row would come back as a raise,
and rendering that as "nothing can be calculated" is item 123's mistake exactly. Verified before
building that **no live role lands there** — `org.settings.manage` is granted only to Organization
Owner and Platform Owner, both of which also carry `finance.operations.*` — so the guard is against
a role change, not against today's data. It asks the **capability** rather than counting rows, so a
capable viewer of an org with no grid seeded reads as "no grid", never as "not for your eyes". On
failure the screen renders without sums rather than with zeroes: a zero beside a trainer's name is a
wrong number, and this is the screen where a wrong number becomes a payment.

**Two counts of "what's missing" now coexist, and that is not settled.** Item 121's pre-close block
answers *"what can a human still fix before closing?"* (the five enterable gaps); the sums block
answers *"why is there no number here?"* and is a **superset** — it includes gaps in the pay grid
itself, which nobody can fix from this screen. The wording distinguishes them, but two blocks
reporting different counts about the same month is a real risk to trust in the screen, and the
honest long-term answer is probably that the calculation's own list replaces the mirror. **Not done
this round**, and not a silent decision: item 121 is shipped, documented behaviour and replacing it
was not in scope.

**Deliberately NOT built:** no payments register, no stored amount, no trainer-facing screen.
Computed at read time, displayed, discarded. One consequence stated rather than discovered later:
because nothing is stored, the figure is **as of now, not as of close** — a grid version backdated
later would make the same closed month display a different number. Correct for a displayed
calculation; the moment *"the number we actually invoiced"* must be reproducible, that is the
payments register. `/my-work` is untouched and still shows a trainer their grade and minutes and
never a rate.

**Performance, stated rather than optimised:** each slot costs ~6 indexed lookups inside the
function, so a year of a few hundred sessions is a few thousand cheap lookups in one call. Fine
today (the real org has **zero** sessions); the thing to watch is that it is org-wide and
unpaginated, for the same reason the sessions fetch beside it is.

**Verified live.** `db/tests/payroll_org_session_pay.sql`, 18 assertions across 3 blocks, against
WOW LAB's **real production grids** — the rounding pair, the 30-min Școala Altfel isolation, and one
reason_code per gap including the assertion that **no real case falls through to `'unknown'`** (the
assertion that fails, deliberately, if a resolver's wording is ever changed without this screen
being told). Full suite: **273 passed, 0 failed, 17 files.** And
`scripts/verify_payroll_sums_test_org_b.ts`, 17 checks against a running app as the Org Owner —
sums render per trainer, `656.26` appears and `656.25` appears nowhere, the raise shows plain
language and not `incomplete version`, the total says it excludes 1 workshop. Cleanup is **not a
silent finally** (item 102): it runs as its own announced step, again on the failure path, and its
**effect is re-queried** — `0` marked rows left, Test Org B back to the 3 sessions and 2 groups it
was found with. Fixtures are deleted **by marker**, never by captured ids (item 124).

**THE PER-ENTITY GROUPING IS NO LONGER HYPOTHETICAL — proof from the real timesheet, 2026-10-20.**
Teodora Merișan, September 2026, one month: **four DSBU workshops invoiced from Experimente WOW**
(16.09, 23.09 among them) **plus a Wow Lab Party on 19.09 invoiced from Brandine**. Same trainer,
same month, **two entities, two invoices** — which is exactly the case a single per-trainer total
cannot express and the reason the entity is the outer grouping rather than a label on a row. It also
rules out the cheaper design that was briefly tempting: one invoice per trainer per month with the
entity shown per workshop. That would have produced one figure Anka then has to split by hand, which
is the work Anca described having to do.

**UPDATE 2026-10-16 — four changes, and the pattern written down as a pattern.**

**1. The set-returning shape is now a convention, not this screen's exception.**
`docs/DATABASE_CONVENTIONS.md` §13: *any* screen that computes a value per row and can fail per row
gets one set-returning function returning a value **or** a classified `reason_code`, never one call
per row and never one call that aborts because one row was unanswerable. Nothing about it is
specific to pay — an invoice line per workshop, a client price per session, a margin per contract
are the same shape. The section carries the whole checklist (null value exactly when reason_code is
set, `error_text` always returned, classify next to the raises, range-scoped, `SECURITY INVOKER`,
refuse a nonsense window, round per row) and the test that has to come with it.

**2. The month is in the URL, and the function takes a range** (`202610160001`). `/payroll?month=
YYYY-MM`, resolved on the server, with the current month as an **explicit** fallback — a malformed,
absent or impossible value lands on the current month rather than on an empty screen that reads as
*"nobody is owed anything"*. Validated by reconstruction, not by regex alone: `2026-13` matches
`/\d{4}-\d{2}/` and is not a month. The immediate reason is that Anca can send a link to a specific
month and the page survives a refresh; the reason in two years is that the plpgsql loop costs ~6
indexed lookups per trainer slot, so org-wide at ~500 sessions a year is ~6,000 lookups per load,
growing forever, to render one month — scoped, it is ~500 and flat. **The sessions fetch is scoped
to the same bounds**, or the sums and the confirmation list would describe different sets of
workshops. `p_to_exclusive` is exclusive and named so, which keeps 28/29/30/31 out of TypeScript
entirely. An inverted or empty range **raises** rather than returning zero rows, because zero rows
is indistinguishable from a genuinely empty month and on this screen that is a statement about
money.

**3. The reason_code coverage test is derived from the function sources, not written by hand**
(`db/tests/payroll_reason_code_coverage.sql`). It reads the six producing functions out of
`pg_proc`, extracts every `raise exception` literal and every `when v_error like ... then ...`
branch, substitutes the `%` placeholders, and asserts with `LIKE` that **every raise has a branch
that matches it** — plus that every branch is reachable, that no raise maps to two different codes
(the CASE's first match would win silently), and that the derivation itself found all six functions
and ≥14 raises, so the file cannot pass by testing nothing the way `rls_ws_d_write.sql` did for a
month.

This replaced fourteen hand-written cases, and the reason is item 120's: *a checker that knows what
to look for only finds what someone already thought of.* That verifier had six anticipated forms
and missed the seventh, introduced in the same commit. **Proved to have teeth by sabotage**: inside
a rolled-back transaction it replaces `app.resolve_language_bonus` with a stub carrying an
unclassified raise, restates the headline assertion verbatim, and requires it to come back false —
which it does, naming the function and the message. The first draft of that block asserted the flip
rather than restating the assertion, which is backwards under the runner's own convention
(`run_rls_suite.ts` inverts any check named `SABOTAGE`), so it reported two failures until it was
restated.

Two reason codes were added while doing this, both for raises in `calculate_session_pay` the
original classifier had skipped as unreachable: `no_trainer` and `no_session`. They are still
unreachable through this screen — the function only asks about trainers holding a slot on a
workshop it just read — but *"unreachable today"* is a fact about today's callers, not about the
function, and the derived test does not accept an unclassified raise on those grounds.

**4. One block, one number** — the presentation change Mihai asked for before the schedule import.
There were two: item 121's five-question mirror, and the sums total's own *"excludes N workshops"*
line. **Two blocks counting the same month by two different definitions, able to disagree in front
of the person closing it.** Now one block with one count, split into two named sections by **who can
act**: *"Missing information — someone can still enter it"* and *"Gaps in the pay grid — not fixable
from this screen"*. The second exists so a grid gap is never filed under *"somebody forgot to type
something"* — that is the difference between a task and a dead end. The total's caveat now *refers*
to that single count (*"excludes the N workshops listed above"*) instead of carrying a second one.

**The two sources are merged rather than one being picked, because they cover different things.**
The calculation's reason_codes are the superset — they include the pay-grid gaps the mirror
provably missed. But the mirror sees one thing the calculation cannot: **a workshop with no trainer
in either slot produces no pay rows at all**, so there is no row to carry a reason, and *nobody to
pay* is still a reason not to close the month. So the calculation answers for workshops that have
slots, the mirror's `no_trainer` for workshops that have none — and the mirror alone when the sums
are unavailable, which is exactly the screen item 121 shipped. The only new judgement is the
five-code `FIXABLE_BY_ENTRY` set; a workshop lands in the second section only if **nothing** about
it can be fixed by entering something.

**Re-verified:** `db/tests/payroll_org_session_pay.sql` now 25 assertions across 4 blocks (block 4
is the range: `p_from` inclusive, the 31st included, `p_to_exclusive` excluded, the previous
month's last day excluded, and both nonsense ranges raising).
`scripts/verify_payroll_sums_test_org_b.ts` now 23 checks, including five for the URL month —
`?month=2026-01` renders its own empty month and not this one's figures, and `not-a-month`,
`2026-13` and no-month-at-all all fall back to the current month.

**Blocked on:** one question, and it is not engineering: whether the **secundar** is paid on the
same formula as the principal. Asked of Anca; built on the current formula, identical for both,
until she answers. The other question that was open here — whether item 121's block should be
replaced by the calculation's own list — is answered in the update above: merged into one block,
because neither source is a superset of the other.
**Re-verify when:** a resolver's raise message is reworded — the `'unknown'` assertion is the
tripwire, and the classifier is the thing to update. Also when `/payroll`'s gate or the rate tables'
SELECT policies change, because the guard's premise ("every viewer who can open this page can read
the grids") is a measured fact about today's roles, not an invariant.
**Lives in:** `supabase/migrations/202610150003_expose_org_session_pay_via_public_wrapper.sql`,
`supabase/migrations/202610150004_seed_test_org_b_pay_grids.sql` (+ both rollbacks),
`app/(app)/payroll/page.tsx`, `payroll-client.tsx`, `payroll/i18n.ts`,
`db/tests/payroll_org_session_pay.sql`, `scripts/verify_payroll_sums_test_org_b.ts`; item 99 above
(the function that waited), item 95 above (the grids and the no-rounding finding), item 121 above
(the mirror this is a superset of), item 123 above (the readability guard), item 124 above
(cleanup by marker), item 102 above (the announce-cleanup rule), item 137 below (the test accounts
holding payroll roles in production, and Anka Orban's missing grade).

---
### 137. Six test accounts hold payroll-capable roles in the production org — and Anka Orban's missing trainer grade is correct for a third reason

2026-10-15, reported and **not acted on**, by instruction. Both halves came out of asking who can
see the sums item 136 above added.

**1. The accounts. Six, not the four named** — `is_test_account = true` also covers two
`maxdigitalro+` aliases. `/payroll`'s gate is `finance.operations.*` **or** `org.settings.manage`:

| Account | Role | Role assigned | Assigned by | Can sign in |
|---|---|---|---|---|
| `test+finance-ops-a@wowlab.dev` | Finance Operations | 2026-07-09 | — (`seed.sql`) | **No** |
| `test+owner-a@wowlab.dev` | Organization Owner | 2026-07-09 | — (`seed.sql`) | **No** |
| `test+ui-finance-ops@wowlab.dev` | Finance Operations | 2026-08-10 | — (`seed.sql`) | **Yes** |
| `test+ui-owner@wowlab.dev` | Organization Owner | 2026-08-11 | — (`seed.sql`) | **Yes** |
| `maxdigitalro+finops@gmail.com` | Finance Operations | 2026-08-05 | `maxdigitalro@gmail.com` | **Yes** |
| `maxdigitalro+master@gmail.com` | Organization Owner | 2026-08-05 | `maxdigitalro@gmail.com` | **Yes** |

The four non-test holders: Anca Tanasescu (Platform Owner), **Anka Orban** (Finance Operations — the
intended user), Laura Moale (Finance Operations), `maxdigitalro@gmail.com` (Organization Owner).

**The distinction that matters is `auth.users`, not the flag.** Two of the six have **no
`auth.users` row** (convention 11: `seed.sql` fixtures exist in `public.users` only and cannot
authenticate) — they are SQL-impersonation fixtures and cannot open a browser session at all. The
other **four can sign in and would see real money** on `/payroll`. That is the actual exposure, and
it is four accounts, not six.

**`is_test_account` does not help here.** Its own column comment: *"purely a display label, does not
affect RLS, sorting, or filtering"* — it drives the Test badge in `/admin/users` and nothing else.
Item 18 below already recorded the matching trap from the other side: `is_test_account = false`
does not mean "a real person", it only means "not inserted by `seed.sql`" — which is exactly why the
two `maxdigitalro+` aliases above are flagged `true` while eight sibling aliases are not.

**What breaks if the payroll roles are removed — measured, not guessed:**
- `test+finance-ops-a@wowlab.dev` — **the standing RLS suite breaks.** Its `finance.operations.*`
  grant is impersonated by four `db/tests/` files (`rls_clients_contracts.sql`, `rls_users.sql`,
  `rls_ws_d_write.sql`, `capability_liveness.sql`) plus four `scripts/verify_*`. This one is load-
  bearing and removing its role would fail `run_rls_suite.ts`.
- `test+owner-a@wowlab.dev` — three `db/tests/` files (`rls_clients_contracts.sql`,
  `rls_ws_d_write.sql`, `rls_ws_d_read.sql`) and `seed.sql` itself. Also load-bearing.
- `test+ui-owner@wowlab.dev` — no `db/tests/` dependency; used by ~8 one-off `scripts/verify_*`,
  several already spent. Removable at the cost of re-pointing those scripts.
- `test+ui-finance-ops@wowlab.dev` — one script (`verify_suppliers.sql`). The cheapest to remove.

**So the two that can sign in are the two that are nearly free to change, and the two that are
load-bearing cannot sign in anyway.** That is a better position than it first looked, and it means
the exposure can be closed without touching the suite: revoke on `test+ui-finance-ops` and
`test+ui-owner`, and decide separately what the two `maxdigitalro+` aliases are for. **Not done** —
Mihai said not to touch them yet.

**2. Anka Orban has no trainer grade, and that is correct — but not for Luiza's reason.** The
question asked was whether she is salaried, in which case the absence would be right the way item
95's is for Luiza Mirt (*"grade 3 if she returns"*). **She is not salaried.** Measured:

- `suppliers` → **ASISMART SRL**, CUI `53213832`, service type *asistență administrativă*, status
  active, linked to her `users.id` through `suppliers.user_id` (item 110's column). She invoices
  through an SRL.
- `admin_rates` → three hourly rows of her own: `admin` **80**, `ateliere` **80**, `financiar`
  **90**, all with `is_uplift_applied = false` — consistent with SRL invoicing at a gross rate,
  unlike the trainer grid whose rates are PFA-inclusive (item 95) and unlike the 50 → 55.50 uplifted
  admin rows (item 128).
- `trainer_grade_assignments` → **no row**. `trainer_home_cities` → **no row**.
- Roles held in `wow-lab`: Finance Administration & Reporting, Finance Operations, **Senior
  Trainer**, **Trainer**.

**So the absence of a grade is right for a third reason: she is not in the trainer pay model at
all.** She is a supplier paid hourly for administrative and financial work, with her own rate table.
Not Luiza's case (a trainer whose grade is pending a return) and not an artefact of a missing row.
**The anomaly is the two trainer roles, not the missing grade** — and her documented workflow is
Toggl plus a monthly PDF to Anca for approval (item 127's §2), which is not a workshop slot.

**Can she be put in a paid slot, and what happens?** Yes — a slot is a plain FK to `users` with
**no role requirement** (item 122), and she holds trainer roles besides. If she is allocated, that
workshop becomes uncalculable with `reason_code = 'no_grade'` and `/payroll` prints *"nu are un grad
valabil la această dată"* under her name. It does **not** fall back to her admin rate:
`calculate_session_pay` never consults `admin_rates`, by construction. So she would be unpayable for
that workshop through this screen, and the month total would exclude it. **That is the correct
behaviour and needs no fix** — it is the exact mirror of item 130's problem (Cătălina Trușan is the
first person holding *both* a trainer grade and an admin rate, which is why the hours-entry screen
cannot key pay on the person).

**RESOLVED 2026-10-16 — both halves acted on, in opposite directions.**

**1. The two signed-in test accounts lost their payroll roles** (`202610160002`).
`test+ui-owner@wowlab.dev` (Organization Owner) and `test+ui-finance-ops@wowlab.dev` (Finance
Operations) now hold no role in `wow-lab`. The other four stay, deliberately: the two with no
`auth.users` row are not an exposure and are load-bearing for four `db/tests/` files, and the two
`maxdigitalro+` aliases are Mihai's own, needed to view the screens as each role.

**They were not deleted from the org.** Both held exactly one role row, so deleting it would have
left them with zero `user_org_roles` rows and they would have vanished from `/admin/users`' Members
list entirely. `app/(app)/admin/users/actions.ts` already refuses to do that — when every role is
unchecked it re-inserts a single row with `role_id = null`, which is how *"member, no role
assigned"* is represented (`202609040003`/`202609040004`, enforced by the partial unique index
`user_org_roles_one_membership_per_org_user`). The migration mirrors that rather than inventing a
shape. They keep their `auth.users` row, can still sign in, and will now be refused by `/payroll`'s
own gate.

**The six `scripts/verify_*.sql` that impersonated them were re-pointed, not given the roles back**
— at `test+owner-a@wowlab.dev` and `test+finance-ops-a@wowlab.dev`, whose role sets are
**identical** (one role each, the same one, verified before the change). That is the better state
on its own terms: SQL-impersonation scripts now use the accounts convention 11 says exist for SQL
impersonation, while the `test+ui-*` accounts exist for browser verification — which is exactly
why they can sign in and were the exposure. Two `*_test_org_b.ts` scripts mentioned
`test+ui-owner` only in a run-instruction comment; those were updated too.
`202608120006_add_is_test_account_flag.sql` still names them and is **not** edited: an applied
migration records what was true when it was written.

**2. Anka Orban's trainer roles are gone** (`202610160003`), and the question that justified them
is closed. **Anca, 2026-10-16: Anka does not deliver workshops.** The `ateliere` row in her
`admin_rates` is *administrative work ON workshops*, not workshops taught — so the second pay path
this item suspected **does not exist**, `app.calculate_session_pay` is complete as written, and the
two trainer roles were an anomaly rather than a record of anything.

**What she lost, measured by simulating the removal in a rolled-back transaction before doing it**
— necessary because she holds **twelve** roles here, so the question was never "do her two finance
roles cover this" but "do the other ten":

| Capability | After removal | Why |
|---|---|---|
| `mywork.*` | **lost** | 8 policies / 7 tables, `/my-work`, the confirm-attendance gate |
| `finance.own.read` | **lost** | 0 policies, 0 code references — inert |
| `materials.custody` | **lost** | 0 policies, 0 code references — inert |
| `community.read` | kept | via `community.*` (Community & People) |
| `curriculum.read` | kept | via `curriculum.*` (Curriculum Manager) |
| `presentations.own` | kept | via `presentations.*` (Curriculum Manager) |
| `sessions.read`, `groups.read`, `finance.operations.*`, `finance.reporting.*` | kept | her finance/ops roles |

**It cost her no visibility at all.** Rows actually readable before/after on all seven tables with a
`mywork.*` branch: sessions 0/0, groups 2/2, clients 3/3, client_contacts 4/4, users 38/38,
session_lesson_plans 0/0, payroll_periods 0/0 — her broader grants already covered everything the
own-slot branches gave her, so `/payroll` is unaffected. Landing destination unchanged:
`resolve_landing_flags` returns `has_mywork=false, has_beyond=true`, which is `/profile`, where
`has_beyond=true` already sent her. Confirmed again after the migration, impersonating her: the
three gone, the rest kept.

So she lost `/my-work` and the ability to confirm her own delivery of a workshop she does not
deliver. **Not touched:** her ten other roles, including the two finance ones that let her close the
month.

**Blocked on:** nothing. Both decisions were made and applied 2026-10-16.
**Re-verify when:** a test account gains a payroll-capable role, or `seed.sql` adds one — the
question to ask is *"can it sign in?"*, which `is_test_account` does not answer.
**Lives in:** `supabase/migrations/202610160002_revoke_payroll_roles_from_signed_in_test_accounts.sql`,
`supabase/migrations/202610160003_revoke_anka_orban_trainer_roles.sql` (+ both rollbacks), and the
six re-pointed `scripts/verify_*.sql`; measured live against `user_org_roles` / `auth.users` /
`admin_rates` / `suppliers`. Item 138 below (the `ateliere` label that caused this question). Item 136 above (the sums that made this worth asking), item 18 below
(`is_test_account = false` does not mean a real person), item 95 above (Luiza's deliberate absence),
item 130 above (grade *and* admin rate on one person), item 128 above (the admin rates and the
uplift), item 122 above (a slot is a plain FK with no role requirement).

---

### 138. `admin_rates.task_category = 'ateliere'` means administrative work ON workshops, not workshops taught — a label that already misled once, on the day it was read

2026-10-16. The three categories in `public.admin_rates` are **`admin`**, **`ateliere`** and
**`financiar`**. Only one of them is named after the thing it is *about* rather than the work it
pays for, and that one is wrong in the obvious reading:

> **`ateliere` is administrative work ON workshops — organising them, and sales. It is NOT workshops
> delivered.** Anca, 2026-10-16.

**It misled within hours of being read.** Investigating why Anka Orban holds trainer roles with no
trainer grade (item 137 above), this session found her `admin_rates` rows — `admin` 80, `ateliere`
80, `financiar` 90 — and reported the `ateliere` row as evidence of *"a second pay path for
workshops that app.calculate_session_pay does not know about"*. Mihai asked Anca rather than
accepting it. There is no second path: she does not deliver workshops, the row pays her for
administering them, and the function is complete as written. Had the inference stood, the next move
would have been to make `calculate_session_pay` consult `admin_rates` — wiring an administrative
hourly rate into workshop pay, for a person who teaches nothing.

**Why this is worth a register entry rather than a column comment.** The label is not wrong in
context — `202610120011`'s own header says it plainly (*"ateliere is workshop organisation plus
sales"*), quoting Anca's 2026-08-07 answer. The failure mode is that **nobody reads a table's
creating migration before reading its rows.** A category value is read in a query result, next to a
number, with no header in sight; `ateliere` beside `80` reads as *"workshops, 80 lei"*. This is item
131's shape — a label repeated often enough reads as sourced — except here the label was accurate
from the start and still produced a false inference, because the word is the name of a different
thing in the same system. `groups.delivery_format` and `sessions` are *about* ateliere; this column
is not.

**The two facts that disambiguate it, for whoever reads this next:**
- `admin_rates.rate_kind = 'hourly'` for all three of Anka's rows. Workshop pay is never hourly in
  this system — it is grade rate × duration multiplier × bonuses, per workshop
  (`202609250001`), and the duration multiplier exists precisely because a 2-hour workshop is
  **1.5×**, not 2×. An hourly row cannot be workshop delivery pay.
- Workshop delivery pay requires a `trainer_grade_assignments` row, and
  `app.calculate_session_pay` never reads `admin_rates` at all — by construction, not by omission.
  A person with an `ateliere` admin rate and no grade is unpayable for a workshop, and that is
  correct.

**Not renamed.** `task_category` is CHECK-constrained to these three values and
`app.resolve_admin_rate` resolves on them; a rename is a migration plus a resolver change plus the
hours-entry screen that does not exist yet (item 130 above). The cost is not the problem — the
problem is that renaming it to something like `ateliere_admin` would be the third name for this work
in a system that already has Anca's own words for it, and the right moment to settle the vocabulary
is when that screen gets built and someone has to label the dropdown. **Recorded here so the next
reader does not repeat the inference**, and flagged as a decision for the hours-entry screen rather
than as a defect.

**Blocked on:** nothing. This is a note, not work.
**Re-verify when:** the hours-entry screen (item 130 above) is built — that is when the label stops
being read only in query results and gets shown to a person, and when a rename should be decided
rather than deferred again.
**Lives in:** `supabase/migrations/202610120011_create_admin_rates.sql` (the header that already
said this), `supabase/migrations/202610120012_seed_admin_rates.sql`; item 137 above (the inference
this corrects), item 131 above (the same class of label failure), item 130 above (the screen that
will have to name this work out loud), item 128 above (the rates themselves and the 11% uplift).

---

### 139. The application cannot record that a workshop did not happen — no RPC, no grant, no path at all. Six real cases a year on two groups of one school

2026-10-16, found while preparing the 2026-2027 schedule import, and bigger than the import.
Verified at both levels Mihai asked about, because "no table grant" and "no sanctioned function"
are different claims and only the second one was still open.

**The complete write surface on `public.sessions` after a row is created.** Every `app.*` function
whose body mentions `public.sessions` was pulled from `pg_proc` and its `UPDATE ... SET` clause
extracted — not read from memory, not inferred from the actions layer:

| Function | Writes |
|---|---|
| `rpc_confirm_session_attendance` | `trainer_principal_confirmed_at` **or** `trainer_secundar_confirmed_at` (the caller's own slot) |
| `rpc_correct_session_confirmation` | both confirmation timestamps |
| `rpc_update_session_allocation` | `trainer_principal_id`, `trainer_secundar_id` |
| `rpc_update_session_attendance` | `attendance_count`, `experiment_delivered` |
| `calculate_session_pay`, `calculate_org_session_pay` | read only |
| `rpc_propose_session_lesson_plan` | reads `sessions`; its `status =` writes `session_lesson_plans`, a different table |

**Six of eighteen columns.** Never written after creation by any sanctioned path:
`session_date`, `start_time`, `duration_minutes`, `location_tier`, **`status`**, `notes`,
`experiment_drive_link`, plus the keys and timestamps. **No function deletes a session.** And
`authenticated` holds `INSERT, SELECT` only — no `UPDATE`, no `DELETE` — so the RLS UPDATE policy
that does mention `sessions.create` is unreachable for want of a column grant. `app_write_owner`
(the role the DEFINER functions run as) has UPDATE on all 18 columns and none of them sets `status`.

**So `status = 'cancelled'` exists in the CHECK constraint and nothing in the system can ever set
it.** A workshop that was cancelled, replaced by a school trip, lost to a parents' evening or a
short day is recorded, permanently, as a workshop that is going to happen. The only route is
`service_role` / `postgres` raw SQL.

**Six cases a year, on two groups of one school** (Mihai, from last year's centraliser). That is not
an edge case; at six schools it is a weekly occurrence.

**Why it has not hurt yet, and why that stops in November.** Pay is already safe by accident: pay
follows the confirmation timestamps, so an unheld workshop that nobody confirms is simply not paid
(Anca's rule, 2026-09-11). The damage is on the other side and in the reading:
- **The client invoice.** Avenor and Scoala Germana are priced **per group per session** (700 and
  770 + VAT), Lycée **per child per session**. A cancelled session must not be billed. Counting it
  as held is ~700–770 RON of error each time — around 4,200–4,620 RON a year for those six cases,
  from a screen that is being built to be the source of truth for exactly that count.
- **The list Anka has to clear.** An unheld workshop sits in `/payroll`'s unconfirmed-slot list
  forever, indistinguishable from "held, and the trainer forgot". The one signal the schema can
  express — `attendance_count = 0`, writable via `rpc_update_session_attendance` — means *zero
  children present*, not *cancelled*, and `calculate_session_pay` never reads it, so a confirmed
  cancelled workshop still computes full pay for both trainers.

**Why this is a design question and not a missing CRUD endpoint.** Convention 12 is explicit: where a
table already has a status value meaning "no longer active, keep the row and its history", a
hard-delete feature is a second contradictory answer and must not be built. `sessions.status` has
`'cancelled'` for precisely that purpose. So the shape is not "add DELETE" — it is a narrow,
audited `rpc_cancel_session(p_session_id, p_reason)` that sets `status = 'cancelled'` and nothing
else, in the column-narrowed DEFINER style item 91 established for every other session write. The
open questions are **who** may call it (Operations allocates and substitutes; Anka closes the
month), whether a cancelled workshop may still be confirmed and paid (a trainer who travelled to a
school that cancelled on the day is a real case, and Anca's *"not paid for a workshop they did not
deliver"* does not obviously answer it), and whether cancelling after the month is closed is
allowed.

**A related asymmetry, recorded here because it is the same surface.**
`rpc_confirm_session_attendance` (the trainer's own) refuses once the month is closed, returning
`month_closed`. `rpc_correct_session_confirmation` (Operations') has **no such gate** — it checks
`is_platform_owner` / `org.settings.manage` / `finance.operations.*` and writes. So Operations can
confirm, or un-confirm, a workshop in a month that is already closed, which is the one thing
closing a month is meant to prevent. Mihai's decision 2026-10-16: **leave it**, note it. It is
plausibly correct — corrections are Laura's and Anka's job (Anca, 2026-09-11) — but it is nowhere
written down as a decision, and the trainer-facing gate's existence implies the other one was
meant to exist too.

**DECIDED 2026-10-16, Mihai — two of the four questions, and the shape is now fixed.**

**1. The reason is a CATEGORY plus optional free text, never free text alone.** The categories come
from last year's real data, where the six cases fall into two causes with opposite consequences:

| category | covers |
|---|---|
| `scoala_a_anulat` | excursion, parents' evening, short day, school closed |
| `trainer_indisponibil` | did not arrive, illness, traffic |
| `vacanta` | a day from the school calendar |
| `alt_motiv` | free text **mandatory** |

The argument is not tidiness: **free text means Anka can never answer "how many times did Avenor
cancel this year"** — which is exactly the question you ask when renegotiating a per-session price.
A category answers it with a `group by`; a text column answers it with somebody reading 200 rows.
And the two main causes point opposite ways — one is the client's doing and bears on the invoice,
the other is ours and bears on the trainer.

**2. Cancelling does not touch pay.** Pay keeps following the confirmation timestamps, exactly as
now. The case of a trainer who travelled to a school that cancelled on the spot goes to Anca; if she
pays it, **how** it is recorded is a separate conversation, because confirming delivery of something
that was not delivered would mean paying correctly and recording falsely. That is the one thing this
function must not be allowed to become a shortcut for.

**The two questions left to me, with my answers.**

**Who may call it: `sessions.create` (plus `org.settings.manage` / platform owner), not the
trainer.** Mihai's leaning, and the schema already decided it — `202609150002`'s own fork decision
says *"`sessions.status` stays Operations' scheduling field, set at creation as today"*, and
cancellation is a fact about the schedule, not about delivery. So this is not a new authority, it is
the existing one applied: the same capability that may create a workshop may cancel it. Mihai's
reason stands on its own too — a trainer saying "it did not happen" is making an assertion, not
recording an observation, and has money on the client side of it.
**The handoff this creates is not friction to be removed — it is the system refusing to let Finance
guess.** `finance.operations.*` is deliberately NOT on that list, so when Anka meets an unheld
workshop while closing the month she has to ask Operations. That is the point. What she sees is
"not confirmed", which is **ambiguous between two different facts**: the workshop did not happen, and
the workshop happened and the trainer forgot to confirm. Operations knows which, because the school
tells *them*. A gate that let Finance resolve that ambiguity alone would be inviting a guess about
money.

**So if it bites, the repair is NOT to add `finance.operations.*` to the gate** — that is the
comfortable change someone will reach for in six months, and it widens an authority to save a
message. The repair is a button on the unconfirmed row that flags it for Operations, in the
application, so the handoff happens where the work is instead of over a phone. Written down here
specifically so the gate does not quietly widen out of convenience.

**Cancellable after the month closes: yes.** The month-close gate on
`app.rpc_confirm_session_attendance` exists because **confirmation is a pay input** — locking it is
what stops someone altering an invoice that has already been issued. Cancellation is explicitly not
a pay input (decision 2 above), so **the reason for that gate does not transfer**, and copying it
would be copying a rule without its argument.

That is the whole justification, and it is deliberately the only one. "Blocking it in the
application does not stop the problem, it only hides it" was also offered and is **rejected as a
reason**: it is true of practically any gate, including the one on confirmation that this system
rightly keeps, so it cannot distinguish the gates that should exist from the ones that should not.
**But** cancelling inside a closed month changes the *client* billing count for a month already
invoiced, so it must be visible rather than merely permitted: the UPDATE lands in `row_history` with
its actor automatically, and the closed-month view should say that a workshop in it was cancelled
after closing. That last part is a screen, not a function, and should ship with it.

**ANSWERED 2026-10-20** — see the revision below.

**REVISED 2026-10-20 — the pay rule was wrong, and `202610190001` is superseded before it ever shipped.**

Decision 2 above ("cancelling does not touch pay") is **withdrawn**. Anca's rule, verbatim: the
school gives notice and the trainer does not travel → **not paid**; the school gives notice and the
trainer travels anyway because they missed it → their mistake, **not paid**; the school forgets to
give notice and the trainer finds an empty room → **PAID**.

**So the determinant is not who cancelled — it is WHETHER THE SCHOOL GAVE NOTICE.** The categories
change accordingly:

| category | paid? |
|---|---|
| `scoala_a_anulat_anuntat` | no |
| `scoala_a_anulat_neanuntat` | **yes** |
| `trainer_indisponibil` | no |
| `vacanta` | no |
| `alt_motiv` | note required; decided by hand |

`202610190001` was applied (not pushed) with the four old categories and a header stating pay is
untouched. It is **superseded by a new migration rather than edited**, since it is already on the
database.

**(b) Paying without a confirmation is not a second source of authority — it is a second way of
recording the same fact.** The fact is *the trainer's time was spent*. The trainer asserts it by
confirming; Operations asserts it by cancelling with "the school gave no notice". **One fact, two
witnesses.** The rule, written once, in one place:

> **payable = confirmed OR (cancelled AND reason = `scoala_a_anulat_neanuntat`)**

**And the confirmation columns must NOT be reused for this case.** They already carry two documented
meanings — *"Pay follows this timestamp"* in one migration and *"when the trainer asserted delivery"*
in another. A third meaning ("or when Operations asserted the trainer's time was spent") makes the
column unusable for reasoning: nobody reading `trainer_principal_confirmed_at` could then say what it
attests. The cancellation row is the witness; the pay rule reads both.

**(c) The third display state is not a third state.** The function returns **0, with no
`reason_code`**. A calculable workshop never produces 0 — the smallest real product is a rate times a
multiplier times at least 1.00 — so **0 is unambiguously "a decided zero"**. The screen explains it
from the session's own cancellation data, which it already has.

`reason_code` stays **exclusively** for reasons that *block* the calculation: a failure, not an
answer. Mixing "could not be computed" and "computed, and the answer is nothing" into one field would
destroy the distinction the whole classifier exists to make — and would put a decided zero under
*"Gaps in the pay grid — not fixable from this screen"*, which is the opposite of true.

**BUILD ORDER — THIS GOES FIRST, and not because of the Tuesday morning.** Item 147's scale question
is settled, so the original reason to wait is gone. The new reason to go first is stronger:
**cancellation is the precondition for generating a schedule at all.**

The chain, which this item named without drawing the conclusion: a generated workshop is
**permanent** — no UPDATE, no DELETE, no reachable `cancelled`. That is why schedule generation was
held behind a holiday calendar: without one, generation would put workshops into school holidays and
nobody could remove them. **`rpc_cancel_session` dissolves that dependency.** Once a workshop can be
cancelled, one generated into a holiday is *repairable*, and the calendar stops being an absolute
precondition and becomes a quality improvement — it stops the mistake happening rather than being
the only thing standing between generation and an unfixable mess.

So the order is: cancellation, then generation, then the calendar when it can be obtained — rather
than calendar, then generation, with cancellation as a later nicety. Which is the reverse of how it
was queued, and the difference is that the first order can start today.

**Blocked on:** Anca's answer on the travelled-trainer case, and writing it. The function is ~40
lines in a shape this repo has written six times; the categories and the pay rule are decided.
**Re-verify when:** before the schedule import generates anything for the rest of the school year.
A generated workshop is permanent today — no UPDATE, no DELETE, no `cancelled` — so generation
without this is how 222 rows become 222 rows nobody can correct.
**Lives in:** nothing changed; measured live against `pg_proc`, `information_schema.table_privileges`
and `information_schema.column_privileges`. `supabase/migrations/202609220001_route_column_narrowed_writes_through_security_definer_functions.sql`
(the four writers and the style a fifth would follow); `docs/DATABASE_CONVENTIONS.md` §12 (why this
is `cancelled`, not DELETE); item 91's own report; item 140 below (the duration key, the other
import blocker found the same day).

---

### 140. The duration multiplier was never a rate per minute — so 45 minutes is a wrong lookup key, not a missing row

2026-10-16. Preparing the schedule import found that four of the six real groups have class lengths
the pay grid raises on: Avenor 15:15–16:00 and 16:15–17:00 are **45 minutes**, Scoala Germana
15:30–16:20 and 16:25–17:15 are **50**. Verified live: `app.resolve_duration_multiplier` raises for
both and returns 1.2 for Lycée's 90. **26 of the 38 retroactive workshops are unpayable**, with
`reason_code = no_duration_row`.

**The obvious fix is the wrong one, and the reason is in the numbers already in the grid.** Adding
rows for 45 and 50 was this session's first recommendation. Mihai refused it, correctly:

| minutes | multiplier | per-minute rate implied |
|---|---|---|
| 30 | 1.0 | 0.0333 |
| 60 | 1.0 | 0.0167 |
| 90 | 1.2 | 0.0133 |
| 120 | 1.5 | 0.0125 |

**The scale is not proportional to time.** If it paid hours, 120 would be 2.0 against 60's 1.0; it
is 1.5. The four values measure **the shape of the job** — the travel, the setup, the packing down,
all of which a 45-minute workshop incurs exactly as a 60-minute one does — not the minutes in the
room. A grid of per-length rows is therefore a **band table being read with an equality key**, and
adding 45 and 50 would make Avenor work and break the next school that schedules 55 or 80.

**The change is to the resolver, not to the data.** Ceiling instead of equality: the smallest band
greater than or equal to the actual length, raising only above the top band. The four rows are
untouched, and `duration_multiplier_rates_minutes_check CHECK (duration_minutes = ANY (ARRAY[30,
60, 90, 120]))` stays as it is — under the new reading that constraint stops being a list of
permitted lengths and becomes the definition of the bands, which is what it always was.

**Two things are broken, not one.** `sessions.duration_minutes` is a nullable `integer` with **no
CHECK constraint of any kind** — the database already accepts 45, and also −5 and 99999. The only
thing preventing a 45-minute workshop from being *recorded* is the `<select>` on the workshop form,
which offers 30/60/90/120 and nothing else. So today a real Avenor workshop cannot be entered at
all, and the fix for that is in the form, not the schema — though the absence of any range check is
worth closing in the same pass, since nothing stops a typo of 1200 from being stored and then
raising forever.

**Awaiting Anca:** the principle, stated as *"a 45-minute workshop is paid as a 60-minute one"*.
Everything above is engineering reasoning from the grid's own numbers; whether the band is the
intended business rule is hers.

**The migration plan, ready for when she answers** — five parts, in this order:

1. **`app.resolve_duration_multiplier`**: replace `and duration_minutes = p_duration_minutes` with
   the smallest available band `>= p_duration_minutes`, chosen **from the rows present in that
   version and context** rather than from a hardcoded list — because the
   `scoala_altfel_saptamana_verde` context has no 30 row, and a 20-minute workshop there must land
   on 60 rather than raise for a band that was never defined. Raise above the top band, with a
   message naming the length and the maximum.
2. **A consequence to decide, not to discover:** ceiling-from-available-rows **closes the 30-minute
   Scoala Altfel gap as a side effect** (30 would resolve up to 60), which is the live defect item
   136's raise-isolation case is built on. `no_duration_row` becomes reachable only above 120. That
   is an improvement and it invalidates a test fixture — `db/tests/payroll_org_session_pay.sql`
   block 2 needs a different unpayable case (a length over the top band, or a missing version).
3. **The reason_code classifier** in `app.calculate_org_session_pay` must change in the same
   migration: the new raise message will not match `'%minutes / context%'`.
   `db/tests/payroll_reason_code_coverage.sql` will fail loudly if it is forgotten — which is the
   first real use of that test, and the reason it was derived from the sources rather than written
   by hand.
4. **The form's duration control**: either widen the `<select>` to the real lengths in use, or
   replace it with a number input. A number input is the honest control once the resolver bands,
   and it makes the missing range CHECK matter.
5. **A CHECK on `sessions.duration_minutes`** — a sane floor and ceiling. Not required by the
   banding, but the banding is the moment someone first types a free-form number into that column.

**BUILT 2026-10-16 (`202610160004`), without waiting for Anca** — Mihai's correction, and it is
right: the lookup and the rows are independent decisions. If 45 is paid as 60 it falls in the 60
band; if 45 ever earns its own rate someone adds a 45 band and it hits exactly, while 50 still lands
on 60. Her answer decides whether rows are added, not how they are found.

Verified live across the real schedule and both edges: 45 -> 1.0, 50 -> 1.0, 90 -> 1.2, exactly 60
-> 1.0, exactly 120 -> 1.5, 121 and 150 -> raise. The 30-minute Scoala Altfel gap closed as
predicted (resolves up to the 60 band), and a 20-minute workshop in that context resolves to 60
rather than raising for a 30 band nobody defined.

All five planned parts shipped: the resolver, the classifier in the same migration, the test fixture
moved to a 150-minute workshop, the form's number input (`202610160006` + the control), and the
range CHECK. **Step 3 of the plan paid for itself immediately**: the removed
`'%minutes / context%'` branch would have matched nothing, and
`db/tests/payroll_reason_code_coverage.sql`'s reachability assertion was shown to fail and name it
when the stale pattern was injected back — the first real use of that test, and it worked in the
direction the sabotage block does not cover.

One decision made while building and not in the plan: the range CHECK is **15..480**, with its
ceiling far above the grid's top band of 120 on purpose. A workshop longer than the grid prices must
stay **recordable and merely unpayable**.

**That has been promoted out of this item into `docs/DATABASE_CONVENTIONS.md` §14**, because it is
not a note about one CHECK — it is the rule *the schema records what happened; the grid decides what
gets paid*, and it is the same principle as §13's "a raise does not take the month down" one layer
lower. It lives in the conventions so that the next person who thinks about tightening a CHECK to
match a configuration table runs into it before they do, rather than finding it in a migration
header for a column they are not reading.

**Blocked on:** nothing. Anca's answer now only decides whether a 45 band is added, which is a row,
not a change.
**Re-verify when:** a new school's schedule arrives with a length not in 30/60/90/120 — under the
banded resolver that is no longer an event, which is the point.
**Lives in:** nothing changed. `supabase/migrations/202608310002_payment_config_tables.sql` and
`202609210006_migrate_groups_delivery_format_to_nine_workshop_types.sql` (the resolver's two
definitions), `supabase/migrations/202609240001_seed_pay_grids_pfa_inclusive_rates.sql` (the four
values and their provenance), `app/(app)/groups/[id]/group-detail-client.tsx` (the select);
item 95 above (the grid), item 136 above (the test fixture this invalidates), item 139 above (the
other import blocker found the same day).

---
### 141. Client price and billing entity have no effective date — recorded because Avenor's case dissolved, not because it was solved

2026-10-16. Avenor changed two things mid-year: the price (950 + VAT → 700) and the invoicing entity
(Experimente Wow → Brandine). Both looked like they needed effective-dating, and
`contracts.billing_rule` is a single free-text column while `contracts.legal_entity_id` is a single
FK — editing either rewrites the whole school year, so September's invoices would read as Brandine's
when Experimente Wow issued them.

**Anca's answer removed the case rather than the gap.** The renegotiation is **retroactive**: 700
applies from **2026-09-01**, and 700 carries **no VAT** because Brandine is not VAT-registered. Price
and entity are one decision, from one date, which is the contract's own `period_start`. So Avenor is
**one** contract with corrected values — Brandine, 700 without VAT, 2026-09-01 → 2027-06-30 — and
nothing needs two prices over two intervals.

**`amends_contract_id` was therefore NOT built**, on Mihai's instruction, and that is the right
call: `supplier_contracts` already has the column and the chain shape, so copying it to `contracts`
is a small migration — but building a mechanism for a case that no longer exists is how a schema
accumulates structure nobody can later justify. Recorded here so the next mid-year change does not
start from scratch.

**What the gap actually is, for when it returns:**
- `contracts.billing_rule` is **free text**, never parsed, read only through the masked view. The
  amount, the currency, the VAT treatment and the unit all live inside one string — so even after
  Anca's answer, *"700 without VAT"* is a sentence, not two fields, and nothing can compute from it.
- `contracts.offer_structure` is a four-value enum that **cannot distinguish Avenor from Scoala
  Germana** — both carry `fixed_price_group_workshop`, though one is per group and the other per
  group **per session**. Lycée's `105 lei/copil/ședință`, the one case the enum could express
  (`price_per_child_present`), has it **unset**.
- `contracts` has `renewal_of` (year to year) and **no `amends_contract_id`** (within a period).
  `supplier_contracts` has both. The asymmetry is unexplained by anything written down.
- **No indicator that an invoice requires an attendance list.** Lycée's does. The enum's
  `price_per_child_present` vs `_enrolled` distinction *is* that question, and it is unset.
- **No column anywhere holds a contractual cap on children.** Scoala Germana's contract caps a group
  at 12; searched every table for `max`/`cap`/`capacity`/`limit`/`seats` — only
  `admin_rates.tier_max_words` and the two child counters exist. `groups.children_confirmed` and
  `children_billed` are counts, not ceilings, and both are null on the two live groups.

**The Avenor contract was corrected 2026-10-16 (`202610160007`)**: Brandine Advertising SRL,
`700 RON fără TVA/grupă/ședință`, period unchanged at 2026-09-01 .. 2027-06-30. One contract, stale
values replaced — not an amendment chain, because Anca's answer made it one decision from one date.
`offer_structure` stays `fixed_price_group_workshop`, wrong in the same way it is wrong for Scoala
Germana, because there is no better value to move it to and swapping one inaccuracy for another
helps nobody. The VAT treatment is in the free text because there is nowhere else for it — which is
this item, unchanged.

**Blocked on:** nothing, deliberately. This is the record, not the work.
**Re-verify when:** a client price or invoicing entity changes **from a date inside a contract's
period** — the first such case is the one to build for, and the supplier side's
`amends_contract_id` is the shape to copy. Also when the invoicing generator (`phase1-development-plan.md`
row 11, still 🔴 Nefăcut) is started, because that is when free text stops being survivable.
**Lives in:** nothing changed. `supabase/migrations/202608160002` (the `offer_structure` enum),
`supabase/migrations/202610120009_create_supplier_contracts.sql` (`amends_contract_id`, the shape to
copy); item 127 above (the supplier register's rate-vs-value argument, the same free-text
precedent), item 133 above (the supplier screen showing a price that contradicts the current grid).

---

### 142. Roles have drifted from what people actually do, in both directions — a review of all 16 real people, not of the two that surfaced

2026-10-16, opened by Mihai as a standing item rather than a task. Two cases turned up within a day
of each other, pointing opposite ways, which is what makes it a review and not two fixes:

- **Anka Orban held Trainer and Senior Trainer and delivers no workshops.** Removed 2026-10-16
  (item 137 above). Her `ateliere` admin rate is administrative work *on* workshops (item 138
  above).
- **Cătălina Trușan delivers four of the six real groups and does not hold Trainer.** She has
  Curriculum Manager + Evaluator + Operations Manager, and grade 6 from 2026-09-01. Pay works
  regardless — a workshop slot is a plain FK with no role requirement — but
  `trainerOptions` on the group screen is built by filtering `user_org_roles` on the role keys
  `trainer` and `senior_trainer`, so **the person who teaches most of the school year does not
  appear in the trainer dropdown** and cannot be allocated through the UI. Worse, and less
  visible: `app.rpc_confirm_session_attendance` requires `mywork.*`, which only the trainer roles
  grant her — so **she cannot confirm her own delivery**, and every one of her workshops would have
  to be confirmed by Operations on her behalf.

**Measured, for the Cătălina case, before proposing it** (simulated in a rolled-back transaction):
adding Trainer gives her four capabilities she lacks — `community.read`, `finance.own.read`,
`materials.custody` (all three with **zero policies and zero code references**, inert today) and
**`mywork.*`** (8 policies across 7 tables). It gives her **no additional visibility**: rows
readable before/after are identical on all seven of those tables (sessions 0/0, groups 2/2, clients
3/3, client_contacts 4/4, users 38/38, session_lesson_plans 0/0, payroll_periods 0/0), because her
Operations Manager grants already cover more broadly than the own-slot branches do. Landing
destination unchanged: `has_mywork=true, has_beyond=true` resolves to `/profile`, as before. So the
role adds exactly the two things she needs — `/my-work` and the ability to confirm her own
workshops — and nothing else.

**The general shape, which is why this is an item and not a ticket.** Role grants in this org were
created across several sessions, some by `seed.sql`, some through `/admin/users`, some to make a
verification script work. Nothing has ever reconciled them against what each person does.
`user_org_roles` has `assigned_by`, and for every test fixture it is **null** — so there is no actor
to ask. Anka alone holds **twelve** roles. The review is: for each of the 16 non-test people in
`wow-lab`, what roles they hold versus what they do, and in particular whether anyone else is in
Cătălina's position (doing the work without the role, which is invisible until a dropdown is empty)
or Anka's (holding a role for work they do not do, which is invisible until it grants something that
matters — as `mywork.*` on a payroll screen nearly did).

**Deliberately not a capability-model change.** Convention 6 says roles and capabilities are data,
not enums, and that application code must never hard-code a role name to gate a feature. The
trainer dropdown filtering on the role keys `trainer`/`senior_trainer` is arguably exactly that —
but the alternative (filtering on `mywork.*`, the capability that means "has own work") would change
who appears in a dropdown on a screen Operations uses daily, and that is a separate decision from
fixing the grants.

**The Cătălina grant was applied 2026-10-16 (`202610160005`)**, with the measurements above as its
justification and the decisive argument being the one that was not about dropdowns: she could not
confirm her own delivery. Verified after: roles are Curriculum Manager + Evaluator + Operations
Manager + Trainer, `mywork.*` true, she appears in the trainer dropdown, no stray role-less row. The
migration refuses to run if she has no grade effective on or before 2026-09-01 — making someone
selectable but unpayable would be worse than leaving them unselectable.

**A RULE THAT CAME OUT OF THIS ITEM SIDEWAYS, 2026-10-20 — how to pick the subject of an
authorization test.** `db/tests/cancel_session_pay_rule.sql` was written to assert that
`finance.operations.*` is NOT on `app.rpc_cancel_session`'s gate, and it chose **Anka Orban** as the
subject because she is the Finance person. It failed — she also holds **Operations Manager**, so she
has `sessions.create` and legitimately succeeds. Worse, because her cancellation went through, the
two checks after it then failed on an already-cancelled session: **one mis-chosen subject produced
three red assertions, none of which was about the gate.**

> **An authorization test that picks its subject by role name tests the name, not the gate.** The
> subject is chosen by **measured capability** — query who actually holds the capability under test
> and, crucially, who holds it *without* the others — not by who has the job title that sounds right.

**Laura Moale** is the person who holds `finance.operations.*` **without** `sessions.create`
(Contract Administrator + Finance Operations), and the test now uses her. The converse is asserted
too, pointing back here: Anka *can* cancel, via Operations Manager rather than via Finance, and
that is this item's subject rather than a gate defect.

This generalises past one test. In an org where one person holds **twelve** roles, "the Finance
person", "the Operations person" and "the trainer" are not capability statements — they are
descriptions of people whose grants have drifted. Any test written against them is a test about
today's accidents.

**Blocked on:** nothing; the review itself is the open work.
**Re-verify when:** a real person is added to the org, or a verification script needs a role — the
second is how `test+ui-owner` ended up with Organization Owner in production (item 137 above).
**Lives in:** nothing changed. `app/(app)/groups/[id]/page.tsx` (the `trainerOptions` role filter),
`supabase/migrations/202609220001` (`rpc_confirm_session_attendance`'s `mywork.*` gate);
item 137 above (Anka, the other direction), item 138 above (the label that explained her),
`docs/DATABASE_CONVENTIONS.md` §6 (roles are data, not enums).

---

### 143. The trainer selector knows the workshop's date and ignores it — the role is global, the grade is dated, and selectability belongs to the date

2026-10-19, generalised out of a guard rather than found as a bug. `202610160005` (granting Cătălina
Trușan the Trainer role) refuses to run unless she already holds a grade effective on or before
2026-09-01, on the reasoning that *making someone selectable but unpayable is worse than leaving
them unselectable*. That guard is right and it is in the wrong place: it protects one migration on
one date for one person, when the thing it implies is a rule about the selector.

**The mismatch.** `trainerOptions` on the group screen is built by filtering `user_org_roles` on the
role keys `trainer` / `senior_trainer` — a **global, undated** question. But pay needs
`app.resolve_trainer_grade(trainer, session_date)`, which is a **dated** one:
`trainer_grade_assignments` carries `effective_from`, and the resolver takes the workshop's own date
as `p_as_of`. So the two disagree by construction:

- A trainer whose first grade starts 2026-11-01, allocated to a workshop on 2026-09-15, is offered
  in the dropdown and produces `reason_code = no_grade` — on a date they were never graded for,
  while being perfectly payable three weeks later.
- The reverse exists too: Cătălina was **unselectable while fully payable**, for three weeks, which
  is what `202610160005` fixed by granting the role. Had the selector asked the dated question, the
  role would have been irrelevant to her selectability.

**The rule.** *Who may be put in a slot is decided by whether they have a grade effective on that
workshop's date, not by whether they hold a role today.* The form already knows the date — it is the
first field in it — so this costs a `where effective_from <= <the date in the form>` and a re-fetch
when the date changes, not new data.

**Why it is not simply "filter on `mywork.*` instead".** That was the first idea and it is a
different fix to a different problem. `mywork.*` is still global and still undated; swapping one
undated predicate for another would keep the defect and merely change who it mis-lists. It would
also entangle this with convention 6 (*application code must never hard-code a role name to gate a
feature*), which the current role-key filter arguably violates — a real objection, but a separate
one, and fixing selectability by date happens to dissolve it: the selector would be keyed on a dated
grade, which is data, rather than on a role name at all.

**What this is not.** Not a pay-model change: `app.calculate_session_pay` already does the dated
thing correctly and needs nothing. Not an authorisation change: a workshop slot stays a plain FK to
`users` with no role requirement (item 122), so the database keeps permitting what the form would
stop offering — which is the right division, since a date-driven dropdown is help, not enforcement.

**Blocked on:** nothing but a decision to do it. One screen, one predicate, one re-fetch.
**Re-verify when:** a trainer joins mid-year, or a grade is backdated — both make the undated
selector wrong in a way nobody will notice until a `no_grade` appears on `/payroll` for someone who
is obviously a trainer. Lorina Ciurusniuc is the live instance in waiting: she took Scoala Germana
over from Teodora mid-year, so her grade's `effective_from` and the handover date are the same
question, and the workshops before it are Teodora's.
**Lives in:** nothing changed. `app/(app)/groups/[id]/page.tsx` (the role-key filter),
`supabase/migrations/202610160005_grant_catalina_trusan_trainer_role.sql` (the guard this
generalises), `supabase/migrations/202608310002_payment_config_tables.sql`
(`app.resolve_trainer_grade`, the dated question); item 142 above (the role drift this is the
selector-side half of), item 122 above (a slot is a plain FK), `docs/DATABASE_CONVENTIONS.md` §6.

---

### 144. The location bonus belongs to the school, and the application asks the trainer — proved on 345 real rows before importing a single workshop

2026-10-19, found by reading the real payroll sheet ("New Wow Lab Trainer Calculations Table") against the schema. A money error on every workshop, in the direction of underpaying.

**Where the application gets the location tier today.** `sessions.location_tier`, a per-session text column, CHECK-constrained to `bucuresti` / `imprejurimi` / `alte_orase`, **typed by hand in the workshop form**. `app.resolve_location_bonus` reads nothing else. The only automatic input is a prefill in `group-detail-client.tsx` which sets `bucuresti` **only when** `trainer_home_cities[principal] = 'bucuresti'` **and** the group's address contains "bucur", and otherwise **clears the field**. `trainer_home_cities` (11 rows) feeds that prefill and nothing else — it has no part in the calculation.

**So the model is trainer-and-school. The process is school alone.** Measured across 1,416 timesheet rows:

| school | trainers | locations recorded |
|---|---|---|
| FUNDATIA LYCEE FRANCAIS ANNA DE NOAILLES | **12 different** | Surroundings 128, Bucharest 1 |
| SCOALA GIMNAZIALA "AVENOR" | **6 different** | Surroundings 161, Bucharest 5 |
| DEUTSCHE SCHULE BUKAREST DSBU SRL | 4 different | **Bucharest 44**, Surroundings 6 |

**The decisive test is not the majority, it is where the minority sits.** If location depended on the trainer, each trainer would be internally consistent and differ from the others. The opposite holds: Cătălina Trușan has both Surroundings (2) *and* Bucharest (1) at Lycée; Andreea Tudor is 5/5 at Avenor; Teodora Merișan is 39 Bucharest / 6 Surroundings at DSBU. **Same person, same school, two answers** — which rules out trainer-dependence and marks the minority as typing errors in a hand-filled column. 10 of 31 schools carry more than one location.

The authoritative mapping (sheet "Mapari Tip Trainer", columns *Denumire Scoala / CUI / Locatia*) agrees and is school-keyed: `18153988` → Surroundings, `RO37336710` → Surroundings. Bonuses: Bucharest 0%, Surroundings 25%, Other cities 100%.

**The import consequence is worse than a wrong default.** Both Lycée groups and both Avenor groups have `address = NULL`, so the prefill **never fires at all** and the field opens empty — 38 workshops, 38 manual choices, no guidance, and `bucuresti` is the plausible wrong pick for a Bucharest-*area* school tariffed at Surroundings. At grade 6 that is 150 × 1.2 × 1.00 = 180.00 instead of 150 × 1.2 × 1.25 = **225.00**: 45 lei short per workshop, per trainer.

**The faithful model** is a location tier on the client (or the group), resolved from there, with the session column kept only as a per-workshop override for the genuine exceptions — `Scoala Altfel`, `Saptamana Verde` and `Wow Lab Party` rows in the sheet really do vary by venue, which is why the column should not simply be deleted. `clients.address` already exists and `clients` already carries the CUI the mapping is keyed by.

**SCOALA GERMANA'S TIER IS UNRESOLVED, and that is a finding rather than a gap in the search.** CUI **44600473 appears nowhere** in the sheet (all 1,045,664 characters searched). The German school present is **DEUTSCHE SCHULE BUKAREST DSBU SRL**, which carries **no Tax ID on any of its rows** and is **absent from the mapping sheet entirely**. By practice it is **Bucharest, 0%** — the opposite of the other two. So the identification is **by name only** and needs Anca: is DSBU SRL our *Scoala Germana* (CUI 44600473), and is its tier really Bucharest?

**A second discrepancy inside the same number, worth separating out.** The sheet's grade-6 rate is **135**, not our 150, and its own total for 1.5h at Surroundings is **202.50**, not 225.00:

| grade | sheet "Cost Total Net" | our `trainer_grade_rates` |
|---|---|---|
| 1 Junior | 100 | 111 |
| 2 Rising Star | 107 | 119 |
| 3 Enthusiastic Mid | 114 | 127 |
| 4 Experienced Mid 2 | 121 | 134 |
| 5 Magic Senior 1 | 128 | 142 |
| 6 Glowing Senior 2 | 135 | 150 |

Ours is the sheet **× 1.11, rounded** — which confirms item 95's PFA-inclusive uplift and item 128's 11% from the source for the first time. Both figures are right on their own basis and they are 11% apart. **Anka must not compare them directly:** checking our 225.00 against last year's 202.50 reads as a 22.50 overpayment when it is the uplift working as designed.

**THE MODEL IS APPROVED, 2026-10-20: tier on the client, the session column kept as an override.**

**And the FORM OF THE PROOF is the part to carry forward, not just its conclusion.** The table above
shows 128-vs-1 and 161-vs-5, and a majority is not an argument — it is a vote, and a vote about
somebody else's data proves nothing about the rule that generated it. What settles it is **where the
minority sits**: Cătălina Trușan recorded both Surroundings *and* Bucharest at Lycée; Andreea Tudor
is 5/5 at Avenor; Teodora Merișan is 39/6 at DSBU. **The same person, at the same school, with two
different answers.** If location were a function of the trainer, that is the one thing that could not
happen. So trainer-dependence is **excluded**, not outvoted — and the minority values are
identifiable as typing errors rather than merely outnumbered.

The general rule, for next time: to disprove *"X depends on Y"*, do not count how often X agrees
with Z. Find a single Y whose X varies with Y held constant. One such case ends the question; ten
thousand majority rows do not.

**An unnamed consequence, now named: `trainer_home_cities` becomes dead.** Once the tier comes from
the client, that table has **no consumer left**. Confirmed exhaustively rather than assumed — its
only reader is a single chain: fetched in `app/(app)/groups/[id]/page.tsx` (line ~365), passed
through `group-detail-client.tsx`, and consumed at one line (~1067) by the `location_tier` prefill
and nowhere else. No RLS policy references it, no database function reads it, and
`app.resolve_location_bonus` takes the tier as an argument and never looks a city up. **It is marked
dead here and deliberately NOT dropped in the same migration as the model change** — a table and its
last caller should not disappear in one step, because that leaves nothing to roll back to if the
client-side tier turns out to need a per-trainer exception after all.

**DSBU'S TIER IS CONFIRMED 2026-10-20 — Bucharest, 0%, and the question to Anca is closed.** Read
off real timesheet rows rather than inferred from the name match: Teodora Merișan at DSBU on
16.09.2026 and 23.09.2026, **Bucharest, 114,00 lei with no location bonus**, and Lorina Ciurusniuc
at DSBU on 30.09.2026, **Bucharest, 107,00**. The school is paid at 0% while Lycée and Avenor are
paid at 25%, which is what made this worth asking rather than assuming — three schools in the same
city, two tariffed as Surroundings and one as Bucharest. It stays absent from the mapping sheet and
still carries no Tax ID, so the mapping tab is incomplete; the timesheet is the authority here.

**ROW 63 IS CLOSED FROM DATA, 2026-10-20.** Laura asked in July: *"Păstrăm distincția Surroundings/Other City dacă încă se aplică?"* — and it was still listed as an open question while this item spent a week proving which entity the tier belongs to. **It applies.** Both non-zero tiers appear on rows paid up to and including 2026-10-12:

- **Surroundings, 25%** — Teodora Merișan, Wow Lab Party, 19.09.2026: `135,00 lei` base with a 25% location bonus, total `142,50`.
- **Other cities, 100%** — Alexandra Nuțu, Scoala Altfel, 12.10.2026: `114,00` base at 100%, total `228,00`. That row is also the most recent in the entire timesheet.

So the three-tier scale is live, not legacy, and `location_bonus_rates`' 0 / 25 / 100 is correct as seeded. Recorded as **a verified fact rather than an open question** — the question was answerable from rows that already existed when it was asked.

**Blocked on:** nothing. The model change is blocked on nothing but a decision.
**Re-verify when:** before any workshop is imported. Every imported row carries whatever tier the person typed, and `location_tier` is write-once (item 139) — a wrong tier cannot be corrected through the application.
**Lives in:** nothing changed. `app/(app)/groups/[id]/group-detail-client.tsx` (the prefill), `supabase/migrations/202608310002_payment_config_tables.sql` (`resolve_location_bonus`); item 95 above (the uplifted grid, now confirmed against its source), item 128 above (the 11%), item 139 above (why a wrong tier is permanent), item 143 above (the other thing the selector asks wrongly).

---
### 145. Grade 7 "Lesson plan writer" cannot be represented, and lesson-plan writing has no home

2026-10-19. The real payroll sheet pays a seventh trainer classification: **`7 / Lesson plan writer / 120,00 lei`**, recorded in the same timesheet with `School Name = "New Lesson Plan"`, `Tax ID = "-"`, duration 1 hour, location Bucharest, 0% bonuses. Observed writers: Diana Cocea, Diego Samayoa, Elena Bacalum.

**It is not merely unbuilt, it is unrepresentable.** `trainer_grade_rates_level_check CHECK (grade_level >= 1 AND grade_level <= 6)` — grade 7 cannot be stored in the pay grid at all, and `trainer_grade_assignments_level_check` has the same bound. And `sessions` is a table of workshops at schools: a lesson plan has no school, no group, no attendance, no location, and no trainer slot.

**It is also not a seventh rung on the same ladder.** The sheet's own increase column reads 0%, 7%, 14%, 21%, 28%, 35% for grades 1-6 and **0% for grade 7** — the six are a progression off a 100 lei base, while 120 is a flat rate for a different kind of work. Treating it as grade 7 in the grid would make `resolve_trainer_grade_rate` return it for a *workshop*, which is the one thing it must never do.

**Elena Bacalum is both** — grade 3 as a trainer and a lesson-plan writer in the same sheet. That is item 130's shape exactly (Cătălina holding a trainer grade and an admin rate), now with a third rate kind, and it is the reason the eventual hours-entry screen cannot key pay on the person.

**The nearest existing home is `admin_rates`**, which already holds hourly work keyed by (person, task category) with its own versioning — adding a `lesson_plan` category there is a smaller change than a seventh grade, and it keeps workshop pay and hourly pay in different tables, which is what they are. Not proposed as a decision; recorded as the obvious candidate.

**WORKSHOP TYPES RECONCILED 2026-10-20, and `New Lesson Plan` is the only gap.** Every non-school
value in the timesheet's School Name column, checked against `groups_delivery_format_check`'s ten
values:

| timesheet | rows | our `delivery_format` |
|---|---|---|
| `Scoala Altfel` | 174 | `scoala_altfel` ✓ |
| `ELECTRICA FURNIZARE S.A` | 150 | a corporate client → `parteneriate_companii` ✓ |
| **`New Lesson Plan`** | **134** | **none — this item** |
| `Saptamana Verde` | 59 | `saptamana_verde` ✓ |
| `Wow Lab Party` | 26 | `wow_lab_party` ✓ (it does exist) |
| `Universitatea Nationala de Stiinta si Tehnologie` | 13 | a client, not a format |
| `Other cities` / `00 lei` | 1 each | **data errors** — a location and a money value typed into the School Name column |

So the nine workshop types cover everything the timesheet records **except lesson-plan writing**,
which is this item. `Wow Lab Party` and `Scoala Altfel` were both already present — and both are
billed from Brandine at non-zero location bonuses (Surroundings 25% and Other cities 100%
respectively on the rows seen), which is a reminder that the location override on the session is
needed: these are venues, not schools, and their tier genuinely varies (item 144).

**Blocked on:** a decision about where this work lives. Not urgent — nobody is being paid through this application yet.
**Re-verify when:** the hours-entry screen (item 130 above) is designed, because that screen is where all three rate kinds meet.
**Lives in:** nothing changed. `supabase/migrations/202608310002_payment_config_tables.sql` (the 1-6 CHECK), `supabase/migrations/202610120011_create_admin_rates.sql` (the candidate home); item 130 above, item 138 above (the `ateliere` label, the same confusion from the other side).

---
### 146. Proposed Total Cost and Approved Cost do differ — so "calculated and displayed, never stored" is an incomplete scope decision

2026-10-19, and it contradicts a decision this project made deliberately. `/payroll` computes pay at read time and stores nothing, on the reasoning that a payments register was out of scope (item 136). The real process has an **approval step with two separate amount columns**, and they are not always equal.

**Measured, on the 1,417 rows readable through the Drive connector:**
- **11 rows where `Proposed Total Cost` ≠ `Approved Cost`** (~0.8%), every one of the shape **Proposed = 0,00 / Approved = the real figure** — the proposal was blank and the amount was entered by hand.
- **Five distinct approval statuses** beyond `Aprobat`: `Nu` (1), `De achitat` (1), `platit in martie` (2), `Verifica Statusul de Aprobare` (2). The column is free text in practice.
- One row carries status **`Nu`** with `Approved Cost = 133,75 lei` — a contradiction inside the source.

**The measurement is indicative, not exhaustive**, and the limit is stated rather than hidden: the connector truncated at ~1.04M characters, so this is **1,417 of ~10,954 rows**. The exact answer is two cells in the sheet:
`=SUMPRODUCT(--(R5:R10958<>S5:S10958))` and `=COUNTIF(T5:T10958,"<>Aprobat")`.

**CLOSED 2026-10-20 — the scope decision stands, and the earlier reading of these 11 rows was wrong.**

Anca's answer: **the approval does not overwrite the amount.** It withholds the approval until the
data is corrected, and `Approved Cost` is then **the same number** as the corrected proposal, not a
different one.

**The counts are corrected 2026-10-20, on Mihai's observation.** `Verifica Statusul de Aprobare`
appears on **exactly the two rows that have no date at all** — it is the sheet's placeholder for an
unfilled row, not a business state. Recounted over dated rows only: **1,446 dated, 2 undated**; the
**11 differing rows are all dated** (so that figure stands), and the real non-`Aprobat` statuses are
**three, not five** — `De achitat` (1), `Nu` (1), `platit in martie` (2). Nine of the 11 differing
rows are Teodora on 30.08.2026 at 120,00, which is the grade-7 lesson-plan rate (item 145), and one
is Alexandra Nuțu on 12.10.2026 at 228,00 (114 × 2.00, Other cities).

**That concentration weakens the register argument further, and is worth stating as such.** Nine of
eleven divergences sit in **lesson-plan writing** — the one domain this application does not model
at all (item 145), where there is no formula to collapse because there is no formula. So the
divergence is not evidence that a calculated figure needs a stored counterpart; it is evidence that
**a domain with no calculation was being recorded in a sheet built for one.** Of the two remaining
rows, one is a `Nu` status and one is a grade whose own value is in question (item 149 below). There
is no case left in which a working calculation produced one number and a human approved another.

And the 11 rows say so themselves, which the first reading of them missed. **All 11 are
Proposed = 0,00 / Approved = the real figure** — not "approved at a different amount" but *a formula
that collapsed to zero, with the amount typed in by hand*. In this application a calculation does
not collapse to zero: it **raises, with a named reason** (`reason_code`), and the screen shows the
reason instead of a number. The failure mode those 11 rows record cannot occur here.

So the scope decision — **the amount stays calculated, the register stays out of scope** — is
confirmed, and this is recorded with Anca's answer as the reason **so it is not reopened from
assumption in three months**. The reason is not the one offered earlier (*"it is a displayed
calculation, not a stored amount"*, which was a restatement of the decision rather than a reason for
it); the reason is that **the approval step never produces a second, different amount.**

**The approval statuses are a different matter and are split out into item 148 below.**
`platit in martie` and `De achitat` do not say *how much* — they say **whether the money moved**,
which is a process stage this application does not model at all, and not the same thing as storing
an amount.

**Blocked on:** nothing. Closed.
**Lives in:** nothing changed. Item 136 above (the scope decision this confirms), item 148 below
(the payment cycle, which is the part that is genuinely missing).

---

### 148. There is no payment cycle — owed / approved / paid is a missing domain, and it is not the same thing as storing an amount

2026-10-20, split out of item 146 above, because conflating the two is what made that item's first reading wrong. The *amount* question is closed: it stays calculated. This is the other half, and it is open.

The real timesheet's `Approval Status` column carries, beyond `Aprobat` and counting **dated rows
only**: **`De achitat`** (1 row), **`platit in martie`** (2), **`Nu`** (1). (`Verifica Statusul de
Aprobare` is excluded — it sits on the two undated rows and is the sheet's own placeholder, not a
state anybody chose.) Those three are not amounts and not approvals of amounts. *"Paid in March"*
and *"to be paid"* say **whether the money moved**.

**What the application has today:** nothing. `payroll_periods` records that a month was closed, by whom and when. `/payroll` computes what is owed. Between "the month is closed and this is owed" and "this has been paid" there is **no state at all** — no stage, no date, no actor, and nothing that could answer *"what is still unpaid from September?"*

**Why it is a domain and not a column.** The stages in the sheet are at least three (owed → approved → paid) and the real vocabulary is messier than that — `De achitat` is a *stage*, `platit in martie` is a stage **plus a date**, and `Verifica Statusul de Aprobare` is a *flag for a human* rather than a stage at all. A single text column is how the sheet ended up with five values that do not form a sequence, and copying that into a column here reproduces the problem rather than solving it. It needs a decided set of stages, a transition per stage with an actor and a date, and a rule about what may still change after each.

**It is also where the register question comes back, honestly this time.** A paid-ness stage needs to point at *a specific sum that was paid*. The moment that is recorded, the amount is stored — not because the calculation was insufficient but because **a payment is a historical event and a calculation is a current answer**, and the two cannot be the same field. So this domain and the payments register are one decision, not two, and item 146's closure does not pre-empt it: that closed *"does the approval produce a different amount"* (no), not *"does a payment need recording"* (unanswered).

**The trap to avoid**, stated because it is the cheap-looking move: adding `paid boolean` to `payroll_periods`. A month is not paid; **a trainer's invoice** is paid, and a trainer may invoice two entities for the same month (item 136's per-entity grouping exists for exactly that). Month-level paid-ness would be wrong on the first month Cătălina bills Brandine and Experimente Wow separately.

**Blocked on:** a decision that nobody needs yet — no money moves through this application. Worth settling before the first real month is invoiced, not before the import.
**Re-verify when:** Anka asks *"what is still unpaid"* and the answer is a spreadsheet. That is this item arriving.
**Lives in:** nothing changed. Item 146 above (the amount half, closed), item 136 above (per-entity grouping, which is what makes month-level paid-ness wrong), item 139 above (the other place where a stage was missing and the status column could not express it), `docs/phase1-development-plan.md` row 11.

---

### 149. Our grades are not stale — 10 of 11 match the timesheet, and the one that differs is not the one the mapping tab would have caused

2026-10-20. The worry was systematic: Alexandra Nuțu reads **grade 3** in the timesheet (12.10.2026) and **grade 1** in the mapping tab, so the mapping tab is behind — and if our ten assignments had been seeded from it, they were seeded from a stale source.

**Measured against the most recent WORKSHOP row per person** (lesson-plan rows and grade 7 excluded, because that is a different rate kind — item 145 — and Răzvan's latest row of any sort is a grade-7 one, which would have read as a six-grade discrepancy it is not):

| person | ours | timesheet | last workshop |
|---|---|---|---|
| **Alexandra Nuțu** | **2** | **3** | 2026-10-12 |
| Alina Garofil | 1 | 1 | 2026-06-08 |
| Andrada Eremia | 6 | 6 | 2026-06-17 |
| Cătălina Trușan | 6 | 6 | 2026-09-30 |
| Elena Bacalum | 4 | 4 | 2026-05-22 |
| Lorina Ciurusniuc | 2 | 2 | 2026-09-30 |
| Raluca Popa | 1 | 1 | 2026-09-08 |
| Răzvan Alexandru Bălașov | 1 | 1 | 2025-12-05 |
| Sonia Ganea | 6 | 6 | 2026-09-08 |
| Teodora Merișan | 3 | 3 | 2026-09-23 |
| Viorel Toboșaru | 2 | 2 | 2025-10-20 |

**One of eleven differs.** So the grades were **not** taken from the mapping tab: that tab says Alexandra is 1, we say 2, the timesheet says 3 — our value matches neither, and it matches the timesheet everywhere else. We are holding a stale intermediate for one person, not a stale source for all of them.

**Alexandra Nuțu has progressed 1 → 2 → 3** (the mapping tab's own `Data` column puts her at grade 1 from 18.11.2024). Ours says 2 effective 2026-09-01; the timesheet pays her 3 on 12.10.2026 — and the 228,00 on that row is 114 × 2.00 (grade 3's rate at Other cities), so the grade and the rate agree with each other there. Hers is the correction to make, with the effective date Anca gives for the promotion — and the date matters for the same reason Lorina's did: a grade effective too early calculates a workshop that should raise.

**Why this is worth recording even though only one row is wrong.** The check itself is the finding: *"which of our grades disagrees with what was actually paid"* is answerable in one pass over the timesheet, and nobody had run it. It should be re-run whenever the grid or the assignments are touched, because a grade that drifts does not fail — it quietly pays the wrong rate, and `/payroll` will show a confident figure either way.

**RESOLVED 2026-10-20 FROM THE TIMESHEET — it is a real promotion, derived, not asked.** Row 69 of
the feedback (Cătălina): *"Trainerul vede nivelul la care e încadrat. Trecere automată de nivel la
nr. ore prag (azi manual, Laura) — de automatizat."* A grade is **a crossed hours threshold**, not a
chosen date, so the question to Anca was the wrong instrument. Her 88 readable rows:

| grade | rate | from | to |
|---|---|---|---|
| 1 | 100 | 2024-11-18 | 2025-03-31 |
| **2** | **107** | **2025-05-05** | 2026-04-03 |
| (7) | (120) | 2025-07-07 | 2025-07-30 — lesson plans, a different rate kind |
| **3** | **114** | **2026-10-12** | (most recent row in the sheet) |

**The rate moves with the grade every time** — 100 → 107 → 114 — so each transition is corroborated
by the money, and this is a promotion rather than a transcription error.

**Our record is wrong in both directions:** we hold *grade 2 effective 2026-09-01*, but she had been
grade 2 since **2025-05-05** (so that effective date is sixteen months late) and was already being
paid as **grade 3 by 2026-10-12**. The second matters for the import, the first does not — the
import window starts 2026-09-01, by which time grade 2 was long since correct.

**Caveat on the grade-3 date, stated because it is one row:** 2026-10-12 is the first *readable*
grade-3 row, and the connector returned ~1,448 of ~10,954 timesheet rows. An earlier grade-3 row may
exist in the unread portion, which would move the date earlier — never later, since 2026-10-12 is the
sheet's own last date.

**Blocked on:** nothing from Anca. The correction is a data fix whose date comes from the sheet.
**Re-verify when:** `trainer_grade_assignments` is edited, or a new timesheet period is read. Also after item 147 below resolves, since if the grid's effective date moves, every assignment's own date wants checking against the same boundary.
**Lives in:** nothing changed. `supabase/migrations/202609240002` (the assignments); item 147 below (the scale and its date), item 145 above (why grade 7 rows had to be excluded from this comparison), item 142 above (the same class of drift, in roles).

---

### 150. Two requirements were derived from a spreadsheet over three days — both were written down in July. The feedback file is read FIRST, before any new module

2026-10-20, and it is a process finding, not a technical one.

`wowlab_feedback_analiza` (Google Sheet `1HWOtFYkCCCJe7e_BkVDPWrFFedOU8eGH_4P48pYp8kI`, 73 observations, rows 3–77 of *Feedback centralizat*, dated 2026-07-30) **row 8**, verbatim — Anka, screen *Plata traineri*:

> *"Adaugă rolul ei la acest ecran; **sumă separată pe entitate**; **statusuri (de plată/facturat/plătit)**; **link către contract**."*

Three of those four were treated as discoveries this week:

| row 8 asked, July 2026 | what happened |
|---|---|
| **sumă separată pe entitate** | built 2026-10-19 as though it came from Anca's answer of 2026-10-18 |
| **statusuri (de plată/facturat/plătit)** | written 2026-10-20 as item 148, "a missing domain", derived from status values in the timesheet |
| **link către contract** | **nowhere** — not built, not recorded, not noticed until now |

The per-entity grouping took a verification pass, a rolled-back 38-workshop simulation and a day's work to justify. The justification was correct and the build is right. **It was also already a written requirement, with a named author, a named screen and a date.** The payment-cycle domain was reconstructed from `De achitat` and `platit in martie` appearing in a column — when row 8 names the three stages outright, and row 36 names a more granular set (`cost validat / așteptăm factură / emisă / plătită`).

**THE RULE:**

> **Before scoping or building any module, `wowlab_feedback_analiza` is read first — all 73 rows,
> filtered to the screens the module touches.** Not after the design, not to validate it, and not
> the cluster summary alone: the per-row table carries the author, the screen and the exact words,
> and the summary drops details (row 8's "link către contract" survives only in the per-row table).

Not "read the requirements" as a platitude. The specific failure was that **this file was read once, in July, summarised into clusters, and then never consulagain while building against the screens it describes.** Three days of inference produced what one filtered read would have produced in ten minutes — and the inference, being inference, missed the third item entirely.

**A mechanical note that caused part of this:** the connector returns a truncated sample by default — the first read of this file came back with 13 of 73 rows and no indication that the rest existed. The full content requires `snippetVerbosity: MAX_ALLOWED`, which exceeds the response limit and is written to a file on disk to be processed locally. **A partial read of a requirements document is worse than no read**, because it produces false confidence about coverage. Whatever is read, the row count read must be compared against the row count claimed.

**WHAT ELSE IN THE 73 TOUCHES WORK ALREADY BUILT OR ABOUT TO BE** — the filtered read, done now:

*Already built, and the row confirms it (no action):*
- **rd. 43 + 75** — trainer principal/secundar per group. Built (`trainer_principal_id` / `trainer_secundar_id`). Row 75 (Cătălina) asks who decides principal vs secundar, preset or chosen — **still unanswered**, and it is a process question, not a schema one.
- **rd. 20** — *"Disciplină" → "Tip atelier"* with 14 modules + Altfel/Verde + Party + Chimie + Custom + Corporate. Built as `delivery_format`'s nine values + `custom`. Row 20 also asks to separate *copii confirmați* from *copii facturați* — built as `children_confirmed` / `children_billed`, both still null on every live group.
- **rd. 40** — audit log with actor + date. Built (`audit_log`, `row_history`).
- **rd. 53** — Evaluator as an adjacent/temporary role. Built.
- **rd. 18** — CUI on clients. Built.

*Directly relevant to the import, and unbuilt:*
- **rd. 65** (Laura) — *"datele afișate ar trebui asociate unui an școlar și stocate separat pe an"*. **Answered as a convention, not as a column:** the school year is **derivable from any date**, so this was never a storage problem. What is expensive is two reports drawing the boundary differently — one from September, another from August, a third from the first Monday of term. So the boundary is fixed once, in `docs/DATABASE_CONVENTIONS.md` §16: **1 September – 31 August, labelled by the starting year.** Nothing to build until a report needs grouping by it.
- **rd. 62** (Laura) — nominal monthly attendance export per school, *"unele școli (Lycée Français) cer un tabel nominal"*. This is the attendance-list half of item 141's invoicing question, named by the school that needs it.
- **rd. 6** — balance import, *"coloană cu entitatea"*, three entities. Same entity dimension as row 8.

*Directly relevant to cancellations (item 139), and unbuilt:*
- **rd. 21 + rd. 77 — and substitution is not hypothetical: the 2025-2026 centraliser's FIRST TAB is called "Replacement during year".** An entire sheet, kept for a whole school year, which is the measure of how often this happens. Row 21 asks for the planning view with *"status înlocuire (solicitat/acceptat/descoperit)"*; row 77 (Cătălina) for *"la înlocuiri, de completat automat realocarea grupei — un fel de status check pe școală"*. **Half of it already exists:** `app.rpc_update_session_allocation` writes `trainer_principal_id` / `trainer_secundar_id`, so reassigning a workshop to a different trainer is a solved, audited operation. What is missing is the **state machine** — requested, accepted, uncovered — and the record that a substitution happened at all, rather than the slot simply reading differently afterwards. **Adjacent to but distinct from cancellation (item 139):** a substitution is a workshop that HAPPENS with a different trainer; a cancellation is one that does not happen. Collapsing them would be the same category error as putting a decided zero in `reason_code`. The pay consequence differs too — a substitute is paid at their own grade, which the existing allocation write already handles correctly.
- **rd. 44** — real calendar dates, and automatic substitute suggestion explicitly deferred by Anca herself (*"nu e cazul acum"*).

*Directly relevant to the hours screen (item 130) and the grade question (item 149):*
- **rd. 64** (Laura) — *"Diferențiere sesiuni recurente / punctuale (Școala Altfel/Party) / ore admin. Structură propusă: Nume, Total ore, Sesiuni recurente, Sesiuni punctuale, Admin, Total plată, Status."* **A column-by-column specification of the hours screen, from the person who will use it.** The analysis calls it *"aproape gata de implementat direct"*. It also confirms that recurring, one-off and admin hours are three separate buckets — which is the distinction item 138's `ateliere` label blurs and item 145's grade 7 sits outside.
- **rd. 69** (Cătălina) — *"Trainerul vede nivelul la care e încadrat. Trecere automată de nivel la nr. ore prag (azi manual, Laura)."* Grade progression is **a crossed hours threshold**, computed. See item 151 below.
- **rd. 60** — the manager sees the performance criteria, *"tabel real atașat (Google Sheet)"*, the basis on which Laura computes the monthly bonus. **The link is not in the file** — all 73 rows and the cluster summary contain no URL, and a Drive search for it returns only the feedback file itself. It is either in the upstream *Feedback centralizat* or attached outside the cell values, and it is owned elsewhere (`hello@hyperfit.ro` owns the feedback file).
- **rd. 24 / 5 / 50 / 59 / 68** — the trainer profile module these all belong to, including a **`KPI eficiență (cost vs. venit generat)`** which needs both the pay side (built) and the client-price side (item 141, free text).

*Directly relevant to the grid (item 147):*
- **rd. 36** — the new rate and the 11% removal. See item 147 below; this is the row the whole week came from.
- **rd. 34** — separate the client billing-code generator from the trainer pay calculator. Two instruments, not one. `/payroll` is the second; the first does not exist.
- **rd. 63** (Laura) — *"Păstrăm distincția Surroundings/Other City dacă încă se aplică?"* **An open question about the location tiers, from July, still unanswered** — asked while item 144 was spending this week proving the tiers belong to the school. Also asks for a monthly per-trainer pay report *stored in the application* for periodic reporting, which is item 148's territory.

*A conflict flagged in July and still undecided:*
- **rd. 7, 8, 9, 10, 15** — Anka repeatedly asks that **Finance Admin & Reporting** see screens scoped to Finance Operations / Operations / Inventory. The analysis marks this `🔴 CONFLICT CU O DECIZIE DEJA TESTATĂ` against the Phase 0 finance segregation (D5b) and says it needs **a conscious decision from Anca, not a silent widening**. **DECIDED 2026-10-20 — see item 153 below: it stays as it is, and the gate now answers by choice rather than by omission.** The decision turned out to bite exactly one screen (`/payroll`) and exactly three test accounts, which is what made it cheap.

**Blocked on:** nothing. The rule is the deliverable; the list above is the backlog it produces.
**Re-verify when:** any module is scoped. And the row count: 73.
**Lives in:** nothing changed. `wowlab_feedback_analiza` (the source); item 136 above (per-entity grouping, requirement rd. 8), item 148 above (payment cycle, requirement rd. 8 and rd. 36), item 147 below (the rate, rd. 36), item 144 above (location tiers, open question rd. 63), item 139 above (the visibility conflict, rd. 7-10/15), item 151 below (grade progression, rd. 69).

---

### 153. Finance Admin & Reporting does not get the five screens — decided 2026-10-20, where until today the gate answered by omission

Anka asked, in July 2026, across five separate feedback rows, that **Finance Administration & Reporting** be added to screens scoped to Finance Operations / Operations / Inventory:

| row | screen |
|---|---|
| rd. 7 | Planificare & Alocări / Grupe & Înscrieri |
| rd. 8 | Plata traineri |
| rd. 9 | Prezența copii |
| rd. 10 | Stoc materiale |
| rd. 15 | Comenzi |

The analysis flagged it `🔴 CONFLICT CU O DECIZIE DEJA TESTATĂ` against the Phase 0 finance segregation (D5b) and said it needed **a conscious decision from Anca, not a silent widening**.

**Mihai's decision, 2026-10-20: it stays as it is. Finance Admin & Reporting does not receive the five screens.**

**What changes today is not the gate but its status.** `/payroll` admits `finance.operations.*` or `org.settings.manage` and not `finance.reporting.*` — and it has done so since it was built, *without anyone deciding it*. Until today the gate answered Anka's request **by omission**: the role was absent because nobody had added it, which is not the same as a refusal. From today it answers **by choice**. That distinction is the whole reason this item exists: an unexamined default and a decision look identical in the code and are completely different things to inherit.

**1. THE COST TODAY IS ZERO, on two counts — and this is the thing a re-reader needs first.**

*Nobody real is affected.* Measured: exactly **three** accounts hold `finance.reporting.*` without the `/payroll` gate, and **all three are `is_test_account = true`** — `maxdigitalro+finadmin@gmail.com`, `test+ui-finance-admin@wowlab.dev`, `test+finance-admin-a@wowlab.dev`. **Zero non-test accounts.** Anka herself holds **Finance Operations as well**, so she personally sees `/payroll` today and will keep seeing it. She asked for the **role**, not for herself — which is the correct way to ask, and also why refusing costs nothing yet.

*And four of the five screens are not actually gated against her.* Of the five:
- **rd. 7** — `/groups` admits `groups.read`, which Finance Admin & Reporting **already holds**. She can already see it.
- **rd. 8** — `/payroll`. **This is the only screen the decision actually closes.**
- **rd. 9, rd. 10, rd. 15** — Prezența copii, Stoc materiale and Comenzi **do not exist**. The nine routes built are clients, contracts, groups, my-work, payment-config, payroll, profile, suppliers, admin.

So a five-screen request resolves to **one screen, excluding three test accounts**. That makes the decision cheap and trivially reversible — one capability added to one gate — which is precisely what someone re-reading this in six months needs to know before treating it as load-bearing architecture.

**2. THE REOPENING TRIGGER, written as a condition rather than as "to be revisited".**

> **The day a real person is granted ONLY Finance Administration & Reporting, this restriction starts
> costing something and this item reopens.**

Not "review periodically" — an item with no condition for reopening never reopens. The condition is checkable in one query (the one above: holders of `finance.reporting.*` without the `/payroll` gate, filtered to `is_test_account = false`), and today it returns nothing.

**A second trigger, for the three screens that do not exist yet:** whoever builds Prezența copii, Stoc materiale or Comenzi will choose a gate for it, and will face this same question with no default to inherit. This decision covers them in advance — they are scoped as they are today — but a builder who disagrees should **reopen the item rather than quietly widen the new screen**, since a new screen has no "how it already was" to appeal to.

**That second trigger is the same shape as §17, and is now written there as §17b.** §17 is the case where a correct decision carries a *wrong reason* and nothing fails, because the reason is prose and no value changes. This is the case where a correct decision has **nothing to apply to yet** and nothing fails, because the surface it governs has no code to test. **Both are ways a decision degrades without producing a single red assertion** — and in this item they sit side by side: for `/payroll` the decision defends a gate that exists and now carries its reason in a comment; for the three unbuilt screens it exists only as intent. Saying which is which, inside the item, is the whole guard. An item that reads as though it governs five screens when it can only defend two would itself be a wrong reason of the §17 kind.

**3. THE MONTH-CLOSE FRICTION STANDS, and is a direct consequence rather than a side effect.**

Anka meets an unheld workshop while closing the month and has to ask Operations, because `app.rpc_cancel_session`'s gate is `sessions.create` and not `finance.operations.*` (item 139). **That remains correct, and for a reason stronger than tidiness:** what she sees is *"not confirmed"*, which is **ambiguous between two different facts** — the workshop did not happen, and the workshop happened and the trainer forgot to confirm. Operations knows which, because the school tells *them*. A gate that let Finance resolve that ambiguity alone would be inviting a guess about money.

And the repair, if it bites, is **not** widening the gate — it is a button on the unconfirmed row that flags it for Operations, inside the application. Item 139 records that so the gate does not widen out of convenience six months from now.

**ANKA HAS TO BE TOLD THE ANSWER IS "NOT YET".** She asked in July, on all five screens, and nothing has gone back to her. If she is not told, she asks again in three months and nobody remembers that it was decided — which is how a decision degrades back into an omission. **This is an action on Mihai, not a code change**, and it is recorded here because the register is where "we decided and told her" needs to be checkable.

**Blocked on:** nothing. Decided.
**Re-verify when:** the query in §1 returns a non-test account, or a new screen among rd. 9 / 10 / 15 is built.
**Lives in:** `app/(app)/payroll/page.tsx` (the gate this decision now justifies), `app/(app)/payroll/actions.ts` (the same gate on the close action); item 150 above (the feedback rows and the rule that surfaced them), item 139 above (the month-close handoff and why the gate must not widen), item 142 above (role sprawl, which is why "Anka already has Finance Operations" was worth measuring rather than assuming).

---

### 154. The school-holiday calendar, as data — and it needs a per-school dimension, which `school_year_calendar_link` already knew

2026-10-20. Found by Mihai, after the links stored on the groups turned out to be unreadable (item 144: one folder on the two Lycée groups, `/u/5/` in the URL, `Requested entity was not found`, nothing in a Drive search). The dates below are the **national** school-year structure for **2026-2027**:

| holiday | from | to |
|---|---|---|
| **Toamnă** | **24 October 2026** | **1 November 2026** |
| Iarnă | 23 December 2026 | 10 January 2027 |
| Schi (one week, by county) | one of 15–21 Feb / 22–28 Feb / 1–7 Mar 2027 | |
| Primăvară | 24 April 2027 | 4 May 2027 |
| Vară | from 19 June 2027 | |

Module 1 ends **Friday 23 October**; return is **Monday 2 November**.

**IT HAD AN IMMEDIATE CONSEQUENCE, which is why this was worth chasing rather than noting.** The weekly schedule projects six workshops onto 26, 27 and 28 October. **They do not happen.** `202610200004` therefore stops at 21 October and asserts that nothing is dated inside 24 October – 1 November. Without the calendar those six would have been entered as real.

**And note what the calendar did NOT do: it did not become a precondition again.** `app.rpc_cancel_session` (202610200003) means a wrongly-scheduled workshop is now repairable, so the calendar is a quality improvement rather than the thing standing between generation and an unfixable mess (item 139). But repairable is not a licence to write down something known to be false — so the six were not inserted "and cancelled later". The right order held: cancellation first, then the calendar makes generation *accurate* rather than merely *survivable*.

**THE SHAPE THE TABLE NEEDS, not built here.** These dates govern **Avenor** — a Romanian private school following the national structure. They do **not** govern the other two:

- **Lycée Français** follows the **French** calendar, which has *vacances de la Toussaint* (typically two weeks in late October/early November), different winter and spring breaks, and a different year end.
- **Deutsche Schule Bukarest** follows its own, on the German pattern.

So the calendar is **not a single list of national dates**. It needs a **per-school dimension, with the national structure as the default and per-school overrides** — one school's holiday is another school's teaching week, and a generator that used one list would be wrong for two of the three schools we already have.

**`groups.school_year_calendar_link` already knew this**, and that is the part worth keeping: it is **per group**, not per organization. Whoever added it understood that schools differ, stored a link rather than dates, and the link then went unread (nothing in the codebase parses it) and unreadable (the folder is not accessible to this account). **The intent was right and the mechanism was a link.** A table of dates with a school dimension is the same intent, expressed as something a generator can query.

**The minimum that makes it useful**, in order of cost:
1. The national structure above, as rows, as the default — covers Avenor today.
2. A nullable school/client reference, so Lycée's and DSBU's own dates can override it.
3. The one open question the data cannot answer: the ski week is **per county**, one of three. Avenor's county determines which, and nothing in the schema records a school's county — `clients.address` is free text (item 144 relies on exactly that for the Bucharest check).

**RESOLVED 2026-10-20.** The design question this item posed — default plus overrides — was **answered in the negative** by `DATABASE_CONVENTIONS.md` §18: there is no default. The national structure matches none of the three schools on any boundary, so it is a fourth calendar nothing uses, and a school without a loaded calendar makes the generator refuse rather than fall back. **The table is built:** `public.school_calendar_closures` (`202610200008`), 58 rows, per school, carrying each school's own wording and its source URL — and one column this item did not anticipate, `blocks_workshop`, because an early-dismissal day is a day the school is *open* and an afternoon workshop still cannot run (item 159 below).
**THE NEXT WORKSHOPS ARE THE WEEK OF 2 NOVEMBER** — Monday 2 and Tuesday 3 at Lycée, Wednesday 4 at Avenor (×2) and Scoala Germana (×2). Six again. Until then **the application is up to date for the first time since this started**: 44 workshops, the last six of them scheduled rather than historical, and nothing between 21 October and the return from holiday.

**Re-verify when:** schedule generation is built, or the next holiday approaches (**23 December 2026**, the winter break, which is the next boundary that will silently produce wrong workshops).

---

**CORRECTED THE SAME DAY, 2026-10-20, by reading the three schools' own calendars (item 155).** Everything above about the *shape* of the problem was right — per-school, overrides, the link that already knew. **The dates were wrong for every school we have**, and the mistake was not in the table: it was in treating the national structure as the default that covers Avenor and the exception as the other two.

| | 19–23 Oct | 24 Oct – 1 Nov | 26–30 Oct |
|---|---|---|---|
| national structure | school | **HOLIDAY** | holiday |
| Lycée Français | **HOLIDAY** | **HOLIDAY** | **HOLIDAY** |
| Deutsche Schule | **HOLIDAY** | weekend / school | school |
| Avenor | **HOLIDAY** | weekend / school | school |

**Avenor does not follow the national structure.** Its own published calendar shades 19–23 October as `Holidays` and leaves 26–30 October white. That is the sentence above — "These dates govern **Avenor** — a Romanian private school following the national structure" — contradicted by the school's own PDF. It was an inference from what kind of school Avenor is, written in the voice of a finding. Nothing was checked.

So three consequences, each the opposite of what this item claimed:

- **The six of 19–21 October were all scheduled into a holiday**, not two of them under suspicion. `202610200004` asserted "nothing dated inside 24 October – 1 November" and that assertion *passed* — it was pointed at a week that two of the three schools teach.
- **"THE NEXT WORKSHOPS ARE THE WEEK OF 2 NOVEMBER" is wrong.** Avenor and the Deutsche Schule teach on **Wednesday 28 October**; four workshops were withheld that should exist. Only the Lycée is out until 2 November.
- **"the application is up to date for the first time since this started"** was the least supported sentence in the item, and it was the one written with most confidence.

**The ski week: the county question is answered, and it is still not enough.** Point 3 above said "nothing in the schema records a school's county". It does not need to — **`clients.address` carries all three, and all three are Bucharest**: Avenor `Drumul Pădurea Pustnicu 125A, 014042`, Lycée `Șoseaua București-Ploiești 160A, 015016`, Deutsche Schule `Strada Coralilor 20G, 013328`. One municipality, one inspectorate, **and ISMB has published its choice: 22–27 February 2027** ([edupedu](https://www.edupedu.ro/vacanta-mobila-2027-pentru-elevii-din-bucuresti-este-programata-in-perioada-22-27-februarie-2027-anunta-ismb/), Ordin 3194/2026, chosen from the 15 Feb – 7 Mar window). So the derivation works: address → municipality → inspectorate → week, with nothing new in the schema.

**And then two of the three schools do not take that week as published.** Avenor shades exactly **22–26 February**, the ISMB week — the derivation's one clean confirmation. The Lycée takes **22 February – 7 March**, a fortnight that *contains* it. The **Deutsche Schule takes 15–19 February** — the *first* week of the national window, not Bucharest's. It is an `Anerkannte deutsche Auslandsschule` on the Baden-Württemberg curriculum and is not bound by ISMB's pick at all.

So the county answers *which week the inspectorate chose*, which is a different question from *which week this school is shut*. Deriving the first and storing it as the second would be wrong for two schools out of three — the same substitution that produced the autumn error above, one layer down. **The county is worth deriving and is not a substitute for the per-school rows.**

**THE WHOLE YEAR, all three schools, 2026-2027** — Mihai asked for the year rather than the week, and this is it. Read from each school's own published calendar; the Lycée's from the PDF's colour bands, since its holidays are colour-coded and extracting the text loses the colour.

| | **Lycée Français** | **Deutsche Schule** | **Avenor College** | *(national)* |
|---|---|---|---|---|
| term starts | 2 Sep 2026 (*pré-rentrée* 1 Sep) | — | 1 Sep 2026 | 7 Sep 2026 |
| **autumn** | **19 Oct – 1 Nov** | **19 – 23 Oct** | **19 – 23 Oct** | *24 Oct – 1 Nov* |
| **winter** | **21 Dec – 3 Jan** | **21 Dec – 8 Jan** | **21 Dec – 8 Jan** | *23 Dec – 10 Jan* |
| back after winter | Mon 4 Jan 2027 | Mon 11 Jan 2027 | Mon 11 Jan 2027 | Mon 11 Jan |
| **ski / mobile week** | **22 Feb – 7 Mar** (two weeks) | **15 – 19 Feb** | **22 – 26 Feb** | *one week, 15 Feb – 7 Mar; ISMB chose 22–27 Feb* |
| **spring** | **26 Apr – 9 May** | **26 Apr – 3 May** | **26 Apr – 3 May** | *24 Apr – 4 May* |
| last teaching day | Fri 2 Jul 2027 | Wed 30 Jun 2027 | Wed 30 Jun 2027 | Fri 18 Jun 2027 |
| summer from | 7 Jul (5–6 Jul *journées pédagogiques*) | 1 Jul | 1 Jul | 19 Jun |

**Days off inside term that are not holidays**, and they matter because two of them land on a Lycée teaching day: **Mon 30 Nov** (Sf. Andrei) and **Tue 1 Dec** (Ziua Națională) are legal holidays at all three — and the Lycée's workshops are Monday and Tuesday, so that week loses both. Then **6 and 7 Jan** (Epiphany, Sf. Ion) fall inside everyone's winter break; **30 Apr – 3 May** (Orthodox Easter) inside everyone's spring break; **1 Jun** (Children's Day, a Tuesday — a Lycée day) and **Mon 21 Jun** (Rusalii — another Lycée day) are term-time losses. Each school also publishes single days its students are off that nothing else predicts — Avenor's teacher inset days (25 Mar 2027 among them), the Deutsche Schule's *Brückentag* on Mon 31 May 2027, the Lycée's *journées pédagogiques* on 5–6 Jul. Per-school, and not derivable from anything.

**The pattern under the table:** the three schools agree on *winter* and *spring* within a couple of days and disagree hardest on *autumn* and the *ski week* — which are exactly the two we needed first.

**The three calendar sources, which is what item 144 and this item were both blocked on:**

| school | source | autumn 2026 |
|---|---|---|
| Lycée Français | `https://www.lyceefrancais.ro/pdf/calendrier/calendrier.pdf` | 19 Oct – 1 Nov |
| Deutsche Schule | `https://www.dsbu.ro/calendar-vacante/` | 19–23 Oct |
| Avenor College | `https://www.avenor.ro/wp-content/uploads/2026/02/2026-2027-Avenor-School-Calendar.pdf` | 19–23 Oct |

These belong in `groups.school_year_calendar_link`, replacing the unreadable Drive folder on the two Lycée groups and filling the four nulls — one line of work, not done here because item 155 holds the decision about what else changes with it.

**Re-verify when:** unchanged in form, different in date. The next boundary is **Monday 30 November** — Sf. Andrei, a legal holiday at all three, and a **Monday**, so it takes a Lycée workshop; **Tuesday 1 December** is Ziua Națională and takes the other. The winter break then starts **21 December** at Avenor and the Deutsche Schule and **21 December** at the Lycée — not 23 December, which is the national date this item recorded.
**Lives in:** nothing changed. `groups.school_year_calendar_link` (the column that anticipated the per-school dimension); `supabase/migrations/202610200004_schedule_to_21_october_unconfirmed.sql` (the first migration to assert against a holiday); item 139 above (cancellation as the precondition, and why the calendar is no longer one), item 144 above (the unreadable links), item 150 above (rd. 65 and the school-year boundary convention, §16).

---
### 155. All six workshops of 19–21 October were scheduled into a school holiday, and four more were withheld from a teaching week — one wrong calendar, both errors

2026-10-20. Mihai asked whether the two Lycée workshops of 19 and 20 October fell inside the French *Toussaint* break, and asked for the whole year resolved at once rather than this week. The answer is yes — **and it is not the interesting part.** Reading all three schools' calendars instead of one turned a two-row question into a six-row error plus a four-row omission.

**What the three calendars say about autumn 2026:**

| | source | autumn holiday | back |
|---|---|---|---|
| Lycée Français Anna de Noailles | the PDF Mihai named | **19 Oct – 1 Nov** (two weeks) | Mon 2 Nov |
| Deutsche Schule Bukarest | `dsbu.ro/calendar-vacante` | **19 – 23 Oct** (one week) | Mon 26 Oct |
| Avenor College | its own 2026-2027 PDF | **19 – 23 Oct** (one week) | Mon 26 Oct |
| *(national structure)* | *Ordin 3194/2026* | *24 Oct – 1 Nov* | *Mon 2 Nov* |

**Every one of the six planned workshops is inside a holiday.** Lycée Monday 19 and Tuesday 20; Avenor ×2 and Scoala Germana ×2 on Wednesday 21. `/payroll` is showing **956.50 of pending pay that can never be earned**, and the two we were not even suspicious about — the German school's, tomorrow — are as wrong as the two we asked about.

**And the same mistake withheld four real ones.** `202610200004` declined to insert 26, 27 and 28 October because the national calendar says holiday. Avenor and the Deutsche Schule teach that week: **Wednesday 28 October is four workshops, worth 551.50.** The guard that was supposed to protect the schedule removed real rows and admitted false ones, in the same decision, from the same source.

**THE METHOD ERROR, which is the part worth keeping.** Item 154 asked three schools' question and answered one school's. It got the *design* right — per-school dimension, national default, overrides — and then wrote a default nobody had checked, as a finding:

> "These dates govern **Avenor** — a Romanian private school following the national structure."

Avenor's calendar was one link from its homepage and took two minutes to read. Nobody read it. The sentence is an inference from what *kind* of institution Avenor is, written in the grammar of an observation, and the two schools flagged as exceptions were flagged because they are *foreign*, not because anything about them had been checked either.

> **A default is a claim about a specific case, and it has to be checked case by case.** The moment a model says "these are the exceptions", the exceptions get evidence and the default gets none — it is the thing that looks like it needs no source. Here the default was wrong for the one school it was written for, and two of the three "exceptions" turned out to be the *same* exception.

This is item 144's shape pointed the other way. There, the location bonus looked trainer-dependent and the proof had to come from a minority value *inside the same trainer at the same school*, because that excludes trainer-dependence rather than outvoting it. Here, "Avenor follows the national calendar" was never excluded by anything — it was assumed, and the one source that could have excluded it was never opened.

**WHAT WAS NOT WRONG, and it matters for what gets written down next.** Nothing false was asserted to anybody. All six rows are `planned` and unconfirmed, which is the application saying *scheduled*, not *delivered* — exactly the distinction `202610200004` drew in its own header and the reason it refused to confirm anything in advance. That discipline is what makes this repairable as a cancellation rather than a falsified record, and it is the second time in two days that refusing to assert more than was known has paid for itself.

**THE REPAIR, written and deliberately not applied** (`supabase/proposed/`, convention §15, both with rollbacks):

- `cancel_19_21_october_school_holidays.sql` — the six, as `vacanta`, which is a category the enum already has because a holiday is not a school cancelling. Asserts the six price at **0** afterwards, and that the 38 delivered are untouched. **Actor: Cătălina**, and getting that name right took three checks — see item 157 below, which is where the first draft of this file was caught putting a name on the rows that could not have performed the act.
- `schedule_28_october_avenor_and_german.sql` — the four of 28 October. **A separate file on purpose.** Cancelling removes something known to be false; inserting writes something forward on a published calendar and nothing else. The calendar says those two schools are open. It does not say our workshop runs — and *"it was scheduled"* and *"it happens"* are different facts, which is the exact distinction `202610200004` made for 19 October and then failed to apply to its own silence about 28 October. Asserts no Lycée row lands inside Toussaint.

**APPLIED the same day**, on Mihai's instruction, as `202610200005` and `202610200006` — see item 158 below for what changed and what it cost to get there.

**And the actor on those six was wrong, corrected within the hour by `202610200007`.** `202610200005` named **Cătălina** because she holds `Operations Manager` and the gate would admit her, defending it as *"`cancelled_by` records who exercised the authority"*. **She exercised nothing** — not asked, did not decide, had not answered. Her role *would have* permitted it, which is a fact about her permissions and not about these rows. The actor is **Mihai** (`maxdigitalro@gmail.com`, `Organization Owner`), and the fact that makes it his is independent of any role: *he read the three calendars, decided, and ran it.* This was the third instance of one substitution in two days, so the rule is now `DATABASE_CONVENTIONS.md` **§19** rather than another item.

**No longer blocked on anything.** The rule that replaced the reasoning is `DATABASE_CONVENTIONS.md` §18: **no school gets dates without its own calendar, and a missing calendar is a refusal rather than a fallback to the national structure.**

**Re-verify when:** before every schedule insert, now — against the school's own calendar, not a national one. The next boundaries are **Monday 30 November** (Sf. Andrei — a legal holiday at all three and a Monday, so it takes a Lycée workshop), **Tuesday 1 December** (Ziua Națională, the other Lycée one), and **Monday 21 December** (winter break starts at all three, two days before the national date).

**Lives in:** `supabase/proposed/cancel_19_21_october_school_holidays.sql` and `supabase/proposed/schedule_28_october_avenor_and_german.sql` (+ rollbacks); `supabase/migrations/202610200004_schedule_to_21_october_unconfirmed.sql` (the header that got it wrong, applied and therefore corrected here rather than edited — §17's handling); item 154 above (corrected in place, with the three calendar URLs and the Bucharest ski week); item 144 above (the form of proof this failed to use); item 152 below (whose name goes on a row).

---
### 156. The closed-month cancellation screen slipped a day behind the function it was decided with — and the reason is structural

2026-10-20. `app.rpc_cancel_session` and the screen that makes its damage visible were decided together on 2026-10-19: a cancellation has **no month-closed gate**, so a workshop can be cancelled after Finance has closed and invoiced the month, and the agreed guard was not a gate but **visibility** — the closed month shows that it happened. The function shipped that day with the pay rule and a test. The screen shipped today.

Mihai named the reason, and it is not "it was forgotten":

> *o funcție și garda ei decise să livreze împreună nu livrează împreună dacă una e o migrare și cealaltă un ecran — una trece prin aserțiuni, cealaltă prin judecată. Aia e un tipar, nu o scăpare.*

**The two halves are not the same kind of work and do not finish the same way.** A migration ends when `raise exception` stops firing: the pay rule, the five categories and the gate all have a row that proves them, and `db/tests/cancel_session_pay_rule.sql` either passes or does not. The screen ends when somebody decides the wording is right — what a finance manager should read on a closed month, whether to name the mechanism or the consequence, whether a count is enough. There is no assertion that fails when that sentence is wrong. (The wording chosen, in the end, names the consequence: *"{{n}} workshop(s) cancelled after this month closed — fewer are billable than when it was closed"*, not *"late cancellations detected"*.)

> **A pair decided together ships together only if both halves end the same way.** When one is settled by assertions and the other by judgement, the assertions finish first — not because the judgement is harder, but because nothing tells you it is unfinished. The migration announces its own completion; the screen has to be *remembered*.

**Why this is a pattern and not an incident.** Three of the guards this project has agreed to are of exactly this shape — a mechanism plus the thing that makes its effect visible: this one; the unconfirmed-slot list beside the pay sums (a slot is *listed*, never summed, and the listing is the whole protection); and the `reason_code` classifier beside the raises, which only held because `db/tests/payroll_reason_code_coverage.sql` derives both sides from `pg_get_functiondef` and asserts they match. **The third one survived because somebody turned the judgement half into an assertion.** That is the available fix, and it is not always available.

**What it costs when it slips.** Here, nothing — nothing was closed, so no closed month existed to be wrong about, and the gap was a day. The exposure is real in the general case: between the function shipping and the screen shipping, the system can do the thing the guard was agreed to make visible, invisibly.

**What to do about it, in order of cost:**
1. **Say which half is the guard** when a pair is agreed, and ship that half first or not at all. Here the function was the capability and the screen was the guard, and they went out in that order.
2. **Where the judgement half can be made assertable, make it** — the coverage test is the proof it is sometimes possible.
3. **Where it cannot**, write the pair into the same register item with the screen named, so the open half is a line somebody reads rather than a thing somebody remembers.

**Built today, verified, not an open task:** `app/(app)/payroll/page.tsx` fetches `closed_at` on periods and the cancelled sessions, and derives `lateCancellationsByPeriod` by comparing `cancelled_at > closed_at`; `payroll-client.tsx` renders the line on the closed-month list; `i18n.ts` carries the wording in both languages; `db/tests/cancel_session_pay_rule.sql` block 3 covers it with 6 assertions.

**Re-verify when:** the next time a mechanism and its visibility are agreed in one decision — which is the trigger, not a date.

**Lives in:** `supabase/migrations/202610200003_cancel_session_five_categories_and_pay_rule.sql` (the no-month-closed-gate decision and its reasoning); `app/(app)/payroll/page.tsx`, `payroll-client.tsx`, `i18n.ts`; `db/tests/cancel_session_pay_rule.sql`; `db/tests/payroll_reason_code_coverage.sql` (the one case where the judgement half became an assertion); item 139 above (why the gate was not widened instead).

---
### 157. `app.is_platform_owner()` returns false for the holder of the role called `Platform Owner` — two mechanisms, one name, and an applied migration names the wrong one

2026-10-20. Found by writing a guard that was expected to pass. A proposed migration (item 155 above) impersonated `hello@maxdigital.ro` and asserted, before writing anything, that the actor clears `rpc_cancel_session`'s gate. **It refused.** Three facts came out of chasing why, and none of them is about that migration.

**1. `app.is_platform_owner()` reads a boolean column, not a role.**

```sql
select coalesce((select u.is_platform_owner from public.users u
                 where u.id = app.current_user_id()), false);
```

**The only row in the real organization with `users.is_platform_owner = true` is `test+platform@wowlab.dev` — a test account.** Anca Tanasescu holds the *role* named `Platform Owner` (plus `Sales Manager`), and the function named `is_platform_owner()` returns **false** for her. She has `org.settings.manage` and `sessions.create` through the role's capabilities, so every gate written as `is_platform_owner() OR <capability>` admits her — through the second clause, never the first.

So the first clause of that gate is, in production, **a clause only a test account satisfies.** It has never been true for a real person. Nothing is broken today, because the capability clauses carry it; what is broken is that reading the gate tells you something false about who gets in and why.

**2. An applied migration states the wrong mechanism.** `202610200002`'s header reads "`request.jwt.claims` is set to Anca (platform owner) for the duration". True of her role, false of the function that bears its name. The import is correct — she had the capabilities, the 38 confirmations are hers, and item 152 already fixed the *reason* her name belongs there. This is the **mechanism** stated wrongly in the same sentence, and it is §17's shape again: a correct action resting on a description that does not hold. Corrected here rather than in the applied file, per §9's precedent.

**3. `hello@maxdigital.ro` has no roles in this organization at all**, `is_platform_owner = false`, `full_name` null. It is a stub row. Whatever it is for, it is not an identity that can act — and a migration had been written putting its name on six rows as the actor of an act it could not have performed. The guard caught it; nothing else would have, because `rpc_cancel_session` returns `'not_permitted'` as a *string* rather than raising, so the loop would have written the string into a variable and carried on.

> **A function whose name repeats a role's name will be read as that role.** Nobody checks whether `is_platform_owner()` means the column or the role, because the name answers the question before it is asked. Here the two disagree completely, and the disagreement survived every gate that quotes the function, because the clause that was wrong was never the clause that let anyone in.

**And a fourth thing, smaller and already known in another form:** `Cătălina Trușan` holds `Operations Manager` alongside `Trainer`, which is why she has `sessions.create`. That is the same double role that made an earlier authorization test pick Anka Orban and prove nothing (item 142 above — *a test that picks its subject by role name tests the name, not the gate*). In item 155's cancellation it is not a hazard but the answer: she clears the gate as Operations, not as a trainer.

**What to decide, and it is genuinely a decision rather than a fix:**
1. **Is `users.is_platform_owner` meant to be set for Anca at all?** If platform ownership is the role, the column is redundant and the function should read the role; if it is a separate, deliberately rarer thing (a break-glass flag that no customer-facing account holds), then the gate clause is working as designed and the *name* is the problem. These point in opposite directions and only one person can say which.
2. Either way, **the test account is the only holder of a production-gating flag**, which is worth looking at on its own terms (item 136's territory: what the `test+*` accounts can do).
3. If the column stays, **rename what reads it** — `has_break_glass()`, `is_superadmin()`, anything that does not collide with a role name.

**Re-verify when:** anything new is gated on `is_platform_owner()`, which is the moment the first clause starts mattering; or when the `test+*` accounts are reviewed.

**Lives in:** `app.is_platform_owner()` (the function); `public.users.is_platform_owner` (the column); `public.user_org_roles` + `public.roles` (the role that shares its name); `supabase/migrations/202610200002_import_2026_2027_schedule_to_16_october.sql` (the header stating the wrong mechanism); `supabase/proposed/cancel_19_21_october_school_holidays.sql` (the guard that found it, and the three checks written into its ACTOR section); item 142 above (role drift, and the double-role hazard in tests); item 152 below (whose name goes on a row, and why).

---
### 158. The same substitution, made twice, one layer apart — and a correct measurement that was not turned back on the rows already written

2026-10-20. Convention §18 is the rule this produced. This item is the mistake, named by the two people who made the two halves of it, because the rule is only worth as much as the thing it stops happening again.

**MIHAI'S HALF: deduced from the kind of school instead of measuring.** Item 154 recorded the national school-year structure and assigned it: these dates govern **Avenor**, a Romanian private school; the Lycée and the Deutsche Schule are the exceptions because they are foreign. The category did the work. Avenor's own calendar was one link from its homepage and shades **19–23 October** as holiday, white across 26–30 — the opposite of the national structure on both halves of the question. Nobody opened it.

**His own words for the shape, written about the ski week the same day:** *"judeţul răspunde la ce săptămână a ales inspectoratul, care e altă întrebare decât ce săptămână e închisă şcoala asta."* That diagnosis is exactly right and it is exactly what the autumn had already done, one layer up: *the kind of school answers which calendar a school might plausibly follow, which is a different question from which weeks this school is shut.* A category was substituted for a measurement, twice, and only the second one was caught at the time.

**CLAUDE'S HALF: the measurement was correct and was not turned on the rows already written.** The three-school table — Lycée 19 Oct – 1 Nov, Deutsche Schule 19–23 Oct, Avenor 19–23 Oct — was produced from the three published calendars and set out as a table. **At that moment six workshops were sitting in the database on 19, 20 and 21 October**, written three hours earlier by `202610200004`, and four more had been deliberately refused for 26–28 October. The table and those rows were never put next to each other. What was reported instead was the calendar as a finding.

> **A correct measurement that is not turned back on the decisions already taken is half a measurement.** The cost of the second half is one query. The cost of skipping it is that the measurement changes nothing — which is indistinguishable, from outside, from not having measured.

It is worse than a missed check, because the measurement *was* the thing that falsified the earlier decision and the earlier decision was recent, known, and written by the same hand. There was no gap in the evidence to be filled. The two facts simply never met.

**WHAT ACTUALLY HAPPENED TO THE SCHEDULE, now applied:**

| | before | after |
|---|---|---|
| 19 Oct Lycée, 20 Oct Lycée | `planned`, pending | **`cancelled` / `vacanta`** |
| 21 Oct Avenor ×2, Scoala Germana ×2 | `planned`, pending | **`cancelled` / `vacanta`** |
| 28 Oct Avenor ×2, Scoala Germana ×2 | *refused, absent* | **`planned`, unconfirmed** |
| 26–27 Oct Lycée | *refused, absent* | **still absent — correctly**, Toussaint runs to 1 Nov |

October now reads **1913.00 payable, 0.00 pending** after the cancellations — the figure Mihai named in advance, to the ban — then **551.50 pending** once the four of 28 October went in. `202610200005` is the **first real use of `app.rpc_cancel_session`**: six cancellations, zero pay, **zero `reason_code`** (decided zeros, not failures — the distinction 202610200003 was built to keep), and six `row_history` rows carrying an actor. The rows were **not deleted** — convention 12. *"This workshop did not happen because the school was on holiday"* is worth keeping; an absent row says nothing, and next year's generator would have to learn the same thing again from nothing.

**WHAT WAS NOT WRONG, and it is the reason this was repairable.** All six were `planned` and unconfirmed. The application was saying *scheduled*, never *delivered* — the distinction `202610200004` drew in its own header when it refused to confirm anything in advance. Nothing false was asserted to anybody, which is why this is a cancellation with a reason rather than a falsified record being quietly corrected.

**Re-verify when:** never for these rows. For the rule, §18 governs: no school gets dates without its own calendar, and a missing calendar is a refusal, not a fallback.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §18 (the rule); items 154 and 155 above (the wrong default and the error it produced); item 144 above (the form of proof that excludes rather than outvotes, which neither half of this used); `supabase/migrations/202610200005_cancel_19_21_october_school_holidays.sql` and `202610200006_schedule_28_october_avenor_and_german.sql`.

---
### 159. A school calendar has more than two states, and the third one costs money — `Early Dismissal 12:00` is a teaching day with no afternoon

2026-10-20. Asked by Mihai before generation rather than after: *"Dacă există un marcaj «Early Dismissal 12:00», calendarele au și alte stări decât vacanță/zi-de-curs."* They do. The 174 workshops reported an hour earlier contained **two days with no children on them, counted as teaching days because they were not holidays.**

**The three calendars re-classified, every marking that is neither a holiday nor an ordinary teaching day:**

| school | states its calendar has | the ones that are not holidays |
|---|---|---|
| **Lycée Français** | 3 | `Journées Pedagogiques sans accueil d'enfants à l'école` — **1 Sep 2026, 5–6 Jul 2027**. Plus 13 `Jours fériés sans ecole`. **No short-day concept exists.** |
| **Avenor College** | 6 colours + 3 kinds of outlined box | **`Early Dismissal for Students - 12:00` — 18 Dec 2026 and 30 Jun 2027.** Plus `Inset Days for Management` (2, both Saturdays), `Nursery Teachers Inset Day & Student Holiday` (4–5 Jan, 1–2 Jul), `All Teachers Inset Day & Student Holiday` (8 Jan, 25 Mar), `Summer School` (5–16 Jul), 14 `Legal Holidays`. |
| **Deutsche Schule** | an event list, not a grid | `Rumänischer Feiertag`, `Rumänischer Nationalfeiertag`, `Heilige drei Könige`, `Rumänischer Feiertag Heiliger Johannes`, `Katholische Ostern`, `Brückentag`, `Kindertag`, `Orthodoxer Pfingstmontag`. **No short day and no inset day published.** |

**The one that bites: Wednesday 30 June 2027 at Avenor.** The school is **open**. The children leave at **12:00**. Our workshops are at **15:15 and 16:15**. Two workshops, 337.50 lei, in an empty building — and a holidays-only calendar would have counted that day as a normal Wednesday, because it is not a holiday and the school is not shut. The other early dismissal, 18 December 2026, is a Friday and hits nothing.

**And there is a precedent in the school's own records**, which is what settles it rather than our inference: the 2025-2026 centraliser, 19 December, carries the note **"zi scurtă — cluburi suspendate"**. Same situation, recorded by them, with the outcome written beside it. The afternoon clubs do not run on a short day; that is not a deduction about what happens after the children leave, it is a consequence they have already written down once.

**So 174 was wrong and 172 is right.** Avenor's last workshop is **Wednesday 23 June**, not 30 June.

| | per group | last workshop |
|---|---|---|
| Lycée Mon / Tue | 27 / 27 | 28 / 29 June (teaching continues to Fri 2 July) |
| Avenor ×2 | 29 | 23 June (30 June is the short day) |
| Deutsche Schule ×2 | 30 | 30 June |
| | **172 total, 27 142,50 lei** | three different endings, none of them chosen by us |

**WHERE THE DATES NOW LIVE: `public.school_calendar_closures`** (`202610200008`), 58 rows for 2026-2027 across the three schools — item 154's table, built at last, and built **without the national default** because §18 says there is none. One row per marking, carrying the school's **own wording** verbatim (`Early Dismissal for Students - 12:00`, `Journées Pedagogiques sans accueil d'enfants à l'école`, `Brückentag`) and the URL it was read from.

**`blocks_workshop` is a stored column, not derived from `kind`**, and that is the whole lesson in one schema decision:

> **"The school is shut" and "a workshop cannot run" are different predicates.** An early-dismissal day is open and blocks. A management inset day on a Saturday is shut-ish and blocks nothing. Anything that computes one from the other is wrong about both.

The three non-blocking rows are recorded anyway, so that *checked and irrelevant* never becomes indistinguishable from *never looked* — which is exactly the failure mode of item 158.

**ONE SOURCE IS WEAKER THAN THE OTHER TWO, and it is written into the table's header rather than left for someone to discover.** The Deutsche Schule publishes an **event list**; Avenor and the Lycée publish **day grids**. An absent entry in a list is not the same as a white cell in a grid. If a `letzter Schultag` half day exists at the Deutsche Schule on 30 June, this table does not know about it, and the 30 workshops on that group assume it does not.

**THE YEAR IS GENERATED** (`202610200009`): 172 workshops, 2 November to each school's own last day, all `planned`, none confirmed. **Not one date is typed in that migration.** The weekday comes from `groups.schedule_pattern`; duration, tier, trainer and start time are templated from each group's most recent non-cancelled session; the excluded weeks come from the closures table; and even the *end* is unchosen — the range runs to 31 August and each school's summer closure cuts it off, which is why the three schools stop on three different days.

The last assertion joins every generated session back to its own school's calendar and requires zero overlaps. **Derived from the table, not from a list of expected dates typed in the same file** — an assertion against a hand-written list proves only that the typing was self-consistent.

**Why generating a year is safe now and would not have been a week ago:** `app.rpc_cancel_session` exists. If a school moves a day, the row is repairable with a reason. Generating 172 rows with no cancellation path would have been writing a year nobody could correct — which is item 139's argument, now spent for the purpose it was saved for.

**Re-verify when:** a school publishes its 2027-2028 calendar; or the Deutsche Schule's 30 June turns out to be a half day. **The next in-term boundary is Monday 30 November** (Sf. Andrei at all three, and a Lycée teaching day) and **Tuesday 1 December**.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §18 (no national default) and §19 (the recorded actor); `public.school_calendar_closures`; `supabase/migrations/202610200008_school_calendar_closures.sql` and `202610200009_generate_schedule_to_end_of_school_year.sql`; items 154, 155 and 158 above (the design, the error and the diagnosis); item 139 above (cancellation as the precondition, now spent).

---
### 160. `/my-work` shows a trainer no workshops at all — and generating a year made that a different problem than it was yesterday

2026-10-20, audited at Mihai's request before the 28 October confirmations rather than after. Read only; nothing below is built.

**What `/my-work` actually renders:** four numbers and a grade. *Confirmed this month*, *Groups assigned*, *Hours this month*, an unconfirmed-count line, and the trainer's grade name. **There is no list of workshops — not past ones, not future ones, not a single date.** There is no confirm button on the page.

`unconfirmedCount` filters `session_date <= today`, and the comment says why: *"a workshop next week isn't late, so counting it would turn a normal state into a warning."* That reasoning is right and it is about the warning, not about the list — it was never a decision to hide the future, because there was no list to hide it from.

**Two of the four numbers moved when 172 rows landed, without anyone touching the page.** *Groups assigned* counts distinct groups across **all** the viewer's sessions with no date bound; *Hours this month* sums `duration_minutes` for every session dated in the current month **including ones that have not happened** — October's figure for Lorina already counts 28 October. Neither is wrong by its own definition. Both are now answering about a future that did not exist when they were written.

**THE PROBLEM THIS WAS ASKED ABOUT, stated precisely.** `202610200009` templated each group's trainer from its most recent non-cancelled session. So **Lorina is the recorded trainer on all 30 remaining Deutsche Schule workshops through 30 June 2027 — eight months, propagated from a handover three weeks old.** Teodora handed over after about three weeks of teaching, so the observed rate of change on that slot is weeks, not years. The question is not whether it goes stale; it is **whether anyone sees the moment it does**, and the only screen Lorina would ever look at is `/my-work`, which does not show her that she is down for 30 workshops.

**Where confirmation actually lives, and the walk to it.** `/groups/[id]`, as a checkbox inside a session card. Sessions are ordered `session_date DESC`, which after generation means Lorina's group page **opens on 30 June 2027** and **28 October is the 31st card of 35**. The label is `Bifează pentru a confirma` at `text-[11px]`, with a default-sized checkbox.

**Once confirmed, a trainer cannot un-confirm.** `ConfirmationControl` renders static text `Confirmat` for an own slot that is already confirmed — no control at all. But `app.rpc_confirm_session_attendance(p_session_id, p_confirmed)` **accepts `false` and nulls the timestamp.** The database allows the undo; the screen does not offer it. A mis-tap is repairable only through Operations' correction path (`correctSessionConfirmation`, Anka).

**And the RPC has no date gate.** Its guards are: row exists, caller is one of the two trainer slots, caller holds `mywork.*`, month not closed. Nothing about `session_date`. **A trainer can confirm 30 June 2027 today** — and could confirm the whole year this afternoon. That was unreachable in practice yesterday, when the furthest row was seven days out. It is reachable now, from the same screen, by scrolling up instead of down.

**What showing the future would cost, since nothing here is built.** The data is already in hand: `page.tsx` fetches every session for the viewer with no date filter and then throws the rows away after counting them. A *"your next workshops"* list is a render change plus i18n strings — no query, no schema, no RLS, no new capability. Putting the **confirm control** on that list is the larger half: the server action is reusable (`confirmSessionAttendance` takes `groupId, sessionId, confirmed`, and `groupId` is on every row already) but it brings `/my-work` its first write path, its first pending/error state, and its first need for the `not_assigned` / `month_closed` messages that today live in the groups dictionary.

**Blocked on:** nothing technical. It is a scope decision, and the deadline that makes it concrete is **28 October**, when four workshops exist in the application before they happen for the first time and two trainers are meant to confirm them themselves.

**Re-verify when:** the first trainer signs in — Lorina has never signed in at all (`auth.users.last_sign_in_at` is null) and Cătălina last did on 2026-09-06.

**Lives in:** `app/(app)/my-work/page.tsx` (the four counters, and the fetch that already has the rows), `my-work-client.tsx`, `i18n.ts`; `app/(app)/groups/[id]/group-detail-client.tsx` (`SessionCard`, `ConfirmationControl`); `app/(app)/groups/actions.ts` (`confirmSessionAttendance`); `app.rpc_confirm_session_attendance`; `lib/landing.ts` (why a trainer lands on `/my-work` and not anywhere else); item 159 above (the generation that changed the shape of this).

---
### 161. The chain before Lorina's first sign-in — five separate things, one bad outcome, and we built the first link ourselves

2026-10-22. Item 160 reported five observations about the trainer's path. Mihai read them as **a chain with an outcome**, which is what they are:

> Sorting DESC puts 30 June 2027 at the top and 28 October at card 31 of 35 → the tap target is under 44px → the RPC has no date guard → the screen has no undo → and the confirmation drives pay. **One mis-tap confirms a workshop in 2027 and she cannot repair it.**

Every link is individually defensible. Together they are a trainer's first ten minutes in the application ending in an uncorrectable wrong payment input.

**AND THE FIRST LINK IS OURS.** The sort was correct while the furthest row was seven days out. `202610200009` generated 172 workshops to June 2027 and buried tomorrow under thirty of them. Nobody changed the sort; the data changed underneath it. *A sort order is an assumption about the shape of the data, and generating a year is a change to that shape.*

**Fixed, in Mihai's order, before 28 October:**

**1. The date guard (`202610220001`).** `session_date > current_date` and `p_confirmed = true` → `future_session`, on **both** RPCs. The rule had been written down in `202610200004`'s header two days earlier — *"nobody can make it in advance"* — honoured by one migration declining to write a value and by nothing else.

**The guard is asymmetric, and that is the design rather than a shortcut.** Setting on a future date is refused; **clearing is always allowed**. Three reasons, the third being the one that would have been missed: the asymmetry is in the fact ("I did not teach this" is true about tomorrow by default); it is what makes point 4's undo shippable at all; and **it lets the guard clean up after itself** — any row confirmed in the future *before* the guard would otherwise stay wrong until its date arrived.

**Operations gets the same guard, and the question of why they shouldn't is the interesting half.** The instinct says they are the correction path and must be able to override. But every one of the 38 confirmations `202610200002` made through that RPC was in the **past**, and that is the shape of the function: a correction says *the record is wrong*, and there is no record yet about a workshop that has not happened. **The override instinct is about who may correct a record; the guard is about what may be asserted.** No role makes a future delivery true — the same substitution §19 names. Operations keeps everything genuinely theirs: no month-closed gate, both slots in one call, and unrestricted clearing on any date.

**2. The ordering, measured before it was changed.** Four buckets — *to confirm* (past, unconfirmed: the debt), *today*, *next* (ascending), *earlier* (collapsed). The measurement was the part that mattered: **34–38 cards per group**, 6–7 past, 27–31 upcoming, which is roughly **19 phone screens** if all of them render. So reordering alone would have put 28 October at the top and still left thirty cards below it. The *next* bucket previews **3** and collapses the rest; *earlier* is collapsed entirely. Not pagination — every row is already in hand from one query, so a round trip buys nothing.

**`to confirm` is empty in all six live groups today**, and it is first anyway: nothing past is unconfirmed, and the bucket exists so that the day that stops being true, it is the first thing on the screen.

**3. The tap target.** `text-[11px]` beside a 13px checkbox became a `min-h-11` (44px) button — Apple's HIG floor, Material's is 48dp. The label changed with it: *"Bifează pentru a confirma"* described **the gesture**, which a checkbox needed; a button's gesture is obvious, so it now says what the tap **asserts** — *"Am ținut acest atelier"*. That matters because what it asserts is what pay follows.

**4. The undo.** `Retrage`, beside `Confirmat`, also 44px. The RPC has always accepted `p_confirmed = false`; only the screen never offered it, so a mis-tap meant asking Operations. Deliberately not *"Anulează"* — that word already means "close this form" three times on the page, and once more it would mean *cancel the workshop*, which is a different act with five categories behind it.

And on a workshop that has not happened, the button is **replaced by a sentence** rather than disabled: *"Încă nu — poți confirma în ziua atelierului."* A disabled target teaches nothing when tapped, and this way the screen and the database refuse for one reason instead of two.

**5. Two of the four figures on `/my-work` were lying, and neither was touched by anyone.** *Hours this month* summed every session dated in the current month including ones that had not happened — **October already counted 28 October**. Now: happened, and not cancelled, with the label saying so. *Groups assigned* had no date bound at all — a figure that only grows and would still name a school somebody left two years ago. Now bounded to the current school year (§16) and excluding groups whose only session was cancelled.

> Neither was wrong when written. Both became wrong when 172 rows landed. **A derived figure has a shape of data it was written against, and nobody re-reads the figures when the data changes shape.**

**6. A read-only list on `/my-work`, and explicitly NOT a confirm button there.** The page's entire content was four numbers with no route forward. It now lists the next five workshops — date, time, school, module, confirmed-or-not — each row a 44px link into the group page where the button lives, with a line saying so.

**The full list with a confirm button was refused, and the reason is dated rather than architectural:** it would be `/my-work`'s first write path, first pending state and first error surface, shipped days before the first trainer ever signs in. *You do not launch a new write surface four days before a person uses the product for the first time.* The read-only half costs nothing — `page.tsx` was already fetching every session and discarding the rows after counting them.

**Still deliberately not done:** the invitation. Mihai asks Anca to tell Lorina first; it goes out once 1–5 are live.

**Re-verify when:** the first trainer signs in. **Lorina has never signed in** (`auth.users.last_sign_in_at` null), and **Cătălina last signed in on 2026-09-06** — she has held the Trainer role since 2026-10-20 and there is no notification mechanism of any kind in this application, so she has not been told and cannot be told by it.

**Lives in:** `supabase/migrations/202610220001_no_confirmation_before_the_workshop.sql`; `db/tests/confirmation_future_guard.sql`; `app/(app)/groups/[id]/group-detail-client.tsx` (buckets, `Bucket`, `DisclosureButton`, `ConfirmationControl`), `page.tsx` (`todayIso`, resolved server-side against a hydration mismatch), `app/(app)/groups/actions.ts` + `session-write-errors.ts` + `i18n.ts`; `app/(app)/my-work/*`; items 159 and 160 above; `DATABASE_CONVENTIONS.md` §16, §19, §20.

---
### 162. Unwritten assumptions about the shape of the data — five more, found by reading rather than failing (§17c audit)

2026-10-22. Asked for after `/my-work`'s two figures turned out to have been correct every day until the schedule stopped stopping a week out. **Report, not repair** — every item below is correct today, which is the entire point of the category.

The question asked of each screen: *does the correctness of this query, sort or derived figure depend on a property of the DATA rather than of the query — and is that property written down anywhere?*

---

**A. `/groups` — "the most recent session per group" is now the furthest-FUTURE session. LIVE TODAY. REPAIRED 2026-10-26, `202610260002`.**

```ts
.order("session_date", { ascending: false })   // then take the first per group
```

The comment above it says *"recent session per group"*, and until 2026-10-20 that is what it returned. It now returns **23 June 2027** for Avenor and **30 June 2027** for the Deutsche Schule, and the trainer column of the whole list is resolved from those rows.

**It displays the right name anyway, and that is the trap, not the reprieve.** `202610200009` templated every generated workshop's trainer from the group's most recent non-cancelled session, so the June 2027 row currently names the same person as today's. The moment Operations reassigns a group from January onward without touching June, **`/groups` will show the outgoing trainer** — which is precisely the staleness item 160 was opened about, now with a screen actively hiding it.

Two assumptions, neither written: *the latest session by date is the most recent one that happened*, and *a group's trainer does not change over its lifetime*.

**A second one in the same query:** it fetches **every session of every group**, unbounded, to pick one row each — 223 rows for 6 groups today. PostgREST's `max_rows = 1000` (`supabase/config.toml`) truncates silently, and because the order is DESC the rows it drops are the **oldest**. So the first thing to break is not the trainer column but **groups whose last session is long past, which lose their row data entirely while active groups look fine.** At ~172 sessions a year, that is roughly five years out.

---

**B. `/payment-config` — `versions[0]` is labelled "current", and the pay engine disagrees the moment anyone schedules a change. REPAIRED 2026-10-26, `202610260001`.**

```ts
const current = versions[0];   // versions ordered by effective_date DESC
const history = versions.slice(1);
```

`app.resolve_trainer_grade_rate` and its four siblings all resolve **`effective_date <= p_as_of`** — the version in force on the workshop's own date. The screen resolves *the newest row that exists*. These agree only while **no version has a future effective_date**, which is true today for all five grids (newest is 2026-09-01 everywhere).

The form on that same screen has an `effectiveDate` input defaulting to today and accepting any date. **Scheduling a rate change ahead of time is the obvious use of an effective-dated grid** — it is what the versions table is for — and the first time anyone does it the screen will label the not-yet-active rates "current" while payroll keeps paying the old ones. No error, no test failure: two correct queries answering different questions.

This is the one worth repairing first, and not because of how likely it is. It is the only one where **the screen would contradict the money**.

---

**C. `/my-work` — the viewer's entire session history, fetched unbounded, to compute four numbers about one month.**

```ts
.or(`trainer_principal_id.eq.${user.id},trainer_secundar_id.eq.${user.id}`)   // no date filter
```

Cătălina already has **144** rows, gaining ~110 a year; Lorina has 70. Against `max_rows = 1000` that is roughly eight years before her counters silently start reading a truncated history — and truncation here has no ordering at all, so what falls off is undefined.

The repairs in item 161 narrowed the *derivations* (`hasHappened`, `schoolYearStart`, the five-row upcoming slice). **The fetch underneath them was not narrowed and still pulls everything.** Assumption, unwritten: *a trainer's total session count stays under PostgREST's row ceiling*.

---

**D. `/contracts` — ordered by `exit_number` ascending, as text.**

Correct today because the three live values are `203.1`, `204`, `205` — same length, all numeric. `supplier_contracts`' own header already records that this column carries free text in the real register (`ANEXA 2`, `Act aditional 03 la contract 10/1...`), and a text sort puts `10` before `9`. Assumption, unwritten: *exit_number values are same-length numerics*.

---

**E. `/groups/[id]` — the whole lesson-plan catalogue on every page load.**

312 rows, unbounded, fetched to populate a picker. Comfortably under 1000 and the catalogue is a fixed import rather than something that grows weekly, so this is named for completeness rather than concern — §20: *checked and not a problem* has to be distinguishable from *not checked*.

---

**AND ONE PLACE THAT ALREADY DOES WHAT §17c ASKS**, which is why the convention is a habit to extend rather than a new idea. `/payroll`'s cancellation fetch is also unbounded, and says so in the comment above it:

> *"Bounded by the number of cancellations that have ever happened — six a year on two groups of one school, by last year's centraliser — which is why one unfiltered read is acceptable here and is not acceptable for sessions."*

That sentence is a **claim about the world**, and a claim about the world can be found to be false by someone reading it. That is the entire difference between this and the five above: not that the fetch is bounded, but that the bound is **written where the next person will hit it**.

**Ranked, if any of them is repaired:** B (the screen would contradict the money) → A (actively hides the staleness item 160 exists for) → C (a ceiling, ~8 years) → D (cosmetic until the register's real numbers arrive) → E (nothing).

---

**RESOLVED 2026-10-26, the first two, in that order.** Mihai's reasons for taking exactly those and leaving the rest:

- **B is not hypothetical and the row is one we promised.** Item 147 says the 111-150 scale is seeded *when a signed contract writes it, with that contract's own start date*. A January contract puts the row in in December. **We wrote the rule that brings it**, so this was a date rather than a risk — and `202610200001` removed a *back*-dated version from the same grid six days earlier, so the grid is already being edited in both directions. Repaired as `DATABASE_CONVENTIONS.md` **§22**: one `app.resolve_grid_version`, called by all five pay resolvers and by the screen through `public.current_grid_versions`, plus a third UI state for a version dated ahead — **scheduled**, rendered rather than hidden, because somebody entered it deliberately.
- **A, because a right answer from a wrong mechanism is worse than a wrong one.** Nobody notices it. And the handover is not hypothetical either: Teodora → Lorina on 2026-09-30, six weeks ago. The next one would have been hidden by the very screen you open to see who teaches what. `public.group_latest_delivered_session` (`security_invoker`) returns the latest **held**, non-cancelled session, one row per group — **which fixes the truncation in the same pass**, since the response is now bounded by the number of groups rather than the number of workshops ever.

**C, D and E stay noted, with the reasons as given:** eight years to the ceiling; an `ANEXA 2` that does not exist yet; and checked-and-fine.

**And one thing the repair itself produced, recorded because it is §20 on a surface §20 had not been applied to.** `202610260001`'s first assertion required all five grids to have a version in force, and the migration **refused to apply**. The assertion was wrong, not the code: `contract_type_uplift` has zero versions by decision (item 147 — there is no uplift to apply). The obvious fix is to relax it to "at least one"; the right one was to **tighten** it to *four, plus `contract_type_uplift` asserted null by name*, with item 147 in the failure message. **A relaxed assertion and an assertion nobody wrote look identical from the outside** — both pass, and neither says anyone considered the fifth grid. Written up as the second surface of `DATABASE_CONVENTIONS.md` §20: data on one side, assertions on the other, same failure mode.

**Re-verify when:** anything changes the shape of `sessions` again — another year generated, a second organization, the six remaining schools of item 159's centraliser. That is the trigger for re-reading this list, and re-reading is the only thing that finds this category.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §17c (the form, and the guard); `app/(app)/groups/page.tsx`, `app/(app)/payment-config/payment-config-client.tsx`, `app/(app)/my-work/page.tsx`, `app/(app)/contracts/page.tsx`, `app/(app)/groups/[id]/page.tsx`; `app/(app)/payroll/page.tsx` (the one written bound); `supabase/config.toml` (`max_rows = 1000`); items 159, 160 and 161 above.

---
### 163. Cătălina gets no signal that she is a trainer — and the indicator is deliberately NOT built before the first real confirmation

2026-10-22, **reframed 2026-10-26, state corrected 2026-10-27**. **Trigger: build after the first real confirmation happens, and decide where it lives from what happens that day. No calendar date is the trigger — see the correction below.**

**The gap.** Cătălina holds two of the four workshops on 28 October. The six repairs of item 161 — the sorted buckets, the 44px button, the read-only list — are all on `/groups/[id]` and `/my-work`, and **she sees none of them on arrival**, because `resolveLandingPath` sends her to `/profile`. She holds `mywork.*` through the Trainer role granted on 2026-10-20 **and** `groups.read`, `curriculum.validate` and the rest through Operations Manager, so `has_beyond` is true.

**Her landing is correct and is not the bug.** The rule in `lib/landing.ts` is that `/my-work` belongs to an account whose work is *only* its own work; for someone who also answers for other people's, `/my-work` is a subset of their job rather than their job. Cătălina's main role is not being a trainer. Sending her to `/my-work` would be wrong for the twelve other things she does.

**What is missing is a signal, not a redirect.** *"You have N workshops to confirm"* — and **the number already exists**, computed on `/my-work` as `unconfirmedCount` (past, unconfirmed, viewer's own slot). The work is surfacing it somewhere she passes, not calculating it.

**WHY IT IS NOT BUILT NOW.** Mihai's reason, and it is the same shape as refusing the confirm button on `/my-work`:

> On 28 October this is solved by a person telling them. The indicator gets built **after**, informed by what actually happens that day — maybe a line in the shell is the answer, maybe something else, and **you do not learn which by adding a surface four days beforehand.**

The candidate placements are genuinely different products and the day will discriminate between them: a count in the shell chrome beside the nav; a line on `/profile`; an item in the `/my-work` nav entry; an email. Choosing now means choosing from a guess about a trainer's behaviour that nobody has observed yet — **this application has never had a trainer sign in and use it.**

**And there is no notification mechanism of any kind to extend.** No notifications table, no invitations table, no email path other than Supabase auth's own magic link. Whatever gets built is the first one, which is another reason not to pick its shape from a guess.

**THE PLAN CHANGED ON 2026-10-26, AND THE NEW ONE IS BETTER.** Anca did not tell them and the invitation did not go out. Mihai's call: **28 October is no longer the test — it is not moved, it is reframed.**

**The four workshops of Wednesday 28 October happen and STAY UNCONFIRMED.** The `to confirm` bucket stops being empty — the exact day it was put first for. And the first sign-in becomes a better test than the one that was lost:

> A same-day confirmation tests one tap. **A confirmation of a debt tests the mechanism the month-end close depends on.** Whenever Lorina first signs in, she will find real work owed rather than one clean row — which is what she will feel at the end of every real month.

**1. OPERATIONS DO NOT CONFIRM THE FOUR WORKSHOPS OF 28 OCTOBER. This is an instruction, not a preference.** Not to tidy the record, not to clear the red line off a screen, not because a month is closing. Anka, Anca and Mihai all hold a path that would do it — `rpc_correct_session_confirmation` admits `finance.operations.*`, `org.settings.manage` and the platform-owner flag. **If anybody confirms on their behalf, the only test that matters is gone**, and what remains is a spreadsheet that moved into Postgres.

The four rows are: Avenor 15:15 and 16:15 (Cătălina), Deutsche Schule 15:30 and 16:25 (Lorina).

**CORRECTION, 2026-10-27 — the 2 November / 4 November table below was wrong, and it was wrong in a specific way.** The previous version of this item named Monday 2 November as Lorina's first sign-in and Wednesday 4 November as the first same-day confirmation, presented as dates that would happen. **Mihai removed both.** His own words: *"2 noiembrie a fost SCOS ca dată. Era propunerea consilierului, nu a lui Mihai."* Those were an advisor's forward projection of what a plausible week looks like, written with the confidence of a plan, when no such plan had been made by the person who actually controls the invitation. That is exactly the failure item 164 names from the other side — a human step treated as a date rather than as a thing a named person still has to decide. Removed rather than kept as "indicative," because an indicative wrong date does the same damage as a committed one to anyone who reads it later without this correction attached.

**What is actually true as of 2026-10-27:**

- **The message to Anca went out today.** Lorina and Cătălina are to learn about their Trainer access **from Anca**, not from this application and not from an email it sends — there is no such email path (above).
- **Lorina's invitation is promised for Thursday 29 October.** This is **Mihai's commitment to Anca**, a person, not a date entered in this register. It is written here because it is the fact in flight, not because the register is what makes it binding.
- **The precondition on the invitation is Mihai's own check**, against the four conditions in the standing decision at the top of this register ("Readiness before invitation"): opening `/my-work` and a group page on his own phone and confirming the six things item 161 built — the buckets, the 44px button, the read-only list, the two corrected figures, the collapsing, the scrolling — actually hold up. **This check has not happened yet.** The invitation does not go out until it does, independent of the 29th.
- **Wednesday 28 October still happens exactly as decided above:** the four workshops are taught, nobody confirms them, and the `to confirm` bucket stops being empty. That part of the plan did not depend on Anca and is unaffected by today's correction.

**What this item does NOT claim any more:** a specific date for Lorina's first sign-in, or for the first same-day confirmation. Those are now simply **after the invitation goes out**, whenever Mihai's check clears it — and the trigger for building the indicator (top of this item) moves with them rather than sitting on a date that already proved wrong once.

**What to watch, once the invitation has actually gone out and someone has actually signed in** — unchanged in substance, only no longer pinned to a date that was never real:

- **Is `to confirm` the first thing she sees?** It is rendered first and in `text-brand-pink`, and this will be the first time it has ever had rows in it. If it is not where her eye goes, the bucket order is wrong and no amount of reasoning about it will say so.
- **Does she read it as a debt or as a notification?** Those produce different behaviour: a debt gets cleared now, a notification gets acknowledged and left. The hint under the heading says *"Deja ținute, neconfirmate — plata urmează confirmarea"*, and whether that lands is the question §21 cannot answer from the outside.
- **How long from opening to confirmed?** Not as a performance figure — as the measure of how many steps the route actually has. She lands on `/my-work`, reads a list, taps into a group, finds the bucket, taps the button. Five is the design; the observed number is the finding.
- Whether `future_session` appears in the logs at all — a trainer tapping the wrong row is a real event and the guard refusing it would be the first evidence the guard was worth shipping.
- And for Cătălina, who is the subject of this item: **whether she ever reaches `/my-work`.** She lands on `/profile` and nothing points her onward. If she does not, the indicator is not an improvement — it is the only route.

**Re-verify when:** the first real confirmation has happened. Not on any date written in this item — that is the thing 2026-10-27 corrected.

**Lives in:** the "Readiness before invitation" decision above (the four conditions Mihai's own phone check is against); `lib/landing.ts` (the rule, and why it is right for her); `app/(app)/my-work/page.tsx` (`unconfirmedCount`, the number that already exists); `app/(app)/shell-chrome.tsx` (one candidate placement); `app/(app)/groups/[id]/group-detail-client.tsx` (the `to confirm` bucket, placed first for this day); items 160 and 161 above, and item 164 below.

---
### 164. 348 tests, 22 conventions, and the step that failed was the one with no mechanism — a person telling two people

2026-10-26. Observed by Mihai when the 28 October plan did not happen. **Nothing is built for this.** It is recorded because the shape will recur, and because naming it is the only intervention that was asked for.

**What was in place.** 348 assertions across 22 files. 22 conventions. Five migrations that refuse to apply if their own preconditions are not met — one of them refused this week, correctly, over an assertion that was wrong. Guards that return `future_session` rather than write a false row. A register that fails CI if an item's cross-reference points the wrong way.

**What was scheduled.** *Anca tells Lorina and Cătălina on Friday; the invitation goes out Monday.*

**The second one is the only step in the entire chain with no mechanism of any kind, and it is the one that did not happen.** Not because anyone forgot in a culpable way — because **a date written in an item does not ring anybody's phone.**

> **Every adoption step from here has that same shape, and none of them has an assertion.** Somebody tells somebody. Somebody receives an email and acts on it. Somebody opens a screen for the first time. Somebody notices a red line and understands it as a debt rather than a notification. Not one of those is a row, a return code or a test, and all of them are load-bearing.

**What this is NOT.** It is not an argument for building a reminder, a task queue, a nudge or an onboarding checklist. Mihai was explicit, and the reasoning is the same as item 163's: a surface built to solve a coordination problem nobody has observed yet would be designed from a guess. The application has still never had a trainer sign in.

**What it IS.** A change in how these steps get written down:

> **Stop recording a human step as a date. Record it as a step that needs a NAMED PERSON and a NAMED MOMENT**, and write the dependency explicitly where the dependent step lives.

The difference in practice, on the same step:

| | |
|---|---|
| before | *"Monday 26 October — Lorina's invitation goes out."* |
| after | *"Thursday 29 October — Lorina's invitation goes out, **after Mihai confirms Anca has spoken to her**. Not on the date alone."* |

The second version has a precondition that can be **checked** rather than a date that can **pass**. It cannot fail silently: somebody asks Mihai, and either the answer is yes or the step is visibly not ready. That is as close to an assertion as a human step gets, and it costs a clause.

**And the asymmetry worth sitting with**, because it is the actual finding rather than the fix:

> The parts of this system that are checked are checked **extremely** well. The parts that are not checked are not checked **at all** — and the boundary between them is invisible from inside either side. From inside the migrations, everything has a guard. From inside the plan, everything has a date. Nobody was looking at the seam.

**Where else the seam already exists today**, recorded so the list is a thing rather than a feeling: Anca being asked about the principal/secundar differential (item 2 below, still open); Cătălina not knowing she holds the Trainer role (item 163); whether the Deutsche Schule's 30 June is a half day (item 159, a question for the school); the six remaining schools' data (item 159); and `groups.school_year_calendar_link` still holding an unreadable Drive folder (item 154). **Every one of them is waiting on a person, and not one has a mechanism.**

**Re-verify when:** an adoption step is being planned. The check is one question — *who, specifically, and what tells us it happened?*

**Lives in:** item 163 above (where the reframed dates now carry their preconditions); items 154 and 159 above and item 2 below (the other steps waiting on a person); `DATABASE_CONVENTIONS.md` §20 (the same instinct applied to data — a thing that did not happen has to leave a trace, or it is indistinguishable from a thing nobody looked at).

---
### 151. `trainer_grade_assignments.source` accepts `'computed'` and nothing computes — the automation it was built for needs an hours history we do not have

2026-10-20. All **11** assignments in the real org carry `source = 'manual'`; the CHECK admits `'computed' | 'manual'` and the second value has never been written. That is not an oversight — it is a placeholder for a requirement, and the requirement is named.

Row 69 of the feedback (Cătălina): *"Trainerul vede nivelul la care e încadrat. **Trecere automată de nivel la nr. ore prag** (azi manual, făcut de Laura) — de automatizat."*

**So a grade is a crossed hours threshold, computed from cumulative hours taught.** Which is why asking Anca for *"the date of Alexandra's promotion"* was the wrong instrument (item 149 above): the date is an output, not an input. Laura computes it by hand today.

**And it is not buildable yet, for a reason that is about data volume rather than logic.** Progression is on **cumulative** hours — the whole history, not the current month. Against that:

- the import brings **38 workshops** from three schools, covering 2026-09-01 .. 2026-10-16;
- the real history is **~10,954 rows** in the timesheet, running from 2024-08-06.

A threshold rule run against 38 workshops would place every trainer at the bottom of the ladder and then "promote" them as the application accumulates what the spreadsheet already knows. Cătălina would compute as a junior for a year.

**So grades stay `'manual'`, seeded from the timesheet, until the hours history is in.** That is the honest sequence, and it has a consequence worth stating: **`'computed'` must not be written by anything until the history is complete**, because the first `'computed'` row is also the moment the application starts claiming the ladder is its own.

**A related observation, measured while checking this:** all ten seeded assignments carry
`effective_from = 2026-09-01`, which is **the seeding date, not the promotion date**. The timesheet
has the real ones — Teodora reached grade 3 on 2026-05-05, Alexandra grade 2 on 2025-05-05. For
current pay this is harmless; for any calculation dated before a real promotion it is wrong. **It
does not affect the 38**, whose window opens 2026-09-01, by which time every one of those grades was
already correct — Alexandra's move to grade 3 (2026-10-12) is the only transition inside the window,
and she has no workshop among the 38.

**Blocked on:** the hours history, which is item 130's hours-entry screen plus a timesheet import
that nobody has scoped. Not urgent.
**Re-verify when:** anything writes `source = 'computed'`, or the timesheet is imported. Also when
`effective_from` on the seeded assignments is corrected to the real promotion dates, which is a
separate and larger data fix than item 149's single row.
**Lives in:** nothing changed. `supabase/migrations/202609240002` (the assignments and the `source`
CHECK); item 149 above (Alexandra, derived rather than asked), item 150 above (rd. 69 and the rule
that would have found it sooner), item 130 above (the hours screen), item 145 above (grade 7, which
no hours threshold reaches).

---

### 152. The 38 workshops imported — and the first application of §17 is to this migration's own reason

2026-10-20. The first real data in the operational tables. `wow-lab` held **zero sessions** until this migration; `/payroll` had been correct and empty since it was built.

**What went in:** four missing groups (Avenor ×2 Wednesday 15:15 and 16:15 `wow_mix`; Scoala Germana ×2 Wednesday 15:30 `chem_me` and 16:25 `wow_mix`) and **38 workshops** from 2026-09-02 to 2026-10-16. Before: 0 sessions, 2 groups. After: 38 sessions, 6 groups. Total **6,118.50**, which Mihai had computed independently beforehand and which matched to the ban.

**Nothing was left to a default, because item 144 is written and not built.** There is no tier on the client yet, and the only automatic input — a prefill firing when the trainer's home city is Bucharest *and* the group's address contains "bucur" — could never fire, since every group has `address = null`. So `location_tier` is written explicitly on all 38, from values read off real paid rows: Lycée `imprejurimi`, Avenor `imprejurimi`, Scoala Germana `bucuresti`.

`duration_minutes` carries the **real** length — 45, 50, 90 — never the band. 45 and 50 both resolve through the 60 band and pay identically, so writing 60 would produce the same money and make the row lie about the class.

**The migration asserts its own result** and refuses otherwise: 6,118.50 across 38 slots; 4,792.50 / 684.00 / 642.00 by trainer and invoicing entity; every row carrying its school's real duration and tier; zero unconfirmed; the before and after counts.

---

**THE REASON CORRECTION — §17's first application, to the migration that was written the same day the convention was.**

The migration impersonates Anca (`request.jwt.claims`) so that
`app.rpc_correct_session_confirmation`'s gate passes and `row_history` records a real actor on all 38
confirmations. The reason written beside that choice was:

> *"The actor on all 38 confirmations is therefore her, which is accurate: this import is being run
> on her instruction."*

**That is not accurate, and the inaccuracy is the dangerous kind.** The import was run on **Mihai's**
instruction, not Anca's. And as written, the reason licenses *any* import Anca asks for — including
one nobody has checked — because its justification is the existence of an instruction rather than
anything about these particular rows.

**The true reason is narrower and better: Anca has already approved these exact 38 workshops.** Every
one of them appears in the real timesheet with `Approval Status = "Aprobat"`, and
`Proposed Total Cost = Approved Cost` on each. The import **carries her existing approval forward; it
does not invent one.** Her name on the confirmations is accurate because she is the person who
approved these workshops, in that document, before this application existed.

Stated that way it licenses **exactly this import** and nothing else: a future import of workshops
that are *not* already approved in the timesheet would need a different actor, or a different
mechanism, and would not be able to borrow this justification.

**The applied migration is NOT edited.** House rule, the same one `DATABASE_CONVENTIONS.md` §9
records for `202608270001`: an applied migration records what was believed when it was written, and
the correction lives here. Which is also the point of §17 — the decision (impersonate Anca) was
right, the reason beside it was wrong, and **nothing failed**: 38 correct confirmations, a correct
actor, no wrong number, no failing test. It would have sat there until someone reasoned from it.

**AND WHAT CHANGED THE NEXT DAY (`202610200004`), because it is the real boundary.** Six more
workshops went in for 19-21 October — **unconfirmed**, `status = 'planned'`. The 38 were history:
delivered, and already approved by Anca, which is what licensed importing them confirmed. These six
have nothing behind them and **four of them had not happened yet**. Marking them confirmed would
assert a future delivery, which is the same refusal as declining to backdate one, pointed forwards.

**So those six are the first workshops this application holds BEFORE they happen.** Everything until
then was a record of what had already occurred. From 21 October the schedule is live in the app, and
`/payroll`'s unconfirmed list stops being empty for a real reason: slots waiting for the trainers who
will teach them to say they did. Monday 19 and Tuesday 20 are in the past and are *still* unconfirmed
and still `planned`, because the application knows they were **scheduled**, not that they were
**delivered** — different facts, and only one is in evidence.

That migration writes no confirmations at all, so it impersonates nobody. The absence is the point:
the reason corrected above licensed confirming rows Anca had already approved, and these are not
such rows.

**Blocked on:** nothing.
**Re-verify when:** any further import writes confirmations. The question to ask is not "who asked
for this import" but **"who already approved these specific rows, and where"**.
**Lives in:** `supabase/migrations/202610200002_import_2026_2027_schedule_to_16_october.sql` (+ its
rollback); `docs/DATABASE_CONVENTIONS.md` §17 (the convention this applies), §9 (the don't-edit-an-
applied-migration precedent); item 144 above (why every tier is explicit), item 147 below (the scale
these amounts use), item 149 above (Lorina's grade boundary, which is what makes the handover safe),
item 136 above (the per-entity grouping these totals are split by).

---

### 147. The pay grid may be the real table with the uplift applied twice — and the operational record has never used our numbers, up to eight days ago

2026-10-20. Two facts from separate reports, unrelated until put together, and together they stop the import. **Nothing may be imported until Anca answers.**

- Item 144 established: our `trainer_grade_rates` = the real payroll table **× 1.11 on all six grades** (100→111, 107→119, 114→127, 121→134, 128→142, 135→150).
- The same sheet carries **Lorina Ciurusniuc, 30.09.2026, grade 2, 107,00 lei/hour** — two rows, the exact workshops queued for import.

Our grid says grade 2 is **119**, effective 2026-09-01. The dates overlap. So either **107 is the trainer's net and the company pays 118.77** (our grid is right), or **107 is what the company already pays and the 11% was applied on top of a base that already contained it** — in which case **every amount in the application is 11% too high**.

That the grid is the table × 1.11 *on all six grades* is what makes this a real risk rather than a coincidence: it was plainly derived from the table by applying the uplift. If that base was already gross, it was applied twice.

**What the sheet decides, and what it does not.** Asked of the data: do rows after the "Incadrare actualizata 30.05.2026" note carry the new scale? Measured on 1,446 dated rows:

| grade | before 30.05.2026 | **on/after 30.05.2026** |
|---|---|---|
| 1 | 100 (192 rows) | **100** (9) |
| 2 | 107 (152) | **107** (2) |
| 3 | 114 (215) | **114** (20) |
| 4 | 121 (127) | — |
| 5 | 128 (175) | — |
| 6 | 135 (378) | **135** (41) |
| 7 | 120 (119) | **120** (15) |

**The scale never changed.** And the sheet is not stale: its rows run to **2026-10-12**, eight days ago, covering the workshops in scope. Searched for our figures across all 1,045,664 characters: **`111,00`, `118,77`, `119,00`, `126,54`, `127,00`, `134,31`, `142,08`, `149,85` — zero occurrences each.** Not one of our six rates has ever been paid through this table.

**It still does not settle which reading is right, and the two column headers point opposite ways.** Column M of the timesheet is titled **"Classification Salary / Hour Taught"** — *salary*, which is the trainer's side. The grade table's rate column renders as **"Cost Total Net…"** (truncated by the connector, so not quotable in full) — *total cost*, which is the company's side. One name says what the trainer earns; the other says what the company pays. They cannot both be true of the same number.

**And Anca's own recorded words support our grid, which is why this is not simply "the sheet wins".** Item 95 quotes her: *"in contractul cu trainerii PFA sau SRL vom avea direct 111 lei/ora tarif de baza junior"* — **111 for junior in the PFA/SRL contract**, against the sheet's 100. Both numbers exist in her account, describing different bases. So the plausible story is that the sheet records the pre-uplift basis and the PFA contract adds 11% — our grid being correct for PFA/SRL trainers and simply never reflected in the sheet.

**The one question that decides it, already with Anca:** what amount appeared on Lorina's invoice for the two workshops of 30 September — **214,00** (2 × 107) or **238,00** (2 × 119)?

**Why this cannot be resolved by reasoning.** Both readings are internally consistent with everything else known. The uplift's existence is documented (item 128 measured it as 11%, not the 11.1% this project wrote down for two months — item 131), and the sheet's constancy is now measured. An invoice is the only artefact that states which side of the uplift the 107 sits on.

**NARROWED 2026-10-20 — Anca is no longer needed, and the question is now about a date, not a number.**

Mihai read the timesheet directly. Real rows:

| trainer | grade | date | school | location | rate |
|---|---|---|---|---|---|
| Teodora Merișan | 3 | 16.09.2026 | DSBU | Bucharest | 114,00 |
| Teodora Merișan | 3 | 23.09.2026 | DSBU | Bucharest | 114,00 |
| Teodora Merișan | 3 | 19.09.2026 | Wow Lab Party | Surroundings | 142,50 |
| Lorina Ciurusniuc | 2 | 30.09.2026 | DSBU | Bucharest | 107,00 |
| Alexandra Nuțu | 3 | 12.10.2026 | Scoala Altfel | Other cities | 228,00 |

**The scale in force in September-October 2026 is 107/114/135. Ours says 119/127/150, effective
2026-09-01. Those two statements are about the same period and they contradict.**

**Where our grid came from, from the repo.** `202609240001` presents all six as *"Anca's confirmed
figures (2026-09-24)"*, and its version note quotes only one of them: *"in contractul cu trainerii
PFA sau SRL vom avea direct 111 lei/ora tarif de baza junior."* No derivation is shown. But **item
128 shows it**: its evidence table for the 11% uplift contains the row `100 → 111.00 — exact`,
labelled *"item 95 above's trainer grade 1"*. So the project did treat the sheet's 100 as the **net**
base and 111 as its gross counterpart. All six of ours are the sheet's scale × 1.11, rounded, and
every one rounds correctly — so whoever produced them worked from that scale on that assumption.

**The quote is in the future tense.** *"vom avea"* — we **will have** 111 as the junior base in the
PFA/SRL contract. Said on 2026-09-24. The grid was dated **2026-09-01**, three weeks earlier, and the
operational record kept paying 100/107/114/135 through **2026-10-12**.

So the most defensible reading is no longer "the rates are wrong" but **"the effective_date is
wrong"**: 111-150 may be right for the renegotiated PFA contracts and was simply backdated to a
month in which the old scale was still being paid. That distinction matters because it changes the
fix from *re-seed the grid* to *move its effective_date and seed the prior scale before it* — and
because importing September-October workshops against a grid effective 2026-09-01 computes them at a
scale nobody was paid.

**Either way the import stays blocked**, and either way `202609240001` is wrong about something: the
rates, or the date they start.

**THE ASYMMETRY THAT LET THIS HAPPEN, which is the part to fix regardless.** `admin_rates` declares
its base in the data, in three columns, and item 128 built them for exactly this reason:

| | `amount` (invoiced) | `net_amount` | `is_uplift_applied` |
|---|---|---|---|
| Laura / Teodora / Alexandra, admin | 55.50 | 50 | **true** |
| Cătălina, admin | 79.92 | 72 | **true** |
| Anka (SRL, gross) | 80 | null | **false** |

with the invariants `is_uplift_applied = (net_amount is not null)` and
`amount = round(net_amount * 1.11, 2)`, and a resolver that returns only the invoiced figure *"so a
caller cannot uplift by accident"*.

**`trainer_grade_rates` has one column: `rate`.** No net, no flag, nothing in the data that says
which side of the uplift it sits on — the claim lives only in a free-text `note` on the version row
and in the prose of two migrations. One domain declares its base and the other does not, and the
screen will show **225,00** where Anca's sheet shows **202,50** with nothing in the data to explain
the difference. Item 128's own guard against double-uplifting Anka's 80 has no equivalent here; the
only thing standing between this grid and a second uplift is that `contract_type_uplift` is kept
empty on purpose.

**What to do about it, not done here:** `trainer_grade_rates` should carry `net_amount` and
`is_uplift_applied` on the same invariants, so that "is 119 gross or net" is answerable from the row
rather than from a migration comment. That is a schema change and it is not urgent; writing the base
down is what stops this question recurring.

**CORRECTION 2026-10-20 — the arithmetic was never evidence, and a third reading explains everything without it.**

The claim *"all six are the timesheet's scale × 1.11 and all six round correctly, so the grid was
derived by applying the uplift"* **does not hold.** An 11% **raise** produces exactly the same six
numbers as an 11% **uplift**. The match is equally consistent with both hypotheses, so it
distinguishes nothing.

**And it is the same error dismantled two items earlier, in item 144.** There, the point was that
counting agreements does not disprove a rule — you need a case that only one hypothesis permits
(the same trainer with two locations at one school). Arithmetic is not such a case: it is the one
observation both readings predict identically. Having made that argument correctly about location, it
was then dropped two days later about rates.

**Why it looked like proof, which is the part worth keeping.** Item 128's evidence table contains
the row `100 → 111.00 — exact`, labelled *"item 95 above's trainer grade 1"* — so the arithmetic
appeared to be *corroborating a derivation the repo had already documented*. But item 128's table is
the **same arithmetic**, applied in a domain where the uplift is independently known:
`admin_rates` has `net_amount`, so 50 → 55.50 is a measured uplift, not an inferred one. Reading
that domain's certainty across into this one — where no `net_amount` exists — is what made a
coincidence look like a citation. **A number that two hypotheses both predict cannot inherit
confidence from a domain where only one of them applies.**

**THE THIRD READING, which neither of us had considered.** Row 36 of the feedback does not stand
alone. Row 34, immediately beside it, is cited in `docs/phase1-development-plan.md` (table row 11,
*"feedback rd. 34"*) and says: *"Generator cod facturare amestecă 2 lucruri diferite: codul de
facturare CLIENT vs. plata trainerului PFA. De separat în 2 instrumente."*

If the 11% *"added artificially to the invoice"* in row 36 was on the **CLIENT's** invoice, then
*"junior base rate 111 lei (not 100)"* is simply **a higher rate — a raise**, there is **no uplift
anywhere in the trainer scale**, and Mihai's *"we don't add them"* is consistent precisely because
they were never added there. **This reading accounts for every measurement without invoking
anything further**: the scale rising from 100 to 111, the timesheet still paying 100-135, the
future-tense quote, and the absence of any net figure in the trainer domain. The repo carries only
the *reference* to rows 34 and 36, not their text, so the quotes above are Mihai's.

**THE VERIFICATION THAT WAS ASKED FOR AND NOT DONE: trainer supplier contracts.** The previous
report covered the grid's columns and the repo's derivation and silently skipped the one place where
what was actually agreed would be written down. Done now, and the answer is that **the contracts are
mute because they do not exist**:

- **`trainer_contracts` — the table does not exist.** Item 127 above records why: it was blocked on
  `initial_grade_level` being `NOT NULL` while the source register carries no grade for anyone.
- The three trainer PFAs are present as **suppliers**, correctly linked to their users, with
  `service_type = "Onorarii trainer"` — and **zero contracts each**: `TRUȘAN FLORINA CĂTĂLINA PFA`
  (Cătălina), `MERIȘAN IOANA-TEODORA PFA` (Teodora), `POPA C. RALUCA-MARIA-DIETETICIAN` (Raluca
  Popa).
- All 30 `supplier_contracts` rows belong to non-trainers. **No `price_text` anywhere contains 111,
  119, 127, 134, 142 or 150** — zero matches. The single hit on the older scale is Raluca Margean's
  article bands (`100 RON net` / `120 RON net` / `170 RON net`), which is copyright-assignment work,
  not an hourly trainer rate.
- Anka Orban's three contracts read `price_text = '80 RON/ORA, 90 RON/ORA'` — matching her
  `admin_rates` rows exactly, at `is_uplift_applied = false`. **A contract states what is invoiced.**
- **One weak signal, flagged as weak:** Margean's contract writes *"RON **net**"* explicitly, so this
  register does say "net" when it means net. Anka's says neither — just `80 RON/ORA`. That is
  consistent with "contracts quote the invoiced figure and only mark a net when one is meant", but it
  is one contract's wording, not a convention, and it cannot be stretched to cover a trainer contract
  that does not exist.

**So the evidence is ABSENT, not ambiguous.** There is no artefact in this database that states
whether 111 is a gross or a raise.

**RETRACTED, on Mihai's instruction: the recommendation to add `net_amount` and `is_uplift_applied`
to `trainer_grade_rates`.** Those columns would **assert** that 119 is the gross of 107 — and if 111
is merely a higher rate, there is no net to record, and the schema would encode a wrong reading
permanently, with invariants defending it. Item 128's guard protects a **known** fact (80 is gross
because Anka invoices through an SRL, and her contract says so). Here the equivalent fact is not
known. **Declaring a base is only safe once there is a base to declare.**

**RESOLVED 2026-10-20 FROM THE SOURCE. There is no uplift in the trainer scale, and `202609240001`'s central claim is a misreading.**

Row 36 of `wowlab_feedback_analiza`, verbatim (Anca, Platform Owner, screen *Plata traineri*, July 2026):

> *"Coloană observații; statusuri mai granulare (cost validat/așteptăm factură/emisă/plătită); coloană bonusuri; **RATĂ NOUĂ: 111 lei bază junior (nu 100) + eliminare 11% artificial din factură.**"*

Flag: `Nu, dar schimbare de bani reali`. Recommendation: *"Schimbarea de rată afectează calculul real de plată — de confirmat explicit cu Anca + Laura înainte de codificare."*

**That is one row containing TWO separate changes:**

1. **A NEW RATE** — *"RATĂ NOUĂ: 111 lei bază junior (nu 100)"*. The source calls it a rate change, a raise from 100 to 111. Not a restatement of 100 on a gross basis.
2. **Removing an artificial 11% from the INVOICE** — *"eliminare 11% artificial din factură"*. Row 34, beside it, says what that invoice is: *"Generator cod facturare amestecă 2 lucruri diferite: codul de facturare client (KPI profitabilitate) vs. plata trainerilor PFA (nu pun coduri pe facturi)"*.

**So the 11% was never inside the trainer scale — it was on the client side, and the instruction was to delete it.** `202609240001` fused the two halves of row 36 into a single claim about the trainer grid: *"the 11.1% PFA/SRL uplift is already inside these rates."* It is not inside them. **111 is simply a higher number than 100.**

The one thing that survives unchanged is the decision to keep `contract_type_uplift` empty — but **for a different reason than the one written on it**. The migration says "because the uplift is already inside these rates"; the correct reason is **because there is no uplift to apply**. Both conclusions keep the table empty, so nothing was computed wrongly — but the stated reason has been wrong since 2026-09-24 and would have justified the opposite change just as easily.

**And this retires the question that could not be answered.** "Is 111 a gross or a raise" is answered: **a raise**. The arithmetic could not separate the two (an 11% raise and an 11% uplift produce identical numbers — see the correction above), no trainer contract exists to state it, and the two column headers in the timesheet point opposite ways. **The requirement document says it outright**, and it was readable the whole time.

**What is still open is only the DATE.** Row 36 is flagged **Blocant** and explicitly *"de confirmat explicit cu Anca + Laura înainte de codificare"* — as of the feedback's date, **July 2026, the rate change was proposed and unconfirmed.** The timesheet then paid 100/107/114/121/128/135 on every row through **2026-10-12**. So the new scale had **not taken effect** three months after being proposed, and `202609240001` dated it **2026-09-01**.

**`supabase/proposed/restate_trainer_grade_scale.sql` is therefore confirmed in direction and sharpened in reason:** the 2026-09-01 version should carry the scale that was paid, and 111-150 is a **pending, unconfirmed rate change** rather than a backdated restatement — which also means it must not be seeded at *any* date until someone confirms it took effect, since row 36 itself says the confirmation had not happened.

**And `net_amount` / `is_uplift_applied` on `trainer_grade_rates` stays retracted, now for a settled reason rather than a cautious one: there is no base, because there was never an uplift.**

**APPLIED 2026-10-20 (`202610200001`).** The 2026-09-01 version now carries **100/107/114/121/128/135**, the scale that was paid, with assertions on three real payments rather than on the literals written (grade 2 on 2026-09-30 = 107, grade 3 on 2026-09-16 = 114, grade 3 on 2026-10-12 = 114). 111-150 is not seeded at any date. Mihai, accepting the single-version variant: *"Registrul de plati bate un citat."*

**THE RULE FOR SEEDING 111-150, written as a rule because this entire week came out of its absence:**

> **A rate enters the grid when a signed trainer contract states it, with that contract's own start
> date. Not when someone says it will.**

`202609240001` put 111-150 into the grid on the strength of *"vom avea direct 111 lei/ora"* — **future
tense, in a requirements document, flagged `Blocant` and "de confirmat explicit cu Anca + Laura
înainte de codificare"** — and dated it 2026-09-01, three weeks before the sentence was even written.
Everything that followed came from that: a week spent asking whether every amount in the application
was 11% too high, a proposal to add `net_amount` and `is_uplift_applied` to a table that needs
neither, and a grid that disagreed with every payment made in the two months it claimed to cover.

**The rule is not "be careful with quotes".** It is that a pay grid is a record of an agreement, and
the artefact that carries an agreement is a signed contract. A requirement document carries an
*intention*. The two are different kinds of thing, and only one of them has a start date that means
anything. Which is also why **item 127 above matters more than it looked**: the absence of
`trainer_contracts` is exactly why the gross-versus-raise question had no evidence in this database
to settle it — the only artefact that could have answered it is the one table that was never built.

**THE LESSON ABOUT THE ARITHMETIC, kept here deliberately and not as a footnote**, because it is the
transferable part:

> We imported the certainty of one domain into another that had no net figure at all. A number that
> two hypotheses predict identically cannot inherit confidence from a domain in which only one of
> them applies.

`admin_rates` has `net_amount`, so 50 → 55.50 is a *measured* uplift. `trainer_grade_rates` has no
such column, so 100 → 111 is an *observed difference* and nothing more. Running the same
multiplication in both places produced the same number and two entirely different epistemic
statuses — and the second was read as if it were the first.

**Blocked on:** nothing. 111-150 waits on a signed contract, per the rule above — not on a date
somebody chooses.

**Blocked on:** Anca, and the import is blocked behind it. Note that the arithmetic in item 144 (180.00 vs 225.00 for a Lycée workshop) is unaffected in its *point* — the location bonus is wrong either way — but its *figures* assume our grid, so they move by 11% if this resolves the other way.
**Re-verify when:** answered. And if our grid turns out to be doubly uplifted, `202609240001`'s seeded grid is wrong at the source and every figure this project has quoted since item 95 needs restating.
**Lives in:** nothing changed. `supabase/migrations/202609240001_seed_pay_grids_pfa_inclusive_rates.sql` (the grid, and the migration whose correctness is in question); item 95 above (Anca's 111 quote), item 128 above (the 11%), item 131 above (the mislabelled 11.1%), item 144 above (where the ×1.11 relationship was measured).

---
### 18. Pending invites — cut deliberately

Investigated as a dashboard-candidate block (org.members.manage-gated,
single true number, no segmentation issue — see item 1's block proposal).
Not shipped. **The count is test residue, not signal.** Checked live who
the 10 non-test, `status = 'invited'` real users actually are:
`anca.tanasescu@gmail.com` (the real product stakeholder herself, not a new
hire being onboarded), eight `maxdigitalro+<role>@gmail.com` addresses
(`community`, `finadmin`, `finops`, `inventory`, `master`, `ops`, `trainer`,
plus the bare `maxdigitalro@gmail.com`) — the agency's own
role-verification accounts, not real team members despite
`is_test_account = false` — and `test+cascade-check@wowlab.dev`, a fixture
by name. `is_test_account = false` turns out not to mean "this is a real
person joining the team"; it only means "not inserted by `seed.sql`." None
of these 10 represent a real pending onboarding today.

**Blocked on:** nothing technical — the query and the gate are both sound.
Blocked on the underlying data not existing yet: a real invited team member.
**Re-verify when:** the real team starts getting real invites through this
system — at that point the count (and this cut decision) should be
revisited.
**Lives in:** `public.users` (`status`, `is_test_account` — confirmed live
this round the two don't mean what they'd need to mean together for this
metric).

### 2. Trainer and supplier contracts

Confirmed live: no `trainer_contracts`/`supplier_contracts` table exists, and
no capability like `trainers.contracts.*` is seeded — only `trainers.allocate`,
`trainers.engagement.read`, `trainers.substitute` exist today, none of them
about a contract record. This is a genuine "not started," not a hidden
feature.

No existing doc records the specific answers quoted for this item (who reads/
creates trainer vs. supplier contracts, trainers not seeing their own
contract, Catalina needing status + validity period before allocating,
trainers holding contracts on all three legal entities at once) — a targeted
search of `docs/progress.md` and `docs/phase1-development-plan.md` for
"trainer contract"/"Traineri/Furnizori" found the opposite: `progress.md`
entry 56 (2026-08-15) lists "tipuri de contract Traineri/Furnizori"
explicitly as one of three items still awaiting Anca's answer, and the entry
after the next contracts-feature round (line 459) still says "extensia de
traineri/furnizori — neatinse." This conversation is the first record of
these specific answers; they are not yet written into any doc.

**Anka confirmed** as the Finance Admin & Reporting stakeholder
(`docs/phase1-development-plan.md` line 15: "Vizibilitate financiară Anka
(Finance Admin & Reporting)"), so "Anka/Anca for supplier [contracts]" does
mean a finance-capability holder needing to write those contracts.

**The conflict, precisely:** there is no active bug today, because nothing
exists yet to conflict with. The risk is a naming collision. The *existing*
`contracts` table's INSERT/UPDATE policy (confirmed live) is:
`org.settings.manage OR (contracts.* AND NOT finance.reporting.* AND NOT
finance.operations.*)` — finance roles are deliberately excluded from writing
client/school contracts, and `app/(app)/contracts/actions.ts` says so
explicitly ("excluding finance_admin_reporting despite it sharing the
contracts.* capability key"). If a trainer/supplier contracts feature reuses
the `contracts.*` capability key or the finance-excluded pattern — the
obvious choice by naming precedent — it would silently inherit a rule that
directly contradicts Anka needing to create/read supplier contracts. The fix
is a distinct capability key for the new feature; this is worth stating
explicitly so whoever builds it doesn't default to the existing pattern.

**Blocked on:** no schema, no capability, no RLS policy exists yet for this
feature at all.
**Lives in:** `app/(app)/contracts/actions.ts` (existing exclusion pattern to
avoid repeating); `docs/progress.md` entries 56 and the line-459 entry (prior
state); this conversation (source of the answers, until written up
elsewhere).

### 19. `groups.contract_id` — CORRECTED 2026-09-18: applied and in real use; this item's own text said otherwise

The full architecture for item 2 above is now written up:
`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md`, with `groups.contract_id`
named as the one prerequisite step that depends on nothing else in it
(§10). That column exists as a migration now
(`supabase/migrations/202608290001_groups_contract_id.sql`,
`nullable uuid references contracts(id)`, dry-run verified — 5/5
assertions passed on the first run) — **not yet applied to production**,
same "dry run before applying" pause as every prior round.

**No backfill was written, and none should be assumed once this is
applied.** Confirmed live: every group in production today (4 total)
belongs to Cambridge School, and Cambridge School's only contract is the
2026-08-10 seed batch record — `notes` literally says "not a verified real
contract." The SAD's own backfill rule ("client has exactly one contract →
populate automatically") is correct as a rule; run against today's data it
would link real verification-round groups (created 2026-08-13/15, not
seed data themselves) to a fake contract, pass every assertion, and report
success while being wrong. So: **all 4 existing groups will have
`contract_id = NULL` after this migration applies, on purpose, indefinitely
— not a pending backfill, a decision.**

**Re-verify/revisit when:** real client/contract data exists for a client
that actually has groups — at that point the backfill rule from the SAD
can run for real, or these 4 specific groups get `contract_id` set by hand
once someone confirms what they actually are. It's also possible they turn
out to be verification residue themselves, same category as the pending-
invites accounts in item 18 — that determination hasn't been made, and
this column staying null is not evidence either way.

**Corrected 2026-09-18, checked live, not assumed from the text above.**
"Not yet applied to production" was wrong by the time it was read again —
`supabase migration list --linked` shows `202608290001` applied, both
directions, and `information_schema.columns` confirms `groups.contract_id`
exists live, nullable `uuid`. The backfill discussion above is doubly
obsolete, not just outdated: the 4 groups it describes no longer exist
(they were Cambridge School seed residue, purged by the "Seed data cannot
be reliably distinguished from real data" entry above, before this
correction was written), and the groups that exist today are real —
`WOW LAB` now holds 2 groups, both for Lycée Français, both carrying a
real, non-null `contract_id` pointing at the signed contract, set through
the create-group form's own `contract_id` field (`docs/progress.md` entry
71's work, not this file's own item 71 above — the two share a number by
coincidence, not by reference). The
"re-verify/revisit when" condition above ("real client/contract data
exists for a client that actually has groups") has been met, and the
answer is: the mechanism already works, unattended, no hand-set values
needed. Nothing here needed building or deciding — the column, the
migration, and the write path were already correct; only this item's own
sentence describing them was wrong, at least by the time anyone read it
again.
**Lives in:** `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §6.2, §10;
`supabase/migrations/202608290001_groups_contract_id.sql`;
`scripts/verify_groups_contract_id.sql`; the "Seed data cannot be reliably
distinguished from real data" entry above (why the 4 original groups no
longer exist to be null).

### 20. Payment configuration grids — six now, one seeded, five still empty

**What it is:** the eleven payment-configuration tables (five versioned grids —
`trainer_grade_versions`/`_rates`, `location_bonus_versions`/`_rates`,
`language_bonus_versions`/`_rates`, `duration_multiplier_versions`/`_rates`,
`contract_type_uplift_versions`/`_rates` — plus `trainer_grade_assignments`,
per-row history, not versioned) and their six `app.resolve_*` functions are
live in production
(`supabase/migrations/202608310002_payment_config_tables.sql`, applied), with
a working UI at `/payment-config`
(`feat: add payment configuration page`, `658a27b`, merged to `main` at
`8e672c2`). Confirmed live, read-only, right after apply: all eleven tables
have 0 rows, RLS enabled on all of them, grants are exactly `INSERT, SELECT`
(no `UPDATE` anywhere — a version is corrected only by inserting a new one,
never edited), and all six resolvers are `SECURITY INVOKER`, `LANGUAGE
plpgsql`.

**Why it's empty on purpose:** the versioned-grids decision
(`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12.9) means a resolver has
nothing to return until at least one version exists — there is no default, no
seed, and the UI doesn't imply otherwise. Confirmed live: each of the five
sections on `/payment-config` renders "No version exists yet." rather than a
table of zeros, for both a Finance-capable identity and a non-Finance one.
Finance enters every value; nothing here is inferred or defaulted (matches
the existing session-form convention of no default for values that vary per
instance).

**Confirmed live, both roles the nav gate now correctly separates** (the nav
gate itself was a real bug, not a chore — see below): a `finance_operations`-
only identity (Laura's actual capability set) sees the FINANȚE nav group with
Payment configuration but not Suppliers, correctly, since she holds
`finance.operations.*` but not `finance.reporting.*`. Before this round the
whole FINANȚE group was gated on `finance.reporting.*` alone
(`app/(app)/layout.tsx`'s old `canReadSuppliers`-only condition), which would
have hidden the group from her entirely. An `operations_manager` identity (no
finance capability) sees neither the group nor the page's data — direct
navigation to `/payment-config` returns `AccessDenied` with the curated
`access_denied_no_finance_capability` copy (EN+RO).

**No live create-version test was run**, deliberately: it would have written
a real financial-policy version into tables with no `UPDATE` grant, meaning
cleanup would require a privileged `DELETE` — the exact habit this session
has otherwise stopped doing to production data.

**2026-09-02 update: a sixth grid, and a provenance column on
`trainer_grade_assignments`, both added and live.**

`trainer_grade_assignments.source` (`text not null check (source in
('computed','manual'))`, no default — `202609020001`) records whether a
grade came from the §12.2 workshop-count formula or was set deliberately by
a person (Luiza Mirt's grade 3 on return being the first real case of the
latter). Added while the table was empty specifically so `NOT NULL` cost
nothing — no backfill decision to make. **It protects nothing today, on
purpose, not by oversight:** no write path in this application consults it
(nothing writes to this table at all yet), and no recalculation job exists
that could read it to decide whether a computed row should be allowed to
supersede a manual one. The column exists so that job, whenever it's built,
has something to check before overwriting a deliberate human decision — the
protection itself is that job's to implement, not this column's. Also
established this round, argued not assumed: `app.resolve_trainer_grade()`
should not become source-aware — its job is "what grade applies on date D,"
identical regardless of origin; whether a computed row may supersede a
manual one is a write-time policy question for whatever inserts new rows,
not a read-time branch in a resolver whose entire six-function family does
nothing but plain two-step lookups.

`lesson_plan_rate_versions`/`lesson_plan_rates` (`202609020002`) is a sixth
grid, for lesson-plan pay (§12.3) — deliberately not folded into
`trainer_grades` as a seventh grade, matching §12.3's own explicit
rejection of that shape. Chosen as a full versions/rates pair (matching the
other five) over a single non-versioned value on §12.9's own stated
reasoning: versioning was applied uniformly to all five original grids even
without direct evidence any of them would change, on the argument that one
mechanism remembered once is safer than several reasoned about
individually. §12.3 rules out lesson-plan pay varying by trainer; it says
nothing about the rate never varying by date — not enough to earn an
exception to that same logic. **Unlike the other five, this one is not
empty:** seeded with one version, `effective_date = 2024-01-01`, `rate =
120`, `created_by = anca.tanasescu@gmail.com` — confirmed by Anca, the rate
has been 120 lei net per plan since 2024 and has not changed. Dated
2024-01-01 rather than the migration date deliberately: `resolve_lesson_plan_rate`
raises for any date before the earliest version, so a version dated today
would make every lesson plan written before today unresolvable once
lesson-plan work itself can be recorded (see below) — dating it at the true
effective date is what avoids that.

**Still blocked on accounts, a different blocker than the six grid
amounts:** the lesson-plan *work* itself (31 plans written 31.08.2026 —
Răzvan Alexandru Bălașov 4, Raluca Popa 17, Teodora Merișan 10) has nowhere
to be recorded — no table exists for it (see item 23 below) — and could not
be recorded even if one did: none of Răzvan Bălașov, Raluca Popa, Teodora
Merișan, or Luiza Mirt exist in `public.users`, and any such table's
`trainer_id` would need to be `NOT NULL REFERENCES users(id)`, matching
every other person-attached table in this schema. Same blocker, different
angle, as item 22's finding on named team members. Happy Face awards and
per-article writing (item 23 below) are blocked the same way, for the same
underlying reason.

**Blocked on:** Anca sending the five remaining real grid amounts (trainer
grade rates, location/language bonus percentages, duration multipliers,
contract type uplift percentages) — nothing technical. The lesson-plan rate
is no longer blocked — it's seeded. The real end-to-end test for the
remaining five is Laura entering the first version through the real form
once that data arrives; that data is meant to stay, not be
created-then-deleted as a verification step.
**Lives in:** `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12 (the whole
payment-model chapter, §12.3 for lesson-plan pay, §12.9 specifically for the
versioning decision); `supabase/migrations/202608310001_sessions_location_language.sql`,
`202608310002_payment_config_tables.sql`, `202609020001_add_trainer_grade_assignments_source.sql`,
`202609020002_lesson_plan_rate_tables.sql`; `app/(app)/payment-config/`
(`page.tsx`, `payment-config-client.tsx`, `actions.ts`, `i18n.ts` — no UI
section for either addition yet, matching `trainer_grade_assignments`'s own
existing no-section precedent); `app/(app)/layout.tsx`
(`canManagePaymentConfig`, the FINANȚE nav gate fix); item 22 and item 23
below (the accounts blocker and the evaluation domain, respectively).

### 22. Five of seven named team members have no account at all — HEADER CORRECTED 2026-09-18, body already tracked the resolution

Checked directly against every row in `public.users` and `auth.users` this session — not a
name-pattern guess that could miss a variant spelling. Of seven people named across this project's
docs and conversations: **Anca (Tanasescu) and Anka (Orban) are the only two with a real account**
— both on real addresses, both with a matching `auth.users` row. The other five: **Cătălina Trușan
has a fixture account only** (`test+catalina@wowlab.dev`) and no row on any address outside
`wowlab.dev`, anywhere. **Laura Moale, Alexandra Nuțu, Teo Merisan, and Raluca Margean have no row
at all** — not a fixture, not a real address, not `is_test_account`, nothing — confirmed against a
full listing of every `email`/`full_name` currently in `public.users`.

Related to item 18 above (Pending invites — cut deliberately), which already found that none of the
`status = 'invited'` rows represent real pending onboarding today. This item states the sharper
fact underneath that one: it isn't only that the invites on file are stale residue instead of
signal — for five of seven named team members, **no invite, account, or fixture exists to be
stale.**

**Onboarding the team is a prerequisite for the 14 schools, not a follow-up.**

No fix proposed here — this entry is the gap, not a fix.

**2026-09-02 addendum, unresolved, not this entry's to resolve:** `WOWLAB_SAD_Contracte_Trainer_Furnizor.md`'s Appendix A (the validated 25-June-2026 workshop-count baseline) names a **"Teodora Merișan"** (101 workshops) and a **"Raluca Popa"** (22 workshops) — plausibly the same people as this item's "Teo Merisan" and "Raluca Margean" under fuller first names and, for Raluca, a different surname entirely. Neither reading is confirmed by anything in this repo. Both are, independently of this item, still absent from `public.users` — see item 20's 2026-09-02 update and item 23 below.

**2026-09-03 addendum — the gap substantially closed, one open thread inside it.** Eight real
accounts created (`scripts/create_eight_real_wow_lab_accounts.ts`), in `wow-lab` only, no
invitations sent: Cătălina Trușan (`catalina_moale@yahoo.com` — a separate account from the
`test+catalina@wowlab.dev` fixture, which is untouched, kept deliberately for impersonation
testing), Laura Moale, Alexandra Nuțu, Teodora Merișan, Răzvan Alexandru Bălașov, Raluca Popa,
Luiza Mirt — all with roles assigned — and Raluca Margean, account created with **no role**
(see below). This operationally settles the 2026-09-02 addendum's open naming question: Mihai's
own account list treats "Raluca Popa" and "Raluca Margean" as two distinct people, provisioned as
two separate accounts — not an Anca-confirmed fact, but no longer an open ambiguity for this
repo's data.

**Cătălina's address, confirmed by Anca, 2026-09-04: `catalina_moale@yahoo.com` is correct** —
the same address this account was already created under on 2026-09-03, now confirmed rather than
assumed correct. Worth recording specifically because a *different* address,
`catalina.moale@gmail.com`, appears in the Happy Face spreadsheet (item 23's workbook) — a `.`
instead of `_` before the surname, and `gmail.com` instead of `yahoo.com`. That gmail address is
not the one to use for her account; do not treat it as an alternate or a correction if it surfaces
again from that spreadsheet.

Roles: Cătălina got `operations_manager`+`curriculum_manager`+`evaluator`, matching her existing
fixture's live role set exactly (not inferred — read directly from `user_org_roles`). Laura got
`finance_operations` (directly confirmed, progress.md line 480). Răzvan, Raluca Popa, and Luiza
Mirt got `trainer` (confirmed via Appendix A / the grade-assignments source column's own "Mirt's
grade 3 on return" comment, migration `202609020001`). **Two role grants are inferred, not
sourced, and need Anca's confirmation:** Alexandra Nuțu's `trainer` (inferred from progress.md's
"hibrizi trainer+admin" line naming her alongside Cătălina/Teodora, plus her 89-workshop Appendix A
count — nothing states this as a role directly) and Teodora's `inventory_custodian` (nothing in
any doc assigns her this specific admin role; only that she does some kind of admin work).
**Raluca Margean got no role at all** — the original "trainer" proposal was directly contradicted
by progress.md's "echipa admin-only" grouping (with Laura/Anka, neither a trainer) and by her
absence from Appendix A's trainer roster entirely, and no confirmed alternative role exists;
Mihai's explicit instruction was to create the account and leave the role pending Anca.

No invitations sent to any of the eight at creation time — created via
`admin.auth.admin.createUser()` specifically to avoid `inviteUserByEmail()`'s automatic email.
Consequence found, and since fixed the same day: the existing admin "Invite" button
(`inviteUser()` in `app/(app)/admin/users/actions.ts`) calls `inviteUserByEmail`, which fails with
"already registered" on all eight now that the accounts exist. A new "Resend invitation" action
(`resendInvitation()`, same file) fixes this for any account that exists but has never signed in —
`signInWithOtp` with `shouldCreateUser:false`, the same mechanism and email template the real
login flow already uses for a returning user's magic link, reused via a service-role call to
bypass the Turnstile check the public `/login` form requires (confirmed live: a service_role call
reaches GoTrue's user-existence check instead of a captcha error). Verified live, real send: sent
to Raluca Popa specifically (one of the eight, chosen for this), confirmed via a second,
independently generated token that the resulting link verifies and lands a real session on
`/profile` showing her name, email, and Trainer role. Not sent to the other seven.

**Naming note, worth keeping so the label isn't misread later.** "Resend invitation" is a UI label,
not a description of the mechanism: `generateLink({type:'invite'})` returns `422 email_exists` for
an already-existing user (confirmed live), so this action cannot use the invite mechanism at all.
It sends a standard magic link (`signInWithOtp`, `type=magiclink`, `magic_link.html` — "Your sign-in
link", not the invite template's "You've been invited") — same outcome for the recipient (a working
`/auth/callback` link that activates the account on first click), different mechanism and different
email copy from the original invite. `shouldCreateUser:false` is set explicitly (confirmed by
reading the live code, not assumed) and re-verified live on 2026-09-04: a request for an address
with no existing account errors (`otp_disabled`, "Signups not allowed for otp") and creates nothing
in either `auth.users` or `public.users` — a typo'd email on this screen fails loudly rather than
silently creating a real account, matching the platform's invite-only design.

**A verification bug, worth recording as a general lesson, not just a fixed mistake.** The first
live assertion pass hardcoded "one `user_org_roles` row per person" and failed — not because of
bad data, but because Cătălina legitimately holds three role rows in the one org. An assertion
that silently encodes an unstated assumption (here: one role per person) fails on *correct* data
that violates the assumption, not on a real defect. Fixed in the same script to assert org
membership (one org, or zero for Raluca Margean) rather than row count.

**2026-09-04, later — the two pending roles assigned, all eight invited, and one structural gap
found while checking the eighth.** `sales_manager` → `anca.tanasescu@gmail.com`, `contract_administrator`
→ `lauraflorentinaa220@gmail.com`, both through the real `/admin/users` "Edit roles" UI (not a
script), each added alongside the person's existing role rather than replacing them — Anca keeps
`platform_owner`, Laura keeps `finance_operations`. Confirmed live: `audit_log` holds a
`user.roles_updated` row for each with a real `actor_user_id`, and both roles' capability grants
resolve correctly via `role_capabilities` (`clients.convert` for Anca's new `sales_manager`,
`contracts.*` for Laura's new `contract_administrator`), independent of any bypass. This closes the
SAD-comparison report's finding that these two roles were unassigned in production contrary to the
SAD's checklist — see item 30's cross-reference and the 2026-09-03 SAD-comparison chat report.

Before sending anything, Raluca Margean's zero-role experience was checked live, not assumed: a
real session (fresh browser context, real magic-link verification, not SQL impersonation) lands
cleanly on `/profile` — nav shows only "Profile", the page reads "You are an unassigned user. You
don't have access to any additional sections yet.", zero console or page errors. Not broken;
`app/(app)/layout.tsx` and `profile/page.tsx` were both already written defensively for an empty
`memberships` array (`?? []` throughout, an explicit `unassigned_role_label` fallback string already
in `profile/i18n.ts`), so this wasn't a near-miss found by luck — the empty case was already handled,
just never exercised by a real zero-role session until now.

**A second thing this check found, not asked for but real: a zero-role account is invisible in
`/admin/users` itself, not just gated by sign-in state.** The Members list (`page.tsx`) is built by
querying `user_org_roles` and joining out to `users` — anchored on the role table, not the user
table — so an account with zero role rows produces zero list rows, full stop. Raluca Margean never
appears there, under any search term or filter, regardless of whether she's signed in. Her
"Resend invitation" therefore couldn't be sent through the button that worked for the other six —
sent instead via the identical mechanism (`signInWithOtp`, `shouldCreateUser:false`), invoked
directly rather than through the UI it's normally reached from, with the same `audit_log` event
type and a note explaining why. Not proposing a fix here — the underlying mechanism is identical
either way, and the gap only bites for the one state (zero roles) this project has never put a real
account into before this session. Worth a real fix if a second zero-role account is ever created on
purpose.

**RESOLVED 2026-09-04, same day.** `user_org_roles.role_id` made nullable (`202609040003`) — a null
role_id is "member of this org, no role assigned yet," representable as a real row for the first
time, not the absence of one. `app.belongs_to_org()` (`202607090001`) already defined org membership
as "has any `user_org_roles` row in this org", independent of role — the schema just couldn't
produce that row before; no RLS policy on `user_org_roles`/`users` references `role_id` in its
predicate (checked live before writing the migration), so nothing else needed to change at that
layer. A partial unique index caps it at one no-role row per (org, user). Raluca Margean given
exactly that row (`202609040004`) — still no role, Anca's decision to make, not this migration's.
`page.tsx`'s `!u || !r` guard relaxed to `!u` only (a null role embed is a real, expected state now,
not a bad row); `editRoles()` now re-inserts a no-role row when saved with nothing checked, instead
of silently deleting someone's only membership row and making them vanish again on the next edit.
Reused the existing `no_roles` i18n string for display — already bilingual, no new key needed.
Verified live in the browser: she now appears in the Members list, her row reads "(no roles)", her
role checkboxes are reachable (opened and cancelled without changing anything — still no role
assigned); her own "Resend invitation" button doesn't show, correctly, since she already has a real
`last_sign_in_at` from the verification pass earlier that same day — checked separately, and
correctly, on a disposable zero-role fixture created and deleted for exactly this purpose.

**All eight now invited, one at a time, reported after each rather than as a batch.** Raluca Popa
confirmed already activated first (`last_sign_in_at` set from the 2026-09-03 verification pass) —
not sent a second link that day; sent one more anyway that same day as a safety margin, already
recorded above. The remaining seven — Cătălina, Laura, Alexandra, Teodora, Răzvan, Luiza Mirt,
Raluca Margean — each confirmed individually via the real admin UI (six of seven) or direct
invocation (Raluca Margean, per the gap above) before moving to the next; no failures.

**Header corrected 2026-09-18 — the body was never wrong, only the title above it.** By the time
this item's later addenda landed (2026-09-03 through 2026-09-08), all seven of the originally-named
missing members had real accounts, and the header still read the original finding as current. This
is a milder case than item 19's above or item 39's below: nothing here asserted a false fact anywhere in
the body — every dated addendum was accurate when written — the title alone stopped describing the
item underneath it and nobody revisited it once the last addendum closed the gap. Retitled to say
so plainly rather than rewritten to imply this was always resolved cleanly.

**Lives in:** `public.users`, `auth.users`, `user_org_roles` (live data); item 18 above
(related finding, same underlying data); `WOWLAB_SAD_Contracte_Trainer_Furnizor.md` Appendix A (the
name-variant discrepancy above); `scripts/create_eight_real_wow_lab_accounts.ts` (the 2026-09-03
creation + the corrected assertion); `app/(app)/admin/users/actions.ts` (`resendInvitation`,
`editRoles`), `app/(app)/admin/users/page.tsx` (`last_sign_in_at` resolution, and the
`user_org_roles`-anchored Members query behind the new gap above), `app/(app)/admin/users/
admin-users-client.tsx` and `i18n.ts` (the "Resend invitation" button, RO/EN); `app/(app)/layout.tsx`,
`app/(app)/profile/page.tsx`, `app/(app)/profile/access-summary.tsx`, `app/(app)/profile/i18n.ts`
(the zero-role empty state, confirmed already correct).

### 23. Performance evaluation domain — read from the real workbook, nothing designed

**What it is:** Anca's real Performance Criteria workbook was read this session — not the app, not
a document already in this repo, not the mockup. **No design proposed against any of it** — this
entry is the findings, recorded as given, per explicit instruction not to design this domain, which
is blocked on Anca.

**Happy Face bonuses come from a monthly criteria matrix, maintained by Cătălina.** Rows are
criteria, columns are people, cells hold written justifications. Eight positive criteria, one
compliance criterion, seven negative ones grouped under "SAD". Per the workbook's own legend: each
criterion met earns one smiley per month; repeated negative behavior leads to a conversation with
the manager, not an automatic penalty. No monthly total is ever negative.

**The evaluation does not drive grade changes — checked directly, not inferred from a tab's name.**
A tab named "compliance criteria for up/downgrading trainers" reads, by its name, like it should
link criteria to grade movement. It holds something else entirely: monthly meeting attendance,
training attendance, and an annual replacement rate. Nothing anywhere in the workbook ties a Happy
Face criterion to a grade change — grade remains exactly the §12.2 workshop-count formula, or (as of
item 20's 2026-09-02 update) a manual override, never this matrix. Consequence: `org_settings.
evaluations_confidential` (OD-7) does not automatically apply to this matrix — it was not built for
it. But the matrix does hold named, critical observations about real people, and whether its
visibility should be restricted the same way, differently, or not at all **is Anca's decision,
still open.** Not designed here.

**Monthly totals are typed by hand, not computed from the criteria — confirmed against real data,
not assumed from the mechanism's description.** May 2026: two people show a total of 500, a third
shows 50. Of the two at 500, one has exactly one criterion marked, the other has none. The person at
50 has one criterion marked. The total does not derive from a count of marked criteria by any
visible rule. Separately, the compliance tab shows distinct "bonus SA" amounts — 100, 200, 300 —
tied to Școala Altfel.

**Confirmed by Anca, 2026-09-04: Școala Altfel bonuses and Happy Face awards are two different
things and stay separate, by design, not an accident of the spreadsheet's layout.** A Happy Face
has a configured value and a criterion from the fixed list; an SA bonus is an arbitrary amount with
a written reason, decided by Anca directly, not tied to any criterion. Mixing the two into one
mechanism would make the per-face value meaningless — already visible in the May 2026 rows above,
where the untied SA amounts are exactly what breaks any attempt to derive a monthly total from a
count of marked criteria. Not designed here; recorded as a real modeling constraint for whenever
this domain is built, not a should-fix on the workbook.

**Replacement rate is measured three separate ways, by three different mechanisms — whether that's
one measure or three is open, not reconciled here.** (1) A monthly observation entered directly in
the Happy Face matrix. (2) An annual statistic in the compliance tab — lessons delivered per year
vs. replacements needed; two people currently exceed a 20% threshold there. (3) A compensation input
at the same 20% threshold in `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md`. Whether these three
are the same number tracked in three places, or three genuinely distinct measures that happen to
share a name and a threshold, is a question for Anca — not resolved by inference here.

**Lesson-plan writers have their own evaluation system, separate from the trainers' one.** The
workbook's "LP WRITERS" tab carries its own positive criteria and its own "SAD" (negative) list,
structurally parallel to but distinct from the trainers' matrix — a July 2025 total of 100 shown for
four people. This is a **second evaluation domain**, entirely separate from the trainers' one, that
nothing in this platform accounts for in any way today — no table, no capability, no mention
anywhere prior to this entry.

**Corrected 2026-09-07 — the original framing here was too broad.** This entry originally said the
~20 people in the Happy Face history are former collaborators, on the grounds that Anca confirmed
they aren't being added to this platform. That conflated two separate facts. Anca's current active
roster (item 33) names Sonia Ganea, Andrada Eremia, Cătălina, Teodora, and Alexandra as active
today — all five appear in the Happy Face history. Appearing in that history says nothing about
whether someone is active now; it's a record of who received an award at some point, not a
membership roster. What actually holds, and is genuinely confirmed by Anca: the **historical bonus
records themselves are not imported.** Their history stays in Laura's spreadsheet — whenever Happy
Face awards are built here, the application will hold awards only from that build date forward.
Recording this explicitly because the alternative is someone mistaking it for data loss: a bonus
report in the app will show no history before the feature's own build date, for real people who
genuinely received real awards before then, some of whom are still active. That gap is a deliberate
scope boundary confirmed by Anca, not evidence anything went missing — but it is a scope boundary on
*bonus history import*, not a statement about who currently works here.

**Blocked on:** Anca — this domain has no confirmed design to build against on any of the six points
above.
**Lives in:** Anca's Performance Criteria workbook (not in this repo, not the mockup); `org_settings.
evaluations_confidential` (OD-7, confirmed not automatically applicable here); `docs/
WOWLAB_SAD_Contracte_Trainer_Furnizor.md` (the 20%-threshold compensation input, one of the three
replacement-rate measurements above); item 20 above (grade-vs-evaluation independence, confirmed
from both directions); item 22 above (the same people this domain is about, still without
`public.users` rows).

---

### 26. No current-organization concept — a real gap, never exercised

Confirmed live this session (wow-lab-test-b investigation). There is no "current org" anywhere in
the session — no column, no cookie, no URL segment. `/clients`, `/contracts`, and `/groups` each
independently loop over the caller's `user_org_roles` memberships with a first-match-wins pattern
(`for (const m of memberships) { if (capability check) { targetOrg = m.organization_id; break } }`),
used for exactly one thing: picking which single org a "+ New X" **create** action targets. The
**read** queries on all three pages carry no explicit `.eq("organization_id", …)` filter at all —
they rely entirely on RLS, which is itself correctly per-row org-scoped (every policy branch
evaluates `app.has_capability(key, organization_id)` against each row's own `organization_id`, not
globally — confirmed by reading the live policy SQL in `202608100003`, not assumed from the
"unsegmented" wording in a code comment, which turned out to refer to client_type segmentation for
finance roles, not cross-org leakage).

The consequence: if a user ever holds membership in **two** organizations, their `/clients`,
`/contracts`, and `/groups` pages would show both orgs' rows merged into one flat list with no
per-row org indicator anywhere in the UI. This is a real, exercisable gap, not a hypothetical — it
has simply never been hit, because no user in this project has ever had multi-org membership. The
`platform.org_switcher.use` capability is seeded into the roles/capabilities system for exactly this
scenario but has no UI behind it anywhere (grepped the whole app for `org_switcher`; zero matches).

The six trainer accounts seeded into wow-lab-test-b this session (item below, `4c182a8`) are
deliberately single-org, asserted live after seeding — so this gap still isn't exercised. It would
be exercised the moment any user is given membership in both wow-lab and wow-lab-test-b, or in any
future second production org.

**No fix proposed here** — reporting the gap, not designing a current-org mechanism.

**Lives in:** `app/(app)/clients/page.tsx`, `app/(app)/contracts/page.tsx`, `app/(app)/groups/page.tsx`
(the first-match-wins `createOrgId` loops, and the unfiltered list queries); `app/(app)/layout.tsx`
(`canManageUsers`, the same first-match-wins shape for nav visibility); `supabase/migrations/
202608100003_add_clients_contracts_rls_policies.sql` (the actual per-row org-scoping that makes this
safe today).

---

### 27. `test+platform@wowlab.dev` — cross-org RLS-bypass visibility (open); `is_test_account` (RESOLVED 2026-09-04)

**Still open, no fix proposed here — do not act.** Exactly one user holds `is_platform_owner =
true`: `test+platform@wowlab.dev` (`status: active`). `app.is_platform_owner()` is a deliberate,
by-design cross-org RLS bypass (`SECURITY DEFINER`, convention #3 — see `202607090001`) — not a bug
in itself. But it means that once wow-lab-test-b holds any data (as of the session that first found
this, it does — six trainer accounts, item 26's seeding), this account's session sees
wow-lab-test-b's rows mixed into its view of wow-lab production `/clients`, `/contracts`, `/groups`.
Pre-existing condition of the bypass's own design, not caused by anything in this item, not a new
mechanism.

**Resolved 2026-09-04, on three fronts — recording all three, because fixing only one would have
looked complete.** The original finding here was narrower than what a full audit turned up: this
account's `is_test_account` read `false` despite the `test+` prefix matching every other
SQL-impersonation fixture in the project — flagged then as "a data-entry gap on this one row," not
corrected. It was one row of seventeen.

1. **The remote's wrong rows, corrected by id.** `test+platform@wowlab.dev` itself (`35e2bb7`),
   then a full-table audit found sixteen more (`79aefce`, migration `202609040002`) — none caught by
   the original 2026-08-12 backfill (`202608120006`)'s static list, for three different reasons:
   predates that migration but outside its stated scope (the two wow-lab-test-b members), created
   the same day or shortly after and simply missed, or created weeks later and never revisited at
   all. Corrected by explicit id, not by address pattern — a pattern accurate today would silently
   catch a real person who matches it later.

2. **`seed.sql`, which would have undone the correction on the very next reset.** Three of the
   seventeen (`test+platform`, `test+trainer-b`, `test+user-b`) are rows `seed.sql` itself inserts,
   and that file never set `is_test_account` on any of its ten rows (`1c7fd25`). Migrations replay
   before `seed.sql` on every reset, so an id-based backfill migration can never reach a row
   `seed.sql` hasn't inserted yet — and more fundamentally, no id-based migration can ever reach
   *any* of these rows on a fresh reset regardless of ordering, because every fixture id here is
   `gen_random_uuid()`, generated fresh every time. The fix had to be set inline, at the point of
   insert, in `seed.sql` itself (and its `ON CONFLICT` branch, so it also overwrites what the two
   fixture-seeding migrations below leave behind for the two emails they share with it).

3. **The admin invite form, which now asks explicitly.** `is_test_account` is now a checkbox on
   `/admin/users`' invite form (`c9d86a4`), unchecked by default, written by `inviteUser()` in the
   same follow-up `UPDATE` that already sets `first_name`/`last_name`/`phone`. The intent exists
   only at the moment of creation, in whoever is creating the account — it cannot be inferred from
   the address afterward, which is exactly how this drifted in the first place.

**Why it drifted: account creation happens in at least eight independent places**, none of which
set this column until now — one production UI action (`inviteUser()`,
`app/(app)/admin/users/actions.ts`); four one-off scripts, each calling the Supabase Admin API
independently (`bootstrap-first-admin.ts`, `seed_test_org_b_trainers.ts`,
`create_eight_real_wow_lab_accounts.ts`, and the two `activate_*_auth_identity.ts` scripts, which
attach an auth identity to an already-existing row rather than creating a new one); and three
direct-SQL insert blocks that bypass the application layer and the `handle_new_auth_user()` trigger
entirely (`seed.sql` and fixture-seeding migrations `202608100005`, `202608130004`). That count is
the actual mechanism of the drift, not carelessness at any one site — a fix aimed at only one of
these eight would have left the other seven exactly as drift-prone as before. The scripts were
deliberately left alone (one-off tools, each written for a known purpose, reviewed individually
before running) — only the ongoing, repeatable path (the admin UI) and the reset-safe source of
truth (`seed.sql`) were fixed.

**Verification caveat, worth keeping attached to this record.** The reset-order reasoning above
(`seed.sql` runs last, id-based migrations can't reach reset-fresh rows) was not verified by an
actual `supabase db reset` — Docker is not installed in this environment (`docker: command not
found`). Verified instead by a rolled-back dry run of the updated `seed.sql` block against the live
schema (real `INSERT`/`ON CONFLICT` path, real constraints, nothing committed — all ten rows read
`true` afterward) and by reasoning through migration filename order and `seed.sql`'s documented
run-last behavior. Not the same as watching a real reset produce the right state end to end.

**Lives in:** `public.users.is_platform_owner` / `public.users.is_test_account` (data, not schema);
`supabase/migrations/202607090001_create_app_schema_rls_helper_functions.sql`
(`app.is_platform_owner()`, the still-open bypass-visibility finding); commits `35e2bb7`, `79aefce`
(migration `202609040002`), `1c7fd25`, `c9d86a4`; `app/(app)/admin/users/actions.ts` (`inviteUser`),
`admin-users-client.tsx`, `i18n.ts`; `supabase/seed.sql`; item 22's 2026-09-03/04 addenda (the audit
that surfaced this).

---

### 28. One activation invite link failed and landed on `/login` — could not be reproduced

Confirmed live this session: the first click of one of the six wow-lab-test-b trainer invite
emails failed and landed on `/login` instead of activating the account. Investigated whether this
means a real routing defect — specifically, whether failure can reach `/login` through a path other
than `app/auth/callback/route.ts`, which is the only redirect site that sets
`?error=auth-callback-failed` (the param the banner built in `8d00681` checks for;
`lib/supabase/middleware.ts`'s own unauthenticated-request redirect carries `?next=<path>` instead,
no error signal at all).

The invite template (`supabase/templates/invite.html`) points directly at
`{{ .SiteURL }}/auth/callback?token_hash={{ .TokenHash }}&type=invite` — our own route, with the
exact params it expects, not a Supabase-hosted intermediate URL. Reproduced every failure mode
directly against it: an already-used token, a malformed token, and a request with no params at all
all land on `/login?error=auth-callback-failed` and would show the banner. A real navigation
(Playwright, not manually-injected cookies) through a valid, unused link also propagated the
session cookie correctly and landed cleanly on `/profile`. **Could not reproduce a failure that
reaches `/login` without the error signal.**

Most likely cause, unconfirmed: a mail client or security gateway prefetching the single-use link
and consuming the token before the human's actual click — common with Gmail and corporate link
scanners, and these are real Gmail addresses. From the callback's point of view this is
indistinguishable from any other already-used token, and per the reproduction above it still lands
on the error-banner path, not a bare page. **Not a confirmed defect.** Worth noting operationally:
this can plausibly happen to a real invitee's first click too, not just these fixtures, and the
remedy in that case is simply to resend the invite — a second, fresh link works normally (fresh
account, no fixture cleanup needed, per the reproduction above).

**No fix proposed here** — do not act.

**Noted 2026-09-18, folded in from `docs/phase1-development-plan.md` row 14 (now superseded, see
item 75 above), not a proposal made here.** That row named a possible mitigation for exactly this
failure shape before this item ever found a real instance of it: an interstitial confirmation page
on `/auth/callback` (a real click required before the token is consumed, rather than consuming it
on first load) — the standard countermeasure against exactly the link-prefetch/scanner cause named
above. Recorded then as `⚪ neconfirmat, opțional`, with no report of it ever being built, and
nothing since has built it either. This item's own finding gives that old, low-priority row a real
case behind it that didn't exist when it was written — still not a proposal to build it, only a
pointer so the two don't stay disconnected.

**Lives in:** `app/auth/callback/route.ts`; `lib/supabase/middleware.ts`; `supabase/templates/
invite.html`; `app/login/page.tsx` (the banner, from `8d00681`); `docs/phase1-development-plan.md`
row 14 (superseded, the mitigation this note points at).

---

### 29. `displayName()` — RESOLVED 2026-09-17, extracted to `lib/display-name.ts` once the trigger actually fired

Was five copies of one rule (`admin/users/admin-users-client.tsx`, `groups/page.tsx`,
`groups/[id]/page.tsx`, `payment-config/page.tsx`, `profile/page.tsx`'s differently-shaped variant)
with an explicit, deliberately-not-yet condition: extract the next time the rule changes, or the
next time a sixth call site needs it — whichever comes first, not on a timer.

**The trigger had already fired before this round -- and this item didn't know it.**
`payroll/page.tsx` gained its own byte-identical copy of `displayName()` in the payroll walkthrough
fixes (item 67, `f74d14b`), the round immediately before this one -- a sixth call site, landed in
the repo before this task ever started. Nobody came back to update this item after that round
landed, so it kept stating a condition -- "neither has happened" -- that the code had already
falsified. Confirmed live via grep across `app/` before concluding anything, not inferred from the
commit message or trusted from this item's own prior text.

**The same shape this register keeps finding, this time about itself.** Nearly every recent entry
in this file is a version of "what was written down stopped matching the thing it describes, and
only checking the source caught it" -- `config push` succeeding vs. which email template was
actually live (item 61), a mockup badge claiming a protection the code behind it never built
(`docs/progress.md` #62, not this file's own item 62), a CUI-constraint recommendation reported as
delivered without ever being written (item 62 below), an RLS branch that reads clean on the page
but is silently dead underneath (item 68). This item is the same failure mode one layer up: a
written trigger condition that nothing re-checks against the code it describes will not notice
when the code satisfies it. The register went stale, not the codebase -- and the fix is the same
one already applied everywhere else this pattern shows up: verify against the current source
before reporting a state, don't carry a prior write-up forward unchecked.

**Extracted (`lib/display-name.ts`), same "promote once the trigger fires" precedent as
`lib/format.ts` (its own header comment says the same thing about its own promotion history).**
Two exports: `displayName()` (the read-only rule, now the single implementation behind
`admin-users-client.tsx`, `groups/page.tsx`, `groups/[id]/page.tsx`, `payment-config/page.tsx`,
`payroll/page.tsx`) and `editableNameFields()` (`profile/page.tsx`'s variant, kept as its own
function producing `{ firstName, lastName }` rather than flattened into the single-string rule --
same distinction this item always drew). `admin-users-client.tsx`'s `Member` type is camelCase, not
the `public.users` column names the other five/shared module use -- kept as a three-line local
adapter (`displayName(member)` calling the shared function with mapped field names) rather than
changing `Member`'s shape or teaching the shared function two input shapes.

**Verified, not just type-checked:** `tsc --noEmit` and a full `next build` clean; then, live in
Test Org B via a real signed-in session (`test+user-b@wowlab.dev`, the org owner fixture, broad
enough to reach all six pages) fetched over HTTP -- `/admin/users` still shows "Test Trainer B1"
(the shared function through the camelCase adapter), and `/profile`'s rendered HTML confirms the
edit-form variant still puts an unsplit `full_name` ("Test Org B Owner", both structured columns
null on that fixture) into the first-name input's `value` attribute with the last-name input empty
-- the exact `editableNameFields` behavior, unchanged from before extraction
(`scripts/verify_display_name_refactor_test_org_b.ts`). Deployed, then the identical check re-run
live against `https://app.wowlab.ro`, real `WOW LAB` org, using `test+ui-owner@wowlab.dev` (a
fixture, not a named teammate): all five pages 200, `/admin/users` correctly shows "QA Trainer"
(a real trainer fixture's `full_name`, resolved through the shared function). No i18n changes --
pure refactor, no new user-facing strings.

**Lives in:** `lib/display-name.ts`; `app/(app)/admin/users/admin-users-client.tsx`,
`app/(app)/groups/page.tsx`, `app/(app)/groups/[id]/page.tsx`,
`app/(app)/payment-config/page.tsx`, `app/(app)/payroll/page.tsx`, `app/(app)/profile/page.tsx`;
`scripts/verify_display_name_refactor_test_org_b.ts`.

---

### 30. `WOWLAB_SAD_Catalog_Roluri.md` — a real project file, not yet in `docs/`

**Correction to an inference made this session (2026-09-03).** While cross-checking role
assignments for item 22's eight accounts, this filename turned up nowhere in this repo or its git
history and was reported to Mihai as not existing. That was wrong in scope, not narrowly wrong in
fact: the file is a real project document — external to this repo today — that has simply never
been ported into `docs/`. The "SAD documents referenced across the project" audit below only ever
checked filenames actually referenced from *within* the codebase (migrations, app code, other
docs); a document nobody has referenced in-repo yet is invisible to that check by construction,
not evidence it doesn't exist elsewhere. Mihai will place the file in `docs/` himself.

**Standing item:** once `docs/WOWLAB_SAD_Catalog_Roluri.md` exists in this repo, it becomes the
real source for role-catalog cross-checks — replacing the weaker substitute used for item 22 (the
live `roles` table plus whatever role assignments happen to be documented elsewhere). Until then,
that substitute is what any role-catalog check in this repo has to fall back to.

**Lives in:** should live in `docs/WOWLAB_SAD_Catalog_Roluri.md` (not present as of this entry);
the "SAD documents referenced across the project" section below (scope corrected there too); item
22's 2026-09-03 addendum (the role-catalog cross-check this gap affected directly).

---

### 31. `anka@asismart.ro` holds all 11 non-superuser roles — deliberate, confirmed by Anca, not test state

The SAD-comparison report done this session (2026-09-03/04, not previously written to this file)
found a real, non-test account — Anka Orban, `anka@asismart.ro` — holding `contract_administrator`,
`finance_admin_reporting`, `finance_operations`, `inventory_custodian`, `evaluator`,
`curriculum_manager`, `candidate`, `community_people`, `operations_manager`, `sales_manager`, and
`senior_trainer` simultaneously, all in `wow-lab`, all assigned in one batch on 2026-08-14 by
`anca.tanasescu@gmail.com`. Flagged at the time as pattern-matching a testing session (every role
but the two superuser ones, assigned together, with a `disabled`→`enabled` cycle inside the same
hour) rather than a real, intended grant.

**Confirmed by Anca, 2026-09-04: this is deliberate, not leftover test state — she keeps all 11.**
Anca's stated grounds: roles are changeable from the app at any time, so there is no cost to a
broad grant that isn't easily reversed later — the concern that made this look like an anomaly
(an unusually wide, all-at-once grant) doesn't hold the same weight when reversing it is a normal
`editRoles` call away, not a migration or a data fix.

**The substantive reason, from Anca, 2026-09-08 — not just the meta-reasoning above for why a broad
grant is low-cost.** Anka covers Laura's responsibilities during Laura's maternity leave, which is
exactly why the role set needs to be this wide: Laura's own real set is `finance_operations` +
`contract_administrator` (item 22), and covering for her plus holding Anka's own normal
responsibilities is what actually accounts for the breadth, not an unexplained maximal grant. This
is the concrete "why," on top of the "why it's safe to leave broad" already recorded above.

**This explicitly includes `evaluator` — worth being precise about, given `evaluations_confidential`
(OD-7).** `evaluator` carries `evaluations.assigned.read`/`evaluations.assigned.write`. Anca's own
policy setting is that evaluations are confidential under OD-7. Holding both the policy-setting
authority and the `evaluator` capability on the same account is therefore a deliberate access
decision by the person who owns that policy, not an oversight that happens to intersect with it —
recorded explicitly so this does not get re-flagged as an anomaly by a future pass that finds the
same combination and assumes, as this session initially did, that it looks like test residue.

**No fix proposed here — do not act.** This entry exists so the next person (or the next session)
who runs a similar audit finds the answer already recorded, instead of re-discovering the same
"looks like a testing session" pattern and re-flagging it as unresolved.

**Lives in:** `public.users`, `user_org_roles` (live data, `wow-lab`); `org_settings.
evaluations_confidential` (OD-7, the policy this account's `evaluator` grant intersects); the
SAD-comparison chat report, 2026-09-03/04 (where this was first found, not previously written here).

---

### 32. Email OTP expiry raised from 1 hour to 24 hours

**Why:** of six real invitations sent the morning of 2026-09-04, three (Laura, Teodora, Luiza Mirt)
lapsed unopened within the hour — confirmed live, not inferred: `auth.one_time_tokens` cross-
referenced against `auth.users.last_sign_in_at` for all six showed the other three activating within
minutes of being sent, while these three's token rows sat unconsumed past the 1-hour `otp_expiry`
window with no sign-in recorded. `supabase/config.toml` `[auth.email]` `otp_expiry`: `3600` → `86400`
(1h → 24h). Confirmed this reached the live project both ways: `supabase config push` prints a
pre-push diff against the *remote* config before writing anything — the diff for this push showed
`otp_expiry = 3600` on the remote side, matching what `config.toml` already said, so the value being
raised was a real, live one, not a stale local assumption; a second, immediate push then reported
"Remote Auth config is up to date" with no further diff, confirming `86400` had landed.

**The tradeoff, stated plainly, not left implicit:** a longer window only helps someone who still
has inbox access and simply hasn't opened the email yet. It does nothing for a link already
consumed by something other than the intended person — a prefetch, a mail-client link scanner — nor
for someone who's given up and deleted the email. For those cases the only real remedy is still a
fresh resend (`resendInvitation()`, `db280ac`), unaffected by this change.

**Single-use behavior is unchanged and unaffected by this setting.** Confirmed already in this
session (previous report) and previously in this repo (`item 28`): consumption and expiry are two
independent failure paths through the identical `verifyOtp` call, both producing the same generic
`auth-callback-failed` banner. Raising `otp_expiry` widens the *time* window; it does not make a
once-clicked (or once-prefetched) link work twice.

**`supabase/templates/invite.html`:** "will expire shortly" → "will expire in 24 hours" (the actual
figure, not a vaguer restatement); the single-use warning in the same sentence is untouched, since
that's the half that actually causes real failures. This template serves invitations only —
confirmed via `config.toml`'s `[auth.email.template.invite]` mapping — not magic-link sign-ins,
which use the separate `magic_link.html`.

**Correction, same day: fixing `invite.html` alone was the wrong scope.** `magic_link.html` carries
the identical vague wording (twice — inline body copy and footer) and is the template
`resendInvitation()`'s "Resend invitation" button actually sends — the mechanism that reaches
Laura, Teodora, and Luiza Mirt specifically. Fixed the same way, both occurrences: "expires
shortly"/"will expire shortly" → the real 24-hour figure, single-use warning untouched. Pushed and
verified the same way — the push whose only purpose was this template change showed exactly one
diff hunk (the template content), confirming nothing else in the `[auth]` block had drifted since
the previous push; a following push reported "up to date" with zero remaining diff.

**An unintended side effect of the same push, found and corrected in this same session, not left
to be discovered later.** `config push` sends the entire `[auth]` block as one object, not per-
field. The first push's own pre-push diff showed the *remote* project carrying four
`additional_redirect_urls` entries (`app-wow-lab-wowlab-ro-anca-tanasescu-...vercel.app` variants)
that were never present in `config.toml` — live drift that predates this session, unrelated to
`otp_expiry`. That push briefly removed them from the live allow-list as a side effect of writing
`otp_expiry`. Restored in `config.toml` and pushed again within the same session, confirmed via a
third push reporting "up to date" with no remaining diff. Origin of that drift unconfirmed —
plausibly a second Vercel project alias/rename this file was never updated for, same class as the
original four URLs' own "already live, do not remove" comment, just one file-update further behind.
Not sent to Laura, Teodora, or Luiza Mirt — their original links are already past the old 1-hour
window; whether to resend now that the window is longer is a decision left open, not made here.

**Full `[auth]` drift audit, requested separately, reported not acted on.** Asked whether any other
field differs between live and `config.toml`, in either direction, beyond the redirect URLs already
found and fixed. The honest answer required by the question itself: `config push` is the only
inspection mechanism available (checked — no `--dry-run`/diff-only flag exists, and this project has
no Management API credentials wired into any session), and it is not a safe read: in this
non-interactive context it computes the diff and applies it in the same operation, with no pause
between (the confirmation gate is skipped under `--agent auto` — already established 2026-07-15, see
that date's progress.md entry). **The only inspection tool is also the thing that overwrites** — any
value set through the dashboard and never written back to `config.toml` is invisible until the next
push, at which point it is silently replaced, not surfaced for review first. Not a new problem
introduced by anything above; the redirect-URL drift is a direct instance of exactly this risk, just
one that happened to be self-correcting because the push that would have erased it silently was
inspected before moving on, not because the tooling caught it. No new drift beyond the redirect URLs
was found: a diff run for an unrelated, single-field change (the `magic_link.html` fix above) would
have shown any other difference too, by construction — a diff compares the whole object, not just the
field being changed — and none appeared, then or on the confirming re-run. That is current as of the
last push this session, not a standing guarantee; nothing here watches for drift introduced after.

**Lives in:** `supabase/config.toml` (`[auth.email]` `otp_expiry`, `additional_redirect_urls`);
`supabase/templates/invite.html`; `supabase/templates/magic_link.html`; `auth.one_time_tokens`,
`auth.users.last_sign_in_at` (live data cross-referenced); item 28 above (single-use-vs-expiry, the
prior evidence this session's finding matches).

---

### 33. 30 May workshop roster vs. Appendix A — compared, not assumed; Appendix A is the baseline

Checked rather than taken on faith that these are simply earlier/later snapshots of the same thing.

**Every name common to both grew or held, none shrank.** 10 of the 30 May roster's 27 names also
appear in `WOWLAB_SAD_Contracte_Trainer_Furnizor.md` Appendix A (25 June 2026): Cătălina Trușan
(820→827), Sonia Ganea (208→212), Andrada Eremia (182→186), Teodora Merișan (89→101), Raluca Popa
(15→22), Alina Garofil (4→5) — all higher, consistent with a later snapshot. Elena Bacalum (118),
Alexandra Nuțu (89), Viorel Tobosaru (41), and Răzvan Bălașov (3) are **identical in both** — flat
over the ~26 days between the two dates, not a violation of "counts can only grow," but worth
recording: 4 of the 10 delivered nothing in that window, or their figures weren't refreshed for the
25 June pull. **No name is lower in Appendix A than in May** — the "these are earlier/later
snapshots of the same roster" premise holds on every overlapping name.

**Total delta across the 10 common names: +35 workshops** over ~26 days (7+4+4+0+12+0+0+7+1+0).
Concentrated in 6 of the 10 people; the other 4 contributed zero.

**17 of the May roster's 27 names do not appear in Appendix A at all**: Diana Fainarea, Andreea
Minea, Diana Pricopi, Andreea Grulic, Diana Gardus (Cocea), Fatima, Sanziana, Diego, Tudor Nedelcu,
Darius Mirea, Mirela Popa, Andreea Tudor, Maria Nicolescu, Adelina Paduraru, Alexandra Gruia, Gita
Adelina, Andra Onas — several with substantial career counts (Diana Fainarea 224, Andreea Minea 225,
Diana Pricopi 191), so this isn't "the small contributors dropped off." **One name, Luiza Mirt,
appears in Appendix A with no May counterpart and no number** ("necunoscut"). This 27-vs-11 split is
not new information invented by this comparison — it matches, almost to the number, what
§12.10 of the same document already states: *"11 traineri activi azi, nu cei 27 din fișierul de
urmărire folosit la verificarea din §12.2 — fișierul e istoric, nu curent."* Appendix A is scoped to
currently-active trainers, not to everyone who ever appears in the tracking file — the 30 May roster
is that broader, historical file, not a rejected or wrong data source, just answering a different
question (who ever delivered a workshop vs. who's active today).

**Grade-arithmetic check on the 30 May roster: zero disagreements.** Reverse-engineered the tier
name → numeric grade mapping from the roster's own internally consistent pattern: Junior=1, Rising
Star=2, Enthusiastic Mid=3, Experienced Mid=4, Glowing Senior=6 (all nine "Glowing Senior" rows
compute to exactly 6 via `min(6, floor(n/36)+1)` on their own printed count). Checked all 27 rows
against this mapping: every single one matches its own arithmetic exactly. No manual overrides
found in this roster. One real gap in what this can prove: nobody in the May roster falls in the
grade-5 range (144–179 workshops — the closest are Elena Bacalum at 118 and Fatima at 180), so
whether "Glowing Senior" also covers grade 5, or grade 5 has its own unlisted tier name, can't be
determined from this data alone.

**Update, 2026-09-07: grades 5 and 6 do have separate names — just not in this roster.** Anca's pay
grid names them distinctly: **"Magic Senior"** for grade 5, **"Glowing Senior"** for grade 6. The
trainer roster (this item's own May data) uses one label, "Glowing Senior," for both — every person
who reached grade 5 or 6 in that snapshot happened to already be at 6, so the roster's own naming
convention was never actually exercised at grade 5 to know whether it would say "Magic Senior" there
or collapse it into "Glowing Senior" too. Still unresolved, and still no practical impact — nobody
currently active occupies that band — but it's a labeling question to settle before someone does,
not purely academic anymore now that the two names are confirmed to exist and differ somewhere in
this system.

**Directive, now backed by the comparison above rather than asserted ahead of it: Appendix A
(25 June 2026) is the current workshop-count baseline. The 30 May roster is superseded and must not
be used for grade computation** — not because it's wrong, but because it's older, and every
overlapping figure it holds is confirmed lower or equal, never higher.

**Appendix A is dated but not citably sourced.** It dates itself three times, unambiguously: in its
own header ("Anexă A — Baseline-ul numărului de workshop-uri, validat (25 iunie 2026)"), in its body
("ancorat la o dată fixă (25 iunie 2026)"), and in its table caption ("Baseline-ul, la 25 iunie
2026"). Its stated source is generic, quoting exactly: **"Calculat din fișierul lor de urmărire"**
("Calculated from their tracking file") — no filename, no link, no named document, just a
description. The calculation cannot be reproduced from the document alone; anyone needing to
re-derive or re-verify it has to go back to whoever holds "their tracking file," which this
document never identifies more specifically than that.

**No fix proposed here** — a workshop-count source issue, not a code issue.

**Lives in:** `WOWLAB_SAD_Contracte_Trainer_Furnizor.md` Appendix A; the 30 May 2026 roster
screenshot (external, not in this repo); item 22 above (name-variant discrepancies this comparison
partly resolves); item 34 below (Anca's current active roster, which supersedes both tables as a
staffing list, though not as a workshop-count source — those are different questions).

---

### 34. Anca's current active roster (2026-09-07) — supersedes both historical tables as a staffing list

Neither the 30 May roster nor Appendix A (item 33) is a current staffing list — both are
workshop-count snapshots, and Appendix A's own text says as much (item 33: scoped to "active
today" only for the purpose of validating the grade formula, not maintained as a roster). Anca has
now sent the actual current list, which is the real answer to "who works here":

**Active (11):** Cătălina Trușan, Sonia Ganea, Alexandra Nuțu (Cluj), Andrada Eremia, Teodora
Merișan, Raluca Popa, Alina Garofil, Răzvan Bălașov, Elena Bacalum (reserve), Viorel Toboșaru
(Cernavodă), Luiza Mirt (possible return).

**On trial, possible addition:** Lorina (no surname given yet).

**Not trainers:** Raluca Margean (articles — consistent with item 22's finding that "trainer" was
the wrong role for her); Laura (invoices, currently on maternity leave — this project's own records
call her "Laura Moale," Anca's current wording says "Laura Preda"; reported separately this session,
not yet recorded here as its own item since it was asked as report-only).

**No longer active (9):** Fatima, Sânziana, Diego, Bianca Necula, Mihai Popa, Roxana Vasile, Ene
Vladimir-Lucian, Bordea Daria, Gabriela Enache.

**Cross-referenced against item 33's 17 May-only names, not just recorded side by side.** Only 3 of
those 17 — Fatima, Sânziana, Diego — were confirmed "no longer active" by Anca's list at the time.
The other 14 (Diana Fainarea, Andreea Minea, Diana Pricopi, Andreea Grulic, Diana Gardus (Cocea),
Tudor Nedelcu, Darius Mirea, Mirela Popa, Andreea Tudor, Maria Nicolescu, Adelina Paduraru,
Alexandra Gruia, Gita Adelina, Andra Onas) appeared in neither Anca's active list nor her
no-longer-active list. **Closed by Anca, 2026-09-08:** these fourteen are former collaborators who
may be reactivated for large projects like Școala Altfel — not added to the platform for now, and
not the same status as the 9 already named "no longer active" (which reads as a more settled
departure than "may come back for the right project"). Separately, 6 of Anca's original 9
"no longer active" names (Bianca Necula, Mihai Popa, Roxana Vasile, Ene Vladimir-Lucian, Bordea
Daria, Gabriela Enache) still appear in neither the May roster nor Appendix A at all — people who
left before or outside the window either table covers; unrelated to the fourteen above.

**RESOLVED, 2026-09-08.** The five — Sonia Ganea, Andrada Eremia, Alina Garofil, Elena Bacalum,
Viorel Toboșaru — got addresses from Anca and accounts the same day (`978be3b`, same procedure as
item 22's original eight), and invitations went out to all five within minutes of creation. All
**11** of Anca's active trainers now have an account in `wow-lab`. Verified live, not assumed:

- **Signed in already:** Cătălina Trușan, Sonia Ganea, Alexandra Nuțu, Andrada Eremia, Teodora
  Merișan, Alina Garofil, Răzvan Bălașov.
- **Outstanding invitation, not yet consumed, not expired:** Elena Bacalum and Viorel Toboșaru —
  each holds one unconsumed token from 2026-09-08, well inside the 24h window (item 32).
- **Invitation lapsed, never signed in:** Luiza Mirt — her one token on file is from 2026-09-04,
  four days stale under any expiry setting this project has used. Not resent: this same item lists
  her as "possible return," not confirmed active — her return is conditional per Anca, so a fresh
  invitation link may be premature ahead of that confirmation, not just outside today's scope.
- **Raluca Popa** shows a sign-in today, 2026-09-08, but that timestamp is this session's own RLS
  verification script re-authenticating her account for a `contracts` capability test (item 37) —
  not new independent activity by her. Her genuine sign-in is the one already on record from
  2026-09-03/04 (item 22); `auth.users.last_sign_in_at` only ever holds the most recent value, so
  the earlier, real one is no longer separately visible in that column.

**Lives in:** `public.users`/`auth.users`/`auth.one_time_tokens` (live data, checked this session);
`scripts/create_five_more_wow_lab_trainers.ts` (`978be3b`); item 22 above (the original eight real
accounts, same pattern this repeated); item 33 above (the two historical tables this roster
supersedes as a staffing statement); item 23 above (the ~20-people correction this roster
triggered); item 37 (the verification work that touched Raluca Popa's `last_sign_in_at`).

---

### 35. "Laura Moale" — RESOLVED: the surname is correct. The check was right; this item's own conclusion was not.

**Confirmed by Anca, 2026-09-08: "Moale" is correct.** Laura Moale is Cătălina Moale's
sister-in-law; "Preda" is Laura's maiden name — the surname changed at marriage, both names are
genuinely hers, and "Moale" is the one that belongs on the account. Nothing about the account
changes: `public.users`, `auth.users.raw_user_meta_data`, the mockup, and every prior doc mention
were already correct. This entry stays open in edited form rather than being deleted, because the
part worth keeping isn't the outcome — it's that the process which produced the wrong hypothesis is
exactly the process that's supposed to catch this class of error, and it's worth being honest about
where it fell short.

**What this item originally got wrong.** The working hypothesis recorded here was that "Moale" was
contamination from "Cătălina Moale" — a plausible-sounding mix-up between two people who happen to
share both a first initial's context (both connected to the same spreadsheet) and, coincidentally,
a surname. The real explanation was more mundane and entirely different: a genuine family
relationship (sister-in-law), not a data-entry confusion at all. The share surname was never a
coincidence to explain — it was the actual fact, sitting in plain view, and the hypothesis reached
past it toward a more interesting-sounding failure story instead.

**The general lesson still holds, sharpened by getting the specific case wrong.** The surname
genuinely was unsourced in this project's own record — that part of the check was correct and worth
doing regardless of outcome, since acting on Anca's single "Preda" message and overwriting a real
person's account would have been exactly as wrong, in the other direction, as never having flagged
"Moale" as unsourced in the first place. What this item adds on top: **checking that something is
unverified is not the same as being able to guess correctly why it looks the way it does.** The
provenance research two sessions ago (the mockup predating item 22 by a month, the same-day
prose/HTML disagreement) was real, checked, correct work — and none of it, however thorough,
amounted to evidence for *why* "Moale" appeared, only for *when*. The "contamination" story filled
that gap with something plausible instead of leaving it open. Record the check as the right call
and the conclusion it produced as a separate, wrong thing — not because the checking failed, but
because a plausible-sounding causal story was treated as more than an unconfirmed guess, which is
the same shape of error this item was written to warn about in the first place, just one level up.
This is the same failure class as the Raluca Margean role assignment (item 22): a detail that
sounded right, wasn't checked as hard as the parts that could be checked, and stood until it
mattered enough to look.

**New, forward-looking: Cătălina Trușan will return to the surname Moale after her divorce.** Her
account (`catalina_moale@yahoo.com`) is under Trușan today — not a change to make now, Anca was
explicit about that — but once it happens, **two active people will share the surname Moale**
(Cătălina and Laura), on top of already being distinguishable only by the coincidence this item
spent two sessions investigating. Worth remembering when that day comes: a display name collision
between two real, active, unrelated-by-that-surname people, arriving from a direction nobody was
watching for.

**Lives in:** `docs/mockup/wow_lab_os_mockup.html`; `docs/OPEN_ITEMS.md` item 22 (the account this
surname belongs to, and the Raluca Margean parallel); `docs/progress.md` entries 25 and 68;
`scripts/create_eight_real_wow_lab_accounts.ts`; `public.users` and `auth.users.raw_user_meta_data`
(live data, `lauraflorentinaa220@gmail.com` and `catalina_moale@yahoo.com`). See also item 48 below
— the second and third instances of this same failure shape (AD-10, `business_line`), both caught
the same way this one eventually was: by checking, not by noticing.

---

### 36. Permanent-group assignments — a count of four, pending one confirmation that may make it five — OVERDUE for its own re-verify date as of 2026-09-18

From Anca, 2026-09-08, not derived or inferred: Raluca Popa will have permanent groups, likely at
IBSB, pending the school's own confirmation expected next week. The permanent-group list — who is
allocated to a recurring group on an ongoing basis, as opposed to per-session/rotating allocation —
is **four people today** and may become **five** once IBSB confirms. The four aren't named here;
this project's own convention (§12.10 of `WOWLAB_SAD_Contracte_Trainer_Furnizor.md`) is that
current-roster names belong in the database once there's a real table to hold them, not
architecture documents, and there's no `groups`-adjacent "permanent assignment" table yet to check
this against — recorded here as the pending business fact, not as a data correction.

**Re-verify next week.** If IBSB confirms, the list becomes five and Raluca Popa's permanent
assignment is real; if not, it stays four and this note can close without further action either
way.

**No fix proposed here** — nothing to build yet, no table this maps to today.

**Flagged 2026-09-18, not resolved — this is a due-date check, not a finding.** "Next week" from
2026-09-08 has passed; ten days on, nothing in this file or `progress.md` records an IBSB answer
either way. Unlike item 19 above or items 39/45 below, nothing here is factually wrong — the count
may genuinely still be four, or IBSB may have confirmed and nobody wrote it down, and this entry can't tell the
difference; there's no code or data this maps to yet for a live check to run against, per its own
"no fix proposed" line. Recorded so the next person reading this knows the date has passed without
implying an answer either way — ask Anca again rather than trust "four" or assume "five."

**Lives in:** Anca's confirmation, 2026-09-08 (not yet in this repo in any structured form); the
eventual `groups`/allocation schema, whenever a "permanent vs. rotating" distinction gets modeled.

---

### 37. Contracts write-side finance exclusion removed — RESOLVED by Anca's decision, 2026-09-08

The INSERT/UPDATE policies on `contracts` (`202608100003`) and its DELETE policy (`202608280001`)
excluded anyone holding `finance.reporting.*` or `finance.operations.*` from writing a contract,
even when they also held `contract_administrator`'s `contracts.*` capability — an unconditional
lock on write, with no alternate branch the way the SELECT policies give finance roles their own
client-type-scoped read instead. This blocked two real people, Laura and Anka, from administering
contracts — part of the `contract_administrator` role both hold
(`WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` line 120 describes Laura's own responsibilities as
including "contractele școli private").

Investigated before any change (chat report, 2026-09-06), then fixed on Anca's explicit
instruction. The two halves of the exclusion had different histories:

- **The `finance.reporting.*` half had a real, narrow reason.** It stopped
  `finance_admin_reporting` from passing the write check through the *same* `contracts.*`
  capability key that also gates read — the two roles share that key, and without the exclusion a
  read-only finance role would have silently gained write access too.
- **The `finance.operations.*` half had no recorded reason.** Nothing in `202608100003`'s own
  comment, in the SAD, or in git history justifies it independently — it blocked a role
  combination (`contract_administrator` + `finance.operations.*`, Laura's actual role set) that
  did not exist in the org when the exclusion was written.

**Anca's decision, accepted as her own tradeoff, not a neutral default:** contract_administrator
holders write contracts regardless of any finance role also held. She is accepting that the same
person who writes a contract's terms may also be the one who invoices on them, rather than keeping
those as two separate people's jobs.

**What changed:** `supabase/migrations/202609080001_remove_contracts_write_finance_exclusion.sql`
drops and recreates the three write policies (INSERT, UPDATE, DELETE on `contracts`) without the
two `NOT has_capability(...)` branches. `canManageContracts()` in `app/(app)/contracts/page.tsx`
and its duplicate in `app/(app)/contracts/[id]/page.tsx`, and the delete check in
`app/(app)/contracts/actions.ts`, were simplified to match — each now just
`isOwner || hasContractsStar`. Rollback at
`supabase/rollbacks/202609080001_remove_contracts_write_finance_exclusion_rollback.sql` restores
the original predicate if this decision is ever reversed.

**Deliberately left untouched:** the SELECT policies on `contracts`, `clients`, and
`client_contacts`. There, the same-looking exclusion is not a lockout — it routes finance-role
holders to their own client-type-scoped read branch, which is the read segregation the SAD does
specify and Anca did not change.

**Verified live, as the real users, not service role:** Laura and Anka can each insert, update,
and delete a contract; a trainer's insert is rejected by RLS; Laura's read still returns only the
private-school contract in a mixed fixture, not the corporate one. Browser-verified end to end as
Laura against a live dev server: "+ New contract" visible, a contract created, opened, edited
(entry number saved), and marked signed. Fixture rows removed afterward — `contracts` and
`clients` confirmed back to `0` in `wow-lab`.

**Not extended, at the time this item was written:** `client_contacts`'s INSERT/UPDATE policies
(`202608100003`) carried the identical write exclusion and would block the same two people from
managing a client's contacts — a task that same migration's own comment describes as belonging to
whoever administers that client's contract. Reported, not fixed, in this item: Anca's decision
above was about `contracts` specifically, and this was a separate question pending her own answer.
**Resolved 2026-09-11 — see item 51 below**, which is that second answer.

**Lives in:** `supabase/migrations/202609080001_remove_contracts_write_finance_exclusion.sql` (its
own header quotes the two superseded comments in full and traces this decision);
`supabase/rollbacks/202609080001_remove_contracts_write_finance_exclusion_rollback.sql`;
`app/(app)/contracts/page.tsx`, `app/(app)/contracts/[id]/page.tsx`, `app/(app)/contracts/actions.ts`;
item 51 below (the `client_contacts` extension of this same decision).

---

### 38. `groups.children_billed` masking — RESOLVED, answered by Anca opposite to the SAD's guess

`WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md` §4 left this open explicitly, not silently:

> "Field: fără câmpuri financiare sensibile pe acest domeniu direct (billing_rule rămâne pe
> contracts) — dar `children_billed` ar putea avea sens mascat pt Operations, de decis la
> construcție (nu blocant)." — *(No sensitive financial fields on this domain directly — but
> children_billed might make sense masked for Operations, to be decided at construction time. Not
> blocking.)*

That decision point was never revisited. What got built instead settled it by default: both
`children_confirmed` and `children_billed` render through `ValueCell` — the identical shared
component (`components/ui/data-table.tsx`) that does real, capability-gated masking for contracts'
financial fields (`visible={financeVisible}` there) — but called here with `visible={true}`
hardcoded, in all three places these fields appear (`groups-client.tsx`'s list columns,
`group-detail-panel.tsx`'s expandable row, `group-info-section.tsx`'s detail page). The component's
own comment in `group-detail-panel.tsx` states this as settled fact: *"ValueCell here has no
capability/masking dimension (visible is always true)."* That comment describes a decision nobody
actually made — the SAD only ever deferred it, "de decis la construcție," and construction picked
the easiest default (no masking) without anyone confirming that was the right call. Pending Anca.

**No fix proposed here.** `updateGroup` (`app/(app)/groups/actions.ts`, added alongside this item)
deliberately excludes both fields from its own scope for the identical reason — see that action's
own comment header. Building either a masked read path or an editable one ahead of Anca's answer
would settle the same open question a second way, just as silently as the first time.

**The general pattern, not just this one field.** This is the eighth instance surfaced in this
project of written text describing a state that was never actually decided, or that used to be true
and no longer is: `users.status` claiming a value no code path maintains (item 21); `is_test_account`
silently unset across eight independent write sites (item 27's original finding); a live
`config.toml` redirect-URL drift silently overwritten by an unrelated push (item 32); the SAD's own
`operations_manager`+`curriculum_manager` merge, applied everywhere in `seed.sql` except the one
place still gated on an unchecked approval box (item 30); the `contracts` finance-exclusion's
`finance.operations.*` half, carrying a "load-bearing, not decorative" comment for a reason nobody
ever recorded (item 37, just above); the `row_history`/`audit_log` masking gap, tracked as its own
deferred SAD checklist (`WOWLAB_SAD_Field_Masking.md` §5); and now this one. Deferred decisions do
not stay visible on their own — nothing marks them as still-open once code ships around them. They
get implemented as whichever default was easiest to write, and the code that results reads exactly
as if the question had been settled, to anyone who didn't already know it hadn't been. Worth
treating as a standing review question for any future "de decis la construcție" note in a SAD: check
whether construction actually decided it, or just picked a default and moved on.

**Resolved, 2026-09-08 — Anca answered, and the answer runs the opposite direction from the SAD's
own guess.** The SAD speculated masking might apply *to Operations* (Cătălina) on `children_billed`.
Anca's actual rule is the reverse: the **child counts** (`children_confirmed`, `children_billed`,
and `sessions.attendance_count`) are visible to everyone, Cătălina and trainers included — what has
to stay hidden from both of them is the **invoiceable amount**, a number that doesn't exist in this
codebase yet. So `ValueCell`'s hardcoded `visible={true}` on both count fields turns out to be
*correct*, by coincidence, not because anyone had decided it was — the comment asserting "no masking
dimension here" was still describing a decision nobody had made, even though the eventual answer
landed on the same default. The full decision, its reasoning, and the four other findings from the
same investigation are recorded in item 39, immediately below.

**Worth naming plainly: the answer only exists because the omission was written down instead of
left silent.** This item's own original finding — the SAD deferred the question, and construction
picked a default without saying so — is what put a concrete question in front of Anca to answer at
all. Had `ValueCell`'s `visible={true}` simply shipped without this item ever being written, the
default would have stood indefinitely, indistinguishable from a real decision, exactly as described
above for `users.status`, `is_test_account`, and the rest. The general pattern's fix isn't
"guess less" — it's "write the omission down where someone will read it," which is what closed this
one.

**Lives in:** `docs/WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md` §4;
`components/ui/data-table.tsx` (`ValueCell`); `app/(app)/groups/groups-client.tsx`,
`app/(app)/groups/group-detail-panel.tsx`, `app/(app)/groups/[id]/group-info-section.tsx` (all three
render sites); `app/(app)/groups/actions.ts` (`updateGroup`'s own scope comment); item 39 (the full
decision record).

---

### 39. `children_confirmed`/`children_billed` — CORRECTED 2026-09-18: findings 2 and 3 were built 2026-09-11 and never marked; finding 1 is now buildable

Anca's answer to item 38's masking question came with the full picture of how these two fields
actually work, which changes what gets built and where. Recorded here as five separate findings —
they don't all point at the same fix.

**1. `children_billed` should not be a writable field at all — derived, not stored, same precedent
as contract expiry.** Anca: *"the children actually present. Entered by trainers, at the session."*
That's a per-session fact. The SAD's own §6 already names the aggregate as the real billing input:
*"Facturarea viitoare va deriva din `sessions.attendance_count` agregat, nu din fișe nominale"* —
future billing derives from `sessions.attendance_count`, aggregated, not from `children_billed`
itself. A single group-level integer cannot faithfully represent a `recurring` group's many
sessions, each with its own, possibly different, attendance — only a single-occurrence group
(a party, one corporate workshop) collapses the two to the same number, and only by coincidence.
Storing `children_billed` as its own writable column would recreate the exact risk this codebase
already ruled against for `contracts.status = 'expired'` (`docs/OPEN_ITEMS.md`'s "Contracts past
`period_end` stay `signed`" entry: *"Contract expiry stays derived, on purpose... every reader
computes `is_expired`... at query time"*) — two stored representations of one fact, with nothing
keeping them in sync. **Decision: `children_billed` is computed at read time as
`SUM(sessions.attendance_count)` for the group (likely filtered to `status = 'delivered'`), never
written directly. Not built now** — it depends on finding 2 below being fixed first.

**2. The real gap, and it blocks any billing work, not just this field: nobody can record what
actually happened at a session.** `attendance_count` is writable in exactly one place —
`NewSessionForm` (`group-detail-client.tsx`) — gated on `sessions.create` (Operations Manager +
Master), and only **at the moment a session is created**, before it has happened. Confirmed on
every layer: `trainer`/`senior_trainer` hold `mywork.*`, `curriculum.read`, `community.read`,
`finance.own.read`, `materials.custody`, `presentations.own` (`supabase/seed.sql`) — nothing that
reaches `sessions.create`. The `sessions` INSERT/UPDATE RLS policies (`202608130003`) check only
`is_platform_owner() OR org.settings.manage OR sessions.create` — `mywork.*` appears in the SELECT
policy alone, never INSERT or UPDATE. `updateSessionAllocation`, the only post-creation edit action
that exists, is deliberately scoped to `trainer_principal_id`/`trainer_secundar_id` only (its own
comment says so). Anca says trainers enter attendance; today they structurally cannot, on any layer,
and neither can anyone else after a session is created. **This blocks finding 1 above and any real
billing computation** — there is no correct aggregate to compute from a fact nobody can actually
record. Needs Anca's confirmation before it's buildable: does she want trainers writing attendance
directly (new capability, new RLS policy, new UI), or reporting it to Cătălina who enters it
(no new capability, just a missing post-creation edit path)? Different answers, different scope.

**3. `children_confirmed` is writable in principle, blocked by RLS today, and needs a different
capability than `groups.create`.** Anca: filled in by Anka and Laura. Checked what they actually
hold: `finance_operations` (Laura) and `finance_admin_reporting` (Anka) both grant `groups.read`
only (`supabase/seed.sql`) — neither holds `groups.create`, the *only* capability the `groups`
UPDATE policy (`202608130003`) checks. What Laura and Anka actually share is `contracts.*`
(`contract_administrator`, confirmed live in item 37's own verification) — matching
`children_confirmed`'s real nature as a contract-side fact ("the count agreed in the contract, or
confirmed by the school's representative"), not an operational one. **Needs an RLS change** — a new
UPDATE policy branch (or an added condition on the existing one) admitting `contracts.*`, not just
`groups.create` — before any form can work for the people who are supposed to use it. Cătălina
(`operations_manager`) already reads both counts under the existing SELECT policy (Operations
Manager sees every group/session in the org, §4's Record-level design) — confirmed, no gap there.
She should **not** gain write on `children_confirmed`: Anca said see, not fill, and she doesn't hold
`contracts.*` anyway, so the capability boundary already matches the intent without changing
anything.

**4. Masking rule, recorded as a constraint on a feature that doesn't exist yet, not implemented
against fields that don't exist.** See item 38's resolution above for the full reversal. Checked
exhaustively for anywhere an invoiceable amount could already be computed or shown: none —
`billing_rule` is plain free text, `offer_structure` is a stored pricing-model classification with
zero code ever reading it to compute anything (its own column comment: *"NOT financially
sensitive... plain passthrough"*), and no query anywhere joins either against `children_confirmed`,
`children_billed`, or `attendance_count`. `docs/phase1-development-plan.md` row 11 ("Generator cod
facturare") is listed 🔴 **Nefăcut** — a real, named, unbuilt feature. The rule itself — child counts
open to everyone including trainers, the eventual invoiceable amount hidden from Cătălina and
trainers both — is now recorded in `docs/WOWLAB_SAD_Field_Masking.md` §2.7, as a constraint that
feature has to satisfy when it's built, not as masking logic written against fields that don't exist
today.

**5. Both count fields should be gated by `delivery_format` — three formats confirmed, one open.**
Anca scoped her answer explicitly to `scoala_altfel`, `saptamana_verde`, `party`, and `corporate` —
four of the six `delivery_format` values — as the per-child formats where any of this applies.
`recurring` (the fixed-sum, ongoing school-club format) was not named, and finding 1's own
structural argument explains why it wouldn't fit the same way. **`custom` is unanswered** — Anca's
scoping doesn't cover it either way, and it must not be guessed at construction time the way
`delivery_format`'s own split from "Tip atelier" already was once, accepted as risk, in this same
SAD (§3). A direct question, not an assumption, when this is built.

**At the time this was written: nothing built yet, deliberately — the decision record ahead of
construction, not a retrofit after.** Finding 2 gates findings 1 and (functionally) 4; finding 3
needs Anca's own RLS scope confirmed before a form is written for it; finding 5's `custom` case
needs a direct answer. **That framing held for three days.**

**Corrected 2026-09-18, checked against the live code, not against this item's own text.** Findings
2 and 3 both describe a blocker that stopped being true on 2026-09-11 — three days after this item
was written — and neither this item nor anything that read it since noticed.

- **Finding 2 — resolved.** `updateSessionAttendance` (`app/(app)/groups/actions.ts`) is live: the
  assigned trainer (row-matched on `trainer_principal_id`/`trainer_secundar_id`, gated on
  `mywork.*`, plus a payroll month-close check) writes their own `attendance_count`/
  `experiment_delivered` after the session, through a real UI ("record attendance" on
  `/groups/[id]`). The code's own comment dates the underlying decision to 2026-09-11: *"The
  assigned trainer recording their own session (Anca's decision, 2026-09-11)."* "Nobody can record
  what actually happened at a session" is no longer true, and has not been true since the day after
  finding 2 was written.
- **Finding 3 — resolved.** `supabase/migrations/202609110002_add_groups_update_contracts_star_branch.sql`,
  same date, adds exactly the `contracts.*` branch this finding names to the `groups` UPDATE
  policy — its own header quotes this finding's own reasoning back, near-verbatim. `updateGroup`
  (`app/(app)/groups/actions.ts`) narrows the write to `children_confirmed` alone, gated on
  `canWriteChildrenConfirmed`, confirmed live in `groups/[id]/page.tsx`. Laura and Anka can fill it;
  Cătălina still cannot — exactly the boundary this finding asked for, not a broader grant.
- **Finding 1 — was blocked on finding 2 alone, and is therefore buildable now, not blocked.** The
  derived read (`SUM(sessions.attendance_count)`, likely filtered to `status = 'delivered'`, per
  this finding's own already-decided shape) now has real data to sum, since finding 2 shipped.
  Checked live: `groups.children_billed` is still the plain stored column, read as-is
  (`groups/[id]/page.tsx`, `groups-client.tsx`, `group-detail-panel.tsx`), never written by any
  action, never derived — the decision recorded above was never implemented, not because it's still
  blocked, but because nobody went back to build it once its blocker cleared.

Findings 4 and 5 are unaffected by any of the above — finding 4 still waits on the billing generator
existing at all (`phase1-development-plan.md` row 11, still 🔴), and finding 5's `custom` gap still
waits on Anca. Only findings 1-3 were ever blocked on the attendance gap; only those three needed
this correction.

**Lives in:** `docs/WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md` §2/§4/§6;
`docs/WOWLAB_SAD_Field_Masking.md` §2.7; `docs/phase1-development-plan.md` row 11;
`supabase/migrations/202608130003_add_groups_sessions_rls_policies.sql`,
`202609110002_add_groups_update_contracts_star_branch.sql`,
`202609110003_add_sessions_update_trainer_branch.sql`,
`202609110004_require_mywork_capability_on_sessions_trainer_branch.sql`; `supabase/seed.sql`
(role/capability grants); `app/(app)/groups/actions.ts` (`addSession`, `updateSessionAllocation`,
`updateSessionAttendance`, `updateGroup`); `app/(app)/groups/[id]/group-detail-client.tsx`
(`NewSessionForm`, the trainer's own attendance UI); item 37 above (Laura/Anka's `contracts.*`,
verified live); item 38 above (the masking question this closes); item 45 below (part 1, the same
build recorded and left unmarked from the other side).

---

### 40. Create-form disabled-submit guards existed but could never fire — RESOLVED 2026-09-09

Found while auditing every select across the three create forms for silent wrong-default risk
(client type; contract client/legal-entity/type; group client/module/delivery-format). Fixing the
selects surfaced a second, independent defect underneath: the guards meant to gate submission on
those same fields were already written, and already looked correct, but could not have caught
anything as they stood.

**`groups-client.tsx`'s `NewGroupForm`:** `disabled={isPending || !clientId || !module ||
!deliveryFormat}` — all three checks were already there, before today's fix. None could ever
evaluate true: `clientId` initialized to `clientOptions[0]?.id ?? ""`, and `module`/`deliveryFormat`
initialized to `MODULE_KEYS[0]`/`FORMAT_KEYS[0]` — both non-empty constants, with no `<option
value="">` in either select's JSX for a user to even select an empty value through. The guard read
as protection and provided none; nothing in the UI could ever produce the state it was checking for.

**`contracts-client.tsx`'s `NewContractForm`:** `disabled={isPending || !clientId ||
!legalEntityId}` — same shape, one layer more deceptive: both selects *did* render an `<option
value="">{t("select_client")}</option>` / `select_entity` placeholder, but `clientId`/`legalEntityId`
state initialized to `clientOptions[0]?.id ?? ""` / `legalEntityOptions[0]?.id ?? ""` — the
placeholder option existed in markup and was still unreachable, because the controlled value never
held `""` for the user to be looking at it. `contract_type` had no gate entry at all — not dead, just
absent, for the identical reason (`CONTRACT_TYPES[0]`, no empty option).

**`clients-client.tsx`'s `NewClientForm`:** `disabled={isPending || !name.trim()}` — `clientType` was
never in the gate; same absence as contract type, same cause (`CLIENT_TYPES[0]`, no empty option).

**Same shape as item 21's `users.status`, a different mechanism.** Item 21 is a database column
nothing reads; this is a client-side boolean nothing could ever make true. Both are code that reads
as a guarantee — "this can't be submitted/considered active until X" — without actually being wired
to anything capable of making X false. Worth checking for elsewhere: a `disabled`/gate condition on
a field that always carries a truthy default is the same failure pattern regardless of which layer
it's written in.

**Fixed the same session:** all three creates now start their required selects on a real empty
string, via a disabled, empty-valued placeholder `<option>` (selected by default, not re-selectable)
— so `!clientId`/`!legalEntityId`/`!module`/`!deliveryFormat` now actually evaluate true until a real
choice is made, and `!clientType`/`!type` were added to their respective gates for the first time.
Group status was deliberately left alone (defaults to `"active"`, no placeholder) — a new group
being active is a reasonable default, unlike the others, where any guess is a real, substantively
wrong value.

**Lives in:** `app/(app)/clients/clients-client.tsx`, `app/(app)/clients/i18n.ts`;
`app/(app)/contracts/contracts-client.tsx`, `app/(app)/contracts/i18n.ts`;
`app/(app)/groups/groups-client.tsx`, `app/(app)/groups/i18n.ts`; item 21 below (the other instance
of this shape).

---

### 41. The client/contract/group create-form procedure lived only in an Asana message — RESOLVED 2026-09-09

The operator-facing instructions for "how to add a school" — the exact procedure item 40's fix was
written against — existed only as a message in Asana. It went stale within a day of being written
(item 40's fix changed six of its "this select comes pre-filled with X" warnings from true to false)
and nothing signalled that: no reference from any doc in `docs/`, no connection to the code it
described, nobody re-reading it on a schedule. A human was following instructions with no mechanism
that could ever tell her they'd drifted.

**Moved into `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md`,** next to the two domain SADs it
operationalizes (`WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`,
`WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md`). Two things make it checkable instead of
memory-based going forward:

- **A manifest table** at the top of the guide: every button label, option text, and default value
  the procedure asserts, each paired with the i18n key and file it's supposed to come from — so a
  claim is a lookup, not a re-read of the screen.
- **`scripts/check_operator_guide.ts`**, run by hand (deliberately not wired into any CI — none
  exists in this repo, and building one for this alone was out of scope): parses the manifest table
  and diffs each row's claimed Romanian text against the live dictionary entry. First run against
  the rewritten guide caught one real mismatch immediately — `create_contract`'s button text is
  "Creează contractul," the draft said "Creează contract" — fixed the same session, in both the
  manifest and the procedure text, then re-verified clean (30/30).

**Scope, stated plainly:** the manifest and script only cover claims that are literal i18n-dictionary
strings. Behavioral claims in the guide (lists start empty, the signed-date field defaults to today,
"cele 13 module") are code facts, not dictionary entries, and are not mechanically checked by this
script — those still rely on whoever edits the underlying form also re-reading the guide, which is
exactly why the guide's own top section states the maintenance obligation directly rather than
leaving it implied.

**Not covered even in principle:** the guide names three legal entities by their display text
(`Experimente Wow SRL`, `Brandine Advertising SRL`, `Asociația STEMplicity`) — live data, not an
i18n string, so no key exists to check it against. Confirmed live while building this item's fix:
the actual stored value is `Asociatia STEMplicity`, without diacritics.

**Correction, 2026-09-10 — this was called "a data-entry gap" above; it is not.** See item 42 below:
Anca confirmed her own name is deliberately written without diacritics in this system, which makes
`Asociatia`'s spelling the same convention, not a typo. The guide's accented spelling
(`Asociația`) is the thing that's actually inconsistent with how this system's names are written —
left as-is here rather than "corrected" a second time without asking, per item 42's own point.
Recorded originally as a manifest/script blind spot (live data has no i18n key to check it against)
— that part still stands; the "gap" framing does not.

**Lives in:** `docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md`;
`scripts/check_operator_guide.ts`; item 40 above (the code-side defect this procedure was written
to warn about, now fixed at the source instead of by warning).

---

### 42. Names are written without diacritics by convention — confirmed by Anca, 2026-09-10

`Asociatia STEMplicity` (`legal_entities`, flagged in item 41 above as a possible data-entry gap)
is not a typo. Anca confirmed the same day that her own name is deliberately written without
diacritics in this system — which makes `Asociatia`'s spelling consistent with an existing
convention, not an error sitting next to a correctly-spelled majority. `lib/format.ts`'s
`ENTITY_SHORT_CODES` map already hardcodes the same undiacritized spelling
(`"Asociatia STEMplicity": "STEM"`) independently, which is corroborating evidence this was never
a one-off slip — the rest of the codebase was already written assuming this spelling, not fighting
it.

**This is the second time in this project a plausible-looking "fix" would have corrected data that
was actually right.** The first was item 35, `"Laura Moale"` — a surname hypothesis built on a
month-old memory turned out to be the thing that was wrong, not the database. Same shape both
times: a spelling that looks like a mistake from pattern-matching against "correct" Romanian is
actually the recorded convention, and the person who could tell the difference is Anca, not a
diacritic checker.

**Do not "correct" `Asociatia STEMplicity`, or any other undiacritized name, without asking her
first.** This is a real, live naming convention now, not an open question.

**Not the same finding as item 43/44 below**, which are about code that mishandles diacritics
in *user input* (search, sorting, uniqueness) — this item is about how names already in the
database are spelled, on purpose, by a human decision. The search fix (`lib/search.ts`, this same
session) is a real, confirmed defect that got fixed; this item is the opposite case, a correct
spelling that almost got "fixed" into something wrong.

**Lives in:** `supabase/migrations/*` (`legal_entities.name` seed values); `lib/format.ts`
(`ENTITY_SHORT_CODES`); item 35 above (the first near-miss); item 41 above (where this was
originally, incorrectly, called a gap).

---

### 43. `localeCompare()` with no locale argument — three places, cosmetic

Confirmed live: `app/(app)/clients/clients-client.tsx:47`, `app/(app)/groups/groups-client.tsx:62`,
and `app/(app)/groups/[id]/page.tsx:220` all sort Romanian names via
`String(a).localeCompare(String(b))` with no locale passed — so the sort order follows whatever
locale the Node runtime defaults to, not Romanian collation rules specifically. Nothing crashes and
nothing goes missing from a list; two similarly-accented names could, in principle, sort in an
order a Romanian speaker wouldn't expect. No action taken — recorded for completeness while
auditing diacritic handling across the app this session (the same audit that produced item 44 and
the `lib/search.ts` fix).

**Re-verify when:** anyone notices actual out-of-order names on screen, or a Romanian-locale sort
becomes worth the small code change (`localeCompare(b, "ro")`) — not urgent on its own.
**Lives in:** the three call sites above.

---

### 44. `contracts.exit_number` uniqueness is byte-exact, with no Unicode normalization anywhere

Confirmed: the `contracts_unique_organization_exit_number` constraint (`202608180002`) is a plain
`unique (organization_id, exit_number)` on an uncollated `text` column, and `addContract` only
calls `.trim()` before insert — no case-folding, no `.normalize()`. Confirmed live (grep) that
`.normalize(` does not appear anywhere in `app/` or `lib/` before this session's `lib/search.ts`
introduced it for search only.

Postgres `=` compares bytes. Unicode allows the same visible accented character to be encoded two
different ways (a precomposed codepoint vs. a base letter plus a separate combining mark),
depending on the OS/keyboard/input method that produced it. Two exit numbers that render
identically on screen could be stored as different byte sequences and both insert — the uniqueness
constraint would not fire, which is the opposite failure from the one it exists to prevent, and
nothing would surface an error to say so.

**Narrow, real, unmitigated, no action taken.** This needs two different input methods producing
different normalization for what looks like the same exit number — not something one person typing
on one machine is likely to hit, but a real gap, not a hypothetical one, and the same "guarantee
the code doesn't actually provide" shape as item 40 above and item 21 below.

**Re-verify when:** exit numbers start coming from more than one input source (a copy-paste from
an external system, an import, a second office) rather than one person typing them by hand.
**Lives in:** `supabase/migrations/202608180002_replace_contract_number_with_entry_exit.sql`;
`app/(app)/contracts/actions.ts` (`addContract`); item 40 above and item 21 below (the other
instances of this shape).

---

### 45. Trainer end-of-session screen — the map, before any of it gets built piecemeal — CORRECTED 2026-09-18: part 1 was built the day after this was written, never marked

Anca described one screen (attendance confirmation, photos, attendance count, experiment logging,
peer feedback) that is much larger than the single question that prompted it. Investigated each of
the five parts against the current schema, RLS, actions, and the two relevant SAD documents before
any of it is built. Recorded as one entry, not five, so the scope is visible as a whole before
anyone decides what's one piece of work and what's four.

**1. Ready to build: `attendance_count`/`experiment_delivered` written by the assigned trainer.**
Both are writable today in exactly one place — `addSession`, at creation, gated on `sessions.create`
(Operations Manager + Master). `updateSessionAllocation` is the only post-creation write action on
`sessions` and is deliberately scoped to `trainer_principal_id`/`trainer_secundar_id` only — no
trainer can write anything to `sessions` today (`mywork.*` reaches the SELECT policy alone). Needs:
a new capability distinct from `sessions.create` (which also grants creating sessions and
reassigning trainers — too broad for "the assigned trainer logs what happened"), a new RLS UPDATE
branch matched on `trainer_principal_id = auth.uid() OR trainer_secundar_id = auth.uid()`, and a
narrow action exposing only `attendance_count`/`experiment_delivered` — RLS restricts rows, not
columns, so the column boundary belongs in the action, the same pattern `updateSessionAllocation`
already uses to narrow Ops's broader grant down to two columns.

**Part 1, corrected 2026-09-18: built, one day after this was written, never marked here.**
`updateSessionAttendance` (`app/(app)/groups/actions.ts`) is exactly what this part specifies —
row-matched on `trainer_principal_id = auth.uid() OR trainer_secundar_id = auth.uid()`, gated on
`mywork.*` (not a new narrower capability — `202609110004` settled that question the same way item
57 below argues it should be settled), narrowed in the action to `attendance_count`/
`experiment_delivered` alone. Live UI: "record attendance" on `/groups/[id]`. The code's own
comment dates the decision to 2026-09-11 — this item was written 2026-09-10 and never revisited to
close part 1 (or part 2, immediately below — same date, same gap) even though it was revisited
repeatedly afterward (2026-09-11, -12, -15) for part 5. Same finding as item 39's correction above,
from the session side rather than the `children_billed` side — one build closed both entries'
blockers, and neither entry noticed on its own.

**2. Ready to build: `children_confirmed` writable by `contracts.*` holders.** Anca removed the
`delivery_format` gating that item 39 (finding 5) had recorded as an open question — both count
fields now apply to every group regardless of format, with a blank value meaning "no count was
agreed," which the existing nullable `int` (no CHECK constraint, `202608130001`) already expresses
natively. Nothing to remove — the read-only display in `group-info-section.tsx` was never
format-gated either. What remains is exactly item 39 finding 3: Laura/Anka hold `contracts.*`, not
`groups.create`, the only capability the current `groups` UPDATE policy checks. That RLS gap is
the entire remaining scope for this part.

**Part 2, corrected 2026-09-18: also built, same date as part 1.** See item 39's correction above
(finding 3) for the full detail — `202609110002_add_groups_update_contracts_star_branch.sql` closed
exactly this RLS gap. Not re-derived here to avoid saying it twice.

**3. Blocked, needs a domain of its own: pre-filling the experiment from a planner.** No
experiment-level catalog exists. `public.modules` (`202608160004`) holds 13 rows, one per
curriculum *module* (`GAGA`, `Green Energy`, …) — one layer too coarse to be "the specific
experiment run today." The real planner — Lesson Plans / Presentation Library, ~300 real plans —
exists only in the mockup as static demo data and, underneath that, in the trainers' own tracking
spreadsheet; it has never been modeled as a table in this platform. `sessions.experiment_delivered`
is free text specifically *because* nothing exists to pick from (its own column comment: "no FK to
a lesson-plans table, since none exists yet as a real table in this app"). Trainers type the
experiment by hand until that catalog is built — a separate, larger piece of work, not a field on
this screen.

**4. Blocked, needs Anca: peer feedback between two trainers on a shared session.** No evaluation
module exists at all — confirmed by grep, and independently by `docs/progress.md`'s own note that
"ferestre de evaluare" was searched for everywhere, including the mockup, and doesn't exist.
`org_settings.evaluations_confidential` (OD-7) is a real, seeded boolean, read by zero application
code — "a column waiting for its consumer." Whether it should apply to trainer-to-trainer session
feedback is genuinely unclear, not just unanswered: OD-7's own documented shape
(`docs/ws-d-plan.md`) is that the evaluated person does **not** see their own evaluation — a
hidden-from-subject model built for a coordinator judging a trainer. Whether Anca wants two
co-trainers' feedback about each other hidden the same way, or visible to both since it's about
coordinating the class rather than judging one of them, is the same open fork item 23 already
recorded for the Happy Face matrix, unresolved there too. Not assumed here either.

**5. The largest, and not a screen feature: nothing in the database records that a specific person
delivered a specific session.** `sessions.trainer_principal_id`/`trainer_secundar_id` is assignment;
`sessions.status` is a free-choice enum set by Operations at creation, before the session happens,
with no connection to whether the trainer showed up, and nothing ever transitions it afterward.
`WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §12.2's grade formula and §12.1's pay formula both count
**delivered sessions per trainer** — the exact fact this schema does not capture. Payment execution
is explicitly out of V1 scope (§12.10), but the more basic problem sits underneath that: even if
payment execution were built today, there is no fact in the database for it to read. Parts 1-4
above are all real, buildable pieces; this one is the precondition every count in §12 depends on.

**Decided, 2026-09-10 — not built yet.** Trainer delivery confirmation will be two nullable
timestamp columns on `sessions`, `trainer_principal_confirmed_at` and
`trainer_secundar_confirmed_at`, matching the two allocation slots that already exist
(`trainer_principal_id`/`trainer_secundar_id`). Per-trainer by construction, which is what the pay
model requires — §12.2 counts sessions per trainer, and a two-trainer session can be delivered for
one and not the other (a no-show secundar, an unreflected last-minute swap).

**Rejected, and why.** A transition on `sessions.status`: rejected because status is session-level
and cannot express a per-trainer fact, and because a trainer-driven transition would give `status`
a second write path alongside `addSession`'s own — the exact shape item 8 already flagged as the
trigger to reconsider `contracts.status`'s design, applied here before it got built rather than
after. A separate confirmation table, one row per trainer per session: rejected on this schema's
own precedent, not on the idea's merits — allocation here is two fixed named slots, never
generalized to N, and the sessions migration's own comment already declined a similarly-shaped
table for per-child attendance for the same stated reason (the bar for a new entity in this domain
is deliberately high). If the two-slot ceiling on trainer allocation itself ever changes, this
decision would need revisiting alongside it — not a new risk, the same one `trainer_principal_id`/
`trainer_secundar_id` already carries.

**The fork is decided.** `sessions.status` stays Operations' scheduling field, set at creation as
today. Nothing derives "delivered by this trainer" from it, and nothing built against these two new
columns should read `status` as if it meant that. The pay count, and anything else asking whether a
specific trainer actually delivered a specific session, reads the two confirmation timestamps
directly. Two fields, two meanings, no overlap — the alternative this session's own item 21/40/44
pattern already argues against: one field two different callers can each believe they own.

**Anca's answers, 2026-09-11 — three of the four open questions close, one concept the schema
doesn't have arrives with them:**
- **Pay follows each trainer's own confirmation.** A trainer who did not deliver is not paid for
  that session. Confirmed 2026-09-11.
- **The timesheet closes at month end and the invoice is issued from it. A trainer cannot modify
  anything afterwards.** Confirmed.
- **Corrections are normally Laura's role, currently covered by Anka.** Anca is willing for the
  trainer to edit their own confirmation up to close, or for edit rights to stay with Laura and
  Anka only if that is simpler. **Mihai's choice: trainer may correct their own until close.**

**Still open, blocking the build — both produce different software, neither is an engineering
default:**
- Whether the month closes automatically on a date, or by a deliberate act. "The last day of the
  month" is compatible with either reading; a scheduled job and a button are different software,
  and they behave differently at 9am on the 1st and again if an invoice is delayed.
- Whether Laura and Anka retain correction rights after close, or whether close removes even
  theirs. Anca's answer only says the *trainer* can't change anything afterwards — it doesn't say
  either way for Laura/Anka.
- **The confirmation-timestamp fork AD-14 makes real, not decided here.** A server-received
  timestamp answers "when did the sync land"; a client-captured one answers "when did the trainer
  actually confirm." They only diverge once an offline queue exists to let time pass between the
  two — which is exactly what AD-14 requires. Today there's no queue, so the question is latent,
  not yet load-bearing; it becomes load-bearing the moment AD-14 gets built. This is a question for
  Anca, not an engineering default: does pay need the trainer's real moment of confirmation, or is
  the moment the confirmation reached the system good enough? Whichever she picks changes what the
  two confirmation columns from part 5's own decision actually store.

**Design decided, 2026-09-11 — not built yet:** a `payroll_periods`-shaped table, one row per
organization per month, not a column on `organizations`. A frontier column (e.g.
`organizations.payroll_closed_through`) can only ever represent the *current* boundary — it loses
which months closed, when, and by whom, the moment a later month closes over it. That is the exact
audit-trail concern AD-10 itself names ("reason and approver," frozen snapshots trusted precisely
because they're traceable). A row per period keeps that history, and sits directly underneath
where AD-10's own proposed `monthly_statements` shape is already headed. The two nullable
confirmation timestamps from this part's own earlier decision still hold as the stored value —
nothing about pay-follows-confirmation or corrections-before-close changes that shape. What sits
on top of them is new: a check, on write, of whether the session's month is closed.

That time condition belongs in RLS, not a `CHECK` — a `CHECK` must be immutable and "is this
month closed" is not, the identical reasoning already recorded for the future-date question on
`signed_date` (item 10), just pointing the other way: `CHECK` can't express a `now()`-relative
condition, RLS can, because RLS re-evaluates per query instead of freezing at row-creation time.
Column narrowing (only the confirmation columns, nothing else on the row) and the human-readable
error in place of RLS's silent zero-rows rejection both stay in the action layer, as everywhere
else this session (`updateGroup`, `updateSessionAttendance`).

**Built and verified live, 2026-09-15**, per Anca's three 2026-09-12 answers: month close is Anka's
deliberate act (a button on a new `/payroll` screen, not a date), Anka may correct either
confirmation timestamp before or after close, a trainer may correct their own only until close. The
capability is `finance.operations.*`, not `contracts.*` — Anka and Laura both happen to hold
`contracts.*` too, for an unrelated reason, the same coincidence-of-role gate `202608300001`
(suppliers) already rejected for this identical pair. `finance.operations.*`'s own catalogue
description, "Trainer pay, reimbursements, private-school invoicing, attendance billing," names
payroll close by description, not by coincidence.

**Anka's after-close correction right means "closed" means closed to the trainer, not frozen —
recorded as what was chosen, not as a problem.** AD-10 specifies a frozen snapshot: once issued, a
statement never changes again, and a correction is a new adjustment line on the *next* period, with
reason and approver. Anca's answer does something else — the record itself stays open to Laura and
Anka indefinitely; only the trainer loses write access at close. The invoice, per her own
description, is issued from a month that can still change after that invoice goes out, if a
correction happens after the fact. This is a real, deliberate difference from AD-10's model, not an
implementation gap — she was not asked to approve AD-10 and did not; she answered a concrete
question about who can touch what, and this is what her answer implies once followed through. If
the invoice-already-issued case matters to her (a correction after the invoice is out, not just
after the month closes), that is a new, more specific question than the one asked — this item does
not resolve it, only names it.

**Lives in:** `supabase/migrations/202608130001_create_groups_sessions_domain_tables.sql`,
`202608130003_add_groups_sessions_rls_policies.sql`, `202608160004_groups_sessions_field_additions.sql`,
`202609150001_create_payroll_periods.sql`, `202609150002_add_sessions_confirmation_columns_and_rls.sql`;
`app/(app)/groups/actions.ts` (`addSession`, `updateSessionAllocation`, `confirmSessionAttendance`,
`correctSessionConfirmation`); `app/(app)/payroll/` (`actions.ts`, `page.tsx`, `payroll-client.tsx`);
`scripts/verify_payroll_periods_close.sql`, `scripts/verify_sessions_confirmation_write.sql`;
`public.file_refs`
(`202607080003`, zero application code references it — relevant background for part 1's photos
question, investigated the same session, not repeated here); `docs/WOWLAB_SAD_Contracte_Trainer_
Furnizor.md` §12; `docs/WOWLAB_SAD_Field_Masking.md` §2.4/§2.5; `docs/ws-d-plan.md`; item 23 above
(the Happy Face precedent for part 4's open question); item 39 above (findings 2, 3, 5 — part 4's
"trainers write directly" answer and part 2's format-gating removal both resolve open questions
recorded there); item 8 below (`contracts.status`'s second-write-path warning, the reason a
trainer-driven `sessions.status` transition was rejected for part 5); items 40, 44 above and item 21
below (the one-field-two-owners shape part 5's decision was written to avoid repeating).

---

### 46. Fifteen architecture decisions existed in a document that was never in the repo

`docs/WOW_LAB_OS_Solution_Architecture_Document.md` (June 2026, Version 1.0, Status "DRAFT —
pending stakeholder approval") defines AD-1 through AD-14, each a resolved ambiguity in the PRD with
its own Problem/Risk/Decision. It lived only in `~/Downloads` until this session — never copied
into `docs/`, never linked from anything, never checked before a decision in its scope got made
again from scratch. AD-15 doesn't appear in it at all; it was coined later, directly inside
`docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`, continuing the same numbering.

**Confirmed by grep, not sampled: five of the fifteen are referenced anywhere in this repo — AD-1,
2, 6, 7, 15.** The other ten sat completely unreferenced until this item. Full status of all
fifteen, checked against the real schema/RLS/actions, not the proposal's own confidence: see
`docs/WOW_LAB_OS_AD_Reconciliation.md`, added the same session. Three findings from it matter enough
to restate here:

- **AD-3 is contradicted by what actually got built.** No `programs` table exists;
  `sessions.group_id` is `NOT NULL`, the opposite of what AD-3 specifies. A different, simpler
  design (`delivery_format` on `groups`) solved the same named risk instead.
- **AD-11 and AD-15 are the same decision, made twice, under two different numbers.** The
  ActiveCampaign/platform system boundary was proposed once in the undiscovered document (AD-11,
  never approved, never referenced) and proposed again, independently, inside
  `WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` — where it *was* found, confirmed, and approved,
  under the label AD-15. Nobody checked the first document before writing the second decision.
- **AD-4 was independently re-argued from scratch, one session before this one, reaching the
  identical conclusion a month later.** Item 45 part 5's decision — `sessions.status` must not
  double as a trainer's confirmation, because a status two callers can each set stops reliably
  meaning either thing — is word-for-word AD-4's own argument, built the same way from this
  codebase's own `contracts.status` precedent (item 8), with zero knowledge AD-4 already existed.
  The two didn't contradict each other, but they could have: a different, incompatible resolution
  argued with equal confidence from the same codebase would have shipped silently over a decision
  already made a month earlier, and nothing anywhere would have flagged the collision.

**AD-10 is the sharpest instance, not the only one.** Recorded in item 45 part 5 from memory, as
established fact, before this session located it. It turned out to be real and well-formed — but a
proposal awaiting approval, not a confirmed decision, by the source document's own stated status.
That specific gap — mistaking "proposed once" for "decided" — is what this whole item is about; AD-4
and AD-11/AD-15 show it happening in the other direction too: real decisions, sitting unreferenced,
either re-litigated at cost or narrowly avoided being overwritten by contradiction, because nothing
connected them to the code they governed.

**The cost was never that the decisions were wrong.** Every one checked against reality in the
reconciliation was either correct, superseded by something better, or simply never built. The cost
is that at least one got paid for twice (AD-4/item 45), one almost went uncaught as a duplicate
(AD-11/AD-15), and the whole batch sat where no decision ever gets re-checked before code that
depends on it gets written — which is the one thing a decision record exists to prevent.

**Lives in:** `docs/WOW_LAB_OS_Solution_Architecture_Document.md` (verbatim source, copied in this
session, not edited); `docs/WOW_LAB_OS_AD_Reconciliation.md` (status of all fifteen, checked against
the repo); item 45 above (AD-4's independent re-derivation, AD-10's unconfirmed status, AD-14's
offline requirement); item 8 below (the `contracts.status` precedent both AD-4 and item 45 used
independently); `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §1/§9 (AD-15, the confirmed twin
of AD-11); item 35 above and item 48 below (the other two instances of "asserted as sourced, wrong,
caught only by checking").

---

### 47. Fifty commits sat unpushed for nine days — RESOLVED 2026-09-10, cause recorded so it doesn't repeat

Between 2026-09-01 and 2026-09-10, fifty commits accumulated on local `main` and never reached
`origin`. Ten migrations were applied to the live database with `db push` whose files existed on
only one machine (item 46's investigation, before this was fixed). Seven of their rollback files
were in the identical position — the recovery path for a change that had already shipped to
production existed nowhere a second person, or a second machine, could reach it. `origin/main`
spent those nine days actively describing `contracts` write policies that Anca had already
replaced with her own decision on 2026-09-06 — not silent on the change, wrong about it. Nothing
was lost. Nothing was recoverable either, for as long as that was true — the two are different
claims, and this item is about the second one.

**Two causes, both real, both worth naming so neither repeats:**

- **Commit and push were treated as one act. They are not.** Every session that touched this
  codebase ended with an instruction to commit; none ended with an instruction to push. A commit is
  durable on the machine that made it. It is not durable, not shared, not deployable, and not
  recoverable by anyone else until it reaches a remote — `git commit` and `git push` are two
  separate verbs for a reason, and this project's own history spent nine days proving why.
- **Every browser verification for nine days ran against `localhost`.** Each one was real evidence
  — the code executed, the database write happened, the screenshot showed the correct behavior.
  None of it was evidence about production, because none of it touched production. Local
  verification proves the change works. Deployment verification proves the change reached someone.
  A screenshot of `localhost:3000` answers "did I build this correctly"; it does not answer "can
  Anca see this yet" — and this session's own prior report (the placeholder-select fix, verified
  repeatedly against `localhost` before anyone checked whether it had shipped) is the concrete case
  that made the distinction impossible to ignore any further.

**The rule, stated plainly, going forward:** work touching the live database or the deployed app is
not done until it is on `origin` and verified on `app.wowlab.ro`. Not committed — pushed. Not
working on a local server — working for whoever the change was for. A migration applied with
`db push` and a fix confirmed on `localhost` are both real progress and neither is finished by
itself.

**Resolved this session:** all fifty commits (plus three more made resolving items 42-46) reached
`origin/develop` then `origin/main` via a fast-forward merge (`develop` had zero commits of its own,
confirmed before merging, so the fast-forward was exact, not a reconciliation) — Preview verified
first (`/clients`' placeholder select, live, before Production ever saw it), then Production
verified separately and directly against `app.wowlab.ro` on a real session: the same placeholder
fix, the `/groups` contract field, `/login`'s RO/EN switch and localization, and diacritic-insensitive
search all confirmed by eye, not inferred from the commit contents.

**Lives in:** item 46 above (what was found undocumented while this was still unpushed); this
session's own commit/push/deploy sequence (`9922eed`, `3b180b7`, `2913d8b`, and the `develop`/`main`
fast-forward that carried them and the prior forty-seven commits to `origin`).

---

### 48. `clients.business_line` — "Anca's own term" was wrong; the paper trail runs the other way

Mihai told Anca `business_line` was her own term, concluded from two rows attributed to her in an
August feedback table. Checked, not assumed — the table is dated 2026-07-30, not August, and the
term does not originate with her.

**The actual chain, in date order:**
- **2026-05-27** — `wow_lab_master_analysis.md` §9, "Three Business Lines": a defined three-value
  company taxonomy — recurring private schools, state schools (Școala Altfel / Săptămâna Verde),
  corporate and private events. Mihai's own analysis document, over two months before any feedback
  from Anca.
- **2026-07-15** — a mockup dashboard card, *"Venit pe linie de business"* ("Revenue by business
  line"), already showing the phrase on screen.
- **2026-07-30** — Anca's feedback (`wowlab_feedback_analiza`, Google Drive) repeats the phrase,
  twice, both about dashboard/forecast screens. The column holding it is labeled by the file itself:
  **"Rezumat cerere"** — summary of the request, not a quote. Elsewhere in the same table, an actual
  quote from her is marked with quotation marks; these two rows aren't. She was giving feedback on a
  screen that had been showing her this exact term for two weeks.
- **2026-08-10** — `business_line` becomes a real column on `clients` — free text, no comment, no
  enum, no definition. The three-value company category from May 27 was not carried forward into it;
  only the name was.

**The undocumented decision was never the phrase.** It's turning a fixed, company-level service
category into an open per-client text box — a grain change nobody decided, made in the same
migration that dropped the definition.

**The pattern, worth recording on its own:** this is the third time in one week a plausible,
specific-sounding detail was asserted as sourced and turned out not to be — the "Laura Moale"
surname (item 35), AD-10 stated as an established decision (item 46's origin), and now this. All
three were caught by checking the actual source, not by noticing something felt off — none of the
three raised any flag before someone went and looked. The check is the only thing that has worked,
three for three; noticing has not caught any of them.

**Lives in:** `wow_lab_master_analysis.md` §9 (`~/Downloads`, not in this repo); the mockup dashboard
card (`docs/mockup/wow_lab_os_mockup.html` and its dated `~/Downloads` predecessors); Google Drive
`wowlab_feedback_analiza` (rows 37, 45, column "Rezumat cerere"); `docs/WOWLAB_SAD_Domeniul_Clients_
Contracts_CRM.md` §4 and `supabase/migrations/202608100001` (where the definition was dropped); item
35 above and item 46 above (the other two instances of this same pattern).

---

### 49. A delete-anything feature — the requirement wasn't found, and the scope it would have is not one feature

Four findings, recorded together because they came from the same request.

**1. The requirement itself was not found — recorded as a request made 2026-09-10, not as
something recovered.** Mihai described an explicit prior requirement: "Add/Edit/Delete on any
database entry from the app, restricted to Anca Tanasescu, with a double confirmation requiring the
word DELETE typed on screen." Checked exhaustively: every file under `docs/`, the full git log,
every mockup variant in `~/Downloads` (about ten HTML files), and four analysis PDFs including the
182-page `WOW LAB OS PRD for Claude Code.pdf` and `wow_lab_master_analysis.md.pdf`. It appears
nowhere — not verbatim, not in pieces assembled from several places. The closest matches are not
it: a role-table line ("Master | Anca Tănăsescu | Everything + global settings, role management")
with no mention of delete or confirmation, and an "Admin/Master: can add/delete" line scoped
narrowly to lesson-plan PPT files, naming the Admin role generally (also held by Laura Moale and
Anka Orban), not Anca specifically. Fourth instance this week of a detail remembered as recorded
that wasn't — after the "Laura Moale" surname (item 35), AD-10 (item 46), and `business_line`
(item 48). This entry treats the request as new, dated today, not as a requirement being restored.

**2. Anca's actual permission state — described wrongly more than once, corrected here against
the live row.** Her `user_org_roles` in `wow-lab` are `platform_owner` and `sales_manager` — not
`organization_owner`, which she does not hold at all. Her `users.is_platform_owner` column — the
actual cross-org superuser flag, read by `app.is_platform_owner()` with no organization parameter
at all — is `false`. The role named "Platform Owner" and the boolean flag of the same name are two
separate mechanisms; she holds only the former. The `roles` table's own description for that row
says as much: cross-org access runs through `users.is_platform_owner`, and the role row "exists for
capability completeness and UI" — decorative for the power in question. Her account `status` is
still `'invited'`, not active. Any future design for elevated permissions for her should start from
this state, not from the organization_owner/platform_owner pairing originally assumed.

**3. The scope of "any entry" is not one feature.** 30 tables in `public`; exactly 2
(`contracts`, `client_contacts`) have a DELETE policy today. All 55 foreign keys in the schema are
`NO ACTION` — confirmed directly against `pg_constraint`, zero exceptions, so the "implicit
RESTRICT" convention noted elsewhere for `contracts_renewal_of_fkey` (item 8) is schema-wide, not a
special case. Only 4 tables are FK-leaves (`client_contacts`, `sessions`, `suppliers`,
`user_org_roles`), and two of those four still have no delete mechanism wired up. `clients` has 3
dependent tables, `users` has 12, `organizations` is referenced by 24 of the 30. Building
"delete anything" means per-table dependency-clearing logic — nothing cascades in this schema, by
convention — plus a new RLS DELETE policy for 28 of 30 tables.

**4. Direct conflict with an already-closed decision.** `docs/DATABASE_CONVENTIONS.md` §12 and
`docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §8 both already close hard-delete on `clients`,
in writing, because `status = 'churned'` already answers "this relationship is over" — a delete
feature there would be a second, contradictory answer to a question already settled, "closed, not
deferred." A literal delete-anything feature that includes `clients` would reopen that decision,
not build alongside it.

**The need underneath, reported separately, not acted on:** the same investigation found that the
actual pressure behind this request is that `wow-lab-test-b` — the designated safe org for exactly
this kind of testing — can't yet carry a full client → contract → group walkthrough (it has zero
`legal_entities` rows, so the contract form's required select can never be filled there). Reported
in full below this item's neighbors, not designed here.

**Lives in:** the two-agent investigation this session (delete requirement search, capability/FK
scoping); `docs/DATABASE_CONVENTIONS.md` §12; `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`
§8; `app/(app)/contracts/actions.ts` (`deleteContract`), `app/(app)/clients/actions.ts`
(`deleteClientContact`) — the two delete paths that exist; item 35, item 46, item 48 above (the
other three "remembered as recorded, wasn't" instances).

---

### 50. Why test data kept reaching production, and the fix — RESOLVED 2026-09-10

Test data reached `wow-lab` production three times in ten days: the seed rows purged 2026-09-01
(24 rows, item "Seed data cannot be reliably distinguished from real data" above), a second
"Maxdigital" client/contract/group purged 2026-09-10 (commit `071ac51`), and "Mirakids"
client/contract/group purged the same date (commit `4cf5738`). The cause was not carelessness.

**There was no reachable route into the test organization.** Three things were true at once:
- Mihai's only account, `maxdigitalro@gmail.com`, held membership in `wow-lab` alone — confirmed
  live against `user_org_roles`, zero rows in `wow-lab-test-b`.
- There is no org switcher anywhere in the app (item 26, "No current-organization concept" —
  `platform.org_switcher.use` is seeded as a capability but has no UI behind it; even a second
  membership would have merged both orgs' rows into one list with no per-row indicator, per that
  item's own finding).
- The only path anyone used, all session, to reach `wow-lab-test-b` at all was a service-role
  script minting a one-time magic link for a separate identity (`test+user-b@wowlab.dev`) — not
  something reachable from a normal login.

On top of that, `wow-lab-test-b` had zero `legal_entities` rows, so even a session that did reach
it could not exercise the contract form even once — confirmed live during this session's timing
measurement (blank-page investigation, part d), which had to report contract-create timing as
unmeasured for exactly this reason.

**Fixed, not just reported:**
- `supabase/migrations/202609100002_seed_test_org_b_legal_entities.sql` seeds two fictional
  `legal_entities` rows into `wow-lab-test-b` — "Test Entity SRL" and "Test Association," names
  that share no word with any of `wow-lab`'s three real entities. Rollback at
  `supabase/rollbacks/202609100002_seed_test_org_b_legal_entities_rollback.sql`. Verified live
  after applying: `wow-lab`'s three real entities untouched, same ids as before.
- `maxdigitalro+testorg@gmail.com` invited into `wow-lab-test-b` as `organization_owner`,
  `is_test_account = true`, through the app's own `inviteUser` action (driven live via the actual
  `/admin/users` UI, not a script bypassing it) — a real Supabase Auth invite, his to activate
  himself. Verified live: this account holds zero membership in `wow-lab`; `maxdigitalro@gmail.com`
  still holds zero membership in `wow-lab-test-b`. The two identities do not cross — deliberately
  not the same account with two memberships, per item 26's own warning about what that would do to
  list views.
- Walked the full client → contract → group flow end to end, logged in as the new account on
  `app.wowlab.ro`, all three steps confirmed by direct query, not just UI appearance: a client, a
  contract against the newly seeded "Test Association" entity, and a group against that contract.
  No remaining blocker found. Verification rows deleted afterward, by exact id, so the account's
  first real session starts from an empty organization.

**The rule that follows:** any verification that creates rows happens in `wow-lab-test-b`. That is
now a real, reachable option — not aspirational the way it was for the ten days this item covers.

**Lives in:** `supabase/migrations/202609100002_seed_test_org_b_legal_entities.sql`;
`supabase/rollbacks/202609100002_seed_test_org_b_legal_entities_rollback.sql`; item 26 above (the
org-switcher gap this works around, not fixes); item 49 above (the request that surfaced this);
commits `071ac51`, `4cf5738` (the two purges this closes the loop on).

---

### 51. `client_contacts` write-side finance exclusion removed — the same exclusion, the same
decision, extended — RESOLVED by Anca's decision, 2026-09-11

Item 37 above fixed this exact exclusion on `contracts` on 2026-09-06, and named
`client_contacts` explicitly as carrying the identical block — deliberately not touched in that
item, because Anca's decision was scoped to `contracts` and widening it without asking was exactly
what was flagged against doing. This item is that second answer, asked for and given five days
later.

**What carried the exclusion:** `client_contacts`'s three WRITE policies — INSERT/UPDATE
(`202608100003`) and DELETE (`202608270001`, whose own comment describes its predicate as
"deliberately IDENTICAL" to INSERT/UPDATE's). All three excluded anyone holding
`finance.reporting.*` or `finance.operations.*`, even when they also held `contract_administrator`'s
`contracts.*` capability — blocking Laura and Anka from managing a client's contacts, the same two
people and the same role combination item 37 found blocked on contracts itself.

**One difference from the contracts case, worth recording precisely:** the contracts exclusion was
called load-bearing in its own comment ("not decorative"). `client_contacts`'s was not — its
original comment (202608100003) called it an "inferred default (flagged in the final report)" for a
table the SAD never specified action-level rules for at all. This exclusion was weaker on its own
terms than the one already removed from `contracts` before Anca was ever asked to decide on it.

**Anca's decision, 2026-09-11 — the same tradeoff as contracts, extended:** contract_administrator
holders manage a client's contacts regardless of any finance role also held.

**What changed:** `supabase/migrations/202609110001_remove_client_contacts_write_finance_exclusion.sql`
drops and recreates the three write policies without the two `NOT has_capability(...)` branches —
its own header quotes 202608100003's original comment in full. `canManageContacts()` in
`app/(app)/clients/[id]/page.tsx` and the `canDelete` check in `deleteClientContact`
(`app/(app)/clients/actions.ts`) were simplified to match, each now just
`isOwner || hasClientsCreate || hasContractsStar`. Rollback at
`supabase/rollbacks/202609110001_remove_client_contacts_write_finance_exclusion_rollback.sql`.

**Deliberately left untouched, same reasoning as item 37:** the SELECT policy and the
`is_billing_contact` row-level masking inside it. There, finance roles read through their own
client-type-scoped branch instead, which is the read segregation the SAD specifies and Anca did not
change.

**Verified live, as the real users, not service role:** Laura and Anka can each insert, update, and
delete a client contact; a trainer's insert is rejected by RLS; Laura's read still returns only the
private-school client's contact in a mixed fixture, not the corporate one — all seven assertions
confirmed both as a dry run before applying and again live against the applied policy.

**A real gap surfaced by browser-verifying this, worth recording on its own:** the DB fix and the
app-code mirror were committed together, but the app-code fix was not yet deployed when first
browser-tested — the deployed frontend still ran the old `canManageContacts()` logic, so the "+ New
contact" button stayed hidden even though the underlying RLS would already have allowed the write.
This is the exact failure mode this task's own instructions warned against ("one without the other
gives a visible button that fails, or a hidden screen that would have worked") — caught here because
verification ran against the actual deployed app, not just the local diff, and re-ran clean once the
deploy completed.

**Browser-verified end to end, in `wow-lab-test-b`, not production** (Anka is working in
`wow-lab` — see item 50): a new fixture account, `test+ui-contract-admin-b@wowlab.dev`
(`contract_administrator` + `finance_operations`, matching Laura's exact role set, `is_test_account`
true), invited through the real `/admin/users` UI into the test org. No client existed there to
attach a contact to, so one was created first (as the test org's owner, since Contract
Administrator + Finance Operations correctly does not hold `clients.create` — the same account
correctly saw no "+ New Client" button, confirming the read/write boundary is exactly right, not
just the finance exclusion). A contact was then added, edited, and deleted as the fixture account —
all three actions succeeded on the deployed app. One false alarm during this pass: the delete's own
screen still showed the deleted contact a moment after confirming, which looked like a failure until
checked directly against the database (already gone) — the same dead-zone rendering delay this
session investigated and reported on separately for creates, now observed on a delete too. Fixture
rows removed afterward — `clients`, `contracts`, `groups`, and `client_contacts` all confirmed back
to `0` in `wow-lab-test-b`. The fixture account itself was left in place, as a reusable test-org
counterpart to Laura's real role set.

**Lives in:**
`supabase/migrations/202609110001_remove_client_contacts_write_finance_exclusion.sql` (its own
header quotes 202608100003's original comment in full);
`supabase/rollbacks/202609110001_remove_client_contacts_write_finance_exclusion_rollback.sql`;
`scripts/verify_remove_client_contacts_write_finance_exclusion.sql`;
`app/(app)/clients/[id]/page.tsx`, `app/(app)/clients/actions.ts`; item 37 above (the contracts
fix this extends, and the reasoning this item repeats rather than re-derives); item 50 above (why
verification ran in `wow-lab-test-b` at all, and the fixture account this item's own browser pass
reused that org for).

---

### 52. Anca's planning-fields spec describes a workshop; the schema models a group — CENTRAL FORK CLOSED 2026-09-21: recurring stays primary, one-off gets extension fields

Three real documents from Anca — a 26-field planning spec, a PDF on principal/secondary/reserve
trainer responsibilities, and a post-workshop feedback form's question list — describe a **workshop**
as a first-class thing: client, legal entity, type, description, date, time range, hours, allocated
trainers with a principal flag plus a reserve, an on-site contact person and phone, address, and up
to four experiments each with its own trainer.

**Checked against the live schema, not assumed. Roughly half the spec has no home at all.**

**Absent entirely** — no column, no table, nothing to point at:
- Address (confirmed live: zero columns named anything like "address" anywhere in the schema).
- Time range (`sessions` has `session_date` and `duration_minutes`, no start/end clock time).
- A third, reserve trainer slot (`sessions` has exactly two: `trainer_principal_id`,
  `trainer_secundar_id`).
- A principal flag per allocation. Today "principal" isn't a stored fact — it's *implied* by which
  of the two fixed columns a trainer's id sits in, not a flag that could mark any one of three
  people. Adding a third column wouldn't fix this half of the gap even if it fixed the slot count.
- Per-experiment attribution. `sessions.experiment_delivered` is one free-text column for the whole
  session — it can hold "what was delivered," never "who delivered which experiment," which is a
  different shape, not a smaller version of the same one. Confirmed the columns exist as described,
  live.
- A workshop-level description field distinct from `notes`.
- A workshop-level on-site contact. `client_contacts` has the person and phone (and even a
  `contact_purpose = 'trainer_facing'` value already), but scoped to the **client**, with no link to
  a specific workshop/session at all.

**Present, but at the wrong grain:** `children_confirmed`, `age_range`, and `business_line` all sit
on `groups` or `clients` — once per group or per client, not once per workshop. Fine for a group
with a single session; wrong the moment a group has more than one, or a client runs workshops of
different kinds.

**Present, but structurally unreachable:** legal entity. Only `contracts.legal_entity_id` carries
it, and `groups.contract_id` is nullable — a workshop belonging to a group with no linked contract
has no path to a legal entity at all, not even an empty one to fill in.

**The underlying cause, recorded as the actual question, not as seven missing columns:** this
schema models *recurring clubs* — one group, many sessions, most workshop-level facts (client,
format, age range, confirmed-count) properly living once on the group because they're stable across
every session in it. Anca's documents describe *one-off workshops*, where the workshop itself is the
unit that carries the client relationship, the venue, the on-site contact, and the team for that one
occasion — nothing above it is stable enough to hoist those facts onto. Both shapes are real. Only
one is modeled. Bolting the missing fields onto `sessions` would make a one-off workshop *look like*
a session of a recurring group by giving it the same container, not resolve which of the two shapes
a one-off workshop actually is.

**A second, separate duplication surfaced by the same documents:** the post-workshop feedback form
asks the trainer how many children attended. `docs/OPEN_ITEMS.md` item 45 part 1 already targets
`sessions.attendance_count` for the same fact, trainer-written, once built. Two systems that don't
talk to each other, asking the same person the same question twice, with no reconciliation and no
way to tell which is right if they ever diverge.

**Checked, not built, at the time this was written:** whether any existing document states workshop
volume — how many one-off workshops Wow Lab runs in a year against how many recurring groups —
since that ratio decides whether the domain gap above is the exception or the actual shape of most
of the business. Searched this repo (`docs/`, `progress.md`), the already-known Drive feedback
spreadsheet, the AD document (mentions the one-off/recurring split conceptually — P3's "Program →
Groups (recurring) or direct sessions (one-off)" — with no figures attached), and two real
operational spreadsheets in `~/Downloads` — `New Wow Lab Trainer Calculations Table.xlsx` ("Pontaj
si Norma," ~11,876 rows, one row per trainer/workshop-date/school occurrence back to 2024) and
`Tabel Costuri Agregate Total HR WOW Lab.xlsx` (a monthly per-trainer cost rollup). No document
anywhere stated the ratio. The raw transactional data in the first spreadsheet could support
computing it — school name, date, and duration per row, back to 2024 — but nothing had done that
computation or stated its result yet.

**Computed 2026-09-21 — `Pontaj si Norma`, 1,422 data rows (of 11,876 raw rows; the rest of the
sheet is unused space).** No column marks workshop type — the split was inferred, not read off a
field, from `School Name`: most of its 34 distinct values are real named schools (recurring club
delivery); a minority are generic event labels standing in for one-off work — `Scoala Altfel` (171
rows), `Saptamana Verde` (59), `Wow Lab Party` (26) — plus three non-school venues identifiable
only by not being a school (`ASOCIATIA CURTEA VECHE`, `PR CORNER S.R.L`, `Mina Museum SRL`, 16 rows
together). 103 rows under `New Lesson Plan` were excluded outright, not counted either way —
`Trainer Classification` on those rows reads `Lesson plan writer`, a different work stream (lesson
authoring pay, not delivery). **This is a proxy inferred from a free-text field, not a fact anyone
recorded as such — treat the numbers below as a first real estimate, not a source of truth the way
a real `delivery_format`-equivalent column on this data would be.**

- **Overall:** recurring 1,045, one-off 274 → **3.8 : 1 by count, 3.7 : 1 by hours** (average
  session length is nearly identical either way — 1.15h recurring vs. 1.19h one-off — so count and
  hours agree here; they need not, and a future check with more format variance shouldn't assume
  they always will).
- **By school year — the trend, not just the average:** 2024/2025 (Aug 2024–Jul 2025, 636 sessions)
  — **2.9 : 1** by count. 2025/2026 (Sep 2025–Jun 2026, partial year, 682 sessions) — **5.2 : 1** by
  count. One-offs fell from 163 to 110 sessions in absolute terms, and from 25.6% to 16.1% of the
  total — recurring is not just the larger share, it is actively growing as a share of what this
  business delivers, in the one year of trend this data shows.
- **Revenue could not be computed, from either spreadsheet.** Both hold trainer *cost* (what Wow Lab
  pays out), never a client-facing price — there is no revenue column anywhere in either file.

**The fork closes: recurring stays the primary model; one-off workshops get the fields they're
missing as an extension of it, not a restructure that promotes workshops to the primary entity.**
At roughly 4:1 and widening, recurring clubs are the dominant shape of real, delivered work today —
not the exception the domain gap above was checked against. That argues directly against making a
one-off workshop the first-class unit with recurring groups as its special case, which was the
live alternative this fork was actually weighing. **It does not make the gap smaller.** One-off
workshops are still roughly a fifth of delivered hours even in the leaner, more recent year — real,
ongoing volume, not noise — so every absence the section above lists (address, time range, the
reserve-trainer slot, a real principal flag, per-experiment attribution, a workshop-level contact
and description) is still a real gap to fill, now scoped as additions to the existing
`groups`/`sessions` model rather than as a second, parallel entity.

**The nine-value workshop type list is verified, not just cited secondhand — read directly from the
source, `Fielduri pentru planificare ateliere.xlsx` (`~/Downloads`), the "Tip Atelier" row's own
dropdown definition, quoted in full:**

> Dropdown list:
> Lista:
> Scoala Altfel
> Scoala Verde
> Wow Lab Party
> Parteneriate cu companii
> Cursuri deschise - Exemplu Cursuri de chimie
> Scoli private (colaborări ocazionale) - Exemplu Science Week la IBSB
> Scoli private (colaborări recurente)
> Wow Lab Party
> Evenimente/prezentari la mall - Exemplu Barlad Value Center
> Party in companii

Ten lines, `Wow Lab Party` listed twice — **nine distinct values**: Scoala Altfel; Scoala Verde;
Wow Lab Party; Parteneriate cu companii (company partnerships); Cursuri deschise (open courses,
e.g. chemistry courses); Scoli private, colaborări ocazionale (private schools, occasional
collaboration, e.g. a Science Week at IBSB); Scoli private, colaborări recurente (private schools,
recurring collaboration); Evenimente/prezentari la mall (mall events/presentations, e.g. Barlad
Value Center); Party in companii (parties at companies).

**Why this can't map onto `delivery_format`'s six values (`recurring`, `scoala_altfel`,
`saptamana_verde`, `party`, `corporate`, `custom`) — checked precisely, not just "it's different":**
the nine-value list mixes three different axes in one flat dropdown that `delivery_format` keeps
separate or collapses on purpose — **occasion** (Scoala Altfel, Scoala Verde), **venue** (mall),
**client type** (private schools, companies), and **frequency** (occasional vs. recurring,
spelled out as two separate private-school lines) all sit at the same list level. One direct
naming mismatch, not just a conceptual one: the spec says **"Scoala Verde,"** the schema's enum
says **`saptamana_verde`** ("Săptămâna Verde") — close enough to be the same program, not
confirmed to be, and not silently treated as such here. Two spec lines (`Wow Lab Party`, `Party in
companii`) and two more (`Parteneriate cu companii`, `Party in companii` again) plausibly both
collapse onto single `delivery_format` values (`party`, `corporate`) — plausibly, not confirmed;
`recurring` most likely corresponds to "Scoli private (colaborări recurente)" alone, leaving state
schools' own recurring relationships (if any) unaccounted for in either list.

**Still Anca's, not settled by the volume answer:** whether the nine-value list replaces
`delivery_format`, sits beside it as a second, more granular classification, or is dropped in favor
of the six already built. The ratio decided the *structural* fork (extend, don't restructure); it
says nothing about which *vocabulary* the extension should speak.

**At the time this fork closed: no migration, no table, no code yet.** Three of the seven
still-absent fields — time range, address, on-site contact — were built the same week, as an
extension of `groups`/`sessions`, not a new entity (item 77 above). Four remain: a real principal
flag (not implied by column position), a third/reserve trainer slot, per-experiment attribution, and
a workshop-level description distinct from `notes` — still pending Anca's vocabulary answer above
for the ones that touch `delivery_format`/`Tip Atelier` directly.

**Lives in:** `docs/OPEN_ITEMS.md` item 45 (the attendance-count duplication's other half); the
three source documents (`WOWLAB_Spec_Trainer_Principal_Secundar.md`, now in `docs/`, untracked;
`Fielduri pentru planificare ateliere.xlsx`, found and read `~/Downloads`, not yet copied in;
`WOWLAB_Spec_Formular_Feedback_Post_Atelier`, still not located); `New Wow Lab Trainer Calculations
Table.xlsx` (`~/Downloads`, `Pontaj si Norma` sheet — the volume computation's own source);
`supabase/migrations/202608130001_create_groups_sessions_domain_tables.sql`,
`202608160004_groups_sessions_field_additions.sql` (the live `sessions`/`groups` schema this was
checked against, and where the extension fields would land); `docs/WOW_LAB_OS_Solution_Architecture_Document.md`
line 49 (the one place the one-off/recurring split is named, without a volume figure).

---

### 53. A trainers screen would show almost nothing real; the mockup's own version has eight unbacked claims, one of them about a named person

Investigated before building anything: what a trainers directory could honestly show today. Answer:
name, email, phone (null for 5 of 11), and role. Everything else is empty — zero grade assignments
in `wow-lab`, zero sessions anywhere in the org, both rate tables globally empty, and no table at
all for availability, module qualification, or hours worked.

**The mockup's `S.trainers` screen — eight claims checked live, none backed:**
1. "21+ active trainers" — eleven exist; one (Anka Orban) actually holds `status='active'`.
2. "7 levels" — `WOWLAB_SAD_Contracte_Trainer_Furnizor.md` says six, "verified against all 27
   trainers in Anca's real file."
3. A "Zone" column — not merely unbuilt: explicitly considered and rejected in writing (same SAD,
   §12-adjacent, only 2 of 11 trainers live outside Bucharest, no general rule confirmed for anyone
   else).
4. "Total hours" — sourced today from external Toggl PDFs archived on Drive, not this database.
5. A bonus/smiley column — zero tables behind either Happy Face mechanism (see below).
6. "Certifications" — no table exists at all, despite `certifications.define`/`certifications.
   override` sitting seeded and unused in the capability catalog (item 49 above, part b).
7. "Minimum 80% in-person" — appears in no document anywhere, not even as a prior proposal; unlike
   the Zone column, this one was never even considered on record.

**8. Recorded separately, as instructed — this one is not an inflated statistic, it is a false
statement about a named real person.** The mockup states Cătălina holds a Trainer role alongside
her admin roles. Checked live: she does not. Her actual roles are `operations_manager`,
`curriculum_manager`, `evaluator` — no trainer role at all. Two *other* named people the mockup
mentions in the same sentence (Alexandra Nuțu, Teodora Merișan) do genuinely hold `trainer` — so
this isn't a category error about the sentence's shape, it's a specific fact about a specific person
that isn't true.

**Correcting my own error, not the mockup's — the seventh instance this week of something asserted
as recorded that was not.** I stated the criteria-matrix observations are visible only to Anca and
Cătălina. Checked against item 23 above: that's the opposite of what it says. Item 23's own text is
"whether its visibility should be restricted... **is Anca's decision, still open**" — undecided, not
decided narrowly. Sixth and seventh both landed this session: the AD-10/business_line pair (items
46/48) and now this. Checking the actual source, not the memory of it, is still the only thing that
has caught any of these — noticing has not caught one.

**Two Happy Face mechanisms, never cross-referenced, neither with a table:** the three-workshops-
as-principal rule (`docs/progress.md` #47, 2026-08-11) and the monthly criteria matrix (item 23,
2026-09-01/04). Neither document mentions the other. Whether they're the same system described
twice, or two genuinely different things that happen to share a name, has never been established —
recorded here as open, not assumed either way.

**The blocking fact underneath all of this — corrected against live data before being recorded,
not taken as given.** Checked `auth.users` for the 10 non-`Anka` trainers, not just `public.users.
status` (which reads `'invited'` for all 10 and is already known, per item 21, to be stored and
unmaintained). The live picture is more specific than "never signed in": all 10 accounts were
created directly (`admin.auth.admin.createUser()`, batches on 2026-09-03 and 2026-09-08, `audit_log`
payload literally reads "Created ahead of sending invitations; no invitation email sent") and every
one of the 10 subsequently had a real invitation sent via `resendInvitation` (`audit_log` event
`user.invitation_resent`, one per person, Raluca Popa twice). Of those 10, **8 show a
`last_sign_in_at` timestamp in `auth.users`** — Alexandra Nuțu, Răzvan Bălașov, Teodora Merișan,
Sonia Ganea, Andrada Eremia, Alina Garofil, Elena Bacalum, Raluca Popa. Only **2 show none at all —
Luiza Mirt and Viorel Toboșaru.** "Ten of eleven have never signed in" does not hold against this
table as stated. What does hold, independent of the sign-in question: **zero rows exist in
`sessions`, org-wide** — nobody has been allocated to a session regardless of whether they've ever
opened the app, because nothing in this app writes a session row except Operations creating one, and
none has been created for a real trainer yet.

**One honest limit on the sign-in finding, stated plainly rather than glossed over:** `auth.
audit_log_entries` — the table that would show IP/user-agent and let a real trainer's login be told
apart from this session's own magic-link-driven verification touching the same accounts — is
completely empty in this project, for every user, not just these ten. The `last_sign_in_at`
timestamps are real Supabase Auth session events, not a stale/unmaintained column the way `users.
status` is — but which of the 8 reflect an actual trainer clicking their own email, versus this
session's own testing incidentally authenticating as them, cannot be fully separated with the
evidence this project retains. Recorded as a genuine gap, not resolved by assumption either
direction.

**Lives in:** `docs/mockup/wow_lab_os_mockup.html` lines 1050-1082 (`S.team`/`S.trainers`);
`docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` (the six-grade and rejected-Zone-column findings);
`docs/OPEN_ITEMS.md` item 21 (`users.status`, unmaintained), item 23 (the criteria matrix's real,
still-open visibility question), item 49 above (`certifications.*`, seeded and unused); `docs/
progress.md` #47 (the other Happy Face mechanism); `public.audit_log` (`user.account_created`,
`user.invitation_resent` events for all 10); `auth.users` (`last_sign_in_at` per person).

---

### 54. The ten trainers' invitations have expired — deliberately not resent

Confirmed 2026-09-11 (item 53's own investigation): every one of the 10 real trainer invitations
(`user.invitation_resent`, `public.audit_log`) is expired — the freshest is three days old, the
oldest eight, both well past any real link's lifetime.

**Decision: do not resend yet.** There is nothing for a trainer to do in the app once they're in —
confirmed the same date, `sessions` holds zero rows org-wide, and item 53 found no trainer-facing
screen of any kind exists. Resending ten invitations into an app with no trainer-facing destination
would reproduce exactly the pattern item 53 already found once: activity that looks like engagement
but isn't backed by anything real underneath it.

**Trigger for resending: when a trainer-facing screen actually exists**, not before. Whoever builds
that screen should resend as part of shipping it, not treat the resend as a separate, earlier step.

**Lives in:** item 53 above (the investigation this decision follows from); `app/(app)/admin/users/
actions.ts` (`resendInvitation` — the mechanism, already built and already proven to work: 8 of the
10 prior resends produced a real sign-in, per item 21's 2026-09-11 caveat below).

---

### 55. Four more mockup screens claim per-trainer filtering they don't perform — same shape as item 53, found investigating the trainer's own screen instead of the management directory

Item 53 checked `S.trainers`, the management-facing directory. A separate pass checked every
screen a `trainer`/`senior_trainer` role can reach in the mockup — there is no dedicated "My
Work" screen; the trainer experience is threaded through 11 shared screens via a `mine`/`trainer`
boolean. Two of those (`S.groups`, `S.pay`) genuinely filter. **Four do not, despite claiming to
in their own banner copy:**

1. **`S.attendance`** (`docs/mockup/wow_lab_os_mockup.html:1095`) — no `mine`/`trainer` branch
   exists in the function at all. The same 3 static rows (Lycée Cl.2 · 12.05 → 11/12; IBSB
   Preschool · 14.05 → 9 anonymous; Cambridge · 11.05 → 8/8) render for every role, despite
   `attendance` being on the trainer nav specifically (line 297).
2. **`S.delivered`** (line 1096) — same shape: no filtering branch, same 3 static "delivered"
   rows (Baking-soda volcano · Lycée; Water rocket · IBSB; DNA from strawberries · Cambridge) for
   every role.
3. **`S.inv_reuse`** (lines 920-936) — the banner explicitly claims "You only see what's in your
   custody" (line 932), but the underlying 5-item table (Volcano kit, Microscopes, Kids' lab
   coats, Water rocket kit, Magnet sets) is not filtered by viewer identity anywhere in the
   function — same custody list shown regardless of role.
4. **`S.plans`** (lines 866-888) — not unfiltered, **mislabeled**. The `mine` branch (line 871:
   `if(mine) rows=rows.filter(p=>p[2]===tt('Elementary','Primar'));`) filters by curriculum
   *level* ("Elementary"), not by which trainer is viewing. The banner (line 883) claims
   "Filtered to your groups: Elementary" — a level filter wearing a per-trainer-groups label.

Same discipline as item 53: checked the function bodies directly, not inferred from banner text
or nav placement. A screen's own copy claiming personalization is not evidence that it is
personalized — three of these four are copy claims with zero backing code, the fourth is a real
filter mislabeled as a different one.

**Lives in:** `docs/mockup/wow_lab_os_mockup.html` (all four screens, line numbers above); item 53
above (the same pattern, found on the management directory screen first).

---

### 56. Five of the trainer's six real capabilities have no route behind them

`trainer`/`senior_trainer` hold six capabilities (`supabase/seed.sql:176-187`, confirmed live via
`role_capabilities`): `mywork.*`, `curriculum.read`, `community.read`, `finance.own.read`,
`materials.custody`, `presentations.own`. Only `mywork.*` reaches an actual screen —
`/groups` and `/groups/[id]` (`app/(app)/layout.tsx`'s `canReadGroups` OR-branch). Confirmed live
by `find`: no `curriculum`, `community`, `presentations`, or `materials` route/directory exists
anywhere under `app/`, and `finance.own.read` has no consuming route either — grepped, zero hits
outside `supabase/seed.sql` itself. Five capabilities granted, five unreachable; a trainer's real
access surface today is exactly one screen, regardless of what their capability set implies.

**Lives in:** `supabase/seed.sql:87-187` (the six grants); `app/(app)/layout.tsx` (the only nav
gate that reads any of them); item 53 above (the same directory-vs-reality gap, on capabilities
instead of a screen).

---

### 57. A row match is not a capability — the sessions attendance-write policy shipped without one, and its own assertions didn't catch it

`sessions`' trainer UPDATE branch shipped 2026-09-10 (migration `202609110003`) as a bare row
match: `trainer_principal_id = auth.uid() OR trainer_secundar_id = auth.uid()`, no capability
check. The migration's own comment reasoned this was deliberate — no capability narrower than
`mywork.*` exists for "may this person touch this specific session," and inventing one
(`sessions.write_own` or similar) is too much ceremony for a two-column edit. Both true. The
conclusion drawn from them was not: the choice was never "a new narrow capability, or nothing."
`mywork.*` already exists, is already held by `trainer`/`senior_trainer`, and is already paired
with this exact row match on this same table's SELECT policy (`202608130003`). Dropping the
capability half of that existing pair wasn't supported by the stated reasoning, which was about a
*different, narrower* capability that was never on the table.

**The general form, not just this one instance.** A row match answers "is this their row." A
capability answers "are they still allowed to do this at all." The two questions are independent,
and RLS needs both when a row's identity can outlive a person's standing to act on it — which it
does here: nothing on `sessions` ever clears `trainer_principal_id`/`trainer_secundar_id` when a
person's role changes. A user whose role — and `mywork.*` with it — had been revoked, but whose id
was still sitting in one of those columns on an existing row, would have retained write access to
`attendance_count`/`experiment_delivered` on it indefinitely, through the row match alone.
Dropping a capability check because no *narrower* key exists leaves the *existing, coarser* one
undropped only by accident — and without it, permission that should expire with the role never
does. Worth checking for the same shape anywhere else a row match stands alone in this schema.

**Corrected by migration `202609110004`**, pairing the row match with
`app.has_capability('mywork.*', organization_id)`, exactly matching the SELECT branch. Verified
live against both `wow-lab` (no regression for the four real people already exercising this path)
and `wow-lab-test-b` (all six trainer fixtures, plus the specific case that proves the fix: a
row-matched account holding no `mywork.*` — `contract_administrator` + `finance_operations` only —
is denied, which would have succeeded under `202609110003` alone).

**How this was found, worth recording on its own: not by the feature's own verification.**
`202609110003` shipped with a dry-run script (`verify_sessions_trainer_attendance_write.sql`) that
passed 5/5 assertions, and the commit itself was described as "verified live, as the real users."
Every assertion in it tests an *allowed* case correctly — principal writes, secundar writes,
Operations retains write, an *unallocated* trainer is denied. None of them construct the
*revoked-role* case: a real row match with the underlying capability absent. A green test suite
answered every question it was written to ask and none of the one it wasn't. This was caught only
by re-reading the shipped policy text against the sibling SELECT policy it was supposed to mirror
— the same "check the actual source, don't trust the assertion count" pattern items 46/48/53
already record, applied here to a policy that had already shipped and already passed.

**Lives in:** `supabase/migrations/202609110003_add_sessions_update_trainer_branch.sql` (the
original, still on disk, comment intact — not rewritten to hide the reasoning that produced the
gap); `supabase/migrations/202609110004_require_mywork_capability_on_sessions_trainer_branch.sql`
(the correction); `scripts/verify_sessions_trainer_attendance_write_test_org_b.sql` (assertion 3
specifically — the one that isolates the gap by row-matching an account with no `mywork.*`);
`supabase/migrations/202608130003_add_groups_sessions_rls_policies.sql` (the SELECT policy this
was supposed to mirror from the start).

---

### 58. Three dependency advisories, none currently reachable — a property of what this app's code does, not of which versions it runs

`npm audit` (GitHub's own Dependabot feed wasn't reachable from this session — no API
authentication available — so this was run against the same underlying advisory database
directly) found three vulnerable packages. `next` (the two RCE advisories, `GHSA-p293-qw3h-jr36`
and `GHSA-2xp9-vwfh-vxw4`) is patched — `15.5.23` → `15.5.24`. `sharp` (`0.34.5`) and `postcss`
(`8.4.31`, nested at `next/node_modules/postcss` — not the separate, already-safe top-level
`postcss@8.5.26` that `@tailwindcss/postcss` actually uses) remain vulnerable; confirmed via the
`package-lock.json` diff that neither moved with the `next` upgrade, and confirmed against
`v15.5.24`'s own changelog that its fix for the AVIF advisory was disabling AVIF optimization
outright rather than bumping `sharp` — the pin was never going to move on its own.

**Why none of the three is reachable today, checked against the actual code, not assumed:**

- **`sharp`** is invoked only by Next's Image Optimization API, and that pipeline is only ever
  fed one input in this app: `/logo-wowlab.png`, a static bundled file, via the two `next/image`
  usages that exist (`app/(app)/shell-chrome.tsx`, `app/login/login-content.tsx`). Every
  user-controlled image — specifically the profile avatar upload
  (`app/(app)/profile/profile-section.tsx`) — deliberately uses a plain `<img>` tag instead, with
  an existing code comment explaining why (a dynamic, short-lived signed URL, not something
  `next/image` can usefully optimize). `next.config.ts` sets no `images.remotePatterns`, so the
  Image Optimization endpoint can't be pointed at an external URL either.
- **`sharp`'s advisories are about parsing attacker-controlled image bytes** (libvips/libheif
  memory-corruption issues) — there is no code path in this app where such bytes reach it.
- **`postcss`** (the vulnerable, Next-bundled copy) only ever runs at build time, over this
  repo's own first-party `.css`/Tailwind source (`postcss.config.mjs` → `@tailwindcss/postcss`
  only). Its advisories require it to parse attacker-controlled CSS text; nothing in this app
  accepts CSS as input at any point, build or runtime.
- **`next` itself** is now patched regardless, since it's the framework serving every request —
  but its two advisories were also not reachable before patching, for hosting-specific reasons:
  the RCE requires a Windows-hosted server (this app runs on Vercel's Linux-based Fluid Compute),
  and the AVIF RCE requires attacker-controlled AVIF bytes reaching the same Image Optimization
  pipeline `sharp`'s advisories require — closed by the same one-static-logo fact above.

**This is a property of current code, not of the versions.** Nothing about `sharp`'s or
`postcss`'s pinned versions makes them safe — they remain genuinely vulnerable libraries at rest.
What closes the gap is that this app never gives either one attacker-controlled input to parse.
**Both close at once if either changes:** adding an `images.remotePatterns` entry, or routing the
avatar upload (or any other user-supplied image) through `next/image` instead of a plain `<img>`,
would open the `sharp` path immediately — and since `sharp`'s and `next`'s own image-pipeline code
share the same entry point, either change should be treated as re-opening this whole item, not
evaluated as if the dependency were unrelated to it.

**Lives in:** `next.config.ts` (no `images` config); `app/(app)/shell-chrome.tsx`,
`app/login/login-content.tsx` (the only two `next/image` usages, both `/logo-wowlab.png`);
`app/(app)/profile/profile-section.tsx` (the avatar upload, deliberately a plain `<img>`);
`postcss.config.mjs` (build-time only, first-party source only); `package.json`/
`package-lock.json` (the `next` 15.5.23 → 15.5.24 bump, `sharp`/`postcss` unchanged).

---

### 59. A platform-level 504 reaches the browser above the app's own error handling — and the raw text is the tell

Mihai created a client in `wow-lab-test-b` on the `develop` Preview build (first real traffic
against it in 22 hours, right after the `next` 15.5.24 upgrade — item 58), then tried to create a
group and got "Gateway Timeout" rendered in the error banner. Investigated before anything was
retried: confirmed live, zero rows in `groups` for that org — nothing was written. Cause identified
afterward: a cold function, not the upgrade — the retry created normally, exactly one row, and all
three checks below passed clean on both Preview and production.

**What's worth recording is the shape of the failure, not the cold start itself.** Every error path
this app's own code controls renders a translated string from an i18n dictionary —
`network_error`("The change was not saved...") or a specific `result.error` message. Neither is ever
the literal words "Gateway Timeout." That phrase reaching the banner at all means Vercel's own
platform-level 504 arrived at the browser above this app's `try`/`catch`, not through it — the
Server Action's own response never came back for the client-side handler to catch and translate.
**This app cannot catch this class of failure — there is no code path between the platform and the
browser for it to intercept.**

**The diagnostic value, worth keeping for the next time this happens:** any error text appearing in
one of this app's own banners that is not one of its own i18n strings did not come from this app's
code. That's a fast, reliable first check — before assuming a bug in `addGroup`/`addClient`/etc.,
check whether the displayed text exists anywhere in that screen's dictionary. If it doesn't, the
failure is upstream of the application, and the right next step is exactly what this item's own
investigation did: query the table directly to confirm whether the write landed, not retry the
action while that's still unknown.

**Lives in:** every server-action-calling form's own `catch { setError(t("network_error")) }` block
(`app/(app)/clients/clients-client.tsx`, `app/(app)/contracts/contracts-client.tsx`,
`app/(app)/groups/groups-client.tsx`, and the equivalent edit forms) — the complete set of error text
this app can ever produce on its own; item 58 above (the `next` 15.5.24 upgrade this incident's
timing coincided with, confirmed unrelated to the cause).

---

### 60. Verifying a precondition on a real account took the direct-SQL route §6.4 warns against

Testing the magic-link email template (2026-09-15) needed a *confirmed* `auth.users` row — this
app's own service-role `signInWithOtp` bypass (the identical mechanism `resendInvitation`,
`app/(app)/admin/users/actions.ts`, already uses in production) refuses an unconfirmed user.
`hello@maxdigital.ro` had just been invited and was correctly unconfirmed, since the invite sitting
in that inbox hadn't been opened yet. Rather than wait for that, `email_confirmed_at` was set
directly via `supabase db query --linked` — a real, ad-hoc SQL write against a live production
account, to manufacture a precondition instead of letting the normal path produce it.

**The same category §6.4 of `docs/WOWLAB_SAD_Field_Masking.md` already warns against, not a new
kind of mistake.** §6.4's stated reason is that a direct `db query` connection carries no
`auth.uid()`, so a write through it lands in `row_history` unattributed. Checked precisely for this
instance, not assumed identical: `auth.users` carries no `row_history` trigger at all — only
`on_auth_user_created`/`on_auth_user_deleted` exist on it (confirmed live against `pg_trigger`) — so
no unattributed row landed anywhere. That's incidental to *this* table, the same way item 45's
`COMMENT ON TABLE` case turned out to leave no row either: had the write instead touched a
`public.*` table that *is* row-history-tracked, the identical detour would have produced exactly the
unattributed row §6.4 describes. The underlying problem holds regardless of which table: a real
account's own state was changed by a route that records nothing about who did it or why, other than
this conversation — and `auth.audit_log_entries` is already confirmed empty project-wide (item 21's
addendum), so there is no independent trail to fall back on either.

**Caught and reverted the same session, before it was used for anything further.**
`email_confirmed_at` was set back to `null`; `confirmed_at` (a generated column) followed
automatically. Re-queried after: both null again, `invited_at` and `last_sign_in_at` unchanged from
right after the real invite send — the account sits exactly where the normal path left it, waiting
for Mihai to open the invite already in his inbox.

**Recorded as the same class of finding as item 6.4's own origin, not as an error report on the
disclosure.** The disclosure — stating plainly what was done, in the same message it was done in —
was the right call and is not what this item is about. The action underneath it was the actual
finding: a verification step that needed a precondition took the direct route to create one,
instead of treating "the precondition isn't met yet" as information and waiting.

**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §6.4; item 21 below (`auth.users.last_sign_in_at`
as the real confirmation signal, `public.users.status` never moving in response to it — the same
mechanics this instance's revert relied on); item 45 (the `COMMENT ON TABLE` precedent for a
direct-SQL write landing on a table with no row_history trigger to leave a row in); `pg_trigger`
against `auth.users` (checked live, not assumed, before writing this entry).

---

### 61. A clean `config push` is a claim about the write, not about what is live

The same two email templates (`supabase/templates/magic_link.html`, `invite.html`), the same
`config push`, produced two different headers depending only on how long after the push the email
was sent: the old white-panel-in-gradient-band header at 17:54:55, the reworked white-header
version at 18:29:50 — 2026-09-15, both real sends, both confirmed via `auth.one_time_tokens.
created_at`, both looked at directly in Gmail, not inferred. The push in between reported no diff
either time.

**Confirmed directly, not from a delay number found anywhere in Supabase's own docs:** on a hosted
project, an accepted config write does not mean the service composing outgoing mail is using it
yet. Roughly 35 minutes after the push, it was. Roughly one second after, it was not. No third
send was needed to bound the window tighter than that, and none was made.

**The general form, since this is the same shape this register keeps finding elsewhere (item 59's
platform 504, item 45's confirmation-vs-reality gaps): a tool reporting success describes what the
tool did, not what the system downstream is now doing.** `config push` finishing clean means the
write was accepted — it says nothing about whether the process that actually sends the next email
has picked it up yet. Verifying a template change means sending an email after a real wait and
looking at what arrives; reading `push`'s own "up to date" output is not that, no matter how many
times it's re-run.

**`config push` is also write-only, confirmed while investigating this, not assumed:** `supabase
config --help` lists exactly one subcommand, `push` — no `get`, `pull`, or `diff`. The public
`/auth/v1/settings` endpoint exposes provider and signup flags only, no template content field at
all. There is no read-only way to ask "what is actually live right now" — sending a real email and
looking at it is the only channel that answers that question, for this specific piece of config.

**Lives in:** `supabase/templates/magic_link.html`, `invite.html` (the two templates this was
found on); `auth.one_time_tokens`, `auth.users.updated_at` (the only source of the two exact send
timestamps, since Resend's own send log was not reachable — no `RESEND_API_KEY` in this
environment — and `auth.audit_log_entries` is already confirmed empty, item 21's addendum); item
59 above (the same "a report of success is not a report of downstream reality" shape, on a
different layer of the stack).

---

### 62. A recommendation deferred once was remembered as delivered — the CUI constraint that wasn't there

A unique `(organization_id, cui)` constraint on `clients` was recommended in a report delivered
2026-09-09 — *"the one worth acting on"*, its own words, with a ready migration shape already
specified. Mihai was told it was done. Anca was told it was done. **Neither was true.** It surfaced
only because an unrelated field-parity investigation happened to read `pg_constraint` on `clients`
and found nothing there at all — confirmed by grep across every migration, every commit, and this
project's own session records: no file, no commit message, no doc entry, anywhere, ever proposes or
applies it. Built now — `202609150003` — 2026-09-15, six days after the report that called it
ready.

**Recorded as its own kind of gap, not folded into the other three this register already tracks.**
Item 39/45's pattern is a *document* describing a state that changed underneath it — something
true once, written down, then quietly false. This is different in kind: nothing here ever
described the constraint as existing in writing that then went stale. The report deferred it — "the
one worth acting on," stated, then not acted on — and *that deferral itself* is what later got
misremembered as a completion, told to two people as fact. A "not now" that is never followed by a
"now" produces no artifact contradicting anything: no comment claims the constraint exists, no test
asserts it, no line of code depends on it being there. There is nothing standing that is false —
only an absence with no reason recorded for the absence, and someone's memory of the recommendation
rounding up to "done." Nothing here would ever fail, drift, or get caught by a schema check; the
only way it surfaces at all is a second pair of eyes independently checking the live constraint
list for an unrelated reason, which is exactly how this one did.

**Lives in:** `supabase/migrations/202609150003_add_clients_unique_organization_cui.sql`,
`supabase/rollbacks/202609150003_add_clients_unique_organization_cui_rollback.sql`; `app/(app)/
clients/actions.ts` (`addClient`, `updateClient`), `app/(app)/clients/duplicate-cui-error.ts`;
`scripts/verify_clients_unique_cui.sql`; item 48 above (the sibling question from the same
2026-09-09 report — `business_line` — which *was* carried all the way through: Anca's confirmation,
a real migration, its own item).

---

### 63. The email logo no longer depends on a site this project does not control

Both auth email templates pointed at `wowlab.ro/wp-content/uploads/.../Logo_WOWlab_cuSlogan.png` —
a WordPress media library administered by nobody on this project. A reorganisation, a plugin
change, or a migration there would have broken every future email's header silently, with no error
anywhere this app could see, and retroactively broken the header in every email already sitting in
an inbox, since a `<img src>` is fetched fresh each time the message is opened, not cached into the
message itself.

**Moved onto infrastructure this platform controls, not a third one picked by default.** Confirmed
first, not assumed: `public/` files are served by this app directly, unauthenticated —
`middleware.ts`'s own matcher excludes every `.png`/`.jpg`/`.svg`/etc. path outright, so a request
for one never reaches the auth gate — and never through `/_next/image` (that path is only ever
invoked by the `next/image` component itself; a direct `<img src>` or a plain HTTP request to a
literal path never touches it, confirmed against `next.config.ts` too — no rewrite or redirect
touches this file). A public Supabase Storage bucket was the documented fallback if this hadn't
held; it wasn't needed.

The file itself: `public/wowlab-logo-email.png`, fetched fresh from wowlab.ro and MD5-diffed
against the copy already embedded in both templates before being committed — byte-identical.
Confirmed reachable at the exact literal URL both templates now reference,
`app.wowlab.ro/wowlab-logo-email.png`, on Preview first, then on production, before either
template was pointed at it — never a window where the config could point at a URL that wasn't
live yet. Same dimensions, same alt text, same layout as before this item — a hosting change, not
a visual one.

**Verified per item 61's own finding, not around it.** Pushed the config, then waited before
sending anything — the actual gap between the push (`21:00:14` local, 2026-09-15) and the one real
test send (`auth.one_time_tokens.created_at`, `22:20:23` UTC / `01:20:23` local, 2026-09-16) was
well over an hour, comfortably past the ten-minute floor item 61 established. One send, to
`maxdigitalro+testorg@gmail.com`, confirmed account, no column touched to make it possible.

**Lives in:** `public/wowlab-logo-email.png`; `supabase/templates/magic_link.html`, `invite.html`
(both templates' header comment, updated in place, records this same history); `middleware.ts`,
`next.config.ts` (what was actually checked, not assumed, before relying on `public/`); item 61
above (the push-then-wait discipline this verification followed).

---

## Masking rollout, remaining

These three are already tracked in `docs/WOWLAB_SAD_Field_Masking.md` §2.5,
§2.6, and §5 — re-verified live here rather than presented as new findings.

### 3. `file_refs.gdpr_class`

**Promoted:** the retention/anonymization gap this item was originally scoped
to isn't `file_refs`-specific — it's platform-wide. See the new "Retention
and anonymization" entry near the top of this file for the full scope
(`client_contacts`, `row_history`/`audit_log`, and what the mockup falsely
implies about children's names and rejected candidates).

What's still specific to `file_refs`, confirmed live: `gdpr_class` is a plain
nullable `text` column with no CHECK constraint, referenced by zero triggers
and zero RLS policies on `file_refs` (`authenticated select/insert/update
file_refs` all key off `organization_id` only). The classification is stored
and never read — true independent of whether a retention mechanism exists to
enforce it against.

**Blocked on:** the platform-wide retention mechanism (see above) plus
someone deciding what `gdpr_class`'s values should actually trigger once it
exists.
**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §2.5.

### 4. `row_history` / `audit_log` — masking a jsonb snapshot

Confirmed live: both tables' SELECT policy is `is_platform_owner() OR
(organization_id IS NOT NULL AND has_capability('org.audit.read',
organization_id))` — today held only by `organization_owner` and platform
owner. Not an open path currently (re-confirmed: `operations_manager` gets
`[]` from both).

Structurally still a parallel exposure: `row_history.old_values`/`new_values`
are raw `row_to_json` snapshots of whatever table fired the trigger,
including historical `billing_rule` in clear text and PII from
`client_contacts`/`users`. `audit_log.payload` contains real invitation
emails (confirmed live: `payload->>'email'` on `user.invited` rows). Masking
a jsonb blob is a different mechanism than masking a named column — there's
no single view-based fix the way `contracts_billing_masked` works, since the
sensitive value's location varies row to row depending on which table the
snapshot is of.

**Becomes a live problem the day someone holds `org.audit.read` without the
matching financial/PII visibility** — not before.
**Blocked on:** the masking mechanism itself doesn't exist yet; needs
separate design, explicitly deferred until the five items in
`WOWLAB_SAD_Field_Masking.md` §5 are closed.
**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §2.6.

### 5. `audit_log.payload` convention

Confirmed live: 5 distinct `event_type` values exist today
(`test.cascade_check`, `user.disabled`, `user.enabled`, `user.invited`,
`user.roles_updated`), written from exactly one call site
(`app/(app)/admin/users/actions.ts`). Payload shapes are ad hoc per event
(`{email, roleIds}` for `user.invited`, `{}` for `user.enabled`) — there is no
written convention anywhere for what's allowed into `payload`, confirmed by
grepping all of `docs/*.md` for the word: only `WOWLAB_SAD_Field_Masking.md`
mentions it, and only to say the convention doesn't exist yet.

5 of the "ten event types" the SAD uses as its own trigger point for writing
this convention have shipped. Worth writing before the next 5, not after.

**Blocked on:** nothing except doing it — this is a documentation task, not a
schema change.
**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §2.6, §5 (item 5);
`app/(app)/admin/users/actions.ts` (the only current writer).

---

## Re-verification obligations (wired correctly, protect nothing yet)

### 6. `client_contacts` trainer branch

**Correction to the original framing:** this is not blocked on a trainer
capability reaching the table — `mywork.*` already reaches it. Confirmed
live via `role_capabilities`: `trainer` and `senior_trainer` hold `mywork.*`
today, exactly as the migration comment
(`202608250001_client_contacts_row_filters_and_notes_grant.sql`) says. The
branch is real and wired correctly for the role side.

What actually makes it unreachable, confirmed live: zero rows in
`client_contacts` have `contact_purpose = 'trainer_facing'` — the one real
contact (Vlad Rasnoveanu) has `contact_purpose = 'general'`. The branch has
a role to grant access to and nothing yet to show it.

**Re-verify when:** a trainer-facing read surface (a future Trainer
Dashboard) ships and/or any real contact gets `contact_purpose =
'trainer_facing'` set — either one changes this from a paper check to a live
one.
**Lives in:** `supabase/migrations/202608250001_client_contacts_row_filters_and_notes_grant.sql` (comment block, lines 29-50).

### 7. `crm_link.*` gate on `external_crm_ref`

Confirmed live via `role_capabilities`: `crm_link.*` and `clients.create` are
held by the identical three roles today — Organization Owner, Platform Owner,
Sales Manager. Genuinely non-discriminating in production right now, exactly
as documented.

**Re-verify when:** any role holds `clients.create` without `crm_link.*` (or
vice versa).
**Lives in:** `app/(app)/clients/actions.ts` (`updateClient`, lines ~234-251).

### 8. Contract status transition guard lives in the action, not a trigger

**Correction to the original framing:** the exact "only write path... a
second write path appearing is the point to reconsider that" comment lives
on `changeClientStatus` in `app/(app)/clients/actions.ts` (lines 218-220),
governing `clients.status` — not on `markContractSigned`. `markContractSigned`
itself carries no equivalent comment.

The underlying claim still holds for contracts, independently confirmed:
`updateContract` explicitly excludes `status` from its payload, `deleteContract`
never writes it, `addContract` only sets it once at INSERT time — so
`markContractSigned` remains the only path that transitions `contracts.status`
after creation, and its guard (`current.status !== "draft" && !== "sent"`)
lives in the action, not a DB constraint or trigger. Same architectural
pattern as `changeClientStatus`, just not documented at the same place.

**Re-verify when:** a second write path to `contracts.status` appears.
**Lives in:** `app/(app)/contracts/actions.ts` (`markContractSigned`, no
citing comment today — worth adding one to match `changeClientStatus`'s);
`app/(app)/clients/actions.ts` lines 218-220 (source of the reasoning as
written).

### 9. `contracts.renewal_of` FK-violation path

Confirmed live: zero contracts have `renewal_of` set anywhere in production
today. The DELETE action's `error.code === "23503"` catch
(`app/(app)/contracts/actions.ts`, `deleteContract`) is real and was proven
to fire correctly — but only synthetically, inside the rolled-back dry-run
transaction (`scripts/verify_contracts_delete.sql`, assertion 4). No real
request has ever exercised it.

**Re-verify when:** a renewal flow gives `renewal_of` a real write path.
**Lives in:** `app/(app)/contracts/actions.ts` lines 275-282;
`scripts/verify_contracts_delete.sql` assertion 4.

### 17. Trainer and Senior Trainer hold byte-identical capability sets

Confirmed live via `role_capabilities`: both roles hold exactly
`community.read, curriculum.read, finance.own.read, materials.custody,
mywork.*, presentations.own` — the same six capabilities, nothing more or
less on either side. No `has_capability()` check anywhere in this codebase
can distinguish a Trainer from a Senior Trainer; every gate either grants
both or neither.

Found while doing the dashboard capability-shape inventory this session (a
CEO-style dashboard collapses these two roles into one shape, which is what
surfaced this). Not necessarily a bug — the two roles may be intended to
differ only in something outside the capability system (seniority, pay,
who's allowed to be `trainer_principal_id` vs. `trainer_secundar_id` on a
session, an org-chart fact) rather than in platform access. But if the
distinction is ever meant to gate something in this app — a Senior Trainer
seeing something a Trainer doesn't, or vice versa — nothing today would
carry that weight; it would need its own capability, not inferred from the
role name.

**Re-verify when:** any feature is proposed that's meant to differ between
these two roles specifically.
**Lives in:** `role_capabilities` (live data, not code — no migration
currently seeds these two roles differently).

---

## Small fixes

### 10. `addContract` accepted `signed_date` on a contract forced to draft — RESOLVED

**Closed across two rounds, 2026-09-02.** Round 1 (`67c5c0b`): a DB-level constraint
(`contracts_signed_date_status_check`, `202609020003` — `signed_date is null or status
in ('signed','expired','renewed')`) plus removing `signed_date` entirely from
`addContract` — the parameter, the insert key, and the "Signed Date" form field. Not
validation, a deletion: `status` is hardcoded to `'draft'` on every create, so there was
never a legitimate value that field could hold there. Both landed together, deliberately
— the constraint alone would have turned a silently-ignored field into a raw `23514` on
a labeled, legitimate-looking form field; the create-path fix alone would have protected
only the one call site that remembers, not `updateContract`, not a future write path, not
a direct/service-role write.

Round 2 (this entry's own commit): `markContractSigned` now takes an optional
`signedDate`, precedence caller-value-else-today. The `current.signed_date` fallback
branch it used to have was removed, not left in — confirmed **provably** dead, not just
empirically unused: by the time that line was reached, `current.status` is already known
to be `'draft'` or `'sent'` (the guard above it already passed), and the new CHECK
constraint guarantees `signed_date IS NULL` whenever status is one of those two — so
`current.signed_date` could never have been anything else, enforced by the database, not
by which code paths happen to exist today. `MarkSignedButton` became a small inline
form (date input defaulting to today, editable), matching `DeleteContractButton`'s
existing trigger-then-confirm-pill shape on the same page — the local precedent
consulted before writing it, not a new pattern. Browser-verified with a real session:
backdated date (`2024-03-15`) stored exactly; date field cleared and submitted stored
today's date (`current_date`, confirmed matching); `row_history` recorded both changes
with a real `actor_user_id` (`ecebf92b…`, resolves to `test+ui-contract-admin@wowlab.dev`
— not null, not a service-role artifact); the transition guard re-confirmed live —
attempting the exact `UPDATE ... WHERE status IN ('draft','sent')` shape against an
already-signed row affected 0 rows. Fixture rows cleaned up after; `contracts` and
`clients` confirmed back to 0.

**Open question, reported not decided: should a future `signed_date` be rejected?** A
contract signed tomorrow isn't signed. No validation of this exists anywhere in this
change — the date input has no `max` attribute, `markContractSigned` doesn't compare the
supplied date to today, and no CHECK constraint expresses it. The case for enforcing it:
"signed in the future" is nonsensical the same way "signed while still a draft" was —
arguably the identical class of defect this whole item just closed, just on the other
side of the date. The case for leaving it alone: unlike draft-vs-signed (a closed,
five-value enum with an unambiguous CHECK), "future" is relative to `now()`, which a
plain `CHECK` cannot express in Postgres (CHECK expressions must be immutable — `now()`
isn't) — enforcing it at the DB level needs a trigger, a materially heavier mechanism
than the single-row `CHECK` that closed the rest of this item cheaply. It could live
client-side (a `max` on the date input — cheap, but skippable, same as any client-only
validation), in the action (`signedDate > today` rejected before the UPDATE — matches
this codebase's own precedent of business-rule checks living in the action layer, e.g.
`markContractSigned`'s own status-transition guard), or via a trigger (the only DB-level
option, and the first trigger this codebase would write for a business-rule check rather
than audit capture — a genuinely bigger step than a CHECK). No proposal made here on
purpose — this is the reasoning, not a decision.

**Remaining gap, not built, real the day someone enters a wrong date:** `signed_date` can
now be *set* at the moment of signing, but still cannot be *corrected* afterward —
`updateContract`'s payload never includes `signed_date` (confirmed, unchanged by either
round). This is Option B from the investigation that preceded this fix (adding
`signed_date` to the edit form, gated to `FROZEN_STATUSES` — `["signed","expired","renewed"]`,
already defined in `contract-detail-client.tsx` and, not coincidentally, identical to the
CHECK's own permitted set). Not built because the concrete near-term need (the 14 schools
arriving with contracts already signed in the past) is served by Option A alone — but a
fat-fingered date typed into the new inline form has no way back today except a direct
database write.

**Lives in:** `app/(app)/contracts/actions.ts` (`addContract`, `markContractSigned`);
`app/(app)/contracts/[id]/mark-signed-button.tsx`;
`app/(app)/contracts/contracts-client.tsx`;
`app/(app)/contracts/[id]/contract-detail-client.tsx` (`FROZEN_STATUSES`, the Option B gap);
`supabase/migrations/202609020003_add_contracts_signed_date_status_check.sql`.

### 11. Catalina's account cannot authenticate

Confirmed live: `public.users` has `test+catalina@wowlab.dev` (id
`c82092ea-4dca-4dc8-8b05-bb2fee957272`); `auth.users` has zero rows for that
id or email. Exactly the seed-fixture pattern documented in
`docs/DATABASE_CONVENTIONS.md` §11, with the fix path already written there.

**Lives in:** `docs/DATABASE_CONVENTIONS.md` §11.

### 12. `RETURNING *` on a table with masked/omitted columns returns 403

Confirmed live on **both** tables this session gave DELETE grants to, not
just the one first noticed: a `DELETE ... ?select=` request without an
explicit column list (i.e., PostgREST's `Prefer: return=representation` with
no `select=` param, which becomes `RETURNING *`) returns `403 42501
permission denied for table <name>` on `client_contacts` **and** on
`contracts` (tested against a non-existent id on the latter — nothing was at
risk). The same request with an explicit `select=id` (what both
`deleteClientContact` and `deleteContract` actually send) returns a clean
`200 []`. Not a bug in either delete feature — both were built with an
explicit `select()` from the start — but a sharp edge for any future direct
REST caller who doesn't specify one.

**Lives in:** confirmed via raw REST calls this session, not written up
anywhere yet.

### 13. `contact_purpose` can be set to `null` at the action layer

Confirmed live: `client_contacts_contact_purpose_check` explicitly allows
`NULL` (`(contact_purpose IS NULL) OR (contact_purpose = ANY (...))`), and
both `addClientContact`/`updateClientContact`
(`app/(app)/clients/actions.ts`) do `contact_purpose: contactPurpose || null`
— an empty string collapses to `null`. Unreachable through the real form
today (it always sends a real value, defaulting to `"general"`), reachable by
any other caller of the action.

**Lives in:** `app/(app)/clients/actions.ts` (`addClientContact`,
`updateClientContact`).

### 14. i18n coverage

**Correction to the estimate:** counted live — 19 files under `app/(app)`
don't import from `lib/i18n`, not "roughly 15"
(`app/(app)/admin/users/page.tsx`, both `clients/[id]/*-client.tsx` files,
`clients/page.tsx`, `clients/[id]/page.tsx`, `contracts/[id]/*.tsx`,
`contracts/page.tsx`, `contracts/term-bar.tsx`, `groups/[id]/*.tsx`,
`groups/page.tsx`, `nav-link.tsx`, `profile/*.tsx`). At the time this was
written, `LOCALE_SWITCHER_ENABLED = false` was confirmed live in `lib/i18n.tsx`,
with its own comment stating every existing page is hardcoded English.

**2026-09-02 correction — that claim is now stale, not still true.**
`LOCALE_SWITCHER_ENABLED` is `true`, confirmed live. `lib/i18n.tsx`'s own
comment on the flag explains why: it was flipped on once "All 20 files with
real hardcoded copy are translated now (verified live, RO walk across all 12
routes, twice)" — a real event that happened after this item was first
written, not an error in the original count. The switcher is genuinely live
and user-facing today, not a designed-but-disabled feature — see item 24
below, which found and closed the one real page still outside its reach.

**Lives in:** `lib/i18n.tsx` line 30.

**Structural constraint found while translating the `AccessDenied`
fallbacks (bucket A):** the i18n layer cannot serve Server Components at
all. Locale lives only in client-side state — `localStorage` plus a React
Context (`LocaleProvider`/`useLocale()`, `lib/i18n.tsx`) — with no
server-side equivalent (no cookie, no header, nothing `page.tsx` can read).
Any `page.tsx` that needs translated copy must delegate to a `"use client"`
leaf component, even for a two-line fallback; there is no smaller fix
available within the current design. This is a consequence of the layer
being built ad hoc during the `/contracts` i18n rework (see its own
top-of-file comment: "no next-intl/react-i18next dependency... matching
this codebase's existing plain, hand-rolled over a new dependency style"),
not a deliberate scoping decision. `next-intl` or a URL/cookie-based locale
would remove the constraint by making the locale resolvable server-side.
Not a rewrite to schedule now — noted so the next page that hits this
doesn't have to rediscover it.

**Remaining gap found while closing out bucket C, outside all three
buckets' stated scope:** `clients/[id]/page.tsx` and `groups/[id]/page.tsx`
still render real hardcoded English directly (not via any `*-client.tsx`
child) — `CLIENT_TYPE_LABELS`/`MODULE_LABELS`/`DELIVERY_FORMAT_LABELS`/
`GROUP_STATUS_LABELS` maps, the `Section`/`Kv` titles and field labels for
their own top info block ("Group info", "Client", "Module", "Schedule",
"Children billed", etc.), and each page's own back-link ("← Clients" /
"← Groups"). `contracts/[id]/page.tsx` has a smaller version of the same
thing (the demo-badge tooltip text, the "No exit number yet — {client}"
heading fallback, the "this draft" delete-label fallback). `suppliers/
[id]/page.tsx` is clean — its only page-level content is the back-link and
the raw status badge, both already either non-prose or covered.
Bucket A only translated these files' `AccessDenied` fallback; buckets B
and C only touched their `*-client.tsx` siblings. This block hits the same
Server-Component constraint documented above and would need the same
fix shape as `profile/page.tsx` got in bucket C (extract into small
`"use client"` leaf components, e.g. a shared `group-info.tsx` /
`client-info-header.tsx`) — not attempted here since it wasn't named in
the three buckets and is a real scoping decision, not a mechanical
follow-on.

**2026-09-02 — observed live, not just inferred, for the first time:**
activating one of the six wow-lab-test-b trainer fixtures via a real
invite-link click landed on `/profile` rendered in English, despite the
account belonging to a Romanian-context org. Confirmed cause matches this
item exactly: `lib/i18n.tsx`'s `LocaleProvider` initializes with
`useState<Locale>("en")` and only reads the persisted choice from
`localStorage` in a post-mount `useEffect`. The switcher itself lives only
on `/login` (a second, independent `LocaleProvider` instance sharing the
same `wowlab.locale` key). Invite/magic-link activation goes
`/auth/callback` → `/profile` directly and never visits `/login`, so the
key is never written and `(app)`'s provider mounts with nothing to read —
`"en"` stands. Same structural gap as the rest of this item, now confirmed
on a real activation path rather than reasoned about in the abstract. No
fix proposed here.

### 24. `/login` was outside `LocaleProvider` and showed no message on a failed magic link — RESOLVED

**Correction on how this item started: there was never a prior entry stating `/login` sits
outside `LocaleProvider`.** That was carried across several turns as an unverified assumption,
not read from anywhere in this file — checked directly before writing this entry, not assumed
again. What follows is what was actually found, investigated fresh, then fixed.

**`/login` was structurally outside `LocaleProvider`, for two independent reasons, not one.**
(1) Route-group structure: `app/login/` is a sibling of `app/(app)/`, never nested under it —
`LocaleProvider` is mounted exactly once, in `app/(app)/layout.tsx`, and Next.js only applies a
segment's layout to routes nested beneath it. (2) Even hypothetically ignoring (1): that same
layout is an `async` Server Component that calls `redirect("/login")` for an unauthenticated
visitor *before* its own `return (<LocaleProvider>...)` statement is ever reached — so an
unauthenticated request would bounce out before the provider was constructed regardless.
Confirmed live: `/login` rendered **hardcoded English, unconditionally** — zero imports from
`lib/i18n` anywhere in `app/login/`. It did not attempt to read locale and fail, and it did not
throw — `useLocale()`'s own `if (!ctx) throw new Error(...)` guard is real and would fire for any
*other* page that called it outside the provider, but `/login` never called it at all, so that
path was never exercised. Its old safety here was incidental, not structural.

**Separately, and more urgent given timing: a failed magic link looked identical to a fresh
page.** `/auth/callback` redirects to `/login?error=auth-callback-failed` on any failure —
missing `token_hash`/`type`, or a real `verifyOtp` error (expired link, already-used link) both
converge on this one value. Checked every `redirect("/login")` call site in the app (the
callback, `app/(app)/layout.tsx`'s auth gate, `app/(app)/actions.ts`'s sign-out): this is the
only error value the app ever emits when redirecting here, from the only place that emits one.
`/login` ignored the param entirely — nothing distinguished a dead link from a first visit.

**Both resolved, 2026-09-02, three commits.** `8d00681`: `/login/page.tsx` reads the `error`
search param (Next 15 — awaited, not a hook) and renders a message when it's present, styled to
match the app's existing `bg-brand-pink/10` error-banner convention. `4e982d6`: a second,
independent `LocaleProvider` mounted around `/login`'s content (reads the same `wowlab.locale`
`localStorage` key, so a returning user's stored preference already applies here for free);
every hardcoded string — including the new callback-failure message and the server action's own
error copy — moved into `app/login/i18n.ts`; a visible EN/RO switch added, reusing
`components/ui/locale-switcher.tsx` unmodified rather than building a second one, gated behind
the same `LOCALE_SWITCHER_ENABLED` flag every other page checks. The server action
(`sendMagicLink`) now returns a stable `errorKey` instead of a hardcoded message string, since it
runs server-side with no way to know the caller's locale — the client resolves the actual text,
the same principle the payment-config resolvers already use for their own exception messages.
Browser-verified before each commit, not assumed: the failure banner renders correctly and only
on a failed callback; the switch changes every string (proper nouns and the example email address
deliberately left untranslated, identical in both); the choice survives a full page reload; the
failure banner itself correctly renders in Romanian too, once switched.

**Lives in:** `app/login/page.tsx`, `login-content.tsx`, `login-form.tsx`, `actions.ts`,
`i18n.ts`; `app/auth/callback/route.ts`; `components/ui/locale-switcher.tsx`; `lib/i18n.tsx`.

### 25. No `error.tsx`, `not-found.tsx`, or `global-error.tsx` exists anywhere

Checked directly: zero files of any of these three names anywhere under `app/`. Next.js's own
unstyled, unbranded, English-only default boundaries apply across the entire application — an
unhandled render error or a genuinely missing route shows the framework's generic page, not
anything carrying this app's own visual identity or, now that item 24 is resolved, its locale
system either. Found while investigating item 24's neighboring routes, not built, not urgent —
recorded because it's real and easy to lose track of once the more pressing `/login` gaps closed.

**Lives in:** `app/` (absence, not a file — checked via `find`, not inferred).

### 21. `users.status` is stored, unmaintained, and gates nothing

Confirmed live this session, both by reading every write path and by cross-referencing
`auth.users` for real accounts. Four write paths exist, total: `supabase/seed.sql` (literal INSERT
values at seed time), `public.handle_new_auth_user()` (an `AFTER INSERT ON auth.users` trigger,
hardcodes `'invited'` — confirmed no `AFTER UPDATE` trigger exists on `auth.users` at all, only
this INSERT one and an unrelated `on_auth_user_deleted`), and `enableAccess`/`disableAccess` in
`app/(app)/admin/users/actions.ts` (set `'active'`/`'disabled'`, but only on an admin's explicit
manual ban/unban action). **No code path transitions `invited` to `active` in response to a real
sign-in, ever.** Confirmed live: all 8 `maxdigitalro+<role>@gmail.com` accounts plus
`anca.tanasescu@gmail.com` — 9 real users, item 18 above — have a matching `auth.users` row, a
confirmed email, and a real `last_sign_in_at` timestamp, while `public.users.status` still reads
`'invited'` for every one of them.

Confirmed nothing gates on it: zero RLS policies reference `users.status` (checked every `create
policy` statement across all migrations — only `sessions.status`/`suppliers.status`/
`contracts.status` appear), `lib/capabilities.ts` has zero references, and the actual app guard
(`middleware.ts` → `lib/supabase/middleware.ts`) has zero references. Exactly two reads exist
anywhere in the app, both display-only: the admin Members list badge
(`app/(app)/admin/users/page.tsx`) and a diagnostic "Technical Details" panel on `/profile`
(`app/(app)/profile/page.tsx`). `auth.users.last_sign_in_at` already holds the fact this column is
trying to represent, correctly, for every account that has ever signed in.

**2026-09-02 — confirmed again on day-one rows, not just historical ones.** All six
wow-lab-test-b trainer fixtures seeded this session, activated via real invite links within
minutes to hours of creation, show the identical pattern live: `auth.users.last_sign_in_at`
populated for all six, `public.users.status` still reading `'invited'` for all six. This isn't a
symptom that only shows up on old rows that predate some fix — a brand-new row, activated the
same day it was created, drifts on its very first sign-in, immediately. Strengthens rather than
changes the decision below.

**Decision (2026-09-02): remove the column, derive instead.** Investigated what each of the two
display sites actually needs (admin Members badge/button: purely binary, "is this account
currently banned" — the tone/button-label logic only ever checks `status === "disabled"`; the
3-way label text and filter dropdown are the only place the wider `invited`/`active`/`disabled`
value leaks through, and that value is already the thing confirmed wrong above. `/profile`
Technical Details: a raw debug-panel display, no branching on it at all) against what `auth.users`
already tracks. Two separate needs, two separate answers, both already correct in `auth.users` at
zero incremental cost:

- The ban state: `disableAccess`/`enableAccess` already call Supabase Auth's native ban mechanism
  (`admin.auth.admin.updateUserById(id, { ban_duration: "876000h" | "none" })`) *before* writing
  `users.status` — confirmed by reading both functions. The app's own code comment identifies the
  real enforcement point: `getUser()` (not `getSession()`) revalidates against the Auth server on
  every request, so a banned user's next request anywhere is rejected. `banned_until` is the
  authoritative record; `users.status` is a redundant mirror of it.
- The active-vs-invited distinction: `auth.users.last_sign_in_at` answers this exactly and cannot
  drift, because Auth sets it as a side effect of the sign-in event it describes, not as a second
  write someone has to remember to make. `users.status` answers it wrong today, for 9 of 11 real
  users, precisely because no code path ever performs that second write.

Trigger for the decision: keeping the column *without* building the missing maintenance (the
option this item originally left open) just keeps drifting — it already has, for 9 of 11 real
users, in this project's ~2-month life. Deriving is less code than maintaining, not more, once
`auth.users` already holds both facts correctly.

**Not being done now:** the admin Members list reads this for N rows in one page load, so removing
the stored column requires a batched read against `auth.users` (a `SECURITY DEFINER` function
taking an array of ids, matching the existing `app.is_platform_owner()` convention, or a
service-role `listUsers()` join) — that batching belongs with that screen's next rework, not ahead
of it. `/profile`'s single-row case is trivial either way and isn't the blocker.

**2026-09-08 — a caveat the decision didn't anticipate, not a reversal.** `last_sign_in_at` holds
only the most recent value, and it updates on any real authentication against that account —
including this project's own verification scripts, when they authenticate as a real person rather
than a fixture. It happened today: an RLS verification script (item 37) generated a magic link and
called `verifyOtp` for Raluca Popa's real account to test a `contracts` write-policy change, and her
`last_sign_in_at` now reads today's date. Her genuine sign-in from 2026-09-03 is no longer visible —
the column keeps no history, only the latest value. The decision above still stands: the column
still answers "has this person ever signed in at all" correctly, the only thing either display site
needs. But once a real person's status is derived from it, whatever a verification script does to
that column becomes visible on the admin screen as if it were the person's own activity. Prefer test
fixtures (the `wow-lab-test-b` seeded accounts) over real accounts for this kind of verification
work going forward; when a real account genuinely has to be used, note it plainly, the way this
entry now does.

**2026-09-11 — the limit the 09-08 caveat named for one account turns out to have no ceiling on it
at all.** `auth.audit_log_entries` — the table that would carry IP/user-agent and let a genuine
sign-in be told apart from this project's own verification activity — is **completely empty**,
project-wide, for every user, not just Raluca Popa's. `last_sign_in_at` answers "has this account
ever authenticated," not "has this person ever used the app," and with that table empty there is no
way to recover the difference after the fact, for anyone. Confirmed against the 10 real trainer
accounts investigated the same date (item 53): 8 of 10 show a `last_sign_in_at` timestamp; how many
of those 8 are the trainer's own click versus this session's own testing cannot be established with
the evidence this project retains.

**This does not overturn the 2026-09-02 decision.** The column still answers its narrow question —
"has this account ever authenticated" — better than the unmaintained `status` field does, and
remains the right thing to derive the admin display from. The limit is what it can be read to mean
beyond that narrow question: a timestamp here is not evidence a specific person has actually been in
the app, and should not be read as such by anyone looking at this data later.

**Lives in:** `supabase/migrations/202607130004_add_auth_support_functions.sql`
(`handle_new_auth_user`); `app/(app)/admin/users/actions.ts` (`enableAccess`, `disableAccess`);
`app/(app)/admin/users/page.tsx`; `app/(app)/profile/page.tsx`; item 53 above (the 10 real trainer
accounts this caveat was confirmed against). See also item 40 above — the same
shape of defect (code asserting a guarantee it did not provide), a client-side gate instead of a
DB column.

---

## Infrastructure

### 15. Supabase branching plan tier

Partially verifiable, not fully confirmed. The CLI (`supabase branches
create`) has no dry-run option, and creating a real preview branch is a
billable action — not attempted, since testing a documentation claim isn't
worth an unrequested infrastructure charge. `supabase orgs list` and
`supabase projects list` don't surface plan tier either. What **is**
independently confirmed: the rolled-back-transaction protocol
(`docs/WOWLAB_SAD_Field_Masking.md` §6 / SAD §6) is the one actually in use —
every migration this session was dry-run this way, never against a branch.

**Not fully verified:** whether the current org plan specifically blocks
branching, versus the team simply not having set one up.
**Lives in:** the migration/rollback protocol itself, used throughout
`scripts/verify_*.sql`.

### 16. Repo visibility

Confirmed live via the GitHub API (unauthenticated `GET
/repos/Wow-Lab-The-WHYology-Insitute/App-Wow-Lab`): `"private": false` — the
repo is public, right now, today.

**Not independently re-confirmed this session:** the causal link to a Vercel
Hobby-plan restriction (private org repos can't auto-deploy on Hobby) — no
Vercel CLI auth was available in this environment to re-check the current
plan. This half is carried over from an established prior finding, not
freshly verified here.

**Reopening trigger, folded in 2026-09-18 from `docs/phase1-development-plan.md` row 16 (now
superseded, see item 75 above) — this file's own text never carried it:** return to private when
**both** (a) the Vercel plan upgrades past Hobby, **and** (b) the app reaches a more mature stage —
Mihai's own stated condition, an explicit "and," not "either." Neither half checked as met here;
recorded so the condition lives in the current register instead of only in a document marked
superseded.
**Lives in:** prior session record (Vercel↔GitHub integration work); GitHub
API confirms the visibility half live.

---

## SAD documents referenced across the project

Every `docs/*.md` filename referenced anywhere in the codebase (migrations,
app code, other docs) was checked for existence. All resolved:
`DATABASE_CONVENTIONS.md`, `WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`,
`WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md`,
`WOWLAB_SAD_Field_Masking.md`, `plan-scaffolding-app.md`, `progress.md`,
`ws-d-d1-mapping.md`, `ws-d-plan.md` — all present in `docs/`. No SAD
document referenced anywhere is missing. No mention of a Trainer/Curriculum/
Academy/Financial/HR-domain SAD was found either, so there's no evidence one
was ever planned and lost.

**Correction, 2026-09-03 (item 30).** This audit's scope is "referenced from the codebase" — it
says nothing about SAD documents that exist but have never been referenced from any migration, app
file, or other doc, and it never claimed to. `WOWLAB_SAD_Catalog_Roluri.md` is exactly that case: a
real project file, external to this repo today, not yet ported into `docs/`. Don't read "No SAD
document referenced anywhere is missing" as "no other SAD document exists anywhere" — it was never
that strong a claim, but a plain reading of it produced exactly that wrong inference once this
session, reported to Mihai and corrected in item 30.

---

## What was checked and discarded or corrected

Nothing on the candidate list turned out to be already resolved or never
true outright — every numbered item above is a real, currently-open item.
Several needed the framing corrected against what's actually live, rather
than left as originally stated:

- **Item 6** — wrong mechanism: the trainer capability (`mywork.*`) already
  reaches `client_contacts` today; what blocks it is zero rows with
  `contact_purpose = 'trainer_facing'`, not a missing capability grant.
- **Item 8** — wrong citation: the "reconsider if a second write path
  appears" reasoning is written on `changeClientStatus`
  (`clients/actions.ts`), not `markContractSigned`. The underlying claim
  about contracts still holds; it just isn't written down at the place named.
- **Item 12** — narrower than actual: verified it reproduces on `contracts`
  too, not only the table where it was first noticed.
- **Item 14** — undercounted: 19 files, not ~15.
- **Item 3** — promoted, not just corrected: the retention/anonymization gap
  isn't a `file_refs` sub-item, it's platform-wide (confirmed via `pg_proc`,
  `pg_cron`, `vercel.json` — nothing exists for any table). Given its own
  top-level entry; item 3 now covers only what's still specific to
  `file_refs.gdpr_class`. Also surfaced: the mockup shows children's-names
  and rejected-candidate retention as active toggles, but neither category
  has any stored data today, and a claim made earlier this session (that
  36-month anonymization "is automatic and scheduled") was itself never
  verified and turns out to be false — corrected in `DATABASE_CONVENTIONS.md`
  §9, not in the already-applied migration that stated it.
- **A separate "analysis doc" for the CEO dashboard** — searched for, doesn't
  exist as its own file. The relevant content lives inside
  `WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §5/§7; folded item 1 into
  that rather than inventing a missing document.
- **A pre-existing doc recording Anca's trainer/supplier-contract answers** —
  searched `docs/progress.md` and `docs/phase1-development-plan.md`; found
  the opposite (still listed as awaiting answer as of the most recent
  relevant entries). Recorded item 2 as: answers given in this conversation,
  not yet written up anywhere else.
- **Supabase branching (item 15) and the Vercel-plan half of item 16** — not
  discarded, but flagged as not fully verifiable in this environment rather
  than asserted as confirmed.
