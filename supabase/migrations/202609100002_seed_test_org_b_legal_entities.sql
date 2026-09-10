-- 202609100002_seed_test_org_b_legal_entities.sql
-- WOW LAB OS: seed two fictional legal_entities rows into
-- wow-lab-test-b, so the contract create form's required Legal Entity
-- select has something to populate with in the test organization.
--
-- Why a migration and not app data entry: legal_entities has no app
-- route anywhere (confirmed: `find app -iname "*legal*"` returns
-- nothing) -- nobody, including Anca, can create one from inside the
-- app today. wow-lab's own three rows (Experimente Wow SRL, Brandine
-- Advertising SRL, Asociatia STEMplicity) were themselves only ever
-- created this same way, by migration.
--
-- Names are deliberately fictional and cannot be mistaken for
-- wow-lab's real entities -- neither name below shares a word with any
-- of the three real ones. This is the concrete fix for
-- docs/OPEN_ITEMS.md item 49's follow-up: wow-lab-test-b existed and
-- was proven isolated, but had zero legal_entities, so the contract
-- form could never be exercised there even once.
--
-- Idempotent: scoped by (organization_id, name), a second run finds
-- both rows already present and inserts nothing new.

insert into public.legal_entities (organization_id, name, entity_type)
select '09098278-4abc-4de6-a21f-5dc044d15ec4', 'Test Entity SRL', 'srl'
where not exists (
  select 1 from public.legal_entities
  where organization_id = '09098278-4abc-4de6-a21f-5dc044d15ec4'
    and name = 'Test Entity SRL'
);

insert into public.legal_entities (organization_id, name, entity_type)
select '09098278-4abc-4de6-a21f-5dc044d15ec4', 'Test Association', 'asociatie'
where not exists (
  select 1 from public.legal_entities
  where organization_id = '09098278-4abc-4de6-a21f-5dc044d15ec4'
    and name = 'Test Association'
);
