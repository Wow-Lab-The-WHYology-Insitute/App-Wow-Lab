-- Restores authenticated's plain table-wide UPDATE/INSERT grant on
-- contracts and groups (pre-202609220001 shape) -- reopens the gap this
-- migration closed. Only roll back together with 202609220001's own
-- rollback.

revoke update (id, organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, status, renewal_of, drive_ref, notes, created_at, updated_at, signed_date, offer_structure, ac_link, entry_number, exit_number) on public.contracts from authenticated;
revoke insert (id, organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, status, renewal_of, drive_ref, notes, created_at, updated_at, signed_date, offer_structure, ac_link, entry_number, exit_number) on public.contracts from authenticated;
grant update on public.contracts to authenticated;
grant insert on public.contracts to authenticated;

revoke update (id, organization_id, client_id, module, delivery_format, schedule_pattern, children_billed, status, notes, created_at, updated_at, age_range, school_year_calendar_link, contract_id, address, on_site_contact_id) on public.groups from authenticated;
revoke insert (id, organization_id, client_id, module, delivery_format, schedule_pattern, children_billed, status, notes, created_at, updated_at, age_range, school_year_calendar_link, contract_id, address, on_site_contact_id) on public.groups from authenticated;
grant update on public.groups to authenticated;
grant insert on public.groups to authenticated;
