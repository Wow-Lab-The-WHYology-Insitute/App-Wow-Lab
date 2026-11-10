-- db/tests/arc_duration_hazard.sql
-- OPEN_ITEMS.md item 193 -- the pontaj's duration column is in HOURS
-- (1 / 1.5 / 2) on every row across the whole sheet; sessions.duration_minutes
-- expects minutes. Mihai's named hazard: an import that writes the raw hour
-- value as minutes produces a plausible, wrong, hard-to-notice price.
--
-- Not an RLS suite -- no authorization branch here -- same naming choice as
-- custom_workshop_type.sql and vet_module.sql.
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner (run_rls_suite.ts), and it must carry check_name / actual /
-- expected / pass.
--
-- Both blocks use wow-lab-test-b's own live fixtures (a real organization,
-- a real group whose delivery_format maps to the 'standard' duration
-- context) -- nothing here touches real WOW LAB data, and every insert
-- rolls back.

-- ============================================================================
-- Block 1: THE NARROWED CASE. ARC's own real values (1, 1.5, 2 hours, read
-- as raw minutes) are all below sessions_duration_minutes_range_check's own
-- floor (15) and are refused loudly, at INSERT time, before
-- app.resolve_duration_multiplier ever runs. Induced directly -- the insert
-- is actually attempted, not reasoned about from the constraint's text.
-- ============================================================================
begin;
  create temp table sabotage_result_1 (rejected boolean) on commit drop;

  do $$
  begin
    begin
      insert into public.sessions (organization_id, group_id, session_date, duration_minutes, status)
      values ('09098278-4abc-4de6-a21f-5dc044d15ec4', 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2020-01-01', 1, 'planned');
      -- Reached only if the range CHECK failed to reject it.
      insert into sabotage_result_1 values (false);
    exception when check_violation then
      insert into sabotage_result_1 values (true);
    end;
  end $$;

  select 'duration_minutes = 1 (ARC''s own hour-value, misread as minutes) is refused by the range CHECK' as check_name,
         (select rejected::text from sabotage_result_1) as actual,
         'true' as expected,
         (select rejected from sabotage_result_1) as pass;
rollback;

-- ============================================================================
-- Block 2: THE OPEN CASE. A raw hour-value of 15 or more (a multi-hour block
-- entered with the same unit slip) clears the floor, is accepted, and
-- resolves -- through the REAL app.resolve_duration_multiplier, not a
-- reconstruction -- to the 30-minute band's 1.0 multiplier: plausible,
-- payable, and wrong, exactly as Mihai named it. This is the case the CHECK
-- constraint does not and cannot cover in general.
-- ============================================================================
begin;
  insert into public.sessions (organization_id, group_id, session_date, duration_minutes, status, notes)
  values ('09098278-4abc-4de6-a21f-5dc044d15ec4', 'bda1f577-f381-4ced-a7f4-4d3399175e95', '2020-01-01', 15, 'planned', 'ACCEPTANCE TEST -- arc_duration_hazard (rolled back)');

  select 'duration_minutes = 15 is accepted by the range CHECK (the floor does not catch this case)' as check_name,
         (select count(*)::text from public.sessions where notes = 'ACCEPTANCE TEST -- arc_duration_hazard (rolled back)' and duration_minutes = 15) as actual,
         '1' as expected,
         (select count(*) from public.sessions where notes = 'ACCEPTANCE TEST -- arc_duration_hazard (rolled back)' and duration_minutes = 15) = 1 as pass
  union all
  select 'app.resolve_duration_multiplier lands a 15-minute input on the 30-minute band at 1.0 -- induced via the real function',
         app.resolve_duration_multiplier('09098278-4abc-4de6-a21f-5dc044d15ec4', 15, 'parteneriate_companii', '2020-01-01')::text,
         '1.0',
         app.resolve_duration_multiplier('09098278-4abc-4de6-a21f-5dc044d15ec4', 15, 'parteneriate_companii', '2020-01-01') = 1.0;
rollback;
