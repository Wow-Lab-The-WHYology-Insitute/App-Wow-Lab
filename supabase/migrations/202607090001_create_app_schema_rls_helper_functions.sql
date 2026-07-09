-- 202607090001_create_app_schema_rls_helper_functions.sql
-- WOW LAB OS, Phase 0 WS-D (D0): RLS helper functions.
-- Idempotent: schema/function/grant statements are all naturally re-runnable
-- (create schema if not exists, create or replace function, grant).
-- This migration creates NO table policies (that is D1) — only the helpers
-- every future policy will call.

create schema if not exists app;

comment on schema app is 'Application-level helper functions for RLS policies (WS-D). Not exposed via the Data API.';

-- 1. app.current_user_id(): the JWT 'sub' claim, i.e. the calling user's id.
create or replace function app.current_user_id()
returns uuid
language sql
stable
set search_path = ''
as $$
  select auth.uid();
$$;

comment on function app.current_user_id() is 'Returns the current caller''s user id from the JWT (auth.uid()).';

-- 2. app.is_platform_owner(): the cross-org RLS bypass condition (convention #3).
-- SECURITY DEFINER so it can read public.users even though that table has no
-- permissive policies yet (deny-by-default, forced RLS).
create or replace function app.is_platform_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select u.is_platform_owner from public.users u where u.id = app.current_user_id()),
    false
  );
$$;

comment on function app.is_platform_owner() is 'True if the current user has users.is_platform_owner = true. SECURITY DEFINER to bypass deny-by-default RLS on public.users.';

-- 3. app.has_capability(cap, org): resolves the current user's roles within
-- `org`, unions their role_capabilities, and matches `cap` either exactly or
-- via a stored wildcard row (e.g. 'curriculum.*' covers 'curriculum.lessons.read').
-- Wildcard match requires the requested cap to start with the wildcard's prefix
-- INCLUDING the trailing dot, so 'curriculum.*' does NOT match 'curriculumX.read'.
create or replace function app.has_capability(cap text, org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    app.is_platform_owner()
    or exists (
      select 1
      from public.user_org_roles uor
      join public.role_capabilities rc on rc.role_id = uor.role_id
      join public.capabilities c on c.id = rc.capability_id
      where uor.user_id = app.current_user_id()
        and uor.organization_id = org
        and (
          c.key = cap
          or (
            right(c.key, 2) = '.*'
            and starts_with(cap, left(c.key, length(c.key) - 1))
          )
        )
    );
$$;

comment on function app.has_capability(text, uuid) is 'True if the current user holds capability `cap` (exact or via a wildcard row) within organization `org`, or is the platform owner. SECURITY DEFINER to bypass deny-by-default RLS on the permission tables.';

-- 4. app.belongs_to_org(org): true if the current user has any role in `org`.
create or replace function app.belongs_to_org(org uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    app.is_platform_owner()
    or exists (
      select 1
      from public.user_org_roles uor
      where uor.user_id = app.current_user_id()
        and uor.organization_id = org
    );
$$;

comment on function app.belongs_to_org(uuid) is 'True if the current user has any user_org_roles row in organization `org`, or is the platform owner. SECURITY DEFINER to bypass deny-by-default RLS on user_org_roles.';

-- Least-privilege exposure: only authenticated (and service_role, which
-- bypasses RLS anyway) can call these; nothing is left executable by PUBLIC.
grant usage on schema app to authenticated, service_role;

revoke all on function app.current_user_id() from public;
revoke all on function app.is_platform_owner() from public;
revoke all on function app.has_capability(text, uuid) from public;
revoke all on function app.belongs_to_org(uuid) from public;

grant execute on function app.current_user_id() to authenticated, service_role;
grant execute on function app.is_platform_owner() to authenticated, service_role;
grant execute on function app.has_capability(text, uuid) to authenticated, service_role;
grant execute on function app.belongs_to_org(uuid) to authenticated, service_role;
