-- The name contradiction (B3, Mihai 2026-10-30), resolved without
-- guessing anyone's real name.
--
-- `lib/display-name.ts`'s displayName() already prefers first_name +
-- last_name over full_name app-wide ("Cătălina Moale" is what every
-- screen already shows) -- full_name is only ever a fallback for when
-- both structured columns are unset. The contradiction was invisible
-- precisely because nothing reads full_name for display while first/last
-- are set; it sat there agreeing with nothing.
--
-- Two separate facts, kept separate on purpose:
--   DISPLAY stays what it already was -- first_name/last_name, "Cătălina
--     Moale". Not decided here to be "the real name"; decided to be
--     the string every screen already shows, which full_name should
--     stop disagreeing with.
--   LEGAL (the invoice) gets its own column, suppliers.legal_name,
--     empty until now -- "TRUȘAN FLORINA CĂTĂLINA PFA", read directly
--     off her supplier contract. Nobody had to decide which of "Moale"
--     or "Trușan" is more real; the invoice name goes in the column
--     that means "name on the invoice."
--
-- users.full_name is updated to match first_name + last_name exactly,
-- closing the self-contradiction (the row disagreeing with itself) --
-- not a claim about which surname is correct, since full_name was never
-- the invoice name either.

do $$
declare
  v_catalina uuid;
  v_before_full_name text;
  v_before_legal_name text;
begin
  select id into v_catalina from public.users where email = 'catalina_moale@yahoo.com';
  if v_catalina is null then
    raise exception 'catalina_legal_name: no user catalina_moale@yahoo.com';
  end if;

  select full_name into v_before_full_name from public.users where id = v_catalina;
  if v_before_full_name <> 'Cătălina Trușan' then
    raise exception 'catalina_legal_name: full_name is not "Cătălina Trușan" any more (is %) -- re-read before applying', v_before_full_name;
  end if;

  update public.users
  set full_name = 'Cătălina Moale'
  where id = v_catalina;

  select legal_name into v_before_legal_name from public.suppliers where user_id = v_catalina;
  if v_before_legal_name is not null then
    raise exception 'catalina_legal_name: suppliers.legal_name already has a value (%) -- re-read before applying', v_before_legal_name;
  end if;

  update public.suppliers
  set legal_name = 'TRUȘAN FLORINA CĂTĂLINA PFA'
  where user_id = v_catalina;

  if (select full_name from public.users where id = v_catalina) <> 'Cătălina Moale' then
    raise exception 'catalina_legal_name: full_name update did not take';
  end if;
  if (select legal_name from public.suppliers where user_id = v_catalina) <> 'TRUȘAN FLORINA CĂTĂLINA PFA' then
    raise exception 'catalina_legal_name: legal_name update did not take';
  end if;

  raise notice 'catalina_legal_name: users.full_name now matches first_name+last_name ("Catalina Moale"); suppliers.legal_name carries the invoice name ("TRUSAN FLORINA CATALINA PFA") for the first time.';
end $$;

-- ---------------------------------------------------------------------------
-- A SECOND, DIFFERENT CASE, FOUND BY THE SAME CHECK, REPORTED NOT FIXED
-- (Mihai's own instruction: give the list, don't repair all of it).
-- ---------------------------------------------------------------------------
-- rabalasov@gmail.com: full_name "Răzvan Alexandru Bălașov", last_name
-- "Balașov" -- missing the diacritic on the first ă, not a different
-- surname the way Cătălina's two names were. No supplier row exists for
-- him at all, so there is no legal_name question here, only a spelling
-- one. Left alone -- see OPEN_ITEMS item 178 for the full list this
-- migration's own check produced.
do $$
begin
  raise notice 'catalina_legal_name: second contradiction found (rabalasov@gmail.com, last_name missing a diacritic) -- NOT fixed, per instruction. See OPEN_ITEMS item 178.';
end $$;
