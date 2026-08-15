-- 202608160004_groups_sessions_field_additions.sql
-- WOW LAB OS, Phase 1: Operational domain (Groups & Sessions) — real gaps
-- from Anca's live-app feedback, additive only.
--
-- sessions.status: expand (planned|delivered|cancelled) to add 'confirmed'
-- — a session can be confirmed (trainer allocated, date locked) before it
-- is actually delivered. Existing rows are untouched: none currently use
-- a value this looser constraint wouldn't already have allowed, and the
-- new value is purely additive to the allowed set.
--
-- groups.age_range — free text (e.g. "6-9 ani"), nullable, no format
-- enforced -- matches schedule_pattern's own "free text, not a stricter
-- shape" treatment (202608130001) rather than inventing a min/max-age
-- pair this app has no other use for yet.
--
-- sessions.duration_minutes — nullable int. Supports the 30/60/90/120
-- values Anca listed, but not constrained to only those -- a CHECK would
-- reject a legitimate 45 or 75-minute session with no real justification,
-- same reasoning as not adding a CHECK to attendance_count.
--
-- sessions.experiment_drive_link — nullable text, alongside the existing
-- experiment_delivered (free text label of WHICH experiment). Distinct
-- columns: experiment_delivered names it, experiment_drive_link points at
-- the actual Drive-hosted presentation for it -- the two can be filled in
-- independently (a trainer might log which experiment ran before the
-- Drive link for that specific session exists).
--
-- public.modules — new small reference table. Keys match the mockup's
-- MODULES object verbatim (docs/mockup/wow_lab_os_mockup.html) -- the same
-- 13 real curriculum-module keys groups.module''s CHECK constraint already
-- enforces (202608130001), so this table's keys are guaranteed to already
-- align with every existing groups.module value, nothing to backfill/
-- reconcile. curriculum_link is left NULL for all 13 rows -- no real Drive
-- links have been provided yet; fabricating placeholder URLs would be
-- worse than an honest empty state. NOT given an FK from groups.module
-- (groups.module stays text+CHECK, unchanged) -- this is a lookup/display
-- table for the module picker and curriculum-link display, not a
-- normalization of the existing column, matching this codebase's existing
-- module comment: "Stored as text+CHECK, not a table FK -- no curriculum-
-- module reference table exists yet in this app." (202608130001) -- that
-- reference table now exists, but converting the existing column to a
-- real FK is a separate, more invasive change than what was asked for
-- here.
--
-- Idempotent: `add column if not exists`, CHECK constraint dropped and
-- re-added by name (only way to widen an existing CHECK's allowed set),
-- `create table if not exists`, modules seed guarded by ON CONFLICT.

alter table public.groups
  add column if not exists age_range text,
  add column if not exists school_year_calendar_link text;

comment on column public.groups.age_range is 'Free text age range for the group (e.g. "6-9 ani") -- no stricter shape enforced, same treatment as schedule_pattern.';
comment on column public.groups.school_year_calendar_link is 'Manual URL to the school-year calendar for this group (Anca''s request). Free text, no validation -- same treatment as contracts.ac_link/clients.external_crm_ref.';

alter table public.sessions
  add column if not exists duration_minutes int,
  add column if not exists experiment_drive_link text;

comment on column public.sessions.duration_minutes is 'Session length in minutes. Not constrained to a fixed set (e.g. 30/60/90/120) -- a CHECK would reject a legitimate other duration with no real justification.';
comment on column public.sessions.experiment_drive_link is 'Drive-hosted presentation link for the experiment named in experiment_delivered. Distinct column, filled independently -- the two can be known at different times.';

do $$
begin
  if exists (
    select 1 from pg_constraint where conname = 'sessions_status_check'
  ) then
    alter table public.sessions drop constraint sessions_status_check;
  end if;
  alter table public.sessions
    add constraint sessions_status_check
    check (status in ('planned', 'confirmed', 'delivered', 'cancelled'));
end;
$$;

create table if not exists public.modules (
  key text primary key,
  display_label text not null,
  curriculum_link text
);

comment on table public.modules is 'Reference/lookup table for the 13 real curriculum modules -- keys match groups.module''s existing CHECK constraint verbatim (202608130001), sourced from docs/mockup/wow_lab_os_mockup.html''s MODULES object. NOT an FK target for groups.module (which stays text+CHECK, unchanged) -- this table backs the module picker''s display labels and per-module Drive curriculum links, it does not normalize the existing column.';
comment on column public.modules.curriculum_link is 'Per-module Drive link to curriculum materials. NULL for all 13 seeded rows -- no real links provided yet; left honestly empty rather than fabricated.';

insert into public.modules (key, display_label, curriculum_link)
values
  ('gaga', 'GAGA', null),
  ('green_energy', 'Green Energy', null),
  ('wow_mix', 'Wow Lab Mix', null),
  ('tiktok', 'Wow TikTok Science', null),
  ('food_science', 'Wow Food Science', null),
  ('lotions', 'Wow Lotions and Potions', null),
  ('magic_physics', 'Magic of Physics', null),
  ('chem_me', 'Chemistry for Me', null),
  ('chem_hs', 'Chemistry for Highschool', null),
  ('lights', 'Lights and Colours', null),
  ('detective', 'Detective Science', null),
  ('astronomy', 'Astronomy', null),
  ('doctor', 'I Wanna Be a Doctor', null)
on conflict (key) do nothing;

-- Global reference table, no organization_id -- same RLS shape as roles/
-- capabilities/role_capabilities (202607080003): enabled+forced, one
-- permissive "any authenticated caller" SELECT policy, no write policy
-- (this table is admin/migration-managed, not app-editable).
grant select on public.modules to authenticated;
alter table public.modules enable row level security;
alter table public.modules force row level security;

DO $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'modules' and policyname = 'authenticated select modules'
  ) then
    create policy "authenticated select modules" on public.modules
      for select
      using (auth.role() = 'authenticated');
  end if;
end;
$$;
