-- Corrects the Scoala Avenor contract: invoicing entity Brandine
-- Advertising SRL, price 700 RON without VAT per group per session,
-- period unchanged at 2026-09-01 .. 2027-06-30.
--
-- WHY IT IS A CORRECTION AND NOT A SECOND CONTRACT. Both facts changed
-- during the school year -- the price from 950 + VAT to 700, and the
-- entity from Experimente Wow to Brandine -- which looked like it needed
-- effective-dating, and the obvious shape was the amendment chain
-- supplier_contracts already has (amends_contract_id). Anca's answer,
-- 2026-10-16, removed the case rather than the gap:
--
--   * the renegotiation is RETROACTIVE -- 700 applies from 1 September
--     2026, which is the contract's own period_start;
--   * 700 carries NO VAT, because Brandine is not VAT-registered;
--   * price and entity are one decision taken on one date.
--
-- So there are not two prices over two intervals. There is one contract
-- whose stored values were stale. amends_contract_id stays unbuilt on
-- Mihai's instruction -- building a mechanism for a case that no longer
-- exists is how a schema accumulates structure nobody can later justify.
-- The gap is recorded as item 141 for the first change that genuinely
-- falls inside a period.
--
-- THE VAT TREATMENT IS IN THE TEXT BECAUSE THERE IS NOWHERE ELSE.
-- billing_rule is free text and the only place the amount, the currency,
-- the VAT treatment and the unit can go; there is no numeric price column
-- for a client (item 141 again). "700 RON fără TVA/grupă/ședință" states
-- all four, in the shape the two sibling contracts already use. It is
-- still a sentence rather than four fields, and nothing can compute from
-- it -- which is the whole content of item 141 and is not fixed here.
--
-- offer_structure stays 'fixed_price_group_workshop'. It is wrong in the
-- same way it is wrong for Scoala Germana -- the enum cannot distinguish
-- per group from per group PER SESSION -- and there is no better value to
-- move it to, so it is left rather than swapped for a different
-- inaccuracy.
--
-- contracts carries the row_history trigger, so the before-image of both
-- columns is captured there. billing_rule has a column-level REVOKE on
-- authenticated (202609220001), so this is only writable by a migration
-- or through app.rpc_set_contract_financials -- a data correction is the
-- former, the same way 202610130002 corrected exit_number.
--
-- Idempotent: guarded on the current values, so re-running changes
-- nothing and a later real edit is never silently overwritten.

do $$
declare
  v_org uuid;
  v_contract uuid;
  v_brandine uuid;
  v_before_entity text;
  v_before_rule text;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'correct_avenor_contract: no organization with slug wow-lab';
  end if;

  select ct.id into v_contract
  from public.contracts ct
  join public.clients c on c.id = ct.client_id
  where ct.organization_id = v_org and c.name = 'Scoala Avenor';
  if v_contract is null then
    raise exception 'correct_avenor_contract: no contract found for client Scoala Avenor';
  end if;

  select id into v_brandine
  from public.legal_entities
  where organization_id = v_org and name = 'Brandine Advertising SRL';
  if v_brandine is null then
    raise exception 'correct_avenor_contract: no legal entity named Brandine Advertising SRL';
  end if;

  select le.name, ct.billing_rule into v_before_entity, v_before_rule
  from public.contracts ct
  left join public.legal_entities le on le.id = ct.legal_entity_id
  where ct.id = v_contract;

  update public.contracts
  set legal_entity_id = v_brandine,
      billing_rule = '700 RON fără TVA/grupă/ședință'
  where id = v_contract;

  -- The period was already right and is deliberately NOT touched: the
  -- retroactive renegotiation applies from period_start, which is already
  -- 2026-09-01. Asserted so a wrong period cannot pass unnoticed behind a
  -- correct price.
  if not exists (
    select 1 from public.contracts
    where id = v_contract
      and period_start = '2026-09-01' and period_end = '2027-06-30'
  ) then
    raise exception 'correct_avenor_contract: period is not 2026-09-01..2027-06-30 as expected -- refusing to leave a corrected price on an unexpected period';
  end if;

  raise notice 'correct_avenor_contract: entity % -> Brandine Advertising SRL; rule % -> 700 RON fara TVA/grupa/sedinta',
    coalesce(v_before_entity,'(none)'), coalesce(v_before_rule,'(none)');
end $$;
