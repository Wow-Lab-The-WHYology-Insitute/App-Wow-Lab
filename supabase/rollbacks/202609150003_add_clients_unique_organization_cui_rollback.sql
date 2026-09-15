-- Rollback for 202609150003_add_clients_unique_organization_cui.sql

alter table public.clients
  drop constraint if exists clients_unique_organization_cui;
