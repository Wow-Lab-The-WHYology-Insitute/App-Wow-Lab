-- 202608160001_fix_bradine_legal_entity_spelling.sql
-- WOW LAB OS: data correction from Anca's live-app feedback.
--
-- "Bradine ADV SRL" was a misspelling carried from the original mockup/SAD
-- doc (docs/mockup/wow_lab_os_mockup.html, docs/WOWLAB_SAD_Domeniul_
-- Clients_Contracts_CRM.md — both consistently say "Bradine ADV", not
-- "Brandine") into the real B5 seed and this legal_entities row. Anca's
-- correction (the actual legal name) is "Brandine Advertising SRL" — full
-- descriptive name + legal suffix, matching the established naming style
-- of the other two real entities ("Experimente Wow SRL", "Asociatia
-- STEMplicity") rather than the abbreviated "ADV" short form.
--
-- FLAG: the mockup and SAD doc still say "Bradine ADV" after this fix —
-- those are historical planning artifacts, not live config, so left
-- untouched here; noted in the report as a known follow-up if Mihai wants
-- them updated too for consistency.
--
-- Updates the row itself (not display text) so the corrected name
-- propagates everywhere it's referenced (Zitec's contract, the entity
-- picker on /contracts, etc.) via the existing FK relationship. legal_
-- entities is AUDITED (202607080002) -- this UPDATE is captured by the
-- existing row_history trigger, so the old (wrong) name stays in the audit
-- trail rather than being silently lost.
--
-- Idempotent: matches on the known-wrong current name, so a second run
-- finds zero matching rows and no-ops.

update public.legal_entities
set name = 'Brandine Advertising SRL'
where name = 'Bradine ADV SRL';
