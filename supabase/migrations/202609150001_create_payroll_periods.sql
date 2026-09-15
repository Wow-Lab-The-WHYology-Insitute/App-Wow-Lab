-- 202609150001_create_payroll_periods.sql
-- WOW LAB OS: payroll_periods -- the smallest honest representation of a
-- closed month (docs/OPEN_ITEMS.md item 45 part 5, design decided
-- 2026-09-11, built here per Anca's three 2026-09-12 answers: month
-- close is Anka's deliberate act, not automatic on a date; Anka may
-- correct a trainer's confirmation after close; a trainer may correct
-- their own only until close).
--
-- One row per organization per month. A row's existence alone means
-- nothing -- closed_at is the only signal: null is open, set is closed.
-- An absent row must read as open, not closed. Every query against this
-- table, here and in 202609150002, is written
-- "not exists (select ... where ... and closed_at is not null)" -- true
-- both when no row exists at all for that org+period AND when a row
-- exists but is still open, so an unclosed month and an untouched month
-- get the same (correct) answer through one expression, not two.
--
-- Insert-only, deliberately -- no UPDATE or DELETE policy exists below.
-- "Close" is the only operation this table supports, and it is a single
-- INSERT with closed_at already set: no separate "open" row gets
-- created first, because nothing here should need an automatic open act
-- to pair with the automatic close this design explicitly rejected
-- (Anca: closing is deliberate, not date-driven -- adding an automatic
-- "month starts open" trigger would quietly reintroduce the same
-- automatic-on-a-date shape for the other end of the same fact). The
-- unique constraint below is what makes closing twice fail at the
-- database level; app/(app)/payroll/actions.ts checks for an existing
-- row first, to turn that into a real "already closed" message instead
-- of a raw 23505 constraint violation, same pattern as
-- markContractSigned (app/(app)/contracts/actions.ts).
create table public.payroll_periods (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  period          date not null,
  closed_at       timestamptz,
  closed_by       uuid references public.users(id),
  created_at      timestamptz not null default now(),
  constraint payroll_periods_period_is_month_start check (period = date_trunc('month', period)::date),
  constraint payroll_periods_organization_period_unique unique (organization_id, period)
);

alter table public.payroll_periods enable row level security;

-- finance.operations.* is the capability that identifies "the person who
-- closes payroll" -- not contracts.*. Confirmed live: Anka and Laura both
-- hold finance.operations.* directly (the Finance Operations role), and
-- its own catalogue description is "Trainer pay, reimbursements,
-- private-school invoicing, attendance billing" -- payroll close is
-- exactly that, by name. contracts.* would also happen to cover both of
-- them today (Anka holds Contract Administrator too, and so does Laura)
-- but for an unrelated reason -- full contract lifecycle management,
-- nothing to do with pay. This is the identical coincidence-of-role
-- mistake 202608300001 (suppliers) already rejected for the same pair
-- of capabilities on a different table: "contracts.* was rejected
-- (contract_administrator also holds it, and the SAD gives
-- contract_administrator nothing here)." finance.reporting.* was
-- considered too and rejected -- its own description ("company-wide
-- reporting... CEO dashboard data") is read-oriented, not an
-- operational write.
create policy "authenticated select payroll_periods" on public.payroll_periods
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('mywork.*', organization_id)
  );

-- mywork.* (Trainer/Senior Trainer) is granted read here, and read only.
-- Not because a trainer manages payroll periods -- because
-- confirmSessionAttendance (app/(app)/groups/actions.ts) reads this
-- table through the trainer's own session client to tell "this month is
-- closed" apart from "this isn't your session" before returning an
-- error. A capability that cannot read this table cannot get that
-- message; RLS's own silent zero-rows-affected on the sessions UPDATE
-- (202609150002) does not distinguish the two either, so this read is
-- how the action does.
create policy "authenticated insert payroll_periods" on public.payroll_periods
  for insert
  to authenticated
  with check (
    (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('finance.operations.*', organization_id)
    )
    and closed_by = app.current_user_id()
  );

grant select, insert on public.payroll_periods to authenticated;
