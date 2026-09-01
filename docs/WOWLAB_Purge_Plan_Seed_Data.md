# WOW LAB OS — Seed/Test Data Purge Plan

Status: **two tiers, no open questions.** Every row below is confirmed for
deletion. This document is a plan only — nothing in it has been executed.

Scope: organization `wow-lab` (`8e0dcc53-062f-4664-907d-826b9f45bec0`). Origin
of this plan is the live-database forensic investigation of seed/test/real
data in that org (row counts, `row_history`, FK references, structural
markers). Rows previously held as open questions are now resolved by Mihai's
direct confirmation:

- The 4 `groups` and 6 `sessions` rows (all against Cambridge School) are
  module-build residue from developing the groups/sessions feature, not real
  scheduling.
- The `clients` row "Maxdigital" and its one `contracts` row are a stand-in
  used for UI testing, not a real client.

Those confirmations are what makes Cambridge School deletable at all — a
`clients` row can't be removed while `groups.client_id` still points at it —
which is why the tier split below is structured the way it is.

---

## Tier 1 — clears the ground

Independent of the demo-client cluster, or a direct prerequisite to it.
Nothing outside this tier depends on any of these rows.

| Table | Row(s) | id(s) |
|---|---|---|
| `suppliers` | "DELETE-ME-TEST-SUPPLIER" | `47970148-fc65-4eb3-aa59-aefece8feffa` |
| `sessions` | all 6, against the 4 Cambridge groups | `72064917-da77-41de-b5c7-e59f8c2765e3`, `ae36039d-1ed6-4e84-b681-f7f0394e7c54`, `bd82b39d-7cf6-43b5-baec-3426509d17ae`, `d9904c02-4ac7-4a67-8794-88018150770b`, `4a09135a-6ddd-423e-a269-d18cb919d2e4`, `16fae46c-48e3-403d-8140-d42b6fd346cc` |
| `groups` | all 4, all under Cambridge School | `dc7fdf01-9859-4f82-a1ce-1e76f4fe2cbc` (chem_me), `c9a90921-423f-49dd-8f47-9815e28c2bba` (astronomy), `bf8b4848-47e4-4c88-95dc-7fff1400cd13` (doctor), `dff71c2e-60e7-47a8-afe9-463a425554af` (lights) |
| `contracts` | Maxdigital's 1 contract | `b8951c03-611f-4bee-895e-d296c098efde` |
| `clients` | Maxdigital | `74cf4089-ab02-40c9-89bf-7988902e154b` |

**Required order within Tier 1:** `sessions` → `groups` → Maxdigital
`contracts` row → Maxdigital `clients` row. `suppliers` has no ordering
constraint with anything (see FK graph below) and can go at any point.

## Tier 2 — the five demo clients

Unblocked once Tier 1's `groups` rows are gone (Cambridge School is the only
one of the five with anything still pointing at it). All five demo clients,
their contracts, and the one client contact go together as a cluster.

| Table | Row(s) | id(s) |
|---|---|---|
| `contracts` | 5 demo contracts (`DEMO-2026-001..005` origin, `202608100007`) | Lycée Français → `bb8cf3ac-023c-4455-a63b-b0030af94570`; IBSB → `723722c8-c0a4-411b-92c9-e3bb4713a316`; Cambridge School → `db4d6266-2090-458a-9234-ea96f03b10de`; King's Oak → `7d671add-6b46-44c7-b085-a997ff2cf13a`; Zitec → `08e6d216-4c0e-442b-a36e-e323f5c66229` |
| `client_contacts` | Vlad Rasnoveanu (Lycée Français's contact) | `ae291c55-6ebc-486e-adcd-d467b923f89d` |
| `clients` | Lycée Français, IBSB, Cambridge School, King's Oak, Zitec | `0440552d-5664-49c6-a606-8b47ca073631`, `5b94eeeb-0ab3-4fae-aac3-867ae8fa71b5`, `a2a35e51-0dd6-4e61-8e31-aad5e0c2bfee`, `fe355b09-3d31-48b0-82b5-5c0405a0a0eb`, `c83342e4-5a0c-4bbe-b7ea-ed654a131a19` |

**Required order within Tier 2:** the 5 `contracts` rows and the 1
`client_contacts` row → then the 5 `clients` rows. Contracts and the client
contact can be dropped in either order relative to each other (neither
references the other), but both must clear before their parent client.

Total: 24 rows across 6 tables (1 supplier, 6 sessions, 4 groups, 6
contracts, 1 client contact, 6 clients).

---

## Reporting requirement 1 — delete order without CASCADE

Checked directly against the schema (`information_schema.referential_constraints`),
not assumed: **every foreign key across all six tables in scope has
`delete_rule = NO ACTION`.** None are `CASCADE`. Deleting a parent row while
a child row still references it fails outright — there is no automatic
cleanup to lean on, which is why the tier and within-tier ordering above is
mandatory, not a style preference.

Full FK graph for the tables in scope:

```
sessions.group_id        → groups.id           (NO ACTION)
groups.client_id         → clients.id           (NO ACTION)
groups.contract_id       → contracts.id         (NO ACTION — NULL on all 4 live rows, not a live constraint here)
contracts.client_id      → clients.id           (NO ACTION)
contracts.legal_entity_id→ legal_entities.id    (NO ACTION — not deleted, no action needed)
contracts.renewal_of     → contracts.id         (NO ACTION — NULL on all 6 rows in scope)
client_contacts.client_id→ clients.id           (NO ACTION)
suppliers.organization_id→ organizations.id     (NO ACTION — organizations not touched)
```

Combined required order: **`sessions` → `groups` → (`contracts` and
`client_contacts`, either order) → `clients`.** `suppliers` is a leaf with no
dependents anywhere in the schema (confirmed — no FK in `public` references
`suppliers.id`) and carries no ordering constraint relative to the rest.

## Reporting requirement 2 — the draft-only contract guard being bypassed

`contracts` has exactly one DELETE policy (`202608280001_contracts_delete.sql`),
and it requires `status = 'draft'` in addition to a capability check.
Current status of the 6 contracts in scope:

| Contract (client) | status |
|---|---|
| Lycée Français | signed |
| IBSB | signed |
| Cambridge School | signed |
| King's Oak | signed |
| Zitec | sent |
| Maxdigital | signed |

**None are `draft`.** Every one of these deletions is outside what the
app's own RLS policy permits — there is no role or capability combination
that clears this policy for a `signed` or `sent` contract. Executing this
plan requires a service-role or direct-Postgres connection that bypasses RLS
entirely, which means knowingly bypassing this guard, not working within it.
That should be a conscious, logged decision at execution time, not an
incidental side effect of "using the admin client."

`client_contacts` has its own DELETE policy (`202608270001_client_contacts_delete.sql`)
with **no status condition** — Vlad Rasnoveanu's row could in principle clear
that policy under a normal authenticated session with the right capability.
It will be deleted through the same service-role connection as everything
else here for procedural consistency, but it is not gated the same way
contracts are.

`clients`, `groups`, `sessions`, and `suppliers` have **no DELETE policy at
all** (checked directly against `pg_policies` — zero rows for `cmd='DELETE'`
on any of the four). This is a different situation from the contracts case:
there is no guard to bypass because the app currently offers no delete path
for these tables to anyone, at any role. Their removal is necessarily an
out-of-band operation regardless of any status value.

## Reporting requirement 3 — what row_history and audit_log retain

All six tables in scope have a `row_history` trigger attached
(`clients_row_history`, `client_contacts_row_history`, `contracts_row_history`,
`groups_row_history`, `sessions_row_history`, `suppliers_row_history` — all
confirmed present). `row_history` fires `BEFORE ... DELETE`, so **every one
of these 24 deletions will itself generate a new `row_history` row**,
capturing the full deleted row in `old_values` (`new_values` NULL, marking
it a delete). Existing `row_history` entries already on these rows (the
seed-migration legal-data backfill on the 5 demo clients, the UI-verification
touches from `test+ui-*` accounts, the suppliers row's own creation-adjacent
touch) are untouched by the deletion — `row_history.row_id` carries no
foreign key back to the tables it audits, so nothing about the delete
operation itself can orphan or cascade into the audit trail. After the
purge, every row's full history — creation-adjacent state through final
deletion — remains queryable in `row_history` by `table_name` + `row_id`,
even though the `row_id` no longer resolves to a live row anywhere.

`audit_log` retains **nothing about any of these 24 rows, before or after**.
Checked directly: every `audit_log` row for `wow-lab` is a user-lifecycle
event (`user.invited`, `user.roles_updated`, `user.disabled`, `user.enabled`,
`test.cascade_check`) with `target_table = 'users'`. The app's own
`writeAuditLog()` helper (`app/(app)/admin/users/actions.ts`) is only ever
called from that one file and hardcodes `target_table: "users"` — there is
no code path anywhere that writes an `audit_log` entry for `clients`,
`contracts`, `groups`, `sessions`, `client_contacts`, or `suppliers`. An
operator looking for a purge trail in `audit_log` will find nothing; `row_history`
is the only record that this data ever existed or was removed.

## Reporting requirement 4 — legal_name/cui values to re-enter from the tracker

Migration `202608110003_backfill_real_client_legal_data.sql` set these real,
tracker-sourced values on 4 of the 5 demo clients being deleted in Tier 2.
Deleting the `clients` rows deletes these values along with them (they exist
only as columns on the row, nowhere else in the live schema). If any of
these clients are re-created later as real records, these are the values to
re-enter from the Google Sheets contract tracker, exactly as the original
migration recorded them:

| Client | legal_name | cui | Confidence (per 202608110003) |
|---|---|---|---|
| Cambridge School | FUNDATIA MATEAS | 35807977 | High — taken directly from an actual contract row in the tracker |
| IBSB | FUNDATIA INTERNATIONAL BRITISH SCHOOL OF BUCHAREST | RO13212072 | High — taken directly from an actual contract row in the tracker |
| King's Oak | KINGS OAK BRITISH INTERNATIONAL SCHOOL S.R.L. | RO42686827 | High — taken directly from an actual contract row in the tracker |
| Lycée Français | FUNDATIA LYCEE FRANCAIS ANNA DE NOAILLES | 18153988 | High — taken directly from an actual contract row in the tracker |
| Zitec | (none — never given) | RO15496736 | **Lower** — found only in an aggregate reference list in the tracker, not on an actual Zitec contract row; the original migration flagged this specific one as worth double-checking against a real Zitec contract when one exists |

Each demo contract's own `legal_entity_id` (all pointing at "Experimente Wow
SRL" except Zitec, which points at "Brandine Advertising SRL") is not
reproduced here since the `legal_entities` rows themselves are not part of
this purge and remain live afterward.
