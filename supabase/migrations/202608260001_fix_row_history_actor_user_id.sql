-- 202608260001_fix_row_history_actor_user_id.sql
-- Fixes row_history_capture(): actor_user_id was reading a raw Postgres
-- session GUC (`current_setting('app.current_user_id', true)`) that
-- nothing anywhere ever sets via set_config -- confirmed live before
-- writing this: all 59 existing row_history rows have actor_user_id =
-- NULL, across every audited table, every session type, since the table
-- started being written to. This is not specific to any one table or to
-- DELETE -- it has never worked, for anyone.
--
-- The fix is a one-line swap: call app.current_user_id() (already used by
-- every RLS policy in this project; does `select auth.uid()`) instead of
-- reading the unset GUC directly. Confirmed empirically, not assumed,
-- before writing this migration:
--   - app.current_user_id() called from INSIDE a SECURITY DEFINER trigger,
--     fired while the session's current role is authenticated, correctly
--     resolves to the real session user -- SECURITY DEFINER changes the
--     executing role for privilege checks, it does not reset or hide
--     session-scoped GUCs like request.jwt.claims, which is what
--     auth.uid() actually reads.
--   - auth.uid() returns a clean NULL, not an error, when there is no JWT
--     context at all -- checked its own definition (every current_setting
--     call uses the missing_ok=true form, every intermediate nullif/cast/
--     ->> step is null-safe) and confirmed live under both a direct
--     Postgres connection and an explicit service_role session with no
--     JWT set: both returned NULL, neither raised.
--
-- Nothing else in this function changes -- the DELETE/UPDATE branching,
-- the old/new capture via row_to_json, the organization_id extraction,
-- and the row_id coalesce are all sound and untouched.
--
-- The existing 59 NULL rows are not backfilled. That information (who
-- actually made those changes) no longer exists anywhere -- there is
-- nothing correct to backfill it with, and inventing a value would be
-- worse than leaving the gap visible as NULL.

create or replace function public.row_history_capture()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare
  captured jsonb;
begin
  captured := case
    when TG_OP = 'DELETE' then row_to_json(old)::jsonb
    else row_to_json(new)::jsonb
  end;

  insert into public.row_history (
    id,
    table_name,
    row_id,
    organization_id,
    actor_user_id,
    old_values,
    new_values,
    changed_at,
    created_at,
    updated_at
  ) values (
    gen_random_uuid(),
    tg_table_name,
    coalesce(old.id, new.id),
    nullif(captured ->> 'organization_id', '')::uuid,
    app.current_user_id(),
    row_to_json(old)::jsonb,
    case when new is null then null else row_to_json(new)::jsonb end,
    now(),
    now(),
    now()
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$function$;
