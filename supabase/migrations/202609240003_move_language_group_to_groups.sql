-- Moves language from sessions to groups.
--
-- REVERSES 202608310001's own reasoning, not silently: that migration
-- said "language_group: same reasoning as location -- confirmed to vary
-- per session, not per client or per trainer." In actual use this
-- doesn't hold for a recurring engagement -- a French-school club is in
-- French every week, and a per-session field for a fact that never
-- changes is fifty-two chances a year to drift, not fifty-two real
-- facts. location_tier stays on sessions (it genuinely varies -- who's
-- assigned varies week to week, and travel depends on who's assigned,
-- not on the school); language doesn't share that dependency, so it
-- doesn't share the placement.
--
-- No data lost: the one real session in the whole database (a fixture,
-- wow-lab-test-b) has language_group = NULL, and it was NULL on every
-- session that ever existed -- the column was added 2026-08-31 with no
-- UI ever built to write to it (confirmed by grep: addSession's insert
-- payload never included it, NewSessionForm never had a field for it).
-- Nothing to carry over.
--
-- Also NOT inferred from any existing group, on purpose, even though
-- one is tempting: "Școala Franceză (Lycee Francais)" (client, WOW LAB,
-- 2 groups) is obviously a French-medium school by name. Guessing is
-- not the same as knowing -- same discipline as the original migration
-- applied to sessions ("no invented value for historical data"), now
-- applied to a group whose language is *not* historical, just not yet
-- confirmed by Anca. Both of its groups' language_group stays NULL
-- until she says so through the edit form this migration's app-code
-- companion adds.

alter table public.groups
  add column language_group text null
    check (language_group in ('ro_en', 'fr_de_es'));

comment on column public.groups.language_group is
  'Which language this group''s sessions are conducted in. Group-level (not session-level, unlike location_tier) because it does not vary week to week for a recurring engagement -- see this column''s own migration (202609240003) for the reversal of sessions.language_group''s original placement reasoning.';

-- groups' UPDATE/INSERT grant to authenticated was narrowed to an
-- explicit column list in 202609220003 (item 91) -- a table-wide grant
-- no longer exists, so a new column needs its own explicit grant or it
-- is silently unwritable via the normal addGroup/updateGroup actions.
-- SELECT was never narrowed the same way (202609220003 only touched
-- UPDATE/INSERT), so no SELECT grant is needed here.
grant update (language_group) on public.groups to authenticated;
grant insert (language_group) on public.groups to authenticated;

-- sessions.language_group: drop. Confirmed no RLS policy, view, or
-- other migration reads this column directly (app.resolve_language_bonus
-- takes language_group as a plain parameter, not a column read inside
-- the function) -- safe to drop cleanly.
alter table public.sessions drop column language_group;
