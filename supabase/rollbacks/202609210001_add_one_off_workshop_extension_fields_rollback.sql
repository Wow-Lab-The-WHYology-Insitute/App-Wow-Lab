-- Rollback for 202609210001_add_one_off_workshop_extension_fields.sql

drop index if exists public.groups_on_site_contact_id_idx;

alter table public.groups
  drop column if exists on_site_contact_id;

alter table public.groups
  drop column if exists address;

alter table public.clients
  drop column if exists address;

alter table public.sessions
  drop column if exists start_time;
