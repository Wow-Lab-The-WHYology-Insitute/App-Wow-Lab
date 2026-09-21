-- 202609210001_add_one_off_workshop_extension_fields.sql
-- OPEN_ITEMS.md item 52: the volume ratio (recurring 3.8:1 one-off,
-- widening) closed the fork toward recurring-as-primary -- one-off
-- workshops get the fields they're missing as an extension of
-- groups/sessions, not a second, parallel entity. This migration is
-- three of those fields: time range, address, on-site contact.
--
-- Anca's own precedent for children_confirmed/children_billed applies
-- here too (item 39): available on every delivery_format, blank where
-- not needed, not gated on delivery_format -- whose own column comment
-- already calls it "NOT explicitly confirmed by Anca," an unconfirmed
-- categorization no field should be conditioned on.
--
-- ============================================================================
-- 1. Time range -- start only, end derived at read time.
-- ============================================================================
-- Same "don't store what you can derive" precedent as contract expiry
-- and children_billed (item 39, finding 1): storing an end time
-- alongside start+duration would let the two disagree, with nothing
-- keeping them in sync. duration_minutes is already nullable and stays
-- that way -- requiring it the moment start_time is set would be a new
-- constraint nothing asks for. A session with a start time but no
-- duration shows the start alone; the app derives
-- start_time + duration_minutes at read time only when both exist.
alter table public.sessions
  add column if not exists start_time time;

comment on column public.sessions.start_time is 'Local clock time the session starts -- date lives separately in session_date, matching the existing session_date/duration_minutes split. No end_time column: derived at read time as start_time + duration_minutes when both are set, never stored, same precedent as contract expiry and children_billed (docs/OPEN_ITEMS.md item 39). Not defaulted from groups.schedule_pattern -- that column is free text with no enforced grammar (confirmed live, no code parses it), so nothing here guesses a time out of it.';

-- ============================================================================
-- 2. Address -- client-level default, group-level override, nothing on
--    sessions. Argued directly against the volume ratio (item 52): at
--    roughly 4:1 recurring, the dominant case is one client address
--    shared by every session of every group at that client -- putting
--    this on sessions would mean re-entering the same string per
--    occurrence for the majority of what this business delivers.
--    Group-level override exists for the real minority the type list
--    names (a mall event, an off-site collaboration) where a specific
--    group's delivery location genuinely differs from its client's own.
-- ============================================================================
alter table public.clients
  add column if not exists address text;

comment on column public.clients.address is 'Free text, no structured parts -- same "no stricter shape enforced" treatment already applied to schedule_pattern and age_range on groups. The default delivery address for every group at this client; groups.address (below) overrides it per group when a specific workshop happens somewhere else.';

alter table public.groups
  add column if not exists address text;

comment on column public.groups.address is 'Override for clients.address, for the minority of groups whose delivery location differs from their client''s own registered address (a mall event, an off-site occasional collaboration -- see the nine-value Tip Atelier list, docs/OPEN_ITEMS.md item 52). NULL means "use the client''s address" -- resolved with COALESCE(groups.address, clients.address) at read time, not backfilled or defaulted here.';

-- ============================================================================
-- 3. On-site contact -- a link to an existing client_contacts row,
--    constrained to that client's own contacts (enforced in the action,
--    same pattern as groups.contract_id's client-ownership check --
--    a raw FK alone can't express "belongs to the same client as this
--    group"), not a free-text name/phone duplicate of a real record.
-- ============================================================================
alter table public.groups
  add column if not exists on_site_contact_id uuid references public.client_contacts(id);

comment on column public.groups.on_site_contact_id is 'The client_contacts row for whoever meets the trainer on-site for this workshop. Nullable, workshop-level (not per-session) -- matches address above. Deliberately independent of that contact''s own contact_purpose: linking a contact here does not itself make them trainer-visible -- see 202609210002, which requires contact_purpose = ''trainer_facing'' on top of this link before a trainer can see the row at all. Validated in the action layer (addGroup/updateGroup) that the linked contact''s client_id matches this group''s own client_id -- a raw FK reference cannot express that constraint.';

create index if not exists groups_on_site_contact_id_idx on public.groups(on_site_contact_id);
