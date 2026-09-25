-- OPEN_ITEMS.md item 91 (built same-day as the finding): column narrowing
-- for sessions/contracts/groups lived ONLY in server action TypeScript.
-- RLS is row-level only (Postgres has no per-row column privilege
-- concept) and every column-level GRANT in this codebase's history is
-- SELECT-only (confirmed by grep across every migration) -- UPDATE/INSERT
-- have always been table-wide for `authenticated`. Confirmed live,
-- 2026-09-22, in WOW LAB Test Org B, not assumed: a trainer, using their
-- own real session cookie (non-httpOnly per @supabase/ssr's own
-- DEFAULT_COOKIE_OPTIONS) and the public anon key, issued a raw PATCH to
-- /rest/v1/sessions and successfully set their CO-TRAINER's
-- trainer_secundar_confirmed_at -- the exact field pay is keyed on
-- (202609150002's own header: "Pay follows this timestamp, not
-- attendance_count or status") -- entirely bypassing
-- confirmSessionAttendance.
--
-- Fix, as decided: revoke the table-level (sessions) or column-level
-- (contracts, groups) write grant from `authenticated` entirely, and
-- route every write that needs to narrow columns by caller identity/
-- capability through a SECURITY DEFINER function that re-checks, inside
-- itself, everything RLS and the action checked before. A SECURITY
-- DEFINER function bypasses RLS by construction (it executes as its
-- OWNER for table-privilege purposes) -- a forgotten check here is a
-- privilege escalation, not a bug, so every check below is a literal,
-- deliberate restatement of what the TypeScript action it replaces
-- already did, not a redesign. Scope: sessions gets every UPDATE path
-- (4 actions); contracts gets its 3 financial columns only (INSERT +
-- UPDATE); groups gets children_confirmed only (UPDATE -- addGroup never
-- set it at INSERT, confirmed by reading it, so INSERT was already safe
-- for this one column, but revoked too for the identical class of gap
-- addSession has on sessions, item 91's own report on that).
-- external_crm_ref (clients) and status_override (clients) are
-- explicitly NOT touched this round -- both currently non-discriminating
-- (same roles hold the narrower and the broader capability today),
-- recorded as open, not fixed here.

-- ============================================================================
-- 1. app_write_owner -- a dedicated role for these functions, separate
-- from app_masking_owner (that one exists for SELECT-side masking; this
-- one performs writes -- distinct blast radius, kept distinct on
-- purpose, not merged for convenience). Same recipe as app_masking_owner
-- (202608190001), same reasoning: NOLOGIN (never a session identity,
-- only ever a function owner), NOBYPASSRLS (postgres has BYPASSRLS in
-- this project despite not being a superuser -- a function owned by
-- postgres would skip org isolation entirely; this role must not repeat
-- that), INHERIT + member of authenticated (a NOINHERIT member does not
-- satisfy `TO authenticated` policies -- confirmed by that same prior
-- migration's own trap -- so this role's own SELECT reads, evaluated
-- under sessions'/contracts'/groups' existing RLS via has_capability()/
-- current_user_id() reading the REAL caller's session-level JWT
-- (unaffected by SECURITY DEFINER's role switch), correctly reproduce
-- the real caller's own visibility, not the owner's).
create role app_write_owner with nologin nobypassrls inherit;
grant authenticated to app_write_owner;
grant usage on schema app to app_write_owner;

comment on role app_write_owner is 'Owner of the SECURITY DEFINER write-routing functions in schema app (item 91). NOLOGIN/NOBYPASSRLS/INHERIT, member of authenticated -- exists so these functions can write columns authenticated no longer has a direct grant for, while every read they perform still respects the real caller''s own RLS visibility via has_capability()/current_user_id() (session-level, unaffected by the role switch). Never grant this role LOGIN or BYPASSRLS.';

-- ============================================================================
-- 2. SESSIONS -- revoke table-level UPDATE from authenticated entirely.
-- Every one of the 4 write actions becomes an RPC. app_write_owner gets
-- its own direct UPDATE grant (NOT inherited from authenticated, which
-- now has none) -- the function's own code, not any grant, is what
-- narrows which columns a given call actually touches.
-- ============================================================================
revoke update on public.sessions from authenticated;
grant update on public.sessions to app_write_owner;

-- ---- 2a. updateSessionAllocation -- reassign trainer_principal_id/trainer_secundar_id.
-- Matches the action's own stated intent ("requires Operations Manager or
-- Master") exactly, NOT the full breadth sessions' current UPDATE policy
-- technically admits (which also includes finance.operations.* and any
-- row-matched trainer) -- the action never explicitly checked a
-- capability before, relying solely on RLS's row admission, so its real
-- boundary was never actually audited until now. Since this becomes the
-- ONLY write path, narrowing to the action's own documented intent is
-- the safe direction to resolve that ambiguity, not the permissive one.
create or replace function app.rpc_update_session_allocation(
  p_session_id uuid,
  p_trainer_principal_id uuid,
  p_trainer_secundar_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
begin
  select organization_id into v_org from public.sessions where id = p_session_id;
  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('sessions.create', v_org)
  ) then
    return 'not_permitted';
  end if;

  update public.sessions
    set trainer_principal_id = p_trainer_principal_id,
        trainer_secundar_id = p_trainer_secundar_id
    where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_update_session_allocation(uuid, uuid, uuid) is 'Item 91. Replaces updateSessionAllocation''s direct .update() -- authenticated no longer has table-level UPDATE on sessions. Writes ONLY trainer_principal_id/trainer_secundar_id. Gate: is_platform_owner() OR org.settings.manage OR sessions.create -- matches the action''s own error message ("requires Operations Manager or Master"), narrower than what sessions'' UPDATE policy technically used to admit (finance.operations.*, row-matched trainers) since that breadth was never actually intended, only never checked.';

-- ---- 2b. updateSessionAttendance -- attendance_count + experiment_delivered, own row only.
create or replace function app.rpc_update_session_attendance(
  p_session_id uuid,
  p_attendance_count int,
  p_experiment_delivered text
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_session_date date;
  v_principal uuid;
  v_secundar uuid;
  v_month_closed boolean;
begin
  select organization_id, session_date, trainer_principal_id, trainer_secundar_id
    into v_org, v_session_date, v_principal, v_secundar
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  if v_principal is distinct from app.current_user_id() and v_secundar is distinct from app.current_user_id() then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  select exists (
    select 1 from public.payroll_periods pp
    where pp.organization_id = v_org
      and pp.period = date_trunc('month', v_session_date::timestamptz)::date
      and pp.closed_at is not null
  ) into v_month_closed;

  if v_month_closed then
    return 'month_closed';
  end if;

  update public.sessions
    set attendance_count = p_attendance_count,
        experiment_delivered = p_experiment_delivered
    where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_update_session_attendance(uuid, int, text) is 'Item 91. Replaces updateSessionAttendance''s direct .update(). Writes ONLY attendance_count/experiment_delivered. Row match (caller is trainer_principal_id or trainer_secundar_id) + mywork.* + month-open, exactly the RLS branch (202609110004) and the action''s own pre-checks this replaces -- re-stated here, not redesigned.';

-- ---- 2c. confirmSessionAttendance -- the exact function this whole item exists for.
create or replace function app.rpc_confirm_session_attendance(
  p_session_id uuid,
  p_confirmed boolean
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
  v_session_date date;
  v_principal uuid;
  v_secundar uuid;
  v_is_principal boolean;
  v_is_secundar boolean;
  v_month_closed boolean;
begin
  select organization_id, session_date, trainer_principal_id, trainer_secundar_id
    into v_org, v_session_date, v_principal, v_secundar
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    return 'not_found';
  end if;

  v_is_principal := (v_principal = app.current_user_id());
  v_is_secundar := (v_secundar = app.current_user_id());
  if not v_is_principal and not v_is_secundar then
    return 'not_assigned';
  end if;

  if not app.has_capability('mywork.*', v_org) then
    return 'not_assigned';
  end if;

  select exists (
    select 1 from public.payroll_periods pp
    where pp.organization_id = v_org
      and pp.period = date_trunc('month', v_session_date::timestamptz)::date
      and pp.closed_at is not null
  ) into v_month_closed;

  if v_month_closed then
    return 'month_closed';
  end if;

  -- The column narrowing THE WHOLE ITEM IS ABOUT: exactly one of the two
  -- columns, chosen by which slot the CALLER (not the target) holds --
  -- never both, never writable for the caller's own non-slot regardless
  -- of what a raw request's body says (there is no p_column parameter at
  -- all -- the caller cannot even ASK for the other slot's column, unlike
  -- the TypeScript action, which could only be trusted not to construct
  -- that payload, not prevented from it).
  if v_is_principal then
    update public.sessions
      set trainer_principal_confirmed_at = case when p_confirmed then now() else null end
      where id = p_session_id;
  else
    update public.sessions
      set trainer_secundar_confirmed_at = case when p_confirmed then now() else null end
      where id = p_session_id;
  end if;

  return 'ok';
end;
$$;

comment on function app.rpc_confirm_session_attendance(uuid, boolean) is 'Item 91. Replaces confirmSessionAttendance''s direct .update() -- the exact write a live test confirmed bypassable via raw PostgREST PATCH on 2026-09-22 (a principal setting trainer_secundar_confirmed_at directly). Writes ONLY the caller''s OWN slot''s confirmation column -- which one is resolved from the row + app.current_user_id(), never from a caller-supplied parameter, so there is no input that can select the other trainer''s column.';

-- ---- 2d. correctSessionConfirmation -- finance.operations.*'s correction path.
create or replace function app.rpc_correct_session_confirmation(
  p_session_id uuid,
  p_principal_confirmed boolean,
  p_secundar_confirmed boolean
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
begin
  select organization_id into v_org from public.sessions where id = p_session_id;
  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('finance.operations.*', v_org)
  ) then
    return 'not_permitted';
  end if;

  update public.sessions
    set trainer_principal_confirmed_at = case when p_principal_confirmed then now() else null end,
        trainer_secundar_confirmed_at = case when p_secundar_confirmed then now() else null end
    where id = p_session_id;

  return 'ok';
end;
$$;

comment on function app.rpc_correct_session_confirmation(uuid, boolean, boolean) is 'Item 91. Replaces correctSessionConfirmation''s direct .update(). Gate: is_platform_owner() OR org.settings.manage OR finance.operations.* -- the action''s own explicit check, restated verbatim, not RLS''s broader unconditional finance.operations.* branch (which, before this migration, admitted this same caller to write attendance_count/status/trainer assignment on ANY session via a raw request -- item 91''s own report).';

grant execute on function app.rpc_update_session_allocation(uuid, uuid, uuid) to authenticated;
grant execute on function app.rpc_update_session_attendance(uuid, int, text) to authenticated;
grant execute on function app.rpc_confirm_session_attendance(uuid, boolean) to authenticated;
grant execute on function app.rpc_correct_session_confirmation(uuid, boolean, boolean) to authenticated;

-- ============================================================================
-- 3. CONTRACTS -- column-level revoke on the 3 financial fields only
-- (INSERT and UPDATE). Every other column on contracts is unaffected --
-- contract_administrator keeps writing everything else exactly as
-- before, through the existing direct RLS-gated path (addContract/
-- updateContract, untouched for every field but these three).
-- ============================================================================
revoke update (billing_rule, estimated_value, previous_year_value) on public.contracts from authenticated;
revoke insert (billing_rule, estimated_value, previous_year_value) on public.contracts from authenticated;
grant update (billing_rule, estimated_value, previous_year_value) on public.contracts to app_write_owner;
grant insert (billing_rule, estimated_value, previous_year_value) on public.contracts to app_write_owner;

create or replace function app.rpc_set_contract_financials(
  p_contract_id uuid,
  p_billing_rule text,
  p_estimated_value numeric,
  p_previous_year_value numeric
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
begin
  select organization_id into v_org from public.contracts where id = p_contract_id;
  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.has_capability('finance.operations.*', v_org)
    or app.has_capability('finance.reporting.*', v_org)
    or app.has_capability('clients.create', v_org)
  ) then
    return 'not_permitted';
  end if;

  update public.contracts
    set billing_rule = p_billing_rule,
        estimated_value = p_estimated_value,
        previous_year_value = p_previous_year_value
    where id = p_contract_id;

  return 'ok';
end;
$$;

comment on function app.rpc_set_contract_financials(uuid, text, numeric, numeric) is 'Item 91. Only writer of contracts.billing_rule/estimated_value/previous_year_value -- authenticated''s column-level INSERT/UPDATE grant on these three is revoked. Gate: finance.operations.* OR finance.reporting.* OR clients.create -- addContract/updateContract''s own existing financeVisible check, restated verbatim. Before this migration a contract_administrator (contracts.*, none of the three) could set these directly despite never being able to read them back through contracts_billing_masked -- confirmed as a real, not hypothetical, gap by both actions'' own prior comments.';

grant execute on function app.rpc_set_contract_financials(uuid, text, numeric, numeric) to authenticated;

-- ============================================================================
-- 4. GROUPS -- children_confirmed, INSERT and UPDATE. addGroup never set
-- it at creation (confirmed by reading it) so INSERT revoke changes
-- nothing addGroup does today -- revoked anyway, closing the identical
-- class of gap item 91's report named for addSession (a raw INSERT
-- setting a column no existing action-level INSERT payload exposes).
-- ============================================================================
revoke update (children_confirmed) on public.groups from authenticated;
revoke insert (children_confirmed) on public.groups from authenticated;
grant update (children_confirmed) on public.groups to app_write_owner;
grant insert (children_confirmed) on public.groups to app_write_owner;

create or replace function app.rpc_set_group_children_confirmed(
  p_group_id uuid,
  p_children_confirmed int
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org uuid;
begin
  select organization_id into v_org from public.groups where id = p_group_id;
  if v_org is null then
    return 'not_found';
  end if;

  if not (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', v_org)
    or app.has_capability('contracts.*', v_org)
  ) then
    return 'not_permitted';
  end if;

  update public.groups
    set children_confirmed = p_children_confirmed
    where id = p_group_id;

  return 'ok';
end;
$$;

comment on function app.rpc_set_group_children_confirmed(uuid, int) is 'Item 91. Only writer of groups.children_confirmed -- authenticated''s column-level INSERT/UPDATE grant is revoked. Gate: is_platform_owner() OR org.settings.manage OR contracts.* -- updateGroup''s own existing canWriteChildrenConfirmed check, restated verbatim (Anca''s 2026-09-11 decision: contract_administrator enters this, operations_manager sees but does not fill it).';

grant execute on function app.rpc_set_group_children_confirmed(uuid, int) to authenticated;
