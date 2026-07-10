-- 202607100008_harden_public_grants_ws_d.sql
-- WOW LAB OS, WS-D hardening: tighten the grant model to match our RLS
-- model. Supabase's own default-privileges setup gives anon/authenticated
-- (and service_role) TRUNCATE/REFERENCES/TRIGGER/MAINTAIN on every future
-- public-schema table, regardless of anything D1a/D1b granted — and
-- TRUNCATE in particular bypasses row-level security entirely (it isn't a
-- row-level operation, so no policy can gate it). Revoking it here doesn't
-- change any RLS behavior; it closes a path that was never subject to RLS
-- in the first place.
--
-- service_role and postgres are untouched throughout — service_role needs
-- full access, and postgres is the table owner.
--
-- Idempotent: REVOKE on a privilege not held is a no-op; ALTER DEFAULT
-- PRIVILEGES REVOKE against entries where the privilege is already absent
-- is likewise a no-op.

-- ============================================================================
-- 1. Existing tables: revoke on everything already in schema public.
-- ============================================================================

revoke truncate, references, trigger, delete on all tables in schema public from anon, authenticated;

-- ============================================================================
-- 2. Future tables: two separate default-privilege entries currently apply
-- to schema public tables, one per creating role — found via pg_default_acl:
--
--   FOR ROLE postgres:       anon/authenticated/service_role get
--                            TRUNCATE,REFERENCES,TRIGGER,MAINTAIN only.
--                            (This is the one every WOW LAB OS migration
--                            table has inherited so far, since migrations
--                            run as postgres — hence DELETE never actually
--                            showed up on any of our tables.)
--
--   FOR ROLE supabase_admin: anon/authenticated/service_role get ALL
--                            privileges (SELECT/INSERT/UPDATE/DELETE/
--                            TRUNCATE/REFERENCES/TRIGGER/MAINTAIN). Any
--                            future public table created as supabase_admin
--                            (some Supabase-managed paths do this, not just
--                            our own migrations) would silently inherit
--                            full anon/authenticated access, DELETE
--                            included. Both entries need the same fix, or
--                            this hardening only half-closes the gap.
--
-- Both are adjusted below, scoped to schema public only — no other schema
-- (storage/auth/graphql/realtime/extensions) is touched; those are
-- Supabase-managed and outside this project's tables.
-- ============================================================================

alter default privileges for role postgres in schema public
  revoke truncate, references, trigger, delete on tables from anon, authenticated;

-- The supabase_admin entry can only be altered by supabase_admin itself (or
-- a member/superuser); postgres is neither, so this is attempted and the
-- expected insufficient_privilege is caught rather than failing the whole
-- migration. This is reported as a known residual gap, not silently
-- swallowed: see docs/progress.md and the migration's own output.
do $$
begin
  begin
    execute 'alter default privileges for role supabase_admin in schema public revoke truncate, references, trigger, delete on tables from anon, authenticated';
    raise notice 'Adjusted supabase_admin''s default-privileges entry successfully.';
  exception
    when insufficient_privilege then
      raise notice 'SKIPPED: postgres lacks permission to alter supabase_admin''s default-privileges entry (insufficient_privilege). That entry still grants anon/authenticated ALL privileges (including DELETE/TRUNCATE) on any FUTURE public-schema table created as supabase_admin. Known residual gap — needs a supabase_admin-privileged session (e.g. Supabase support) to close.';
  end;
end $$;
