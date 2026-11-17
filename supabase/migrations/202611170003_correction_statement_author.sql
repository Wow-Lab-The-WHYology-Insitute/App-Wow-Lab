-- 202611170003_correction_statement_author.sql
--
-- Who made the change an impact statement sanctions (OPEN_ITEMS item 196,
-- Mihai's decision 2026-11-17, option (3)). /payroll showed "—" for a group
-- change's author: a group has no "changed by" column, the author lives only
-- in row_history, and row_history is readable only with org.audit.read
-- (Organization Owner, Platform Owner). Whoever reviews a statement needs to
-- know who made the change.
--
-- Option (1) -- letting finance read row_history for these tables -- was
-- measured and refused: RLS filters rows, not columns, so it would have
-- opened the whole history of every group (address, notes as they were
-- before an edit, children counts, contract) and the activity of the
-- Operations staff, for one name on one screen -- org.audit.read widened
-- through the back door.
--
-- This function is the narrow version, and its narrowness is the point. It
-- is BOUND TO A STATEMENT: the only input is a grid_corrections id, and the
-- row_history row it may read is fixed by that statement alone -- its target
-- table, its target id, and its created_at. That last link is exact, not
-- approximate: row_history_capture writes changed_at = now(), the statement
-- is written with created_at = now(), and both happen in the same
-- transaction (induced 2026-11-17: one row_history row at the statement's
-- moment, actor = the caller, 0 others).
--
-- Same read gate as grid_corrections' own SELECT policy: whoever can read the
-- statement can read its author, and nothing more.
--
-- Test: db/tests/pay_input_guard.sql points 12-14, written first.

create or replace function app.correction_statement_author(p_statement_id uuid)
returns table (actor_user_id uuid, changed_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
-- THE CONSTRAINT THIS FUNCTION EXISTS UNDER (Mihai, 2026-11-17). It returns
-- ONLY the author and the moment of the change that produced THIS statement.
-- It is never a free search of row_history:
--   * its only input is a statement id -- no table, no row, no time window;
--   * the history row is matched on the statement's own target table AND
--     target id AND created_at, all three, taken from the statement;
--   * it returns (actor_user_id, changed_at) -- never old_values/new_values,
--     never any other row;
--   * if the statement's moment ever matched more than one actor, it returns
--     NOTHING rather than choose.
-- Widening any of these turns it into the bypass of org.audit.read it was
-- built to avoid. db/tests/pay_input_guard.sql point 14 sabotages exactly
-- that (a free search of the group's history) and must fail.
declare
  v public.grid_corrections%rowtype;
begin
  select * into v from public.grid_corrections where id = p_statement_id;
  if v.id is null then
    return;
  end if;

  -- The statements' own read gate (grid_corrections SELECT policy).
  if not (app.is_platform_owner()
          or app.has_capability('finance.operations.*', v.organization_id)
          or app.has_capability('finance.reporting.*', v.organization_id)) then
    return;
  end if;

  if v.group_id is not null then
    -- A group is not a new row: its author exists only in row_history.
    if (select count(distinct h.actor_user_id) from public.row_history h
        where h.table_name = 'groups' and h.row_id = v.group_id
          and h.organization_id = v.organization_id and h.changed_at = v.created_at) = 1 then
      return query
        select h.actor_user_id, h.changed_at from public.row_history h
        where h.table_name = 'groups' and h.row_id = v.group_id
          and h.organization_id = v.organization_id and h.changed_at = v.created_at
        limit 1;
    end if;
  elsif v.trainer_grade_assignment_id is not null then
    -- A new row carries its own author.
    return query
      select a.set_by, a.created_at from public.trainer_grade_assignments a
      where a.id = v.trainer_grade_assignment_id and a.organization_id = v.organization_id;
  else
    -- A correcting grid version carries its own author.
    return query execute format(
      'select created_by, created_at from public.%I where id = $1 and organization_id = $2',
      v.target || '_versions'
    ) using coalesce(v.trainer_grade_version_id, v.duration_multiplier_version_id,
                     v.location_bonus_version_id, v.language_bonus_version_id), v.organization_id;
  end if;
end;
$$;

revoke all on function app.correction_statement_author(uuid) from public;
grant execute on function app.correction_statement_author(uuid) to authenticated;

create or replace function public.correction_statement_author(p_statement_id uuid)
returns table (actor_user_id uuid, changed_at timestamptz)
language sql
stable
security invoker
set search_path = ''
as $$ select * from app.correction_statement_author(p_statement_id); $$;

comment on function public.correction_statement_author(uuid) is
  'PostgREST-exposed wrapper around app.correction_statement_author(): the author and moment of the change ONE impact statement sanctions, behind the statements'' own read gate. Never a search of row_history (202611170003, item 196).';

revoke all on function public.correction_statement_author(uuid) from public;
grant execute on function public.correction_statement_author(uuid) to authenticated;
