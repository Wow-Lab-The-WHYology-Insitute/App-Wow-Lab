-- 202607100002_add_read_select_policies_ws_d_d1a.sql
-- WOW LAB OS, WS-D · D1a: READ (SELECT) RLS policies + base GRANTs for all 11
-- foundation tables, per docs/ws-d-d1-mapping.md and the approved decisions
-- (org.settings.manage/org.members.manage/org.entities.manage/org.audit.read/
-- org.members.read replace the guessed community.* proxy for the "org admin"
-- gap in that proposal).
--
-- Scope: SELECT only. INSERT/UPDATE are D1b. DELETE stays deny-all everywhere
-- (no grant issued anywhere in this file).
--
-- Idempotent: GRANT is naturally re-runnable; CREATE POLICY is guarded by a
-- pg_policies existence check, matching the pattern already used in
-- 202607080003 for roles/capabilities/role_capabilities.

-- ============================================================================
-- Base GRANTs. Without these, `authenticated` gets "permission denied" on
-- these tables regardless of policy — Postgres checks table-level privilege
-- before RLS ever filters a row. This is the gap D0 flagged as still open.
-- ============================================================================

grant usage on schema public to authenticated;

grant select on public.organizations to authenticated;
grant select on public.legal_entities to authenticated;
grant select on public.users to authenticated;
grant select on public.roles to authenticated;
grant select on public.user_org_roles to authenticated;
grant select on public.org_settings to authenticated;
grant select on public.capabilities to authenticated;
grant select on public.role_capabilities to authenticated;
grant select on public.audit_log to authenticated;
grant select on public.row_history to authenticated;
grant select on public.file_refs to authenticated;

-- ============================================================================
-- SELECT policies.
-- roles / capabilities / role_capabilities already have a permissive SELECT
-- policy from 202607080003 ("authenticated select <table>", using
-- auth.role() = 'authenticated') — only the GRANT above was missing for
-- those three; left untouched here.
-- ============================================================================

-- organizations: platform owner, or a member of that org.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'organizations' and policyname = 'authenticated select organizations'
  ) then
    create policy "authenticated select organizations" on public.organizations
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.belongs_to_org(id)
      );
  end if;
end;
$$;

-- legal_entities: platform owner, or any member of the owning org (approved
-- simplification — no capability gate on read, unlike the contracts.*/
-- contracts.read guess in the D1 mapping proposal).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'legal_entities' and policyname = 'authenticated select legal_entities'
  ) then
    create policy "authenticated select legal_entities" on public.legal_entities
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      );
  end if;
end;
$$;

-- org_settings: platform owner, or any member of the owning org.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'org_settings' and policyname = 'authenticated select org_settings'
  ) then
    create policy "authenticated select org_settings" on public.org_settings
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      );
  end if;
end;
$$;

-- users: platform owner, own row, or an org-admin (org.members.read in some
-- org the target user belongs to) looking up someone else's profile.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'users' and policyname = 'authenticated select users'
  ) then
    create policy "authenticated select users" on public.users
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or id = app.current_user_id()
        or exists (
          select 1
          from public.user_org_roles uor
          where uor.user_id = users.id
            and app.has_capability('org.members.read', uor.organization_id)
        )
      );
  end if;
end;
$$;

-- user_org_roles: platform owner, own membership row, or org.members.read
-- within that row's own organization_id (no EXISTS needed — this table
-- already carries organization_id directly).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'user_org_roles' and policyname = 'authenticated select user_org_roles'
  ) then
    create policy "authenticated select user_org_roles" on public.user_org_roles
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or user_id = app.current_user_id()
        or app.has_capability('org.members.read', organization_id)
      );
  end if;
end;
$$;

-- audit_log: platform owner, or org.audit.read within that row's org. The
-- explicit organization_id IS NOT NULL guard keeps null-org (platform-level)
-- events visible to the platform owner only, never via the capability path.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'audit_log' and policyname = 'authenticated select audit_log'
  ) then
    create policy "authenticated select audit_log" on public.audit_log
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or (organization_id is not null and app.has_capability('org.audit.read', organization_id))
      );
  end if;
end;
$$;

-- row_history: same shape as audit_log, now that organization_id is
-- denormalized onto this table (202607100001). The one legacy NULL-org row
-- (captured before that migration) stays platform-owner-only — expected.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'row_history' and policyname = 'authenticated select row_history'
  ) then
    create policy "authenticated select row_history" on public.row_history
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or (organization_id is not null and app.has_capability('org.audit.read', organization_id))
      );
  end if;
end;
$$;

-- file_refs: platform owner, or any member of the owning org. Baseline
-- org-scope only for now; may tighten to a capability-gated policy later
-- once a file_refs-specific or domain-specific capability exists (see
-- docs/ws-d-d1-mapping.md, "file_refs", Open Question #3).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'file_refs' and policyname = 'authenticated select file_refs'
  ) then
    create policy "authenticated select file_refs" on public.file_refs
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      );
  end if;
end;
$$;
