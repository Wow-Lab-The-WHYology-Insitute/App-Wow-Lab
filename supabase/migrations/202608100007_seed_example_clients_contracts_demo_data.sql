-- 202608100007_seed_example_clients_contracts_demo_data.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C2) — illustrative demo
-- records, so Anca has something real to look at (C1 shipped schema+RLS
-- with zero visible rows).
--
-- *** EXAMPLE DATA — NOT REAL CONTRACT TERMS ***
-- Client names (Lycée Français, IBSB, Cambridge School, King's Oak, Zitec)
-- are real public business names already used elsewhere in this project
-- (docs/mockup/wow_lab_os_mockup.html's CLIENTS array) — not personal data,
-- fine to seed. Contract numbers, dates, and billing_rule text below are
-- illustrative: the rate STRINGS are lifted from that same existing mockup
-- array for plausibility/consistency with prior project artifacts, but
-- neither the mockup data nor this seed has been verified against Anca's
-- actual current contracts — do not treat any of this as authoritative
-- billing terms. Contract numbers are prefixed DEMO- specifically so
-- nobody mistakes these for real invoiced contract numbers later.
--
-- This is demo/illustrative content, not required application data (unlike
-- supabase/seed.sql's roles/capabilities/test-user rows) — kept as its own
-- migration, not folded into seed.sql.
--
-- Idempotent: guarded by NOT EXISTS on (organization_id, name) for clients
-- (no unique constraint on that pair) and ON CONFLICT for contracts
-- (unique on (organization_id, contract_number), see 202608100001).

do $$
declare
  v_org_wow_lab uuid;
  v_entity_experimente_wow uuid;
  v_entity_bradine_adv uuid;
  v_client_lycee uuid;
  v_client_ibsb uuid;
  v_client_cambridge uuid;
  v_client_kings_oak uuid;
  v_client_zitec uuid;
begin
  select id into v_org_wow_lab from public.organizations where slug = 'wow-lab';
  select id into v_entity_experimente_wow from public.legal_entities where organization_id = v_org_wow_lab and name = 'Experimente Wow SRL';
  select id into v_entity_bradine_adv from public.legal_entities where organization_id = v_org_wow_lab and name = 'Bradine ADV SRL';

  -- Clients.
  if not exists (select 1 from public.clients where organization_id = v_org_wow_lab and name = 'Lycée Français') then
    insert into public.clients (organization_id, name, client_type, business_line, status)
    values (v_org_wow_lab, 'Lycée Français', 'private_school', 'Recurring', 'active')
    returning id into v_client_lycee;
  else
    select id into v_client_lycee from public.clients where organization_id = v_org_wow_lab and name = 'Lycée Français';
  end if;

  if not exists (select 1 from public.clients where organization_id = v_org_wow_lab and name = 'IBSB') then
    insert into public.clients (organization_id, name, client_type, business_line, status)
    values (v_org_wow_lab, 'IBSB', 'private_school', 'Recurring', 'active')
    returning id into v_client_ibsb;
  else
    select id into v_client_ibsb from public.clients where organization_id = v_org_wow_lab and name = 'IBSB';
  end if;

  if not exists (select 1 from public.clients where organization_id = v_org_wow_lab and name = 'Cambridge School') then
    insert into public.clients (organization_id, name, client_type, business_line, status)
    values (v_org_wow_lab, 'Cambridge School', 'private_school', 'Recurring', 'active')
    returning id into v_client_cambridge;
  else
    select id into v_client_cambridge from public.clients where organization_id = v_org_wow_lab and name = 'Cambridge School';
  end if;

  if not exists (select 1 from public.clients where organization_id = v_org_wow_lab and name = 'King''s Oak') then
    insert into public.clients (organization_id, name, client_type, business_line, status)
    values (v_org_wow_lab, 'King''s Oak', 'private_school', 'Recurring', 'active')
    returning id into v_client_kings_oak;
  else
    select id into v_client_kings_oak from public.clients where organization_id = v_org_wow_lab and name = 'King''s Oak';
  end if;

  if not exists (select 1 from public.clients where organization_id = v_org_wow_lab and name = 'Zitec') then
    insert into public.clients (organization_id, name, client_type, business_line, status)
    values (v_org_wow_lab, 'Zitec', 'corporate', 'Corporate party', 'active')
    returning id into v_client_zitec;
  else
    select id into v_client_zitec from public.clients where organization_id = v_org_wow_lab and name = 'Zitec';
  end if;

  -- Contract contacts (example, matching the mockup's own contract-contact
  -- distinction from AC marketing contacts — SAD §2).
  if not exists (select 1 from public.client_contacts where client_id = v_client_lycee and full_name = 'Vlad Rasnoveanu') then
    insert into public.client_contacts (organization_id, client_id, full_name, role_at_client, email, is_billing_contact, is_primary)
    values (v_org_wow_lab, v_client_lycee, 'Vlad Rasnoveanu', 'Head of Clubs', 'vlad.rasnoveanu@lyceefrancais.ro', true, true);
  end if;

  -- Contracts. DEMO- prefix + illustrative dates/rates, see header note.
  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_number, contract_type, period_start, period_end, status, billing_rule, notes)
  values
    (v_org_wow_lab, v_client_lycee, v_entity_experimente_wow, 'DEMO-2026-001', 'recurring_annual', '2025-09-01', '2026-06-30', 'signed', '95 lei / child / session (VAT incl.)', 'Example seed record — see migration header, not a verified real contract.'),
    (v_org_wow_lab, v_client_ibsb, v_entity_experimente_wow, 'DEMO-2026-002', 'recurring_annual', '2025-09-01', '2026-06-30', 'signed', '80 lei / child + VAT', 'Example seed record — see migration header, not a verified real contract.'),
    (v_org_wow_lab, v_client_cambridge, v_entity_experimente_wow, 'DEMO-2026-003', 'recurring_annual', '2025-09-01', '2026-06-30', 'draft', '950 lei / workshop + VAT · min 8', 'Example seed record — see migration header, not a verified real contract.'),
    (v_org_wow_lab, v_client_kings_oak, v_entity_experimente_wow, 'DEMO-2026-004', 'recurring_annual', '2025-09-01', '2026-06-30', 'signed', '450 lei / workshop (VAT incl.)', 'Example seed record — see migration header, not a verified real contract.'),
    (v_org_wow_lab, v_client_zitec, v_entity_bradine_adv, 'DEMO-2026-005', 'one_off_event', '2026-05-15', '2026-05-15', 'sent', 'event contract', 'Example seed record — see migration header, not a verified real contract.')
  on conflict (organization_id, contract_number) do nothing;
end $$;
