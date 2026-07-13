> ⚠️ **SUPERSEDED** — this was the pre-implementation D1 proposal. The policies actually
> shipped are in migrations `202607100002` (D1a reads) and `202607100004`/`202607100006`
> (D1b writes) + the org-admin capabilities in `fe9d5aa`. Kept for history only.

# WS-D · D1 — RLS Policy Mapping Proposal (for review)

**Status: PROPOSAL ONLY.** No policy SQL, no migration. This maps, for each of the 11
foundation tables and each operation, the proposed base `GRANT` to `authenticated`, the RLS
condition (expressed only via `app.is_platform_owner()`, `app.belongs_to_org(org)`,
`app.has_capability(cap, org)`, or "own row"), and which seeded capability (from the B4
14-role catalog) governs it. Where the catalog has no clean answer, the row is marked
**AMBIGUOUS** with the closest available capability proposed — nothing below invents a new
capability key; any new key would need to go back through a seed change, not a silent D1 add.

`app.is_platform_owner()` is an implicit `OR` on every condition below (platform owner bypass,
convention #3); it is written explicitly the first time per table and implied after that.

---

## organizations

The tenant anchor — not org-scoped (convention #2 exception). No capability in the B4 catalog
names "manage an organization"; only `app.is_platform_owner()` is a clean fit here.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.is_platform_owner() OR app.belongs_to_org(id)` | none — structural (org membership), not capability-gated | A user can see the orgs they belong to; no domain capability needed to just "see your own org exists." |
| INSERT | INSERT | `app.is_platform_owner()` | **AMBIGUOUS** — closest: `platform.admin.manage` | Creating a new organization (franchise onboarding) reads as a platform-admin action; no `organizations.create`-type capability exists. |
| UPDATE | UPDATE | `app.is_platform_owner()` | **AMBIGUOUS** — no capability fits | organization_owner is *named* for this but holds no capability that specifically covers editing `organizations` itself (their "all capabilities within own org" grant is every *seeded* capability row, and none is called `organizations.*`). Proposing platform_owner-only until this is resolved; see Open Questions. |
| DELETE | none | deny (no grant) | n/a | Orgs are never hard-deleted (GDPR convention #9, and org_b is explicitly permanent infrastructure). |

---

## legal_entities

AUDITED, org-scoped. "Sensitive legal/billing container data." No capability was ever named
`legal_entities.*` in the B4 catalog; closest fit is `contracts.*` (legal entity = the
contracting party's legal identity) plus the narrower `contracts.read`.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.belongs_to_org(organization_id) AND (app.has_capability('contracts.*', organization_id) OR app.has_capability('contracts.read', organization_id))` | **AMBIGUOUS** — guessed: `contracts.*` / `contracts.read` | Covers contract_administrator, finance_admin_reporting (both hold `contracts.*`) and finance_operations (`contracts.read`). organization_owner sees it via its blanket set. |
| INSERT | INSERT | `app.belongs_to_org(organization_id) AND app.has_capability('contracts.*', organization_id)` | **AMBIGUOUS** — guessed: `contracts.*` | Only full contract lifecycle roles create legal entities. |
| UPDATE | UPDATE | same as INSERT | **AMBIGUOUS** — guessed: `contracts.*` | |
| DELETE | none | deny (no grant) | n/a | Legal/billing container records are corrected via UPDATE + row_history, not deleted. |

---

## users

Global identity table — **no `organization_id` column**, so org-scoped capability checks need
an `EXISTS` through `user_org_roles` rather than a direct column reference. This is structurally
different from every other table here; flagged in Open Questions.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `id = app.current_user_id() OR app.is_platform_owner() OR EXISTS (SELECT 1 FROM user_org_roles uor WHERE uor.user_id = users.id AND app.has_capability('community.*', uor.organization_id))` | **AMBIGUOUS** — guessed: `community.*` | Own row always visible. Broader "see other people in my org" visibility is guessed as community_people's `community.*` (the role is literally named "Community & People"); operations_manager plausibly also needs some visibility (to allocate/substitute trainers) but has no matching capability either — see Open Questions. |
| INSERT | none | n/a | n/a | Proposing this is **not** a client-side `authenticated` action at all — new rows come from a service-role/Edge Function flow reacting to Supabase Auth signup or an invite-acceptance flow, not a direct PostgREST insert. |
| UPDATE | UPDATE | `id = app.current_user_id() OR app.is_platform_owner() OR EXISTS (SELECT 1 FROM user_org_roles uor WHERE uor.user_id = users.id AND app.has_capability('community.*', uor.organization_id))` | **AMBIGUOUS** — guessed: `community.*` | Own-profile edits, plus the same guessed people-admin path as SELECT. |
| DELETE | none | deny (no grant) | n/a | Users are anonymized in place at 36 months (convention #9), never hard-deleted. |

---

## user_org_roles

AUDITED, "most security-sensitive membership table." Org-scoped via its own `organization_id`.
No capability in the catalog is named for "assign/revoke a role" — same guessed `community.*`
gap as `users`.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `user_id = app.current_user_id() OR app.is_platform_owner() OR app.has_capability('community.*', organization_id)` | **AMBIGUOUS** — guessed: `community.*` | A user can always see their own role rows; broader admin visibility is the same guess as `users`. |
| INSERT | INSERT | `app.is_platform_owner() OR app.has_capability('community.*', organization_id)` | **AMBIGUOUS** — guessed: `community.*` | Assigning a role to a user. |
| UPDATE | UPDATE | same as INSERT | **AMBIGUOUS** — guessed: `community.*` | e.g. changing `assigned_by`/`assigned_at`; role changes are more naturally a delete+insert but UPDATE is included for completeness. |
| DELETE | DELETE | same as INSERT | **AMBIGUOUS** — guessed: `community.*` | Revoking a role. |

---

## org_settings

One row per org. `evaluations_confidential` gates OD-7 later. No capability named
`org_settings.*` exists — same recurring "org-admin" gap.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.belongs_to_org(organization_id)` | none — any org member may read settings that affect their own experience (e.g. OD-7 confidentiality) | Not capability-gated by design; read is a prerequisite for other features to function correctly for *any* role. |
| INSERT | none | n/a | n/a | One row per org, created at org-provisioning time (same service-role flow as `organizations` INSERT), not by end users. |
| UPDATE | UPDATE | `app.is_platform_owner()` | **AMBIGUOUS** — no capability fits | Same gap as `organizations` UPDATE: organization_owner has no specific capability named for this; proposing platform_owner-only pending resolution. |
| DELETE | none | deny (no grant) | n/a | Settings are updated, not deleted (one row is structurally required per org via the unique constraint). |

---

## roles / capabilities / role_capabilities

Global reference tables (convention #2 exception) — explicit rule given: read-only for
`authenticated`, writes are seed/service-role only.

| Table | Op | Base GRANT | RLS condition | Governing capability |
|---|---|---|---|---|
| roles | SELECT | SELECT | `true` (any authenticated user) | none — needed to resolve permissions/labels in the UI |
| roles | INSERT/UPDATE/DELETE | none | deny (no grant) | n/a — seed/service-role only |
| capabilities | SELECT | SELECT | `true` | none |
| capabilities | INSERT/UPDATE/DELETE | none | deny (no grant) | n/a — seed/service-role only |
| role_capabilities | SELECT | SELECT | `true` | none |
| role_capabilities | INSERT/UPDATE/DELETE | none | deny (no grant) | n/a — seed/service-role only |

---

## audit_log

Append-only business event log, org-scoped. Explicit rule given: SELECT only to platform_owner
+ org admins; UPDATE/DELETE never (already enforced by `prevent_audit_log_modification()`
regardless of RLS/grants — RLS is a second layer here, not the only one).

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.is_platform_owner() OR app.has_capability('community.*', organization_id)` | **AMBIGUOUS** — no "org-admin"/audit capability exists; guessed `community.*` as the least-bad proxy | Same recurring gap as `org_settings`/`user_org_roles`. A dedicated capability (e.g. an "org admin" one) would remove the guesswork here and in three other tables. |
| INSERT | INSERT | `app.belongs_to_org(organization_id) AND actor_user_id = app.current_user_id()` | none — logging is not itself capability-gated; the *action being logged* already required its own capability check elsewhere | A user may only write audit rows attributing themselves as the actor, within their own org. |
| UPDATE | none | deny (no grant) | n/a | Enforced twice: no grant here, and `audit_log_prevent_modification()` trigger blocks it unconditionally even for platform_owner. |
| DELETE | none | deny (no grant) | n/a | Same double enforcement as UPDATE. |

---

## row_history

Generic history log for audited tables. **No `organization_id` column**, and it spans multiple
heterogeneous target tables (`table_name` + `row_id`) — there is no generic, single-join way to
express "org-scope this row" without either adding `organization_id` at capture time or doing a
dynamic per-`table_name` join. Proposing the safe interim default and flagging the real fix as
an open question rather than guessing a join.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.is_platform_owner()` | none — deliberately not scoped further yet | Org owners cannot currently see their own org's history under this proposal. See Open Questions — needs either a schema change (store `organization_id` on capture) or a dynamic per-`table_name` policy, neither of which this document invents unilaterally. |
| INSERT | none | n/a | n/a | Only ever written by the `row_history_capture()` trigger function itself, never by a direct client insert. |
| UPDATE | none | deny (no grant) | n/a | Immutable history log. |
| DELETE | none | deny (no grant) | n/a | Immutable history log. |

---

## file_refs

AUDITED, org-scoped. "EU storage file references." Used across many domains (curriculum
materials, contracts, evaluations, …) with no capability of its own in the B4 catalog — proposing
the generic org-scope + own-upload baseline, and pushing real fine-grained control to whatever
domain table references a given file.

| Op | Base GRANT | RLS condition | Governing capability | Notes |
|---|---|---|---|---|
| SELECT | SELECT | `app.belongs_to_org(organization_id)` | **AMBIGUOUS** — no single capability fits a cross-domain attachment table | Baseline org-scope only. A file's *real* visibility (e.g. "can this trainer see this specific curriculum attachment") should be enforced by the domain table that references `file_refs`, not by `file_refs` itself. |
| INSERT | INSERT | `app.belongs_to_org(organization_id) AND uploaded_by = app.current_user_id()` | none | Any org member may upload a file attributed to themselves; the calling feature already gated *why* they're uploading. |
| UPDATE | UPDATE | `uploaded_by = app.current_user_id() OR app.is_platform_owner()` | **AMBIGUOUS** — no capability fits (e.g. reclassifying `gdpr_class`) | Uploader can correct their own file's metadata; broader admin correction guessed as platform_owner-only for now. |
| DELETE | none | deny (no grant) | n/a | GDPR retention (convention #9): anonymize/retire, don't hard-delete; storage cleanup is a service-role process, not an RLS-gated client action. |

---

## OPEN QUESTIONS / AMBIGUOUS

1. **No "org-admin" capability exists in the B4 catalog.** Four tables (`org_settings` UPDATE,
   `audit_log` SELECT, `user_org_roles` INSERT/UPDATE/DELETE/SELECT-beyond-own-row, `users`
   SELECT/UPDATE-beyond-own-row) all need some notion of "administers this org's people/settings,"
   and the closest guess used throughout is `community.*` (community_people) — a real but
   imperfect fit, since that role's stated scope is "Community & People," not general org
   administration. organization_owner covers all of these anyway via its blanket capability set,
   but nothing below platform_owner/organization_owner currently can. **Needs a decision**: either
   accept `community.*` as the de facto org-admin proxy, or add a dedicated capability (e.g. under
   a new `org.admin.*` or similar) in a follow-up seed change — not something this document adds
   unilaterally.

2. **`organizations` and `org_settings` UPDATE have no governing capability at all.**
   organization_owner is the intuitively "right" role but holds no capability literally named for
   editing either table (its grant is "every seeded capability," none of which is called
   `organizations.*`). Proposal defaults to platform_owner-only, which may be tighter than
   intended — **needs a decision** on whether organization_owner should be able to self-service
   edit their own org's name/status/settings, and if so, via what capability.

3. **`legal_entities` and `file_refs` have no capability of their own.** `legal_entities` is
   guessed as governed by `contracts.*`/`contracts.read` (legal identity underpins contracts);
   `file_refs` is proposed as ungated beyond org-scope + own-upload, since it's a generic
   cross-domain attachment table. Both are guesses, not settled mappings.

4. **`users` and `row_history` have no `organization_id` column**, unlike every other table here.
   `users` is worked around via an `EXISTS` through `user_org_roles`. `row_history` has no
   workaround proposed — SELECT is platform_owner-only for now. Giving org owners visibility into
   their own org's history needs either a schema change (denormalize `organization_id` onto
   `row_history` at capture time) or a dynamic per-`table_name` policy — a real design decision,
   not a D1 policy-writing detail.

5. **DELETE is proposed as deny-all across all 11 tables** (no `authenticated` grant anywhere).
   This is consistent with the append-only/audit/GDPR-anonymization conventions already in place,
   but is called out explicitly so it's a reviewed, deliberate choice rather than an oversight.

6. **`users` and `org_settings` INSERT are proposed as "not a client-side action at all"** — new
   rows are expected to come from service-role/Edge-Function provisioning flows (auth signup,
   org onboarding), not direct PostgREST inserts by `authenticated`. Worth confirming that's
   actually how those flows will be built before D1 implementation.
