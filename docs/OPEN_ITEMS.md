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

---

## Masking rollout, remaining

These three are already tracked in `docs/WOWLAB_SAD_Field_Masking.md` §2.5,
§2.6, and §5 — re-verified live here rather than presented as new findings.

### 3. `file_refs.gdpr_class`

Confirmed live: `gdpr_class` is a plain nullable `text` column with no CHECK
constraint, referenced by zero triggers and zero RLS policies on `file_refs`
(`authenticated select/insert/update file_refs` all key off
`organization_id` only). The classification is stored and never read.

**Stronger finding than the SAD's own framing:** a full search for any
retention/anonymization mechanism — `pg_proc` functions named
`%retention%`/`%anonymiz%`/`%gdpr%`/`%purge%`/`%scrub%`, the `pg_cron`
extension, `vercel.json` crons, a Supabase Edge Function — found **nothing,
for any table, anywhere**. `DATABASE_CONVENTIONS.md` §9 states "Personal data
is anonymized in place at 36 months — never hard-deleted" as if it were an
implemented mechanism; it is a policy decision with no automated
implementation behind it today. This claim was itself relied on, unverified,
earlier in this session (the `client_contacts` DELETE migration's own comment
says the 36-month anonymization "is automatic and scheduled") — that
sentence should be read as intent, not confirmed fact, until this is built.

**Blocked on:** no retention/anonymization policy exists to enforce
`gdpr_class` against, for `file_refs` or any other table.
**Lives in:** `docs/WOWLAB_SAD_Field_Masking.md` §2.5; `docs/
DATABASE_CONVENTIONS.md` §9 (states the policy, not the implementation).

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
- **Item 3** — understated: no retention/anonymization mechanism exists for
  *any* table (confirmed via `pg_proc`, `pg_cron`, `vercel.json`), not only
  for `file_refs`. This also means a claim made earlier this session (that
  36-month anonymization "is automatic and scheduled") was itself never
  verified and turns out to be a stated policy, not an implemented one.
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
