-- OPEN_ITEMS.md item 83, resolving it. Item 78 (202609210003) made
-- clients.status derived: only 'paused'/'churned' are real overrides,
-- everything else (including the literal string 'active', still held by
-- the 3 real WOW LAB rows) falls through to a signed-contract check.
-- Which of 'prospect'/'active' a row happened to hold stopped being
-- signal the day that shipped -- both mean exactly "no override," and
-- which one survives on a given row is an accident of write history, not
-- something anyone should read. Confirmed exhaustively (item 83's own
-- audit): no app code, RLS policy, view, or test read the raw column
-- wrong -- every genuine "what is this client's status" question already
-- went through public.client_effective_status(). The reader this was
-- actually wrong for is outside the app entirely -- Supabase Studio,
-- `supabase db query`, any future ad hoc script -- where no grant or
-- code-layer discipline reaches, because a person or a script reads a
-- column named `status` and reasonably believes it.
--
-- Rejected alternative (item 83): REVOKE SELECT on the raw column from
-- authenticated, keeping the name. Only protects PostgREST/authenticated
-- sessions -- Studio and `supabase db query` connect as a role that
-- REVOKE from authenticated does not touch, so it would leave the actual
-- risk completely unprotected while fixing a reader that was never wrong.
--
-- Chosen: rename the column to what it now holds. A rename protects every
-- reader uniformly -- Studio, psql, service_role, authenticated all see
-- the same renamed column, nobody can mistake it for "the status" by
-- habit, the same way billing_rule/estimated_value are protected from
-- being read as public data by living behind a differently-purposed
-- column, not a remembered grant.
--
-- ============================================================================
-- ACCEPTANCE TEST, run before this migration (all 4 real rows, both orgs)
-- ============================================================================
-- WOW LAB: Scoala Avenor (stored 'active' -> effective 'active'), Scoala
-- Germana (stored 'active' -> effective 'active'), Lycee Francais (stored
-- 'active' -> effective 'active'). WOW LAB Test Org B: MAX (stored
-- 'prospect' -> effective 'prospect'). No paused/churned rows exist
-- anywhere today. The rename must produce the IDENTICAL 4 effective
-- values after -- see scripts/verify_clients_status_override_rename.sql,
-- which re-derives all 4 inside the same rolled-back transaction as this
-- migration's exact DDL and asserts equality row by row, not just by eye.
--
-- ============================================================================
-- WHAT public.row_history HOLDS FOR public.clients, BEFORE AND AFTER THIS
-- MIGRATION -- READ THIS BEFORE INTERPRETING clients_row_history ENTRIES
-- ============================================================================
-- clients_row_history (202608100001) captures a full row_to_json snapshot
-- on every UPDATE/DELETE, before and after, as opaque jsonb -- it does not
-- know about column renames, and this migration does not (cannot) rewrite
-- history rows to match. Consequence, stated plainly for whoever reads
-- row_history next: entries with changed_at BEFORE this migration's
-- deploy carry the key "status" in old_values/new_values, with one of the
-- four original literal values ('prospect', 'active', 'paused',
-- 'churned') -- including Mihai's 2026-09-17 manual moves to 'active'.
-- Entries with changed_at AFTER carry the key "status_override" instead,
-- with one of ('paused', 'churned') or JSON null. There is no single
-- query that reads this column's history uniformly across the boundary --
-- filter by changed_at and read the correct key for each side, and do not
-- assume a missing "status_override" key on an old row means null; it
-- means the row predates the rename and used the other key.
--
-- ============================================================================
-- THE RENAME ITSELF
-- ============================================================================

-- 1. Make room for NULL before anything tries to reject it.
alter table public.clients alter column status drop not null;
alter table public.clients alter column status drop default;

-- 2. Backfill: 'prospect' and 'active' both meant "no override" the
-- moment item 78 shipped -- collapse both to the literal absence of one.
-- 'paused'/'churned' are untouched; they were always real, are still
-- real, and this statement does not match them.
update public.clients set status = null where status in ('prospect', 'active');

-- 3. Drop the old 4-value constraint before the rename so the column
-- being renamed is never, even momentarily, both wrongly named and
-- wrongly constrained.
alter table public.clients drop constraint clients_status_check;

-- 4. The rename. addClient/changeClientStatus and every other writer or
-- reader are updated in this same round -- confirmed by item 83's
-- exhaustive audit that nothing else references the old name.
alter table public.clients rename column status to status_override;

-- 5. The new, honest constraint: exactly what a manual override can be.
alter table public.clients
  add constraint clients_status_override_check
  check (status_override is null or status_override in ('paused', 'churned'));

comment on column public.clients.status_override is
  'Manual override only -- NULL means none. paused/churned are the two real values this column can hold; the literal strings prospect/active are no longer legal here because they never meant anything stored, only "no override" (item 78/83). The client''s actual status is always public.client_effective_status(clients), never this column read directly -- see that function''s own comment for the derivation. Written only by changeClientStatus (app/(app)/clients/actions.ts); "reactivate" (paused/churned -> active) writes literal NULL, not a borrowed status word.';

-- ============================================================================
-- public.client_effective_status(): same shape, new column name
-- ============================================================================
create or replace function public.client_effective_status(c public.clients)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when c.status_override is not null then c.status_override
    when exists (
      select 1 from public.contracts ct
      where ct.client_id = c.id and ct.status = 'signed'
    ) then 'active'
    else 'prospect'
  end;
$$;

comment on function public.client_effective_status(public.clients) is
  'Computed column (item 78, renamed item 83): effective client status. status_override (paused/churned) always wins when set; otherwise active iff a signed contract exists, else prospect. security definer -- bypasses contracts RLS deliberately for this one boolean, see 202609210003''s original header for the full argument (unchanged by this migration). status_override is NULL, not a status word, for every client with no manual override -- this function is still the only correct way to read a client''s status; the column never was, even before this rename.';
