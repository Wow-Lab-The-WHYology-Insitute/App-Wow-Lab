-- seed.sql
-- WOW LAB OS, Phase 0 WS-B (B4): canonical roles, capabilities, and role-capability map.
-- Idempotent: upsert on natural keys (roles.key, capabilities.key, role_capabilities(role_id, capability_id)).
-- Re-running this file must not create duplicates or duplicate role_capabilities rows.
-- Runs with the service role (bypasses RLS by design).

-- 1. Canonical roles (approved catalog; procurement_manager intentionally excluded/deferred).
insert into public.roles (key, name, display_name, description, is_system)
values
  ('platform_owner', 'Platform Owner', 'Platform Owner',
    'Cross-org superuser. Cross-org access is granted via users.is_platform_owner, not user_org_roles; this role row exists for capability completeness and UI.', true),
  ('organization_owner', 'Organization Owner', 'Organization Owner',
    'Master / CEO — full authority within own organization.', true),
  ('sales_manager', 'Sales Manager', 'Sales Manager',
    'Sales pipeline: clients, conversions, renewals, CRM link to ActiveCampaign.', true),
  ('contract_administrator', 'Contract Administrator', 'Contract Administrator',
    'Full contract lifecycle management.', true),
  ('operations_manager', 'Operations Manager', 'Operations Manager',
    'Operations & team: scheduling, trainer allocation, calendars, certification overrides.', true),
  ('curriculum_manager', 'Curriculum Manager', 'Curriculum Owner',
    'Curriculum ownership: content, feedback, validation, academy authoring, presentation governance, certification definitions.', true),
  ('finance_operations', 'Finance Operations', 'Finance Operations',
    'Trainer pay, reimbursements, private-school invoicing, attendance billing. Excludes company profitability/reporting.', true),
  ('finance_admin_reporting', 'Finance Administration & Reporting', 'Finance Administration & Reporting',
    'Company-wide reporting, revenue/cost, balance import, CEO dashboard data, corporate/state contracts, grants.', true),
  ('inventory_custodian', 'Inventory Custodian', 'Inventory Custodian',
    'Inventory items, movements, custody, status, and return validation. Excludes procurement (deferred).', true),
  ('community_people', 'Community & People', 'Community & People',
    'Community programs and trainer engagement.', true),
  ('senior_trainer', 'Senior Trainer', 'Senior Trainer',
    'Everything a trainer has; eligible to be additionally granted the evaluator role. No evaluations.write by default.', true),
  ('trainer', 'Trainer', 'Trainer',
    'Own work, curriculum read access, community read, own finance, materials custody, own presentations.', true),
  ('evaluator', 'Evaluator', 'Evaluator',
    'Read/write only on evaluations assigned to this user. Excludes finance, inventory admin, strategic reporting.', true),
  ('candidate', 'Candidate', 'Candidate',
    'Candidate portal only, magic-link access.', true)
on conflict (key) do update
  set name = excluded.name,
      display_name = excluded.display_name,
      description = excluded.description,
      is_system = excluded.is_system,
      updated_at = now();

-- 2. Capability reference (key = domain.resource.action; '*' denotes "all actions/resources in that
-- namespace" and is stored as a literal capability row, not expanded into an invented CRUD list).
insert into public.capabilities (key, domain, resource, action, description)
values
  ('platform.cross_org.access', 'platform', 'cross_org', 'access', 'Cross-organization access for the platform owner.'),
  ('platform.admin.manage', 'platform', 'admin', 'manage', 'Platform administration capabilities.'),
  ('platform.org_switcher.use', 'platform', 'org_switcher', 'use', 'Use the organization switcher UI.'),

  ('clients.create', 'clients', 'clients', 'create', 'Create client/prospect records.'),
  ('clients.convert', 'clients', 'clients', 'convert', 'Convert a prospect into an active client.'),
  ('clients.read', 'clients', 'clients', 'read', 'Read client records.'),
  ('renewals.read', 'renewals', 'renewals', 'read', 'Read contract renewal data.'),
  ('crm_link.*', 'crm_link', 'crm_link', '*', 'ActiveCampaign CRM reference/link. Proposals themselves live in ActiveCampaign and are not seeded here.'),

  ('contracts.*', 'contracts', 'contracts', '*', 'Full contract lifecycle management.'),
  ('contracts.read', 'contracts', 'contracts', 'read', 'Read contracts (private scope).'),

  ('operations.*', 'operations', 'operations', '*', 'Full operations & team management.'),
  ('trainers.allocate', 'trainers', 'trainers', 'allocate', 'Allocate trainers to sessions.'),
  ('trainers.substitute', 'trainers', 'trainers', 'substitute', 'Substitute a trainer on a session.'),
  ('calendars.*', 'calendars', 'calendars', '*', 'Full calendar management.'),
  ('certifications.override', 'certifications', 'certifications', 'override', 'Override a certification status/outcome.'),
  ('certifications.define', 'certifications', 'certifications', 'define', 'Define certification requirements.'),
  ('alerts.operational.read', 'alerts', 'operational', 'read', 'Read operational alerts.'),

  ('curriculum.*', 'curriculum', 'curriculum', '*', 'Full curriculum ownership.'),
  ('curriculum.feedback.*', 'curriculum', 'feedback', '*', 'Manage curriculum feedback.'),
  ('curriculum.validate', 'curriculum', 'curriculum', 'validate', 'Validate curriculum content.'),
  ('curriculum.read', 'curriculum', 'curriculum', 'read', 'Read curriculum content.'),
  ('academy.*', 'academy', 'academy', '*', 'Module content and quiz authoring.'),
  ('presentations.*', 'presentations', 'presentations', '*', 'Presentation governance; approve-to-official.'),
  ('presentations.own', 'presentations', 'presentations', 'own', 'Manage own presentations only (own-data scope).'),
  ('materials.requirements.*', 'materials', 'requirements', '*', 'Manage material requirements.'),
  ('materials.custody', 'materials', 'materials', 'custody', 'Custody of assigned materials.'),

  ('finance.operations.*', 'finance', 'operations', '*', 'Trainer pay, reimbursements, private-school invoicing, attendance billing.'),
  ('finance.reporting.*', 'finance', 'reporting', '*', 'Company-wide reporting, revenue/cost, balance import, CEO dashboard data.'),
  ('finance.own.read', 'finance', 'own', 'read', 'Read own finance data.'),
  ('grants.*', 'grants', 'grants', '*', 'Grants management.'),

  ('inventory.*', 'inventory', 'inventory', '*', 'Inventory items, movements, custody, status, and return validation.'),

  ('community.*', 'community', 'community', '*', 'Full community & people management.'),
  ('community.read', 'community', 'community', 'read', 'Read community content.'),
  ('trainers.engagement.read', 'trainers', 'engagement', 'read', 'Read trainer engagement data.'),

  ('mywork.*', 'mywork', 'mywork', '*', 'Own work / assignments.'),

  ('evaluations.assigned.read', 'evaluations', 'assigned', 'read', 'Read evaluations assigned to this user.'),
  ('evaluations.assigned.write', 'evaluations', 'assigned', 'write', 'Write evaluations assigned to this user.'),

  ('candidate.portal.access', 'candidate', 'portal', 'access', 'Candidate portal access via magic link.')
on conflict (key) do update
  set domain = excluded.domain,
      resource = excluded.resource,
      action = excluded.action,
      description = excluded.description,
      updated_at = now();

-- 3. Explicit role -> capability grants for all roles except platform_owner and organization_owner,
-- which are granted every capability below (handled separately as "all capabilities").
insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from (
  values
    ('sales_manager', 'clients.create'),
    ('sales_manager', 'clients.convert'),
    ('sales_manager', 'clients.read'),
    ('sales_manager', 'renewals.read'),
    ('sales_manager', 'crm_link.*'),

    ('contract_administrator', 'contracts.*'),
    ('contract_administrator', 'clients.read'),

    ('operations_manager', 'operations.*'),
    ('operations_manager', 'clients.read'),
    ('operations_manager', 'trainers.allocate'),
    ('operations_manager', 'trainers.substitute'),
    ('operations_manager', 'calendars.*'),
    ('operations_manager', 'certifications.override'),
    ('operations_manager', 'alerts.operational.read'),

    ('curriculum_manager', 'curriculum.*'),
    ('curriculum_manager', 'curriculum.feedback.*'),
    ('curriculum_manager', 'curriculum.validate'),
    ('curriculum_manager', 'academy.*'),
    ('curriculum_manager', 'presentations.*'),
    ('curriculum_manager', 'materials.requirements.*'),
    ('curriculum_manager', 'certifications.define'),

    ('finance_operations', 'finance.operations.*'),
    ('finance_operations', 'contracts.read'),
    ('finance_operations', 'clients.read'),

    ('finance_admin_reporting', 'finance.reporting.*'),
    ('finance_admin_reporting', 'contracts.*'),
    ('finance_admin_reporting', 'grants.*'),
    ('finance_admin_reporting', 'clients.read'),

    ('inventory_custodian', 'inventory.*'),

    ('community_people', 'community.*'),
    ('community_people', 'trainers.engagement.read'),

    ('senior_trainer', 'mywork.*'),
    ('senior_trainer', 'curriculum.read'),
    ('senior_trainer', 'community.read'),
    ('senior_trainer', 'finance.own.read'),
    ('senior_trainer', 'materials.custody'),
    ('senior_trainer', 'presentations.own'),

    ('trainer', 'mywork.*'),
    ('trainer', 'curriculum.read'),
    ('trainer', 'community.read'),
    ('trainer', 'finance.own.read'),
    ('trainer', 'materials.custody'),
    ('trainer', 'presentations.own'),

    ('evaluator', 'evaluations.assigned.read'),
    ('evaluator', 'evaluations.assigned.write'),

    ('candidate', 'candidate.portal.access')
) as m(role_key, capability_key)
join public.roles r on r.key = m.role_key
join public.capabilities c on c.key = m.capability_key
on conflict (role_id, capability_id) do nothing;

-- 4. platform_owner: all capabilities (including platform.* cross-org/admin/org-switcher).
insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from public.roles r
cross join public.capabilities c
where r.key = 'platform_owner'
on conflict (role_id, capability_id) do nothing;

-- 5. organization_owner: all capabilities within own org (everything except the platform.* domain,
-- which is reserved for the cross-org platform_owner).
insert into public.role_capabilities (role_id, capability_id)
select r.id, c.id
from public.roles r
cross join public.capabilities c
where r.key = 'organization_owner'
  and c.domain <> 'platform'
on conflict (role_id, capability_id) do nothing;
