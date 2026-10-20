# Database Conventions

Canonical database conventions for WOW LAB OS, defined during Phase 0 WS-B (B1). Every
migration and every seed file must follow these. Any new table or trigger should be checked
against this list before it ships.

## 1. Identifiers

Every table has `id uuid primary key default gen_random_uuid()`. Foreign key columns are named
`<entity>_id` (e.g. `organization_id`, `role_id`, `user_id`), referencing the singular entity the
column points to.

## 2. Tenancy

Every business/operational table has `organization_id uuid not null references organizations(id)`.
This column is the RLS anchor: row-level security policies scope access by matching it against the
caller's organization context.

Exceptions:
- `organizations` itself (it is the tenant anchor, not a tenant of anything).
- Global reference tables that are not org-scoped: `roles`, `capabilities`, `role_capabilities`,
  and geo lookups.

## 3. Platform Owner

Platform Owner is cross-org via `users.is_platform_owner`. It is never forced into a single-org
assignment through `user_org_roles` — it is the RLS bypass condition, checked directly against the
`users` table rather than a per-org role grant.

## 4. Timestamps

Every table has `created_at` and `updated_at`, both `timestamptz not null default now()`.
`updated_at` is maintained by the shared `trigger_set_updated_at` `BEFORE UPDATE` trigger — every
table gets this trigger attached, not a bespoke one.

## 5. Naming

Snake_case throughout. Table names are plural (`organizations`, `role_capabilities`). Column names
are singular (`organization_id`, not `organization_ids`).

## 6. Roles & permissions are data, not enums

`roles`, `capabilities`, and `role_capabilities` are data tables, not hard-coded enums — this keeps
the permission model configurable and franchise-ready. Application code must never hard-code a role
name to gate a feature; it must resolve access through the capability map instead.

Wildcard capabilities (e.g. `curriculum.*`) are stored as a single literal row, not expanded into
an enumerated list of every fine-grained action. The capability resolver must prefix/glob-match a
requested capability against these wildcard rows (e.g. a check for `curriculum.lessons.update` is
satisfied by a granted `curriculum.*` row).

## 7. Row-Level Security

RLS is enabled and deny-by-default on every table at creation time. Permissive policies are added
per table in WS-D — a table is never shipped with RLS off, even temporarily, while waiting for its
policies.

## 8. Audit

Sensitive tables get the `row_history` trigger (`row_history_capture()`, `BEFORE UPDATE OR DELETE`).
Currently attached to: `client_contacts`, `clients`, `contracts`, `file_refs`, `groups`,
`legal_entities`, `org_settings`, `sessions`, `user_org_roles` (confirmed live via `pg_trigger`,
2026-08-26 — nine tables, not the four previously listed here; five were added and this line was
never updated). Attach it to any new table marked audited, and update this list when you do.

`audit_log` is append-only: UPDATE and DELETE are denied for everyone, including Platform Owner,
enforced by a dedicated trigger rather than by policy alone.

## 9. GDPR

Data resides in the EU (Frankfurt), including backups. The design intent is that personal data is
anonymized in place at 36 months — never hard-deleted. **This is a policy decision, not an
implemented mechanism.** Verified 2026-08-26: no retention/anonymization job exists anywhere in
this system — no DB function, no `pg_cron` (extension not installed), no Vercel cron, no Edge
Function. `docs/OPEN_ITEMS.md` has the full scope of what this leaves unenforced (`client_contacts`
PII, `row_history`/`audit_log` snapshots, and what the mockup implies for children's names and
rejected candidates, neither of which actually has stored data yet).

Until the automatic mechanism is built, `client_contacts` DELETE
(`supabase/migrations/202608270001_client_contacts_delete.sql`) is the only implemented erasure
route for personal data in this system — an on-demand path someone has to invoke, not a substitute
for the automatic one. That migration's own comment says the 36-month job "runs automatically";
it does not, and was never verified before that comment was written. The migration is already
applied and is not being edited to fix this — this section is the correction.

## 10. Migrations vs. seed

Schema changes live in ordered migration files under `supabase/migrations/`. Seed data lives
separately (`supabase/seed.sql`) and must be idempotent — re-running it must not create duplicates
or otherwise change the outcome of a prior run.

## 11. Seed fixtures cannot authenticate

Every `test+*@wowlab.dev` (and `maxdigitalro+*@gmail.com`) row inserted directly by
`supabase/seed.sql` exists in `public.users` but has no matching `auth.users` row. They were
built for SQL-level RLS impersonation (`SET ROLE authenticated` plus a spoofed
`request.jwt.claims`, as in `db/tests/*.sql`), not for signing in — none of them can
authenticate through the real app.

Mechanism: `handle_new_auth_user()` guards its insert with `on conflict (id) do nothing` — it
only protects against an `id` collision. A real Auth signup (invite, magic link) for one of
these emails generates a brand-new `auth.users.id`, different from the `id` `seed.sql` already
put in `public.users`. The guard never fires, and the insert then hits the `users_email_key`
unique constraint on `public.users.email` instead, failing with `23505`.

This is not a bug — these accounts serve RLS tests, not people. A real person needing browser
access gets a real invite, which creates its own matching `auth.users` row from scratch. If a
seed fixture ever genuinely needs to log in, the fix is `admin.auth.admin.createUser({ id:
<existing public.users.id>, email, email_confirm: true })` — passing the existing id turns the
trigger's own `on conflict (id) do nothing` into a no-op instead of a collision, leaving the
fixture's existing `user_org_roles` grants intact. Not something to run by default.

## 12. A status value that means "gone" replaces hard delete, not the other way round

If a table already has a status (or equivalent) value whose purpose is "this record is no
longer active, but keep it and its history" — `clients.status = 'churned'` is the concrete
case (see `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §4, §8) — a hard-delete feature
for that table is not a smaller, more convenient version of the same idea. It is a second,
contradictory answer to a question the schema already settled: the status value exists
specifically so the row survives, and a delete path would let someone route around that on a
whim. Don't build one. This isn't a judgment call to revisit per-table without the underlying
question changing — it's closed until the actual product decision it rests on changes, not
until someone finds deleting more convenient.

This is a general principle, not just about clients — check whether a table already has a
"soft-gone" status before ever proposing hard delete for it.

## 13. Per-row calculations that can fail per row: one set-returning function, an amount **or** a reason_code

Any screen that computes a value per row and can fail per row gets **one set-returning function
that returns, for every row, either the value or a classified reason there isn't one** — never one
call per row, and never a single call that aborts because one row was unanswerable.

First built as `app.calculate_org_session_pay` (`202610150003`, range-scoped in `202610160001`) for
`/payroll`'s per-trainer pay. It is written down here because **nothing about it is specific to
pay**: pay per trainer slot, an invoice line per workshop, a client price per session, a margin per
contract — each computes per row from several lookups, each can be missing an input for one row and
fine for the next, and each is read by a screen where a wrong number is worse than no number.

**The shape.**

```
returns table (<row key...>, value numeric, reason_code text, error_text text)
```

- **One call per screen, not per row.** PostgREST has no way to ask for "the value, or the reason
  there isn't one" per row, so a per-row wrapper means N round trips *and* no isolation.
- **A raise aborts the statement**, so the catching has to happen inside plpgsql: a `begin ...
  exception when others then ... end` block around each row's computation, writing to variables, with
  `return next` *after* the block rather than inside it.
- **`value` is null exactly when `reason_code` is set.** Never zero for "could not compute" — on a
  money screen a zero is a wrong number that becomes a payment.
- **`error_text` is returned alongside, always.** An unmatched shape classifies as `'unknown'` and
  the screen prints the raw message: degraded and ugly, never silent. No failure may vanish by
  failing to match.
- **Classify inside the function, next to the raises**, not in the application. The alternatives are
  worse in both directions: re-asking each input question in SQL duplicates the computing function's
  own guards (and such mirrors drift — item 121's missed every pay-grid gap), while matching in
  TypeScript puts the match a repo away from the raise it matches.
- **Scope by range, not by "everything".** The caller passes the window it is about to display
  (`[p_from, p_to_exclusive)` — exclusive upper bound, so no caller does month-end arithmetic). An
  org-wide version is only correct while the org is empty; the cost of rendering one screen must not
  grow with the org's history. That means the window has to be a **server-side** fact — in the URL,
  not in client state.
- **`SECURITY INVOKER`**, unless the function has an authorization check of its own. These functions
  compose lookups over rate/config tables with their own RLS; `SECURITY DEFINER` would let any
  caller reconstruct those tables row by row from the values returned.
- **Refuse a nonsense window** (inverted or empty range) with a raise rather than returning zero
  rows. Zero rows is indistinguishable from "this window is genuinely empty", which on these screens
  is a statement about money.
- **Round per row, in `numeric`, if the screen shows a rounded figure** — and let totals be the sum
  of the rounded rows. Someone adds the displayed rows up by hand; the total has to agree with a
  calculator. Rounding in the application instead means the language's float representation decides
  the answer.

**The test that has to come with it.** A hand-written list of the failure shapes tests the shapes
someone already thought of. Derive them: read the producing functions' source out of `pg_proc`,
extract every `raise exception` literal and every classifier branch, and assert that **every raise
has a branch that matches it** and every branch is reachable — then sabotage it (add an
unclassified raise inside a rolled-back transaction) and assert the check flips to false.
`db/tests/payroll_reason_code_coverage.sql` is the worked example. Without this, a raise added six
months later becomes a silent `'unknown'` and every existing assertion still passes — which is
item 120's lesson, where a checker written with six anticipated forms missed the seventh added in
the same commit.

## 14. The schema records what happened; the grid decides what gets paid

**A constraint on an operational column must not enforce a pricing rule.** When the two disagree —
when something real happened that the pay configuration cannot price — the record of it is kept and
the *payment* is what fails, loudly and by name. Never the entry.

The worked case is `sessions.duration_minutes`. Its CHECK allows **15 to 480 minutes** while the pay
grid's top band is **120**. That 120–480 gap is a decision, not an oversight:

- A four-hour Școala Altfel day is a real thing that can happen. With a ceiling of 120 it would be
  **unenterable** — Operations would have to lie about the length, or not record the workshop at
  all, and the lie would then be the input to pay.
- With a ceiling of 480 it is **recorded truthfully and simply unpayable**:
  `app.resolve_duration_multiplier` raises above the top band,
  `app.calculate_org_session_pay` classifies that as `no_duration_row`, and `/payroll` shows it
  under *"Gaps in the pay grid — not fixable from this screen"*. Operations records what happened;
  Finance finds out it cannot be priced, and by whom it can be fixed.

**This is the same principle as "a raise does not take the month down" (§13), one layer lower.**
There, one unanswerable row must not cost the other rows their figures. Here, one unpriceable fact
must not cost the organisation its record of the fact. In both cases the failure is **named and
contained** rather than prevented by refusing the input.

**So: before tightening any CHECK on an operational column to match a configuration table, stop.**
The question is not "what values can we price?" but "what values can occur?" — and if the answer is
that something can occur which cannot be priced, that belongs in the resolver's raise and on the
screen, not in a constraint that makes the occurrence unrecordable. A CHECK on such a column is for
**impossible** values (a negative length, a typo of 1200), not for unprofitable or unconfigured
ones.

A side effect worth knowing, since it is how this gets caught: constraints that encode pay rules
also make the test suite unable to construct the unpayable case. `db/tests/payroll_org_session_pay.sql`
needs to insert a workshop above the top band in order to assert that one raise does not take the
month down; a CHECK clamped at 120 would have made that fixture uninsertable, and the test would
have had to be weakened to fit the constraint.

## 15. A migration awaiting a decision lives in `supabase/proposed/`, not in `supabase/migrations/`

A migration that is written and reviewed but **deliberately not applied** — waiting on a decision
rather than on effort — goes in `supabase/proposed/`, with its rollback beside it. It is armed by
moving it to `supabase/migrations/<timestamp>_<name>.sql` and its rollback to
`supabase/rollbacks/<same timestamp>_<name>_rollback.sql`.

**Why a directory and not a naming convention.** The first attempt named the file
`202610200001_PROPOSED_restate_trainer_grade_scale.sql` and left it in `supabase/migrations/`,
reasoning that `PROPOSED` in the name was warning enough. It was not: **`supabase db push` selects
files by the leading timestamp alone and ignores the rest of the filename.** Checked immediately
after writing it, the file was listed as *pending* — it would have been applied by the next
`db push` anyone ran, for any unrelated reason, with nobody deciding anything. Moving it out of the
directory made `pending` go back to `none`.

> **A marker the tool does not read is not a marker.** It is a comment addressed to whoever happens
> to look, on a path where the thing that acts is a command nobody is watching.

This generalises past migrations. Before relying on a filename, a prefix, a suffix or a comment to
hold something back, check what the tool that would act on it actually parses — and if the answer is
"not that", the guard has to be structural: a different directory, a different branch, a missing
file. Naming conventions are for humans reading; they stop nothing.

**What belongs in a proposed file.** The same quality as any migration — full header, guards,
rollback — plus, in the header, **the decision it is waiting on** and, where the proposal differs
from what was asked for, the argument for the difference. A proposed migration is how a
disagreement gets made concrete enough to settle: `restate_trainer_grade_scale.sql` was written
arguing against the instruction that prompted it, and the argument was accepted from reading the
file.

`docs/OPEN_ITEMS.md` carries the reasoning; `supabase/proposed/README.md` carries the mechanics.

## 16. The school year is 1 September – 31 August, labelled by its starting year

`2026-2027` runs from **2026-09-01** to **2027-08-31**. A date belongs to the school year whose
September it follows, so `2026-10-16` and `2027-06-30` are both in `2026-2027`.

**It is derived, never stored.** Any date yields its school year arithmetically, so there is no
column for it and no backfill to get wrong:

```sql
-- the starting year of the school year containing a date
case when extract(month from d) >= 9
     then extract(year from d)
     else extract(year from d) - 1
end
```

**The convention exists because the expensive failure is not storage, it is disagreement.** One
report grouping from September, another from August, a third from the first Monday of term, produce
three different answers to "how much did we bill this year" and no way to tell which is wrong.
Requirement rd. 65 (Laura) asked for a school-year dimension on every report; fixing the boundary
once is the whole of what that needs until something groups by it.

Where the boundary is used, it must be used as written: not "the academic year", not "the contract
period" (client contracts here run 1 September – 30 June, which is a *shorter* window inside the
school year and must not be confused with it), and not the calendar year.

## 17. A correct decision with a wrong reason written beside it

When a decision is recorded, the **reason** recorded with it is load-bearing, because the next
person to touch it will re-derive the decision from that reason — and a wrong reason justifies the
opposite change just as comfortably as the right one.

The worked case: `contract_type_uplift` is deliberately kept at zero rows, and the comment on
`app.resolve_contract_type_uplift` explains why — *"the PFA-inclusive rates in
trainer_grade_rates already have the 11.1% uplift baked in; calling this would double it."* **The
decision was right and the reason was wrong.** There was never an uplift inside those rates
(item 147): the 11% belonged to the client invoice and the instruction was to delete it. The table
should stay empty **because there is no uplift to apply**, not because it has already been applied.

Nothing was ever computed wrongly, which is exactly what makes this dangerous: a wrong reason
beside a correct decision produces **no failing test and no wrong number**. It sits there until
someone reasons from it — and the reason as written would have licensed seeding
`contract_type_uplift` the moment anyone concluded the rates were net.

**So at every revision, the reason is checked, not just the decision.** The question is not "is this
still the right call" but **"is this still the right call for the reason written here"**. The two
come apart silently, and only the first one has tests. Worth looking for deliberately — a decision
whose stated reason no longer holds is a trap with no tripwire.
