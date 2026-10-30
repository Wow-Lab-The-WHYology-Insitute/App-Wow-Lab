-- B1 (Mihai 2026-10-30): session_lesson_plans becomes one-to-MANY per
-- (session, trainer), accepted design, built as specified.
--
-- WHY: the 2025-2026 centraliser shows most Lycée sessions carrying TWO
-- experiments ("Filtration, the water cycle in nature / Oobleck",
-- "Orbeez on a hot pan & squeaky ball / Slime"). The old
-- UNIQUE(session_id, trainer_id) capped this at one, silently -- a
-- trainer who ran two experiments could only ever record the second.
--
-- THE SCHEMA CHANGE IS SMALL: the table already had the right three
-- columns (session_id, trainer_id, lesson_plan_id); only the unique
-- constraint needed to move from the first two to all three. No new
-- table.
--
-- `experiment_delivered` (sessions, free text) RETIRES -- not migrated,
-- because zero real sessions have ever had it filled in (confirmed live
-- before writing this). session_lesson_plans is now the single source
-- for "which experiments this session involves," used both before the
-- workshop (propose/validate, item 117) and after (delivered, below).
--
-- ===========================================================================
-- `delivered boolean not null default true` -- THE REASON LIVES HERE,
-- NOT ONLY IN THE REGISTER, PER MIHAI'S OWN INSTRUCTION.
-- ===========================================================================
-- A pre-checked box is an assertion nobody made (§21's own principle,
-- applied to a default instead of a label) -- unless the thing that makes
-- it true is already established by the time anyone could read it as a
-- claim. Here it is: by the time a row exists, EITHER it is still
-- `status = 'proposed'` (not decided, not yet anyone's business whether
-- it was delivered -- the default is inert, not a claim), OR it has been
-- `validated` (Cătălina already confirmed the PLAN is appropriate, before
-- the workshop). The actual event this flag is about -- did the trainer
-- deliver what they said they would -- becomes a live assertion only once
-- the SESSION ITSELF is confirmed (`trainer_principal_confirmed_at`/
-- `trainer_secundar_confirmed_at`), the one act this schema already
-- treats as personal and irreducible (§19). Until that confirmation
-- exists, `delivered = true` on this row is inherited state, not a
-- statement anyone is answerable for -- read it as meaningless on an
-- unconfirmed session, the exact same way the whole row already reads as
-- provisional while `trainer_principal_confirmed_at IS NULL`.
--
-- So: pre-checked is safe BECAUSE the only thing that would make it a lie
-- -- the workshop being over and having gone differently -- is exactly
-- the window where the trainer is already asked to look at this screen
-- (recording attendance) and can uncheck it. A trainer who never opens
-- that screen also never confirms the session, so nothing downstream ever
-- reads `delivered = true` as a fact about a workshop that happened --
-- it reads as a fact about a workshop that is still only scheduled,
-- which is what it already was.

-- A bare UNIQUE INDEX, not a table CONSTRAINT -- confirmed live before
-- writing this (it has no entry in pg_constraint), so DROP INDEX is the
-- right statement, not DROP CONSTRAINT.
drop index public.session_lesson_plans_session_trainer_key;
create unique index session_lesson_plans_session_trainer_plan_key
  on public.session_lesson_plans (session_id, trainer_id, lesson_plan_id);

alter table public.session_lesson_plans
  add column delivered boolean not null default true;

comment on column public.session_lesson_plans.delivered is
  'Pre-checked by default -- see this migration''s own header (202610300007) for why that is safe: the flag is only a real assertion once the SESSION ITSELF is confirmed, and an unconfirmed session already reads as provisional in full. Editable by the owning trainer via app.rpc_update_session_lesson_plan_delivered, same month-closed gate as attendance_count.';

-- ---------------------------------------------------------------------------
-- rpc_propose_session_lesson_plan: ADD a plan, never replace one. The old
-- body upserted on (session_id, trainer_id) -- replacing whatever plan was
-- there. Now each (session, trainer, plan) triple is independent; calling
-- this again with a DIFFERENT plan adds a second row, and calling it again
-- with the SAME plan is a harmless no-op (idempotent "propose this", not
-- an error).
-- ---------------------------------------------------------------------------
create or replace function app.rpc_propose_session_lesson_plan(
  p_session_id uuid,
  p_lesson_plan_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_principal uuid;
  v_secundar uuid;
  v_me uuid := app.current_user_id();
begin
  select organization_id, trainer_principal_id, trainer_secundar_id
    into v_org, v_principal, v_secundar
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  if v_principal is distinct from v_me and v_secundar is distinct from v_me then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  if not exists (
    select 1 from public.lesson_plans lp
    where lp.id = p_lesson_plan_id and lp.organization_id = v_org
  ) then
    return 'plan_not_found';
  end if;

  insert into public.session_lesson_plans
    (organization_id, session_id, trainer_id, lesson_plan_id, status)
  values (v_org, p_session_id, v_me, p_lesson_plan_id, 'proposed')
  on conflict (session_id, trainer_id, lesson_plan_id) do nothing;

  return 'ok';
end;
$$;

comment on function app.rpc_propose_session_lesson_plan(uuid, uuid) is
  'Item 117, re-pointed 2026-10-30 (item 179, B1) at the new one-to-many unique key: ADDS a plan rather than replacing whatever was there. Calling it again with the same plan is a harmless no-op; a DIFFERENT plan is a second, independent row. Row match + mywork.*, unchanged.';

-- ---------------------------------------------------------------------------
-- rpc_remove_session_lesson_plan: new. The trainer's own retraction --
-- "I am not doing this experiment after all." Allowed at any status,
-- same autonomy the confirmation Undo control already gives a trainer
-- over their own slot; Cătălina's validation applies to a specific plan
-- choice, and retracting that choice is the trainer's to make, not hers
-- to have locked.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_remove_session_lesson_plan(
  p_row_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_trainer uuid;
begin
  select organization_id, trainer_id into v_org, v_trainer
  from public.session_lesson_plans
  where id = p_row_id;

  if v_org is null then
    return 'not_found';
  end if;

  if v_trainer is distinct from app.current_user_id() then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  delete from public.session_lesson_plans where id = p_row_id;

  return 'ok';
end;
$$;

comment on function app.rpc_remove_session_lesson_plan(uuid) is
  'Item 179 (B1): the trainer''s own retraction of ONE proposed/validated plan. Own row only (trainer_id = caller + mywork.*). Allowed at any status -- the trainer''s authority over their own proposal, same shape as the confirmation Undo control.';

-- ---------------------------------------------------------------------------
-- rpc_update_session_lesson_plan_delivered: new. Same month-closed gate as
-- app.rpc_update_session_attendance, because this is the same kind of
-- fact -- what actually happened -- recorded alongside it.
-- ---------------------------------------------------------------------------
create or replace function app.rpc_update_session_lesson_plan_delivered(
  p_row_id uuid,
  p_delivered boolean
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_trainer uuid;
  v_session_id uuid;
  v_session_date date;
  v_month_closed boolean;
begin
  select organization_id, trainer_id, session_id into v_org, v_trainer, v_session_id
  from public.session_lesson_plans
  where id = p_row_id;

  if v_org is null then
    return 'not_found';
  end if;

  if v_trainer is distinct from app.current_user_id() then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  select session_date into v_session_date from public.sessions where id = v_session_id;

  select exists (
    select 1 from public.payroll_periods pp
    where pp.organization_id = v_org
      and pp.period = date_trunc('month', v_session_date::timestamptz)::date
      and pp.closed_at is not null
  ) into v_month_closed;

  if v_month_closed then
    return 'month_closed';
  end if;

  update public.session_lesson_plans set delivered = p_delivered where id = p_row_id;

  return 'ok';
end;
$$;

comment on function app.rpc_update_session_lesson_plan_delivered(uuid, boolean) is
  'Item 179 (B1): the trainer''s own correction of whether a proposed/validated plan was actually delivered. Own row + mywork.* + month-open, same shape as app.rpc_update_session_attendance -- this is the same kind of post-workshop fact, recorded alongside it.';

grant execute on function app.rpc_propose_session_lesson_plan(uuid, uuid) to authenticated;
grant execute on function app.rpc_remove_session_lesson_plan(uuid) to authenticated;
grant execute on function app.rpc_update_session_lesson_plan_delivered(uuid, boolean) to authenticated;

create or replace function public.rpc_remove_session_lesson_plan(p_row_id uuid)
returns text
language sql
set search_path = ''
as $$ select app.rpc_remove_session_lesson_plan(p_row_id); $$;
comment on function public.rpc_remove_session_lesson_plan(uuid) is
  'PostgREST-exposed wrapper around app.rpc_remove_session_lesson_plan() (item 179). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_remove_session_lesson_plan(uuid) from public;
grant execute on function public.rpc_remove_session_lesson_plan(uuid) to authenticated;

create or replace function public.rpc_update_session_lesson_plan_delivered(p_row_id uuid, p_delivered boolean)
returns text
language sql
set search_path = ''
as $$ select app.rpc_update_session_lesson_plan_delivered(p_row_id, p_delivered); $$;
comment on function public.rpc_update_session_lesson_plan_delivered(uuid, boolean) is
  'PostgREST-exposed wrapper around app.rpc_update_session_lesson_plan_delivered() (item 179). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_update_session_lesson_plan_delivered(uuid, boolean) from public;
grant execute on function public.rpc_update_session_lesson_plan_delivered(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Assertions.
-- ---------------------------------------------------------------------------
do $$
declare
  v_zero_experiment_delivered integer;
  v_new_unique boolean;
  v_old_unique boolean;
begin
  -- Scoped to wow-lab (the real org) specifically, matching what was
  -- actually verified before writing this migration -- a test-org
  -- fixture (Test Org B's own payroll-test row) does carry a leftover
  -- experiment_delivered string, and that is not this migration's
  -- business to clean up.
  select count(*) into v_zero_experiment_delivered
  from public.sessions s join public.organizations o on o.id = s.organization_id
  where o.slug = 'wow-lab' and s.experiment_delivered is not null;
  if v_zero_experiment_delivered <> 0 then
    raise exception 'session_lesson_plans_one_to_many: expected 0 real wow-lab sessions with experiment_delivered set (nothing to migrate), found %', v_zero_experiment_delivered;
  end if;

  select exists(select 1 from pg_indexes where indexname = 'session_lesson_plans_session_trainer_plan_key') into v_new_unique;
  select exists(select 1 from pg_indexes where indexname = 'session_lesson_plans_session_trainer_key') into v_old_unique;
  if not v_new_unique or v_old_unique then
    raise exception 'session_lesson_plans_one_to_many: unique constraint swap did not take (new=%, old still present=%)', v_new_unique, v_old_unique;
  end if;

  if to_regprocedure('app.rpc_remove_session_lesson_plan(uuid)') is null
     or to_regprocedure('app.rpc_update_session_lesson_plan_delivered(uuid, boolean)') is null then
    raise exception 'session_lesson_plans_one_to_many: a new function signature did not take';
  end if;

  raise notice 'session_lesson_plans_one_to_many: one session+trainer can now carry multiple plans; delivered defaults true per the reasoning in this migration''s own header; experiment_delivered retired with zero rows to migrate.';
end $$;
