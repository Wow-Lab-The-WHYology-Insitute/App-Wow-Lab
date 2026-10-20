-- The six workshops of 19-21 October did not happen: all three schools were
-- on their autumn holiday. Cancelled with category `vacanta`.
--
-- ===========================================================================
-- DECIDED 2026-10-20 BY MIHAI, after reading the same three calendars
-- ===========================================================================
-- "ANULEAZA cele 6, motiv 'vacanta', prin rpc_cancel_session. Nu le sterge
-- - conventia 12, randul ramane cu motivul."
--
-- This is the FIRST REAL USE of app.rpc_cancel_session: six cancellations,
-- zero pay, zero reason_code, a real actor in row_history. Everything the
-- function was built for in 202610200003, exercised on real rows rather
-- than on a test fixture.
--
-- Nothing false had been asserted before this ran: all six rows were
-- `planned` and unconfirmed -- the application saying "scheduled", not
-- "delivered". What was wrong is that /payroll showed 956.50 of pending pay
-- that could never be earned. After this, October reads 1913.00 payable and
-- 0.00 pending.
--
-- NOT DELETED, and that is convention 12: the row stays, carrying the
-- reason. "This workshop did not happen because the school was on holiday"
-- is a fact worth keeping; an absent row says nothing at all, and next
-- year's generator would have no way to learn that this week is never a
-- teaching week.
--
--
-- VERIFIED BEFORE APPLYING: this file and its rollback were run against the
-- live database inside `begin; ... rollback;` -- forward, then
-- 202610200006, then both rollbacks -- and the state came back to exactly
-- 1/1/4 planned workshops with no category. Every assertion in all four
-- files held before any of it was committed.
-- ===========================================================================
-- THE EVIDENCE, read from each school's own published calendar
-- ===========================================================================
-- Lycee Francais Anna de Noailles -- https://www.lyceefrancais.ro/pdf/calendrier/calendrier.pdf
--   Vacances de la Toussaint: Monday 19 October - Sunday 1 November 2026.
--   Last school day Friday 16 October; return Monday 2 November.
--   (Read from the PDF's colour bands, not its text: the holidays are
--   colour-coded and extracting the text loses the colour. 19 and 20 October
--   are `Vacances Scolaires` blue.)
--
-- Deutsche Schule Bukarest -- https://www.dsbu.ro/calendar-vacante/
--   Herbstferien: "Oktober 19 (Montag) - 23 (Freitag)" 2026. ONE week.
--   Return Monday 26 October.
--
-- Avenor College -- https://www.avenor.ro/wp-content/uploads/2026/02/2026-2027-Avenor-School-Calendar.pdf
--   19-23 October 2026 shaded `Holidays`. ONE week. Return Monday 26 October.
--
-- ===========================================================================
-- WHAT THIS MEANS FOR THE REASON `202610200004` GAVE, which was wrong
-- ===========================================================================
-- That migration stopped at 21 October and asserted that nothing is dated
-- inside 24 October - 1 November, on the NATIONAL school-year structure
-- (item 154). The national structure governs none of these three schools'
-- autumn break:
--
--             19-23 Oct     24 Oct - 1 Nov     26-30 Oct
--   national  school        HOLIDAY            holiday
--   Lycee     HOLIDAY       HOLIDAY            HOLIDAY
--   DSBU      HOLIDAY       weekend/school     school
--   Avenor    HOLIDAY       weekend/school     school
--
-- So the guard was pointed at the wrong week. It protected a week that two
-- of the three schools teach, and admitted the week all three take off.
-- Both halves of that are repaired -- this file cancels the six that were
-- wrongly inserted; `schedule_28_october_avenor_and_german.sql` beside it
-- inserts the four that were wrongly withheld.
--
-- ===========================================================================
-- ACTOR: Catalina, and three facts had to be checked before writing a name
-- ===========================================================================
-- app.rpc_cancel_session writes `cancelled_by = app.current_user_id()`, so
-- somebody's name goes on these six rows, and the gate decides who CAN be
-- that somebody: is_platform_owner() OR org.settings.manage OR
-- sessions.create.
--
-- The first draft of this file impersonated Mihai, reasoning that the
-- assertion is his: he read the three calendars. The guard below was written
-- to prove the actor passes the gate, and it refused. Three things came out
-- of chasing that, and they outlive this migration:
--
--   1. `hello@maxdigital.ro` HAS NO ROLES IN THIS ORGANIZATION and
--      `users.is_platform_owner` is false on it. full_name is null. It is a
--      stub row, not an operating identity -- it cannot cancel anything, and
--      a migration that put its name on six rows would have been writing
--      down an actor who could not have performed the act.
--
--   2. THE ONLY ROW WITH `users.is_platform_owner = true` IS A TEST
--      ACCOUNT, `test+platform@wowlab.dev`. Anca Tanasescu holds the ROLE
--      named `Platform Owner` and the FUNCTION `app.is_platform_owner()`
--      returns false for her -- two mechanisms wearing the same name and
--      disagreeing. 202610200002's header says "Anca (platform owner)";
--      that is true of her role and false of the function, and she passed
--      that migration's gate on capabilities from the role, never on
--      is_platform_owner(). The import is correct; its reason names the
--      wrong mechanism.
--
--   3. Catalina Trusan holds `Operations Manager` as well as `Trainer`.
--      That is why she has `sessions.create` -- the same double role that
--      made an earlier gate test pick Anka Orban and prove nothing
--      (item 142). Here it is not a problem: it is the answer.
--
-- SO: CATALINA. Not because she is the Lycee's trainer -- a trainer saying
-- "it did not happen" is an assertion with money on the client side, which
-- is exactly why this gate excludes trainers. Because she holds Operations
-- Manager, and a cancellation is a fact about the schedule that Operations
-- records (202609150002's fork decision, restated in 202610200003's gate).
-- She is also the trainer at four of the six, so she is the Operations
-- person closest to them.
--
-- WHAT THIS DOES NOT CLAIM. `cancelled_by` records who exercised the
-- authority, not that Catalina personally testified to anything. She had
-- not answered when this ran. The FACT is not her testimony -- it is three
-- published calendars that anybody can open and check, which is precisely
-- why it does not need to be somebody's testimony. That is the difference
-- from a confirmation, which is irreducibly personal and which item 152
-- would not let anyone make on another person's behalf.
--
-- IF SHE ANSWERS THAT THE WORKSHOPS DID RUN, the rollback beside this file
-- restores all six to `planned` and refuses if anything has been confirmed
-- in the meantime.
--
-- ===========================================================================
-- CATEGORY: `vacanta`, and it is deliberately not `scoala_a_anulat_anuntat`
-- ===========================================================================
-- The school did not cancel anything. Its calendar was published months ago
-- and we scheduled into it. `vacanta` says exactly that, and it is the
-- category that will make "how often does this happen" answerable the moment
-- somebody asks -- which is the whole reason the five categories are an
-- enum rather than free text.
--
-- Pay consequence: not payable, via the rule in app.calculate_session_pay
-- (payable = confirmed OR cancelled-and-scoala_a_anulat_neanuntat). The six
-- stop being pending pay. That is the point.

do $$
declare
  v_org uuid;
  v_actor uuid;
  v_actor_email constant text := 'catalina_moale@yahoo.com';
  v_row record;
  v_result text;
  v_n integer := 0;
  v_pending numeric;
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then
    raise exception 'cancel-holiday: no organization with slug wow-lab';
  end if;

  select id into v_actor from public.users where email = v_actor_email;
  if v_actor is null then
    raise exception 'cancel-holiday: no user % to act as', v_actor_email;
  end if;

  -- Refuse if the six are not in the state this was written against.
  if (select count(*) from public.sessions
      where organization_id = v_org
        and session_date between '2026-10-19' and '2026-10-21'
        and status = 'planned'
        and cancellation_category is null
        and trainer_principal_confirmed_at is null
        and trainer_secundar_confirmed_at is null) <> 6 then
    raise exception 'cancel-holiday: expected exactly 6 planned, unconfirmed, uncancelled workshops in 19-21 October -- re-read before cancelling';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'role', 'authenticated')::text, true);

  -- THE GUARD THAT CAUGHT THE FIRST DRAFT. Refuse before writing anything if
  -- the chosen actor cannot pass rpc_cancel_session's own gate -- otherwise
  -- the first call returns 'not_permitted' and the only evidence is a string.
  if not (app.is_platform_owner()
          or app.has_capability('org.settings.manage', v_org)
          or app.has_capability('sessions.create', v_org)) then
    raise exception 'cancel-holiday: % cannot pass rpc_cancel_session''s gate -- pick an actor who can, do not widen the gate', v_actor_email;
  end if;

  for v_row in
    select s.id, s.session_date, c.name as school
    from public.sessions s
    join public.groups g on g.id = s.group_id
    join public.clients c on c.id = g.client_id
    where s.organization_id = v_org
      and s.session_date between '2026-10-19' and '2026-10-21'
    order by s.session_date, s.start_time
  loop
    v_result := public.rpc_cancel_session(v_row.id, 'vacanta', null);
    if v_result <> 'ok' then
      raise exception 'cancel-holiday: % on % returned %', v_row.school, v_row.session_date, v_result;
    end if;
    v_n := v_n + 1;
  end loop;

  -- ---- Assertions ----
  if v_n <> 6 then
    raise exception 'cancel-holiday: cancelled %, expected 6', v_n;
  end if;

  if exists (
    select 1 from public.sessions
    where organization_id = v_org
      and session_date between '2026-10-19' and '2026-10-21'
      and (status <> 'cancelled' or cancellation_category <> 'vacanta'
           or cancelled_at is null or cancelled_by is distinct from v_actor)
  ) then
    raise exception 'cancel-holiday: a workshop in 19-21 October is not cancelled as vacanta by the expected actor';
  end if;

  -- THE ONE THAT MATTERS: they are worth nothing now.
  select coalesce(sum(p.amount), 0) into v_pending
  from public.calculate_org_session_pay(v_org, '2026-10-19', '2026-10-22') p;
  if v_pending <> 0 then
    raise exception 'cancel-holiday: the six still price at %, expected 0', v_pending;
  end if;

  -- And nothing else moved: the 38 delivered workshops are untouched.
  if (select count(*) from public.sessions
      where organization_id = v_org and session_date <= '2026-10-16'
        and status = 'delivered' and cancellation_category is null) <> 38 then
    raise exception 'cancel-holiday: the 38 delivered workshops are no longer 38 delivered and uncancelled';
  end if;

  raise notice 'cancel-holiday: 6 workshops of 19-21 October cancelled as vacanta; 956.50 of pending pay is now 0; the 38 delivered are untouched';
end $$;
