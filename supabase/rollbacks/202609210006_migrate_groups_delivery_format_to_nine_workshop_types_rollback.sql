-- Unlike 202609210005's rollback, this one IS a true undo -- the forward
-- migration touched exactly 3 known rows by explicit id with a recorded
-- original value each, so there is no lossy backfill here.

alter table public.groups drop constraint groups_delivery_format_check;
alter table public.groups
  add constraint groups_delivery_format_check
  check (delivery_format in ('recurring', 'scoala_altfel', 'saptamana_verde', 'party', 'corporate', 'custom'));

comment on column public.groups.delivery_format is 'WORKING DECISION, risk accepted (SAD §3): split from "Tip atelier" into module + delivery_format is Mihai''s interpretation today, NOT explicitly confirmed by Anca. Flagged here so this assumption is never silently forgotten.';

update public.groups set delivery_format = 'recurring' where id = 'de6e6f56-0d5c-4f6a-b13d-4da9a9ebd558';
update public.groups set delivery_format = 'recurring' where id = 'efbe7e46-758e-4634-b9d8-57205ac45576';
update public.groups set delivery_format = 'corporate' where id = 'bda1f577-f381-4ced-a7f4-4d3399175e95';

create or replace function app.resolve_duration_multiplier(p_organization_id uuid, p_duration_minutes integer, p_delivery_format text, p_as_of date)
returns numeric
language plpgsql
stable
as $$
declare
  v_context text;
  v_version_id uuid;
  v_multiplier numeric;
begin
  v_context := case
    when p_delivery_format in ('scoala_altfel', 'saptamana_verde') then 'scoala_altfel_saptamana_verde'
    else 'standard'
  end;

  select id into v_version_id
  from public.duration_multiplier_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_duration_multiplier: no duration_multiplier_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select multiplier into v_multiplier
  from public.duration_multiplier_rates
  where version_id = v_version_id
    and duration_minutes = p_duration_minutes
    and delivery_context = v_context;

  if v_multiplier is null then
    raise exception 'app.resolve_duration_multiplier: version % has no row for % minutes / context % -- incomplete version', v_version_id, p_duration_minutes, v_context;
  end if;

  return v_multiplier;
end;
$$;

comment on function app.resolve_duration_multiplier(uuid, integer, text, date) is 'Duration multiplier resolver -- Sec12.6/12.7 of the payment SAD. scoala_altfel/saptamana_verde double the 2h rate; everything else uses the standard curve.';
