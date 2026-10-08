-- 202610070002_add_suppliers_user_id_and_self_read.sql
--
-- Two changes, one cause.
--
-- CAUSE: `public.suppliers` (202608300001) has no link to `public.users`.
-- The supplier contract register (`Tabel contracte furnizori Wow Lab.xlsx`,
-- ~/Downloads, 39 contracts / 22 suppliers) contains five counterparties who
-- are already people in this app -- ASISMART SRL (Anka Orban), RALUCA MARGEAN,
-- TRUSAN FLORINA CATALINA PFA (Catalina Trusan), POPA C. RALUCA-MARIA-
-- DIETETICIAN (Raluca Popa), MERISAN IOANA-TEODORA PFA (Teodora Merisan).
-- Those five matches were made BY READING EMAIL ADDRESSES BY EYE, comparing
-- the spreadsheet's `Adresa de email` column against `users.email`. Nothing in
-- the schema recorded, enforced or could re-derive them. That is what this
-- column fixes: the identity match stops being an observation someone made
-- once and becomes a stored fact.
--
-- CONSEQUENCE: with no `user_id`, the "own row" branch that this codebase has
-- already built twice (`users_masked`, `client_contacts`) and that
-- docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md Sec5 recommends for
-- `trainer_contracts` was not merely unbuilt on the supplier side -- it was
-- UNEXPRESSIBLE. `app.current_user_id()` returns a `users.id`; there was no
-- column on `suppliers` or (per Sec3.3) on the future `supplier_contracts` to
-- compare it against. Adding the column is what makes the predicate writable,
-- so the predicate is added in the same migration rather than left as a
-- follow-up nobody connects back to this column.
--
-- Verified live immediately before writing this: `suppliers` has 0 rows, so
-- the new column starts fully NULL and there is nothing to backfill. The seed
-- that populates it for the five is a SEPARATE migration (202610070003) --
-- deliberately split, see that file's header.

-- ============================================================================
-- 1. THE COLUMN
-- ============================================================================
-- Nullable, and permanently so: most suppliers are companies with no platform
-- account and never will have one. 17 of the 22 in the register are exactly
-- that. NULL here means "this supplier is not a person who uses this app",
-- which is the normal case, not missing data.
--
-- No UNIQUE constraint. One person could legitimately hold two supplier
-- identities -- an SRL and a PFA, or a PFA that is re-registered -- and the
-- register already shows a person invoicing under a company name (Anka Orban
-- via ASISMART SRL). A UNIQUE constraint would reject the second one. If a
-- rule is wanted later it is "at most one ACTIVE supplier row per user", which
-- is a partial unique index on status='active', not this.
--
-- No ON DELETE: `users` rows are not deleted in this schema (same reasoning
-- as trainer_contracts.user_id, SAD Sec3.2), and a supplier must survive a
-- change in the person's platform status.
alter table public.suppliers
  add column if not exists user_id uuid references public.users(id);

comment on column public.suppliers.user_id is
  'Nullable link to the platform user who IS this supplier, when they are the same legal person. NULL for every supplier who is only a company -- the normal case (17 of the 22 seeded in 202610070003). Exists for two reasons: (1) the five person-suppliers were identified by matching the contract register''s email column against users.email BY EYE, and nothing recorded that match -- this column makes it a stored, re-derivable fact rather than a one-off observation; (2) it is the only thing that makes the "own row" SELECT branch below expressible at all, since app.current_user_id() returns a users.id and suppliers previously had no column to compare it against. NOT a statement that the person holds any particular role -- see the SELECT policy comment.';

create index if not exists suppliers_user_id_idx on public.suppliers(user_id);

-- ============================================================================
-- 2. THE SELF-READ BRANCH -- SELECT ONLY
-- ============================================================================
-- Before: a supplier row was visible only to app.is_platform_owner() or a
-- holder of finance.reporting.*. Confirmed live before writing this, that
-- capability is held by exactly three roles -- finance_admin_reporting,
-- organization_owner, platform_owner -- which today means three accounts
-- (Anka Orban, Anca Tanasescu, maxdigitalro@gmail.com). Notably NOT Laura
-- Moale, who holds finance_operations: that exclusion is deliberate and
-- matches SAD Sec5 ("Laura nu vede contractele de furnizor deloc"), and this
-- migration does not change it.
--
-- The consequence that prompted this branch: Catalina Trusan holds
-- curriculum_manager, evaluator and operations_manager -- none of which carry
-- finance.reporting.* -- so once her PFA exists as a supplier row she could
-- not see the row that IS her. Not her contract: her own identity record.
--
-- Added now rather than later because the column that blocked it is being
-- added in this same migration -- splitting them means the next person to want
-- the branch has to rediscover why it was impossible.
--
-- THIS BRANCH HAS A LIVE READER FROM THE MOMENT user_id IS POPULATED --
-- corrected 2026-10-07, having first been justified as "a policy with no
-- reader costs nothing". That was wrong: `app/(app)/suppliers/` is a complete,
-- committed screen. `page.tsx` guards only that a user is signed in and then
-- runs an RLS-filtered `select` -- the capability check there computes
-- `createOrgId` (the create form) and `canEdit`, NOT read access, which is
-- left to this policy. So once her row carries a user_id, Catalina Trusan
-- visiting /suppliers directly sees a one-row list: herself, with no create
-- form and no edit button. The nav LINK is gated on finance.reporting.*
-- (`layout.tsx`), so she is not led there -- but the route is reachable by URL.
-- That is the intended behaviour of this branch, stated here so nobody reads
-- the one-row list as an RLS leak.
--
-- SELECT ONLY, deliberately. The INSERT and UPDATE policies are left exactly
-- as 202608300001 wrote them. A supplier seeing their own identity record is
-- not a supplier being able to edit it -- self-service maintenance of one's
-- own CUI or name was never asked for and would be a write path into
-- finance-owned reference data.
--
-- No belongs_to_org() guard on the own-row branch, matching the predicate SAD
-- Sec5 specifies for trainer_contracts verbatim (`tc.user_id =
-- app.current_user_id()`, with the org check living only on the capability
-- branch). The row is yours because it is yours; which org recorded it does
-- not change that. Stated explicitly because the omission looks like an
-- oversight and is not.
--
-- user_id is read FROM THE ROW, never from a parameter -- Field Masking Sec5.3's
-- oracle trap. And because user_id is nullable, `user_id = app.current_user_id()`
-- evaluates to NULL (not true) for the 17 company rows, so they are unaffected
-- by this branch rather than accidentally exposed by it.
drop policy "authenticated select suppliers" on public.suppliers;

create policy "authenticated select suppliers" on public.suppliers
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
    or user_id = app.current_user_id()
  );

comment on table public.suppliers is
  'Reference/identity table for contract counterparties who invoice Wow Lab (SAD Contracte_Trainer_Furnizor Sec3.1, step 2 of Sec10). IDENTITY ONLY -- holds no contract: no dates, no value, no rate, no contract number, no drive_ref. Supplier contracts are a separate table (Sec3.3, step 4) that does not exist yet. A person can be BOTH a supplier here and a trainer with a trainer_contract keyed on user_id -- that is not duplication, because this table carries no contract for the two to disagree about. status=''inactive'' replaces hard delete. Readable by finance.reporting.* holders, platform owner, and (since 202610070002) the supplier themselves via user_id -- writable only by the first two.';
