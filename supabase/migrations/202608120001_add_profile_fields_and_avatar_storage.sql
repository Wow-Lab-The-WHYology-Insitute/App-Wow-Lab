-- 202608120001_add_profile_fields_and_avatar_storage.sql
-- WOW LAB OS: profile fields (first_name, last_name, phone) + avatar
-- upload infrastructure, on top of the existing users table.
--
-- Investigation (step 0, done before writing this): public.users row
-- creation relative to invite is SYNCHRONOUS, not deferred. Confirmed live
-- against this database's actual trigger (not just the migration file):
--   select trigger_name, action_timing, event_manipulation, action_statement
--   from information_schema.triggers
--   where event_object_schema = 'auth' and event_object_table = 'users';
-- -> on_auth_user_created, AFTER INSERT, EXECUTE FUNCTION
--    handle_new_auth_user() (202607130004). That trigger function inserts
-- the matching public.users row synchronously, in the same transaction as
-- auth.users' own insert -- Postgres AFTER INSERT triggers always run
-- before the triggering statement (and therefore the whole transaction)
-- commits. admin.auth.admin.inviteUserByEmail() performs that auth.users
-- insert server-side and only returns once it's done, so by the time our
-- Next.js inviteUser() server action has `data.user.id` in hand, the
-- public.users row already exists. Conclusion: first_name/last_name/phone
-- entered AT INVITE TIME can be written with a normal UPDATE in the same
-- server action, right after the invite call -- no deferral to first
-- login/confirmation is needed.
--
-- No new table-level RLS policy is needed for these columns: the existing
-- "authenticated update users" policy (WS-D) already allows
-- `id = app.current_user_id()` self-update (checked live via pg_policies
-- before writing this), which is exactly the self-service model the
-- profile edit and name/phone fields need.
--
-- avatar_url stores a Storage PATH within the new `avatars` bucket
-- (e.g. '<user_id>/avatar'), never raw bytes -- resolved to a short-lived
-- signed URL at render time (see app code), not a public URL. See the
-- storage.objects policies below for why: the access model is
-- "authenticated org members can read any avatar, but only the owner can
-- write/replace/delete their own" -- a public bucket would make avatars
-- readable by anyone with the link, forever, with no auth at all, which
-- doesn't match that model.

alter table public.users
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists phone text,
  add column if not exists avatar_url text;

comment on column public.users.first_name is 'Optional. Separate from full_name (kept for backward compat with the invite-time trigger default) -- not backfilled from it.';
comment on column public.users.last_name is 'Optional.';
comment on column public.users.phone is 'Optional, free-text (no format constraint -- international formats vary).';
comment on column public.users.avatar_url is 'Storage PATH within the private `avatars` bucket (e.g. "<user_id>/avatar"), NOT a public URL and NOT raw bytes. Resolve to a signed URL at render time via storage.from(''avatars'').createSignedUrl(). Null means no avatar set.';

-- Avatar bucket: private (public = false) -- see comment above on why a
-- public bucket doesn't match the required access model. Idempotent
-- upsert so this migration can be re-run safely.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Object path convention: '<user_id>/avatar' (fixed filename, no
-- extension -- Storage serves the correct Content-Type from the upload's
-- own contentType regardless of filename, and a fixed path means
-- "replace" is a plain upsert, never accumulating orphaned old files).
-- storage.foldername(name) splits that path into folder segments, so
-- (storage.foldername(name))[1] is the owning user_id.

drop policy if exists "avatars authenticated read" on storage.objects;
create policy "avatars authenticated read" on storage.objects
  for select
  to authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars owner insert" on storage.objects;
create policy "avatars owner insert" on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = app.current_user_id()::text
  );

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update" on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = app.current_user_id()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = app.current_user_id()::text
  );

drop policy if exists "avatars owner delete" on storage.objects;
create policy "avatars owner delete" on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = app.current_user_id()::text
  );
