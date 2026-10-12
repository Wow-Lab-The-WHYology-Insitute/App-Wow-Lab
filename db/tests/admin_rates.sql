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
      app.resolve_admin_rate(v_org, v_margean, 'per_article', null, '2000-4000', '2026-10-12')::text;
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
