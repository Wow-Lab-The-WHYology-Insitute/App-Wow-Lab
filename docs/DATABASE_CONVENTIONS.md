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
