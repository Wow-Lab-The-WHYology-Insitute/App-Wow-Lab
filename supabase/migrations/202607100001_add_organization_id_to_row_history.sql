-- 202607100001_add_organization_id_to_row_history.sql
-- WOW LAB OS, WS-D prep: denormalize organization_id onto row_history at capture
-- time, so org admins can eventually be scoped to their own org's audit history
-- (resolves the open question in docs/ws-d-d1-mapping.md, "row_history" section,
-- Open Question #4). Idempotent; row_history is empty, so no backfill is needed.

alter table public.row_history add column if not exists organization_id uuid;

comment on column public.row_history.organization_id is 'Denormalized from the captured row at trigger time (see row_history_capture()); NULL when the audited table has no organization_id column.';

create index if not exists row_history_organization_id_idx on public.row_history(organization_id);

-- Generic capture, extended to also denormalize organization_id: pulled from the
-- captured row's jsonb (new_values on INSERT/UPDATE, old_values on DELETE). Works
-- for any audited table; stays NULL if that table has no organization_id column.
-- old_values/new_values/actor capture behavior is unchanged from the original
-- version in 202607080003_create_permissions_audit_storage_skeleton.sql.
create or replace function public.row_history_capture()
returns trigger
language plpgsql
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

comment on function public.row_history_capture() is 'Use on audited tables: create trigger foo_row_history before update or delete on <table> for each row execute function public.row_history_capture(). organization_id is denormalized from the captured row''s jsonb (new_values on INSERT/UPDATE, old_values on DELETE); NULL if the table has no organization_id column.';
