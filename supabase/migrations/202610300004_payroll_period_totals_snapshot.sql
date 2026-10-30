-- The month-close snapshot (B2, Mihai 2026-10-30), form (c) with the
-- addition he asked for: "the month changed since closing" is not useful
-- without "changed FROM WHAT."
--
-- ===========================================================================
-- WHAT THIS IS: one row per (period, trainer, entity), written ONCE, at
-- close time, never again.
-- ===========================================================================
-- amount_bani = the PAYABLE total (confirmed sessions only, never pending)
-- PLUS the trainer-principal bonus (item 175) for that period/trainer/
-- entity, exactly what /payroll's own sums block would have shown that
-- trainer for that entity at the moment of closing.
--
-- `legal_entity_id` is nullable -- the same "payable but unattributable"
-- state /payroll's own `entityOfGroup` already has (item 169, a group with
-- no contract). Not distinguished from "entity unreadable" here: closing a
-- month requires finance.operations.*/org.settings.manage, which already
-- reads the grids and the entities in full, so "unreadable" cannot occur
-- for whoever is actually closing.
--
-- ===========================================================================
-- WHY THIS IS NOT A LEDGER -- THE BOUNDARY MIHAI ASKED BE WRITTEN, NOT
-- PRESUMED
-- ===========================================================================
--   * ONE ROW PER (period, trainer, entity) -- never per workshop. It
--     cannot answer "which sessions make up this total" or "what did THIS
--     workshop pay" -- only app.calculate_org_session_pay can, live, and
--     still does.
--   * WRITTEN ONCE, AT CLOSE, NEVER UPDATED, NEVER READ BY ANY WRITE PATH.
--     Nothing in this application ever computes what to pay someone FROM
--     this table -- /payroll always computes live, for every month,
--     closed or not. This table is read-only input to a COMPARISON
--     banner, never an input to a payment decision.
--   * THE BOUNDARY, STATED SO IT CAN BE CHECKED RATHER THAN ASSUMED: the
--     day any code path reads `payroll_period_totals` to decide what
--     to pay a trainer -- instead of to show "closed at X, now shows Y" --
--     is the day this table became a ledger by misuse. Nothing here does
--     that today, and this comment is what the next reader checks it
--     against.
--
-- RLS mirrors payroll_periods exactly -- same capability set, SELECT also
-- open to mywork.* (a trainer reading their OWN row only, same shape
-- payroll_periods itself already grants), INSERT restricted to the same
-- three capabilities and to inserting one's own `closed_by`-equivalent
-- actor fact implicitly (the row's existence is gated by the SAME
-- transaction that writes payroll_periods.closed_by, in
-- closePayrollPeriod -- see that action).

create table public.payroll_period_totals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  payroll_period_id uuid not null references public.payroll_periods(id),
  trainer_id uuid not null references public.users(id),
  legal_entity_id uuid references public.legal_entities(id),
  amount_bani integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trigger_set_updated_at
  before update on public.payroll_period_totals
  for each row execute function public.trigger_set_updated_at();

create index payroll_period_totals_period_idx on public.payroll_period_totals (payroll_period_id);
create index payroll_period_totals_trainer_idx on public.payroll_period_totals (trainer_id);

alter table public.payroll_period_totals enable row level security;

create policy "authenticated select payroll_period_totals" on public.payroll_period_totals
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or app.has_capability('finance.operations.*', organization_id)
    or (app.has_capability('mywork.*', organization_id) and trainer_id = app.current_user_id())
  );

create policy "authenticated insert payroll_period_totals" on public.payroll_period_totals
  for insert to authenticated
  with check (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or app.has_capability('finance.operations.*', organization_id)
  );

-- No UPDATE, no DELETE policy at all -- deny by default (§7), and
-- deliberately: a snapshot that could be edited after the fact is not a
-- snapshot. If a close is ever genuinely mistaken, the fix is a NEW
-- period row (reopen is not built, same as today) and a new snapshot, not
-- an edit to this one.

do $$
declare
  v_table_exists boolean;
begin
  select exists(select 1 from information_schema.tables where table_name = 'payroll_period_totals') into v_table_exists;
  if not v_table_exists then
    raise exception 'payroll_period_totals: table did not get created';
  end if;
  raise notice 'payroll_period_totals: table live, RLS enabled, insert/select policies match payroll_periods exactly, no update/delete path exists.';
end $$;
