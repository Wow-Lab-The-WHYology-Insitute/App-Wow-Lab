-- The six cancellations of 202610200005 carry the wrong actor. Corrected to
-- the person who actually decided and ran them.
--
-- ===========================================================================
-- WHAT WAS WRONG, AND IT WAS THE ARGUMENT, NOT THE TYPO
-- ===========================================================================
-- 202610200005 wrote `cancelled_by = Catalina Trusan` and defended it in its
-- own header: she holds Operations Manager, a cancellation is a fact about
-- the schedule that Operations records, so -- the argument went --
-- `cancelled_by` records who exercised the authority rather than who
-- testified.
--
-- SHE EXERCISED NOTHING. She was not asked, did not decide, and had not
-- answered when it ran. Her role WOULD HAVE permitted it. That is a fact
-- about her permissions and not a fact about these six rows.
--
-- This is the third instance of one substitution in two days, which is why
-- the rule is now `DATABASE_CONVENTIONS.md` §19 rather than another item:
--
--   1. 202610200002 named Anca because "the import runs on her
--      instruction" -- it ran on Mihai's. Corrected (item 152) to the real
--      fact: she had already approved those exact 38 rows in the timesheet.
--   2. This one named Catalina because the gate would admit her.
--   3. The ski week, same day: the county answers which week the
--      inspectorate chose, not which week this school is shut (§18).
--
-- Each replaces A SPECIFIC FACT ABOUT A SPECIFIC PERSON with A CATEGORY THAT
-- PERSON BELONGS TO. The category is always true and always irrelevant.
--
-- ===========================================================================
-- THE CORRECT ACTOR, AND THE FACT THAT MAKES IT CORRECT
-- ===========================================================================
-- `maxdigitalro@gmail.com` -- Mihai, `Organization Owner` in wow-lab,
-- holding both `org.settings.manage` and `sessions.create`.
--
-- The fact about this person and these rows, independent of the role: HE
-- READ THE THREE SCHOOL CALENDARS, DECIDED THE SIX WORKSHOPS DID NOT HAPPEN,
-- AND ORDERED THE CANCELLATION. That sentence is true whatever roles he
-- holds, which is exactly the test §19 sets.
--
-- NOTE which account this is NOT. `hello@maxdigital.ro` is the address the
-- work is done from, and in this database it is a stub: no roles in any
-- organization, `is_platform_owner` false, `full_name` null, zero rows in
-- row_history. 202610200005's FIRST draft tried to use it and its own guard
-- refused -- see item 157. The operating identity is the Organization Owner
-- account, created 2026-07-13, and this migration asserts its capabilities
-- rather than assuming them.
--
-- ===========================================================================
-- WHY A DIRECT UPDATE AND NOT THE RPC
-- ===========================================================================
-- app.rpc_cancel_session returns 'already_cancelled' for a row that is
-- already cancelled, by design (202610200003) -- cancelling is not an
-- operation you repeat. There is no "re-attribute" RPC and there should not
-- be one: this is a repair to a migration's own choice, not a user action.
--
-- So it is an UPDATE, touching ONE COLUMN. status, category, note and
-- cancelled_at are left exactly as they are: the cancellations were right,
-- their timestamp is when they really happened, and `vacanta` is still the
-- reason. Only the name is wrong.
--
-- row_history records this correction with Mihai as its actor too, which is
-- accurate twice over -- he is both the author of the repair and the person
-- the repair names.
--
-- ROLLBACK restores Catalina, and exists only so the pair is reversible as a
-- unit. Applying it would re-introduce a known-wrong attribution.

do $$
declare
  v_org uuid;
  v_mihai uuid;
  v_cat uuid;
  v_n integer;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'correct-actor: no organization with slug wow-lab';
  end if;

  select id into v_mihai from public.users where email = 'maxdigitalro@gmail.com';
  select id into v_cat   from public.users where email = 'catalina_moale@yahoo.com';
  if v_mihai is null or v_cat is null then
    raise exception 'correct-actor: missing the Organization Owner account or Catalina';
  end if;

  -- The new actor must really be able to have done this. §19's point is not
  -- that capability picks the name -- it is that the name picked must also
  -- hold the capability, or the row records something impossible.
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_mihai::text, 'role', 'authenticated')::text, true);
  if not (app.has_capability('org.settings.manage', v_org)
          and app.has_capability('sessions.create', v_org)) then
    raise exception 'correct-actor: maxdigitalro@gmail.com does not hold org.settings.manage and sessions.create in wow-lab';
  end if;

  -- Refuse unless the six are exactly as 202610200005 left them.
  if (select count(*) from public.sessions
      where organization_id = v_org
        and session_date between '2026-10-19' and '2026-10-21'
        and status = 'cancelled'
        and cancellation_category = 'vacanta'
        and cancelled_by = v_cat
        and cancelled_at is not null) <> 6 then
    raise exception 'correct-actor: the six workshops of 19-21 October are not the six cancelled by 202610200005 -- re-read before re-attributing';
  end if;

  update public.sessions
  set cancelled_by = v_mihai
  where organization_id = v_org
    and session_date between '2026-10-19' and '2026-10-21'
    and status = 'cancelled'
    and cancellation_category = 'vacanta';

  get diagnostics v_n = row_count;
  if v_n <> 6 then
    raise exception 'correct-actor: re-attributed % rows, expected 6', v_n;
  end if;

  -- ---- Assertions: ONLY the name moved ----
  if exists (
    select 1 from public.sessions
    where organization_id = v_org
      and session_date between '2026-10-19' and '2026-10-21'
      and (status <> 'cancelled' or cancellation_category <> 'vacanta'
           or cancellation_note is not null or cancelled_at is null
           or cancelled_by <> v_mihai
           or trainer_principal_confirmed_at is not null
           or trainer_secundar_confirmed_at is not null)
  ) then
    raise exception 'correct-actor: something other than the actor changed on the six';
  end if;

  if exists (select 1 from public.sessions
             where organization_id = v_org and cancelled_by = v_cat) then
    raise exception 'correct-actor: a cancellation still names Catalina';
  end if;

  -- And they are still worth nothing, which the re-attribution must not touch.
  if (select coalesce(sum(p.amount), 0)
      from public.calculate_org_session_pay(v_org, '2026-10-19', '2026-10-22') p) <> 0 then
    raise exception 'correct-actor: the six no longer price at 0';
  end if;

  raise notice 'correct-actor: 6 cancellations re-attributed from Catalina (role) to Mihai (decided and ran it); status, category and timestamp untouched';
end $$;
