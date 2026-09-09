# Architecture Decisions (AD-1…AD-15) — proposed vs. built

**What this file is not:** a correction to `docs/WOW_LAB_OS_Solution_Architecture_Document.md`. That
file is copied in verbatim and stays wrong where it's wrong — it's the source, kept as a record of
what was proposed, not edited to match what actually got built. This file is the second half: for
each AD, what's true in the repo today, checked against the actual schema, RLS, actions, and docs —
not inferred from the proposal's own confidence.

**Why this exists.** The source document's own closing line: *"Approval of this SAD (including
decisions AD-1…AD-14 and closure of OD-1…OD-10) is the gate for starting Phase 0."* No approval of
any kind is recorded anywhere for this document — it was never even in the repo. Development
proceeded anyway. Four of the fourteen (AD-1, 2, 6, 7) turned out to match what got built, closely,
without ever going through that gate. The rest sat completely dormant, referenced nowhere, for as
long as this document lived only in `~/Downloads`. AD-15 doesn't appear in this document at all — it
was coined later, directly inside a repo `docs/` file, and is the only one of the fifteen with an
explicit written approval anywhere.

## Summary

| AD | Status today |
|---|---|
| 1 | **Implemented.** `organization_id` + RLS on every org-scoped table — exactly as proposed. |
| 2 | **Implemented.** Client belongs to the org; Legal Entity referenced on the Contract. |
| 3 | **Superseded.** No `programs` table exists; `sessions.group_id` is `NOT NULL` — the opposite of what AD-3 proposed. One-off events are `delivery_format` values on `groups` instead. |
| 4 | **Re-derived independently, one month later, reaching the same conclusion.** No `rescheduled` status or `reporting_complete` field exist, but the core argument — a hand-settable status must not double as a trainer's confirmation — is exactly what item 45 part 5 argued into existence from scratch, unaware AD-4 already made it. |
| 5 | **Partially implemented, re-derived independently.** Versioned compensation rule-set tables exist and match AD-5's shape; currency-pairing wasn't carried over (single-currency V1). Arrived at without reference to this document. |
| 6 | **Referenced in repo; feature status not verified this session.** `AD-6` is cited in `WOWLAB_SAD_Catalog_Roluri.md` and `OPEN_ITEMS.md` matching this AD's description. Whether the candidate/magic-link flow is actually built wasn't re-checked in this pass. |
| 7 | **Partially implemented, disconnected from its own citation.** `file_refs` exists with this AD named directly in its column comment — the one place in the whole repo `AD-7` is cited outside a doc — but zero application code ever writes to it. |
| 8 | **Unbuilt, not contradicted.** No curriculum ownership/visibility/licensing columns exist. Consistent with the single-org-until-franchise deferral AD-1 states for itself. |
| 9 | **Unbuilt, and actively contradicted on the immutability half.** No session auto-generation exists at all. Worse: nothing stops a `delivered`/`cancelled` session from being freely edited today — the opposite of what AD-9 requires. |
| 10 | **Proposal, never approved — recorded from memory, not from any document, until this session.** Zero repo references before `OPEN_ITEMS.md` item 45. |
| 11 | **The same decision as AD-15, made twice under two different numbers.** Nobody checked this document before re-deriving and re-approving the identical CRM/platform boundary as "AD-15." |
| 12 | **Half implemented, re-derived independently.** UI locale catalogs (`lib/i18n.tsx`) match AD-12(a); content-level `language`/`family_id` variants (AD-12(b)) don't exist. |
| 13 | **Implemented exactly, with zero traceability.** `row_history` + `audit_log` are the identical two-layer shape AD-13 specifies, real and in active use — the cleanest match in this list, and the one with the least excuse for carrying no citation anywhere. |
| 14 | **Unbuilt, and now directly load-bearing for an open item.** No offline queue, service worker, or local persistence exists anywhere. Named this session as the reason item 45 part 5's confirmation-timestamp design does not survive unchanged. |
| 15 | **Implemented and approved — the only clean case.** Not in the source document; coined and approved directly in `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §9. Same decision as AD-11. |

## Detail

### AD-1 — Multi-tenancy via `organization_id` + RLS
**Implemented.** Every org-scoped table in every migration carries `organization_id`, enforced by
RLS (`enable row level security` + `force row level security`, no exceptions found). Referenced
directly: `docs/WOWLAB_SAD_Catalog_Roluri.md` §3 ("platform_owner... bypass RLS"), `OPEN_ITEMS.md`.

### AD-2 — Client belongs to Organization; Legal Entity on the Contract
**Implemented.** `clients.organization_id`; `contracts.legal_entity_id` (`202608100001`) — the exact
shape proposed, not the PRD's rejected cascade. Referenced directly:
`WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`, `OPEN_ITEMS.md`.

### AD-3 — `program_id` mandatory, `group_id` optional on sessions
**Superseded.** The real schema has no `programs` table at all. `sessions.group_id uuid not null
references public.groups(id)` (`202608130001`) — required, the opposite of AD-3's proposed
`group_id` optional. One-off events (party, corporate, `scoala_altfel`, `saptamana_verde`) are
`delivery_format` enum values on `groups` instead of a separate program layer. A different, simpler
design solved the same named risk (fake one-session groups). Zero repo references to `AD-3`.

### AD-4 — Session status enum; "Completed" derived, never hand-set
**Re-derived independently, a month later, same conclusion.** Real `sessions.status` =
`planned|confirmed|delivered|cancelled` (`202608130001`, widened `202608160004`) — a different value
set, no `rescheduled`, no `reporting_complete`. But AD-4's actual argument — a status two different
callers can each set must not double as "the trainer confirmed" — is word-for-word the argument item
45 part 5 made against reusing `sessions.status` for trainer confirmation, built from this
codebase's own `contracts.status` precedent (item 8), with no knowledge AD-4 existed. Zero repo
references to `AD-4`.

### AD-5 — Compensation as versioned Rule Set data
**Partially implemented, re-derived independently.** `trainer_grades`, `location_bonuses`,
`language_bonuses`, `duration_multipliers`, `contract_type_uplifts` (`WOWLAB_SAD_Contracte_Trainer_
Furnizor.md` §12.8, `202608310002_payment_config_tables.sql`) is the same versioned, org-scoped
rule-set shape AD-5 specifies. Currency-pairing (AD-5's other half) wasn't carried over — consistent
with V1 being single-currency by the same franchise deferral AD-1 states. Zero repo references to
`AD-5`.

### AD-6 — Candidates as records, not accounts
**Referenced; feature not re-verified this session.** Cited in `WOWLAB_SAD_Catalog_Roluri.md`
("candidate → rămâne separat, portal magic-link") and `OPEN_ITEMS.md`, matching AD-6's shape by
description. Whether the magic-link flow itself is built as specified wasn't checked in this pass —
recorded as referenced, not as confirmed-built.

### AD-7 — Storage split: platform (operational binaries) vs. Drive (authored documents)
**Partially implemented, disconnected from its own citation.** `public.file_refs`
(`202607080003`) exists, and its own table comment says *"EU storage file references supporting
AD-7 split storage"* — the one place in this entire repo `AD-7` is named directly in code, not just
a doc. But zero application code anywhere reads or writes `file_refs` (confirmed by grep; reported
in item 45 part 1's photos investigation). The schema-level half of AD-7 shipped with its citation
intact; nothing ever connected it to a feature.

### AD-8 — Network-shared curriculum, ownership + visibility + licensing
**Unbuilt, not contradicted.** `public.modules` (`202608160004`) has no `owner_organization_id`,
`visibility`, or licensing columns — a flat, single-org lookup table. Matches AD-1's own stated
deferral ("single-org UI until Franchise phase"). Zero repo references to `AD-8`.

### AD-9 — Deterministic session generation; delivered/cancelled sessions immutable
**Unbuilt, and actively contradicted on the immutability half.** No auto-generation feature exists —
`addSession` is manual, one session at a time; `groups.schedule_pattern` is free text, not a
generator input. More importantly: nothing enforces immutability on delivered or cancelled sessions.
The `sessions` UPDATE RLS policy (`202608130003`) checks only capability, never `status` — any
`sessions.create` holder can freely edit a `delivered` session's fields today, exactly what AD-9
says should never be allowed. Zero repo references to `AD-9`.

### AD-10 — Frozen monthly statements/billing periods
**Proposal, never approved.** Reported in full last session: this document's own status is "DRAFT —
pending stakeholder approval," Anca is the named audience, not the author, and nothing anywhere
records her having reviewed AD-10 specifically. Zero repo references existed before this session's
`OPEN_ITEMS.md` item 45, written from memory alone.

### AD-11 — Thin CRM boundary; AC integration manual/CSV first
**The same decision as AD-15, made twice, under two different numbers.**
`WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §1/§9 and `clients.external_crm_ref`'s own column
comment describe, almost word for word, the identical boundary AD-11 proposes — AC owns
sales/marketing, the platform owns operational data from "Won" onward, webhook automation explicitly
future work, manual/CSV handoff today — confirmed **"APROBATĂ"** there, under the label `AD-15`.
`AD-11` itself has zero repo references. Nobody checked this document before re-deriving and
re-approving the same boundary a second time.

### AD-12 — Split i18n: UI locale catalogs vs. content language variants
**Half implemented, re-derived independently.** `lib/i18n.tsx`'s per-page RO/EN dictionaries are
exactly AD-12(a) — built, and in active use across every page in this app. AD-12(b) — content rows
carrying `language` + `family_id` — doesn't exist; `modules` has no language column at all. Zero
repo references to `AD-12`.

### AD-13 — Two audit layers: DB row history + app-level business-event log
**Implemented exactly, with zero traceability.** `row_history` (before update/delete trigger on
audited tables, actor + old/new values) and `audit_log` (append-only business events) both exist
and are both real, working infrastructure, cited extensively elsewhere in this repo
(`WOWLAB_SAD_Field_Masking.md`, `OPEN_ITEMS.md` items 6, 12, 45). This is the cleanest match between
proposal and reality anywhere in this list — and the one with the least excuse for having zero
references to `AD-13` itself.

### AD-14 — PWA with offline queue for trainer reporting
**Unbuilt, and now directly load-bearing for an open decision.** No service worker, no
`manifest.json`, no `navigator.onLine` check, no IndexedDB, no local persistence of any form data
anywhere in this repo (confirmed by grep, last session). Named this session as the specific reason
item 45 part 5's two confirmation-timestamp columns don't survive unchanged: a server-received
timestamp measures the wrong moment exactly when a trainer is offline, which is what AD-14 exists to
handle. This AD predicted the gap that surfaced independently, from a completely different
direction, a month later.

### AD-15 — ActiveCampaign / platform system boundary (repo-native)
**Implemented and approved.** Not in the source document — coined and confirmed directly inside
`docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §1 ("propunere AD-15") and §9 ("**APROBATĂ**"),
matched by `clients.external_crm_ref` in the real schema. The only one of the fifteen with an
explicit written approval anywhere in this project — and the same decision as AD-11.

## Cross-cutting notes, not separately actioned

- **OD-7** (`docs/WOW_LAB_OS_Solution_Architecture_Document.md` §6.4: *"Classroom-evaluation
  visibility to the evaluated trainer... PRD explicitly defers"*) is where the repo's
  `org_settings.evaluations_confidential` / OD-7 traces back to — the same open fork item 45 part 4
  named for peer trainer feedback. Not a numbered AD, and not reconciled in this file; flagged
  because it answers a "where did OD-7 come from" question this session happened to surface.
- This reconciliation covers AD-1 through AD-15 only. The source document also lists ten Open
  Decisions (OD-1…OD-10, §6.4) and an implementation roadmap (Phase 6) not reconciled here.
