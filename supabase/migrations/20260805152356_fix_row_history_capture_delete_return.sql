-- 20260805152356_fix_row_history_capture_delete_return.sql
-- WOW LAB OS: row_history_capture() must return OLD on DELETE.
--
-- Found while verifying the /admin/users mobile-responsive task (2026-08-05):
-- the function unconditionally did `return new;`. On a BEFORE DELETE trigger,
-- NEW is always NULL — and in Postgres, a BEFORE trigger that returns NULL
-- silently skips the operation for that row. So every DELETE on the 4
-- audited tables (org_settings, user_org_roles, legal_entities, file_refs)
-- has been silently no-op'd since this trigger existed: the calling code
-- sees no error, but the row is never actually removed. Reproduced live via
-- direct PostgREST calls (DELETE responds 200 with 0 rows affected; a
-- follow-up SELECT with the identical filter still returns the row).
--
-- Fix: return OLD on DELETE, NEW otherwise — the standard pattern for a
-- single trigger function shared across INSERT/UPDATE/DELETE.
--
-- Idempotent: CREATE OR REPLACE FUNCTION, identical body to
-- 202607100006 except the final return statement.

create or replace function public.row_history_capture()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  captured jsonb;
begin
  captured := case
    when TG_OP = 'DELETE' then row_to_json(old)::jsonb
    else row_to_json(new)::jsonb
  end;

  insert into public.row_history (
    id,
    table_name,
    row_id,
    organization_id,
    actor_user_id,
    old_values,
    new_values,
    changed_at,
    created_at,
    updated_at
  ) values (
    gen_random_uuid(),
    tg_table_name,
    coalesce(old.id, new.id),
    nullif(captured ->> 'organization_id', '')::uuid,
    nullif(current_setting('app.current_user_id', true), '')::uuid,
    row_to_json(old)::jsonb,
    case when new is null then null else row_to_json(new)::jsonb end,
    now(),
    now(),
    now()
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$$;

comment on function public.row_history_capture() is 'Use on audited tables: create trigger foo_row_history before update or delete on <table> for each row execute function public.row_history_capture(). organization_id is denormalized from the captured row''s jsonb (new_values on INSERT/UPDATE, old_values on DELETE); NULL if the table has no organization_id column. SECURITY DEFINER so the trigger''s own row_history insert works regardless of the invoking (e.g. authenticated) role''s own grants. Returns OLD on DELETE (NEW is always NULL there) and NEW otherwise, so a BEFORE DELETE trigger never silently cancels the delete.';
