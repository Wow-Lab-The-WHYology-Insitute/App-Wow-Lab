-- 202611100001_scoala_arc_client_contract.sql
-- OPEN_ITEMS.md item 193 (item 171's own "Scoala ARC specifically" entry) --
-- Scoala ARC, the fourth client. Built from Anca's real October timesheet,
-- read fresh for this ask (2026-11-10), not from memory: 20 rows, two days
-- (19/20 October 2026), all Brandine Advertising, all Bucharest (0%
-- location tier), all "Romanian or English", all duration 1 (hour -- the
-- timesheet's own column header, not assumed).
--
-- CUI 37239989 was supplied by Mihai directly (the "Mapari Tip Trainer"
-- tab's own value against the ARC name, per item 171) -- blank on every
-- pontaj row itself. Confirmed live, immediately before this insert, not
-- reused from an earlier session's check: no client or supplier anywhere
-- in this organization already carries this CUI or this name.
--
--   select c.id from public.clients c join public.organizations o on
--     o.id = c.organization_id where o.slug = 'wow-lab'
--     and (c.cui = '37239989' or c.name ilike '%arc%');
--   -- 0 rows, 2026-11-10.
--
-- ============================================================================
-- WHAT THIS MIGRATION DOES NOT DO, ON PURPOSE
-- ============================================================================
-- No sessions. The pontaj's 20 rows (Catalina x6 + Lorina x6 on the 19th,
-- Lorina x4 + Teodora x4 on the 20th) cannot distinguish two different real
-- shapes that would need different session counts and different trainer
-- allocations: six 19-October workshops delivered JOINTLY (both trainers
-- present per workshop -- 6 physical sessions, each needing a principal and
-- a secundar CHOSEN, not inferred) versus twelve delivered IN PARALLEL (each
-- trainer running her own separate group, coincidentally the same school and
-- date -- 12 independent sessions, no secundar on any of them, the principal
-- bonus never eligible). Both produce the identical 6-and-6 row shape in the
-- timesheet. Mihai's own instruction, once this was surfaced: an import
-- asserts a fact, and this one does not have the fact yet -- same rule as
-- item 152 (no false confirmation, no exception for the inconvenience of
-- waiting). The sessions stay unwritten until Anca answers joint-vs-parallel
-- for both days. See OPEN_ITEMS.md item 193 for the full reasoning,
-- including Mihai's own hand-check of the eventual total and why it is
-- already known to land at 2.598,00 lei, not his own 2.626,00 (Teodora's
-- live grade is 3, not 4 -- see that item).
--
-- Also see item 189 point 5 and item 171's own correction: this item's
-- earlier draft quoted Anca on the bonus ("UN SINGUR bonus de 20 lei") --
-- she never said it; it was Mihai's own anticipatory note, corrected in
-- place, not repeated here.
--
-- ============================================================================
-- WHAT IT DOES BUILD -- unambiguous from the timesheet, nothing inferred.
-- ============================================================================
-- contract_type = 'one_off_event': the enum's own fit for a two-day
-- engagement (contracts.contract_type already offers this value --
-- 202608100001 -- nothing added here). status = 'signed': matching the
-- live convention every other real contract in this org already uses
-- (Avenor, Lycee, Scoala Germana are all 'signed', entry_number/
-- exit_number null on at least one of each) -- confirmed live before
-- writing this, not a status invented for this one row.
--
-- The model needed nothing new for the burst shape itself, measured before
-- building: groups.delivery_format already has 'custom' (one-off, no
-- enforced recurrence pattern -- 202609260001), sessions has no
-- UNIQUE(group_id, session_date) of any kind, and
-- app.resolve_duration_multiplier's own case statement already maps
-- 'custom' to the 'standard' delivery context (202609260001's own
-- assertion). A burst is not a shape this schema has to be taught.

do $$
declare
  v_org uuid;
  v_brandine uuid;
  v_client uuid;
  v_contract uuid;
  v_existing_cui_count integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'scoala_arc: no organization with slug wow-lab';
  end if;

  select le.id into v_brandine from public.legal_entities le
  where le.organization_id = v_org and le.name ilike '%brandine%';
  if v_brandine is null then
    raise exception 'scoala_arc: no legal entity matching %%brandine%% in wow-lab';
  end if;

  -- Re-confirmed live, not reused from item 171's own earlier check (SS24).
  select count(*) into v_existing_cui_count from public.clients
  where organization_id = v_org and (cui = '37239989' or name ilike '%arc%');
  if v_existing_cui_count <> 0 then
    raise exception 'scoala_arc: expected 0 existing clients named ARC or carrying CUI 37239989, found %', v_existing_cui_count;
  end if;

  -- No status/status_override set: item 78/83 (202609210003/202609210005)
  -- made clients.status derived, not written -- a client's effective
  -- status is 'active' iff a signed contract exists (else 'prospect'),
  -- via public.client_effective_status(). The signed contract inserted
  -- below makes this row resolve to 'active' on its own; writing a
  -- literal value here would be exactly the stale pattern that rename
  -- was built to retire.
  insert into public.clients (organization_id, name, client_type, cui, notes)
  values (
    v_org,
    'Scoala ARC',
    'private_school',
    '37239989',
    'CUI supplied by Mihai (Maparile Tip Trainer tab), not present on any real timesheet row -- see OPEN_ITEMS.md item 171/193. First real engagement: 19-20 October 2026.'
  )
  returning id into v_client;

  insert into public.contracts (organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, status, notes)
  values (
    v_org,
    v_client,
    v_brandine,
    'one_off_event',
    '2026-10-19',
    '2026-10-20',
    'signed',
    'OPEN_ITEMS.md item 193: retroactive entry for a real, already-delivered two-day engagement (per Anca''s timesheet). No paper contract document confirmed independently of the timesheet; status follows this org''s live convention for real contracts, same as Avenor/Lycee/Scoala Germana, not an overclaim invented for this row.'
  )
  returning id into v_contract;

  if (select public.client_effective_status(c) from public.clients c where c.id = v_client) <> 'active' then
    raise exception 'scoala_arc: expected client % to resolve to effective status active once a signed contract exists, got %', v_client,
      (select public.client_effective_status(c) from public.clients c where c.id = v_client);
  end if;

  raise notice 'scoala_arc: client % and contract % created, effective status active via the signed contract. No groups, no sessions -- blocked on Anca''s joint-vs-parallel answer (item 193).', v_client, v_contract;
end $$;
