-- Rollback for 202609150001_create_payroll_periods.sql

drop policy if exists "authenticated insert payroll_periods" on public.payroll_periods;
drop policy if exists "authenticated select payroll_periods" on public.payroll_periods;
drop table if exists public.payroll_periods;
