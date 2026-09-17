-- 202609160001_add_users_trainer_name_visibility_branches.sql
-- WOW LAB OS: the payroll-walkthrough finding that trainer names render
-- as "Unknown" -- to Anka reviewing a session for payroll, and to a
-- trainer looking at their own co-trainer -- traced to its actual cause
-- before this migration was written, not assumed: public.users' own
-- SELECT policy (202607100002) grants a row only to the platform owner,
-- the row's own owner, or a viewer holding org.members.read in an org
-- the target belongs to. finance.operations.* (Anka's own gate on
-- /payroll) and mywork.* (a trainer's own gate) are both real
-- capabilities that do NOT imply org.members.read -- confirmed live
-- against role_capabilities before writing this: Finance Operations and
-- Contract Administrator hold neither; Trainer/Senior Trainer hold
-- neither. This has always been a visibility gap, not a display bug --
-- displayName() and the "Unknown" fallback in groups/[id]/page.tsx and
-- payroll/page.tsx were both already doing the right thing with what
-- they were allowed to see.
--
-- Two new branches, each scoped to exactly the case that needs it --
-- the instruction this migration was written against was explicit that
-- the fix must not hand anyone names they should not see, so neither
-- branch is "finance/trainers can see everyone":
--
-- 1. A finance.operations.* holder may see the name of anyone who holds
--    trainer or senior_trainer in the SAME organization. Scoped to the
--    trainer role specifically, not to org membership generally -- Anka
--    needs trainer names for payroll review; she gains no new visibility
--    into e.g. another Contract Administrator's row through this branch.
-- 2. A mywork.* holder (a trainer) may see the name of anyone who is
--    trainer_principal_id or trainer_secundar_id on a session where the
--    viewer THEMSELVES also holds one of those two slots -- a shared
--    session, not the whole org. A trainer sees their own co-trainers on
--    sessions they are actually on together, nothing broader.
--
-- Cannot edit 202607100002 -- already applied. Same drop-and-recreate
-- shape 202609110002/202609110003/202609110004 already used to extend an
-- applied policy.
DO $$
begin
  drop policy if exists "authenticated select users" on public.users;
  create policy "authenticated select users" on public.users
    for select
    to authenticated
    using (
      app.is_platform_owner()
      or id = app.current_user_id()
      or exists (
        select 1
        from public.user_org_roles uor
        where uor.user_id = users.id
          and app.has_capability('org.members.read', uor.organization_id)
      )
      or exists (
        select 1
        from public.user_org_roles target_uor
        join public.roles target_role on target_role.id = target_uor.role_id
        where target_uor.user_id = users.id
          and target_role.key in ('trainer', 'senior_trainer')
          and app.has_capability('finance.operations.*', target_uor.organization_id)
      )
      or exists (
        select 1
        from public.sessions s
        where (s.trainer_principal_id = users.id or s.trainer_secundar_id = users.id)
          and (s.trainer_principal_id = app.current_user_id() or s.trainer_secundar_id = app.current_user_id())
          and app.has_capability('mywork.*', s.organization_id)
      )
    );
end;
$$;
