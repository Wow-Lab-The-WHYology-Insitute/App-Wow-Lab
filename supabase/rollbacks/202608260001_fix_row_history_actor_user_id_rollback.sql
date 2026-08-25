-- 202608260001_fix_row_history_actor_user_id_rollback.sql
-- Rolls back 202608260001: restores row_history_capture() to its exact
-- prior body (reading the unset GUC, i.e. actor_user_id always NULL for
-- everyone again). Nothing else about the function changes either
-- direction.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

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
    nullif(current_setting('app.current_user_id', true), '')::uuid,
    row_to_json(old)::jsonb,
    case when new is null then null else row_to_json(new)::jsonb end,
    now(),
    now(),
    now()
  );
  return case when TG_OP = 'DELETE' then old else new end;
end;
$function$;
