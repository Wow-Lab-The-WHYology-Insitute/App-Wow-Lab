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
Currently attached to: `user_org_roles`, `org_settings`, `legal_entities`, `file_refs`. Attach it to
any new table marked audited.

`audit_log` is append-only: UPDATE and DELETE are denied for everyone, including Platform Owner,
enforced by a dedicated trigger rather than by policy alone.

## 9. GDPR

Data resides in the EU (Frankfurt), including backups. Personal data is anonymized in place at 36
months — never hard-deleted.

## 10. Migrations vs. seed

Schema changes live in ordered migration files under `supabase/migrations/`. Seed data lives
separately (`supabase/seed.sql`) and must be idempotent — re-running it must not create duplicates
or otherwise change the outcome of a prior run.
