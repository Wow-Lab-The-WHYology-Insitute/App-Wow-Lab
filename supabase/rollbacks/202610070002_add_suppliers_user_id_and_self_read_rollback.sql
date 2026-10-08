-- 202610070002_add_suppliers_user_id_and_self_read_rollback.sql
--
-- Reverses 202610070002 exactly: restores the two-branch SELECT policy, drops
-- the index, drops the column, and clears the table comment.
--
-- ORDER MATTERS. The policy must be restored BEFORE the column is dropped --
-- the forward policy references `user_id`, so dropping the column first would
-- either cascade the policy away or fail, leaving the table with no SELECT
-- policy at all for a window. A table with RLS enabled and no SELECT policy is
-- deny-all, so getting this backwards would silently blind the three accounts
-- that can legitimately read suppliers.
--
-- NOTE: if 202610070003 (the 22-row seed) has been applied, run ITS rollback
-- first. Dropping `user_id` here would silently discard the five identity
-- matches it stored, and those were made by reading emails by eye -- they are
-- not re-derivable from anything else in the schema.

-- 1. Restore the original two-branch SELECT policy (202608300001, verbatim).
drop policy "authenticated select suppliers" on public.suppliers;

create policy "authenticated select suppliers" on public.suppliers
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

-- 2. Index, then column.
drop index if exists public.suppliers_user_id_idx;

alter table public.suppliers
  drop column if exists user_id;

-- 3. The table had NO comment before 202610070002 -- confirmed live
-- (obj_description returned null), so restoring means clearing it, not
-- rewriting an earlier string.
comment on table public.suppliers is null;
