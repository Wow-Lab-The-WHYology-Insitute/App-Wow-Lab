-- ============================================================================
-- Raluca's per-article tiers: the BOUNDARY, which is what was actually
-- missing. Anca, 2026-10-13.
-- ============================================================================
-- The thresholds were NOT absent -- 202610120012 seeded tier_min_words and
-- tier_max_words for all four tiers. They OVERLAPPED, which is worse than
-- absent, because a lookup written against them returns an answer and the
-- answer is arbitrary:
--
--     tier_label    min    max
--     500-1000      500   1000
--     1000-2000    1000   2000     <- 1000 is in this tier AND the one above
--     2000-4000    2000   4000     <- 2000 likewise
--     over-4000    4000   null     <- 4000 likewise
--
-- A 1000-word article matched both the 100 RON tier and the 150 RON tier, and
-- which one won depended on row order. Anca's rule settles it in one sentence:
-- THE UPPER BOUND BELONGS TO THE LOWER TIER.
--
--     500-1000     ->  100 RON
--     1001-2000    ->  150 RON
--     2001-4000    ->  250 RON
--     over 4000    ->  350 RON
--     internal newsletter -> 150 RON each (no word count, untouched here)
--
-- So the minimums move up by one and the labels follow them. The amounts are
-- NOT touched: those were already right and are not what was being asked.
--
-- BELOW 500 THERE IS NO TIER, and that is deliberate, not an omission. Anca
-- confirmed it does not happen. The consequence for the hours-entry screen,
-- when it is built: a word count under 500 is REJECTED, never rounded up into
-- the first tier. Guessing a tier is how the overlap above would have been
-- re-created at a different boundary. Recorded as item 132.
-- ============================================================================
do $$
declare
  v_moved integer;
begin
  update public.admin_rates set tier_min_words = 1001, tier_label = '1001-2000'
   where rate_kind = 'per_article' and tier_label = '1000-2000';
  get diagnostics v_moved = row_count;
  if v_moved <> 1 then
    raise exception 'expected exactly 1 row for the 1000-2000 tier, moved %', v_moved;
  end if;

  update public.admin_rates set tier_min_words = 2001, tier_label = '2001-4000'
   where rate_kind = 'per_article' and tier_label = '2000-4000';
  get diagnostics v_moved = row_count;
  if v_moved <> 1 then
    raise exception 'expected exactly 1 row for the 2000-4000 tier, moved %', v_moved;
  end if;

  update public.admin_rates set tier_min_words = 4001
   where rate_kind = 'per_article' and tier_label = 'over-4000';
  get diagnostics v_moved = row_count;
  if v_moved <> 1 then
    raise exception 'expected exactly 1 row for the over-4000 tier, moved %', v_moved;
  end if;
end $$;

-- A range has to be well-formed. This does NOT prevent two tiers overlapping
-- each other -- that needs a cross-row constraint, and the cheaper instrument
-- for four rows is the assertion added to db/tests/admin_rates.sql in the same
-- commit, which walks the boundaries (500, 1000, 1001, 2000, 2001, 4000, 4001)
-- and requires each to resolve to EXACTLY one tier. A CHECK that cannot see
-- other rows would have caught none of what went wrong here.
alter table public.admin_rates
  add constraint admin_rates_tier_range_well_formed_check
  check (
    tier_min_words is null
    or tier_max_words is null
    or tier_min_words <= tier_max_words
  );

comment on column public.admin_rates.tier_min_words is
  'Inclusive lower bound, in words. The upper bound belongs to the LOWER tier (Anca 2026-10-13), so consecutive tiers are 500-1000 / 1001-2000 / 2001-4000 / 4001+. No tier exists below 500: a smaller word count is rejected, never rounded up.';
comment on column public.admin_rates.tier_max_words is
  'Inclusive upper bound, in words; null means open-ended (the top tier). See tier_min_words.';
