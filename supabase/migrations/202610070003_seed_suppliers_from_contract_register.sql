-- 202610070003_seed_suppliers_from_contract_register.sql
--
-- Seeds public.suppliers (previously zero rows) with all 22 counterparties
-- from the real supplier contract register -- `Tabel contracte furnizori Wow
-- Lab.xlsx` (~/Downloads, sheet misnamed `Tabel Clienti Wow Lab`; it holds
-- suppliers, not clients). 39 contract rows collapse to 22 distinct suppliers;
-- this table holds the SUPPLIER, not the contract, so one row per supplier.
--
-- WHY THIS IS A SEPARATE MIGRATION FROM 202610070002, which asked for both in
-- one: 202610070002 is schema (a column and a policy branch) and is correct
-- regardless of whether these particular 22 rows ever load. These 22 rows are
-- real production data about real companies and five real people, and whether
-- they should be inserted by migration or typed in by hand is a judgement
-- call. Splitting is what lets that stay open without also holding back the
-- column the self-read branch needs. If the answer is "type them in the app",
-- this file is deleted and 202610070002 still stands on its own.
--
-- THEY ARE CORRECTABLE AFTER LOADING -- corrected 2026-10-07. An earlier
-- version of this reasoning claimed there was no supplier screen. There is:
-- `app/(app)/suppliers/` (list + create) and `app/(app)/suppliers/[id]/`
-- (detail + edit), both committed and live since 2026-08-27/09-09.
-- `updateSupplier` in `app/(app)/suppliers/actions.ts` edits name, legal_name,
-- cui, service_type, status and notes -- every column this migration populates
-- except user_id. So a holder of finance.reporting.* can fix any value below
-- through the app, and the `suppliers_row_history` trigger (BEFORE UPDATE OR
-- DELETE, confirmed live via pg_trigger) records the change with old_values.
-- Nothing here needs a follow-up migration or a hand-written production write
-- to correct.
--
-- WHAT LOADING DOES FREEZE, as a named list someone can ask Anca or Anka
-- about rather than discover later -- five values the register does not carry:
--   service_type NULL: BOLT, CENTRUL MEDICAL UNIREA SRL, PIDGIN HOST SRL,
--                      POSITIVE PROJECTS SRL
--   cui NULL:          PIDGIN HOST SRL (source cell empty -- distinct from the
--                      two deliberately withheld CNPs below)
-- All five are editable in the app, so these are gaps that can be closed, not
-- wrong values that have to be found first.
--
-- PROVENANCE: THIS FILE IS THE ONLY RECORD OF WHERE THESE 22 ROWS CAME FROM.
-- `suppliers_row_history` fires BEFORE UPDATE OR DELETE -- not INSERT -- so the
-- load itself leaves no history row, and `audit_log` stopped being written on
-- 2026-09-10 and never covered this table. That is OPEN_ITEMS item 104 ("this
-- database cannot answer who inserted this row") landing on real production
-- data for the first time rather than in principle. Consequence to respect:
-- the absence of a history row for any of these 22 is NOT evidence about their
-- origin -- the answer is this file, and nothing else.
--
-- ============================================================================
-- THE CNP DECISION -- why two rows have a NULL cui on purpose
-- ============================================================================
-- Two suppliers in the register are individuals whose `CUI` cell holds a
-- 13-digit Romanian CNP (cod numeric personal -- the national identity
-- number), not a company fiscal code: BEREA ALEXANDRU-VALENTIN and RALUCA
-- MARGEAN. Every other identifier in that column is a 7-to-8-digit CUI, with
-- or without the RO VAT prefix.
--
-- Decision (Mihai, 2026-10-07): the CNPs are NOT imported. `cui` is NULL for
-- those two, and the reason is recorded on the row itself in `notes` so the
-- gap never reads as missing data someone should go and fill.
--
-- The reasoning, recorded because a future reader will otherwise assume the
-- value was simply unavailable: nothing in this application computes from a
-- CNP, nothing joins on it, and no screen displays it. Its only real use is
-- invoicing, which happens in SmartBill, outside this system. So importing it
-- would add the single most sensitive identifier a person holds to a table
-- readable by three accounts, in exchange for no capability whatsoever. The
-- two alternatives were considered and rejected: importing it and extending
-- the masking rules (buys nothing, and `WOWLAB_SAD_Field_Masking.md` masks
-- values that have a legitimate reader -- this one has none), and a separate
-- column with its own classification (same objection, plus it makes the
-- schema assert that storing CNPs is an intended capability).
--
-- A THIRD row also has a NULL cui, for an entirely different reason, and the
-- two must not be conflated: PIDGIN HOST SRL has no CUI in the source file at
-- all (register row 18, cell empty). That one IS missing data and may be
-- filled in later. The withheld pair must not be.
--
-- ============================================================================
-- COLUMN-BY-COLUMN, AND THE JUDGEMENTS MADE
-- ============================================================================
-- `name`        -- verbatim from the register's FURNIZORI/COMPANIE column,
--                  including its own inconsistent casing (`United Media
--                  Corporation S.R.L.` beside `ASISMART SRL`). Not normalised:
--                  there is no consumer, no CHECK, and tidying would mean
--                  inventing a house style nobody has asked for.
--
-- `legal_name`  -- left NULL for all 22, which DEVIATES from the instruction
--                  to populate it, and is flagged here rather than done
--                  quietly. The register carries exactly ONE name per
--                  supplier, and for 20 of the 22 that name is already the
--                  registered legal form (`S.R.L.`, `SRL`, `S.A.`, `PFA`,
--                  `PERSOANA FIZICA AUTORIZATA`, `CABINET AVOCAT`). Copying it
--                  into both columns would assert a trade-name/legal-name
--                  distinction the source does not make; deriving a short
--                  trade name would be invention. The two that genuinely are
--                  trade names (`BOLT`, and probably `PIDGIN HOST SRL`) are
--                  the ones whose legal name we do NOT have. One UPDATE
--                  reverses this if a second source turns up.
--
-- `cui`         -- cleaned, not transformed. Two cleanings applied: the
--                  spreadsheet's float artifact (`53213832.0` -> `53213832`,
--                  from numeric cells) and one internal space (`RO 17290146`
--                  -> `RO17290146`, NEXT TOP). The `RO` prefix is kept exactly
--                  where the source has it and NOT added where it is absent --
--                  presence of the prefix carries VAT-registration meaning,
--                  so normalising it either way would be inventing a fact.
--                  Result: 19 populated, 3 NULL (2 withheld CNPs + 1 absent).
--
-- `service_type` -- from the register's Note column. CONFIRMED LIVE BEFORE
--                  WRITING THIS: there is no CHECK constraint on this column.
--                  `public.suppliers` has exactly three constraints -- the PK,
--                  the organization_id FK, and suppliers_status_check on
--                  `status` -- so every value below is accepted by definition
--                  and the question of an allowed set does not arise.
--                  Taken verbatim, with two deliberate substitutions where the
--                  source note names a DOCUMENT rather than a service, because
--                  an amendment label is not a service type:
--                    ROMAN V. ANDRA: 'ACT ADITIONAL LA CONTRACTUL DE ASISTENTA
--                      JURIDICA' -> 'Asistenta juridica'
--                    RALUCA MARGEAN: 'CONTRACT DE CESIUNE A DREPTURILOR DE
--                      AUTOR' -> 'Cesiune drepturi de autor'
--                  In both cases the service is named inside the source string;
--                  nothing is inferred from outside it, and both source
--                  strings are preserved in `notes`.
--                  Four suppliers get NULL -- BOLT, CENTRUL MEDICAL UNIREA,
--                  PIDGIN HOST, POSITIVE PROJECTS -- because the register has
--                  no note for them on any of their rows. Guessing the service
--                  from the company name (telephony? medical? hosting?) would
--                  be exactly the kind of plausible invention that is worse
--                  than an honest empty cell.
--
-- `notes`       -- provenance, not prose: how many contracts the register
--                  holds for this supplier, which of the three Wow Lab legal
--                  entities they contract with, and -- where applicable -- the
--                  verbatim source note that `service_type` shortened, or the
--                  reason `cui` is null. This is the audit trail back to the
--                  spreadsheet row numbers.
--
-- `status`      -- 'active' for all 22 (the column default). Note this is
--                  SUPPLIER status, not contract status: several have expired
--                  contracts (S.C. WORDSPIN's expired 2025-06-17, RALUCA
--                  MARGEAN's original 2025-09-01) but the supplier itself has
--                  not been retired. 'inactive' replaces hard delete
--                  (202608300001) and is a decision for whoever retires a
--                  relationship, not something to infer from a date.
--
-- `user_id`     -- populated for the five person-suppliers, each looked up BY
--                  EMAIL and each raising if absent. Those five email matches
--                  are the entire basis of the link and were originally made
--                  by eye against the register's `Adresa de email` column; the
--                  lookups below are what turn that into a stored fact. See
--                  202610070002's column comment.
--                  NOT a claim about roles: Catalina Trusan invoices as a
--                  trainer and holds no trainer role, which is correct -- she
--                  does not record her own sessions. A contract and a role are
--                  unrelated, and nothing here should be read as evidence that
--                  any of the five should hold any particular role.
--
-- Seeded into the real org (slug `wow-lab`) only. Test Org B gets nothing:
-- these are real companies, and the register's own values would be the wrong
-- shape for a fixture.

do $$
declare
  v_org      uuid;
  v_anka     uuid;
  v_margean  uuid;
  v_catalina uuid;
  v_popa     uuid;
  v_merisan  uuid;
  v_existing int;
  v_inserted int;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'supplier seed: no organization with slug=wow-lab';
  end if;

  -- Fail loudly on a double-apply rather than silently doubling the register.
  -- There is no unique constraint on `name` (and shouldn't be -- see
  -- 202610070002 on why a person may hold two supplier identities), so
  -- `on conflict` cannot protect this. The guard is the protection.
  select count(*) into v_existing from public.suppliers where organization_id = v_org;
  if v_existing <> 0 then
    raise exception 'supplier seed: org wow-lab already has % supplier row(s) -- refusing to seed on top of existing data', v_existing;
  end if;

  -- The five identity lookups. Each raises: a silent NULL here would quietly
  -- undo the entire point of the user_id column.
  select id into v_anka     from public.users where email = 'anka@asismart.ro';
  select id into v_margean  from public.users where email = 'ralucamargean@yahoo.com';
  select id into v_catalina from public.users where email = 'catalina_moale@yahoo.com';
  select id into v_popa     from public.users where email = 'popar216@gmail.com';
  select id into v_merisan  from public.users where email = 'merisanteodora@gmail.com';

  if v_anka is null then raise exception 'supplier seed: no user anka@asismart.ro (ASISMART SRL)'; end if;
  if v_margean is null then raise exception 'supplier seed: no user ralucamargean@yahoo.com (RALUCA MARGEAN)'; end if;
  if v_catalina is null then raise exception 'supplier seed: no user catalina_moale@yahoo.com (TRUSAN FLORINA CATALINA PFA)'; end if;
  if v_popa is null then raise exception 'supplier seed: no user popar216@gmail.com (POPA C. RALUCA-MARIA-DIETETICIAN)'; end if;
  if v_merisan is null then raise exception 'supplier seed: no user merisanteodora@gmail.com (MERISAN IOANA-TEODORA PFA)'; end if;

  insert into public.suppliers (organization_id, name, legal_name, cui, service_type, status, notes, user_id)
  values
    -- ---- the five person-suppliers (user_id populated) --------------------
    (v_org, 'ASISMART SRL', null, '53213832',
     'ASISTENTA ADMINISTRATIVA SI OPERATIONALA', 'active',
     'Register rows 2-4: 3 contracts, one per legal entity (Experimente WOW, Brandine Advertising, Asociatia Stemplicity). Contact/administrator: ORBAN ANNAMARIA. Linked to user Anka Orban by email match on anka@asismart.ro.',
     v_anka),

    (v_org, 'RALUCA MARGEAN', null, null,
     'Cesiune drepturi de autor', 'active',
     'Register rows 26-28: original contract plus Act adiţional 1 and 2, all with Experimente WOW. cui DELIBERATELY NULL: the source cell holds a 13-digit CNP (national identity number), not a company fiscal code, and is not imported -- see this migration''s header. This is a withheld value, NOT missing data. Source note, verbatim: "CONTRACT DE CESIUNE A DREPTURILOR DE AUTOR". Linked to user Raluca Margean by email match on ralucamargean@yahoo.com.',
     v_margean),

    (v_org, 'TRUȘAN FLORINA CĂTĂLINA PFA', null, '52912786',
     'Onorarii trainer', 'active',
     'Register rows 32-34: 3 contracts, one per legal entity, all 2026-09-01 to 2027-06-30. Linked to user Cătălina Trușan by email match on catalina_moale@yahoo.com. She holds no trainer role in user_org_roles, and that is correct -- a contract and a role are unrelated.',
     v_catalina),

    (v_org, 'POPA C. RALUCA-MARIA-DIETETICIAN', null, '51370202',
     'Onorarii trainer', 'active',
     'Register rows 35-37: 3 contracts, one per legal entity, all 2026-09-01 to 2027-06-30. Linked to user Raluca Popa by email match on popar216@gmail.com.',
     v_popa),

    (v_org, 'MERIȘAN IOANA-TEODORA PFA', null, '54506814',
     'Onorarii trainer', 'active',
     'Register rows 38-40: 3 contracts, one per legal entity, all 2026-09-01 to 2027-06-30. Linked to user Teodora Merișan by email match on merisanteodora@gmail.com.',
     v_merisan),

    -- ---- the 17 company suppliers (user_id NULL -- the normal case) -------
    (v_org, 'BEREA ALEXANDRU-VALENTIN', null, null,
     'Chirie', 'active',
     'Register row 5: 1 contract with Experimente WOW, open-ended ("nedeterminat"). cui DELIBERATELY NULL: the source cell holds a 13-digit CNP (national identity number), not a company fiscal code, and is not imported -- see this migration''s header. This is a withheld value, NOT missing data.',
     null),

    (v_org, 'BOLT', null, '14532901',
     null, 'active',
     'Register row 6: 1 contract with Experimente WOW. service_type NULL: the register has no note for this supplier, and the service is not derivable from the name without guessing.',
     null),

    (v_org, 'CENTRUL MEDICAL UNIREA SRL', null, 'RO5919324',
     null, 'active',
     'Register row 7: 1 contract with Experimente WOW, expiry recorded as the duration "1 AN" rather than a date. service_type NULL: no note in the register.',
     null),

    (v_org, 'CERISEO SRL', null, 'RO29889972',
     'Mentenanta site wowlab', 'active',
     'Register rows 8-9: 2 contracts with Experimente WOW (the second is ANEXA 2). Contact: CERIZA PETRESCU.',
     null),

    (v_org, 'EDUKIWI HUB S.R.L', null, 'RO41694988',
     'CURS Metoda High Performance Automations', 'active',
     'Register row 30: 1 contract with Experimente WOW.',
     null),

    (v_org, 'FLEXIBLE OFFICE SPACE S.R.L.', null, '46788773',
     'CHIRIE SEDIUL SOCIAL', 'active',
     'Register rows 10-13: 4 contracts -- the most of any supplier -- across all three legal entities (Asociatia Stemplicity holds two).',
     null),

    (v_org, 'INTELLEMMI CONSULT S.R.L.', null, '18778790',
     'MARCI // BREVETE DE INVENTIE', 'active',
     'Register row 25: 1 contract with Brandine Advertising. Longest term in the register -- expiry 2035-04-29, 123 months; worth confirming the year is not a typo.',
     null),

    (v_org, 'JOSAN SIMONA-CORINA PERSOANA FIZICA AUTORIZATA', null, '52967420',
     'Contract SEO', 'active',
     'Register row 14: 1 contract with Experimente WOW.',
     null),

    (v_org, 'NEXT TOP INTERNATIONAL S.R.L.', null, 'RO17290146',
     'Contract contabilitate', 'active',
     'Register rows 15-16: 2 contracts (Experimente WOW, Brandine Advertising), both with no start or expiry date recorded. cui normalised from the source''s "RO 17290146" (internal space removed).',
     null),

    (v_org, 'ORANGE ROMANIA S.A.', null, '9010105',
     'Servicii Telefonie', 'active',
     'Register row 17: 1 contract with Experimente WOW.',
     null),

    (v_org, 'PIDGIN HOST SRL', null, null,
     null, 'active',
     'Register row 18: 1 contract with Experimente WOW, no dates recorded. cui NULL because the source cell is EMPTY -- this is missing data that may be filled in later, unlike the two withheld CNP rows. service_type NULL: no note in the register.',
     null),

    (v_org, 'POSITIVE PROJECTS SRL', null, '32934020',
     null, 'active',
     'Register row 19: 1 contract with Experimente WOW, expiry "N/A". Contact: Irina Popescu. service_type NULL: no note in the register.',
     null),

    (v_org, 'ROMAN V. ANDRA - CABINET AVOCAT', null, '33020632',
     'Asistenta juridica', 'active',
     'Register rows 20-22: 3 contracts (Experimente WOW ×2, Brandine Advertising). service_type shortened from the source note, which names a document not a service -- verbatim: "ACT ADITIONAL LA CONTRACTUL DE ASISTENȚĂ JURIDICĂ". Row 21 has "N/A" in BOTH start and expiry.',
     null),

    (v_org, 'S.C. WORDSPIN S.R.L.', null, '31403836',
     'Contract prestari servicii informatice', 'active',
     'Register row 23: 1 contract with Experimente WOW, expired 2025-06-17. Supplier left active -- expiry of a contract is not retirement of a supplier.',
     null),

    (v_org, 'SAGA SOFTWARE S.R.L.', null, 'RO17602787',
     'Licenta Web contabilitate in cont', 'active',
     'Register row 24: 1 contract with Experimente WOW.',
     null),

    (v_org, 'STAR TAXI APP SRL', null, 'RO29300987',
     'Taxi', 'active',
     'Register row 31: 1 contract with Experimente WOW, open-ended ("nedeterminat"); the validity formula on this row had no cached result at all.',
     null),

    (v_org, 'United Media Corporation S.R.L.', null, 'RO12797530',
     'Contract Cadru de Cooperare in Comunicare Comerciala', 'active',
     'Register row 29: 1 contract with Experimente WOW.',
     null);

  select count(*) into v_inserted from public.suppliers where organization_id = v_org;
  if v_inserted <> 22 then
    raise exception 'supplier seed: expected 22 rows after insert, found %', v_inserted;
  end if;

  select count(*) into v_inserted from public.suppliers where organization_id = v_org and user_id is not null;
  if v_inserted <> 5 then
    raise exception 'supplier seed: expected 5 rows with user_id, found %', v_inserted;
  end if;

  select count(*) into v_inserted from public.suppliers where organization_id = v_org and cui is null;
  if v_inserted <> 3 then
    raise exception 'supplier seed: expected 3 rows with null cui (2 withheld CNPs + 1 absent in source), found %', v_inserted;
  end if;
end $$;
