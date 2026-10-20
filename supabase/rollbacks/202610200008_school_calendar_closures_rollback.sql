-- Rollback for 202610200008_school_calendar_closures.sql.
--
-- Drops the table and everything on it. Refuses if any session has been
-- generated from it -- at that point the schedule depends on these rows for
-- its explanation, and dropping them leaves 172 workshops whose dates nobody
-- can justify.

do $$
declare v_org uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is not null and exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date > '2026-10-28'
  ) then
    raise exception 'closures rollback: workshops exist beyond 28 October -- roll back 202610200009 first, or the schedule loses the calendar that justifies it';
  end if;
end $$;

drop trigger if exists school_calendar_closures_row_history on public.school_calendar_closures;
drop trigger if exists school_calendar_closures_set_updated_at on public.school_calendar_closures;
drop policy if exists "org members select school_calendar_closures" on public.school_calendar_closures;
drop table if exists public.school_calendar_closures;
