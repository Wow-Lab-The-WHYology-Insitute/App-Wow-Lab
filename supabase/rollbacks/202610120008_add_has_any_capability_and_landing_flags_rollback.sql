-- Rollback for 202610120008 -- drops both functions and their wrappers.
--
-- Lossless: functions hold no data. But NOT safe while the deployed app calls
-- them: lib/landing.ts resolves the post-sign-in destination through
-- public.resolve_landing_flags, and without it every sign-in would fall to the
-- function's own failure path. Revert the app code first, or accept that every
-- account lands on /profile until it is restored -- which is the fail-closed
-- direction, not a lockout.
--
-- app.has_capability is NOT touched. It predates this migration and everything
-- else in the schema depends on it.

drop function if exists public.resolve_landing_flags(text, text[]);
drop function if exists public.has_any_capability(text[], uuid);
drop function if exists app.resolve_landing_flags(text, text[]);
drop function if exists app.has_any_capability(text[], uuid);
