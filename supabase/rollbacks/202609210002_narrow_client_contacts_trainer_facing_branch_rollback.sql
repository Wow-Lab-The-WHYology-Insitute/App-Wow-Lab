-- Rollback for 202609210002_narrow_client_contacts_trainer_facing_branch.sql
-- Restores the "authenticated select client_contacts" policy to exactly
-- its 202608250001 shape (the unscoped mywork.* branch).

DO $$
begin
  drop policy "authenticated select client_contacts" on public.client_contacts;

  create policy "authenticated select client_contacts" on public.client_contacts
    for select
    to authenticated
    using (
      (
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
        or (
          app.has_capability('mywork.*', organization_id)
          and contact_purpose = 'trainer_facing'
        )
      )
      and (
        not is_billing_contact
        or is_primary
        or app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('finance.operations.*', organization_id)
        or app.has_capability('finance.reporting.*', organization_id)
      )
    );
end;
$$;
