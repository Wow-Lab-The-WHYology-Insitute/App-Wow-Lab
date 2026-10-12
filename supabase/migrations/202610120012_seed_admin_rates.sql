-- ============================================================================
-- The nine admin rates. Anca 2026-08-07, corrected by her 2026-08-10 message
-- (item 111). One version, effective 2026-08-10 -- the date of the correction,
-- not of the original figures, because the correction is what made them final.
-- ============================================================================
-- FINAL, no uplift (net_amount null, is_uplift_applied false):
--   Anka Orban      Admin      80 RON/hour
--   Anka Orban      Ateliere   80 RON/hour
--   Anka Orban      Financiar  90 RON/hour
--   Raluca Margean  article  500-1000 words   100
--   Raluca Margean  article  1000-2000 words  150
--   Raluca Margean  article  2000-4000 words  250
--   Raluca Margean  article  over 4000 words  350
--   Raluca Margean  internal newsletter      150 each
--
-- UPLIFTED, net x 1.11 (exact, see the schema migration's measurement):
--   Laura Moale        50 -> 55.50
--   Teodora Merisan    50 -> 55.50
--   Alexandra Nutu     50 -> 55.50
--   Catalina Trusan    72 -> 79.92   <- new; in no earlier record
--
-- Catalina is the first person with BOTH a trainer grade (202609240002) and an
-- admin rate, which is a constraint on the hours-entry screen rather than on
-- this table -- recorded as item 130.
--
-- Names are resolved to users by email, never by full_name: item 35 and item 42
-- both record a surname being "corrected" wrongly, and emails do not have
-- spelling variants. Every lookup is asserted non-null before insert.
do $$
declare
  v_org uuid;
  v_version uuid;
  v_anka uuid; v_margean uuid; v_laura uuid; v_teodora uuid; v_alexandra uuid; v_catalina uuid;
  v_anca uuid;
  v_n int;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'admin rate seed: organization wow-lab not found';
  end if;

  if exists (select 1 from public.admin_rate_versions where organization_id = v_org) then
    raise exception 'admin rate seed: org wow-lab already has an admin_rate_versions row -- refusing to seed on top of existing data';
  end if;

  select id into v_anka       from public.users where email = 'anka@asismart.ro';
  select id into v_margean    from public.users where email = 'ralucamargean@yahoo.com';
  select id into v_laura      from public.users where email = 'lauraflorentinaa220@gmail.com';
  select id into v_teodora    from public.users where email = 'merisanteodora@gmail.com';
  select id into v_alexandra  from public.users where email = 'alexandra.nutu2010@gmail.com';
  select id into v_catalina   from public.users where email = 'catalina_moale@yahoo.com';
  select id into v_anca       from public.users where email = 'anca.tanasescu@gmail.com';

  if v_anka is null or v_margean is null or v_laura is null or v_teodora is null
     or v_alexandra is null or v_catalina is null then
    raise exception 'admin rate seed: one of the six people did not resolve (anka=% margean=% laura=% teodora=% alexandra=% catalina=%)',
      v_anka, v_margean, v_laura, v_teodora, v_alexandra, v_catalina;
  end if;

  insert into public.admin_rate_versions (organization_id, effective_date, created_by, note)
  values (v_org, '2026-08-10', v_anca,
    'Anca 2026-08-07 as corrected by her 2026-08-10 message. Anka''s three rates and Raluca Margean''s article tiers are FINAL -- the invoiced amounts, no uplift. Only Laura, Teodora Merisan, Alexandra Nutu and Catalina Trusan carry the 11% uplift. Margean''s tiers supersede the supplier contract''s three tiers (item 111).')
  returning id into v_version;

  -- FINAL: Anka's three categories, in her own words (see the column comment).
  insert into public.admin_rates
    (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
  values
    (v_org, v_version, v_anka, 'hourly', 'admin',     80, null, false),
    (v_org, v_version, v_anka, 'hourly', 'ateliere',  80, null, false),
    (v_org, v_version, v_anka, 'hourly', 'financiar', 90, null, false);

  -- FINAL: Margean's four word-count bands plus the flat newsletter rate. The
  -- newsletter figure is the one the supplier contract never carried at all
  -- (item 105 recorded it as missing); these tiers supersede that contract's.
  insert into public.admin_rates
    (organization_id, version_id, person_user_id, rate_kind, tier_label, tier_min_words, tier_max_words, amount, net_amount, is_uplift_applied)
  values
    (v_org, v_version, v_margean, 'per_article', '500-1000',   500,  1000, 100, null, false),
    (v_org, v_version, v_margean, 'per_article', '1000-2000', 1000,  2000, 150, null, false),
    (v_org, v_version, v_margean, 'per_article', '2000-4000', 2000,  4000, 250, null, false),
    (v_org, v_version, v_margean, 'per_article', 'over-4000', 4000,  null, 350, null, false);
  insert into public.admin_rates
    (organization_id, version_id, person_user_id, rate_kind, amount, net_amount, is_uplift_applied)
  values
    (v_org, v_version, v_margean, 'per_newsletter', 150, null, false);

  -- UPLIFTED: net x 1.11, exact. The CHECK recomputes it, so these literals
  -- cannot drift from the arithmetic they claim.
  insert into public.admin_rates
    (organization_id, version_id, person_user_id, rate_kind, task_category, amount, net_amount, is_uplift_applied)
  values
    (v_org, v_version, v_laura,     'hourly', 'admin', 55.50, 50, true),
    (v_org, v_version, v_teodora,   'hourly', 'admin', 55.50, 50, true),
    (v_org, v_version, v_alexandra, 'hourly', 'admin', 55.50, 50, true),
    (v_org, v_version, v_catalina,  'hourly', 'admin', 79.92, 72, true);

  -- 12 = Anka 3 + Margean's 4 article bands + her 1 newsletter + 4 uplifted
  -- hourly. The first version of this assertion said 13 and the seed refused
  -- itself on the first run -- the guard catching a miscount in its own
  -- migration, which is what it is for.
  select count(*) into v_n from public.admin_rates where organization_id = v_org;
  if v_n <> 12 then
    raise exception 'admin rate seed: expected 12 rates, found %', v_n;
  end if;
  select count(*) into v_n from public.admin_rates where organization_id = v_org and is_uplift_applied;
  if v_n <> 4 then
    raise exception 'admin rate seed: expected 4 uplifted rates, found %', v_n;
  end if;
  select count(*) into v_n from public.admin_rates
   where organization_id = v_org and not is_uplift_applied and net_amount is not null;
  if v_n <> 0 then
    raise exception 'admin rate seed: % FINAL rate(s) carry a net amount, which would invite an uplift', v_n;
  end if;
end $$;
