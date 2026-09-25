-- Rollback for 202609240003. LOSSY if run after any real group has had
-- its language_group set through the app -- dropping groups.language_group
-- discards whatever was entered there; re-adding sessions.language_group
-- restores an empty column, not the discarded values (there is no
-- session-level record of what they were, by design -- this migration's
-- whole point was that the fact belongs to the group, not the session).
-- Safe with zero data loss only if run before anyone uses the new field.

revoke update (language_group) on public.groups from authenticated;
revoke insert (language_group) on public.groups from authenticated;

alter table public.groups drop column language_group;

alter table public.sessions
  add column language_group text null
    check (language_group in ('ro_en', 'fr_de_es'));
