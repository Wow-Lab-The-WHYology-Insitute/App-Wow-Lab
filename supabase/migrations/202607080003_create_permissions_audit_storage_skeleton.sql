-- 202607080003_create_permissions_audit_storage_skeleton.sql
-- Permission reference + audit + storage skeleton for WOW LAB OS.
-- Idempotent: creates tables if missing and alters existing tables non-destructively.
-- RLS is enabled deny-by-default on all tables.

-- Ensure roles table has the target reference fields.
alter table public.roles add column if not exists key text;
alter table public.roles add column if not exists display_name text;
alter table public.roles add column if not exists is_system boolean not null default false;

update public.roles
set key = lower(regexp_replace(name, '[^a-z0-9_]+', '_', 'gi'))
where key is null;

update public.roles
set display_name = name
where display_name is null;

alter table public.roles alter column key set not null;
alter table public.roles alter column display_name set not null;

create unique index if not exists roles_key_key on public.roles(key);

-- Permission reference tables.
create table if not exists public.capabilities (
  id uuid primary key default gen_random_uuid(),
  key text not null,
  domain text not null,
  resource text not null,
  action text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists capabilities_key_key on public.capabilities(key);

create table if not exists public.role_capabilities (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references public.roles(id),
  capability_id uuid not null references public.capabilities(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists role_capabilities_role_capability_key on public.role_capabilities(role_id, capability_id);

comment on table public.capabilities is 'Global capability reference table; not organization-scoped.';
comment on table public.role_capabilities is 'Capability map between roles and capabilities; not organization-scoped.';

-- Audit and storage skeleton.
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id),
  actor_user_id uuid references public.users(id),
  event_type text not null,
  target_table text not null,
  target_id uuid,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.row_history (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  row_id uuid,
  actor_user_id uuid references public.users(id),
  old_values jsonb,
  new_values jsonb,
  changed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.file_refs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  storage_path text not null,
  mime_type text not null,
  byte_size bigint not null,
  uploaded_by uuid references public.users(id),
  gdpr_class text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.audit_log is 'Append-only business event log; no UPDATE or DELETE allowed from any role.';
comment on table public.row_history is 'Generic history log for audited tables. Attach with a before update/delete trigger.';
comment on table public.file_refs is 'EU storage file references supporting AD-7 split storage.';

-- Reusable row history trigger function.
create or replace function public.row_history_capture()
returns trigger
language plpgsql
as $$
begin
  insert into public.row_history (
    id,
    table_name,
    row_id,
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

comment on function public.row_history_capture() is 'Use on audited tables: create trigger foo_row_history before update or delete on <table> for each row execute function public.row_history_capture();';

-- Append-only enforcement for audit_log.
create or replace function public.prevent_audit_log_modification()
returns trigger
language plpgsql
as $$
begin
  raise exception 'audit_log is append-only';
end;
$$;

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'audit_log'
      and trigger_name = 'audit_log_prevent_modification'
  ) then
    create trigger audit_log_prevent_modification
      before update or delete on public.audit_log
      for each row execute function public.prevent_audit_log_modification();
  end if;
end;
$$;

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'user_org_roles'
      and trigger_name = 'user_org_roles_row_history'
  ) then
    create trigger user_org_roles_row_history
      before update or delete on public.user_org_roles
      for each row execute function public.row_history_capture();
  end if;
end;
$$;

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'org_settings'
      and trigger_name = 'org_settings_row_history'
  ) then
    create trigger org_settings_row_history
      before update or delete on public.org_settings
      for each row execute function public.row_history_capture();
  end if;
end;
$$;

-- Updated_at triggers for new tables.
DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'capabilities'
      and trigger_name = 'capabilities_set_updated_at'
  ) then
    create trigger capabilities_set_updated_at
      before update on public.capabilities
      for each row execute function public.trigger_set_updated_at();
  end if;
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'role_capabilities'
      and trigger_name = 'role_capabilities_set_updated_at'
  ) then
    create trigger role_capabilities_set_updated_at
      before update on public.role_capabilities
      for each row execute function public.trigger_set_updated_at();
  end if;
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'audit_log'
      and trigger_name = 'audit_log_set_updated_at'
  ) then
    create trigger audit_log_set_updated_at
      before update on public.audit_log
      for each row execute function public.trigger_set_updated_at();
  end if;
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'row_history'
      and trigger_name = 'row_history_set_updated_at'
  ) then
    create trigger row_history_set_updated_at
      before update on public.row_history
      for each row execute function public.trigger_set_updated_at();
  end if;
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'file_refs'
      and trigger_name = 'file_refs_set_updated_at'
  ) then
    create trigger file_refs_set_updated_at
      before update on public.file_refs
      for each row execute function public.trigger_set_updated_at();
  end if;
end;
$$;

-- Enable deny-by-default RLS on all tables.
alter table public.roles enable row level security;
alter table public.roles force row level security;

alter table public.capabilities enable row level security;
alter table public.capabilities force row level security;

alter table public.role_capabilities enable row level security;
alter table public.role_capabilities force row level security;

alter table public.audit_log enable row level security;
alter table public.audit_log force row level security;

alter table public.row_history enable row level security;
alter table public.row_history force row level security;

alter table public.file_refs enable row level security;
alter table public.file_refs force row level security;

-- Read-only policy for authenticated users on global reference tables.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'roles' and policyname = 'authenticated select roles'
  ) then
    create policy "authenticated select roles" on public.roles
      for select
      using (auth.role() = 'authenticated');
  end if;
end;
$$;

DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'capabilities' and policyname = 'authenticated select capabilities'
  ) then
    create policy "authenticated select capabilities" on public.capabilities
      for select
      using (auth.role() = 'authenticated');
  end if;
end;
$$;

DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'role_capabilities' and policyname = 'authenticated select role_capabilities'
  ) then
    create policy "authenticated select role_capabilities" on public.role_capabilities
      for select
      using (auth.role() = 'authenticated');
  end if;
end;
$$;
