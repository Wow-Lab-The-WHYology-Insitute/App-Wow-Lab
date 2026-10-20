-- Rollback for 202610200002. Removes the 38 imported workshops and the four
-- groups created for them, returning wow-lab to 0 sessions and the 2 Lycée
-- groups it had before.
--
-- The two Lycée groups are NOT deleted -- they predate this migration.
-- Their sessions are, because this migration created them.
--
-- Scoped by the four group ids this migration inserted plus the Lycée
-- sessions it created, rather than "all sessions in wow-lab", so a workshop
-- entered by hand after the import survives. If any such row exists the
-- delete below leaves it, and the count assertion at the end will fail
-- loudly rather than quietly removing someone's work.
--
-- row_history holds the before-image of all 38 confirmations (each was an
-- UPDATE through app.rpc_correct_session_confirmation, actor Anca), so the
-- confirmation history survives this rollback even though the rows do not.

do $$
declare
  v_org uuid;
  v_remaining integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'rollback: no organization with slug wow-lab';
  end if;

  -- Sessions on the four groups this migration created.
  delete from public.sessions
  where organization_id = v_org
    and group_id in (
      'c1000000-0000-0000-0000-0000000000a1'::uuid,
      'c1000000-0000-0000-0000-0000000000a2'::uuid,
      'c1000000-0000-0000-0000-0000000000b1'::uuid,
      'c1000000-0000-0000-0000-0000000000b2'::uuid
    );

  -- Lycée sessions this migration created: the 12 it inserted are exactly
  -- the ones in its own date window on the two pre-existing groups.
  delete from public.sessions s
  using public.groups g, public.clients c
  where s.group_id = g.id and g.client_id = c.id
    and s.organization_id = v_org
    and c.name like 'Școala Franceză%'
    and s.session_date between '2026-09-07' and '2026-10-16';

  delete from public.groups
  where organization_id = v_org
    and id in (
      'c1000000-0000-0000-0000-0000000000a1'::uuid,
      'c1000000-0000-0000-0000-0000000000a2'::uuid,
      'c1000000-0000-0000-0000-0000000000b1'::uuid,
      'c1000000-0000-0000-0000-0000000000b2'::uuid
    );

  select count(*) into v_remaining from public.sessions where organization_id = v_org;
  if v_remaining <> 0 then
    raise notice 'rollback: % session(s) remain in wow-lab -- entered outside this migration, left in place', v_remaining;
  end if;
end $$;
