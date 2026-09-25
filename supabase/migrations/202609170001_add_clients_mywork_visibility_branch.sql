-- 202609170001_add_clients_mywork_visibility_branch.sql
-- OPEN_ITEMS.md item 66: a trainer's own group detail page
-- (app/(app)/groups/[id]/page.tsx) rendered the client's raw UUID instead
-- of its name. Traced before this was written: public.clients' own SELECT
-- policy (202608100003) has branches for platform owner, org.settings.
-- manage, clients.read (non-finance), finance.operations.* (private_
-- school/parent_b2c), and finance.reporting.* (everything else) -- no
-- branch at all for mywork.*, so a trainer/senior_trainer viewer gets zero
-- rows back for ANY client, unconditionally. That's clients' deliberate
-- finance-segregation design doing exactly what it was built to do; it was
-- just never asked to cover the trainer's own screen. Confirmed a trainer
-- delivering a session already knows which client they're delivering to --
-- withholding the name protects nothing, and the raw id that was rendering
-- instead protected nothing either, it just looked broken.
--
-- Scope, deliberately narrow -- NOT "trainers can read clients": a
-- mywork.* holder may see a client row only if that client has a group
-- with a session the viewer is themselves allocated to (principal or
-- secundar). Same session-scoped shape as 202609160001's own mywork.*
-- branch on public.users, and structurally identical to public.groups'
-- own existing mywork.* branch (202608130003) -- not a new pattern.
--
-- Checked against item 68's lesson before writing this (an RLS branch that
-- queries a second table inline inherits that table's own RLS, silently,
-- unless it's exactly aligned): the nested reads below on public.groups
-- and public.sessions use the IDENTICAL condition groups' and sessions'
-- own mywork.* branches already use for this exact viewer/capability
-- pair -- mywork.* + trainer_principal_id/trainer_secundar_id row match.
-- A viewer who reaches this branch can therefore already read, under
-- groups'/sessions' own RLS, every row this branch's subquery touches --
-- nothing here can be silently narrowed to false the way 202609160001's
-- finance.operations.* branch was, because there's no capability mismatch
-- between what this branch checks and what the referenced tables' own
-- policies check.
--
-- Cannot edit 202608100003 -- already applied. Same drop-and-recreate
-- shape 202609160001/202609160002 already used to extend an applied
-- policy.
DO $$
begin
  drop policy if exists "authenticated select clients" on public.clients;
  create policy "authenticated select clients" on public.clients
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
        and client_type in ('private_school', 'parent_b2c')
      )
      or (
        app.has_capability('finance.reporting.*', organization_id)
        and client_type not in ('private_school', 'parent_b2c')
      )
      or (
        app.has_capability('mywork.*', organization_id)
        and exists (
          select 1
          from public.groups g
          where g.client_id = clients.id
            and exists (
              select 1
              from public.sessions s
              where s.group_id = g.id
                and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
            )
        )
      )
    );
end;
$$;
