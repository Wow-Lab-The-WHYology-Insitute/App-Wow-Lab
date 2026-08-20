-- 202608200001_fix_masking_function_execute_grant.sql
-- Fixes an ACL gap left by 202608190001_contracts_field_masking.sql.
-- 202608190001 itself is left untouched — this runs as a fresh migration
-- on top of it, not an edit to already-applied history. A replay of both
-- files in order goes broken-then-fixed and converges on the correct
-- final state either way.
--
-- Diagnosis (docs/WOWLAB_SAD_Field_Masking.md, trap 5.7): 202608190001
-- revoked postgres's temporary membership in app_masking_owner (granted
-- only to make ALTER FUNCTION ... OWNER TO legal, per trap 5.6) BEFORE
-- running `revoke execute ... from public` / `grant execute ... to
-- authenticated`. Reproduced in a rolled-back transaction against a
-- throwaway function: those two statements, run while postgres no longer
-- belongs to the owning role, complete without error (soft warnings only
-- -- 01006/01007, "no privileges could be revoked/granted") but do not
-- actually change the ACL. The function's default (PUBLIC has EXECUTE)
-- survives. Confirmed live: pg_proc.proacl for
-- app.masked_contract_financials is currently
-- `{=X/app_masking_owner,app_masking_owner=X/app_masking_owner}` --
-- PUBLIC has execute, authenticated does not have an explicit grant of its
-- own (it reaches the function only transitively, through PUBLIC).
--
-- Practical risk today is low, not zero: schema app is still unexposed to
-- PostgREST, and the function's own double predicate (belongs_to_org +
-- capability, both keyed off the real caller's request.jwt.claims,
-- unaffected by who owns or can execute the function) returns null to
-- any caller without genuine org membership and capability -- an anon
-- caller reaching this function despite the PUBLIC grant still gets null,
-- not real data. This fix closes the gap anyway rather than relying on
-- that second layer alone.
--
-- Order matters (this is the fix): grant the temporary membership back,
-- run the revoke/grant pair WHILE still a member, then give up the
-- membership last. Verified in a rolled-back dry run against the real
-- function before this file was applied -- see the conversation record
-- for the exact proacl before/after.
grant app_masking_owner to postgres;
revoke execute on function app.masked_contract_financials(uuid) from public;
grant execute on function app.masked_contract_financials(uuid) to authenticated;
revoke app_masking_owner from postgres;
