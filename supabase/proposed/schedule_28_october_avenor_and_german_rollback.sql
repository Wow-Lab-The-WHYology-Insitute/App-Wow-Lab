-- Rollback for schedule_28_october_avenor_and_german.sql.
--
-- Deletes the four workshops of 28 October. Refuses if any has been
-- confirmed or cancelled since -- at that point it carries a person's
-- assertion and deleting it would destroy a record, not undo a migration.

do $$
declare
  v_org uuid;
  v_n integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'schedule-28oct rollback: no organization with slug wow-lab';
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org and session_date = '2026-10-28'
      and (trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null
           or status <> 'planned')
  ) then
    raise exception 'schedule-28oct rollback: a workshop on 28 October has been confirmed or cancelled since -- refusing to delete it';
  end if;

  delete from public.sessions
  where organization_id = v_org and session_date = '2026-10-28';

  get diagnostics v_n = row_count;
  if v_n <> 4 then
    raise exception 'schedule-28oct rollback: deleted % workshops, expected 4', v_n;
  end if;

  raise notice 'schedule-28oct rollback: the 4 workshops of 28 October are gone';
end $$;
