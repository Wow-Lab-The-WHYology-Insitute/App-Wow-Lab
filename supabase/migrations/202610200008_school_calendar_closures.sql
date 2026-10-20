-- The three schools' calendars, as data. Item 154's table, finally built --
-- and built WITHOUT the national default, because §18 says there isn't one.
--
-- ===========================================================================
-- WHY THIS EXISTS AT ALL, when a generator could carry the dates inline
-- ===========================================================================
-- Because they would then be unreadable, uncheckable and unshareable. The
-- dates below were read off three published calendars by eye and by pixel;
-- the only way anybody can ever audit that is if they are rows somebody can
-- SELECT next to the source URL they came from.
--
-- And because 202610200009 asserts against this table rather than against a
-- hand-written list of expected dates. An assertion that compares a
-- generator's output to a list typed in the same migration proves the typing
-- was consistent. An assertion that compares it to the CALENDAR proves the
-- schedule matches the school.
--
-- ===========================================================================
-- WHAT A ROW IS, AND WHY `blocks_workshop` IS A SEPARATE COLUMN
-- ===========================================================================
-- One row = one marking on one school's calendar, with the school's OWN
-- WORDING in `label`. Not our paraphrase: `Early Dismissal for Students -
-- 12:00`, `Journees Pedagogiques sans accueil d'enfants a l'ecole`,
-- `Brueckentag`. When somebody asks in March why there is no workshop on a
-- Wednesday, the answer should be the school's sentence, not ours.
--
-- `kind` groups them so "how many short days does Avenor have" is a GROUP BY.
-- `blocks_workshop` answers the only question the generator asks, and it is
-- NOT derivable from `kind`:
--
--   * `zi_scurta` -- Avenor, 30 June 2027, `Early Dismissal for Students -
--     12:00`. School is OPEN. Children leave at noon. Our workshops are at
--     15:15 and 16:15. BLOCKS. This is the row the whole table was worth
--     building for: a holiday-only calendar would have counted that day as a
--     teaching day and put two workshops into an empty building.
--   * `inset_management` -- Avenor, 14 Nov 2026 and 17 Apr 2027, `Inset Days
--     for Management`. Both Saturdays, and management training does not shut
--     the school. DOES NOT BLOCK. Recorded anyway, because "we looked and it
--     does not matter" and "we never looked" must not be the same row count.
--   * `alt` -- `School Opening Ceremony` (1 Sep, does not block),
--     `Summer School` (5-16 July, blocks -- a different programme runs).
--
-- ===========================================================================
-- THE SOURCES, one per school, recorded on every row
-- ===========================================================================
-- Lycee Francais  https://www.lyceefrancais.ro/pdf/calendrier/calendrier.pdf
--   A single-page colour grid. The holidays ARE the colours, so the text
--   layer is useless: it was rasterised and classified by pixel. Legend --
--   blue `Vacances Scolaires`, pink `Jours feries sans ecole`, orange
--   `Journees Pedagogiques sans accueil d'enfants a l'ecole`. Three states,
--   no short days.
-- Deutsche Schule https://www.dsbu.ro/calendar-vacante/
--   An EVENT LIST, not a day grid -- which is weaker evidence in one specific
--   way, recorded here so nobody later reads its silence as a measurement:
--   it publishes no short day and no inset day, and an absent entry in a list
--   is not the same as a white cell in a grid. If a `letzter Schultag` half
--   day exists, this table does not know about it.
-- Avenor College  https://www.avenor.ro/wp-content/uploads/2026/02/2026-2027-Avenor-School-Calendar.pdf
--   A day grid with SIX legend colours and three kinds of outlined box. The
--   richest of the three, and the only one with early dismissals.
--
-- ===========================================================================
-- NO NATIONAL ROWS, and that is §18 as a schema decision
-- ===========================================================================
-- The national structure (Ordin 3194/2026) matches none of these three on any
-- boundary. It is not seeded as a default anybody falls back to, because
-- there is nothing to fall back to: a school with no rows here makes the
-- generator REFUSE (202610200009 asserts exactly that). The failure mode of a
-- fallback is a workshop with the right group, the right trainer, the right
-- price and the wrong week; the failure mode of a refusal is somebody being
-- told to go and get the calendar.

create table public.school_calendar_closures (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,

  -- Convention §16: the school year is 1 September - 31 August, labelled by
  -- its starting year. Stored as text because that is how everyone says it.
  school_year text not null,

  from_date date not null,
  to_date date not null,            -- INCLUSIVE, so a single day is from = to

  kind text not null,
  label text not null,              -- the school's own wording, verbatim
  source_url text not null,

  -- Whether a workshop can run that day. See the header: not derivable from
  -- `kind`, which is why it is stored and not computed.
  blocks_workshop boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint school_calendar_closures_range_check check (to_date >= from_date),
  constraint school_calendar_closures_kind_check check (kind in (
    'vacanta',          -- a school holiday
    'sarbatoare',       -- a public or religious holiday, no school
    'zi_pedagogica',    -- staff in, children out
    'zi_scurta',        -- school open, children leave early
    'inset',            -- teacher training, students off
    'inset_management', -- management training, students unaffected
    'alt'               -- anything else; the label carries it
  )),
  constraint school_calendar_closures_year_check check (school_year ~ '^\d{4}-\d{4}$')
);

create index school_calendar_closures_lookup
  on public.school_calendar_closures (client_id, from_date, to_date)
  where blocks_workshop;

comment on table public.school_calendar_closures is
  'Every marking on a school''s published calendar that is not an ordinary teaching day -- holidays, public holidays, pedagogical days, early-dismissal days, inset days -- one row per marking, per school, with the school''s own wording in `label` and the URL it was read from in `source_url`. PER SCHOOL WITH NO NATIONAL DEFAULT: the national school-year structure matches none of the three schools on any boundary (DATABASE_CONVENTIONS.md §18), so a school with no rows here makes schedule generation refuse rather than fall back. `blocks_workshop` is stored rather than derived from `kind` because an early-dismissal day is a day the school is OPEN and an afternoon workshop still cannot run, while a management inset day on a Saturday blocks nothing.';

comment on column public.school_calendar_closures.blocks_workshop is
  'Whether a workshop can run on these dates. Not a synonym for "school is shut": Avenor''s 30 June 2027 is an `Early Dismissal for Students - 12:00` -- the school is open, the children are gone by noon, and the 15:15 and 16:15 workshops cannot happen. Rows that do NOT block are recorded anyway, so that "checked and irrelevant" is distinguishable from "never looked".';

comment on column public.school_calendar_closures.label is
  'The school''s own wording, verbatim and untranslated. When somebody asks why there is no workshop on a given Wednesday, the answer should be the school''s sentence.';

alter table public.school_calendar_closures enable row level security;

-- Readable by anyone in the organization, including trainers. A trainer needs
-- to know when their school is shut more than almost anyone, and there is
-- nothing sensitive here: every row was copied from a public web page.
create policy "org members select school_calendar_closures"
  on public.school_calendar_closures
  for select to authenticated
  using (app.is_platform_owner() or app.belongs_to_org(organization_id));

grant select on public.school_calendar_closures to authenticated;

create trigger school_calendar_closures_set_updated_at
  before update on public.school_calendar_closures
  for each row execute function trigger_set_updated_at();

-- Calendars get corrected -- a school moves a day, we misread a colour -- and
-- "who changed this date and when" is exactly the question that will be asked
-- the first time a workshop lands wrong.
create trigger school_calendar_closures_row_history
  before delete or update on public.school_calendar_closures
  for each row execute function row_history_capture();

-- ---------------------------------------------------------------------------
-- The seed: 2026-2027, three schools, read 2026-10-20.
-- ---------------------------------------------------------------------------
do $$
declare
  v_org uuid;
  v_lyc uuid; v_ave uuid; v_ger uuid;
  v_n integer;
  v_lyc_url constant text := 'https://www.lyceefrancais.ro/pdf/calendrier/calendrier.pdf';
  v_ave_url constant text := 'https://www.avenor.ro/wp-content/uploads/2026/02/2026-2027-Avenor-School-Calendar.pdf';
  v_ger_url constant text := 'https://www.dsbu.ro/calendar-vacante/';
begin
  select id into v_org from public.organizations where slug = 'wow-lab';
  if v_org is null then raise exception 'closures: no organization with slug wow-lab'; end if;

  select id into v_lyc from public.clients where organization_id = v_org and name like 'Școala Franceză%';
  select id into v_ave from public.clients where organization_id = v_org and name = 'Scoala Avenor';
  select id into v_ger from public.clients where organization_id = v_org and name = 'Scoala Germana';
  if v_lyc is null or v_ave is null or v_ger is null then
    raise exception 'closures: missing one of the three schools';
  end if;

  -- ---- Lycee Francais Anna de Noailles ----
  insert into public.school_calendar_closures
    (organization_id, client_id, school_year, from_date, to_date, kind, label, source_url, blocks_workshop)
  select v_org, v_lyc, '2026-2027', x.a::date, x.b::date, x.k, x.l, v_lyc_url, x.blk
  from (values
    ('2026-09-01','2026-09-01','zi_pedagogica','Pré-rentrée',true),
    ('2026-10-19','2026-11-01','vacanta','Vacances de la Toussaint',true),
    ('2026-11-30','2026-11-30','sarbatoare','Saint Andrei',true),
    ('2026-12-01','2026-12-01','sarbatoare','Fete Nationale',true),
    ('2026-12-21','2027-01-03','vacanta','Vacances de Noël',true),
    ('2026-12-25','2026-12-25','sarbatoare','Noël',true),
    ('2027-01-01','2027-01-01','sarbatoare','Jour de l''an',true),
    ('2027-01-06','2027-01-06','sarbatoare','Epiphanie',true),
    ('2027-01-07','2027-01-07','sarbatoare','Ion Botezatorul',true),
    ('2027-01-24','2027-01-24','sarbatoare','Jour de l''unification',true),
    ('2027-02-22','2027-03-07','vacanta','Vacances d''hiver',true),
    ('2027-04-26','2027-05-09','vacanta','Vacances de printemps',true),
    ('2027-04-30','2027-04-30','sarbatoare','Vendredi de Pâques',true),
    ('2027-05-01','2027-05-01','sarbatoare','1er Mai',true),
    ('2027-05-02','2027-05-02','sarbatoare','Pâques',true),
    ('2027-05-03','2027-05-03','sarbatoare','Lundi de Pâques',true),
    ('2027-06-01','2027-06-01','sarbatoare','Jours des enfants',true),
    ('2027-06-21','2027-06-21','sarbatoare','Pentecôte',true),
    ('2027-07-05','2027-07-06','zi_pedagogica','Journées Pedagogiques sans accueil d''enfants à l''école',true),
    ('2027-07-07','2027-08-31','vacanta','Vacances d''été',true)
  ) x(a,b,k,l,blk);

  -- ---- Avenor College ----
  insert into public.school_calendar_closures
    (organization_id, client_id, school_year, from_date, to_date, kind, label, source_url, blocks_workshop)
  select v_org, v_ave, '2026-2027', x.a::date, x.b::date, x.k, x.l, v_ave_url, x.blk
  from (values
    ('2026-09-01','2026-09-01','alt','School Opening Ceremony',false),
    ('2026-10-19','2026-10-23','vacanta','Holidays',true),
    ('2026-11-14','2026-11-14','inset_management','Inset Days for Management',false),
    ('2026-11-30','2026-12-01','sarbatoare','Legal Holidays',true),
    ('2026-12-18','2026-12-18','zi_scurta','Early Dismissal for Students - 12:00',true),
    ('2026-12-21','2026-12-24','vacanta','Holidays',true),
    ('2026-12-25','2026-12-26','sarbatoare','Legal Holidays',true),
    ('2026-12-28','2026-12-31','vacanta','Holidays',true),
    ('2027-01-01','2027-01-02','sarbatoare','Legal Holidays',true),
    ('2027-01-04','2027-01-05','inset','Nursery Teachers Inset Day & Student Holiday',true),
    ('2027-01-06','2027-01-07','sarbatoare','Legal Holidays',true),
    ('2027-01-08','2027-01-08','inset','All Teachers Inset Day & Student Holiday',true),
    ('2027-01-24','2027-01-24','sarbatoare','Legal Holidays',true),
    ('2027-02-22','2027-02-26','vacanta','Holidays',true),
    ('2027-03-25','2027-03-25','inset','All Teachers Inset Day & Student Holiday',true),
    ('2027-03-26','2027-03-26','vacanta','Holidays',true),
    ('2027-04-17','2027-04-17','inset_management','Inset Days for Management',false),
    ('2027-04-26','2027-04-29','vacanta','Holidays',true),
    ('2027-04-30','2027-05-03','sarbatoare','Legal Holidays',true),
    ('2027-06-01','2027-06-01','sarbatoare','Legal Holidays',true),
    ('2027-06-20','2027-06-21','sarbatoare','Legal Holidays',true),
    ('2027-06-30','2027-06-30','zi_scurta','Early Dismissal for Students - 12:00',true),
    ('2027-07-01','2027-07-02','inset','Nursery Teachers Inset Day & Student Holiday',true),
    ('2027-07-05','2027-07-16','alt','Summer School',true),
    ('2027-07-19','2027-08-31','vacanta','Holidays',true)
  ) x(a,b,k,l,blk);

  -- ---- Deutsche Schule Bukarest ----
  insert into public.school_calendar_closures
    (organization_id, client_id, school_year, from_date, to_date, kind, label, source_url, blocks_workshop)
  select v_org, v_ger, '2026-2027', x.a::date, x.b::date, x.k, x.l, v_ger_url, true
  from (values
    ('2026-10-19','2026-10-23','vacanta','Herbstferien'),
    ('2026-11-30','2026-11-30','sarbatoare','Rumänischer Feiertag'),
    ('2026-12-01','2026-12-01','sarbatoare','Rumänischer Nationalfeiertag'),
    ('2026-12-21','2027-01-08','vacanta','Weihnachtsferien'),
    ('2027-01-06','2027-01-06','sarbatoare','Heilige drei Könige'),
    ('2027-01-07','2027-01-07','sarbatoare','Rumänischer Feiertag Heiliger Johannes'),
    ('2027-02-15','2027-02-19','vacanta','Winterferien'),
    ('2027-03-26','2027-03-29','sarbatoare','Katholische Ostern'),
    ('2027-04-26','2027-05-03','vacanta','Osterferien'),
    ('2027-05-31','2027-05-31','sarbatoare','Brückentag'),
    ('2027-06-01','2027-06-01','sarbatoare','Kindertag'),
    ('2027-06-21','2027-06-21','sarbatoare','Orthodoxer Pfingstmontag'),
    ('2027-07-01','2027-08-29','vacanta','Sommerferien')
  ) x(a,b,k,l);

  -- ---- Assertions ----
  select count(*) into v_n from public.school_calendar_closures where organization_id = v_org;
  if v_n <> 58 then
    raise exception 'closures: seeded % rows, expected 58 (20 Lycee + 25 Avenor + 13 Deutsche Schule)', v_n;
  end if;

  -- All three schools have rows -- §18's precondition for generating at all.
  if (select count(distinct client_id) from public.school_calendar_closures
      where organization_id = v_org and school_year = '2026-2027') <> 3 then
    raise exception 'closures: not all three schools have a 2026-2027 calendar';
  end if;

  -- THE TWO ROWS THIS TABLE EXISTS FOR: Avenor's early dismissals, both
  -- blocking, one of them on a Wednesday.
  if (select count(*) from public.school_calendar_closures
      where client_id = v_ave and kind = 'zi_scurta' and blocks_workshop) <> 2 then
    raise exception 'closures: Avenor should have exactly 2 blocking early-dismissal days';
  end if;
  if not exists (select 1 from public.school_calendar_closures
                 where client_id = v_ave and from_date = '2027-06-30'
                   and kind = 'zi_scurta' and blocks_workshop
                   and label = 'Early Dismissal for Students - 12:00') then
    raise exception 'closures: Avenor 30 June 2027 is not recorded as a blocking short day';
  end if;

  -- The non-blocking rows exist and are non-blocking, so that "looked and it
  -- does not matter" stays distinguishable from "never looked".
  if (select count(*) from public.school_calendar_closures
      where organization_id = v_org and not blocks_workshop) <> 3 then
    raise exception 'closures: expected 3 non-blocking rows (2 management insets + the opening ceremony)';
  end if;

  -- Autumn: the thing that started all of this. Three schools, three answers,
  -- none of them the national 24 October - 1 November.
  if not (exists (select 1 from public.school_calendar_closures
                  where client_id = v_lyc and from_date = '2026-10-19' and to_date = '2026-11-01')
      and exists (select 1 from public.school_calendar_closures
                  where client_id = v_ave and from_date = '2026-10-19' and to_date = '2026-10-23')
      and exists (select 1 from public.school_calendar_closures
                  where client_id = v_ger and from_date = '2026-10-19' and to_date = '2026-10-23')) then
    raise exception 'closures: the three autumn holidays are not as read from the three calendars';
  end if;

  -- Every row carries its school's source URL, because a date with no source
  -- is a date nobody can check.
  if exists (select 1 from public.school_calendar_closures
             where organization_id = v_org and coalesce(btrim(source_url), '') = '') then
    raise exception 'closures: a row has no source_url';
  end if;

  raise notice 'closures: 58 rows for 2026-2027 across 3 schools; Avenor carries 2 early-dismissal days, one of them a Wednesday';
end $$;
