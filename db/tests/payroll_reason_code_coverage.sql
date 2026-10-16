-- db/tests/payroll_reason_code_coverage.sql
-- Every place app.calculate_session_pay and its five resolvers can RAISE
-- must have a reason_code branch in app.calculate_org_session_pay's
-- classifier. Derived FROM THE FUNCTION SOURCES at run time, never from a
-- hand-written list of cases.
--
-- WHY DERIVED AND NOT ENUMERATED. The first version of this suite listed
-- the raise shapes by hand -- fourteen of them, each asserted by firing a
-- fixture that reaches it. That is a good test of the fourteen and no test
-- at all of the fifteenth. A raise added in six months by someone adding a
-- resolver, or a new guard in calculate_session_pay, would fall through to
-- `else 'unknown'` and the screen would print raw SQL at Anka -- and every
-- existing assertion would still pass.
--
-- This is item 120's lesson, which cost a release: the verifier written for
-- the gendered-noun rename contained six anticipated forms and missed the
-- seventh, which was introduced in the same commit. A checker that knows
-- what to look for only finds what someone already thought of. So this one
-- asks pg_get_functiondef for the real source and counts.
--
-- HOW IT WORKS, and the honest limits of it.
--   1. Pull the source of all six producing functions out of pg_proc.
--   2. Extract every `raise exception '<literal>'` message from them.
--   3. Pull the classifier's source and extract every `when v_error like
--      '%<pattern>%'` branch.
--   4. For each raise message, require at least one classifier pattern
--      that MATCHES it -- matched by actually running the message against
--      the pattern with LIKE, not by comparing strings. A `%`-wrapped
--      pattern that no raise can produce is also reported, since a
--      classifier branch matching nothing is a branch someone will trust.
--
-- The limit, stated rather than hidden: a raise message is a format string
-- (`'... no session % '`), so the `%` placeholders are substituted here
-- with a token before matching. A classifier pattern that depends on the
-- SUBSTITUTED value rather than the literal text around it would not be
-- provable this way -- none currently does, and the fixture-driven
-- assertions in payroll_org_session_pay.sql cover the behaviour end to end.
-- This file answers a narrower question: is any raise unclassifiable?
--
-- Reads catalogs only. No fixtures, nothing to clean up. Still wrapped in
-- begin/rollback for the runner's own block convention.

begin;
  create temp table raises (fn text, msg text);

  -- The six functions that can raise inside the classifier's try block:
  -- calculate_session_pay itself plus the five resolvers it composes.
  -- Listed by NAME, but their raise messages are read from their sources --
  -- so adding a resolver means adding one name here, and forgetting to do
  -- that is the one gap this file cannot close by itself. Guarded below by
  -- asserting the count of functions actually found.
  insert into raises (fn, msg)
  select p.proname, m.msg
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral (
    -- Every single-quoted literal that follows `raise exception`. The
    -- pattern stops at the first unescaped quote, which is correct for
    -- these messages: none of them contains an escaped quote.
    select (regexp_matches(pg_get_functiondef(p.oid), 'raise exception\s+''([^'']+)''', 'g'))[1] as msg
  ) m
  where n.nspname = 'app'
    and p.proname in (
      'calculate_session_pay',
      'resolve_trainer_grade',
      'resolve_trainer_grade_rate',
      'resolve_duration_multiplier',
      'resolve_location_bonus',
      'resolve_language_bonus'
    );

  -- The classifier's own branches, from its own source.
  create temp table patterns (pat text, code text);
  insert into patterns (pat, code)
  select m[1], m[2]
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral (
    select regexp_matches(
      pg_get_functiondef(p.oid),
      'when\s+v_error\s+like\s+''([^'']+)''\s+then\s+''([a-z_]+)''',
      'g'
    ) as m
  ) x
  where n.nspname = 'app' and p.proname = 'calculate_org_session_pay';

  -- Raise messages are format strings; substitute the placeholders with a
  -- token so LIKE can be run against them the way it is at run time.
  create temp table resolved_raises as
  select fn, msg, replace(msg, '%', 'XX') as concrete from raises;

  create temp table check_results (check_name text, pass boolean, detail text);

  -- Guard on the derivation itself: if these came back empty the file would
  -- "pass" by testing nothing, which is exactly how rls_ws_d_write.sql gave
  -- false positives for a month (item 86/88).
  insert into check_results
  select 'all six producing functions were found in pg_proc',
         (select count(distinct fn) = 6 from raises),
         (select coalesce(string_agg(distinct fn, ', '), '(none)') from raises);

  insert into check_results
  select 'at least 14 raise sites were extracted from their sources',
         (select count(*) >= 14 from raises),
         (select count(*)::text || ' found' from raises);

  insert into check_results
  select 'the classifier''s branches were extracted from its source',
         (select count(*) >= 14 from patterns),
         (select count(*)::text || ' branches' from patterns);

  -- THE ASSERTION THIS FILE EXISTS FOR.
  insert into check_results
  select 'every raise site has a classifier branch that matches it',
         not exists (
           select 1 from resolved_raises r
           where not exists (
             select 1 from patterns p where r.concrete like p.pat
           )
         ),
         coalesce((
           select string_agg(r.fn || ': ' || r.msg, ' | ')
           from resolved_raises r
           where not exists (select 1 from patterns p where r.concrete like p.pat)
         ), 'all matched');

  -- The other direction: a branch that no raise can reach. Not a
  -- correctness bug on its own, but it is a branch someone will later trust
  -- as covering something, and it usually means a message was reworded.
  insert into check_results
  select 'every classifier branch is reachable by some raise site',
         not exists (
           select 1 from patterns p
           where not exists (
             select 1 from resolved_raises r where r.concrete like p.pat
           )
         ),
         coalesce((
           select string_agg(p.code || ' (' || p.pat || ')', ' | ')
           from patterns p
           where not exists (select 1 from resolved_raises r where r.concrete like p.pat)
         ), 'all reachable');

  -- No raise may map to two different codes: the classifier is a CASE, so
  -- the first match wins silently, and two patterns matching one message
  -- means the reason shown depends on branch order rather than on the
  -- fault. Reported with the pair, because fixing it needs to know which.
  insert into check_results
  select 'no raise site is matched by branches carrying different codes',
         not exists (
           select 1
           from resolved_raises r
           join patterns p on r.concrete like p.pat
           group by r.msg
           having count(distinct p.code) > 1
         ),
         coalesce((
           select string_agg(x.msg || ' -> ' || x.codes, ' | ')
           from (
             select r.msg, string_agg(distinct p.code, '/') as codes
             from resolved_raises r
             join patterns p on r.concrete like p.pat
             group by r.msg
             having count(distinct p.code) > 1
           ) x
         ), 'no ambiguity');

  select check_name, pass, detail from check_results order by check_name;
rollback;

-- ============================================================================
-- SABOTAGE. The block above passes today; this one proves it can fail.
--
-- A derived checker that cannot be shown to break is worth no more than the
-- hand-written list it replaced -- rls_ws_d_write.sql passed for a month
-- while asserting nothing, including on its own sabotage self-check (item
-- 86/88). So: inside a transaction that always rolls back, replace one of
-- the six producing functions with a stub carrying a raise message no
-- classifier branch can match, re-run the same derivation, and require the
-- headline assertion to come back FALSE.
--
-- This is the scenario the file exists for, acted out: someone adds a raise
-- in six months and does not touch the classifier. The replacement is a
-- stub rather than the real resolver plus one line, because the derivation
-- reads the SOURCE and never calls the function -- what it returns is
-- irrelevant here, and a stub makes the sabotage unmistakable.
-- ============================================================================
begin;
  -- Same signature, so this is a replace rather than a second overload, and
  -- the rollback restores the real one. Nothing calls it inside this block.
  create or replace function app.resolve_language_bonus(
    p_organization_id uuid,
    p_language_group text,
    p_as_of date
  )
  returns numeric
  language plpgsql
  stable
  set search_path to ''
  as $sabotage$
  begin
    raise exception 'app.resolve_language_bonus: SABOTAGE -- a failure shape nobody classified';
  end;
  $sabotage$;

  create temp table raises (fn text, msg text);
  insert into raises (fn, msg)
  select p.proname, m.msg
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral (
    select (regexp_matches(pg_get_functiondef(p.oid), 'raise exception\s+''([^'']+)''', 'g'))[1] as msg
  ) m
  where n.nspname = 'app'
    and p.proname in (
      'calculate_session_pay',
      'resolve_trainer_grade',
      'resolve_trainer_grade_rate',
      'resolve_duration_multiplier',
      'resolve_location_bonus',
      'resolve_language_bonus'
    );

  create temp table patterns (pat text, code text);
  insert into patterns (pat, code)
  select m[1], m[2]
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral (
    select regexp_matches(
      pg_get_functiondef(p.oid),
      'when\s+v_error\s+like\s+''([^'']+)''\s+then\s+''([a-z_]+)''',
      'g'
    ) as m
  ) x
  where n.nspname = 'app' and p.proname = 'calculate_org_session_pay';

  create temp table resolved_raises as
  select fn, msg, replace(msg, '%', 'XX') as concrete from raises;

  create temp table check_results (check_name text, pass boolean, detail text);

  -- Precondition, NOT a sabotage assertion, so it is named so: the
  -- sabotaged raise has to be visible to the derivation at all, otherwise
  -- the assertion below would come back false for the wrong reason and the
  -- runner would read that as teeth it does not have.
  insert into check_results
  select 'sabotage precondition: the unclassified raise is visible to the derivation',
         (select exists (select 1 from raises where msg like '%SABOTAGE%')),
         (select count(*)::text || ' raise sites now' from raises);

  -- The headline assertion, RESTATED VERBATIM from the block above. The
  -- runner inverts any check whose name starts with SABOTAGE: reporting
  -- false here is what counts as a pass, because it means the coverage
  -- check noticed the unclassified raise. Reporting true would mean the
  -- check is decorative and a raise added in six months becomes a silent
  -- 'unknown'.
  insert into check_results
  select 'SABOTAGE: every raise site has a classifier branch that matches it',
         not exists (
           select 1 from resolved_raises r
           where not exists (select 1 from patterns p where r.concrete like p.pat)
         ),
         coalesce((
           select string_agg(r.fn || ': ' || r.msg, ' | ')
           from resolved_raises r
           where not exists (select 1 from patterns p where r.concrete like p.pat)
         ), 'nothing unmatched -- the checker is blind');

  select check_name, pass, detail from check_results order by check_name;
rollback;
