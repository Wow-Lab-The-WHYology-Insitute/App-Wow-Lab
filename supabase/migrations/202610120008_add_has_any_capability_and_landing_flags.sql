-- ============================================================================
-- Two functions so the post-sign-in landing costs ONE round trip instead of
-- up to nine. The rules do not change -- both of these call the existing
-- app.has_capability once per key, and nothing about who lands where moves.
-- ============================================================================
-- Measured before building, against the real deployment, warm median of five
-- (scripts/measure_landing_path.ts): trainer 660 ms, owner 295 ms, ops manager
-- 274 ms. The trainer is the worst case because they are the one account that
-- cannot short-circuit: mywork.* matches, then all eight "beyond own work"
-- keys have to come back false before /my-work is the answer. Everyone else
-- exits on the first or second call.
--
-- ============================================================================
-- 1. app.has_any_capability -- the primitive
-- ============================================================================
-- Deliberately a LOOP over app.has_capability rather than one widened query.
-- app.has_capability is where the wildcard rule lives (`right(c.key,2) = '.*'
-- and starts_with(cap, left(c.key, length(c.key)-1))`) plus the
-- is_platform_owner OR; re-expressing that in a single IN-list would be a
-- second implementation of the authorization rule that could drift from the
-- first. One call per key keeps exactly one definition of "has".
--
-- Fails closed on every degenerate input: null array, empty array, and an
-- array of keys nobody holds all return false.
create or replace function app.has_any_capability(p_caps text[], p_org uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_cap text;
begin
  if p_caps is null or array_length(p_caps, 1) is null or p_org is null then
    return false;
  end if;

  foreach v_cap in array p_caps loop
    if app.has_capability(v_cap, p_org) then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

comment on function app.has_any_capability(text[], uuid) is
  'True if the current user holds ANY of the given capabilities in the given organization. Calls app.has_capability once per key, so the wildcard expansion and the is_platform_owner branch have exactly one definition and cannot drift. Fails closed on a null or empty array.';

-- ============================================================================
-- 2. app.resolve_landing_flags -- both answers, every organization, one call
-- ============================================================================
-- Returns the two booleans lib/landing.ts needs, computed across ALL of the
-- caller's organizations, which is what lets the app drop its own
-- user_org_roles lookup as well as the per-capability round trips.
--
-- TAKES NO USER PARAMETER, and that is the security property that matters:
-- it is SECURITY DEFINER, so a user id argument would let any signed-in caller
-- ask where somebody else lands and, worse, probe another person's
-- capabilities one array at a time. The subject is always
-- app.current_user_id(). With no session that is null, no organization
-- matches, both answers come back false, and the app sends the caller to
-- /profile -- the fail-closed direction.
--
-- SECURITY DEFINER is also what makes the membership read independent of
-- user_org_roles' own policy, so this function cannot be silently narrowed to
-- "no organizations" by a future policy change on that table.
create or replace function app.resolve_landing_flags(p_mywork_cap text, p_beyond_caps text[])
returns table (has_mywork boolean, has_beyond boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_mywork boolean := false;
  v_beyond boolean := false;
begin
  for v_org in
    select distinct uor.organization_id
    from public.user_org_roles uor
    where uor.user_id = app.current_user_id()
  loop
    if not v_mywork and app.has_capability(p_mywork_cap, v_org) then
      v_mywork := true;
    end if;
    if not v_beyond and app.has_any_capability(p_beyond_caps, v_org) then
      v_beyond := true;
    end if;
    -- Both known: nothing a further organization could change.
    exit when v_mywork and v_beyond;
  end loop;

  has_mywork := v_mywork;
  has_beyond := v_beyond;
  return next;
end;
$$;

comment on function app.resolve_landing_flags(text, text[]) is
  'The two facts lib/landing.ts needs -- does the caller hold the "my own work" capability, and do they hold any capability that implies a screen beyond it -- across every organization they belong to, in one round trip. The CAPABILITY LIST IS PASSED IN, not duplicated here: lib/landing.ts holds the definition (BEYOND_OWN_WORK_CAPABILITIES) next to the comment explaining it must grow when a nav group is added. Subject is always app.current_user_id(); there is deliberately no user parameter on a SECURITY DEFINER function.';

grant execute on function app.has_any_capability(text[], uuid) to authenticated;
grant execute on function app.resolve_landing_flags(text, text[]) to authenticated;

-- ============================================================================
-- PostgREST wrappers -- schema `app` is not exposed via the Data API.
-- Same shape as 202609220002 and public.has_capability before it.
-- ============================================================================
create or replace function public.has_any_capability(caps text[], org uuid)
returns boolean language sql stable security invoker set search_path = ''
as $$ select app.has_any_capability(caps, org); $$;
comment on function public.has_any_capability(text[], uuid) is
  'PostgREST-exposed wrapper around app.has_any_capability(). SECURITY INVOKER, forwarding only -- the underlying function is already SECURITY DEFINER.';
revoke all on function public.has_any_capability(text[], uuid) from public;
grant execute on function public.has_any_capability(text[], uuid) to authenticated;

create or replace function public.resolve_landing_flags(p_mywork_cap text, p_beyond_caps text[])
returns table (has_mywork boolean, has_beyond boolean)
language sql stable security invoker set search_path = ''
as $$ select * from app.resolve_landing_flags(p_mywork_cap, p_beyond_caps); $$;
comment on function public.resolve_landing_flags(text, text[]) is
  'PostgREST-exposed wrapper around app.resolve_landing_flags(). SECURITY INVOKER, forwarding only.';
revoke all on function public.resolve_landing_flags(text, text[]) from public;
grant execute on function public.resolve_landing_flags(text, text[]) to authenticated;
