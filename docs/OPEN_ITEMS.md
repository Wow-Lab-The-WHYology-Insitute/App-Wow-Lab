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
after that roster showed five of those people are active today.

This register does not replace the SAD documents — several items below are
already tracked there in more depth, and this entry says so and points at the
section rather than duplicating it. Its job is to be the one place that lists
everything open, across domains, so nothing here has to be rediscovered.

Update this file as items close or new ones are confirmed. Don't add a
candidate item without checking it against the current code/DB first — that
is the entire reason this file exists instead of being a wishlist.

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

### 19. `groups.contract_id` — a known-null column, deliberately

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
**Lives in:** `docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md` §6.2, §10;
`supabase/migrations/202608290001_groups_contract_id.sql`;
`scripts/verify_groups_contract_id.sql`.

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

### 22. Five of seven named team members have no account at all

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

**Lives in:** `app/auth/callback/route.ts`; `lib/supabase/middleware.ts`; `supabase/templates/
invite.html`; `app/login/page.tsx` (the banner, from `8d00681`).

---

### 29. `displayName()` — the same rule, duplicated in five files, no shared module

Confirmed live: `admin/users/admin-users-client.tsx`, `groups/page.tsx`, `groups/[id]/page.tsx`,
`payment-config/page.tsx`, and now `profile/page.tsx` (this session, item e's fix) each carry their
own local `displayName()`/equivalent. One rule, five independent copies: prefer
`first_name`+`last_name`, fall back to `full_name`, skip the fallback if it looks like an email.
The first four are byte-identical. The fifth necessarily differs in shape — it isn't producing one
display string for read-only rendering, it's deriving two separate initial values for an editable
form, and it feeds an unsplit `full_name` into the first-name field rather than a combined string
into a label. Same rule, not the same function signature.

**Not a defect, not urgent, not to be fixed under time pressure.** Recording as a refactor with an
explicit trigger, not an open-ended someday: extract to one shared module the next time this rule
changes, or the next time a sixth call site needs it — whichever comes first. Until then, five
copies (four identical, one a variant) is the known, accepted state, not an oversight to clean up
opportunistically.

**Lives in:** `app/(app)/admin/users/admin-users-client.tsx`, `app/(app)/groups/page.tsx`,
`app/(app)/groups/[id]/page.tsx`, `app/(app)/payment-config/page.tsx`, `app/(app)/profile/page.tsx`.

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
those 17 — Fatima, Sânziana, Diego — are confirmed "no longer active" by Anca's list. The other 14
(Diana Fainarea, Andreea Minea, Diana Pricopi, Andreea Grulic, Diana Gardus (Cocea), Tudor Nedelcu,
Darius Mirea, Mirela Popa, Andreea Tudor, Maria Nicolescu, Adelina Paduraru, Alexandra Gruia, Gita
Adelina, Andra Onas) appear in neither Anca's active list nor her no-longer-active list — genuinely
unaccounted for, some with large career counts, not resolved here. Separately, 6 of Anca's 9
"no longer active" names (Bianca Necula, Mihai Popa, Roxana Vasile, Ene Vladimir-Lucian, Bordea
Daria, Gabriela Enache) appear in neither the May roster nor Appendix A at all — people who left
before or outside the window either table covers.

**Blocking, recorded as such — not a nice-to-have.** Five people on this active list have no
account and no email address anywhere in this repo or the live database: **Sonia Ganea, Andrada
Eremia, Alina Garofil, Elena Bacalum, Viorel Toboșaru.** Confirmed live, not assumed — checked
`public.users` by name against all 43 rows, zero matches for any of the five. Their accounts can't
be created the way the other eight real accounts were (item 22) until an address exists for each;
nothing to build against here yet.

**No fix proposed here** — waiting on addresses for the five, and on Anca for anything about Lorina
or the Laura Moale/Preda surname question (reported this session, not yet its own item here).

**Lives in:** `public.users` (live data, checked this session); item 22 above (the original eight
real accounts, same pattern this blocks on repeating); item 33 above (the two historical tables this
roster supersedes as a staffing statement); item 23 above (the ~20-people correction this roster
triggered).

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

**Lives in:** `supabase/migrations/202607130004_add_auth_support_functions.sql`
(`handle_new_auth_user`); `app/(app)/admin/users/actions.ts` (`enableAccess`, `disableAccess`);
`app/(app)/admin/users/page.tsx`; `app/(app)/profile/page.tsx`.

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
