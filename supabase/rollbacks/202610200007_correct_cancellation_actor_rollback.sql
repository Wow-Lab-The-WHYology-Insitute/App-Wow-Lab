-- Rollback for 202610200007_correct_cancellation_actor.sql.
--
-- Restores Catalina as the actor on the six cancellations. It exists so the
-- migration is reversible as a unit, NOT because reversing it is ever the
-- right thing to do: the attribution it restores is the one
-- DATABASE_CONVENTIONS.md §19 was written to stop.
--
-- Refuses if anything other than the actor has changed since.

do $$
declare
  v_org uuid; v_mihai uuid; v_cat uuid; v_n integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  select id into v_mihai from public.users where email = 'maxdigitalro@gmail.com';
  select id into v_cat   from public.users where email = 'catalina_moale@yahoo.com';
  if v_org is null or v_mihai is null or v_cat is null then
    raise exception 'correct-actor rollback: missing org or one of the two users';
  end if;

  if (select count(*) from public.sessions
      where organization_id = v_org
        and session_date between '2026-10-19' and '2026-10-21'
        and status = 'cancelled' and cancellation_category = 'vacanta'
        and cancelled_by = v_mihai) <> 6 then
    raise exception 'correct-actor rollback: the six are not in the state 202610200007 left them';
  end if;

  update public.sessions set cancelled_by = v_cat
  where organization_id = v_org
    and session_date between '2026-10-19' and '2026-10-21'
    and status = 'cancelled' and cancellation_category = 'vacanta';

  get diagnostics v_n = row_count;
  if v_n <> 6 then
    raise exception 'correct-actor rollback: restored % rows, expected 6', v_n;
  end if;

  raise notice 'correct-actor rollback: the six name Catalina again -- which is the wrong actor, by §19';
end $$;
