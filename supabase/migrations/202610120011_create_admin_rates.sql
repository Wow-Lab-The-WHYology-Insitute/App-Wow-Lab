-- ============================================================================
-- Admin rates. Anca's 2026-08-07 figures as corrected by her 2026-08-10
-- message (item 111). Two shapes in one domain, one versioned table.
-- ============================================================================
--
-- WHY ONE TABLE WITH A DISCRIMINATOR, not one flat table and not two tables
-- ------------------------------------------------------------------------
-- The two shapes are keyed differently, not merely shaped differently: Anka's
-- rate is keyed by (person, task category), Margean's by (person, word-count
-- band). A single flat table with both `task_category` and the tier columns
-- nullable admits four states, two of which are meaningless -- both set, and
-- neither set -- and nothing would stop either. That is SAD §4's own objection
-- to a polymorphic discriminator on `contracts`, at smaller scale.
--
-- Two separate tables (admin_hourly_rates / admin_article_rates) would be
-- honest and was the second choice. Against it: two versioning headers, two
-- effective-date resolvers and two RLS policies that must stay identical --
-- and the versioning machinery is the expensive part and is identical for
-- both. A third shape would then be a third table.
--
-- So: one table, one versioned header, and a `rate_kind` discriminator whose
-- CHECK makes the wrong combinations unrepresentable rather than discouraged.
--
-- THE 11% UPLIFT, AND THE LABEL THIS PROJECT HAS BEEN USING FOR IT
-- ---------------------------------------------------------------
-- Measured, exactly, in decimal, before writing the constraint below:
--
--     50 x 1.11  = 55.50   EXACT (stored 55.50)   |  x1.111 = 55.550
--     72 x 1.11  = 79.92   EXACT (stored 79.92)   |  x1.111 = 79.992
--    100 x 1.11  = 111.00  EXACT (item 95's trainer grade 1)
--
-- **The uplift is 11%, not 11.1%.** All three independent rate sets land on
-- x1.11 exactly and none lands on x1.111. This project's own notes call it
-- "11.1%" in several places (item 95, item 111, 202609240001's comments,
-- 202609250001's) -- the label is wrong, the data is right. Those migrations
-- are not rewritten; they record what was believed when written, and the
-- register carries the correction.
--
-- So the tolerance on the CHECK below is ZERO. Both uplifted rows reconcile
-- to the ban, so a slack allowance would only make the constraint decorative
-- -- it would stop catching the thing it exists to catch.
create table public.admin_rate_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  effective_date date not null,
  created_by uuid references public.users(id),
  note text,
  created_at timestamptz not null default now()
);

create table public.admin_rates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  version_id uuid not null references public.admin_rate_versions(id) on delete cascade,
  person_user_id uuid not null references public.users(id),

  rate_kind text not null,

  -- hourly only. Anca's words, 2026-08-07: admin is everything administrative
  -- but not financial; ateliere is workshop organisation plus sales and
  -- ActiveCampaign; financiar is accounting and financial statements.
  task_category text,

  -- per_article only. Stored as the band, not as a parsed rule: the source is
  -- a bulleted list in one spreadsheet cell and the bands are inclusive of the
  -- lower bound, open at the top for the last one.
  tier_label text,
  tier_min_words integer,
  tier_max_words integer,

  -- ALWAYS the invoiced figure, for every row -- the number that gets paid.
  amount numeric not null,
  -- Populated ONLY where an uplift was applied, which is what makes
  -- is_uplift_applied checkable rather than merely asserted.
  net_amount numeric,
  is_uplift_applied boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint admin_rates_kind_check
    check (rate_kind in ('hourly', 'per_article', 'per_newsletter')),
  constraint admin_rates_task_category_check
    check (task_category is null or task_category in ('admin', 'ateliere', 'financiar')),

  -- Each kind carries exactly its own keys and no others. This is the
  -- constraint that earns the single-table choice: a row with both a task
  -- category and a word band, or with neither, cannot exist.
  constraint admin_rates_shape_check
    check (
      (rate_kind = 'hourly'
         and task_category is not null
         and tier_label is null and tier_min_words is null and tier_max_words is null)
      or (rate_kind = 'per_article'
         and task_category is null
         and tier_label is not null and tier_min_words is not null)
      or (rate_kind = 'per_newsletter'
         and task_category is null
         and tier_label is null and tier_min_words is null and tier_max_words is null)
    ),

  constraint admin_rates_tier_order_check
    check (tier_max_words is null or tier_min_words is null or tier_max_words > tier_min_words),

  -- THE PAIR THAT STOPS SOMEONE ADDING 11% TO ANKA'S 80.
  -- net_amount is present exactly when an uplift was applied...
  constraint admin_rates_uplift_flag_matches_net_check
    check (is_uplift_applied = (net_amount is not null)),
  -- ...and when it was, the arithmetic has to reconcile at 11%, exactly.
  -- A future row claiming an uplift that does not hold is rejected.
  constraint admin_rates_uplift_reconciles_check
    check (net_amount is null or amount = round(net_amount * 1.11, 2)),

  constraint admin_rates_amount_positive_check
    check (amount > 0 and (net_amount is null or net_amount > 0))
);

-- One rate per person per kind per category/tier within a version. Uses
-- coalesce because a unique index treats nulls as distinct, which would admit
-- two 'financiar' rows for the same person in the same version.
create unique index admin_rates_unique_within_version
  on public.admin_rates
  (version_id, person_user_id, rate_kind, coalesce(task_category, ''), coalesce(tier_label, ''));

create index admin_rates_person_idx on public.admin_rates (organization_id, person_user_id);
create unique index admin_rate_versions_org_date_key
  on public.admin_rate_versions (organization_id, effective_date);

comment on table public.admin_rates is
  'What the people doing administrative work are paid. Two shapes under one versioned header, separated by rate_kind: an hourly rate that varies by task category (Anka) and a per-article rate that varies by word count (Raluca Margean), plus a flat per-newsletter rate. Versioned exactly like the five trainer pay grids -- immutable rows, a correction is a new version -- so a rate change never rewrites history. Admin hours themselves are NOT modelled yet (item 129).';
comment on column public.admin_rates.amount is
  'The INVOICED amount, always -- for every row and every kind. For Anka and Margean this is also the agreed figure with nothing added (net_amount null, is_uplift_applied false): Anca confirmed 2026-08-10 that their rates are FINAL and no uplift goes on top. For the four uplifted people it is net x 1.11.';
comment on column public.admin_rates.net_amount is
  'The pre-uplift figure, populated ONLY where an uplift was applied -- 50 for Laura/Teodora/Alexandra, 72 for Catalina. NULL for every FINAL rate, which is the point: there is no net figure to uplift Anka''s 80 from, and two CHECKs enforce that (is_uplift_applied = (net_amount is not null), and amount = round(net_amount * 1.11, 2)). Same shape as the trainer grid, whose six rates are PFA-inclusive already with contract_type_uplift deliberately kept empty (item 95).';
comment on column public.admin_rates.is_uplift_applied is
  'Redundant by construction with net_amount, on purpose: the redundancy is what makes the claim checkable. The uplift is 11%, NOT the 11.1% several of this project''s notes say -- 50->55.50, 72->79.92 and 100->111 are all exact at x1.11 and none is exact at x1.111 (item 128).';
comment on column public.admin_rates.task_category is
  'Anka''s three categories, her words: admin = everything administrative but not financial; ateliere = workshop organisation plus sales and ActiveCampaign; financiar = accounting and financial statements. This is the task-type mapping item 105 recorded as open.';

-- ============================================================================
-- RLS -- the same predicate the five pay grids use
-- ============================================================================
alter table public.admin_rate_versions enable row level security;
alter table public.admin_rates enable row level security;

-- Deliberately the SAME predicate as the trainer pay grids
-- (202608310002): platform owner OR finance.operations.* OR
-- finance.reporting.*. Wider than supplier_contracts' on purpose -- Laura runs
-- day-to-day pay, and these are pay rates rather than counterparty contracts.
-- NOT extended to the person whose rate it is: an own-row branch here is the
-- same decision item 127 declined for supplier_contracts, and nobody has asked.
create policy "authenticated select admin_rate_versions" on public.admin_rate_versions
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

create policy "authenticated select admin_rates" on public.admin_rates
  for select to authenticated
  using (
    app.is_platform_owner()
    or app.has_capability('finance.operations.*', organization_id)
    or app.has_capability('finance.reporting.*', organization_id)
  );

-- SELECT and INSERT, never UPDATE -- the five pay grids' own rule. A version
-- is immutable; a correction is a new version with a later effective_date, so
-- history is never rewritten.
grant select, insert on public.admin_rate_versions to authenticated;
grant select, insert on public.admin_rates to authenticated;

create trigger admin_rates_set_updated_at
  before update on public.admin_rates
  for each row execute function trigger_set_updated_at();

-- ============================================================================
-- app.resolve_admin_rate -- two steps, like the six existing resolvers
-- ============================================================================
-- Finds the version valid at the date FIRST, then the row inside that exact
-- version -- never one join with an order-by-limit, which could silently fall
-- back to an older version's value when a new version is missing a row.
-- Raises instead. SECURITY INVOKER, like the six: a DEFINER resolver with no
-- internal capability check would let anyone reconstruct the whole grid by
-- repeated calls.
create or replace function app.resolve_admin_rate(
  p_organization_id uuid,
  p_person_user_id uuid,
  p_rate_kind text,
  p_task_category text,
  p_tier_label text,
  p_as_of date
)
returns numeric
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_version_id uuid;
  v_amount numeric;
begin
  select id into v_version_id
  from public.admin_rate_versions
  where organization_id = p_organization_id and effective_date <= p_as_of
  order by effective_date desc
  limit 1;

  if v_version_id is null then
    raise exception 'app.resolve_admin_rate: no admin_rate_versions row effective on or before % (org %)', p_as_of, p_organization_id;
  end if;

  select amount into v_amount
  from public.admin_rates
  where version_id = v_version_id
    and person_user_id = p_person_user_id
    and rate_kind = p_rate_kind
    and coalesce(task_category, '') = coalesce(p_task_category, '')
    and coalesce(tier_label, '') = coalesce(p_tier_label, '');

  if v_amount is null then
    raise exception 'app.resolve_admin_rate: version % has no % row for person % (category %, tier %) -- incomplete version',
      v_version_id, p_rate_kind, p_person_user_id, p_task_category, p_tier_label;
  end if;

  return v_amount;
end;
$$;

comment on function app.resolve_admin_rate(uuid, uuid, text, text, text, date) is
  'The invoiced amount for one person''s one kind of admin work at a date. Two-step like the six pay-grid resolvers (version-at-date, then the row inside that version) so an incomplete new version fails loudly rather than falling back to an older value. Returns the INVOICED figure -- never the net -- so a caller cannot accidentally uplift a FINAL rate.';

grant execute on function app.resolve_admin_rate(uuid, uuid, text, text, text, date) to authenticated;
