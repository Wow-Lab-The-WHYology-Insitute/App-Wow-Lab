-- 202608200005_users_masked_view.sql
-- Users field masking, step 1 of 3 (docs/WOWLAB_SAD_Field_Masking.md §2.3):
-- create public.users_masked alongside the base table. GRANTS ARE
-- UNCHANGED IN THIS STEP — authenticated keeps its existing table-level
-- SELECT on public.users. Nothing reads this view yet; step 2 migrates
-- the call sites found while scoping this work (/profile, /admin/users),
-- step 3 flips the base-table grants.
--
-- Predicate differs from contracts' in one structural way: users has no
-- organization_id column (a user can belong to several orgs via
-- user_org_roles), and the rule itself has two branches, not one --
-- a caller always sees their OWN row's email/phone regardless of
-- capability (this is what /profile depends on), in addition to the
-- org.members.manage branch. Both branches live in the function, not the
-- view -- same reasoning as contracts 3.1.
--
-- The capability check is bound to the SAME shared organization as the
-- membership check, in one EXISTS with one join, not two independent
-- conditions (shares_org_with() AND has_capability() checked separately
-- would let org.members.manage in org A unlock a member of org B on the
-- strength of both sharing unrelated org C -- deliberately not written
-- that way).
--
-- Reuses app_masking_owner (created for contracts, 202608190001) rather
-- than a second dedicated role -- it was already named generically (not
-- app_contracts_masking_owner), already NOLOGIN/NOBYPASSRLS/INHERIT,
-- already a member of authenticated, already holds USAGE+CREATE on
-- schema app. Only new state added is the SELECT grant below and this
-- function's ownership.

-- ============================================================================
-- Direct grant for the columns this function's own read of public.users
-- needs (id to find the row, email/phone -- the masked columns
-- themselves). Not inherited from authenticated's grant: that grant is
-- staying untouched in this step, and will exclude email/phone once step
-- 3 flips it -- this role needs its own standing access independent of
-- that, same relationship as contracts' equivalent grant.
grant select (id, email, phone) on public.users to app_masking_owner;

-- ============================================================================
-- The masking function. own-row branch first (unconditional -- this is
-- what /profile depends on, per the SAD's explicit requirement that a
-- user always sees their own email/phone regardless of capability), OR
-- the bound shared-org + capability check.
--
-- Platform owner: confirmed live, not assumed, before writing this --
-- the real platform_owner fixture (test+platform@wowlab.dev) has ZERO
-- rows in user_org_roles (DATABASE_CONVENTIONS.md #3: platform owner is
-- cross-org via users.is_platform_owner, deliberately never forced into
-- a user_org_roles row). has_capability()'s own is_platform_owner()
-- bypass only fires once the EXISTS's own join already found a `mine`
-- row to evaluate it against -- with zero user_org_roles rows, `mine`
-- matches nothing, the join produces no rows to check has_capability()
-- against at all, and the bypass never gets a chance to apply. Net
-- effect: platform owner sees their OWN row's email/phone (first branch,
-- unaffected), but NOT another user's, through this function, unless
-- they separately hold a real org membership.
--
-- CONFIRMED CORRECT, not a gap (Mihai, after seeing this reported):
-- platform owner operates the platform, not any organization. Auto-
-- reading every person's email and phone across every org is not a
-- default worth having under GDPR. If they need access to a specific
-- org's members, they get a real membership in it, same as anyone else.
-- No is_platform_owner() branch added here, deliberately -- see
-- docs/WOWLAB_SAD_Field_Masking.md §2.3 for the same note, including how
-- this differs from contracts (app.belongs_to_org() folds in
-- is_platform_owner() there) and why that's a difference to record, not
-- an inconsistency to fix.
create function app.masked_user_contact_fields(target_user_id uuid)
returns record
language sql
security definer
set search_path = ''
as $$
  select case
    when target_user_id = app.current_user_id()
      or exists (
        select 1
        from public.user_org_roles mine
        join public.user_org_roles theirs
          on theirs.organization_id = mine.organization_id
        where mine.user_id = app.current_user_id()
          and theirs.user_id = target_user_id
          and app.has_capability('org.members.manage', mine.organization_id)
      )
    then row(u.email, u.phone)
    else null
  end
  from public.users u
  where u.id = target_user_id;
$$;

-- Trap 5.6 (temporary membership for the owner transfer) + 5.7 (that
-- membership must be held through every grant/revoke on the function,
-- not just through OWNER TO -- given up last, not right after the
-- transfer).
grant app_masking_owner to postgres;
alter function app.masked_user_contact_fields(uuid) owner to app_masking_owner;
revoke execute on function app.masked_user_contact_fields(uuid) from public;
grant execute on function app.masked_user_contact_fields(uuid) to authenticated;
revoke app_masking_owner from postgres;

-- ============================================================================
-- The view. security_invoker = true -- row visibility keeps resolving
-- through the caller's own grants/RLS on public.users (the existing
-- "authenticated select users" policy, 202607080002-era), unchanged by
-- this migration. Column order matches the base table's own ordinal
-- position exactly (id, email, full_name, status, is_platform_owner,
-- created_at, updated_at, first_name, last_name, phone, avatar_url,
-- is_test_account) -- only email/phone become lateral-joined output
-- instead of direct passthrough.
create view public.users_masked
with (security_invoker = true)
as
select
  u.id,
  f.email,
  u.full_name,
  u.status,
  u.is_platform_owner,
  u.created_at,
  u.updated_at,
  u.first_name,
  u.last_name,
  f.phone,
  u.avatar_url,
  u.is_test_account
from public.users u
cross join lateral app.masked_user_contact_fields(u.id)
  as f(email text, phone text);

comment on view public.users_masked is 'SECURITY INVOKER view over users: nulls email and phone unless the caller is viewing their own row, or holds org.members.manage in an organization they share with the target row''s user (both conditions bound to the SAME organization_id in one EXISTS -- never checked as two independent conditions, which would let org.members.manage in org A unlock a member of org B via an unrelated shared org C). Resolved once per row via app.masked_user_contact_fields() (SECURITY DEFINER, owned by app_masking_owner, shared with contracts'' masking -- see docs/WOWLAB_SAD_Field_Masking.md 3.1/5.5/5.6/5.7). Platform owner sees their own row via the first branch same as anyone; they do NOT automatically see other users'' email/phone through this view unless they separately hold a real user_org_roles membership -- confirmed live and confirmed CORRECT (not a gap): platform owner operates the platform, not any org, and auto-reading everyone''s contact PII across every org is not a default worth having under GDPR (see the function''s own comment, and SAD §2.3). Row visibility is inherited unchanged from the base table''s existing RLS policy via this view''s own security_invoker=true. GRANTS ON public.users ARE UNCHANGED as of this migration -- this view exists alongside the base table; nothing depends on it yet.';

-- A new view needs its own initial grant regardless -- distinct from "the
-- base table's grants stay unchanged this step" (contracts_billing_masked
-- didn't need this line here only because that grant already existed
-- from an earlier migration; this view has never existed before now).
grant select on public.users_masked to authenticated;
