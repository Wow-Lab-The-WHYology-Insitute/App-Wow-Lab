-- Removes Anka Orban's Trainer and Senior Trainer roles in wow-lab.
--
-- WHY. She does not deliver workshops. Confirmed by Anca, 2026-10-16: the
-- `ateliere` row in her admin_rates is ADMINISTRATIVE WORK ON workshops,
-- not workshops taught -- so there is no second pay path, and the two
-- trainer roles are an anomaly rather than a record of anything. She is a
-- supplier (ASISMART SRL, CUI 53213832, linked through suppliers.user_id)
-- paid hourly for administrative and financial work, with her own rate
-- table; she has no trainer_grade_assignments row and no
-- trainer_home_cities row.
--
-- WHAT SHE LOSES, measured rather than reasoned. She holds twelve roles in
-- this org, so the question is not "do her two finance roles cover this"
-- but "do the other ten". Simulated by deleting these two inside a
-- rolled-back transaction and re-asking app.has_capability for every
-- capability the two grant:
--
--   LOST      mywork.*            -- 8 policies across 7 tables, /my-work
--   LOST      finance.own.read    -- 0 policies, 0 code references
--   LOST      materials.custody   -- 0 policies, 0 code references
--   kept      community.read      -- via community.*      (Community & People)
--   kept      curriculum.read     -- via curriculum.*     (Curriculum Manager)
--   kept      presentations.own   -- via presentations.*  (Curriculum Manager)
--
-- Two of the three losses are inert today: nothing in the schema or the
-- codebase reads finance.own.read or materials.custody at all. The third,
-- mywork.*, costs her the /my-work nav item and page, and the gate on
-- app.rpc_confirm_session_attendance -- confirming her own delivery of a
-- workshop, which she does not do.
--
-- It costs her NO VISIBILITY. Measured the same way, counting rows
-- actually readable before and after on all seven tables whose policies
-- have a mywork.* branch: sessions 0/0, groups 2/2, clients 3/3,
-- client_contacts 4/4, users 38/38, session_lesson_plans 0/0,
-- payroll_periods 0/0. Her broader grants (sessions.read, groups.read,
-- clients.read, org.members.read, contracts.*) already cover everything
-- the own-slot branches were giving her, so /payroll -- which reads
-- sessions and groups -- is unaffected. Her landing destination is
-- unchanged too: resolve_landing_flags returns has_mywork=false,
-- has_beyond=true afterwards, which is /profile, exactly where
-- has_beyond=true already sent her.
--
-- NOT touched: her Finance Operations and Finance Administration &
-- Reporting roles, which are why she can close the month at all, and the
-- other eight.
--
-- user_org_roles carries the row_history trigger, so this is captured
-- there with its before-image.

do $$
declare
  v_org uuid;
  v_user uuid;
  v_removed integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'revoke_anka_trainer_roles: no organization with slug wow-lab';
  end if;

  select id into v_user from public.users where email = 'anka@asismart.ro';
  if v_user is null then
    raise exception 'revoke_anka_trainer_roles: no user anka@asismart.ro';
  end if;

  delete from public.user_org_roles uor
  using public.roles r
  where r.id = uor.role_id
    and uor.organization_id = v_org
    and uor.user_id = v_user
    and r.name in ('Trainer', 'Senior Trainer');

  get diagnostics v_removed = row_count;

  -- She holds ten other roles, so this can never empty her membership --
  -- asserted rather than assumed, because the "member, no role" repair
  -- that 202610160002 needs would be wrong here and silent if it were.
  if not exists (
    select 1 from public.user_org_roles
    where organization_id = v_org and user_id = v_user and role_id is not null
  ) then
    raise exception 'revoke_anka_trainer_roles: refusing to leave anka@asismart.ro with no roles -- expected ten others to remain';
  end if;

  raise notice 'revoke_anka_trainer_roles: removed % role grant(s)', v_removed;
end $$;
