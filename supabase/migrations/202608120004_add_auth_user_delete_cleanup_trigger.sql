-- 202608120004_add_auth_user_delete_cleanup_trigger.sql
-- WOW LAB OS: fixes the root cause behind two confirmed-orphaned rows
-- (test+invite-with-073557@wowlab.dev, test+invite-without-073557@wowlab.dev)
-- — admin.auth.admin.deleteUser() removed their auth.users row but left
-- public.users/user_org_roles behind, silently, because public.users.id
-- has NO foreign key to auth.users.id at all (confirmed: `create table
-- public.users (id uuid primary key, ...)`, 202607080002 — a bare PK, not
-- a reference).
--
-- Investigated before assuming a straight FK: a plain
-- `public.users.id references auth.users(id) on delete cascade` is not
-- viable. Many existing public.users rows (the C1 SQL-only test fixtures,
-- e.g. test+catalina, test+owner-a) were deliberately seeded with no
-- matching auth.users row at all — adding that FK would fail validation
-- against current data. More importantly, even if it existed, Postgres
-- would still have to cascade FURTHER into whatever references
-- public.users.id, and pg_constraint shows five such FKs, all currently
-- NO ACTION:
--   user_org_roles.user_id, user_org_roles.assigned_by,
--   audit_log.actor_user_id, row_history.actor_user_id,
--   file_refs.uploaded_by
-- A blind CASCADE through those would try to hard-DELETE audit_log and
-- row_history rows -- which is wrong twice over: it would erase audit
-- history that should survive the actor's account being removed, and
-- audit_log's own append-only trigger (prevent_audit_log_modification,
-- 202607080003) would actively BLOCK the cascade's DELETE anyway, failing
-- the whole transaction.
--
-- So: a trigger, not a bare FK cascade, mirroring on_auth_user_created's
-- own AFTER-trigger-on-auth.users pattern (202607130004) and applying the
-- correct rule per referencing table:
--   - user_org_roles.user_id: DELETE -- this user's own memberships
--     genuinely no longer exist once their identity is gone.
--   - user_org_roles.assigned_by, audit_log.actor_user_id,
--     row_history.actor_user_id, file_refs.uploaded_by: SET NULL --
--     these are audit/provenance trails; the row they're on should
--     survive, only the now-dangling actor reference is cleared.
-- SECURITY DEFINER for the same reason handle_new_auth_user() is: it
-- fires under auth's own internal role, which has no grant on any of
-- these public tables' deny-by-default RLS.

create or replace function public.handle_deleted_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.audit_log set actor_user_id = null where actor_user_id = old.id;
  update public.row_history set actor_user_id = null where actor_user_id = old.id;
  update public.user_org_roles set assigned_by = null where assigned_by = old.id;
  update public.file_refs set uploaded_by = null where uploaded_by = old.id;
  delete from public.user_org_roles where user_id = old.id;
  delete from public.users where id = old.id;
  return old;
end;
$$;

comment on function public.handle_deleted_auth_user() is 'Cleans up public.users/user_org_roles when Supabase Auth deletes an auth.users row (e.g. admin.auth.admin.deleteUser()) -- public.users.id has no FK to auth.users.id (deliberately: some rows are SQL-only test fixtures with no auth identity), so nothing would otherwise catch this. Nulls out (never deletes) actor/uploader references on audit_log/row_history/file_refs/user_org_roles.assigned_by to preserve those trails -- only this user''s own user_org_roles rows and their public.users row are actually removed.';

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_schema = 'auth'
      and event_object_table = 'users'
      and trigger_name = 'on_auth_user_deleted'
  ) then
    create trigger on_auth_user_deleted
      after delete on auth.users
      for each row execute function public.handle_deleted_auth_user();
  end if;
end;
$$;
