-- 202609150002_add_sessions_confirmation_columns_and_rls.sql
-- WOW LAB OS: trainer_principal_confirmed_at / trainer_secundar_confirmed_at
-- on sessions (docs/OPEN_ITEMS.md item 45 part 5) -- nullable, one per
-- trainer slot, set when that trainer confirms they delivered. Pay
-- follows this timestamp, not attendance_count or status (item 45 part
-- 5's own fork, decided earlier: sessions.status stays Operations'
-- scheduling field, nothing here changes that).
--
-- Built per Anca's three 2026-09-12 answers: pay follows each trainer's
-- own confirmation; a trainer cannot modify anything after their
-- session's month closes (payroll_periods, 202609150001); Anka may
-- correct either timestamp before or after close.

alter table public.sessions
  add column trainer_principal_confirmed_at timestamptz,
  add column trainer_secundar_confirmed_at timestamptz;

-- Extends the sessions UPDATE policy (202608130003, corrected by
-- 202609110003/202609110004) with two changes. Cannot edit an applied
-- policy -- same drop-and-recreate shape those two migrations used.
--
-- 1. The existing trainer branch (row match + mywork.*) now also
--    requires the session's own month to be open. "A trainer cannot
--    modify anything afterwards" (Anca, 2026-09-12) is unqualified --
--    not scoped to the confirmation columns alone -- so the close check
--    sits on the whole branch, the same one attendance_count/
--    experiment_delivered already go through, not on a second copy of
--    it. The action layer still narrows which column a matched,
--    open-month trainer can actually reach (updateSessionAttendance for
--    attendance_count/experiment_delivered, confirmSessionAttendance for
--    their own confirmation timestamp only, never their co-trainer's) --
--    RLS restricts rows, not columns, unchanged from every prior
--    decision this session.
--
-- 2. A new, unconditional finance.operations.* branch -- Anka's
--    correction path, and Laura's, before or after close. Unconditional
--    on purpose: a correction is precisely the case where the row match
--    (this trainer's own session) does not apply -- Laura and Anka
--    correct sessions they are not allocated to, on any month. The
--    action layer (correctSessionConfirmation) is what actually narrows
--    this branch to the two confirmation columns; RLS granting row
--    access here does not grant column access to attendance_count/
--    experiment_delivered or anything else on the row -- same division
--    of labor as sessions.create's own existing unconditional branch,
--    unchanged below.
--
-- Verified live against WOW LAB Test Org B before and after --
-- scripts/verify_sessions_confirmation_write.sql.
DO $$
begin
  drop policy if exists "authenticated update sessions" on public.sessions;
  create policy "authenticated update sessions" on public.sessions
    for update
    to authenticated
    using (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
      or app.has_capability('finance.operations.*', organization_id)
      or (
        app.has_capability('mywork.*', organization_id)
        and (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
        and not exists (
          select 1 from public.payroll_periods pp
          where pp.organization_id = sessions.organization_id
            and pp.period = date_trunc('month', sessions.session_date)::date
            and pp.closed_at is not null
        )
      )
    )
    with check (
      app.is_platform_owner()
      or app.has_capability('org.settings.manage', organization_id)
      or app.has_capability('sessions.create', organization_id)
      or app.has_capability('finance.operations.*', organization_id)
      or (
        app.has_capability('mywork.*', organization_id)
        and (trainer_principal_id = app.current_user_id() or trainer_secundar_id = app.current_user_id())
        and not exists (
          select 1 from public.payroll_periods pp
          where pp.organization_id = sessions.organization_id
            and pp.period = date_trunc('month', sessions.session_date)::date
            and pp.closed_at is not null
        )
      )
    );
end;
$$;
