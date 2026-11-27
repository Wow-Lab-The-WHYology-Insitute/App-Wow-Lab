-- 202611270001_actor_pinned_to_caller.sql
--
-- §19 made binding on the `*_by` columns (OPEN_ITEMS item 210, Mihai
-- 2026-11-27). Measured first, and induced: of the 11 `*_by` columns an app
-- user can in fact INSERT, only payroll_periods.closed_by was pinned to the
-- caller. On the other 10 a raw POST could record ANYONE as the author -- a
-- Finance Operations account created a grade version with created_by = the
-- Organization Owner and it was accepted.
--
-- THE RULE (Mihai, written into §19): a `*_by` column answers "who did the
-- ACT this row records".
--   * If the row records ONE ACT, the column is immutable, and a new act is
--     a NEW ROW.
--   * If the row is the record of a CURRENT STATE, the column says who set
--     it last.
--
-- 1. INSERT, all 10: the same WITH CHECK clause closed_by already carries,
--    appended to each table's existing INSERT policy. RLS only: migrations
--    and service_role are unaffected, and §23 governs what they write.
--    Checked before writing: no app path sends anyone but the caller --
--    rpc_create_grid_version (INVOKER) writes auth.uid(); the grade/statement
--    paths are DEFINER and write the caller; user_org_roles is written by
--    /admin/users through the service-role client with the caller's id.
-- 2. UPDATE, the two decided:
--    * file_refs.uploaded_by -- IMMUTABLE. The upload is an act; a rename is
--      not. authenticated keeps UPDATE on every other column, not this one.
--    * trainer_home_cities.set_by -- whoever updates. One current fact per
--      row: the UPDATE policy's WITH CHECK pins it to the caller.
-- 3. user_org_roles.assigned_by on UPDATE is NOT touched: measured and
--    reported (item 210), Mihai's to decide.
--
-- Test: db/tests/actor_pinned_to_caller.sql (written first, run failing
-- from db/tests/pending/, moved into the suite by this commit).

-- 1. INSERT: append the pin to each existing INSERT policy.
do $$
declare
  t record;
  v_name text;
  v_check text;
begin
  for t in select * from (values
    ('contract_type_uplift_versions', 'created_by'), ('duration_multiplier_versions', 'created_by'),
    ('language_bonus_versions', 'created_by'), ('lesson_plan_rate_versions', 'created_by'),
    ('location_bonus_versions', 'created_by'), ('trainer_grade_versions', 'created_by'),
    ('trainer_grade_assignments', 'set_by'), ('trainer_home_cities', 'set_by'),
    ('user_org_roles', 'assigned_by'), ('file_refs', 'uploaded_by')) v(tbl, col)
  loop
    select polname, pg_get_expr(polwithcheck, polrelid) into strict v_name, v_check
    from pg_catalog.pg_policy where polrelid = format('public.%I', t.tbl)::regclass and polcmd = 'a';
    execute format('alter policy %I on public.%I with check ((%s) and (%I = app.current_user_id()))',
                   v_name, t.tbl, v_check, t.col);
  end loop;
end $$;

-- 2a. file_refs.uploaded_by: immutable for app users. The UPDATE grant was
--     table-wide; it becomes every column except uploaded_by.
revoke update on public.file_refs from authenticated;
grant update (id, organization_id, storage_path, mime_type, byte_size, gdpr_class, created_at, updated_at)
  on public.file_refs to authenticated;

-- 2b. trainer_home_cities.set_by: pinned to whoever updates.
do $$
declare
  v_name text;
  v_check text;
begin
  select polname, pg_get_expr(polwithcheck, polrelid) into strict v_name, v_check
  from pg_catalog.pg_policy where polrelid = 'public.trainer_home_cities'::regclass and polcmd = 'w';
  execute format('alter policy %I on public.trainer_home_cities with check ((%s) and (set_by = app.current_user_id()))',
                 v_name, v_check);
end $$;

-- 3. Self-test: no `*_by` column an app user can INSERT is left unpinned,
--    and file_refs.uploaded_by is no longer updatable by app users.
do $$
begin
  if exists (
    select 1 from information_schema.column_privileges cp
    where cp.table_schema = 'public' and cp.grantee = 'authenticated' and cp.privilege_type = 'INSERT'
      and cp.column_name ~ '_by$'
      and exists (select 1 from pg_catalog.pg_class c where c.oid = format('public.%I', cp.table_name)::regclass
                  and (not c.relrowsecurity or exists (select 1 from pg_catalog.pg_policy p2 where p2.polrelid = c.oid and p2.polcmd in ('a', '*'))))
      and not exists (
        select 1 from pg_catalog.pg_policy p
        where p.polrelid = format('public.%I', cp.table_name)::regclass and p.polcmd in ('a', '*')
          and pg_get_expr(p.polwithcheck, p.polrelid) ~ ('\m' || cp.column_name || '\s*=\s*(app\.current_user_id\(\)|auth\.uid\(\))'))) then
    raise exception 'self-test: a *_by column app users can INSERT is still unpinned';
  end if;
  if has_column_privilege('authenticated', 'public.file_refs', 'uploaded_by', 'UPDATE') then
    raise exception 'self-test: file_refs.uploaded_by is still updatable by authenticated';
  end if;
end $$;
