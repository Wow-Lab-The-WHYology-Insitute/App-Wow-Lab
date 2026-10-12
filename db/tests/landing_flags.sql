-- db/tests/landing_flags.sql
-- app.has_any_capability + app.resolve_landing_flags (202610120008, item 125).
--
-- Only the LAST statement's result set per begin/rollback block reaches the
-- runner, and it must carry check_name / actual / expected / pass.
--
-- Every block impersonates. A SECURITY DEFINER function that answers about
-- app.current_user_id() cannot be tested as the connecting role, which has no
-- user id at all -- and that degenerate case is itself asserted in block 1.

-- ============================================================================
-- Block 1: has_any_capability -- the primitive, including every way of
-- asking it nothing.
-- ============================================================================
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_org uuid := (select id from public.organizations where slug = 'wow-lab-test-b');
    v_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
  begin
    -- No session at all: fails closed rather than erroring.
    insert into r select 'no_session', app.has_any_capability(array['mywork.*'], v_org)::text;

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
    insert into r select 'holds_one', app.has_any_capability(array['clients.read','mywork.*'], v_org)::text;
    insert into r select 'holds_none', app.has_any_capability(array['clients.read','contracts.read'], v_org)::text;
    insert into r select 'empty_array', app.has_any_capability(array[]::text[], v_org)::text;
    insert into r select 'null_array', app.has_any_capability(null, v_org)::text;
    insert into r select 'null_org', app.has_any_capability(array['mywork.*'], null)::text;
    insert into r select 'unknown_key', app.has_any_capability(array['not.a.real.capability'], v_org)::text;
    -- The wildcard rule still comes from app.has_capability, not from a second
    -- implementation: a trainer holds `curriculum.read` outright, and an owner
    -- holds `curriculum.*` -- asked for the narrow key, both must answer true.
    insert into r select 'wildcard_narrow_key', app.has_any_capability(array['curriculum.read'], v_org)::text;
  end $$;

  select 'no session: false, not an error' as check_name,
         (select val from r where what='no_session') as actual, 'false' as expected,
         (select val from r where what='no_session') = 'false' as pass
  union all
  select 'true when the caller holds any one of the keys',
         (select val from r where what='holds_one'), 'true',
         (select val from r where what='holds_one') = 'true'
  union all
  select 'false when the caller holds none of them',
         (select val from r where what='holds_none'), 'false',
         (select val from r where what='holds_none') = 'false'
  union all
  select 'an empty array is false, never true',
         (select val from r where what='empty_array'), 'false',
         (select val from r where what='empty_array') = 'false'
  union all
  select 'a null array is false',
         (select val from r where what='null_array'), 'false',
         (select val from r where what='null_array') = 'false'
  union all
  select 'a null organization is false',
         (select val from r where what='null_org'), 'false',
         (select val from r where what='null_org') = 'false'
  union all
  select 'an invented capability key is false',
         (select val from r where what='unknown_key'), 'false',
         (select val from r where what='unknown_key') = 'false'
  union all
  select 'the wildcard rule still comes from app.has_capability',
         (select val from r where what='wildcard_narrow_key'), 'true',
         (select val from r where what='wildcard_narrow_key') = 'true';
rollback;

-- ============================================================================
-- Block 2: resolve_landing_flags for the three real shapes.
-- ============================================================================
-- These are the three accounts the landing rule exists to tell apart:
--   trainer      mywork.* and nothing beyond  -> /my-work
--   ops manager  no mywork.* at all           -> /profile
--   owner        both                          -> /profile
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_ops uuid := (select id from public.users where email = 'test+ui-ops-manager-b@wowlab.dev');
    v_owner uuid := (select id from public.users where email = 'test+user-b@wowlab.dev');
    c_beyond constant text[] := array['clients.read','contracts.read','groups.read',
      'finance.operations.*','finance.reporting.*','org.members.manage','org.settings.manage','curriculum.validate'];
    v_m boolean; v_b boolean;
  begin
    insert into r select 'connecting_role', (has_mywork::text || '/' || has_beyond::text)
      from app.resolve_landing_flags('mywork.*', c_beyond);

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
    select has_mywork, has_beyond into v_m, v_b from app.resolve_landing_flags('mywork.*', c_beyond);
    insert into r values ('trainer', v_m::text || '/' || v_b::text);

    perform set_config('request.jwt.claims', json_build_object('sub', v_ops::text, 'role', 'authenticated')::text, true);
    select has_mywork, has_beyond into v_m, v_b from app.resolve_landing_flags('mywork.*', c_beyond);
    insert into r values ('ops', v_m::text || '/' || v_b::text);

    perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
    select has_mywork, has_beyond into v_m, v_b from app.resolve_landing_flags('mywork.*', c_beyond);
    insert into r values ('owner', v_m::text || '/' || v_b::text);
  end $$;

  select 'no session: both false, so the app lands on /profile' as check_name,
         (select val from r where what='connecting_role') as actual, 'false/false' as expected,
         (select val from r where what='connecting_role') = 'false/false' as pass
  union all
  select 'a plain trainer: mywork yes, beyond no -> /my-work',
         (select val from r where what='trainer'), 'true/false',
         (select val from r where what='trainer') = 'true/false'
  union all
  select 'an operations_manager: no mywork at all -> /profile',
         (select val from r where what='ops'), 'false/true',
         (select val from r where what='ops') = 'false/true'
  union all
  select 'an organization_owner: holds both -> /profile',
         (select val from r where what='owner'), 'true/true',
         (select val from r where what='owner') = 'true/true';
rollback;

-- ============================================================================
-- Block 3: SABOTAGE. Grant the trainer role a capability it does not hold and
-- the trainer's "beyond own work" answer must flip from false to true.
-- ============================================================================
-- Without this, block 2's trainer assertion would pass identically if
-- resolve_landing_flags ignored its p_beyond_caps argument entirely and
-- hardcoded false -- "the trainer answers false" is not evidence that the
-- question was asked. The sabotage adds clients.read (which gates /clients) to
-- the trainer role, so the correct answer genuinely becomes true; a run that
-- still says false has no teeth.
begin;
  create temp table r (what text, val text) on commit drop;
  grant insert, select on r to authenticated;

  do $$
  declare
    v_trainer uuid := (select id from public.users where email = 'maxdigitalro+trainerb1@gmail.com');
    v_role uuid := (select id from public.roles where key = 'trainer');
    v_cap uuid := (select id from public.capabilities where key = 'clients.read');
    c_beyond constant text[] := array['clients.read','contracts.read','groups.read',
      'finance.operations.*','finance.reporting.*','org.members.manage','org.settings.manage','curriculum.validate'];
    v_m boolean; v_b boolean;
  begin
    insert into public.role_capabilities (role_id, capability_id) values (v_role, v_cap);

    set local role authenticated;
    perform set_config('request.jwt.claims', json_build_object('sub', v_trainer::text, 'role', 'authenticated')::text, true);
    select has_mywork, has_beyond into v_m, v_b from app.resolve_landing_flags('mywork.*', c_beyond);
    insert into r values ('trainer', v_m::text || '/' || v_b::text);
  end $$;

  select 'SABOTAGE: a plain trainer holds nothing beyond their own work, same assertion as block 2, clients.read granted to the trainer role' as check_name,
         (select val from r where what='trainer') as actual, 'true/false' as expected,
         (select val from r where what='trainer') = 'true/false' as pass;
rollback;
