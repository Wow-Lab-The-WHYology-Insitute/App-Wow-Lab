-- 0002_create_tenancy_identity_core_tables.sql
-- Core tenancy + identity tables for WOW LAB OS.
-- RLS is enabled on every table. No permissive policies are created in this migration.

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_test boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.organizations is 'Tenant anchor table; no organization_id column.';

create table public.legal_entities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  name text not null,
  registration_number text,
  entity_type text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.legal_entities is 'AUDITED: sensitive legal/billing container data; row-history required.';

create table public.users (
  id uuid primary key,
  email text not null unique,
  full_name text not null,
  status text not null default 'invited',
  is_platform_owner boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.users is 'Platform identity table; auth user id is the primary key.';

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.roles is 'Global reference table for configurable roles; not organization-scoped.';

create table public.user_org_roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  user_id uuid not null references public.users(id),
  role_id uuid not null references public.roles(id),
  assigned_by uuid references public.users(id),
  assigned_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_org_roles_unique_organization_user_role unique (organization_id, user_id, role_id)
);

comment on table public.user_org_roles is 'AUDITED: most security-sensitive membership table; row-history required.';

create table public.org_settings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) unique,
  evaluations_confidential boolean not null default true,
  settings jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.org_settings is 'AUDITED: organization configuration; row-history required.';

create trigger organizations_set_updated_at
  before update on public.organizations
  for each row execute function public.trigger_set_updated_at();

create trigger legal_entities_set_updated_at
  before update on public.legal_entities
  for each row execute function public.trigger_set_updated_at();

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.trigger_set_updated_at();

create trigger roles_set_updated_at
  before update on public.roles
  for each row execute function public.trigger_set_updated_at();

create trigger user_org_roles_set_updated_at
  before update on public.user_org_roles
  for each row execute function public.trigger_set_updated_at();

create trigger org_settings_set_updated_at
  before update on public.org_settings
  for each row execute function public.trigger_set_updated_at();

alter table public.organizations enable row level security;
alter table public.organizations force row level security;

alter table public.legal_entities enable row level security;
alter table public.legal_entities force row level security;

alter table public.users enable row level security;
alter table public.users force row level security;

alter table public.roles enable row level security;
alter table public.roles force row level security;

alter table public.user_org_roles enable row level security;
alter table public.user_org_roles force row level security;

alter table public.org_settings enable row level security;
alter table public.org_settings force row level security;
