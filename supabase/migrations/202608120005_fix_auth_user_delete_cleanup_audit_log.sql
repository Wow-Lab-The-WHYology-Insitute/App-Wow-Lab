-- 202608120005_fix_auth_user_delete_cleanup_audit_log.sql
-- WOW LAB OS: fixes a real bug in 202608120004's cleanup trigger, found by
-- actually testing it (not assumed) immediately after applying it: it
-- tried `update public.audit_log set actor_user_id = null ...`, which
-- audit_log's own append-only trigger (prevent_audit_log_modification,
-- 202607080003) unconditionally blocks — ALL updates, not just updates to
-- some other "protected" column, exactly matching DATABASE_CONVENTIONS.md
-- §8 ("UPDATE and DELETE are denied for everyone, including Platform
-- Owner"). A raw SQL `delete from auth.users where id = ...` against the
-- live DB immediately surfaced this: `ERROR: P0001: audit_log is
-- append-only`, which rolled back the entire auth.users deletion, not
-- just the audit_log touch.
--
-- Confirmed via information_schema.triggers before writing this: neither
-- row_history nor file_refs nor user_org_roles has any similar
-- modification-blocking trigger (only row_history_capture, which just
-- records old/new values, and trigger_set_updated_at) -- audit_log is the
-- only genuinely immutable one. So the fix has two parts:
--   1. Drop the audit_log touch entirely -- it can never be nulled.
--   2. Wrap the final `delete from public.users` in an exception handler
--      for foreign_key_violation specifically: if this user was ever an
--      audit_log actor, that FK can never be cleared, so their
--      public.users row must survive (their auth identity is still gone;
--      only the identity row that the immutable audit trail needs to
--      stay resolvable remains) -- WITHOUT that being caught, the auth
--      user delete itself would keep failing/rolling back for anyone
--      with audit history, silently, which is worse than the small
--      number of rows this leaves in place.
-- Everything else from 202608120004 (row_history/file_refs/
-- user_org_roles.assigned_by SET NULL, this user's own user_org_roles
-- DELETE) was already correct and is unchanged.

create or replace function public.handle_deleted_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.row_history set actor_user_id = null where actor_user_id = old.id;
  update public.user_org_roles set assigned_by = null where assigned_by = old.id;
  update public.file_refs set uploaded_by = null where uploaded_by = old.id;
  delete from public.user_org_roles where user_id = old.id;

  begin
    delete from public.users where id = old.id;
  exception
    when foreign_key_violation then
      -- audit_log is append-only and can never be touched (see above) --
      -- if this user is still referenced there as an actor, their
      -- public.users row must survive so the audit trail stays
      -- resolvable. Not a bug, not silently swallowed data loss -- the
      -- auth.users row is still gone either way.
      null;
  end;

  return old;
end;
$$;
