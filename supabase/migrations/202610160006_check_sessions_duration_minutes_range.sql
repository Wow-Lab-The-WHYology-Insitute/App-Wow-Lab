-- A range CHECK on sessions.duration_minutes, which has had none.
--
-- The column is a nullable integer with no constraint of any kind: today
-- it accepts 45 and 50 (which it needs to), and equally accepts -5, 0 and
-- 99999. The only thing that has kept it sane is the <select> on the
-- workshop form offering 30/60/90/120 -- a control that is being replaced
-- in this same change by a number input, because 202610160004 made the
-- duration resolver band and a fixed four-option select is no longer the
-- honest control. The moment the column becomes freely typeable is the
-- moment the absence of a floor and a ceiling starts to matter.
--
-- 15 TO 480. A floor of 15 minutes is below anything WOW LAB runs (the
-- shortest real class is 45) and above a typo of 1 or 5. A ceiling of 480
-- is eight hours: longer than any workshop, short of a typo of 1200, and
-- deliberately WELL ABOVE the pay grid's own top band of 120.
--
-- That gap between 120 and 480 is the point, not an oversight. A workshop
-- longer than the top band must remain RECORDABLE and simply unpayable --
-- app.resolve_duration_multiplier raises above the top band and
-- app.calculate_org_session_pay classifies that as 'no_duration_row', so
-- /payroll shows it under "Gaps in the pay grid -- not fixable from this
-- screen" instead of refusing the entry. Operations records what happened;
-- Finance finds out it cannot be priced. Clamping the CHECK at 120 would
-- have made the schema enforce a pay rule, which is the wrong layer: a
-- real four-hour Scoala Altfel day would then be unenterable rather than
-- unpriced, and db/tests/payroll_org_session_pay.sql block 2 could not
-- insert its over-the-top-band fixture at all.
--
-- NULL stays allowed. Pencilling in a date before the length is known is
-- how scheduling starts here (item 121's own reasoning: location depends
-- on who is assigned, and nobody is assigned yet). /payroll's pre-close
-- block is where the absence surfaces.
--
-- Validated against existing rows first: the real org has no sessions at
-- all and Test Org B's three are 120/120/null, so nothing in the database
-- violates this. NOT VALID was therefore not needed -- the constraint is
-- added fully validated, which is only safe because that was checked
-- rather than assumed.

alter table public.sessions
  add constraint sessions_duration_minutes_range_check
  check (duration_minutes is null or (duration_minutes >= 15 and duration_minutes <= 480));

comment on constraint sessions_duration_minutes_range_check on public.sessions is
  'A sane floor and ceiling only. The ceiling (480) is deliberately far above the pay grid''s top band (120) so a workshop longer than anything the grid prices stays recordable and merely unpayable -- enforcing the pay rule here would be the wrong layer.';
