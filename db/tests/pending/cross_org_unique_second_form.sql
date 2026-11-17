-- db/tests/pending/cross_org_unique_second_form.sql
--
-- HELD OUT OF THE SUITE ON PURPOSE (scripts/run_rls_suite.ts reads only the
-- top level of db/tests/). OPEN_ITEMS item 198, "the class, second form":
-- written and validated 2026-11-17, NOT yet repaired (Mihai: show the surface
-- first). On the live schema the first block FAILS, naming exactly
-- trainer_home_cities_trainer_unique -- in the suite it would keep it red for
-- every session until that one-line repair is authorized.
--
-- WHEN THE REPAIR LANDS: move the first block into
-- db/tests/cross_org_write_isolation.sql as point 15, with a SABOTAGE block
-- (a table with UNIQUE (trainer_id) added -> must flip), and delete this file.
-- The two blocks after it are the validation that was run instead of a
-- sabotage, because a sabotage proves nothing while the main check already
-- fails (§27): with the bad key scoped, inside a rolled-back transaction, the
-- check reads "none"; with a sabotage table added, it flips.

-- ============================================================================
-- Point 15 -- THE CLASS, second form (Mihai, 2026-11-17): a UNIQUE key on an
-- org-scoped table that neither includes organization_id nor reaches the
-- organization through a composite key lets one organization make a write
-- IMPOSSIBLE for another. Nothing moves; something becomes impossible, so no
-- "did wow-lab change" probe can see it. Excluded, each for a stated reason:
--   * the primary key on `id` alone -- random uuids; another organization
--     cannot take an id that has not been generated;
--   * a key one of whose columns is the child side of a composite
--     (x, organization_id) foreign key -- that column already belongs to one
--     organization, so two organizations cannot collide on it.
-- ============================================================================
begin;
  select 'no unique key on an org-scoped table that ignores the organization (the class, second form)' as check_name,
    coalesce((
      select string_agg(t.relname || '.' || coalesce(con.conname, i.relname), ', ' order by t.relname)
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      join pg_class i on i.oid = ix.indexrelid
      left join pg_constraint con on con.conindid = ix.indexrelid
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), 'none') as actual,
    'none' as expected,
    coalesce((
      select count(*) = 0
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), false) as pass;
rollback;

-- ---- validation, rolled back: nothing is repaired by running it ----
begin;
  alter table public.trainer_home_cities drop constraint trainer_home_cities_trainer_unique;
  alter table public.trainer_home_cities add constraint trainer_home_cities_org_trainer_unique unique (organization_id, trainer_id);
  select 'VALIDATION (rolled back, nothing repaired): with the one bad key scoped -- no unique key on an org-scoped table that ignores the organization (the class, second form)' as check_name,
    coalesce((
      select string_agg(t.relname || '.' || coalesce(con.conname, i.relname), ', ' order by t.relname)
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      join pg_class i on i.oid = ix.indexrelid
      left join pg_constraint con on con.conindid = ix.indexrelid
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), 'none') as actual,
    'none' as expected,
    coalesce((
      select count(*) = 0
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), false) as pass;
rollback;

begin;
  alter table public.trainer_home_cities drop constraint trainer_home_cities_trainer_unique;
  alter table public.trainer_home_cities add constraint trainer_home_cities_org_trainer_unique unique (organization_id, trainer_id);
  create table public.zz_unique_sabotage (id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations (id), trainer_id uuid not null references public.users (id), unique (trainer_id));
  select 'SABOTAGE (rolled back): same, a table with UNIQUE (trainer_id) added -- no unique key on an org-scoped table that ignores the organization (the class, second form)' as check_name,
    coalesce((
      select string_agg(t.relname || '.' || coalesce(con.conname, i.relname), ', ' order by t.relname)
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      join pg_class i on i.oid = ix.indexrelid
      left join pg_constraint con on con.conindid = ix.indexrelid
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), 'none') as actual,
    'none' as expected,
    coalesce((
      select count(*) = 0
      from pg_class t
      join pg_index ix on ix.indrelid = t.oid and ix.indisunique
      where t.relnamespace = 'public'::regnamespace and t.relkind = 'r'
        and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'organization_id' and not a.attisdropped)
        and not exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey) and a.attname = 'organization_id')
        and not (ix.indisprimary and (select array_agg(a.attname::text) from pg_attribute a where a.attrelid = t.oid and a.attnum = any (ix.indkey)) = array['id'])
        and not exists (
          select 1 from pg_constraint fk
          where fk.conrelid = t.oid and fk.contype = 'f' and array_length(fk.conkey, 1) = 2
            and fk.conkey[1] = any (ix.indkey)
            and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attnum = fk.conkey[2] and a.attname = 'organization_id'))
    ), false) as pass;
rollback;
