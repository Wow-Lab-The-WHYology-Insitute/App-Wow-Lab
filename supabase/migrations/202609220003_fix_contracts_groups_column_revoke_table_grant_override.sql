-- Fixes a real bug in 202609220001, caught by db/tests/rls_write_routing_
-- functions.sql's own raw-write test on its first run, not assumed
-- correct because the column-level REVOKE statement looked right:
-- REVOKE UPDATE (col) ON table FROM authenticated does NOT remove
-- authenticated's ability to write that column when a BROADER
-- table-level GRANT UPDATE ON table TO authenticated (202608100003 for
-- contracts, 202608130003 for groups) already exists -- Postgres ACL
-- entries are additive; a table-wide grant continues to authorize every
-- column regardless of a narrower column-level revoke layered on top.
-- Confirmed live: information_schema.column_privileges still showed
-- authenticated/UPDATE on billing_rule after 202609220001 supposedly
-- revoked it, and a direct impersonated UPDATE succeeded with no
-- exception. The three financial columns and children_confirmed were
-- NEVER actually protected between 202609220001 landing and this fix --
-- confirmed by that same raw-write test, which is exactly what it was
-- built to catch.
--
-- Real fix, matching the already-established SELECT-masking pattern
-- (contracts_field_masking, 202608190001; users_field_masking_grants,
-- 202608210001) applied to UPDATE/INSERT instead of SELECT: REVOKE the
-- table-level grant entirely, then GRANT it back on the explicit column
-- list minus the protected ones -- the only way to actually narrow a
-- column set downward from a table-wide grant.

revoke update on public.contracts from authenticated;
revoke insert on public.contracts from authenticated;
grant update (id, organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, status, renewal_of, drive_ref, notes, created_at, updated_at, signed_date, offer_structure, ac_link, entry_number, exit_number) on public.contracts to authenticated;
grant insert (id, organization_id, client_id, legal_entity_id, contract_type, period_start, period_end, status, renewal_of, drive_ref, notes, created_at, updated_at, signed_date, offer_structure, ac_link, entry_number, exit_number) on public.contracts to authenticated;

revoke update on public.groups from authenticated;
revoke insert on public.groups from authenticated;
grant update (id, organization_id, client_id, module, delivery_format, schedule_pattern, children_billed, status, notes, created_at, updated_at, age_range, school_year_calendar_link, contract_id, address, on_site_contact_id) on public.groups to authenticated;
grant insert (id, organization_id, client_id, module, delivery_format, schedule_pattern, children_billed, status, notes, created_at, updated_at, age_range, school_year_calendar_link, contract_id, address, on_site_contact_id) on public.groups to authenticated;

comment on function app.rpc_set_contract_financials(uuid, text, numeric, numeric) is 'Item 91, bug-fixed 202609220003: only writer of contracts.billing_rule/estimated_value/previous_year_value. The 202609220001 column-level revoke alone did nothing -- authenticated''s pre-existing table-wide UPDATE/INSERT grant (202608100003) still covered these columns until this migration also revoked the table-level grant and re-granted the explicit non-financial column list. Gate: finance.operations.* OR finance.reporting.* OR clients.create -- addContract/updateContract''s own existing financeVisible check, restated verbatim.';

comment on function app.rpc_set_group_children_confirmed(uuid, int) is 'Item 91, bug-fixed 202609220003: only writer of groups.children_confirmed. Same table-wide-grant-overrides-column-revoke bug as contracts, same fix (202608130003''s table-level grant revoked and re-granted on the explicit non-children_confirmed column list). Gate: is_platform_owner() OR org.settings.manage OR contracts.*.';
