-- 202610300004 created public.payroll_period_totals with RLS policies but
-- no table-level GRANT at all -- found immediately, writing the RLS test
-- for it: a POLICY only FILTERS rows within what a GRANT already allows,
-- it never substitutes for one. Without this, `authenticated` could not
-- reach the table at all, policies notwithstanding.
--
-- SELECT and INSERT only -- never UPDATE, never DELETE. This is actually
-- the STRONGER half of "no update/delete path exists" that migration's
-- own comment claimed: a role with no grant to update or delete cannot
-- even attempt the statement, which fails before RLS is ever evaluated.
-- The missing policy was correct; it was never reachable on its own.

grant select, insert on public.payroll_period_totals to authenticated;

do $$
declare
  v_select boolean;
  v_insert boolean;
  v_update boolean;
  v_delete boolean;
begin
  select exists(select 1 from information_schema.table_privileges where table_name='payroll_period_totals' and grantee='authenticated' and privilege_type='SELECT') into v_select;
  select exists(select 1 from information_schema.table_privileges where table_name='payroll_period_totals' and grantee='authenticated' and privilege_type='INSERT') into v_insert;
  select exists(select 1 from information_schema.table_privileges where table_name='payroll_period_totals' and grantee='authenticated' and privilege_type='UPDATE') into v_update;
  select exists(select 1 from information_schema.table_privileges where table_name='payroll_period_totals' and grantee='authenticated' and privilege_type='DELETE') into v_delete;

  if not v_select or not v_insert then
    raise exception 'grant_payroll_period_totals: SELECT/INSERT grant to authenticated did not take';
  end if;
  if v_update or v_delete then
    raise exception 'grant_payroll_period_totals: UPDATE or DELETE was granted to authenticated -- this must stay absent';
  end if;

  raise notice 'grant_payroll_period_totals: authenticated holds SELECT+INSERT only, UPDATE/DELETE confirmed absent.';
end $$;
