-- 202608300001_suppliers.sql
-- suppliers -- step 2 of docs/WOWLAB_SAD_Contracte_Trainer_Furnizor.md
-- Sec10 (Sec3.1 for the table spec). The counterparty for supplier
-- contracts (step 4) -- without it, a contract with "the SEO firm" has
-- nothing to reference.

create table public.suppliers (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id),
  name              text not null,
  legal_name        text,
  cui               text,
  service_type      text,
  status            text not null default 'active',
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint suppliers_status_check check (status in ('active', 'inactive'))
);

-- status = 'inactive' replaces hard delete, same convention as clients
-- (DATABASE_CONVENTIONS.md Sec12, cited directly in the SAD Sec3.1: "un
-- furnizor cu contracte în istoric nu se șterge"). No DELETE policy, no
-- DELETE grant, below.

create trigger suppliers_row_history
  before delete or update on public.suppliers
  for each row execute function row_history_capture();

create trigger suppliers_set_updated_at
  before update on public.suppliers
  for each row execute function trigger_set_updated_at();

alter table public.suppliers enable row level security;

-- One predicate, all three verbs -- confirmed live before writing this,
-- not assumed: finance.reporting.* is held today by exactly
-- finance_admin_reporting (Anka), organization_owner (Anca), and
-- platform_owner, and by no one else -- the identical set SAD Sec7.2 asks
-- for on suppliers. contracts.* was rejected (contract_administrator also
-- holds it, and the SAD gives contract_administrator nothing here).
-- org.settings.manage was deliberately dropped from this predicate --
-- it's the organization-settings capability, not a business-data key, and
-- carrying it forward from clients/contracts onto a new table would just
-- be inherited noise. Confirmed live: organization_owner holds
-- finance.reporting.* directly (not only reachable via the
-- is_platform_owner() bypass), so the two-branch predicate below is
-- complete -- no third branch needed for org.settings.manage or for Anca
-- specifically.
--
-- grants.* matches the same three roles today too, and was rejected on
-- purpose -- see the SAD Sec7.2 update for why (coincidence of role, not
-- of domain; would break silently the day the two capabilities diverge).
create policy "authenticated select suppliers" on public.suppliers
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated insert suppliers" on public.suppliers
  for insert
  to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated update suppliers" on public.suppliers
  for update
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  )
  with check (
    app.is_platform_owner()
    or app.has_capability('finance.reporting.*', organization_id)
  );

grant select, insert, update on public.suppliers to authenticated;

-- No field masking: confirmed against the SAD Sec3.1 column list --
-- name/legal_name/cui/service_type/status/notes, no financial value
-- anywhere on this table. The money lives on supplier_contracts.
-- contract_value (step 4), masked there, not here.
