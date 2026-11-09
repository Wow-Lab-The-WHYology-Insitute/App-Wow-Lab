-- Rollback for 202611090006_comment_contract_type_uplift_tables.sql
-- Purely additive (COMMENT ON TABLE) -- trivially reversible by clearing
-- the comments back to NULL.

comment on table public.contract_type_uplift_versions is null;
comment on table public.contract_type_uplift_rates is null;
