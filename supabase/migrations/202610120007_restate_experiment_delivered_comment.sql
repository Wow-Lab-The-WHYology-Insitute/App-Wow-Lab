-- sessions.experiment_delivered keeps its column and changes its job.
--
-- Its comment has said, since 202608130001: "Free text for now (SAD §5) -- no
-- FK to a lesson-plans table, since none exists yet as a real table in this
-- app (mockup only)." That sentence stops being true with 202610120003.
--
-- The column is NOT dropped, and not parsed into links. Three reasons, in
-- order of weight:
--
--   1. A trainer will deliver something the catalogue cannot name. The
--      catalogue is a snapshot of a Google Sheet that keeps growing --
--      202610070001 recorded Mihai's own instruction that "new plans appearing
--      later is an update, not a reason to wait" -- and trainers improvise. A
--      selector with no escape hatch produces either a wrong link or a blank.
--   2. Dropping the fallback in the same migration that introduces its
--      replacement means the first bug in the selector leaves a trainer with
--      nowhere to record what they taught.
--   3. Parsing it into links would invent data. Three values exist in the whole
--      database, all in Test Org B: null, 'Vulcanul', 'Pasta de dinti a
--      elefantului'. Both non-null ones are Romanian titles matching no plan
--      filename, and the 11 strings 202610120004 rejected show exactly what
--      title-matching produces at scale.
--
-- What it becomes: the overflow field. If a session_lesson_plans row exists for
-- a trainer, the plan is the answer; this column is what was delivered when the
-- catalogue had no row for it.

comment on column public.sessions.experiment_delivered is
  'Free-text fallback for a delivery the catalogue cannot name. SUPERSEDED as the primary record by public.session_lesson_plans (202610120005), which carries one plan per trainer per session plus its validation state -- this column cannot express two experiments with two owners, and both trainers'' writes land on it through the same routing function, so the second to save overwrites the first. Kept on purpose, not pending deletion: a trainer will deliver something not in the catalogue, and this is where it goes. NEVER parse this column into session_lesson_plans rows -- see 202610120007 for why. Read order for a session''s delivered experiments: session_lesson_plans first, this column only when no row exists.';
