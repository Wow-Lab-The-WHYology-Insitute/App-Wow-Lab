-- 202609110002_add_groups_update_contracts_star_branch_rollback.sql
-- Rolls back 202609110002: restores the groups UPDATE policy to its
-- pre-2026-09-11 form, byte-identical to 202608130003's own predicate --
-- Operations Manager (+Master) only, contracts.* branch removed.
--
-- Restoring this reinstates the exact block that kept Laura and Anka
-- from writing children_confirmed -- do not run this without confirming
-- Anca's decision has actually changed, not just that a rollback is
-- convenient. updateGroup()'s own column-level gate would still try to
-- include children_confirmed in the payload for a contracts.* holder
-- after this rollback; RLS would then reject the whole UPDATE, same
-- "Not permitted" error path the action already has, not a silent
-- partial write -- but the action itself would need its own update if
-- this rollback is meant to stand for any length of time, not just this
-- policy.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

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
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('groups.create', organization_id)
    );
end;
$$;
