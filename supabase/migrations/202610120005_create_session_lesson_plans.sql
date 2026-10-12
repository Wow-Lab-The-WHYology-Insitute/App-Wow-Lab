-- ============================================================================
-- session_lesson_plans: which plan each trainer delivers at a session, and
-- whether Catalina has validated it. Anca decided 2026-10-12 that validation
-- moves out of WhatsApp and into the app (item 117).
-- ============================================================================
-- THE LINK CARRIES A TRAINER, not just a plan, and that is the document's
-- requirement rather than a modelling preference. WOWLAB_Spec_Trainer_
-- Principal_Secundar.md: "La un atelier de o ora, care cuprinde doua
-- experimente, fiecare trainer este responsabil integral de propriul
-- experiment." Two experiments, one owner each. sessions.experiment_delivered
-- is a single text column that cannot say whose experiment it names, and both
-- trainers match the identical RLS branch, so today the second one to save
-- silently overwrites the first.
--
-- Per-trainer is also already the house shape: app.calculate_session_pay takes
-- (session_id, trainer_id) and raises for a trainer who was not on the
-- session, and sessions carries trainer_principal_confirmed_at /
-- trainer_secundar_confirmed_at as two separate columns for the same reason.
--
-- ============================================================================
-- ONE ROW PER (session, trainer) -- a narrowing of what was first reported
-- ============================================================================
-- The report that preceded this recommended `unique (session_id, trainer_id,
-- lesson_plan_id)` and no cap, so a two-hour workshop could carry more than
-- one experiment per trainer. That is incompatible with the thing that was
-- actually settled: a re-proposal UPDATES THE ROW IN PLACE and the attempt
-- history lives in row_history rather than in extra rows. Update-in-place
-- needs a stable address for "this trainer's experiment for this session", and
-- (session, trainer, plan) is not one -- changing the plan would insert
-- instead of update, and the old proposal would linger as a second row.
--
-- So the cap wins, and it is the document's own number: one experiment per
-- trainer per session, "propriul experiment", singular, throughout. The
-- speculative two-hour case is not evidence.
-- If a session ever genuinely needs two experiments from one trainer, THE
-- THING TO CHANGE IS THIS UNIQUE INDEX, and the shape to change it to is the
-- triple above.
create table public.session_lesson_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  trainer_id uuid not null references public.users(id),
  -- No ON DELETE action: removing a catalogue plan that a trainer has already
  -- proposed must fail loudly. 202610120004's rollback says the same from the
  -- other side.
  lesson_plan_id uuid not null references public.lesson_plans(id),
  status text not null default 'proposed',
  decision_note text,
  decided_by uuid references public.users(id),
  decided_at timestamptz,
  decision_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint session_lesson_plans_status_check
    check (status in ('proposed', 'validated', 'changes_requested')),

  -- "Changes requested" with no statement of what to change is the failure
  -- that sends people back to WhatsApp, which is the thing this table exists
  -- to replace. Enforced here rather than in the routing function because it
  -- is a property of the row, not of one write path.
  constraint session_lesson_plans_note_required_check
    check (status <> 'changes_requested' or decision_note is not null),

  -- A decision has a decider and a time, or it is not a decision. Keeps
  -- `proposed` clean too: a row that was decided and re-proposed must have its
  -- decision fields cleared, not left pointing at a stale verdict.
  constraint session_lesson_plans_decision_fields_check
    check (
      (status = 'proposed' and decided_by is null and decided_at is null and decision_note is null)
      or (status <> 'proposed' and decided_by is not null and decided_at is not null)
    ),

  -- Nothing can be "seen" before it was decided.
  constraint session_lesson_plans_seen_requires_decision_check
    check (decision_seen_at is null or decided_at is not null)
);

create unique index session_lesson_plans_session_trainer_key
  on public.session_lesson_plans (session_id, trainer_id);

create index session_lesson_plans_trainer_unseen_idx
  on public.session_lesson_plans (trainer_id)
  where decided_at is not null and decision_seen_at is null;

create index session_lesson_plans_plan_idx
  on public.session_lesson_plans (lesson_plan_id);

comment on table public.session_lesson_plans is
  'One row per (session, trainer): the plan that trainer will deliver, and its validation state. Replaces the WhatsApp round-trip the responsibilities document describes (item 117). A session delivered with no validation keeps its rows at status ''proposed'' -- the record of what was delivered never depends on a workflow step having completed.';
comment on column public.session_lesson_plans.status is
  'proposed | validated | changes_requested. THREE states, symmetric on both trainer slots. changes_requested exists because the document names the step explicitly, in the secundar''s own list: "Face eventualele modificari solicitate." It is NOT terminal -- the trainer picks again and the row returns to proposed. There is deliberately NO fourth value for "delivered without approval": those rows stay ''proposed'', which reads correctly and is countable (select count(*) ... where status = ''proposed'' and session_date < now()).';
comment on column public.session_lesson_plans.decision_seen_at is
  'When the trainer acknowledged the decision. This column IS the notification -- there is no notifications table, because this row already has exactly one addressee (its own trainer_id). Unseen is decided_at is not null and (decision_seen_at is null or decision_seen_at < decided_at); the comparison, rather than a boolean, is what makes a SECOND decision on the same row notify again after changes were requested and a new plan proposed. Both this column and decided_at were added with the table on purpose: adding them later has no correct backfill -- null re-notifies every trainer about every historical approval, created_at silently marks unseen things seen.';
comment on column public.session_lesson_plans.decision_note is
  'What Catalina asked to be changed. Required by CHECK when status is changes_requested, optional otherwise.';

-- ============================================================================
-- row_history, explicitly -- item 104's subject
-- ============================================================================
-- The trigger is per-table and a new table gets none by default. Without it,
-- "which plan did this trainer propose before the current one" has no answer
-- anywhere, because re-proposal updates the row in place. That is the whole
-- reason the attempt history can live outside this table rather than in extra
-- rows.
--
-- Note what it will and will not record, so nobody over-reads it later:
-- row_history_capture fires BEFORE DELETE OR UPDATE only, never on INSERT, so
-- the FIRST proposal leaves no history row -- its provenance is the row itself.
-- And actor_user_id comes from app.current_user_id(), which is populated for
-- every write through the routing functions below (all called by a signed-in
-- user) and null for anything done by a migration.
create trigger session_lesson_plans_row_history
  before delete or update on public.session_lesson_plans
  for each row execute function row_history_capture();

create trigger session_lesson_plans_set_updated_at
  before update on public.session_lesson_plans
  for each row execute function trigger_set_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================
alter table public.session_lesson_plans enable row level security;

-- A trainer sees EVERY row for a session they are on, not only their own --
-- also a requirement of the document rather than a convenience: the principal
-- "se coordoneaza cu Trainerul Secundar, astfel incat cele doua experimente sa
-- fie potrivite si coerente." They cannot make two experiments coherent
-- without seeing both. The WRITE path is still own-row-only; this is the read.
--
-- The nested session condition is the same shape groups' own mywork.* branch
-- already uses for this exact viewer/capability pair -- item 68's lesson: a
-- nested read whose condition differs from the joined table's own branch can
-- be silently narrowed to false.
create policy "authenticated select session_lesson_plans" on public.session_lesson_plans
  for select to authenticated
  using (
    (
      app.has_capability('mywork.*', organization_id)
      and exists (
        select 1 from public.sessions s
        where s.id = session_lesson_plans.session_id
          and (s.trainer_principal_id = app.current_user_id()
               or s.trainer_secundar_id = app.current_user_id())
      )
    )
    or app.has_capability('sessions.read', organization_id)
    or app.has_capability('curriculum.validate', organization_id)
  );

-- SELECT only. Every write goes through a SECURITY DEFINER routing function
-- (202610120006), per item 91 -- not because a policy could not express these
-- rules, but because the column sets are disjoint per caller and RLS restricts
-- rows, not columns: a WITH CHECK that admits a trainer's re-proposal would
-- also admit that trainer writing their own `validated`.
grant select on public.session_lesson_plans to authenticated;
