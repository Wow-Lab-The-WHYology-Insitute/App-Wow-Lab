-- Grants Cătălina Trușan the Trainer role in wow-lab.
--
-- WHY. She delivers four of the six real 2026-2027 groups (both Lycée
-- Français groups and both Avenor groups) and holds grade 6 effective
-- 2026-09-01 -- but her roles are Curriculum Manager + Evaluator +
-- Operations Manager, with no trainer role at all. Pay already works: a
-- workshop slot is a plain FK to users with no role requirement (item
-- 122). Two other things do not:
--
--   * `trainerOptions` on the group screen is built by filtering
--     user_org_roles on the role keys 'trainer' / 'senior_trainer'
--     (app/(app)/groups/[id]/page.tsx), so the person who teaches most of
--     the school year does not appear in the trainer dropdown and cannot
--     be allocated through the UI at all.
--   * THE DECISIVE ONE: app.rpc_confirm_session_attendance requires
--     `mywork.*`, which only the trainer roles grant her. So today she
--     cannot confirm her own delivery, and all 26 of her workshops --
--     every one in the retroactive import and every one for the rest of
--     the year -- would have to be confirmed by Operations on her behalf
--     through rpc_correct_session_confirmation. She is the trainer; the
--     confirmation is hers to make.
--
-- WHAT IT GIVES HER, measured by simulating the grant in a rolled-back
-- transaction before writing this, not reasoned from the capability list:
--
--   mywork.*            NEW  -- 8 policies across 7 tables
--   community.read      NEW  -- 0 policies, 0 code references (inert)
--   finance.own.read    NEW  -- 0 policies, 0 code references (inert)
--   materials.custody   NEW  -- 0 policies, 0 code references (inert)
--   curriculum.read     already held via curriculum.*    (Curriculum Manager)
--   presentations.own   already held via presentations.*  (Curriculum Manager)
--
-- AND IT GIVES HER NO ADDITIONAL VISIBILITY. Rows readable before/after,
-- counted as her on every table whose policy has a mywork.* branch:
-- sessions 0/0, groups 2/2, clients 3/3, client_contacts 4/4, users 38/38,
-- session_lesson_plans 0/0, payroll_periods 0/0. Her Operations Manager
-- grants already reach wider than the own-slot branches do, so mywork.*
-- adds the two things she needs and nothing else. Landing destination
-- unchanged: resolve_landing_flags gives has_mywork=true, has_beyond=true,
-- which is /profile -- where has_beyond=true already sent her.
--
-- This is the opposite direction of 202610160003, which removed Trainer
-- and Senior Trainer from Anka Orban, who holds no grade and delivers
-- nothing. Same drift, both ways; the review of all 16 real people is
-- item 142.
--
-- Idempotent: on conflict on (organization_id, user_id, role_id).
-- user_org_roles carries the row_history trigger, so this is captured.

do $$
declare
  v_org uuid;
  v_user uuid;
  v_role uuid;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'grant_catalina_trainer: no organization with slug wow-lab';
  end if;

  select id into v_user from public.users where email = 'catalina_moale@yahoo.com';
  if v_user is null then
    raise exception 'grant_catalina_trainer: no user catalina_moale@yahoo.com';
  end if;

  select id into v_role from public.roles where name = 'Trainer';
  if v_role is null then
    raise exception 'grant_catalina_trainer: no role named Trainer';
  end if;

  -- She must already be a member, and must already hold the grade this
  -- whole change assumes -- asserted rather than trusted, because a grant
  -- to someone with no grade would make her selectable in the dropdown and
  -- then unpayable, which is worse than not being selectable.
  if not exists (
    select 1 from public.user_org_roles
    where organization_id = v_org and user_id = v_user
  ) then
    raise exception 'grant_catalina_trainer: catalina_moale@yahoo.com is not a member of wow-lab';
  end if;

  if not exists (
    select 1 from public.trainer_grade_assignments
    where organization_id = v_org and trainer_id = v_user and effective_from <= '2026-09-01'
  ) then
    raise exception 'grant_catalina_trainer: no trainer grade effective on or before 2026-09-01 -- refusing to make her selectable but unpayable';
  end if;

  insert into public.user_org_roles (organization_id, user_id, role_id, assigned_by)
  values (v_org, v_user, v_role, null)
  on conflict (organization_id, user_id, role_id) do nothing;

  -- If she had been a role-less member (role_id null), that placeholder is
  -- now wrong -- same rule 202610160002 applies from the other side.
  delete from public.user_org_roles
  where organization_id = v_org and user_id = v_user and role_id is null;
end $$;
