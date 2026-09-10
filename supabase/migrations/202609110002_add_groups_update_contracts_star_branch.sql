-- 202609110002_add_groups_update_contracts_star_branch.sql
-- WOW LAB OS: Anca's decision -- Anka and Laura (contract_administrator,
-- holding contracts.*) fill a group's contracted child count
-- (children_confirmed); Cătălina (operations_manager) sees it but does
-- not fill it. Adds a contracts.* branch to the groups UPDATE policy so
-- a contracts.* holder can pass RLS on a groups row at all -- today they
-- hold neither groups.create nor org.settings.manage and are rejected
-- outright, before any column-level question is even reached.
--
-- Cannot edit 202608130003_add_groups_sessions_rls_policies.sql -- already
-- applied. That migration's own comment, quoted in full:
--
--   "groups — INSERT/UPDATE: Operations Manager (+Master) only."
--
-- That was the correct, complete answer to the task spec it was written
-- against -- Groups & Sessions was scoped with no partial-write role
-- other than Operations. It is no longer complete: this migration adds
-- the first partial-write role the domain has had.
--
-- ============================================================================
-- SCOPE, DELIBERATELY NARROW
-- ============================================================================
--
-- RLS restricts ROWS, not columns -- this migration only lets a
-- contracts.* holder's UPDATE reach a groups row at all. It says nothing
-- about which columns they may actually set; that boundary belongs in
-- updateGroup() (app/(app)/groups/actions.ts), which already narrows
-- Operations' broader grant down to specific fields the same way
-- updateContract() narrows finance visibility -- by omitting a column
-- from the UPDATE payload entirely when the capability check fails,
-- not by sending it and trusting RLS or the client. A contracts.* holder
-- who is not also an operations_manager may write children_confirmed
-- and nothing else; the action enforces that, not this policy.
--
-- INSERT and DELETE on groups are untouched -- Anca's decision was about
-- an existing group's child count, not about who may create or remove a
-- group.

DO $$
begin
  drop policy if exists "authenticated update groups" on public.groups;
  create policy "authenticated update groups" on public.groups
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('groups.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('groups.create', organization_id)
      or app.has_capability('contracts.*', organization_id)
    );
end;
$$;
