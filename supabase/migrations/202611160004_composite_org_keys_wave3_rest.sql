-- 202611160004_composite_org_keys_wave3_rest.sql
--
-- Tenant isolation, wave 3 of 3 (OPEN_ITEMS item 198): the remaining 6
-- foreign keys between org-scoped tables -- on-site contacts, lesson plans,
-- suppliers. After this, NO single-column foreign key exists between two
-- org-scoped tables, and the self-test below asserts exactly that, as a
-- class, not key by key. Reasoning as in 202611160002 (wave 1, read its
-- header).
--
-- Tests first, failing against the live schema
-- (db/tests/cross_org_write_isolation.sql points 12-14): all 6 cross-org
-- writes accepted, each with its control accepted; point 13 (the class)
-- named these 6 as the only plain keys left.
--
-- No observable probe for this wave, a negative result recorded (§20): no
-- wow-lab figure, status or screen was found that a cross-org row here would
-- move; every reader found is RLS-scoped to the child's organization or a
-- DEFINER RPC checking the row's own organization (item 198's map).
--
-- Measured before writing: 0 existing cross-org references across all 6.
-- Delete rules kept: session_lesson_plans.session_id and
-- lesson_plan_modules.lesson_plan_id cascade, the rest NO ACTION. Nullable
-- keys (on_site_contact_id, amends_contract_id) stay MATCH SIMPLE.
--
-- Out of scope by design, as in waves 1-2: keys to `users` (global) and to
-- `organizations` (the organization is the parent).

-- 1. The parents without a referenceable (id, organization_id) yet.
alter table public.client_contacts add constraint client_contacts_id_organization_id_key unique (id, organization_id);
alter table public.sessions add constraint sessions_id_organization_id_key unique (id, organization_id);
alter table public.lesson_plans add constraint lesson_plans_id_organization_id_key unique (id, organization_id);
alter table public.suppliers add constraint suppliers_id_organization_id_key unique (id, organization_id);
alter table public.supplier_contracts add constraint supplier_contracts_id_organization_id_key unique (id, organization_id);

-- 2. The six keys.
alter table public.groups drop constraint groups_on_site_contact_id_fkey;
alter table public.groups add constraint groups_on_site_contact_id_org_fkey
  foreign key (on_site_contact_id, organization_id) references public.client_contacts (id, organization_id);
alter table public.session_lesson_plans drop constraint session_lesson_plans_session_id_fkey;
alter table public.session_lesson_plans add constraint session_lesson_plans_session_id_org_fkey
  foreign key (session_id, organization_id) references public.sessions (id, organization_id) on delete cascade;
alter table public.session_lesson_plans drop constraint session_lesson_plans_lesson_plan_id_fkey;
alter table public.session_lesson_plans add constraint session_lesson_plans_lesson_plan_id_org_fkey
  foreign key (lesson_plan_id, organization_id) references public.lesson_plans (id, organization_id);
alter table public.lesson_plan_modules drop constraint lesson_plan_modules_lesson_plan_id_fkey;
alter table public.lesson_plan_modules add constraint lesson_plan_modules_lesson_plan_id_org_fkey
  foreign key (lesson_plan_id, organization_id) references public.lesson_plans (id, organization_id) on delete cascade;
alter table public.supplier_contracts drop constraint supplier_contracts_supplier_id_fkey;
alter table public.supplier_contracts add constraint supplier_contracts_supplier_id_org_fkey
  foreign key (supplier_id, organization_id) references public.suppliers (id, organization_id);
alter table public.supplier_contracts drop constraint supplier_contracts_amends_contract_id_fkey;
alter table public.supplier_contracts add constraint supplier_contracts_amends_contract_id_org_fkey
  foreign key (amends_contract_id, organization_id) references public.supplier_contracts (id, organization_id);

-- 3. Self-test, the class: no single-column foreign key between two
-- org-scoped tables survives anywhere in public.
do $$
declare
  v_left text;
begin
  select string_agg(cl.relname || '.' || a.attname || ' -> ' || pc.relname, ', ') into v_left
  from pg_constraint con
  join pg_class cl on cl.oid = con.conrelid
  join pg_class pc on pc.oid = con.confrelid
  join pg_attribute a on a.attrelid = con.conrelid and a.attnum = con.conkey[1]
  where con.contype = 'f' and cl.relnamespace = 'public'::regnamespace
    and array_length(con.conkey, 1) = 1
    and exists (select 1 from pg_attribute x where x.attrelid = cl.oid and x.attname = 'organization_id' and not x.attisdropped)
    and exists (select 1 from pg_attribute x where x.attrelid = pc.oid and x.attname = 'organization_id' and not x.attisdropped);
  if v_left is not null then
    raise exception '202611160004 self-test: single-column keys between org-scoped tables remain: %', v_left;
  end if;
end;
$$;
