-- 202608310002_payment_config_tables_rollback.sql
-- Rolls back 202608310002: drops the six resolver functions, then the
-- eleven tables in dependency order (rates/assignments before their
-- version parents, so FKs never block a drop). Restores exact
-- pre-migration state -- none of this existed before, nothing else was
-- touched by the forward migration.
--
-- Lives in supabase/rollbacks/, never supabase/migrations/ (SAD Sec6.2).

drop function if exists app.resolve_trainer_grade(uuid, date);
drop function if exists app.resolve_trainer_grade_rate(uuid, integer, date);
drop function if exists app.resolve_location_bonus(uuid, text, date);
drop function if exists app.resolve_language_bonus(uuid, text, date);
drop function if exists app.resolve_duration_multiplier(uuid, integer, text, date);
drop function if exists app.resolve_contract_type_uplift(uuid, text, date);

drop table if exists public.trainer_grade_assignments;

drop table if exists public.contract_type_uplift_rates;
drop table if exists public.contract_type_uplift_versions;

drop table if exists public.duration_multiplier_rates;
drop table if exists public.duration_multiplier_versions;

drop table if exists public.language_bonus_rates;
drop table if exists public.language_bonus_versions;

drop table if exists public.location_bonus_rates;
drop table if exists public.location_bonus_versions;

drop table if exists public.trainer_grade_rates;
drop table if exists public.trainer_grade_versions;
