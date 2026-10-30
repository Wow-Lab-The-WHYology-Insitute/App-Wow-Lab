-- db/tests/payroll_period_totals_rls.sql
-- public.payroll_period_totals (B2, item 177) -- the month-close
-- snapshot. RLS mirrors payroll_periods exactly, plus a trainer's own
-- row via mywork.*. No UPDATE/DELETE policy exists at all -- deny by
-- default (§7), asserted directly rather than assumed from "no policy
-- means no policy".
--
-- Fixtures created while privileged, then role-switched, same pattern as
-- rls_groups_sessions.sql. Everything rolls back.

begin;
  select set_config('app.wow_lab', (select id::text from public.organizations where slug = 'wow-lab'), true);
  select set_config('app.trainer_a', (select id::text from public.users where email = 'test+trainer-a@wowlab.dev'), true);
  select set_config('app.finance_ops_a', (select id::text from public.users where email = 'test+finance-ops-a@wowlab.dev'), true);
  -- Resolved here, while still privileged -- once the role below switches
  -- to a plain Trainer, that role cannot read an arbitrary user's row by
  -- email (users' own SELECT policy is own-row/finance-ops-only), so this
  -- lookup would itself fail with permission denied if left inline later.
  select set_config('app.trainer_b', (select id::text from public.users where email = 'test+trainer-b@wowlab.dev'), true);

  create temp table check_results (check_name text, pass boolean);
  -- Owned by the privileged role that created it; every later check below
  -- runs as `authenticated` (a real role switch, not just the JWT claims
  -- GUC, since this file exercises raw table RLS rather than a
  -- SECURITY DEFINER RPC) and needs write access to record its result.
  grant insert, select on check_results to authenticated;

  -- A real payroll_periods row to attach the snapshot to -- a fresh
  -- period, far from anything real, so this never collides with a period
  -- actually closed in wow-lab.
  do $$
  declare v_period_id uuid;
  begin
    insert into public.payroll_periods (organization_id, period, closed_at, closed_by)
    values (current_setting('app.wow_lab')::uuid, '2031-01-01', now(), current_setting('app.finance_ops_a')::uuid)
    returning id into v_period_id;
    perform set_config('app.period_id', v_period_id::text, true);
  end $$;

  -- ---- INSERT ----
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.trainer_a'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  declare v_caught boolean := false;
  begin
    begin
      insert into public.payroll_period_totals (organization_id, payroll_period_id, trainer_id, legal_entity_id, amount_bani)
      values (current_setting('app.wow_lab')::uuid, current_setting('app.period_id')::uuid, current_setting('app.trainer_a')::uuid, null, 100);
    exception when others then v_caught := true;
    end;
    insert into check_results values ('a trainer cannot insert a snapshot row for themselves', v_caught);
  end $$;

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.finance_ops_a'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  declare v_caught boolean := false;
  begin
    begin
      insert into public.payroll_period_totals (organization_id, payroll_period_id, trainer_id, legal_entity_id, amount_bani)
      values (current_setting('app.wow_lab')::uuid, current_setting('app.period_id')::uuid, current_setting('app.trainer_a')::uuid, null, 100);
    exception when others then v_caught := true;
    end;
    insert into check_results values ('finance.operations.* CAN insert a snapshot row', not v_caught);
  end $$;

  -- ---- SELECT ----
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.trainer_a'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into check_results values (
    'the trainer sees their OWN snapshot row via mywork.*',
    (select count(*) = 1 from public.payroll_period_totals where payroll_period_id = current_setting('app.period_id')::uuid)
  );

  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.trainer_b'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  insert into check_results values (
    'a DIFFERENT trainer sees none of it -- own-row only, not org-wide mywork.*',
    (select count(*) = 0 from public.payroll_period_totals where payroll_period_id = current_setting('app.period_id')::uuid)
  );

  -- ---- UPDATE / DELETE: no policy exists at all, deny by default (§7) ----
  select set_config('request.jwt.claims', json_build_object('sub', current_setting('app.finance_ops_a'), 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
  do $$
  declare v_caught boolean := false; v_n integer;
  begin
    begin
      update public.payroll_period_totals set amount_bani = 999 where payroll_period_id = current_setting('app.period_id')::uuid;
      get diagnostics v_n = row_count;
    exception when others then v_caught := true;
    end;
    -- Either an error, or zero rows affected -- both mean "did not update".
    insert into check_results values ('a snapshot row cannot be UPDATED, even by finance.operations.*', v_caught or v_n = 0);
  end $$;

  do $$
  declare v_caught boolean := false; v_n integer;
  begin
    begin
      delete from public.payroll_period_totals where payroll_period_id = current_setting('app.period_id')::uuid;
      get diagnostics v_n = row_count;
    exception when others then v_caught := true;
    end;
    insert into check_results values ('a snapshot row cannot be DELETED, even by finance.operations.*', v_caught or v_n = 0);
  end $$;

  select check_name, pass from check_results order by check_name;
rollback;
