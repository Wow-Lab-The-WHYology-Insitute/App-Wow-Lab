-- app.calculate_session_pay: the first function in this domain that
-- computes rather than looks up. Deliberately NOT named resolve_* and
-- not shaped like the seven resolvers it composes (app.resolve_trainer_
-- grade, resolve_trainer_grade_rate, resolve_duration_multiplier,
-- resolve_location_bonus, resolve_language_bonus) -- those each answer
-- one question, pure lookup, no arithmetic. This one composes several
-- of their answers and multiplies them, which is a different kind of
-- operation and gets a different name to say so, not the resolver shape
-- stretched to cover something it wasn't built for.
--
-- Per trainer, not per session: a session has two slots (principal,
-- secundar), and each trainer can hold a different grade -- "this
-- session's pay" isn't a single number without saying whose. Takes a
-- trainer id and refuses (raises) if that trainer isn't principal or
-- secundar on the session -- a pay figure for someone who had no part
-- in the session is not a smaller or more cautious answer than an
-- error, it is a wrong one.
--
-- rate x duration_multiplier x (1 + location_bonus/100 + language_bonus/100),
-- unrounded. location_bonus_rates.bonus_percent and language_bonus_
-- rates.bonus_percent are stored as whole percent (25, not 0.25) --
-- divided by 100 here, the one place this shape actually multiplies
-- anything together. No rounding step exists anywhere in this function
-- on purpose: 444 of 1,456 real approved historical amounts carry bani
-- (198.36, 164.16, 200.625 among them) -- "to the leu" meant to the
-- ban, not to the whole number (item 95).
--
-- Never calls app.resolve_contract_type_uplift. The six PFA-inclusive
-- rates trainer_grade_rates carries already have the 11.1% PFA/SRL
-- uplift baked in (Anca, item 95: "in contractul cu trainerii PFA sau
-- SRL vom avea direct 111 lei/ora tarif de baza junior") -- calling the
-- uplift resolver here would double it, not add to it.
-- contract_type_uplift and contract_type_uplift_versions are kept at
-- zero rows for exactly this reason; see app.resolve_contract_type_
-- uplift's own COMMENT ON FUNCTION (202609240001) for the same note
-- from the other side.
--
-- delivery_context (standard vs scoala_altfel_saptamana_verde) is read
-- from the GROUP's delivery_format, never from anything on the session
-- -- sessions carries no format of its own. Passed straight through to
-- app.resolve_duration_multiplier, whose own internal mapping already
-- does the narrowing: of the nine workshop types (item 79/85), only
-- scoala_altfel and saptamana_verde map to the special context --
-- confirmed by reading that resolver's own case statement, not assumed
-- -- every other one of the nine (wow_lab_party, parteneriate_companii,
-- cursuri_deschise, scoli_private_ocazionale, scoli_private_recurente,
-- evenimente_mall, party_companii) resolves as standard.
--
-- SECURITY INVOKER (the default -- no SECURITY DEFINER), same reasoning
-- as all seven resolvers it calls: this function has no internal
-- authorization check of its own, so SECURITY DEFINER would let any
-- caller reconstruct grade rates regardless of their own SELECT rights
-- on trainer_grade_rates etc. (finance.operations.*/finance.reporting.*/
-- owner only, 202608310002) -- meaning, today, only a finance- or
-- owner-capable caller can successfully call this function at all; a
-- plain trainer's own session cookie does not carry read access to the
-- rate tables underneath it. Not fixed here -- nothing calls this
-- function yet (no UI, no payroll screen), and the eventual caller is
-- expected to be finance-facing, matching every other pay-grid read in
-- this codebase. Revisit if a trainer-facing caller is ever built.
--
-- Fails loud on every missing input, matching the resolvers' own
-- discipline, one level up:
--   - no such session, or the trainer isn't principal/secundar on it:
--     raised directly by this function, naming the session/trainer ids.
--   - session has no duration_minutes or no location_tier, or the
--     group has no language_group: raised directly by this function,
--     naming which field and which row -- these are recorded facts
--     that simply were never entered, not a grid gap, so the message
--     says so specifically rather than falling through into a
--     resolver's more generic "no row for value" message.
--   - no grade assignment for this trainer, no rate for their grade, no
--     multiplier for this exact duration/context, no bonus for this
--     tier/language: raised by the underlying resolver itself, whose
--     own message already names the specific input and organization --
--     not caught or rewrapped here, so the caller sees exactly which
--     resolver failed and why.

create or replace function app.calculate_session_pay(
  p_session_id uuid,
  p_trainer_id uuid
)
returns numeric
language plpgsql
stable
set search_path to ''
as $$
declare
  v_org uuid;
  v_session_date date;
  v_duration_minutes integer;
  v_location_tier text;
  v_principal_id uuid;
  v_secundar_id uuid;
  v_group_id uuid;
  v_delivery_format text;
  v_language_group text;
  v_grade integer;
  v_rate numeric;
  v_duration_multiplier numeric;
  v_location_bonus numeric;
  v_language_bonus numeric;
begin
  if p_trainer_id is null then
    raise exception 'app.calculate_session_pay: p_trainer_id must not be null';
  end if;

  select organization_id, session_date, duration_minutes, location_tier, trainer_principal_id, trainer_secundar_id, group_id
    into v_org, v_session_date, v_duration_minutes, v_location_tier, v_principal_id, v_secundar_id, v_group_id
  from public.sessions
  where id = p_session_id;

  if v_org is null then
    raise exception 'app.calculate_session_pay: no session % ', p_session_id;
  end if;

  if p_trainer_id is distinct from v_principal_id and p_trainer_id is distinct from v_secundar_id then
    raise exception 'app.calculate_session_pay: trainer % is not the principal or secundar trainer on session %', p_trainer_id, p_session_id;
  end if;

  if v_duration_minutes is null then
    raise exception 'app.calculate_session_pay: session % has no duration_minutes recorded', p_session_id;
  end if;

  if v_location_tier is null then
    raise exception 'app.calculate_session_pay: session % has no location_tier recorded', p_session_id;
  end if;

  select delivery_format, language_group into v_delivery_format, v_language_group
  from public.groups
  where id = v_group_id;

  if v_language_group is null then
    raise exception 'app.calculate_session_pay: group % has no language_group recorded', v_group_id;
  end if;

  v_grade := app.resolve_trainer_grade(p_trainer_id, v_session_date);
  v_rate := app.resolve_trainer_grade_rate(v_org, v_grade, v_session_date);
  v_duration_multiplier := app.resolve_duration_multiplier(v_org, v_duration_minutes, v_delivery_format, v_session_date);
  v_location_bonus := app.resolve_location_bonus(v_org, v_location_tier, v_session_date);
  v_language_bonus := app.resolve_language_bonus(v_org, v_language_group, v_session_date);

  return v_rate * v_duration_multiplier * (1 + v_location_bonus / 100 + v_language_bonus / 100);
end;
$$;

revoke all on function app.calculate_session_pay(uuid, uuid) from public;
grant execute on function app.calculate_session_pay(uuid, uuid) to authenticated, service_role;
