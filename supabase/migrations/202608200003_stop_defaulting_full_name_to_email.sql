-- 202608200003_stop_defaulting_full_name_to_email.sql
-- Fixes the actual source of what 202608200002 only patched around:
-- handle_new_auth_user defaults full_name to the invited email whenever no
-- name is supplied at invite time (every invite today, per the invite path
-- fix landing alongside this — inviteUserByEmail was never passing any
-- metadata). That default walks straight past the users field-masking
-- work about to start (docs/WOWLAB_SAD_Field_Masking.md §2.3): full_name
-- gets an explicit GRANT there, email is restricted -- a raw email sitting
-- in full_name is the same value, reachable through an unrestricted
-- column, regardless of what the masking view does.
--
-- full_name must become nullable for "leave it NULL" to be possible at
-- all -- it has been `not null` since the original schema
-- (202607080002). Dropping that constraint is a required part of this
-- fix, not an incidental one.
alter table public.users alter column full_name drop not null;

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
    new.raw_user_meta_data ->> 'full_name',
    'invited',
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
