-- 202608100005_seed_clients_contracts_test_fixtures.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — test fixture users.
--
-- Same rationale as 202608100002: this is TEST-ONLY fixture data (mirrors
-- supabase/seed.sql part 9-10's test+role@wowlab.dev pattern exactly), but
-- delivered as a migration too so it reaches the already-provisioned live
-- remote via `db push`, without requiring a separate seed.sql apply/reset.
-- supabase/seed.sql carries the same rows as the canonical source for future
-- `db reset` runs.
--
-- No sales_manager or contract_administrator test user existed before this
-- (only finance_operations/finance_admin_reporting/trainer/owner roles had
-- one) — needed for db/tests/rls_clients_contracts.sql.
--
-- Idempotent: identical on-conflict pattern as supabase/seed.sql parts 9-10.

insert into public.users (id, email, full_name, status, is_platform_owner)
values
  (gen_random_uuid(), 'test+sales-a@wowlab.dev', 'Test Sales Manager A', 'active', false),
  (gen_random_uuid(), 'test+contract-admin-a@wowlab.dev', 'Test Contract Administrator A', 'active', false)
on conflict (email) do update
  set full_name = excluded.full_name,
      status = excluded.status,
      is_platform_owner = excluded.is_platform_owner,
      updated_at = now();

insert into public.user_org_roles (organization_id, user_id, role_id)
select o.id, u.id, r.id
from (
  values
    ('test+sales-a@wowlab.dev', 'wow-lab', 'sales_manager'),
    ('test+contract-admin-a@wowlab.dev', 'wow-lab', 'contract_administrator')
) as m(user_email, org_slug, role_key)
join public.users u on u.email = m.user_email
join public.organizations o on o.slug = m.org_slug
join public.roles r on r.key = m.role_key
on conflict (organization_id, user_id, role_id) do nothing;
