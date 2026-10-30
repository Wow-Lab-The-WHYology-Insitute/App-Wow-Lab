-- Rollback for 202610300008. Restores the exact 2026-10-20 12:24:11.22144+00
-- confirmation timestamp this migration cleared, on the same two Scoala
-- Germana 2026-10-14 sessions, and ONLY if nothing else has happened to them
-- since.
--
-- This does NOT restore the original (wrong) row_history actor -- that
-- would mean deliberately re-attributing the assertion to Anca, the exact
-- thing the forward migration refused to do a second time. Like the
-- forward migration, this rollback impersonates nobody; row_history will
-- again record actor_user_id = NULL on whatever row this write produces.
--
-- Refuses rather than overwrites if the row has moved on since -- same
-- defensive shape as 202610200004's own rollback.

do $$
declare
  v_status_1 text;
  v_status_2 text;
  v_confirmed_1 timestamptz;
  v_confirmed_2 timestamptz;
begin
  select status, trainer_principal_confirmed_at into v_status_1, v_confirmed_1
  from public.sessions where id = '725eaf35-49ce-4adc-92db-d71db1f6fea7';

  select status, trainer_principal_confirmed_at into v_status_2, v_confirmed_2
  from public.sessions where id = '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46';

  if v_status_1 is null or v_status_2 is null then
    raise exception 'rollback: one or both target sessions no longer exist';
  end if;

  if v_status_1 <> 'delivered' or v_status_2 <> 'delivered' then
    raise exception 'rollback: status has changed since the forward migration (% / %) -- refusing to silently restore a confirmation on a row that moved on. Decide what happens to it first.', v_status_1, v_status_2;
  end if;

  if v_confirmed_1 is not null or v_confirmed_2 is not null then
    raise exception 'rollback: a confirmation already exists on one or both rows -- someone (a trainer, Operations) has acted since this was cleared. Refusing to overwrite it.';
  end if;

  update public.sessions
    set trainer_principal_confirmed_at = '2026-10-20 12:24:11.22144+00'
    where id in ('725eaf35-49ce-4adc-92db-d71db1f6fea7', '549e2fd1-c1ed-46a7-be3f-d9752cc8ec46');

  raise notice 'rollback: trainer_principal_confirmed_at restored to the original 2026-10-20 import timestamp on both rows. actor_user_id on the new row_history rows is NULL, same as the forward migration -- not re-attributed to Anca.';
end $$;
