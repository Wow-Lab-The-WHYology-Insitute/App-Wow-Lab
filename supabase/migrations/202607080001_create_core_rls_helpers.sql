-- 0001_create_core_rls_helpers.sql
-- Shared database infrastructure used by core tenancy and identity tables.

create extension if not exists pgcrypto;

create or replace function public.trigger_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
