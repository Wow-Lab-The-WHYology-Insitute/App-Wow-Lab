-- 202608100001_create_clients_contracts_domain_tables.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1).
-- Source: docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md, §4.
--
-- Creates clients, client_contacts, contracts. Per DATABASE_CONVENTIONS.md:
-- uuid pk, organization_id tenancy anchor, snake_case plural table names,
-- created_at/updated_at + trigger_set_updated_at, RLS enabled+forced with
-- NO policies yet (deny-by-default — policies land in migration 0003).
--
-- Enum-shaped columns (client_type, status, contract_type) are `text` with a
-- CHECK constraint, matching the existing style in this codebase
-- (organizations.status, users.status are plain text, not native Postgres
-- enum types) rather than introducing a new column-type pattern.
--
-- Idempotent: `create table if not exists`, triggers/RLS/indexes guarded the
-- same way as 202607080003.

-- ============================================================================
-- clients — the client account (AD-2: belongs to the organization, not a
-- legal entity — billing entity is decided per-contract via legal_entity_id).
-- ============================================================================
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  name text not null,
  client_type text not null check (client_type in ('private_school', 'state_school', 'corporate', 'parent_b2c', 'special_project')),
  business_line text,
  status text not null default 'prospect' check (status in ('prospect', 'active', 'paused', 'churned')),
  external_crm_ref text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.clients is 'AUDITED: client account (AD-15 handoff point from ActiveCampaign at "Won"). external_crm_ref links back to the AC contact/deal id but is NOT wired to a live webhook yet (separate future spec, see SAD §2/§9). Record-level RLS segregates finance_operations (private_school) from finance_admin_reporting (corporate/state_school/special_project) — see migration 0003.';
comment on column public.clients.client_type is 'Drives record-level RLS segregation for Finance Operations vs Finance Admin & Reporting (SAD §6).';
comment on column public.clients.external_crm_ref is 'ActiveCampaign contact/deal id. Field only — the AC webhook integration is a separate future spec (SAD §9, "Următorii pași" #2), not built here.';

create index if not exists clients_organization_id_idx on public.clients(organization_id);
create index if not exists clients_client_type_idx on public.clients(client_type);

-- ============================================================================
-- client_contacts — contract/billing contacts at the client (distinct from
-- ActiveCampaign's marketing contacts, per SAD §2 — intentionally not forced
-- to match).
-- ============================================================================
create table if not exists public.client_contacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  client_id uuid not null references public.clients(id),
  full_name text not null,
  role_at_client text,
  email text,
  phone text,
  is_billing_contact boolean not null default false,
  is_primary boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.client_contacts is 'AUDITED, PII. GDPR anonymization-at-36-months (DATABASE_CONVENTIONS.md #9 / B1 standing rule) applies to this table once the anonymization job is built — not built in this migration, only flagged so nothing here contradicts it later.';

create index if not exists client_contacts_organization_id_idx on public.client_contacts(organization_id);
create index if not exists client_contacts_client_id_idx on public.client_contacts(client_id);

-- ============================================================================
-- contracts — the contract lifecycle. billing_rule lives here (not on
-- clients) — field-level masking is applied via a view in migration 0004.
-- ============================================================================
create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  client_id uuid not null references public.clients(id),
  legal_entity_id uuid not null references public.legal_entities(id),
  contract_number text not null,
  contract_type text not null check (contract_type in ('recurring_annual', 'one_off_event', 'framework')),
  period_start date,
  period_end date,
  status text not null default 'draft' check (status in ('draft', 'sent', 'signed', 'expired', 'renewed')),
  renewal_of uuid references public.contracts(id),
  billing_rule text,
  drive_ref text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint contracts_unique_organization_contract_number unique (organization_id, contract_number)
);

comment on table public.contracts is 'AUDITED. legal_entity_id decides the billing entity (Experimente Wow / Bradine ADV / STEMplicity), independent of which org the client belongs to (AD-2). billing_rule is field-masked for non-finance callers — see public.contracts_billing_masked (migration 0004). Record-level RLS segregates finance_operations (private_school-linked clients) from finance_admin_reporting (everything else) via a join to clients.client_type — see migration 0003.';
comment on column public.contracts.billing_rule is 'PLAIN TEXT ON THE BASE TABLE — masking is enforced by public.contracts_billing_masked (a SECURITY INVOKER view), not a table/column-level grant. Any query against this base table directly, bypassing the view, sees the real value if it has SELECT access to the row at all. App code for non-finance/non-master roles must read the view, not this table, per SAD §6.';

create index if not exists contracts_organization_id_idx on public.contracts(organization_id);
create index if not exists contracts_client_id_idx on public.contracts(client_id);
create index if not exists contracts_legal_entity_id_idx on public.contracts(legal_entity_id);
create index if not exists contracts_renewal_of_idx on public.contracts(renewal_of);

-- ============================================================================
-- updated_at triggers (DATABASE_CONVENTIONS.md #4).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'clients' and trigger_name = 'clients_set_updated_at'
  ) then
    create trigger clients_set_updated_at
      before update on public.clients
      for each row execute function public.trigger_set_updated_at();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'client_contacts' and trigger_name = 'client_contacts_set_updated_at'
  ) then
    create trigger client_contacts_set_updated_at
      before update on public.client_contacts
      for each row execute function public.trigger_set_updated_at();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'contracts' and trigger_name = 'contracts_set_updated_at'
  ) then
    create trigger contracts_set_updated_at
      before update on public.contracts
      for each row execute function public.trigger_set_updated_at();
  end if;
end;
$$;

-- ============================================================================
-- row_history audit triggers (DATABASE_CONVENTIONS.md #8: BEFORE UPDATE OR
-- DELETE — NOT insert; matches every existing audited table exactly. INSERT
-- has no prior state to diff, so the convention never captures it. See the
-- final report for this explicit deviation from the task's literal
-- "INSERT/UPDATE" wording in favor of the established, already-reviewed
-- convention.)
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'clients' and trigger_name = 'clients_row_history'
  ) then
    create trigger clients_row_history
      before update or delete on public.clients
      for each row execute function public.row_history_capture();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'client_contacts' and trigger_name = 'client_contacts_row_history'
  ) then
    create trigger client_contacts_row_history
      before update or delete on public.client_contacts
      for each row execute function public.row_history_capture();
  end if;

  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'contracts' and trigger_name = 'contracts_row_history'
  ) then
    create trigger contracts_row_history
      before update or delete on public.contracts
      for each row execute function public.row_history_capture();
  end if;
end;
$$;

-- ============================================================================
-- RLS: enabled + forced, deny-by-default. NO policies here (DATABASE_
-- CONVENTIONS.md #7) — policies land in 202608100003.
-- ============================================================================
alter table public.clients enable row level security;
alter table public.clients force row level security;

alter table public.client_contacts enable row level security;
alter table public.client_contacts force row level security;

alter table public.contracts enable row level security;
alter table public.contracts force row level security;
