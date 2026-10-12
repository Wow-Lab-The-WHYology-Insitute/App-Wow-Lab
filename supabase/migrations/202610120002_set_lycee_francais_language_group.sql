-- ============================================================================
-- Lycee Francais is taught in ENGLISH -- Anca confirmed 2026-10-12. Both of
-- its groups get language_group = 'ro_en', which carries NO bonus.
-- ============================================================================
-- This closes the one case 202609240003 named and deliberately refused to
-- guess. That migration's own words: "'Scoala Franceza (Lycee Francais)'
-- (client, WOW LAB, 2 groups) is obviously a French-medium school by name.
-- Guessing is not the same as knowing ... Both of its groups' language_group
-- stays NULL until she says so."
--
-- She said so, and the obvious guess was WRONG. The school is French by name
-- and English by delivery. Had anyone inferred it from the name -- which is
-- precisely what 202609240003 declined to do -- both groups would now carry
-- 'fr_de_es', the 20% branch, and every session there would overpay by 20%
-- (language_bonus_rates: fr_de_es 20, ro_en 0, Anca 2026-09-24, item 95).
-- Third time a plausible-looking inference would have corrupted correct data
-- in this project: "Laura Moale" (item 35) and the STEMplicity spelling
-- (item 42) were the first two.
--
-- 'ro_en' is the no-bonus key, so this write changes no pay outcome today --
-- it records a fact, and removes a NULL that app.resolve_language_bonus would
-- otherwise raise on when app.calculate_session_pay is finally called for a
-- session in one of these groups. That is the point: NULL is not "no bonus",
-- it is "unknown", and the resolvers are built to fail loudly on unknown.
--
-- Written as a migration rather than through the edit form, even though
-- 202609240003 pointed at the form: a confirmed fact from Anca belongs in a
-- reviewable, reversible artifact with its provenance attached (same reasoning
-- as 202609240002, which seeded ten trainers' grades from her answers). The
-- form stays the path for any later change.
--
-- One honest gap, stated rather than papered over: groups_row_history fires on
-- this UPDATE and will record actor_user_id = NULL, because a migration has no
-- JWT and app.current_user_id() reads one. The actor is not faked by setting a
-- claim. This file is the provenance record -- item 104's exact shape, now on
-- purpose rather than by accident.

do $$
declare
  v_updated int;
begin
  update public.groups g
     set language_group = 'ro_en'
    from public.clients c, public.organizations o
   where g.client_id = c.id
     and c.organization_id = o.id
     and o.slug = 'wow-lab'
     and c.name ilike '%Lycee Francais%'
     and g.language_group is null;

  get diagnostics v_updated = row_count;

  -- Exactly two groups, verified live before this was written. Raising on any
  -- other number is the point: if a third group appeared, or if someone had
  -- already set one of the two by hand, this migration must stop rather than
  -- quietly do something different from what was reviewed.
  if v_updated <> 2 then
    raise exception
      'Expected exactly 2 Lycee Francais groups with a NULL language_group, updated %. Check the live rows before re-running.',
      v_updated;
  end if;
end $$;
