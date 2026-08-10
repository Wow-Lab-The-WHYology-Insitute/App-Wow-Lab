-- 202608100003_add_clients_contracts_rls_policies.sql
-- WOW LAB OS, Phase 1: Clients & Contracts domain (C1) — RLS policies
-- (Menu/Record/Action levels; Field-level masking is migration 0004).
--
-- Design note — capability-based branching, not hardcoded role names
-- (DATABASE_CONVENTIONS.md #6): contract_administrator and
-- finance_admin_reporting hold the IDENTICAL capability key 'contracts.*',
-- but need different record-level scope (contract_administrator:
-- unrestricted; finance_admin_reporting: restricted to non-private_school-
-- linked clients). The same key alone can't distinguish them, so every
-- "unrestricted" branch below explicitly excludes callers who also hold
-- finance.operations.* or finance.reporting.* (which only the two finance
-- roles hold), pushing them to their own restricted branch instead. This
-- mirrors the existing pattern of referencing capability keys literally in
-- policy SQL (e.g. 'org.audit.read' in 202607100002) — it does not
-- hardcode a role name anywhere.
--
-- 'org.settings.manage' is used as the organization_owner marker, exactly
-- as in 202607100004 (organizations/org_settings UPDATE policies) — it is
-- granted to organization_owner only via the B4 seed's dynamic "all
-- non-platform.* capabilities" grant, so no other role can match it.
--
-- parent_b2c ASSUMPTION: the SAD (§3/§6) only names "școli private" for
-- Finance Operations and "corporate + stat + granturi" for Finance Admin &
-- Reporting — parent_b2c is not mentioned by either. Per the task's own
-- suggested default, parent_b2c is grouped with private_school under the
-- finance_operations branch below (small-scale reasoning). Flagged again in
-- the final report — this is an assumption, not a confirmed decision.
--
-- Idempotent: GRANT is naturally re-runnable; CREATE POLICY is guarded by a
-- pg_policies existence check, matching 202607100002/202607100004.

-- ============================================================================
-- Base GRANTs.
-- ============================================================================
grant select, insert, update on public.clients to authenticated;
grant select, insert, update on public.client_contacts to authenticated;
grant select, insert, update on public.contracts to authenticated;
-- No DELETE grant anywhere — deny-by-default per DATABASE_CONVENTIONS.md #7,
-- reinforced by 202607100008's default-privileges revoke for tables created
-- by `postgres` (the role migrations run as), same as every WS-D table.

-- ============================================================================
-- clients — SELECT (menu + record level).
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'clients' and policyname = 'authenticated select clients'
  ) then
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
      );
  end if;
end;
$$;

-- clients — INSERT (sales_manager, per SAD §6 "sales_manager poate crea
-- client"). UPDATE mirrors INSERT — the task only specified INSERT
-- explicitly; granting UPDATE to the same capability set is an inferred
-- default (flagged in the final report), not a literal instruction.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'clients' and policyname = 'authenticated insert clients'
  ) then
    create policy "authenticated insert clients" on public.clients
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
      );
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'clients' and policyname = 'authenticated update clients'
  ) then
    create policy "authenticated update clients" on public.clients
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
      );
  end if;
end;
$$;

-- ============================================================================
-- client_contacts — SELECT, record-level mirrored from the linked client's
-- client_type (this table has no client_type column of its own). Neither
-- the task nor the SAD specifies this join explicitly for client_contacts —
-- extending the same segregation here (rather than leaving contacts
-- unfiltered) is an inferred decision, flagged in the final report: PII on
-- an otherwise-invisible-to-you client would be a stranger gap otherwise.
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'client_contacts' and policyname = 'authenticated select client_contacts'
  ) then
    create policy "authenticated select client_contacts" on public.client_contacts
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
          and exists (
            select 1 from public.clients cl
            where cl.id = client_contacts.client_id
              and cl.client_type in ('private_school', 'parent_b2c')
          )
        )
        or (
          app.has_capability('finance.reporting.*', organization_id)
          and exists (
            select 1 from public.clients cl
            where cl.id = client_contacts.client_id
              and cl.client_type not in ('private_school', 'parent_b2c')
          )
        )
      );
  end if;
end;
$$;

-- client_contacts — INSERT/UPDATE. Neither the task nor the SAD specifies
-- action-level rules for this table. Inferred default (flagged in the final
-- report): whoever can own the client relationship (clients.create =
-- sales_manager) or the contract (contracts.* excluding the two finance
-- roles = contract_administrator) can manage its contacts, plus org/platform
-- owner.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'client_contacts' and policyname = 'authenticated insert client_contacts'
  ) then
    create policy "authenticated insert client_contacts" on public.client_contacts
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'client_contacts' and policyname = 'authenticated update client_contacts'
  ) then
    create policy "authenticated update client_contacts" on public.client_contacts
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or app.has_capability('clients.create', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      );
  end if;
end;
$$;

-- ============================================================================
-- contracts — SELECT (menu + record level). client_type lives on clients,
-- not contracts, so the finance branches join through client_id.
-- ============================================================================
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'contracts' and policyname = 'authenticated select contracts'
  ) then
    create policy "authenticated select contracts" on public.contracts
      for select
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          (app.has_capability('contracts.*', organization_id) or app.has_capability('contracts.read', organization_id))
          and not app.has_capability('finance.operations.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
        )
        or (
          app.has_capability('finance.operations.*', organization_id)
          and exists (
            select 1 from public.clients cl
            where cl.id = contracts.client_id
              and cl.client_type in ('private_school', 'parent_b2c')
          )
        )
        or (
          app.has_capability('finance.reporting.*', organization_id)
          and exists (
            select 1 from public.clients cl
            where cl.id = contracts.client_id
              and cl.client_type not in ('private_school', 'parent_b2c')
          )
        )
      );
  end if;
end;
$$;

-- contracts — INSERT/UPDATE: contract_administrator (+ Master) only. This is
-- the one place finance_admin_reporting's shared 'contracts.*' key MUST NOT
-- grant write access (task: "Only contract_administrator (+ Master) can
-- INSERT/UPDATE contracts") — the "not finance.reporting.*"/"not
-- finance.operations.*" exclusions are load-bearing here, not decorative.
DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'contracts' and policyname = 'authenticated insert contracts'
  ) then
    create policy "authenticated insert contracts" on public.contracts
      for insert
      to authenticated
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'contracts' and policyname = 'authenticated update contracts'
  ) then
    create policy "authenticated update contracts" on public.contracts
      for update
      to authenticated
      using (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      )
      with check (
        app.is_platform_owner()
        or app.has_capability('org.settings.manage', organization_id)
        or (
          app.has_capability('contracts.*', organization_id)
          and not app.has_capability('finance.reporting.*', organization_id)
          and not app.has_capability('finance.operations.*', organization_id)
        )
      );
  end if;
end;
$$;
