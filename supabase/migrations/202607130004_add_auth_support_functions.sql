-- 202607130004_add_auth_support_functions.sql
-- WOW LAB OS, Next.js scaffolding S1 (auth): two pieces of DB-side support
-- for real Supabase Auth sessions, neither of which existed before now
-- (everything through WS-D was verified via SQL impersonation, never a
-- real logged-in session).
--
-- 1. public.has_capability(cap, org): a minimal, deliberate wrapper around
--    app.has_capability(). The `app` schema is intentionally NOT exposed via
--    the Data API (see its own comment in 202607090001) — PostgREST only
--    auto-generates RPC endpoints for functions in exposed schemas (public,
--    per supabase/config.toml [api] schemas), so the Next.js app has no way
--    to call app.has_capability() directly. This wrapper is the one
--    exception: SECURITY INVOKER (no elevation of its own — the underlying
--    app.has_capability() is already SECURITY DEFINER and does its own
--    privilege-checked reads), just forwarding the call so PostgREST can
--    expose it. Nothing else in `app` is exposed this way.
--
-- 2. public.handle_new_auth_user() + trigger on auth.users: until now, ALL
--    public.users rows were inserted directly by seed.sql with manually
--    generated ids — none of the 7 test users have a real auth.users
--    identity, so none of them could actually log in. Every real user from
--    now on (via admin.inviteUserByEmail, or eventually self-serve magic
--    link if that's ever enabled) is created in auth.users first; without
--    this trigger, that would leave an auth identity with no corresponding
--    public.users row, breaking every RLS policy and every capability
--    check that joins through public.users/user_org_roles. SECURITY
--    DEFINER because the trigger fires under auth's own internal role
--    (not postgres, not service_role), which has no grant on public.users
--    — same structural reason row_history_capture() needed it
--    (202607100006).

create or replace function public.has_capability(cap text, org uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select app.has_capability(cap, org);
$$;

comment on function public.has_capability(text, uuid) is 'Deliberate, minimal PostgREST-exposed wrapper around app.has_capability() (the app schema itself is not exposed via the Data API). SECURITY INVOKER — app.has_capability() is already SECURITY DEFINER and authenticated already holds EXECUTE on it directly (202607090001); this wrapper only exists to be reachable via .rpc() from the Next.js app.';

revoke all on function public.has_capability(text, uuid) from public;
grant execute on function public.has_capability(text, uuid) to authenticated, service_role;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, email, full_name, status, is_platform_owner)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
    'invited',
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

comment on function public.handle_new_auth_user() is 'Creates the matching public.users row whenever Supabase Auth creates an auth.users row (invite, magic link, etc.) — public.users has no direct INSERT grant for anyone but service_role, so without this every real signup would be an orphaned auth identity. on conflict (id) do nothing is an idempotency guard, not an expected path; a genuine email collision (e.g. re-inviting one of the manually-seeded test+*@wowlab.dev addresses, which already have a public.users row under a different id) will correctly surface as a unique-constraint error rather than silently overwriting an existing user''s id.';

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_schema = 'auth'
      and event_object_table = 'users'
      and trigger_name = 'on_auth_user_created'
  ) then
    create trigger on_auth_user_created
      after insert on auth.users
      for each row execute function public.handle_new_auth_user();
  end if;
end;
$$;
