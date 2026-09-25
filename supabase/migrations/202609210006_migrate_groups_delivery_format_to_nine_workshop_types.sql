-- OPEN_ITEMS.md item 79's mapping, resolving it. Anca decided (2026-09-21)
-- the nine workshop types replace delivery_format's six values --
-- Scoala Altfel; Saptamana Verde (as she named it, matching the
-- schema's own existing scoala_altfel/saptamana_verde 1:1, not the
-- source spreadsheet's literal "Scoala Verde" item 52 originally quoted);
-- Wow Lab Party; Parteneriate cu companii; Cursuri deschise; Scoli
-- private (colaborari ocazionale); Scoli private (colaborari recurente);
-- Evenimente/prezentari la mall; Party in companii.
--
-- Item 79 already found this lower-risk than it looked: the duration
-- multiplier (app.resolve_duration_multiplier) has no live caller
-- anywhere in app code; payroll and masking read nothing from this
-- field; custom has zero live rows. Confirmed again, fresh, before
-- writing this migration -- unchanged since item 79.
--
-- ============================================================================
-- EVERY ROW, EXPLICITLY, NOT A BLANKET MAPPING -- confirmed live
-- immediately before writing this migration, exactly 3 rows exist across
-- both orgs in this shared database:
-- ============================================================================
-- WOW LAB, client "Skoala Franceza" (Lycee Francais, client_type
-- private_school), module wow_mix, id de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558:
-- 'recurring' -> 'scoli_private_recurente'. Clean, not just by the general
-- 6-to-9 rule: this row's own client is a private school with an ongoing
-- relationship, exactly what the target value names.
-- WOW LAB, same client, module wow_mix, id
-- efbe7e46-758e-4634-b9d8-57205ac45576: same mapping, same reasoning.
-- WOW LAB Test Org B, client "MAX" (client_type corporate), module
-- green_energy, id bda1f577-f381-4ced-a7f4-4d3399175e95: 'corporate' ->
-- 'parteneriate_companii'. This is the one row whose old value SPLITS --
-- 'corporate' has no single clean target ('parteneriate_companii',
-- 'party_companii', and 'evenimente_mall' were all plausible) -- reported
-- to Mihai before this migration was written, not defaulted; he chose
-- parteneriate_companii.
--
-- No scoala_altfel, saptamana_verde, party, or custom rows exist live
-- anywhere, so those three old values have nothing to migrate -- their
-- entries below exist for completeness/future-proofing only, confirmed
-- to affect zero rows right now.
--
-- If any row exists that this migration doesn't know about (it shouldn't
-- -- confirmed exhaustively above), the new CHECK constraint added below
-- will reject it and this migration will FAIL LOUDLY rather than leave a
-- row silently holding an illegal value -- the constraint is the real
-- safety net here, not just documentation.
-- The old 6-value constraint must be dropped BEFORE these writes -- none
-- of the 9 new keys are legal under it, so it would reject every one of
-- these UPDATEs otherwise. The new constraint is added right after, so
-- the column is never left unconstrained across a transaction boundary
-- (this migration runs as one transaction; there is no window where
-- another session could write an arbitrary value while the constraint is
-- absent).
alter table public.groups drop constraint groups_delivery_format_check;

update public.groups set delivery_format = 'scoli_private_recurente' where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558';
update public.groups set delivery_format = 'scoli_private_recurente' where id = 'efbe7e46-758e-4634-b9d8-57205ac45576';
update public.groups set delivery_format = 'parteneriate_companii'  where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95';

-- ============================================================================
-- THE CONSTRAINT ITSELF
-- ============================================================================
-- Keys stay ASCII snake_case (Mihai's instruction); labels carry the
-- diacritics, in app/(app)/groups/i18n.ts, RO and EN. scoala_altfel and
-- saptamana_verde keep their EXACT existing literal strings -- the
-- underlying program didn't change meaning, only got confirmed, so the
-- key doesn't change either (same reasoning item 83 used for paused/
-- churned surviving the status rename unchanged).
--
-- No catch-all/escape-hatch value -- item 79 already flagged this as a
-- real structural gap (custom's old role has no equivalent here), and
-- Anca's decision was "these nine replace the six," not "these nine plus
-- a fallback." Not invented here; if a workshop genuinely doesn't fit any
-- of the nine, that is now a real gap to surface, not silently absorbed.
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

-- ============================================================================
-- DURATION MULTIPLIER: re-keyed, not silently orphaned
-- ============================================================================
-- app.resolve_duration_multiplier has no live caller anywhere in app code
-- today (item 79/85's own finding, reconfirmed) -- it WILL have one the
-- day payroll computation is built, and this re-key is what keeps that
-- day from silently reading a delivery_format value that no longer
-- exists. The two literal strings it matches against, 'scoala_altfel' and
-- 'saptamana_verde', are UNCHANGED by this migration (same key choice
-- reasoning as above) -- so the CASE WHEN's values don't need to change,
-- only this comment needs to say so explicitly, so a future reader finds
-- confirmation here rather than having to re-derive it.
create or replace function app.resolve_duration_multiplier(p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date)
returns numeric
language plpgsql
stable
as $$
declare
  v_context text;
  v_version_id uuid;
  v_multiplier numeric;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  select id into v_version_id
  from public.duration_multiplier_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select multiplier into v_multiplier
  from public.duration_multiplier_rates
  where version_id = v_version_id
    and duration_minutes = p_duration_minutes
    and delivery_context = v_context;

  if v_multiplier is null then
    raise exception 'app.resolve_duration_multiplier: version % has no row for % minutes / context % -- incomplete version', v_version_id, p_duration_minutes, v_context;
  end if;

  return v_multiplier;
end;
$$;

comment on function app.resolve_duration_multiplier(uuid, integer, text, date) is
  'RE-KEYED 2026-09-21 (item 79/85): groups.delivery_format moved from 6 values to Anca''s 9 workshop types. The two values this function matches against, scoala_altfel and saptamana_verde, are UNCHANGED literal strings under the new 9-value list (same program, same key, item 79''s own confirmed 1:1 mapping) -- this CREATE OR REPLACE exists to record that re-confirmation explicitly, not because the matched values needed to change. Re-verify this comment (not just the code) the day a payroll calculation actually calls this function for the first time -- item 79/85 found zero live callers as of this migration.';
