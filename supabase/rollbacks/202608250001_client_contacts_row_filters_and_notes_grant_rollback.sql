-- 202608250001_client_contacts_row_filters_and_notes_grant_rollback.sql
-- Rolls back 202608250001: restores the original SELECT policy (no billing
-- row gate, no trainer branch, no client_type/capability logic changed)
-- and restores table-wide SELECT on client_contacts for authenticated
-- (notes readable again, same as before this migration).
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD §6.2).

drop policy "authenticated select client_contacts" on public.client_contacts;

create policy "authenticated select client_contacts" on public.client_contacts
  for select
  to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('org.settings.manage', organization_id)
    or (
      app.has_capability('clients.read', organization_id)
      and not app.has_capability('finance.operations.*', organization_id)
      and not app.has_capability('finance.reporting.*', organization_id)
    )
    or (
      app.has_capability('finance.operations.*', organization_id)
      and exists (
        select 1 from public.clients cl
        where cl.id = client_contacts.client_id
          and cl.client_type = any (array['private_school', 'parent_b2c'])
      )
    )
    or (
      app.has_capability('finance.reporting.*', organization_id)
      and exists (
        select 1 from public.clients cl
        where cl.id = client_contacts.client_id
          and cl.client_type <> all (array['private_school', 'parent_b2c'])
      )
    )
  );

revoke select (
  id,
  organization_id,
  client_id,
  full_name,
  role_at_client,
  email,
  phone,
  is_billing_contact,
  is_primary,
  contact_purpose,
  created_at,
  updated_at
) on public.client_contacts from authenticated;

grant select on public.client_contacts to authenticated;
