-- 202608130003_add_groups_sessions_rls_policies.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — RLS
-- policies (Menu/Record/Action levels).
--
-- "Master" bypass: app.is_platform_owner() OR
-- app.has_capability('org.settings.manage', organization_id), exactly
-- matching 202608100003's own established idiom for Clients & Contracts —
-- organization_owner holds org.settings.manage via the dynamic "all
-- non-platform.* capabilities" grant (seed.sql part 5), so no separate
-- role check is needed anywhere below.
--
-- Record-level design (SAD §4, task spec): Operations Manager, Finance
-- Operations, Finance Admin & Reporting, and Master all see every
-- group/session in the org -- this domain has NO client-type-style
-- segregation the way Clients & Contracts does (confirmed in the task
-- spec and the SAD, which names no such split). Trainer/Senior Trainer are
-- the one role pair with row-level restriction: only sessions where they
-- are trainer_principal_id or trainer_secundar_id, and only groups
-- referenced by such a session -- gated on mywork.* (already held by both
-- roles from B4, no new grant needed) rather than groups.read/
-- sessions.read (which they deliberately do NOT hold, keeping their scope
-- narrow at the capability level too, not just via the row match).
--
-- Action-level (task spec, explicit): Operations Manager (+Master) write
-- groups AND sessions, including trainer_principal_id/trainer_secundar_id
-- (an ordinary column within a normal row UPDATE -- no field-level
-- masking construct needed, since no OTHER role has partial write access
-- to these tables at all). Finance Admin & Reporting: SELECT only, no
-- write policy at all (matches SAD §4's flagged ambiguity resolved
-- conservatively, per the task's explicit instruction). Trainer/Senior
-- Trainer: SELECT only on their own allocated sessions -- no INSERT/UPDATE
-- policy for either role. DELETE: no policy at all, anywhere -- deny-by-
-- default per DATABASE_CONVENTIONS.md #7, identical to Clients & Contracts.
--
-- Idempotent: GRANT is naturally re-runnable; CREATE POLICY is guarded by
-- a pg_policies existence check, matching 202608100003.

-- ============================================================================
-- Base GRANTs. No DELETE grant anywhere (deny-by-default).
-- ============================================================================
grant select, insert, update on public.groups to authenticated;
grant select, insert, update on public.sessions to authenticated;

-- ============================================================================
-- groups — SELECT (menu + record level).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'groups' and policyname = 'authenticated select groups'
  ) then
    create policy "authenticated select groups" on public.groups
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('groups.read', organization_id)
        or (
          app.has_capability('mywork.*', organization_id)
          and exists (
            select 1 from public.sessions s
            where s.group_id = groups.id
              and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
          )
        )
      );
  end if;
end;
$$;

-- groups — INSERT/UPDATE: Operations Manager (+Master) only.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'groups' and policyname = 'authenticated insert groups'
  ) then
    create policy "authenticated insert groups" on public.groups
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('groups.create', organization_id)
      );
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'groups' and policyname = 'authenticated update groups'
  ) then
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
  end if;
end;
$$;

-- ============================================================================
-- sessions — SELECT (menu + record level). Trainer/Senior Trainer: own
-- allocated sessions only, via mywork.* + a direct row match (no join
-- needed, trainer_principal_id/trainer_secundar_id live on this table).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'authenticated select sessions'
  ) then
    create policy "authenticated select sessions" on public.sessions
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('sessions.read', organization_id)
        or (
          app.has_capability('mywork.*', organization_id)
          and (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
        )
      );
  end if;
end;
$$;

-- sessions — INSERT/UPDATE: Operations Manager (+Master) only, including
-- setting/changing trainer_principal_id/trainer_secundar_id (ordinary
-- columns on the row this policy already gates -- no separate check
-- needed for them specifically).
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'authenticated insert sessions'
  ) then
    create policy "authenticated insert sessions" on public.sessions
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('sessions.create', organization_id)
      );
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'authenticated update sessions'
  ) then
    create policy "authenticated update sessions" on public.sessions
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('sessions.create', organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('sessions.create', organization_id)
      );
  end if;
end;
$$;
