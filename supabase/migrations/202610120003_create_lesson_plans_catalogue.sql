-- ============================================================================
-- The lesson-plan catalogue. Two tables, because a plan belongs to several
-- modules and a module holds several plans -- Anca confirmed that shape
-- 2026-10-12 (item 110), closing the objection that shared plans were a
-- defect.
-- ============================================================================
-- Measured against the real workbook (`Centralizator module WOW LAB
-- 2023-2024-2025 (1).xlsx`, the 2026-10-07 export) before this was designed,
-- not inferred from the shape of the problem. The four numbers this schema
-- exists to survive:
--
--   * 288 distinct plans across 16 sheets; 113 of them on more than one
--     sheet, one on five.
--   * 68 of 286 titled plans carry MORE THAN ONE TITLE. The same file is
--     "Seeing DNA", "DNA extraction", "Dna extraction" and "Extraction of
--     DNA". So the title cannot live only on the plan.
--   * The ordinal is per sheet and not even unique within one: 43 (sheet,
--     ordinal) collisions. It is a sort hint, never a key.
--   * 20 (sheet, plan) pairs appear TWICE on the same sheet -- 18 of them in
--     `Modul WOW LAB MIX`, which is three curated lists side by side
--     (beginner / advanced / copii mici) and genuinely holds the same plan in
--     two of them.
--
-- ============================================================================
-- public.lesson_plans -- one row per plan, including plans not yet written
-- ============================================================================
-- `plan_ref` is the natural key: the filename normalized (lowercased, `.xlsx`
-- stripped, whitespace collapsed). Only one plan in the source is written two
-- ways (`FIZ_INERTIA_EGG_DROP_CHALLENGE_CM_2` with and without `.xlsx`), so
-- the normalization is cheap -- but case varies far more and would split rows
-- without it. `plan_filename` keeps the first-seen raw string, because that is
-- what a trainer searching by filename will type.
--
-- It is NULLABLE, and that is the load-bearing decision. 40 rows in the source
-- are chapter pointers -- `1. Lungs`, `17. Immune system`, 17 on `Modul
-- ANATOMY` and 23 on `I WANT TO BE A DOCTOR`. They are not junk: they are
-- those two modules' syllabus, the topics for which no plan has been written
-- yet. Dropping them makes Anatomy look like a 6-lesson module when it is a
-- 23-lesson one, and erases the gap between planned and written -- a gap with
-- money attached, since `lesson_plan_rates` pays 133.20 per plan written
-- (item 95). So they come in with `plan_ref = null` and `status = 'planned'`,
-- and the uniqueness is a PARTIAL index: a filename is unique, an absent
-- filename is not a value to collide on.
create table public.lesson_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  plan_ref text,
  plan_filename text,
  canonical_title text not null,
  what_is_taught text,
  author_initials text,
  author_user_id uuid references public.users(id),
  status text not null default 'written',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lesson_plans_status_check
    check (status in ('written', 'planned')),
  -- The two halves of status are not independent facts. A 'written' plan with
  -- no filename is unidentifiable; a 'planned' one with a filename is written.
  -- Stated as a constraint rather than trusted to the importer, because the
  -- importer is the only writer today and will not be forever.
  constraint lesson_plans_status_matches_plan_ref_check
    check (
      (status = 'written' and plan_ref is not null)
      or (status = 'planned' and plan_ref is null)
    )
);

create unique index lesson_plans_org_plan_ref_key
  on public.lesson_plans (organization_id, plan_ref)
  where plan_ref is not null;

comment on table public.lesson_plans is
  'The lesson-plan catalogue, imported from the Centralizator workbook (202610120004). One row per plan. Rows with plan_ref null and status ''planned'' are chapter pointers -- a topic on a module sheet with no plan written yet, 40 of them in the source -- kept on purpose so a module''s real size and its written/unwritten gap are both visible (item 110). what_is_taught is nullable because it is populated on 467 of 523 source rows, not all.';
comment on column public.lesson_plans.plan_ref is
  'Normalized filename (lowercased, .xlsx stripped, whitespace collapsed) -- the natural key, unique per organization via a PARTIAL index that ignores nulls. Null for a chapter pointer.';
comment on column public.lesson_plans.canonical_title is
  'ONE title per plan, chosen at import (the most frequent spelling, longest on a tie). 68 of 286 titled plans carry more than one title in the source; the per-sheet variants live on lesson_plan_modules.title_on_sheet, not here. A search that only reads this column will not find a plan by the name a trainer actually knows it by.';
comment on column public.lesson_plans.author_initials is
  'Parsed from the filename (ANAT_SeeingDNA_DC_4 -> DC). 19 distinct sets across the catalogue, and two filenames yield none (CHIM_Water filter-LM_5 uses a hyphen; FZ_Running toys_11 has no initials). author_user_id stays null for most: the two highest-volume authors (GS, DC) resolve to no account in this system at all (item 103).';

-- ============================================================================
-- public.lesson_plan_modules -- the many-to-many, carrying what varies per
-- placement rather than per plan
-- ============================================================================
-- `module` is a REAL foreign key to public.modules(key), which finally gives
-- that table a job: 202610070001 recorded that it "is referenced NOWHERE
-- outside its own creating migration -- no app code reads it, no test reads
-- it, nothing joins to it," and that groups.module is validated by a CHECK
-- with every key written inline instead. This is the first join to it. The
-- CHECK on groups.module is deliberately NOT changed here -- that is a
-- separate decision about an existing column with live rows, and doing it
-- inside this migration would couple the catalogue to it.
create table public.lesson_plan_modules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lesson_plan_id uuid not null references public.lesson_plans(id) on delete cascade,
  module text not null references public.modules(key),
  -- MIX's three parallel lists. Null everywhere else, and null is the common
  -- case: only `wow_mix` has variants in the source.
  variant text,
  ordinal integer,
  title_on_sheet text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lesson_plan_modules_variant_check
    check (variant is null or variant in ('level_beginner', 'level_advanced', 'copii_mici'))
);

-- (plan, module) is NOT unique, on purpose: `Modul WOW LAB MIX` holds the same
-- plan in two of its three lists 18 times over. (plan, module, variant) is,
-- with coalesce because a unique index treats nulls as distinct and would
-- silently allow a true duplicate on every non-MIX sheet -- which the source
-- also contains, twice (one on GAGA, one on LOTIONS AND POTIONS). Those two
-- are plain data-entry duplicates and the import rejects them rather than
-- inventing a variant to fit them.
create unique index lesson_plan_modules_plan_module_variant_key
  on public.lesson_plan_modules (lesson_plan_id, module, coalesce(variant, ''));

create index lesson_plan_modules_module_idx
  on public.lesson_plan_modules (organization_id, module);

comment on table public.lesson_plan_modules is
  'Which modules a lesson plan appears under, and what varies per appearance: the sheet''s own title for it, its position in that sheet''s order, and (wow_mix only) which of the three curated lists it sits in. 113 of 288 plans have more than one row here; wow_mix has 80 plans of which 75 also sit elsewhere, which is why MIX is a re-cut of the other modules rather than a module with its own content (item 103).';
comment on column public.lesson_plan_modules.ordinal is
  'The sheet''s own numbering. A SORT HINT, never a key: the same plan is #1 on GAGA, #12 on TikTok Science and #17 on MIX, and 43 (sheet, ordinal) pairs are reused within a single sheet.';
comment on column public.lesson_plan_modules.title_on_sheet is
  'The title as that module sheet writes it, which is often not the canonical one -- 68 plans carry several. The trainer''s selector has to search these and say WHICH title matched, or a search for "DNA extraction" returns a row labelled "Seeing DNA" and reads as broken.';
comment on column public.lesson_plan_modules.variant is
  'wow_mix only: which of the three side-by-side lists on that sheet (beginner / advanced / young children). Null for every other module. Without it the (plan, module) pair is not unique and MIX''s three lists collapse into one.';

-- ============================================================================
-- RLS -- read-only to everyone whose job touches curriculum, writable by
-- nobody
-- ============================================================================
alter table public.lesson_plans enable row level security;
alter table public.lesson_plan_modules enable row level security;

-- ONE clause, and that is not an omission. app.has_capability() already
-- expands wildcards (`right(c.key,2) = '.*' and starts_with(cap, ...)`) and
-- already ORs in app.is_platform_owner() itself, so asking for
-- `curriculum.read` admits, verified against the live role grants:
--   * trainer and senior_trainer   -- hold curriculum.read outright
--   * curriculum_manager           -- holds curriculum.* (Anka, Catalina)
--   * organization_owner           -- holds curriculum.* (Mihai)
--   * platform_owner               -- holds curriculum.* (Anca)
-- and refuses finance-only and role-less accounts (Laura, Raluca Margean).
-- Adding the customary `app.is_platform_owner() or app.has_capability
-- ('org.settings.manage', ...)` preamble would be pure duplication here.
create policy "authenticated select lesson_plans" on public.lesson_plans
  for select to authenticated
  using (app.has_capability('curriculum.read', organization_id));

create policy "authenticated select lesson_plan_modules" on public.lesson_plan_modules
  for select to authenticated
  using (app.has_capability('curriculum.read', organization_id));

-- SELECT only. No INSERT/UPDATE/DELETE grant to authenticated anywhere: the
-- catalogue is loaded by migration (202610120004) and there is no screen that
-- edits it. A write path gets its grant, its policy and its row_history
-- trigger together, in the migration that introduces it -- which is also when
-- there will be something for a history row to record. Giving this table a
-- history trigger now would capture nothing but its own import.
grant select on public.lesson_plans to authenticated;
grant select on public.lesson_plan_modules to authenticated;

create trigger lesson_plans_set_updated_at
  before update on public.lesson_plans
  for each row execute function trigger_set_updated_at();

create trigger lesson_plan_modules_set_updated_at
  before update on public.lesson_plan_modules
  for each row execute function trigger_set_updated_at();
