-- 202609210002_narrow_client_contacts_trainer_facing_branch.sql
-- Corrects 202608250001's mywork.* branch on client_contacts before its
-- first real use (the on-site contact feature, 202609210001). That
-- branch's own comment already flagged it as unverified: "RE-VERIFY
-- THIS ASSERTION THE DAY A TRAINER-FACING READ CAPABILITY (a future
-- Trainer Dashboard) IS ADDED... it is currently unreachable in
-- production... a paper check, not a live one." This is that day.
--
-- As shipped, the branch is a bare row match:
--   app.has_capability('mywork.*', organization_id)
--   and contact_purpose = 'trainer_facing'
-- -- no scoping to the viewer's own sessions at all. Marking one contact
-- trainer_facing would show it to every trainer/senior_trainer in the
-- org, not the ones on that specific workshop. Confirmed live (no rows
-- have contact_purpose = 'trainer_facing' yet, per that migration's own
-- comment) that this has never actually been exercised in production --
-- narrowing it now changes no live behavior, only what the branch will
-- do the first time it's used for real.
--
-- Fix: the identical session-scoped shape already proven correct twice
-- in this codebase -- 202609160001's mywork.* branch on public.users,
-- and 202609170001's mywork.* branch on public.clients (item 66) -- a
-- viewer sees the row only if it's reachable through a group with a
-- session they're actually allocated to. Checked against item 68's
-- lesson before writing this: the nested reads on public.groups and
-- public.sessions use the exact condition those tables' own mywork.*
-- branches already use for this viewer/capability pair, so nothing here
-- can be silently narrowed to false the way 202609160001's original
-- finance.operations.* branch was -- a viewer who reaches this branch
-- can already read, under groups'/sessions' own RLS, every row this
-- branch's subquery touches.
--
-- Deliberately narrower than "any group at this client with a session
-- I'm on": scoped through groups.on_site_contact_id specifically, not
-- through client_id alone -- a trainer sees a contact this way only if
-- that contact is actually linked as the on-site contact for a group
-- they have a session in, not every trainer_facing contact belonging to
-- the same client. contact_purpose = 'trainer_facing' stays required on
-- top of the link (not replaced by it) -- linking a contact as
-- on-site does not itself make them trainer-visible; whoever manages
-- client_contacts still has to mark them trainer_facing separately, the
-- same deliberate two-step this migration's own comment on
-- groups.on_site_contact_id already names.
--
-- Cannot edit 202608250001 -- already applied. Same drop-and-recreate
-- shape every prior extension of an applied policy in this project uses.
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
          and exists (
            select 1
            from public.groups g
            where g.on_site_contact_id = client_contacts.id
              and exists (
                select 1
                from public.sessions s
                where s.group_id = g.id
                  and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
              )
          )
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
