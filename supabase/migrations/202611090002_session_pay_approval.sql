-- Approval, built per Anca's own answer today, 2026-11-09, reconciled
-- against item 185's own measurement of what already existed (payroll
-- gate capabilities, the month close, the confirmation columns) rather
-- than built in parallel to it.
--
-- ===========================================================================
-- THE REAL PROCESS, Anca's own words, item 184/185's own correction
-- ===========================================================================
-- "Trainerul trece [ca s-a tinut atelierul]. Catalina SAU Anca aproba."
-- Approval AUTHORIZES the amount that resulted from confirmation; it does
-- not recompute or change it. Unapproved stays unpayable. This is NOT a
-- replacement for the trainer's own confirmation (item 184's first
-- framing of "maybe the real process never asks trainers to confirm" was
-- the same error shape flagged against the Scoala Altfel/entity-on-session
-- argument, in the other direction: two additive facts -- the trainer
-- model is correct AND a step is missing -- read as mutually exclusive.
-- Both are true. Zero self-confirmations stays a real, unresolved
-- problem; this migration gives the missing step a mechanism, it does
-- not explain the first one away.
--
-- ===========================================================================
-- THE APPROVER IS A CAPABILITY, NOT A ROLE -- Cătălina is the proof
-- ===========================================================================
-- "Aprobatorul e definit prin capabilitate, nu prin rol: Catalina e trainer
-- si aproba." Checked live before writing this: Cătălina holds Operations
-- Manager + Trainer (+ Evaluator + Curriculum Manager), and Operations
-- Manager holds neither finance.operations.* nor finance.reporting.* --
-- she could not have passed either existing finance gate. A model that
-- gated approval on "not a trainer" would have refused her by
-- construction, which is exactly the shape Mihai named as wrong.
--
-- So this is a NEW, narrow capability -- finance.approvals.approve --
-- granted to Operations Manager (which is how Cătălina gets it), checked
-- alongside the existing finance.operations.* / org.settings.manage /
-- platform-owner branches so Anca, Anka, Laura and the owner account keep
-- exactly the reach they already had. Not folded into finance.operations.*
-- itself: that wildcard also grants closing the whole month and writing
-- contract financials, neither of which this capability is about.
--
-- ===========================================================================
-- THE MEASUREMENT THAT DECIDED FREEZING THE AMOUNT
-- ===========================================================================
-- Asked: can app.calculate_session_pay reproduce a session's amount after
-- its grid is RESTATED (not a new dated version -- an in-place correction,
-- like 202610300001's own UPDATE of trainer_grade_rates.rate on the
-- EXISTING version_id)? trainer_grade_rates carries no date of its own --
-- only version_id + grade_level + rate; all date resolution lives on
-- trainer_grade_versions.effective_date, one level up. A restatement that
-- mutates rate on an existing version_id therefore changes the resolved
-- answer for EVERY date mapped to that version, past included -- which is
-- the exact mechanism 202610200001's 100-135 regression and 202610300001's
-- 111-150 restoration both went through. So: NO, the live calculation
-- cannot be trusted to reproduce a past amount after such a restatement.
-- Approval MUST store the amount it authorizes, not a pointer to recompute
-- later -- per Mihai's own stated rule for this exact measurement.
--
-- ===========================================================================
-- WHO APPROVED -- NOT A NEW COLUMN, ROW_HISTORY, SAME AS CONFIRMATION
-- ===========================================================================
-- "Se inregistreaza cine a aprobat, cand, si care suma a fost aprobata."
-- WHEN and WHAT AMOUNT are first-class columns (needed for payroll's own
-- read path, which cannot reliably derive them from row_history). WHO is
-- deliberately NOT a redundant column -- trainer_principal_confirmed_at
-- already records "when" with "who" living only in row_history.actor_user_id
-- (§19/§23), and this follows the identical shape rather than inventing a
-- second mechanism for the same kind of fact.
--
-- ===========================================================================
-- BULK, ON PURPOSE -- DECIDED, NOT ASKED
-- ===========================================================================
-- "O actiune in bloc in interfata scrie multe aprobari pe sesiune - asta
-- am decis, nu o intreb." app.rpc_approve_session_pay takes an ARRAY of
-- session ids and approves whichever of each session's two slots is
-- currently confirmed and not yet approved -- no slot parameter, because
-- approval acts on whatever confirmation already produced, automatically,
-- never on a slot the caller has to name.
--
-- NOT BUILT HERE, by explicit instruction: withdrawing an approval, and a
-- four-eyes rule. Both are Mihai's own open questions for Anca, not design
-- decisions made on her behalf.

insert into public.capabilities (key, domain, resource, action, description)
values
  ('finance.approvals.approve', 'finance', 'approvals', 'approve', 'Approve a confirmed session''s pay, authorizing the amount that resulted from the trainer''s own confirmation -- does not recompute or change it. Distinct from finance.operations.* (which also closes the month and writes contract financials) so it can be granted narrowly to a capability-holder who is also a trainer.')
on conflict (key) do update
  set domain = excluded.domain,
      resource = excluded.resource,
      action = excluded.action,
      description = excluded.description,
      updated_at = now();

insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (values ('operations_manager', 'finance.approvals.approve')) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;

alter table public.sessions
  add column trainer_principal_approved_at timestamptz,
  add column trainer_principal_approved_amount_bani integer,
  add column trainer_secundar_approved_at timestamptz,
  add column trainer_secundar_approved_amount_bani integer;

alter table public.sessions
  add constraint sessions_principal_approval_amount_paired_check
    check ((trainer_principal_approved_at is null) = (trainer_principal_approved_amount_bani is null)),
  add constraint sessions_secundar_approval_amount_paired_check
    check ((trainer_secundar_approved_at is null) = (trainer_secundar_approved_amount_bani is null)),
  add constraint sessions_principal_approval_needs_confirmation_check
    check (trainer_principal_approved_at is null or trainer_principal_confirmed_at is not null),
  add constraint sessions_secundar_approval_needs_confirmation_check
    check (trainer_secundar_approved_at is null or trainer_secundar_confirmed_at is not null),
  add constraint sessions_principal_approved_amount_nonnegative_check
    check (trainer_principal_approved_amount_bani is null or trainer_principal_approved_amount_bani >= 0),
  add constraint sessions_secundar_approved_amount_nonnegative_check
    check (trainer_secundar_approved_amount_bani is null or trainer_secundar_approved_amount_bani >= 0);

comment on column public.sessions.trainer_principal_approved_at is 'When the principal slot''s confirmed pay was approved -- authorizes trainer_principal_approved_amount_bani, does not recompute it. Null until app.rpc_approve_session_pay writes it. Who approved lives in row_history.actor_user_id (§19/§23), not a column here, matching trainer_principal_confirmed_at''s own shape.';
comment on column public.sessions.trainer_principal_approved_amount_bani is 'The amount, in bani, FROZEN at approval time from app.calculate_session_pay -- not recomputed live, because a grid restatement (in place, not a new dated version -- e.g. 202610300001) changes the resolved answer for every date mapped to that version, past included. Null iff trainer_principal_approved_at is null.';
comment on column public.sessions.trainer_secundar_approved_at is 'Same shape as trainer_principal_approved_at, for the secundar slot.';
comment on column public.sessions.trainer_secundar_approved_amount_bani is 'Same shape as trainer_principal_approved_amount_bani, for the secundar slot.';

create or replace function app.rpc_approve_session_pay(p_session_ids uuid[])
returns table (session_id uuid, slot text, status text, amount_bani integer)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
  v_org uuid;
  v_principal_id uuid;
  v_secundar_id uuid;
  v_principal_confirmed timestamptz;
  v_secundar_confirmed timestamptz;
  v_principal_approved timestamptz;
  v_secundar_approved timestamptz;
  v_principal_approved_amount integer;
  v_secundar_approved_amount integer;
  v_permitted boolean;
  v_amount numeric;
  v_new_principal_approved timestamptz;
  v_new_principal_amount integer;
  v_principal_status text;
  v_new_secundar_approved timestamptz;
  v_new_secundar_amount integer;
  v_secundar_status text;
begin
  foreach v_id in array p_session_ids loop
    select organization_id, trainer_principal_id, trainer_secundar_id,
           trainer_principal_confirmed_at, trainer_secundar_confirmed_at,
           trainer_principal_approved_at, trainer_secundar_approved_at,
           trainer_principal_approved_amount_bani, trainer_secundar_approved_amount_bani
      into v_org, v_principal_id, v_secundar_id,
           v_principal_confirmed, v_secundar_confirmed,
           v_principal_approved, v_secundar_approved,
           v_principal_approved_amount, v_secundar_approved_amount
    from public.sessions where id = v_id;

    if v_org is null then
      session_id := v_id; slot := null; status := 'not_found'; amount_bani := null;
      return next;
      continue;
    end if;

    v_permitted := (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', v_org)
      or app.has_capability('finance.operations.*', v_org)
      or app.has_capability('finance.approvals.approve', v_org)
    );
    if not v_permitted then
      session_id := v_id; slot := null; status := 'not_permitted'; amount_bani := null;
      return next;
      continue;
    end if;

    v_new_principal_approved := v_principal_approved;
    v_new_principal_amount := v_principal_approved_amount;
    if v_principal_id is null then
      v_principal_status := null;
    elsif v_principal_approved is not null then
      v_principal_status := 'already_approved';
    elsif v_principal_confirmed is null then
      v_principal_status := 'not_confirmed';
    else
      begin
        v_amount := round(app.calculate_session_pay(v_id, v_principal_id) * 100);
        v_new_principal_approved := now();
        v_new_principal_amount := v_amount;
        v_principal_status := 'approved';
      exception when others then
        v_principal_status := 'error: ' || sqlerrm;
      end;
    end if;

    v_new_secundar_approved := v_secundar_approved;
    v_new_secundar_amount := v_secundar_approved_amount;
    if v_secundar_id is null then
      v_secundar_status := null;
    elsif v_secundar_approved is not null then
      v_secundar_status := 'already_approved';
    elsif v_secundar_confirmed is null then
      v_secundar_status := 'not_confirmed';
    else
      begin
        v_amount := round(app.calculate_session_pay(v_id, v_secundar_id) * 100);
        v_new_secundar_approved := now();
        v_new_secundar_amount := v_amount;
        v_secundar_status := 'approved';
      exception when others then
        v_secundar_status := 'error: ' || sqlerrm;
      end;
    end if;

    -- One UPDATE for both slots, so a session with both eligible produces
    -- one row_history entry, not two -- same reasoning rpc_correct_session_
    -- confirmation already applies to the confirmed_at pair.
    if v_principal_status = 'approved' or v_secundar_status = 'approved' then
      update public.sessions
        set trainer_principal_approved_at = v_new_principal_approved,
            trainer_principal_approved_amount_bani = v_new_principal_amount,
            trainer_secundar_approved_at = v_new_secundar_approved,
            trainer_secundar_approved_amount_bani = v_new_secundar_amount
        where id = v_id;
    end if;

    if v_principal_status is not null then
      session_id := v_id; slot := 'principal'; status := v_principal_status;
      amount_bani := case when v_principal_status in ('approved', 'already_approved') then v_new_principal_amount else null end;
      return next;
    end if;

    if v_secundar_status is not null then
      session_id := v_id; slot := 'secundar'; status := v_secundar_status;
      amount_bani := case when v_secundar_status in ('approved', 'already_approved') then v_new_secundar_amount else null end;
      return next;
    end if;
  end loop;
end;
$$;

comment on function app.rpc_approve_session_pay(uuid[]) is 'Approves whichever of each session''s two pay slots is confirmed and not yet approved, freezing the amount from app.calculate_session_pay at approval time (grids can be restated in place -- the frozen amount is the authorized one regardless of later restatements). Gate: is_platform_owner() OR org.settings.manage OR finance.operations.* OR finance.approvals.approve (Cătălina''s own path, Operations Manager, not a finance role -- the approver is a capability, not a role). Does not recompute or alter the amount; authorizes it. Bulk by design (an array of session ids, no slot parameter) -- a single UI action approves everything eligible. Does not support withdrawing an approval or a four-eyes rule; neither is built. Item 185/186.';

revoke all on function app.rpc_approve_session_pay(uuid[]) from public;
grant execute on function app.rpc_approve_session_pay(uuid[]) to authenticated;

create or replace function public.rpc_approve_session_pay(p_session_ids uuid[])
returns table (session_id uuid, slot text, status text, amount_bani integer)
language sql
security invoker
set search_path = ''
as $$
  select * from app.rpc_approve_session_pay(p_session_ids);
$$;
comment on function public.rpc_approve_session_pay(uuid[]) is 'PostgREST-exposed wrapper around app.rpc_approve_session_pay() -- the app schema itself is not exposed via the Data API. SECURITY INVOKER, forwarding only.';
revoke all on function public.rpc_approve_session_pay(uuid[]) from public;
grant execute on function public.rpc_approve_session_pay(uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- Assertions.
-- ---------------------------------------------------------------------------
do $$
declare
  v_cap_id uuid;
  v_grant_exists boolean;
  v_n integer;
begin
  select id into v_cap_id from public.capabilities where key = 'finance.approvals.approve';
  if v_cap_id is null then
    raise exception 'session-pay-approval: capability finance.approvals.approve was not created';
  end if;

  select exists (
    select 1 from public.role_capabilities rc
    join public.roles r on r.id = rc.role_id
    where r.key = 'operations_manager' and rc.capability_id = v_cap_id
  ) into v_grant_exists;
  if not v_grant_exists then
    raise exception 'session-pay-approval: operations_manager was not granted finance.approvals.approve';
  end if;

  select count(*) into v_n from information_schema.columns
  where table_schema = 'public' and table_name = 'sessions'
    and column_name in ('trainer_principal_approved_at', 'trainer_principal_approved_amount_bani',
                         'trainer_secundar_approved_at', 'trainer_secundar_approved_amount_bani');
  if v_n <> 4 then
    raise exception 'session-pay-approval: expected 4 new columns on sessions, found %', v_n;
  end if;

  raise notice 'session-pay-approval: capability + grant + columns all in place. RPC behavior exercised in db/tests/session_pay_approval.sql.';
end $$;
