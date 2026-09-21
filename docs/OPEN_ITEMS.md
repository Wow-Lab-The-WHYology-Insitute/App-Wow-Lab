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

**Blocked on:** a decision on whether payroll-closing needs cross-segment client visibility, or
should stay scoped to whoever already holds `finance.reporting.*` too (sidestepping the question
by construction) -- not a technical blocker.
**Re-verify when:** real sessions exist across more than one client-type segment and someone holding
only `finance.operations.*` is the one closing payroll.
**Lives in:** the payroll walkthrough fixes entry below (the trainer-name gap this parallels);
item 20 (Laura's `finance.operations.*`-only capability set); `app/(app)/payroll/page.tsx` (the
join); the `clients` table's own SELECT policy (its client-type segregation branch).

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
nothing in it changed — so in the narrowest sense the cited evidence is still true. The conclusion
drawn from it is not: "this discipline catches what a developer review exists to catch" is the part
three dated, real, previously-uncounted instances now contradict. Separately, and independent of
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

**Lives in:** `docs/ws-d-plan.md` (lines 3, 100 — unedited); `docs/phase1-development-plan.md` §4,
row 15 (the closure, unedited); `db/tests/rls_ws_d_read.sql`, `rls_ws_d_write.sql` (the cited suite,
frozen since 2026-07-10), `rls_clients_contracts.sql`, `rls_groups_sessions.sql` (the two
domain suites, each frozen at its own construction week); `supabase/migrations/202608120002_org_scope_avatar_read_policy.sql`,
`202608120003_fix_avatar_read_policy_via_shares_org_helper.sql` (the third, earliest instance, newly
recorded here); `supabase/migrations/202608100003_add_clients_contracts_rls_policies.sql`,
`202608250001_client_contacts_row_filters_and_notes_grant.sql`, `202607100004_add_write_policies_ws_d_d1b.sql`
(the two live unverified candidates); `202609150002_add_sessions_confirmation_columns_and_rls.sql`
(the one checked and ruled safe); item 57 below (the second instance); item 68 above (the third
instance); `phase1-development-plan.md`'s own broader staleness, addressed separately below — this
closure's isolation from the rest of this register is one symptom of it, not the whole of it.

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
**Lives in:** `docs/phase1-development-plan.md` row 6 (superseded, see item 75 below);
`docs/progress.md` #42-43 (the original rate confirmation and correction).

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

**No migration, no table, no code — the structural fork is closed; the extension work itself is not
started.** What's now buildable, pending Anca's vocabulary answer above: the seven still-absent
fields listed earlier in this item, added to `groups`/`sessions`, not to a new entity.

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
