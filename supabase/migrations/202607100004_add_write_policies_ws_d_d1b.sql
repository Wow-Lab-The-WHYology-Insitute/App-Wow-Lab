-- 202607100004_add_write_policies_ws_d_d1b.sql
-- WOW LAB OS, WS-D · D1b: WRITE (INSERT/UPDATE) RLS policies + base GRANTs,
-- per docs/ws-d-d1-mapping.md and the approved decisions (org.* capabilities
-- from the WS-D prep seed change replace the guessed community.* proxy).
--
-- Scope: INSERT/UPDATE only, and only on the 6 tables listed below. Reference
-- tables (roles/capabilities/role_capabilities), audit_log, and row_history
-- get NO authenticated write policy or grant — seed/service-role/trigger
-- only. DELETE stays deny-all everywhere (no grant, no policy, unchanged).
--
-- Idempotent: GRANT is naturally re-runnable; CREATE POLICY is guarded by a
-- pg_policies existence check, matching 202607100002 (D1a).

-- ============================================================================
-- Base GRANTs — only INSERT/UPDATE, only on tables that get a matching policy
-- below (org_settings/organizations/users get UPDATE only: no authenticated
-- INSERT grant, since new rows there come from seed/service-role flows).
-- ============================================================================

grant insert, update on public.user_org_roles to authenticated;
grant update on public.org_settings to authenticated;
grant update on public.organizations to authenticated;
grant insert, update on public.legal_entities to authenticated;
grant update on public.users to authenticated;
grant insert, update on public.file_refs to authenticated;

-- ============================================================================
-- WRITE policies.
-- ============================================================================

-- user_org_roles: org.members.manage is the power capability — assigning /
-- reassigning roles. organization_owner only, per the seed's dynamic grant
-- (all non-platform.* capabilities).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'user_org_roles' and policyname = 'authenticated insert user_org_roles'
  ) then
    create policy "authenticated insert user_org_roles" on public.user_org_roles
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.members.manage', organization_id)
      );
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'user_org_roles' and policyname = 'authenticated update user_org_roles'
  ) then
    create policy "authenticated update user_org_roles" on public.user_org_roles
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.members.manage', organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.members.manage', organization_id)
      );
  end if;
end;
$$;

-- org_settings: UPDATE only. No authenticated INSERT (one row per org,
-- created at org-provisioning time by service role).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'org_settings' and policyname = 'authenticated update org_settings'
  ) then
    create policy "authenticated update org_settings" on public.org_settings
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
      );
  end if;
end;
$$;

-- organizations: UPDATE only, gated by org.settings.manage on the org's OWN
-- id (organizations has no separate organization_id column — it IS the org).
-- No authenticated INSERT (new orgs are provisioned by service role).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'organizations' and policyname = 'authenticated update organizations'
  ) then
    create policy "authenticated update organizations" on public.organizations
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', id)
      );
  end if;
end;
$$;

-- legal_entities: INSERT and UPDATE gated by org.entities.manage.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'legal_entities' and policyname = 'authenticated insert legal_entities'
  ) then
    create policy "authenticated insert legal_entities" on public.legal_entities
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.entities.manage', organization_id)
      );
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'legal_entities' and policyname = 'authenticated update legal_entities'
  ) then
    create policy "authenticated update legal_entities" on public.legal_entities
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.entities.manage', organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.entities.manage', organization_id)
      );
  end if;
end;
$$;

-- users: UPDATE only (no authenticated INSERT — invite-only via service
-- role). Own profile always editable; org.members.manage additionally
-- allows editing any user who belongs to an org the caller manages.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'users' and policyname = 'authenticated update users'
  ) then
    create policy "authenticated update users" on public.users
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or id = app.current_user_id()
        or exists (
          select 1
          from public.user_org_roles uor
          where uor.user_id = users.id
            and app.has_capability('org.members.manage', uor.organization_id)
        )
      )
      with check (
        app.is_platform_owner()
        or id = app.current_user_id()
        or exists (
          select 1
          from public.user_org_roles uor
          where uor.user_id = users.id
            and app.has_capability('org.members.manage', uor.organization_id)
        )
      );
  end if;
end;
$$;

-- file_refs: INSERT and UPDATE, baseline org-scope only (same as the D1a
-- SELECT policy). May tighten to a capability-gated policy later once a
-- file_refs-specific or domain-specific capability exists (see
-- docs/ws-d-d1-mapping.md, "file_refs", Open Question #3).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'file_refs' and policyname = 'authenticated insert file_refs'
  ) then
    create policy "authenticated insert file_refs" on public.file_refs
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      );
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'file_refs' and policyname = 'authenticated update file_refs'
  ) then
    create policy "authenticated update file_refs" on public.file_refs
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.belongs_to_org(organization_id)
      );
  end if;
end;
$$;
