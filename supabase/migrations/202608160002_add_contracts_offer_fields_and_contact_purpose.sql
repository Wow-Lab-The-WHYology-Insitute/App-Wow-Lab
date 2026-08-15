-- 202608160002_add_contracts_offer_fields_and_contact_purpose.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain — real gaps from Anca's
-- live-app feedback, same shape as the earlier tracker-fields migration
-- (202608110001): additive nullable columns, no backfill obligation.
--
-- contracts:
--   entry_number, exit_number — the school/client's own registry tracking
--     numbers for official correspondence on this contract (Romanian
--     institutional practice: "număr intrare/ieșire"), distinct from both
--     our contract_number and the client's client_contract_number.
--   offer_structure — which pricing MODEL this contract uses (not an
--     actual price, so unlike billing_rule/estimated_value it is NOT
--     financially sensitive and is not added to the masked view's unmask
--     condition — it's added as a plain passthrough column instead,
--     alongside contract_number/status/etc).
--   ac_link — manual URL to the corresponding ActiveCampaign record. No
--     automation, no validation beyond a plain text column -- matches
--     clients.external_crm_ref's existing "free text, app renders it as a
--     link when it looks like one" treatment rather than inventing a
--     stricter URL type.
--
-- client_contacts:
--   contact_purpose — Anca's explicit finding: a school's operational
--     contact, contract-signing contact, and billing contact are often 3
--     different people, not one. Distinct from the existing
--     is_billing_contact/is_primary booleans (which stay as-is, unrelated
--     concerns) -- this is a single-select classification of WHICH kind of
--     contact this person is for the client, not a fourth boolean flag.
--
-- Idempotent: `add column if not exists`, CHECK constraints guarded the
-- same way other enum-shaped text columns in this codebase already are
-- (module/delivery_format/status, etc — text + CHECK, not a native enum).

alter table public.contracts
  add column if not exists entry_number text,
  add column if not exists exit_number text,
  add column if not exists offer_structure text,
  add column if not exists ac_link text;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'contracts_offer_structure_check'
  ) then
    alter table public.contracts
      add constraint contracts_offer_structure_check
      check (offer_structure is null or offer_structure in (
        'fixed_price_group_workshop', 'price_per_child_present',
        'price_per_child_enrolled', 'price_per_contract'
      ));
  end if;
end;
$$;

comment on column public.contracts.entry_number is 'The client/school''s own registry entry number for official correspondence on this contract (Romanian institutional practice) -- distinct from contract_number (ours) and client_contract_number (their filing reference for the contract document itself).';
comment on column public.contracts.exit_number is 'Same as entry_number, for outgoing correspondence.';
comment on column public.contracts.offer_structure is 'Which pricing MODEL this contract uses -- not an actual price, so unlike billing_rule/estimated_value this is NOT financially sensitive and is a plain passthrough column in public.contracts_billing_masked (202608160003), not part of its unmask condition.';
comment on column public.contracts.ac_link is 'Manual URL to the corresponding ActiveCampaign record. Free text, no validation -- same treatment as clients.external_crm_ref.';

alter table public.client_contacts
  add column if not exists contact_purpose text;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'client_contacts_contact_purpose_check'
  ) then
    alter table public.client_contacts
      add constraint client_contacts_contact_purpose_check
      check (contact_purpose is null or contact_purpose in (
        'signing_authority', 'trainer_facing', 'finance_facing', 'general'
      ));
  end if;
end;
$$;

comment on column public.client_contacts.contact_purpose is 'WHICH kind of contact this person is for the client (operational/trainer-facing, contract-signing authority, billing, or general) -- a school''s operational contact, signing contact, and billing contact are often 3 different people (Anca''s finding). Distinct from is_billing_contact/is_primary, which are unrelated existing flags. Nullable -- not backfilled for existing rows.';
