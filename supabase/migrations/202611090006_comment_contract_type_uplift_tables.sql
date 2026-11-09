-- 202611090006_comment_contract_type_uplift_tables.sql
--
-- OPEN_ITEMS.md item 188 point 3: "zero exposure, structurally" was a
-- correct measurement and a wrong state to leave it in. The function
-- (app.resolve_contract_type_uplift) already carries a COMMENT ON
-- FUNCTION saying it is built, correct, and unused on purpose
-- (202609240001) -- but the TWO TABLES it reads from carry no such
-- warning, and a table is what someone reading the schema actually lands
-- on first. contract_type_uplift is also the exact name of the thing
-- October's real mistake was about (the 11.1% PFA/SRL uplift, baked into
-- trainer_grade_rates instead of resolved separately) -- not a
-- hypothetical confusion, a recurrence of a real one.
--
-- DECIDED: comment, not drop. Checked first, per instruction: both tables
-- are read by a LIVE, working /payment-config UI section
-- (app/(app)/payment-config/page.tsx, payment-config-client.tsx's
-- ContractTypeUpliftsSection, actions.ts's
-- createContractTypeUpliftVersion), and asserted to stay EMPTY BY
-- DECISION by three live scripts/tests
-- (db/tests/grid_version_in_force.sql, scripts/verify_pay_grids_seed.sql,
-- scripts/verify_payment_config_grid_counts.sql) plus
-- app.resolve_contract_type_uplift itself, which 202609240001 already
-- decided to keep in place rather than drop ("dropping a working,
-- harmless resolver is a bigger and unrequested action"). Dropping the
-- tables would break all of that and require removing a whole UI
-- section nobody has asked to remove -- the identical "bigger and
-- unrequested action" 202609240001 already weighed, one layer down, on
-- the tables the kept function reads from rather than on the function
-- itself. Comment is the non-destructive option that still closes the
-- real gap: a human reading the TABLE, not only the function, now reads
-- the same warning.
--
-- WORTH NAMING, NOT BUILT HERE: the /payment-config UI gives no warning
-- on screen that filling this grid in does nothing -- the section looks
-- exactly as live as the other four. Filling it in today would not
-- change any session's pay (calculate_session_pay still never calls the
-- resolver), so this is not a financial risk the way the other three
-- grids' exposure is -- but it is a believability risk: the screen
-- itself argues against this comment's own warning. Left to Mihai to
-- decide whether the UI needs its own note; not decided or built here.

comment on table public.contract_type_uplift_versions is
  'Deliberately kept at zero rows. The 111-150 trainer_grade_rates grid (effective 2026-09-01) already has the 11.1% PFA/SRL uplift baked in (Anca, item 95) -- app.calculate_session_pay never calls app.resolve_contract_type_uplift, and must not, or the uplift doubles. A 0%-seeded row would look configured while being silently unreachable (item 92''s shape); staying empty is the honest signal. If the uplift ever needs to move OUT of trainer_grade_rates and become its own multiplier, that is a decision about calculate_session_pay''s own composition, not a row to add here first -- see app.resolve_contract_type_uplift''s own COMMENT ON FUNCTION, migration 202609240001, and OPEN_ITEMS.md items 95 and 188.';

comment on table public.contract_type_uplift_rates is
  'Deliberately kept at zero rows, same reason as contract_type_uplift_versions (see that table''s own COMMENT ON TABLE): the uplift this table would hold is already baked into trainer_grade_rates, and app.calculate_session_pay never reads this table. Do not seed it to "configure" the uplift -- it would sit unread. See migration 202609240001 and OPEN_ITEMS.md items 95 and 188.';
