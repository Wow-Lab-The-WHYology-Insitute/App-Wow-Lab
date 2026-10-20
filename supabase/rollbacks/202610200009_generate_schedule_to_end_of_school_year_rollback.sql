-- Rollback for 202610200009_generate_schedule_to_end_of_school_year.sql.
--
-- Deletes the 172 generated workshops. Refuses if any has been confirmed or
-- cancelled since: at that point the row carries a person's assertion or a
-- recorded reason, and deleting it destroys a record rather than undoing a
-- migration.

do $$
declare v_org uuid; v_n integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'generate rollback: no organization with slug wow-lab'; end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date >= '2026-11-02'
      and (status <> 'planned' or trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null or cancellation_category is not null)
  ) then
    raise exception 'generate rollback: a generated workshop has been confirmed or cancelled -- refusing to delete it';
  end if;

  delete from public.sessions where organization_id = v_org and session_date >= '2026-11-02';
  get diagnostics v_n = row_count;
  if v_n <> 172 then
    raise exception 'generate rollback: deleted % workshops, expected 172', v_n;
  end if;

  if (select count(*) from public.sessions where organization_id = v_org) <> 48 then
    raise exception 'generate rollback: did not land back on 48 sessions';
  end if;

  raise notice 'generate rollback: the 172 generated workshops are gone; back to 48';
end $$;
