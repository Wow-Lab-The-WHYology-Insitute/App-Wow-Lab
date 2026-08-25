-- 202608250001_client_contacts_row_filters_and_notes_grant.sql
-- client_contacts, Round A (docs/WOWLAB_SAD_Field_Masking.md §2.2): amends
-- the existing SELECT policy only -- no view, no SECURITY DEFINER
-- function, no grant flip on email/phone. Anca's decision changed the
-- shape of this table's masking entirely once contact_purpose turned out
-- to designate WHO a contact is for, not just a descriptive label: the
-- trainer rule is "sees rows marked trainer_facing", a row filter, not
-- "sees email nulled", a column mask. Confirmed live before writing this:
-- contact_purpose has a CHECK constraint (4 values or null, not an enum/
-- FK), and its only use anywhere in the app today is a display badge --
-- nothing anywhere reads it in a WHERE clause. This migration is the first
-- thing that ever filters on it.
--
-- Two additions to the SELECT policy, both confirmed against live data
-- before writing:
--
-- 1. Billing-contact rows (is_billing_contact = true) are invisible unless
--    the caller holds a finance capability or is owner/platform owner --
--    EXCEPT when is_primary = true, which is never hidden regardless of
--    the billing flag. Anca's reasoning: the intent was dedicated
--    accounting contacts, not (e.g.) a school director who also happens
--    to handle invoices. Confirmed live: the only real row in production
--    today (Vlad Rasnoveanu / Lycee Francais) is BOTH is_billing_contact
--    AND is_primary -- a naive "hide all billing rows from non-finance"
--    rule would have left that client with zero visible contacts for
--    Operations. The is_primary exception exists because of this real
--    row, not as a hypothetical.
--
-- 2. A new branch: app.has_capability('mywork.*', organization_id) sees
--    only rows where contact_purpose = 'trainer_facing'. mywork.*
--    confirmed live (role_capabilities) to be held by exactly trainer,
--    senior_trainer, organization_owner, and platform_owner -- the latter
--    two already see everything via their own first-listed branches, so
--    this new branch only ever changes behavior for trainer/senior_trainer
--    and never widens owner access. Neither trainer nor senior_trainer
--    holds clients.read, finance.operations.*, finance.reporting.*, or
--    org.settings.manage (confirmed live) -- today NO capability reaches
--    this table for either role through any other branch, so this branch
--    is their only path in, and it is currently unreachable in production:
--    nothing has ever set contact_purpose = 'trainer_facing' (the one live
--    row has contact_purpose = null, confirmed live -- it was created
--    2026-08-10, six days before 202608160002 added this column at all).
--
--    Its own verification (assertion 7 in scripts/verify_client_contacts_
--    row_filters.sql) proves the branch is wired correctly, NOT that it
--    protects anything live -- there is no production traffic today this
--    assertion could catch a regression in. RE-VERIFY THIS ASSERTION THE
--    DAY A TRAINER-FACING READ CAPABILITY (a future Trainer Dashboard) IS
--    ADDED. Until then it is a paper check, not a live one -- said here and
--    in the SAD so it isn't mistaken for coverage it doesn't have yet.
--
-- The billing-row gate applies uniformly across every branch, including
-- the new trainer one, not just the pre-existing clients.read branch -- a
-- trainer_facing row that also happens to be a non-primary billing contact
-- stays hidden from trainer/senior_trainer, same as it would from
-- Operations. Structured as an outer AND (which branch can see this row at
-- all) AND (does the billing gate allow it), rather than repeating the
-- billing condition inside every branch -- one gate, not five copies of it.
--
-- notes: revoked from authenticated entirely. Trap 5.2 applies (SAD §5.2)
-- -- REVOKE on a single column is inert over an existing table-level
-- GRANT, so the table-level SELECT is revoked first, then the explicit
-- column list (everything except notes) is granted back. Confirmed live:
-- nothing in the app reads or writes notes; it's free-text commentary
-- about a person. Cheapest moment to close it is now, before anything
-- depends on it.

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

revoke select on public.client_contacts from authenticated;

grant select (
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
) on public.client_contacts to authenticated;
