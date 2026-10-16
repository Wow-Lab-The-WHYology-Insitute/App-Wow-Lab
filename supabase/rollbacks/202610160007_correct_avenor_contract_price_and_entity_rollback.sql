-- Rollback for 202610160007. Restores the Scoala Avenor contract to
-- Experimente Wow SRL and "950 + TVA/grupa".
--
-- Those are the values the contract held before the correction, and they
-- are STALE, not merely different: Anca confirmed 2026-10-16 that the
-- renegotiated 700 (without VAT, Brandine not being VAT-registered)
-- applies retroactively from 1 September 2026. Rolling this back restores
-- a price and an invoicing entity that no longer describe the engagement,
-- so only do it to undo a mistaken application of the migration itself.
--
-- row_history holds the before-image of both columns either way.

do $$
declare
  v_org uuid;
  v_contract uuid;
  v_experimente uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select ct.id into v_contract
  from public.contracts ct join public.clients c on c.id = ct.client_id
  where ct.organization_id = v_org and c.name = 'Scoala Avenor';
  select id into v_experimente
  from public.legal_entities
  where organization_id = v_org and name = 'Experimente Wow SRL';

  if v_contract is null or v_experimente is null then
    raise exception 'rollback: missing Avenor contract or Experimente Wow SRL';
  end if;

  update public.contracts
  set legal_entity_id = v_experimente,
      billing_rule = '950 + TVA/grupa'
  where id = v_contract;
end $$;
