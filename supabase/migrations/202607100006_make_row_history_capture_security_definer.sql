-- 202607100006_make_row_history_capture_security_definer.sql
-- WOW LAB OS, WS-D · D1b follow-up: row_history_capture() must be
-- SECURITY DEFINER.
--
-- Found while verifying D1b (202607100004): the function was SECURITY
-- INVOKER, so the trigger ran with the CALLING role's own privileges. Per
-- D1b's explicit design, `authenticated` has no INSERT grant on
-- row_history ("seed/service-role/trigger only") — but because the trigger
-- itself is the sanctioned writer and had no elevated privilege of its own,
-- any authenticated user's otherwise policy-permitted UPDATE on an audited
-- table (org_settings, user_org_roles, legal_entities, file_refs) failed
-- with "permission denied for table row_history" the moment the trigger
-- fired. This is the standard reason audit-trigger functions are written
-- SECURITY DEFINER: the trigger's own internal insert needs to work
-- regardless of the invoking user's grants, while the triggering
-- statement itself still goes through the invoking user's normal RLS/grant
-- checks beforehand — this change does not widen access to the audited
-- tables themselves, only to the trigger's own row_history write.
--
-- set search_path = '' matches the convention already used for the app.*
-- SECURITY DEFINER helpers (202607090001); the one table reference here
-- was already schema-qualified (public.row_history), so this is a
-- defensive hardening, not a behavior change.
--
-- Idempotent: CREATE OR REPLACE FUNCTION, identical body to
-- 202607100001 plus the security definer + search_path clauses.

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
  return new;
end;
$$;

comment on function public.row_history_capture() is 'Use on audited tables: create trigger foo_row_history before update or delete on <table> for each row execute function public.row_history_capture(). organization_id is denormalized from the captured row''s jsonb (new_values on INSERT/UPDATE, old_values on DELETE); NULL if the table has no organization_id column. SECURITY DEFINER so the trigger''s own row_history insert works regardless of the invoking (e.g. authenticated) role''s own grants.';
