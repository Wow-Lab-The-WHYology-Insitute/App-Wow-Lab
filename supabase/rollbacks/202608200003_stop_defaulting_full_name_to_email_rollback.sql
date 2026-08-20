-- Rollback of 202608200003_stop_defaulting_full_name_to_email.sql.
--
-- Per the convention in docs/WOWLAB_SAD_Field_Masking.md §6.2: lives in
-- supabase/rollbacks/, not supabase/migrations/, so it can never be
-- auto-applied by a plain `supabase db push`. Applying it for real means
-- copying it into supabase/migrations/ with a fresh timestamp, pushing,
-- then moving it back out.
--
-- Ordering note: this assumes it is applied BEFORE
-- 202608200004_backfill_full_name.sql's rollback, i.e. rollbacks run in
-- the reverse of the order their forward migrations were applied in. If
-- that backfill has already run and left some rows with full_name IS
-- NULL, restoring `not null` below will fail until those rows are
-- resolved first (roll back 202608200004 first).
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

alter table public.users alter column full_name set not null;
