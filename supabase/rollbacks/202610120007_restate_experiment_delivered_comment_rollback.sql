-- Rollback for 202610120007 -- restores 202608130001's original comment
-- verbatim. Pure documentation; no data, no schema.

comment on column public.sessions.experiment_delivered is
  'Free text for now (SAD §5) -- no FK to a lesson-plans table, since none exists yet as a real table in this app (mockup only).';
