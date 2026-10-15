-- ============================================================================
-- The three schools' street addresses. Anca, 2026-10-13, as Google Maps links.
-- ============================================================================
-- PROVENANCE, which is the reason this is a migration and not an afternoon of
-- typing into the app: an address is a fact that came from somewhere, and in
-- six months the question will be "who said this is where the school is". The
-- answer is this file. Anca sent three Google Maps links on 2026-10-13; the
-- strings below are what those pages give, copied rather than retyped.
--
-- DIACRITICS ARE LEFT EXACTLY AS GOOGLE MAPS WRITES THEM -- "Pădurea", "Șoseaua
-- București-Ploiești", "Coralilor ... București". Not normalised, not stripped.
-- This is the OPPOSITE of item 42's rule for organisation names, and
-- deliberately so: item 42 settled that `Asociatia STEMplicity` is written the
-- way the dropdown and the paperwork write it. An address is written the way
-- the map writes it, because that is the form a person types when they are
-- looking for the building. The two rules do not conflict; they apply to
-- different kinds of string.
--
--   Scoala Avenor                      Drumul Pădurea Pustnicu 125A, 014042 București
--   Școala Franceză (Lycee Francais)   Șoseaua București-Ploiești 160A, 015016 București
--   Scoala Germana                     Strada Coralilor 20G, 013328 București
--
-- MATCHED ON CUI, not on name and certainly not on position. The display name
-- of the second one is `'Școala Franceză  (Lycee Francais)'` -- with TWO
-- spaces before the parenthesis, live, today. Matching it by name means
-- reproducing that typo exactly or silently updating nothing; the CUI has no
-- such variants. Item 35 and item 42 are both about a name being "corrected"
-- wrongly, and this avoids the whole class.
--
-- REFUSES rather than overwrites. If any of the three is missing, or if any of
-- them already HAS an address, this raises and changes nothing: somebody may
-- have typed one into the app between this being written and being run, and
-- that value is newer than this file and was entered by a person who could see
-- the client. Silently replacing it would be the worst outcome available.
-- ============================================================================
do $$
declare
  v_org uuid;
  v_found integer;
  v_filled integer;
  v_changed integer;
  v_rows constant text[][] := array[
    ['RO37336710', 'Drumul Pădurea Pustnicu 125A, 014042 București'],
    ['18153988',   'Șoseaua București-Ploiești 160A, 015016 București'],
    ['44600473',   'Strada Coralilor 20G, 013328 București']
  ];
  v_row text[];
begin
  select id into v_org from public.organizations where name = 'WOW LAB';
  if v_org is null then
    raise exception 'organization "WOW LAB" not found';
  end if;

  select count(*) into v_found
    from public.clients
   where organization_id = v_org
     and cui in ('RO37336710', '18153988', '44600473');
  if v_found <> 3 then
    raise exception 'expected to find 3 clients by CUI in WOW LAB, found % -- refusing to guess which one moved', v_found;
  end if;

  select count(*) into v_filled
    from public.clients
   where organization_id = v_org
     and cui in ('RO37336710', '18153988', '44600473')
     and address is not null;
  if v_filled <> 0 then
    raise exception '% of the three already have an address -- refusing to overwrite a value entered through the app, which is newer than this file', v_filled;
  end if;

  v_changed := 0;
  foreach v_row slice 1 in array v_rows loop
    update public.clients
       set address = v_row[2]
     where organization_id = v_org and cui = v_row[1] and address is null;
    if not found then
      raise exception 'no row updated for cui % -- aborting with the table untouched', v_row[1];
    end if;
    v_changed := v_changed + 1;
  end loop;

  if v_changed <> 3 then
    raise exception 'expected to set 3 addresses, set %', v_changed;
  end if;
  raise notice 'addresses set on 3 clients';
end $$;
