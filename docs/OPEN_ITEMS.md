# Open Items Register

A verified list of known-open work: threads not started, rollout gaps, standing
re-verification obligations, small confirmed defects, and infrastructure
constraints. Every item below was checked against the current codebase and/or
the live production database on 2026-08-26 — none of it is carried over from
memory or notes without a fresh check. Where a check corrected or narrowed the
original framing, the correction is written into the item itself, not hidden.

This register does not replace the SAD documents — several items below are
already tracked there in more depth, and this entry says so and points at the
section rather than duplicating it. Its job is to be the one place that lists
everything open, across domains, so nothing here has to be rediscovered.

Update this file as items close or new ones are confirmed. Don't add a
candidate item without checking it against the current code/DB first — that
is the entire reason this file exists instead of being a wishlist.

---

## No scheduled execution mechanism exists

**What it is:** nothing in this system runs on a timer. Confirmed live, comprehensively: `pg_cron`
is not in `pg_extension` (full list checked: `pg_stat_statements`, `pgcrypto`, `plpgsql`,
`supabase_vault`, `uuid-ossp` — nothing scheduling-related); `vercel.json` declares no `crons`;
`package.json` has no cron/scheduler dependency; no `pg_proc` function named
`%retention%`/`%anonymiz%`/`%gdpr%`/`%purge%`/`%scrub%` exists; there is no Supabase Edge Function
doing this either. This is one gap with several symptoms, not several separate gaps — anything
that should happen "automatically, on a schedule, without a person clicking a button" currently
doesn't happen at all, for any reason, anywhere in this codebase.

**Known symptoms today:**
1. **Retention/anonymization** (36-month rule) — documented in `docs/DATABASE_CONVENTIONS.md` §9
   and shown as an active, toggled-on setting in the mockup, when no mechanism exists to run it.
   Full detail below, in this same entry.
2. **Contract expiry transitions** — signed contracts past their term don't move to `expired`
   automatically, because nothing runs to move them. See its own entry, "Contracts past
   `period_end` stay `signed`," further down — that entry is the second half of this same root
   cause, recorded separately because it also raises a design question (stored status vs. derived
   on read) that's independent of the scheduling gap itself.
3. **Anything else time-driven that gets designed later** inherits this same blocker by
   default — worth checking against this entry before assuming a "runs nightly" or "expires after
   N days" feature can just be written as a function and left to fire itself.

**Why the retention symptom belongs at the platform level, not under `file_refs`:** it's a real,
unenforced gap across every category of personal data this platform is supposed to age out
automatically —
- `client_contacts` — PII (email, phone, full_name) for a real person, confirmed live (Vlad
  Rasnoveanu, Lycée Français).
- `row_history`/`audit_log` snapshots — jsonb blobs containing PII and historical financial values,
  confirmed live to never expire (see item 4 below).
- `file_refs.gdpr_class` — the originally-scoped item, still real, see its own entry below for what's
  specific to it.
- Children's names and rejected candidates — see the correction below: neither actually has stored
  data today, but both are described elsewhere as already-retained-and-anonymized.

**Documents and the mockup both describe this as active when it does not exist.**
`docs/DATABASE_CONVENTIONS.md` §9 stated "Personal data is anonymized in place at 36 months — never
hard-deleted" as fact (corrected in this pass — see below). The mockup goes further and shows it as
a live, toggled-on setting: `docs/mockup/wow_lab_os_mockup.html` line 1109, the Organization
Settings page's "Active policies" panel, has three rows all badged "on" (`b-teal`, the same class
used for genuinely active policies): "Anonymize children 36 months after group ends,"
"Rejected-candidate retention — 36 months," and "Confidential evaluations (OD-7)." Checked the
actual backing data: both real organizations' `org_settings.settings` jsonb is `{}` — empty, no
retention configuration stored anywhere, not even inert. The mockup's toggles have no
implementation behind them at all.

**Correction to two of the three categories the mockup implies are being retained:** confirmed
live, neither has any data to retain in the first place —
- Children's names are never stored. `docs/WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md`
  states the attendance model is deliberately "numeric-first" (`attendance_count`, an integer)
  specifically so no per-child record has to exist; a per-child table
  (`session_child_attendance`) is explicitly named as something not built, "fiindcă nu există
  cerere reală pt el" (no real demand for it).
- Rejected candidates: no `candidates` table exists anywhere in `information_schema.tables`. The
  recruitment flow (`docs/phase1-development-plan.md` §3) is mockup/plan-stage only, never built as
  real schema.

So the gap is live and real for `client_contacts`, `users` PII, and `row_history`/`audit_log` —
and moot for children's names and candidates until those features are built with actual data.

**This session's own earlier claim was wrong too, for the record:** the `client_contacts` DELETE
migration comment (`supabase/migrations/202608270001_client_contacts_delete.sql`) states the
36-month anonymization job "runs automatically and is scheduled" — asserted without having been
verified, now confirmed false. That migration is already applied and is not being edited to fix
this (correcting applied migration history isn't the right move); `docs/DATABASE_CONVENTIONS.md`
§9 carries the correction instead. Practically: **`client_contacts` DELETE (202608270001) is
currently the only implemented erasure route for personal data in this system** — not one option
among several, the only one, for anyone who asks to be removed now.

**Blocked on:** choosing a scheduling mechanism for this platform (Supabase `pg_cron`, a Vercel
cron hitting an API route, or an external scheduler) — none exists today in any form, so every
symptom above is blocked on the same missing piece of infrastructure, not on separate designs.
**Lives in:** `docs/DATABASE_CONVENTIONS.md` §9 (corrected this pass); `docs/mockup/
wow_lab_os_mockup.html` line 1109 (the false "on" badges); `docs/
WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md` (numeric-first principle, no per-child data);
`supabase/migrations/202608270001_client_contacts_delete.sql` (the uncorrected, applied migration
comment); `package.json`, `vercel.json`, `pg_extension` (checked, nothing scheduling-related in
any of them).

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
   it — this is a direct symptom of "No scheduled execution mechanism exists" above, not an
   independent gap. Nothing in this codebase currently runs "for every signed contract where
   `period_end < today`, do X."
2. **The open design question, independent of the mechanism.** Even once something can run on a
   schedule, it still has to be decided whether `expired` should be a **stored status** (something
   writes `status = 'expired'` at some point, so `contracts.status` stays the single source of
   truth `markContractSigned`/`deleteContract` already treat it as) or a **derived-on-read** state
   (every reader computes `is_expired = status = 'signed' AND period_end < today` at query time,
   the same way `TermBar` already computes `isPast` client-side, and `status` itself never changes
   until a human acts). These have different implications: a stored status needs the scheduled
   write mechanism above and a decision about whether it's still safe to `markContractSigned`-style
   edit an expired contract; a derived state needs no write path at all but means `contracts.status
   = 'signed'` alone is no longer sufficient to answer "is this contract still current" anywhere it's
   checked (RLS policies, the dashboard, `contracts-client.tsx`'s own status badge).

**Confirmed not caught by the existing render logic:** `TermBar`'s `isRenewalCritical` requires
`!isPast` — an already-ended contract renders in muted gray ("ended N months ago"), not flagged.
The dashboard inventory (this session) found 0 contracts in `TermBar`'s own "critical" 85% window
and 4 past end entirely — the existing UI's one piece of renewal-pressure signal doesn't surface
the more urgent bucket at all today.

**Blocked on:** the scheduling mechanism (see above) plus the stored-vs-derived decision, which
doesn't depend on the mechanism and could be settled first.
**Lives in:** `app/(app)/contracts/term-bar.tsx` (`isRenewalCritical`, `isPast`);
`app/(app)/contracts/actions.ts` (`markContractSigned` — the only place `status` is written after
creation, per item 8 below).

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

### 10. `addContract` accepts `signed_date` on a contract forced to draft

Confirmed live and reachable through the real UI: the "New Contract" form
(`app/(app)/contracts/contracts-client.tsx`, `signed_date_label` input) sends
a `signedDate` value through to `addContract`, which inserts it as-is while
hardcoding `status: "draft"`. No CHECK constraint on `contracts` ties
`signed_date` to `status` (confirmed via `pg_constraint`). A contract can be
created as a draft that already carries a signed date. Currently latent:
zero rows in production have this combination today.

**Lives in:** `app/(app)/contracts/actions.ts` (`addContract`);
`app/(app)/contracts/contracts-client.tsx` (the form field).

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
`groups/page.tsx`, `nav-link.tsx`, `profile/*.tsx`). `LOCALE_SWITCHER_ENABLED
= false` confirmed in `lib/i18n.tsx`, with its own comment stating every
existing page is hardcoded English — the flag and the reasoning both check
out; only the count needed updating.

**Lives in:** `lib/i18n.tsx` line 30.

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
