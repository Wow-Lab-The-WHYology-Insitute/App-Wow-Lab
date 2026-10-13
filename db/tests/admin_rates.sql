-- db/tests/admin_rates.sql
-- admin_rates (202610120011/202610120012, item 128).
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner, and it must carry check_name / actual / expected / pass.

-- ============================================================================
-- Block 1: the twelve seeded rates, and the FINAL-vs-uplifted split.
-- ============================================================================
begin;
  select 'twelve rates seeded' as check_name,
         (select count(*)::text from public.admin_rates) as actual, '12' as expected,
         (select count(*) from public.admin_rates) = 12 as pass
  union all
  select 'exactly four carry the uplift',
         (select count(*)::text from public.admin_rates where is_uplift_applied), '4',
         (select count(*) from public.admin_rates where is_uplift_applied) = 4
  union all
  -- THE ASSERTION THAT MATTERS: no FINAL rate carries a net figure, so there
  -- is nothing for someone to uplift Anka's 80 from.
  select 'no FINAL rate carries a net amount to be uplifted from',
         (select count(*)::text from public.admin_rates where not is_uplift_applied and net_amount is not null),
         '0',
         (select count(*) from public.admin_rates where not is_uplift_applied and net_amount is not null) = 0
  union all
  select 'Anka''s three categories are 80 / 80 / 90, all FINAL',
         (select string_agg(amount::text, '/' order by task_category) from public.admin_rates r
            join public.users u on u.id = r.person_user_id
           where u.email = 'anka@asismart.ro'),
         '80/80/90',
         (select string_agg(amount::text, '/' order by task_category) from public.admin_rates r
            join public.users u on u.id = r.person_user_id
           where u.email = 'anka@asismart.ro') = '80/80/90'
           and (select count(*) from public.admin_rates r join public.users u on u.id = r.person_user_id
                 where u.email = 'anka@asismart.ro' and r.is_uplift_applied) = 0
  union all
  select 'Margean has four article bands plus one newsletter rate, all FINAL',
         (select count(*) filter (where rate_kind='per_article')::text || '+' ||
                 count(*) filter (where rate_kind='per_newsletter')::text
            from public.admin_rates r join public.users u on u.id = r.person_user_id
           where u.email = 'ralucamargean@yahoo.com'),
         '4+1',
         (select count(*) filter (where rate_kind='per_article') = 4
                 and count(*) filter (where rate_kind='per_newsletter') = 1
                 and count(*) filter (where is_uplift_applied) = 0
            from public.admin_rates r join public.users u on u.id = r.person_user_id
           where u.email = 'ralucamargean@yahoo.com')
  union all
  select 'the top article band is open at the top (over 4000 words)',
         (select coalesce(max(tier_max_words)::text, 'null') from public.admin_rates
           where tier_label = 'over-4000'),
         'null',
         (select count(*) from public.admin_rates where tier_label = 'over-4000' and tier_max_words is null) = 1
  union all
  -- The uplift is 11%, not the 11.1% several of this project's notes say.
  select 'every uplifted row reconciles at exactly 11%',
         (select count(*)::text from public.admin_rates
           where is_uplift_applied and amount <> round(net_amount * 1.11, 2)),
         '0',
         (select count(*) from public.admin_rates
           where is_uplift_applied and amount <> round(net_amount * 1.11, 2)) = 0
  union all
  select 'and NONE of them reconciles at 11.1% -- the label was wrong, not the data',
         (select count(*)::text from public.admin_rates
           where is_uplift_applied and amount = round(net_amount * 1.111, 2)),
         '0',
         (select count(*) from public.admin_rates
           where is_uplift_applied and amount = round(net_amount * 1.111, 2)) = 0
  union all
  select 'Catalina''s new admin rate is 72 net / 79.92 invoiced',
         (select net_amount::text || '/' || amount::text from public.admin_rates r
            join public.users u on u.id = r.person_user_id where u.email = 'catalina_moale@yahoo.com'),
         '72/79.92',
         (select net_amount::text || '/' || amount::text from public.admin_rates r
            join public.users u on u.id = r.person_user_id where u.email = 'catalina_moale@yahoo.com') = '72/79.92'
  union all
  select 'one version, effective 2026-08-10 (the date of her correction)',
         (select count(*)::text || '@' || max(effective_date)::text from public.admin_rate_versions),
         '1@2026-08-10',
         (select count(*)::text || '@' || max(effective_date)::text from public.admin_rate_versions) = '1@2026-08-10';
rollback;

-- ============================================================================
-- Block 2: the constraints. Each ATTEMPTS the illegal write.
-- ============================================================================
begin;
  create temp table r (what text, ok boolean) on commit drop;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_user uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_ver uuid;
  begin
    insert into public.admin_rate_versions (organization_id, effective_date, note)
    values (v_org, '2026-01-01', 'DRYRUN version') returning id into v_ver;

    -- The pair that stops an 11% being added to a FINAL rate.
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
      values (v_org, v_ver, v_user, 'hourly', 'admin', 88.80, 80, false);
      insert into r values ('flag_must_match_net', false);
    exception when check_violation then insert into r values ('flag_must_match_net', true); end;

    -- An uplift that does not reconcile -- the decorative-CHECK test.
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
      values (v_org, v_ver, v_user, 'hourly', 'admin', 88.88, 80, true);
      insert into r values ('uplift_must_reconcile', false);
    exception when check_violation then insert into r values ('uplift_must_reconcile', true); end;

    -- 11.1% must now FAIL, which is the arithmetic finding expressed as a test:
    -- 50 x 1.111 = 55.55 is not a legal row.
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
      values (v_org, v_ver, v_user, 'hourly', 'ateliere', 55.55, 50, true);
      insert into r values ('eleven_point_one_rejected', false);
    exception when check_violation then insert into r values ('eleven_point_one_rejected', true); end;

    -- 11% exactly must be accepted.
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
      values (v_org, v_ver, v_user, 'hourly', 'financiar', 55.50, 50, true);
      insert into r values ('eleven_percent_accepted', true);
    exception when check_violation then insert into r values ('eleven_percent_accepted', false); end;

    -- The shape CHECK: the two keys can never both be set, nor both absent.
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, tier_label, tier_min_words, amount)
      values (v_org, v_ver, v_user, 'hourly', 'admin', '500-1000', 500, 80);
      insert into r values ('both_keys_rejected', false);
    exception when check_violation then insert into r values ('both_keys_rejected', true); end;

    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, amount)
      values (v_org, v_ver, v_user, 'hourly', 80);
      insert into r values ('hourly_needs_category', false);
    exception when check_violation then insert into r values ('hourly_needs_category', true); end;

    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount)
      values (v_org, v_ver, v_user, 'hourly', 'contabilitate', 80);
      insert into r values ('category_vocabulary', false);
    exception when check_violation then insert into r values ('category_vocabulary', true); end;

    -- Versions are immutable: no UPDATE grant exists, so a correction is a new
    -- version. Asserted as a privilege, not as a constraint.
    insert into r select 'no_update_grant',
      not exists (select 1 from information_schema.table_privileges
                   where grantee='authenticated' and table_schema='public'
                     and table_name='admin_rates' and privilege_type='UPDATE');
  end $$;

  select 'claiming no uplift while carrying a net amount is rejected' as check_name,
         (select ok::text from r where what='flag_must_match_net') as actual, 'true' as expected,
         (select ok from r where what='flag_must_match_net') as pass
  union all
  select 'an uplift that does not reconcile is rejected',
         (select ok::text from r where what='uplift_must_reconcile'), 'true',
         (select ok from r where what='uplift_must_reconcile')
  union all
  select '11.1% (50 -> 55.55) is REJECTED',
         (select ok::text from r where what='eleven_point_one_rejected'), 'true',
         (select ok from r where what='eleven_point_one_rejected')
  union all
  select '11% (50 -> 55.50) is accepted -- control for the one above',
         (select ok::text from r where what='eleven_percent_accepted'), 'true',
         (select ok from r where what='eleven_percent_accepted')
  union all
  select 'a row with both a task category and a word band is rejected',
         (select ok::text from r where what='both_keys_rejected'), 'true',
         (select ok from r where what='both_keys_rejected')
  union all
  select 'an hourly rate with no task category is rejected',
         (select ok::text from r where what='hourly_needs_category'), 'true',
         (select ok from r where what='hourly_needs_category')
  union all
  select 'an invented task category is rejected',
         (select ok::text from r where what='category_vocabulary'), 'true',
         (select ok from r where what='category_vocabulary')
  union all
  select 'rates are immutable: authenticated holds no UPDATE grant',
         (select ok::text from r where what='no_update_grant'), 'true',
         (select ok from r where what='no_update_grant');
rollback;

-- ============================================================================
-- Block 3: the resolver returns the INVOICED figure and fails loudly.
-- ============================================================================
begin;
  create temp table r (what text, val text) on commit drop;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab');
    v_anka uuid := (select id from public.users where email = 'anka@asismart.ro');
    v_cat uuid := (select id from public.users where email = 'catalina_moale@yahoo.com');
    v_margean uuid := (select id from public.users where email = 'ralucamargean@yahoo.com');
  begin
    insert into r select 'anka_financiar',
      app.resolve_admin_rate(v_org, v_anka, 'hourly', 'financiar', null, '2026-10-12')::text;
    -- The invoiced figure, never the net: a caller cannot accidentally uplift.
    insert into r select 'catalina_invoiced',
      app.resolve_admin_rate(v_org, v_cat, 'hourly', 'admin', null, '2026-10-12')::text;
    insert into r select 'margean_band',
      -- '2001-4000' since 202610130001: app.resolve_admin_rate keys on the
      -- tier LABEL, so relabelling the tier is a change to that function's
      -- contract and not a cosmetic edit. This call site was the only caller
      -- in the repo; the first suite run after the migration failed here, with
      -- "incomplete version", which is the resolver correctly refusing a tier
      -- it no longer has.
      app.resolve_admin_rate(v_org, v_margean, 'per_article', null, '2001-4000', '2026-10-12')::text;
    insert into r select 'margean_newsletter',
      app.resolve_admin_rate(v_org, v_margean, 'per_newsletter', null, null, '2026-10-12')::text;

    -- Before the version's effective date: raises rather than guessing.
    begin
      perform app.resolve_admin_rate(v_org, v_anka, 'hourly', 'admin', null, '2026-01-01');
      insert into r values ('before_effective', 'returned a value');
    exception when others then insert into r values ('before_effective', 'raised'); end;

    -- A person with no rate: raises rather than returning null.
    begin
      perform app.resolve_admin_rate(v_org, v_cat, 'hourly', 'financiar', null, '2026-10-12');
      insert into r values ('missing_row', 'returned a value');
    exception when others then insert into r values ('missing_row', 'raised'); end;
  end $$;

  select 'Anka''s Financiar hour resolves to 90' as check_name,
         (select val from r where what='anka_financiar') as actual, '90' as expected,
         (select val from r where what='anka_financiar') = '90' as pass
  union all
  select 'Catalina resolves to the INVOICED 79.92, not the net 72',
         (select val from r where what='catalina_invoiced'), '79.92',
         (select val from r where what='catalina_invoiced') = '79.92'
  union all
  select 'Margean''s 2000-4000 band resolves to 250',
         (select val from r where what='margean_band'), '250',
         (select val from r where what='margean_band') = '250'
  union all
  select 'her newsletter rate resolves to 150',
         (select val from r where what='margean_newsletter'), '150',
         (select val from r where what='margean_newsletter') = '150'
  union all
  select 'a date before the version raises, never guesses',
         (select val from r where what='before_effective'), 'raised',
         (select val from r where what='before_effective') = 'raised'
  union all
  select 'a person with no rate of that kind raises, never returns null',
         (select val from r where what='missing_row'), 'raised',
         (select val from r where what='missing_row') = 'raised';
rollback;

-- ============================================================================
-- Block 4: SABOTAGE. Drop the reconcile CHECK and the 11.1% row must land.
-- ============================================================================
-- Without this, block 2's "11.1% is rejected" would pass identically if the
-- constraint did not exist and the insert failed for some unrelated reason.
begin;
  create temp table r (what text, ok boolean) on commit drop;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_user uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_ver uuid;
  begin
    alter table public.admin_rates drop constraint admin_rates_uplift_reconciles_check;

    insert into public.admin_rate_versions (organization_id, effective_date, note)
    values (v_org, '2026-01-01', 'DRYRUN sabotage version') returning id into v_ver;
    begin
      insert into public.admin_rates (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
      values (v_org, v_ver, v_user, 'hourly', 'ateliere', 55.55, 50, true);
      insert into r values ('eleven_point_one_rejected', false);
    exception when check_violation then insert into r values ('eleven_point_one_rejected', true); end;
  end $$;

  select 'SABOTAGE: 11.1% (50 -> 55.55) is REJECTED, same assertion as block 2, admin_rates_uplift_reconciles_check dropped' as check_name,
         (select ok::text from r where what='eleven_point_one_rejected') as actual, 'true' as expected,
         (select ok from r where what='eleven_point_one_rejected') as pass;
rollback;

-- ============================================================================
-- Block 5: the per-article tiers tile the line from 500 upward -- no overlap,
-- no gap. 202610130001, Anca 2026-10-13.
-- ============================================================================
-- This is the assertion the schema cannot make. A CHECK sees one row, and
-- every single row here was individually well-formed while 1000, 2000 and 4000
-- each belonged to TWO tiers at once -- so a lookup returned an answer and the
-- answer depended on row order. The test walks the boundaries instead and
-- requires each word count to resolve to exactly one tier.
--
-- 499 is in the list on purpose: it must resolve to ZERO tiers. Anca confirmed
-- articles under 500 words do not happen, so the hours-entry screen rejects
-- them rather than rounding up into the 100 RON tier -- and an assertion that
-- only ever checked "exactly one" would have been satisfied by a first tier
-- quietly widened to start at 0.
begin;
  create temp table words (n integer, expect integer) on commit drop;
  insert into words values
    (499, 0),   -- below the floor: no tier, deliberately
    (500, 1), (1000, 1),           -- first tier, both ends inclusive
    (1001, 1), (2000, 1),          -- second
    (2001, 1), (4000, 1),          -- third
    (4001, 1), (999999, 1);        -- open-ended top

  select 'every boundary word count resolves to exactly the expected number of tiers' as check_name,
         (select count(*)::text from words w
           where (select count(*) from public.admin_rates r
                   where r.rate_kind = 'per_article'
                     and w.n >= r.tier_min_words
                     and (r.tier_max_words is null or w.n <= r.tier_max_words)) <> w.expect) as actual,
         '0' as expected,
         (select count(*) from words w
           where (select count(*) from public.admin_rates r
                   where r.rate_kind = 'per_article'
                     and w.n >= r.tier_min_words
                     and (r.tier_max_words is null or w.n <= r.tier_max_words)) <> w.expect) = 0 as pass
  union all
  -- The amounts each boundary lands on, stated rather than implied: the whole
  -- point of the boundary rule is WHICH price a 1000-word article gets.
  select '1000 words is the 100 RON tier, not the 150 one (the upper bound belongs to the lower tier)',
         (select r.amount::text from public.admin_rates r
           where r.rate_kind = 'per_article' and 1000 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)),
         '100',
         (select r.amount from public.admin_rates r
           where r.rate_kind = 'per_article' and 1000 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)) = 100
  union all
  select '1001 words is the 150 RON tier',
         (select r.amount::text from public.admin_rates r
           where r.rate_kind = 'per_article' and 1001 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)),
         '150',
         (select r.amount from public.admin_rates r
           where r.rate_kind = 'per_article' and 1001 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)) = 150
  union all
  select '4000 words is the 250 RON tier, not the 350 one',
         (select r.amount::text from public.admin_rates r
           where r.rate_kind = 'per_article' and 4000 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)),
         '250',
         (select r.amount from public.admin_rates r
           where r.rate_kind = 'per_article' and 4000 between r.tier_min_words and coalesce(r.tier_max_words, 2147483647)) = 250
  union all
  select 'no per-article tier starts below 500',
         (select coalesce(min(tier_min_words)::text, 'none') from public.admin_rates where rate_kind = 'per_article'),
         '500',
         (select min(tier_min_words) from public.admin_rates where rate_kind = 'per_article') = 500
  union all
  select 'the newsletter rate has no word bounds at all',
         (select count(*)::text from public.admin_rates
           where rate_kind = 'per_newsletter' and (tier_min_words is not null or tier_max_words is not null)),
         '0',
         (select count(*) from public.admin_rates
           where rate_kind = 'per_newsletter' and (tier_min_words is not null or tier_max_words is not null)) = 0;
rollback;

-- ============================================================================
-- Block 6: SABOTAGE -- re-create the overlap and block 5's walk must fail.
-- ============================================================================
-- Without this, block 5 above asserts something about data that happens to be
-- right; it is not a guard until it has been shown to break. This re-introduces
-- exactly the defect 202610130001 fixed -- the second tier starting at 1000
-- again -- and then re-runs BLOCK 5'S OWN FIRST ASSERTION, unchanged. The
-- runner requires a SABOTAGE row to come back pass:false; a true here would
-- mean the walk cannot see an overlap and has no teeth.
begin;
  create temp table words (n integer, expect integer) on commit drop;
  insert into words values
    (499, 0), (500, 1), (1000, 1), (1001, 1), (2000, 1),
    (2001, 1), (4000, 1), (4001, 1), (999999, 1);

  update public.admin_rates set tier_min_words = 1000
   where rate_kind = 'per_article' and tier_label = '1001-2000';

  select 'SABOTAGE: the second tier starts at 1000 again, same assertion as block 5' as check_name,
         (select count(*)::text from words w
           where (select count(*) from public.admin_rates r
                   where r.rate_kind = 'per_article'
                     and w.n >= r.tier_min_words
                     and (r.tier_max_words is null or w.n <= r.tier_max_words)) <> w.expect) as actual,
         '0' as expected,
         (select count(*) from words w
           where (select count(*) from public.admin_rates r
                   where r.rate_kind = 'per_article'
                     and w.n >= r.tier_min_words
                     and (r.tier_max_words is null or w.n <= r.tier_max_words)) <> w.expect) = 0 as pass;
rollback;
