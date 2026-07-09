-- Attach the existing row_history trigger to legal_entities and file_refs,
-- both marked AUDITED in spec but missing row-history until now.

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'legal_entities'
      and trigger_name = 'legal_entities_row_history'
  ) then
    create trigger legal_entities_row_history
      before update or delete on public.legal_entities
      for each row execute function public.row_history_capture();
  end if;
end;
$$;

DO $$
begin
  if not exists (
    select 1 from information_schema.triggers
    where event_object_table = 'file_refs'
      and trigger_name = 'file_refs_row_history'
  ) then
    create trigger file_refs_row_history
      before update or delete on public.file_refs
      for each row execute function public.row_history_capture();
  end if;
end;
$$;
