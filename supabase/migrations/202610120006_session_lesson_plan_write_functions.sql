-- ============================================================================
-- The three write paths for session_lesson_plans, as SECURITY DEFINER routing
-- functions with disjoint column sets -- item 91's pattern, extended rather
-- than copied.
-- ============================================================================
--   app.rpc_propose_session_lesson_plan   trainer   -> lesson_plan_id, status
--   app.rpc_decide_session_lesson_plan    validator -> status, decided_*, note
--   app.rpc_mark_session_lesson_plan_seen trainer   -> decision_seen_at
--
-- authenticated holds no INSERT/UPDATE grant on the table at all, so these are
-- the only ways in. Three functions and not one because the callers are
-- disjoint and so are the columns: the trainer must never write `validated`,
-- the validator must never swap the plan, and "I have seen this" is the
-- trainer's act on a row the validator just wrote.

-- ---- 1. propose: the trainer picks their own experiment ----------------------
-- Upserts on (session_id, trainer_id) -- re-proposing updates in place and
-- CLEARS the previous decision, which is what makes a second verdict notify
-- again (decision_seen_at goes back to null alongside decided_at).
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

  -- Row match first, capability second -- same order and same two checks as
  -- app.rpc_update_session_attendance, so a revoked trainer loses this the
  -- moment they lose mywork.* (item 57: a bare row match with no capability
  -- check left a revoked trainer's write access outstanding indefinitely).
  if v_principal is distinct from v_me and v_secundar is distinct from v_me then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  -- The plan has to exist in the SAME organization. Checked here rather than
  -- left to the foreign key: the FK admits any organization's plan, and a
  -- cross-org proposal is exactly the shape item 107 records on `suppliers`.
  if not exists (
    select 1 from public.lesson_plans lp
    where lp.id = p_lesson_plan_id and lp.organization_id = v_org
  ) then
    return 'plan_not_found';
  end if;

  insert into public.session_lesson_plans
    (organization_id, session_id, trainer_id, lesson_plan_id, status)
  values (v_org, p_session_id, v_me, p_lesson_plan_id, 'proposed')
  on conflict (session_id, trainer_id) do update
    set lesson_plan_id = excluded.lesson_plan_id,
        status = 'proposed',
        decision_note = null,
        decided_by = null,
        decided_at = null,
        decision_seen_at = null;

  return 'ok';
end;
$$;

comment on function app.rpc_propose_session_lesson_plan(uuid, uuid) is
  'Item 117. The trainer''s own write: lesson_plan_id + status=''proposed'', own row only (row match on the session + mywork.*, the same pair app.rpc_update_session_attendance uses). Re-proposing clears decided_by/decided_at/decision_note/decision_seen_at, so a new verdict notifies again. NOT month-gated: proposing happens before delivery -- see app.rpc_decide_session_lesson_plan''s own note.';

-- ---- 2. decide: validate, or ask for changes --------------------------------
-- GATED ON app.has_capability('curriculum.validate', org) ALONE, and the
-- absence of the customary `app.is_platform_owner() or` branch is deliberate,
-- not an omission. Two independent reasons:
--
--   1. app.is_platform_owner() reads the users.is_platform_owner COLUMN, not
--      the platform_owner ROLE. For Anca -- who holds the platform_owner role
--      and owns this business -- that column is FALSE. A gate written on that
--      predicate alone would admit Mihai and refuse Anca.
--   2. app.has_capability() already ORs app.is_platform_owner() in itself, and
--      already expands wildcards, so the one clause below admits
--      curriculum_manager (curriculum.* -- Anka, Catalina), organization_owner
--      (Mihai), platform_owner (Anca) and the column flag if it is ever set.
--      An extra branch would be pure duplication.
--
-- Verified against the live role grants when this was written: exactly four
-- accounts hold it, and they are the four who should.
--
-- NOT MONTH-GATED, and this is the thing most likely to be broken by someone
-- extending this file. app.rpc_update_session_attendance -- the function this
-- one sits beside and is shaped after -- refuses when the session's month is
-- closed, because a trainer must not revise what they delivered after payroll
-- ran. Validation is the opposite case: it happens BEFORE delivery, it changes
-- no figure any payroll calculation reads, and blocking it on a closed month
-- would make a late-but-honest approval impossible while changing nothing
-- about pay. Do not copy the payroll_periods lookup into this function.
create or replace function app.rpc_decide_session_lesson_plan(
  p_row_id uuid,
  p_status text,
  p_note text
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if p_status not in ('validated', 'changes_requested') then
    return 'invalid_status';
  end if;

  select organization_id into v_org
  from public.session_lesson_plans
  where id = p_row_id;

  if v_org is null then
    return 'not_found';
  end if;

  if not app.has_capability('curriculum.validate', v_org) then
    return 'not_permitted';
  end if;

  -- Returned as its own code rather than left to the CHECK constraint, so the
  -- caller gets "say what to change" instead of a raw constraint-violation
  -- string. The CHECK stays as the backstop for any other write path.
  if p_status = 'changes_requested' and v_note is null then
    return 'note_required';
  end if;

  update public.session_lesson_plans
    set status = p_status,
        decision_note = v_note,
        decided_by = app.current_user_id(),
        decided_at = now(),
        -- A new decision is unseen by definition, including when it replaces
        -- an earlier one the trainer had already acknowledged.
        decision_seen_at = null
    where id = p_row_id;

  return 'ok';
end;
$$;

comment on function app.rpc_decide_session_lesson_plan(uuid, text, text) is
  'Item 117. Catalina''s write: status + decided_by/decided_at/decision_note. Gated on has_capability(''curriculum.validate'') ALONE -- no is_platform_owner() branch, because that predicate reads the users column (false for Anca, who holds the role) and because has_capability already ORs it in. decided_by is taken from app.current_user_id(), never from a parameter. DELIBERATELY NOT month-gated, unlike app.rpc_update_session_attendance beside it: validation precedes delivery and feeds no pay figure.';

-- ---- 3. mark seen: the trainer acknowledges the decision --------------------
create or replace function app.rpc_mark_session_lesson_plan_seen(
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
  v_decided timestamptz;
begin
  select organization_id, trainer_id, decided_at
    into v_org, v_trainer, v_decided
  from public.session_lesson_plans
  where id = p_row_id;

  if v_org is null then
    return 'not_found';
  end if;

  -- Own row only, even though the SELECT policy lets a co-trainer READ this
  -- row: seeing your co-trainer's verdict is coordination, marking it seen on
  -- their behalf is not.
  if v_trainer is distinct from app.current_user_id() then
    return 'not_yours';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_yours';
  end if;

  if v_decided is null then
    return 'nothing_to_see';
  end if;

  update public.session_lesson_plans
    set decision_seen_at = now()
    where id = p_row_id;

  return 'ok';
end;
$$;

comment on function app.rpc_mark_session_lesson_plan_seen(uuid) is
  'Item 117. The trainer''s acknowledgement: decision_seen_at only, own row only, and only once a decision exists (nothing_to_see otherwise). This is the whole notification write path -- there is no notifications table.';

grant execute on function app.rpc_propose_session_lesson_plan(uuid, uuid) to authenticated;
grant execute on function app.rpc_decide_session_lesson_plan(uuid, text, text) to authenticated;
grant execute on function app.rpc_mark_session_lesson_plan_seen(uuid) to authenticated;

-- ============================================================================
-- PostgREST-exposed wrappers -- schema `app` is not in config.toml's [api]
-- schemas, so the app can only call these. Same shape as 202609220002.
-- ============================================================================
create or replace function public.rpc_propose_session_lesson_plan(p_session_id uuid, p_lesson_plan_id uuid)
returns text language sql security invoker set search_path = ''
as $$ select app.rpc_propose_session_lesson_plan(p_session_id, p_lesson_plan_id); $$;
comment on function public.rpc_propose_session_lesson_plan(uuid, uuid) is
  'PostgREST-exposed wrapper around app.rpc_propose_session_lesson_plan() (item 117). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_propose_session_lesson_plan(uuid, uuid) from public;
grant execute on function public.rpc_propose_session_lesson_plan(uuid, uuid) to authenticated;

create or replace function public.rpc_decide_session_lesson_plan(p_row_id uuid, p_status text, p_note text)
returns text language sql security invoker set search_path = ''
as $$ select app.rpc_decide_session_lesson_plan(p_row_id, p_status, p_note); $$;
comment on function public.rpc_decide_session_lesson_plan(uuid, text, text) is
  'PostgREST-exposed wrapper around app.rpc_decide_session_lesson_plan() (item 117). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_decide_session_lesson_plan(uuid, text, text) from public;
grant execute on function public.rpc_decide_session_lesson_plan(uuid, text, text) to authenticated;

create or replace function public.rpc_mark_session_lesson_plan_seen(p_row_id uuid)
returns text language sql security invoker set search_path = ''
as $$ select app.rpc_mark_session_lesson_plan_seen(p_row_id); $$;
comment on function public.rpc_mark_session_lesson_plan_seen(uuid) is
  'PostgREST-exposed wrapper around app.rpc_mark_session_lesson_plan_seen() (item 117). SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_mark_session_lesson_plan_seen(uuid) from public;
grant execute on function public.rpc_mark_session_lesson_plan_seen(uuid) to authenticated;
