-- Rollback for 202609260001 -- restores the nine-value constraint and the
-- column comment 202609210006 left behind.
--
-- This is a TRUE undo only while no group actually uses 'custom'. The
-- forward migration widened a CHECK constraint and wrote no data; narrowing
-- it again is lossless for the three live rows (2x scoli_private_recurente,
-- 1x parteneriate_companii -- none of them custom).
--
-- It is NOT lossless if a 'custom' row has been created since. The
-- constraint re-add below will then FAIL LOUDLY rather than silently
-- discard or remap that row -- deliberately. A workshop someone classified
-- as Custom is a real record with a real classification, and the correct
-- response to "rolling this back would invalidate it" is a human decision
-- about that group, not an automatic rewrite. Same principle as the
-- forward migration's constraint being "the real safety net, not just
-- documentation."
--
-- If you genuinely need to force the rollback, requalify those rows first
-- and record what they became:
--   select id, name from public.groups where delivery_format = 'custom';

alter table public.groups drop constraint groups_delivery_format_check;

alter table public.groups
  add constraint groups_delivery_format_check
  check (delivery_format in (
    'scoala_altfel',
    'saptamana_verde',
    'wow_lab_party',
    'parteneriate_companii',
    'cursuri_deschise',
    'scoli_private_ocazionale',
    'scoli_private_recurente',
    'evenimente_mall',
    'party_companii'
  ));

comment on column public.groups.delivery_format is
  'Anca''s nine workshop types (2026-09-21, item 79/85 -- REPLACING the six-value working decision this column previously held, superseding this column''s own earlier "not explicitly confirmed by Anca" flag for the VALUE LIST specifically): scoala_altfel, saptamana_verde, wow_lab_party, parteneriate_companii, cursuri_deschise, scoli_private_ocazionale, scoli_private_recurente, evenimente_mall, party_companii. The module+delivery_format SPLIT itself (vs. a single "Tip atelier" field) remains Mihai''s own interpretation, unconfirmed by this decision -- only the delivery_format vocabulary was decided. Recurring, for the resources-caption distinction (app/(app)/groups/[id]/trainer-resources-section.tsx) and the group-create form''s schedule-pattern shape (groups-client.tsx), means scoli_private_recurente ONLY -- confirmed with Mihai, not all nine, and not by a "recurring" substring check.';
