# Database Conventions

Canonical database conventions for WOW LAB OS, defined during Phase 0 WS-B (B1). Every
migration and every seed file must follow these. Any new table or trigger should be checked
against this list before it ships.

## 1. Identifiers

Every table has `id uuid primary key default gen_random_uuid()`. Foreign key columns are named
`<entity>_id` (e.g. `organization_id`, `role_id`, `user_id`), referencing the singular entity the
column points to.

## 2. Tenancy

Every business/operational table has `organization_id uuid not null references organizations(id)`.
This column is the RLS anchor: row-level security policies scope access by matching it against the
caller's organization context.

Exceptions:
- `organizations` itself (it is the tenant anchor, not a tenant of anything).
- Global reference tables that are not org-scoped: `roles`, `capabilities`, `role_capabilities`,
  and geo lookups.

## 3. Platform Owner

Platform Owner is cross-org via `users.is_platform_owner`. It is never forced into a single-org
assignment through `user_org_roles` — it is the RLS bypass condition, checked directly against the
`users` table rather than a per-org role grant.

## 4. Timestamps

Every table has `created_at` and `updated_at`, both `timestamptz not null default now()`.
`updated_at` is maintained by the shared `trigger_set_updated_at` `BEFORE UPDATE` trigger — every
table gets this trigger attached, not a bespoke one.

## 5. Naming

Snake_case throughout. Table names are plural (`organizations`, `role_capabilities`). Column names
are singular (`organization_id`, not `organization_ids`).

## 6. Roles & permissions are data, not enums

`roles`, `capabilities`, and `role_capabilities` are data tables, not hard-coded enums — this keeps
the permission model configurable and franchise-ready. Application code must never hard-code a role
name to gate a feature; it must resolve access through the capability map instead.

Wildcard capabilities (e.g. `curriculum.*`) are stored as a single literal row, not expanded into
an enumerated list of every fine-grained action. The capability resolver must prefix/glob-match a
requested capability against these wildcard rows (e.g. a check for `curriculum.lessons.update` is
satisfied by a granted `curriculum.*` row).

## 7. Row-Level Security

RLS is enabled and deny-by-default on every table at creation time. Permissive policies are added
per table in WS-D — a table is never shipped with RLS off, even temporarily, while waiting for its
policies.

## 8. Audit

Sensitive tables get the `row_history` trigger (`row_history_capture()`, `BEFORE UPDATE OR DELETE`).
Currently attached to: `client_contacts`, `clients`, `contracts`, `file_refs`, `groups`,
`legal_entities`, `org_settings`, `sessions`, `user_org_roles` (confirmed live via `pg_trigger`,
2026-08-26 — nine tables, not the four previously listed here; five were added and this line was
never updated). Attach it to any new table marked audited, and update this list when you do.

`audit_log` is append-only: UPDATE and DELETE are denied for everyone, including Platform Owner,
enforced by a dedicated trigger rather than by policy alone.

## 9. GDPR

Data resides in the EU (Frankfurt), including backups. The design intent is that personal data is
anonymized in place at 36 months — never hard-deleted. **This is a policy decision, not an
implemented mechanism.** Verified 2026-08-26: no retention/anonymization job exists anywhere in
this system — no DB function, no `pg_cron` (extension not installed), no Vercel cron, no Edge
Function. `docs/OPEN_ITEMS.md` has the full scope of what this leaves unenforced (`client_contacts`
PII, `row_history`/`audit_log` snapshots, and what the mockup implies for children's names and
rejected candidates, neither of which actually has stored data yet).

Until the automatic mechanism is built, `client_contacts` DELETE
(`supabase/migrations/202608270001_client_contacts_delete.sql`) is the only implemented erasure
route for personal data in this system — an on-demand path someone has to invoke, not a substitute
for the automatic one. That migration's own comment says the 36-month job "runs automatically";
it does not, and was never verified before that comment was written. The migration is already
applied and is not being edited to fix this — this section is the correction.

## 10. Migrations vs. seed

Schema changes live in ordered migration files under `supabase/migrations/`. Seed data lives
separately (`supabase/seed.sql`) and must be idempotent — re-running it must not create duplicates
or otherwise change the outcome of a prior run.

## 11. Seed fixtures cannot authenticate

Every `test+*@wowlab.dev` (and `maxdigitalro+*@gmail.com`) row inserted directly by
`supabase/seed.sql` exists in `public.users` but has no matching `auth.users` row. They were
built for SQL-level RLS impersonation (`SET ROLE authenticated` plus a spoofed
`request.jwt.claims`, as in `db/tests/*.sql`), not for signing in — none of them can
authenticate through the real app.

Mechanism: `handle_new_auth_user()` guards its insert with `on conflict (id) do nothing` — it
only protects against an `id` collision. A real Auth signup (invite, magic link) for one of
these emails generates a brand-new `auth.users.id`, different from the `id` `seed.sql` already
put in `public.users`. The guard never fires, and the insert then hits the `users_email_key`
unique constraint on `public.users.email` instead, failing with `23505`.

This is not a bug — these accounts serve RLS tests, not people. A real person needing browser
access gets a real invite, which creates its own matching `auth.users` row from scratch. If a
seed fixture ever genuinely needs to log in, the fix is `admin.auth.admin.createUser({ id:
<existing public.users.id>, email, email_confirm: true })` — passing the existing id turns the
trigger's own `on conflict (id) do nothing` into a no-op instead of a collision, leaving the
fixture's existing `user_org_roles` grants intact. Not something to run by default.

## 12. A status value that means "gone" replaces hard delete, not the other way round

If a table already has a status (or equivalent) value whose purpose is "this record is no
longer active, but keep it and its history" — `clients.status = 'churned'` is the concrete
case (see `docs/WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` §4, §8) — a hard-delete feature
for that table is not a smaller, more convenient version of the same idea. It is a second,
contradictory answer to a question the schema already settled: the status value exists
specifically so the row survives, and a delete path would let someone route around that on a
whim. Don't build one. This isn't a judgment call to revisit per-table without the underlying
question changing — it's closed until the actual product decision it rests on changes, not
until someone finds deleting more convenient.

This is a general principle, not just about clients — check whether a table already has a
"soft-gone" status before ever proposing hard delete for it.

## 13. Per-row calculations that can fail per row: one set-returning function, an amount **or** a reason_code

Any screen that computes a value per row and can fail per row gets **one set-returning function
that returns, for every row, either the value or a classified reason there isn't one** — never one
call per row, and never a single call that aborts because one row was unanswerable.

First built as `app.calculate_org_session_pay` (`202610150003`, range-scoped in `202610160001`) for
`/payroll`'s per-trainer pay. It is written down here because **nothing about it is specific to
pay**: pay per trainer slot, an invoice line per workshop, a client price per session, a margin per
contract — each computes per row from several lookups, each can be missing an input for one row and
fine for the next, and each is read by a screen where a wrong number is worse than no number.

**The shape.**

```
returns table (<row key...>, value numeric, reason_code text, error_text text)
```

- **One call per screen, not per row.** PostgREST has no way to ask for "the value, or the reason
  there isn't one" per row, so a per-row wrapper means N round trips *and* no isolation.
- **A raise aborts the statement**, so the catching has to happen inside plpgsql: a `begin ...
  exception when others then ... end` block around each row's computation, writing to variables, with
  `return next` *after* the block rather than inside it.
- **`value` is null exactly when `reason_code` is set.** Never zero for "could not compute" — on a
  money screen a zero is a wrong number that becomes a payment.
- **`error_text` is returned alongside, always.** An unmatched shape classifies as `'unknown'` and
  the screen prints the raw message: degraded and ugly, never silent. No failure may vanish by
  failing to match.
- **Classify inside the function, next to the raises**, not in the application. The alternatives are
  worse in both directions: re-asking each input question in SQL duplicates the computing function's
  own guards (and such mirrors drift — item 121's missed every pay-grid gap), while matching in
  TypeScript puts the match a repo away from the raise it matches.
- **Scope by range, not by "everything".** The caller passes the window it is about to display
  (`[p_from, p_to_exclusive)` — exclusive upper bound, so no caller does month-end arithmetic). An
  org-wide version is only correct while the org is empty; the cost of rendering one screen must not
  grow with the org's history. That means the window has to be a **server-side** fact — in the URL,
  not in client state.
- **`SECURITY INVOKER`**, unless the function has an authorization check of its own. These functions
  compose lookups over rate/config tables with their own RLS; `SECURITY DEFINER` would let any
  caller reconstruct those tables row by row from the values returned.
- **Refuse a nonsense window** (inverted or empty range) with a raise rather than returning zero
  rows. Zero rows is indistinguishable from "this window is genuinely empty", which on these screens
  is a statement about money.
- **Round per row, in `numeric`, if the screen shows a rounded figure** — and let totals be the sum
  of the rounded rows. Someone adds the displayed rows up by hand; the total has to agree with a
  calculator. Rounding in the application instead means the language's float representation decides
  the answer.

**The test that has to come with it.** A hand-written list of the failure shapes tests the shapes
someone already thought of. Derive them: read the producing functions' source out of `pg_proc`,
extract every `raise exception` literal and every classifier branch, and assert that **every raise
has a branch that matches it** and every branch is reachable — then sabotage it (add an
unclassified raise inside a rolled-back transaction) and assert the check flips to false.
`db/tests/payroll_reason_code_coverage.sql` is the worked example. Without this, a raise added six
months later becomes a silent `'unknown'` and every existing assertion still passes — which is
item 120's lesson, where a checker written with six anticipated forms missed the seventh added in
the same commit.

## 14. The schema records what happened; the grid decides what gets paid

**A constraint on an operational column must not enforce a pricing rule.** When the two disagree —
when something real happened that the pay configuration cannot price — the record of it is kept and
the *payment* is what fails, loudly and by name. Never the entry.

The worked case is `sessions.duration_minutes`. Its CHECK allows **15 to 480 minutes** while the pay
grid's top band is **120**. That 120–480 gap is a decision, not an oversight:

- A four-hour Școala Altfel day is a real thing that can happen. With a ceiling of 120 it would be
  **unenterable** — Operations would have to lie about the length, or not record the workshop at
  all, and the lie would then be the input to pay.
- With a ceiling of 480 it is **recorded truthfully and simply unpayable**:
  `app.resolve_duration_multiplier` raises above the top band,
  `app.calculate_org_session_pay` classifies that as `no_duration_row`, and `/payroll` shows it
  under *"Gaps in the pay grid — not fixable from this screen"*. Operations records what happened;
  Finance finds out it cannot be priced, and by whom it can be fixed.

**This is the same principle as "a raise does not take the month down" (§13), one layer lower.**
There, one unanswerable row must not cost the other rows their figures. Here, one unpriceable fact
must not cost the organisation its record of the fact. In both cases the failure is **named and
contained** rather than prevented by refusing the input.

**So: before tightening any CHECK on an operational column to match a configuration table, stop.**
The question is not "what values can we price?" but "what values can occur?" — and if the answer is
that something can occur which cannot be priced, that belongs in the resolver's raise and on the
screen, not in a constraint that makes the occurrence unrecordable. A CHECK on such a column is for
**impossible** values (a negative length, a typo of 1200), not for unprofitable or unconfigured
ones.

A side effect worth knowing, since it is how this gets caught: constraints that encode pay rules
also make the test suite unable to construct the unpayable case. `db/tests/payroll_org_session_pay.sql`
needs to insert a workshop above the top band in order to assert that one raise does not take the
month down; a CHECK clamped at 120 would have made that fixture uninsertable, and the test would
have had to be weakened to fit the constraint.

## 15. A migration awaiting a decision lives in `supabase/proposed/`, not in `supabase/migrations/`

A migration that is written and reviewed but **deliberately not applied** — waiting on a decision
rather than on effort — goes in `supabase/proposed/`, with its rollback beside it. It is armed by
moving it to `supabase/migrations/<timestamp>_<name>.sql` and its rollback to
`supabase/rollbacks/<same timestamp>_<name>_rollback.sql`.

**Why a directory and not a naming convention.** The first attempt named the file
`202610200001_PROPOSED_restate_trainer_grade_scale.sql` and left it in `supabase/migrations/`,
reasoning that `PROPOSED` in the name was warning enough. It was not: **`supabase db push` selects
files by the leading timestamp alone and ignores the rest of the filename.** Checked immediately
after writing it, the file was listed as *pending* — it would have been applied by the next
`db push` anyone ran, for any unrelated reason, with nobody deciding anything. Moving it out of the
directory made `pending` go back to `none`.

> **A marker the tool does not read is not a marker.** It is a comment addressed to whoever happens
> to look, on a path where the thing that acts is a command nobody is watching.

This generalises past migrations. Before relying on a filename, a prefix, a suffix or a comment to
hold something back, check what the tool that would act on it actually parses — and if the answer is
"not that", the guard has to be structural: a different directory, a different branch, a missing
file. Naming conventions are for humans reading; they stop nothing.

**What belongs in a proposed file.** The same quality as any migration — full header, guards,
rollback — plus, in the header, **the decision it is waiting on** and, where the proposal differs
from what was asked for, the argument for the difference. A proposed migration is how a
disagreement gets made concrete enough to settle: `restate_trainer_grade_scale.sql` was written
arguing against the instruction that prompted it, and the argument was accepted from reading the
file.

`docs/OPEN_ITEMS.md` carries the reasoning; `supabase/proposed/README.md` carries the mechanics.

## 16. The school year is 1 September – 31 August, labelled by its starting year

`2026-2027` runs from **2026-09-01** to **2027-08-31**. A date belongs to the school year whose
September it follows, so `2026-10-16` and `2027-06-30` are both in `2026-2027`.

**It is derived, never stored.** Any date yields its school year arithmetically, so there is no
column for it and no backfill to get wrong:

```sql
-- the starting year of the school year containing a date
case when extract(month from d) >= 9
     then extract(year from d)
     else extract(year from d) - 1
end
```

**The convention exists because the expensive failure is not storage, it is disagreement.** One
report grouping from September, another from August, a third from the first Monday of term, produce
three different answers to "how much did we bill this year" and no way to tell which is wrong.
Requirement rd. 65 (Laura) asked for a school-year dimension on every report; fixing the boundary
once is the whole of what that needs until something groups by it.

Where the boundary is used, it must be used as written: not "the academic year", not "the contract
period" (client contracts here run 1 September – 30 June, which is a *shorter* window inside the
school year and must not be confused with it), and not the calendar year.

## 17. A correct decision with a wrong reason written beside it

When a decision is recorded, the **reason** recorded with it is load-bearing, because the next
person to touch it will re-derive the decision from that reason — and a wrong reason justifies the
opposite change just as comfortably as the right one.

The worked case: `contract_type_uplift` is deliberately kept at zero rows, and the comment on
`app.resolve_contract_type_uplift` explains why — *"the PFA-inclusive rates in
trainer_grade_rates already have the 11.1% uplift baked in; calling this would double it."* **The
decision was right and the reason was wrong.** There was never an uplift inside those rates
(item 147): the 11% belonged to the client invoice and the instruction was to delete it. The table
should stay empty **because there is no uplift to apply**, not because it has already been applied.

Nothing was ever computed wrongly, which is exactly what makes this dangerous: a wrong reason
beside a correct decision produces **no failing test and no wrong number**. It sits there until
someone reasons from it — and the reason as written would have licensed seeding
`contract_type_uplift` the moment anyone concluded the rates were net.

**So at every revision, the reason is checked, not just the decision.** The question is not "is this
still the right call" but **"is this still the right call for the reason written here"**. The two
come apart silently, and only the first one has tests. Worth looking for deliberately — a decision
whose stated reason no longer holds is a trap with no tripwire.

### 17b. The second form: a correct decision with nothing to appeal to

The same failure has a mirror image, and it is easier to miss because there is no wrong sentence to
find. **A decision can also degrade by being made about something that does not exist yet**, so that
when the thing is built there is no "how it already was" for the decision to attach to.

The worked case is item 153: Finance Administration & Reporting is deliberately kept off five
screens. Two of those screens exist, and for them the decision has something concrete to defend —
the gate as written, with a comment saying why. **Three of them do not exist.** Whoever builds
Prezența copii, Stoc materiale or Comenzi will pick a gate from scratch, with no existing behaviour
to preserve and nothing to contradict. The decision covers them in intent and in nothing else.

**Both forms produce no failing test**, which is what makes them one convention rather than two:

| form | what is wrong | why nothing catches it |
|---|---|---|
| §17 | the decision is right, the **reason** beside it is wrong | no value changes; the reason is prose |
| §17b | the decision is right, there is **nothing it applies to yet** | the thing it governs has no code to test |

So a decision taken about unbuilt surface is recorded with **the surface named**, and the builder's
obligation is to **reopen the item rather than choose freshly** — because choosing freshly is
indistinguishable from the decision never having been made. Where the decision exists only as
intent, say so in it; an item that reads as though it governs five screens when it can only defend
two is itself a wrong reason of the §17 kind.

### 17c. The third form: correct code, changed world

**Decided 2026-10-22 by Mihai.** §17 and §17b are both about a decision outliving its
justification. The third form is about **code outliving the data it was written against**, and it
is the only one of the three with a guard rather than just a habit.

| form | what is wrong | why nothing catches it |
|---|---|---|
| §17 | the decision is right, the **reason** beside it is wrong | no value changes; the reason is prose |
| §17b | the decision is right, the **thing it governs has no code yet** | there is nothing to test |
| **§17c** | **the code is right, the world changed under it** | **it was true every time anyone checked** |

**The worked case.** `/my-work` showed *Hours this month* as the sum of `duration_minutes` over
every session dated in the current month. Correct, every single day, for as long as the schedule
stopped a week out — **because every session in the current month had already happened.** On
2026-10-20, `202610200009` generated 172 workshops to June 2027, and October's figure began
counting 28 October days before it ran. Nobody edited the query. Nobody edited the data model.
A different migration changed what the table contained.

Its neighbour went the same way: *Groups assigned* counted distinct groups across all the viewer's
sessions with no date bound, which was a sensible number while a trainer had one term of history
and is a number that only grows now.

> **Neither was wrong when it was written. Both became wrong when 172 rows landed.**

And the sort order on `/groups/[id]` is the same failure in a third place: `session_date DESC` put
the most recent workshop on top, which was right while the furthest row was seven days out and
buried tomorrow under thirty future cards the moment a year existed.

**THE GUARD, which §17 and §17b do not have:**

> **When the correctness of a query, a sort or a derived figure depends on a property of the
> DATA rather than of the query, write the property down beside it.**

*Hours this month* assumed **every session in the current month is in the past**. That assumption
was true every time anyone looked, and it was never written, so there was nothing for the
generation migration to contradict. Had the line read `// assumes the schedule does not extend
past today`, the person generating a year would have had something to hit.

**What the written property buys, concretely:** it is the only artefact that can be *falsified*.
A test asserts the output for data that exists; it passes happily when the data's shape changes
underneath it, because the fixture changed shape too. A written assumption is a claim about the
world, and claims about the world can be found to be false by reading.

**How to write it.** One sentence, in the comment on the derivation, naming the property and what
breaks without it — not "careful here". The three repaired in item 161 now read as bounded
expressions rather than assumptions (`hasHappened`, `schoolYearStart`, four explicit buckets),
which is better again: **an assumption that can be expressed as a filter should be the filter.**
Write the sentence where it cannot.

**What to do when you find one.** Nothing, necessarily. This form is found by **reading, not by
failing**, so the finding is a report and the repair is a separate decision — the same split
§20 asks for, and the reason the audit in `OPEN_ITEMS.md` item 162 is a list rather than a branch.
That audit found five more, every one of them correct today: a list ordered to show "the most
recent session" that now returns June 2027, a screen labelling the newest rate version "current"
while the pay engine resolves by date, two unbounded fetches against PostgREST's 1000-row ceiling,
and a numeric column sorted as text. It also found the one place that already writes its bound
down, which is what the habit looks like when it is kept.


## 18. No school gets dates without its own calendar — the national structure is not a default

**Decided 2026-10-20 by Mihai, after the national structure was wrong for all three schools we
have, on every boundary.**

| | autumn | winter | ski week | spring | last day |
|---|---|---|---|---|---|
| Lycée Français | 19 Oct – 1 Nov | 21 Dec – 3 Jan | 22 Feb – 7 Mar | 26 Apr – 9 May | 2 Jul |
| Deutsche Schule | 19 – 23 Oct | 21 Dec – 8 Jan | 15 – 19 Feb | 26 Apr – 3 May | 30 Jun |
| Avenor College | 19 – 23 Oct | 21 Dec – 8 Jan | 22 – 26 Feb | 26 Apr – 3 May | 30 Jun |
| **national structure** | *24 Oct – 1 Nov* | *23 Dec – 10 Jan* | *per county* | *24 Apr – 4 May* | *18 Jun* |

**Not one row of the national structure matches any school we have, on any boundary.** It is not a
default with overrides. **It is a fourth calendar that nothing uses.**

So:

> **A school gets dates only from its own calendar. If a school has no calendar loaded, the
> generator refuses — it does not fall back to the national structure.**

Refusing is the whole point. A fallback produces workshops that look exactly like correct ones:
right group, right trainer, right price, wrong week. A refusal produces nothing, and somebody goes
and gets the calendar. **The failure mode of the fallback is silent and the failure mode of the
refusal is loud**, and only one of those is survivable in a system whose output is somebody being
told to show up at a locked school.

**Why the earlier framing was wrong, and it was not a detail.** `OPEN_ITEMS.md` item 154 designed
this table as "the national structure as the default, with per-school overrides" and got the
*shape* right — per-school, a link that already knew schools differ. It then wrote a default
nobody had checked. Avenor's calendar was one link from its homepage; the sentence "Avenor — a
Romanian private school following the national structure" is an inference from *what kind of
institution Avenor is*, written in the grammar of an observation.

> **A default is a claim about a specific case and has to be checked case by case.** The moment
> anything is labelled "the exceptions", the exceptions get evidence and the default gets none —
> it is the thing that looks like it needs no source.

**The same substitution, twice, one layer apart.** The ski week has a clean version of this: the
county *is* derivable from `clients.address`, all three schools are Bucharest, and ISMB published
22–27 February 2027. But **the county answers which week the inspectorate chose, which is a
different question from which week this school is shut** — the Deutsche Schule takes 15–19
February and is not bound by ISMB at all. Deriving the first and storing it as the second is the
same move as deriving a school's holidays from its nationality. Both replace a measurement with a
category.

**And the measurement is only half done until it is turned on what is already written.** The
three-school table that proves this was produced and tabulated before the rows written three hours
earlier were re-read against it. The table said "Avenor 19–23 October" while six workshops sat in
the database on exactly those dates, and the two facts were not put next to each other. **A
correct measurement that is not turned back on the decisions already taken is half a
measurement** — the cost of the second half is one query, and the cost of skipping it is that the
measurement changes nothing.

**Lives in:** `OPEN_ITEMS.md` items 154, 155 and 158; `groups.school_year_calendar_link` (the
per-group column that anticipated this); `supabase/migrations/202610200005` and `202610200006`
(the repair).

## 19. The recorded actor is who did the thing, not who was allowed to do it

**Decided 2026-10-20 by Mihai, on the third instance of the same mistake in two days.**

Every `*_by` column — `cancelled_by`, `confirmed_by`, `actor_user_id` in `row_history` — answers
**"who did this"**. It never answers "who could have". A migration that has to impersonate somebody
in order to pass a gate is choosing a name for a row, and the only correct choice is the person who
actually took the decision.

> **A capability is permission to act. It is not evidence that anyone acted.**

**The three instances, which is why this is a convention and not an item.**

1. `202610200002` recorded Anca on 38 confirmations because *"this import is being run on her
   instruction"*. It was run on Mihai's. Corrected (item 152) to the real reason: **she had already
   approved those exact 38 rows in the timesheet**, which is a specific fact about her and about
   these rows.
2. `202610200005` recorded Cătălina on six cancellations because she holds `Operations Manager` and
   **the gate would admit her**. She had not been asked, had not decided, and had not answered. The
   argument offered — that `cancelled_by` records who exercised the authority — is the same
   substitution in a new coat: **she exercised nothing.** Corrected by `202610200007`.
3. The ski week, the same day, one layer out: the county answers *which week the inspectorate
   chose*, not *which week this school is shut* (§18).

All three replace **a specific fact about a specific person** with **a category that person belongs
to**. The category is always true and always irrelevant.

**The test, before writing any name into a `*_by` column:**

> Name one fact about **this person** and **these rows** that is true independently of their role.
> If the only sentence available is about their permissions, it is the wrong person.

Anca's fact: *she approved these 38 rows in the timesheet.* Mihai's fact on the cancellations: *he
read the three calendars, decided, and ran it.* Cătălina had no such fact. **Being the right person
to ask is not the same as having been asked.**

**Where this bites hardest.** A confirmation is irreducibly personal — the trainer asserting they
taught a class — and nobody may make one on another person's behalf under any role. A cancellation
is weaker: the fact can be public (a published school calendar), so it does not need testimony.
**But "does not need testimony" licenses nothing about whose name goes on it.** It only means the
fact survives without a witness; the actor column still records the person who acted, and that is
whoever decided.

**And if nobody suitable can pass the gate**, that is information, not an obstacle to route around
by borrowing a name. `202610200005`'s first draft tried to use an account with no roles at all; the
right response was to find the account that genuinely holds `Organization Owner` — not to reach for
someone whose role happened to fit.

**Lives in:** `OPEN_ITEMS.md` items 152, 157 and 159; §17 (the general form — a correct decision
with a wrong reason); `supabase/migrations/202610200007_correct_cancellation_actor.sql`.

## 20. A negative result is a result — record it, or "checked and irrelevant" becomes "never looked"

**Decided 2026-10-20 by Mihai, generalising from three rows in
`school_calendar_closures`.**

When an exhaustive search finds nothing — or finds something and establishes it does not
matter — **the finding is the absence, and the absence has to be written down somewhere a later
reader will hit.** Otherwise the next person re-runs the same search, or worse, assumes it was
never run and treats the gap as unexplored territory.

**The instance it came from.** `school_calendar_closures` holds 58 rows. Three of them have
`blocks_workshop = false`:

| | | |
|---|---|---|
| Avenor, 14 Nov 2026 | `Inset Days for Management` | a Saturday; management training does not shut the school |
| Avenor, 17 Apr 2027 | `Inset Days for Management` | same |
| Avenor, 1 Sep 2026 | `School Opening Ceremony` | a school day, not a closure |

Nothing in the generator reads them. They could have been left out and every number would be
identical. **They are in because leaving them out makes the table say something false** — not
"these days are fine", but *nothing at all*, which is the same shape the table takes for a marking
nobody noticed. A reader counting 55 rows cannot tell whether the management inset days were
examined and dismissed or missed entirely.

> **An empty result and an unasked question look the same from the outside.** The only thing that
> separates them is a record, and the record costs one row.

**Where this applies beyond calendars**, because it is not about calendars:

- **An exhaustive search that finds nothing.** `OPEN_ITEMS.md`'s closing section already does this
  — "every `docs/*.md` filename referenced anywhere was checked; all resolved" is a negative result
  recorded as a result, and its own correction note is what made the *scope* of that negative
  honest. A search for a table, a policy, a caller, a second write path: if the answer is "none",
  say so, say what was searched, and say what would have counted as a hit.
- **A hypothesis excluded by evidence.** Item 144 proved the location bonus is not
  trainer-dependent by finding the minority value *inside the same trainer at the same school*.
  The useful artefact is the exclusion, not the conclusion it supports.
- **A capability deliberately not granted, a branch deliberately not written.** Already the house
  style in migration headers (`finance.operations.*` is deliberately ABSENT, NO "own row" branch,
  decided rather than skipped) — this convention is that habit named, and extended from migration
  comments to data and to reports.

**The test:** if removing the record would leave a later reader unable to distinguish *"we looked
and it did not matter"* from *"nobody looked"*, keep the record. If the two are already
distinguishable by something else, it is noise.

**THE SAME CONVENTION ON A SECOND SURFACE: assertions.** 2026-10-26. `202610260001` asserted that
all five pay grids have a version in force, and the migration refused to apply. **The assertion
was wrong, not the code:** `contract_type_uplift` has zero versions deliberately — item 147, there
is no uplift to apply, so the grid is empty rather than seeded with zeros.

The obvious repair is to relax it to *"at least one grid is in force"*. That is the wrong repair,
and for exactly the reason the three non-blocking calendar rows exist:

> **A relaxed assertion and an assertion nobody wrote look identical from the outside.** Both pass.
> Neither says that somebody considered the fifth grid and concluded it should stay empty.

So it was tightened instead — **four in force, plus `contract_type_uplift` asserted null by name**,
with item 147 cited in the failure message. A deliberate absence stays a **claim the code makes**,
and the day anybody seeds that grid the migration fails and sends them to read why it was empty.

| surface | the negative result | what records it |
|---|---|---|
| **data** | Avenor's two management inset days block nothing | three rows with `blocks_workshop = false` |
| **assertions** | `contract_type_uplift` is empty on purpose | `<> 4` raises, naming item 147 |

Same convention, same failure mode, two places it has to be applied. **An assertion that is
loosened to accommodate a known exception stops recording that the exception is known.**

**And state the strength of the negative.** `school_calendar_closures`' header records that the
Deutsche Schule publishes an **event list** rather than a day grid, so its silence about short days
is weaker evidence than Avenor's white cells. An absence found by exhausting a grid and an absence
found by reading a list that might be incomplete are different facts, and a negative result that
does not say which is only half recorded.

**Lives in:** `public.school_calendar_closures` (the three non-blocking rows, and the table
comment); `db/tests/school_calendar_closures.sql` (which asserts they exist *and* that they do not
block); `OPEN_ITEMS.md` items 144 and 159; §18 and §19 (the two conventions this one most often
has to be applied alongside).

## 21. A control that triggers an assertion is labelled with the assertion, not the gesture

**Decided 2026-10-22 by Mihai, from a correction he did not ask for.** The request was a 44px tap
target on the confirmation control. Raising it from an 11px checkbox to a button exposed a second
problem that the checkbox had been hiding:

| | label | what it names |
|---|---|---|
| before | *Bifează pentru a confirma* — "Check to confirm" | **the gesture** |
| after | *Am ținut acest atelier* — "I taught this workshop" | **the assertion** |

A checkbox needs the gesture named, because "check" is genuinely ambiguous — tick it, tick it off,
is it a filter, is it a setting. A button's gesture is already obvious, so the words are free to
say what pressing it **means**. And here the meaning is the only thing that matters:

> **This timestamp is what pay follows.** A trainer tapping it is not performing an interface
> action, they are stating that they taught a class.

So:

> **Where a control writes something a person is answerable for — an assertion, an approval, a
> consent, a declaration — the label is the sentence they are signing, in the first person.** Not
> the gesture ("check", "tick", "click to…"), not the field name ("Confirmed"), not the system's
> word for the operation ("Submit", "Save").

**The test:** read the label aloud as the sentence the person is saying. *"I taught this
workshop"* works. *"Check to confirm"* is nobody saying anything. *"Confirmed"* is the system
describing a row.

**It applies to the neighbours too, and the neighbours are where it goes wrong.** The undo beside
it is `Retrage` — deliberately **not** `Anulează`, which already means "close this form" three
times on that page and would, one more time, mean *cancel the workshop*: a different act, a
different RPC, five categories behind it. **A word that already carries a meaning on the same
screen cannot be borrowed for a second one.**

**And the inverse — a control that asserts nothing keeps the gesture**, because there is nothing
else for it to say: `Show 27 more upcoming`, `Hide earlier workshops`. Those are navigation, and
naming them as declarations would be the same error pointed the other way.

**Where it does NOT apply:** Operations' correction checkbox on the same row stays a checkbox and
stays labelled `Confirmat`. It is a two-state field somebody sets **on another person's behalf**,
not an act they are answerable for — the first person would be a lie there, and §19's whole point
is that the row records who did the thing.

**Lives in:** `app/(app)/groups/i18n.ts` (`confirmation_confirm_button`, `confirmation_undo_button`,
`confirmation_not_yet`); `app/(app)/groups/[id]/group-detail-client.tsx` (`ConfirmationControl`);
`OPEN_ITEMS.md` item 161; §19 (whose name goes on the row the control writes).

## 22. A screen that labels something "current" asks the same function the engine asks

**Decided 2026-10-22 by Mihai; built 2026-10-26.** The general form of §17c's worst case, written
as its own rule because the repair is mechanical and the failure is not detectable from either
side.

> **A screen that shows a value from a versioned, effective-dated table resolves "which version"
> by calling the resolver the engine calls — not by taking the first row of a list it ordered
> itself.**

**Why re-deriving it in the screen is not a shortcut but a second truth.** `/payment-config`
labelled `versions[0]` — the newest `effective_date` that **exists** — as "current". Every pay
resolver takes the newest with **`effective_date <= the workshop's date`**: the version in force
**on that date**. Both queries are correct. They answer different questions. They return the same
row for as long as nothing is dated ahead, and then they silently stop.

> **A screen with its own notion of "the first one in the list" has its own truth, and two truths
> about the same number disagree without anything failing.**

**This was scheduled, not hypothetical.** `OPEN_ITEMS.md` item 147 is the instruction that
produces the row: *the 111-150 scale is seeded when a signed contract writes it, with that
contract's own start date.* A contract starting in January puts the row in the table in December.
From that moment the old screen would have read **150 at grade 6** while payroll correctly paid
**135** until January — and Anca would have hand-calculated on a figure the application was not
using. **We wrote the rule that brings that row**, which is the strongest form this problem takes:
not a risk, a date.

**The repair has three parts, and the middle one is the one that gets skipped.**

1. **There has to BE one function.** The selection was written out five times, identically, inside
   five plpgsql bodies. Adding a sixth copy for the screen would have been the same bug with
   better manners. `app.resolve_grid_version(org, grid, as_of)` is extracted first; the five
   resolvers call it.
2. **The screen reaches that same function**, through a thin `security invoker` wrapper
   (`public.current_grid_versions`) rather than a re-implementation in TypeScript. It adds an
   answer, never visibility.
3. **The screen gains a third state.** A version dated ahead is neither *current* (the engine is
   not using it) nor *history* (it has not been used). Before, there were two buckets and the
   future row was shoved into the first. Now it renders as **scheduled**, with its date —
   **because somebody deliberately entered it**, and a scheduled change that vanished from the
   screen would be the same failure pointed the other way.

**Where else this applies today:** anything with a `*_versions` table. The five pay grids are done.
The next one that appears inherits the rule rather than rediscovering it.

**The smell, stated so it is findable by reading:** `versions[0]`, `rows[0]`, `.slice(1)`,
`order by … limit 1` **written in application code** over a table whose rows are effective-dated.
Every one of those is a screen deciding for itself which row is the true one.

**Lives in:** `supabase/migrations/202610260001_one_resolver_for_which_version_is_in_force.sql`;
`app.resolve_grid_version`, `public.current_grid_versions`;
`app/(app)/payment-config/page.tsx` and `payment-config-client.tsx` (`ScheduledVersions`);
`db/tests/grid_version_in_force.sql`; §17c (the family this is the worst case of);
`OPEN_ITEMS.md` items 147 and 162.

## 23. `row_history.actor_user_id = NULL` is a documented state, not an absence

**Decided 2026-10-30 by Mihai, on the first real case — `202610300008`, item 152's correction.**

A NULL actor is indistinguishable, by looking at the column alone, from a NULL nobody meant to
write — the same shape §20 names for a missing row or a loosened assertion: **a deliberate absence
and an unasked question look identical from the outside, and only a record separates them.**

`app.current_user_id()` is `auth.uid()` (§19, `202608260001`), and it resolves to a clean NULL
whenever no `request.jwt.claims` is set — which is exactly the case for a migration that
impersonates nobody. **That NULL has exactly one correct meaning in this schema, and only one:**

> **A real person decided this action and is named in the migration that performed it. Nobody is
> named in `row_history` because naming anyone who could merely PASS the capability gate — rather
> than the person who actually decided — would be a second instance of the mistake §19 already
> named, committed in the act of correcting the first one.**

**This is not a new column, a new enum value, or a new convention for WHEN to leave it NULL** — §19
already says who goes in `*_by`/`actor_user_id` columns, and this is what follows when nobody
real can be named truthfully. What's missing until now is the record that a NULL here was
considered and chosen, not dropped. **The documentation lives beside the write, not in the
schema:**

- The migration that produces a NULL actor states, in its own header, that it is a system
  correction, on the owner's direct instruction, with no human actor by design — and gives the
  specific reason (`202610300008`'s own: the only two real accounts holding the gate's capability
  did not decide this; the decision-maker's own account holds no role at all).
- The migration's assertion block checks the NULL explicitly — `202610300008` fails if the
  newest `row_history` row carries a non-null `actor_user_id`, which would mean the migration was
  impersonated when it should not have been.
- `OPEN_ITEMS.md` records the same reasoning at the item, for a reader who finds the row before
  the migration file.

**The test, parallel to §20's:** if a later reader, finding `actor_user_id = NULL` on a row,
cannot tell *"this was a deliberate system correction, reasoned about and recorded"* from
*"whoever wrote this forgot to impersonate anyone,"* the record is incomplete. The migration that
writes the NULL is where that has to be settled — not a comment added later, not a value inferred
from context.

**Lives in:** `supabase/migrations/202610300008_clear_false_confirmation_scoala_germana_14oct.sql`
(the first real instance, and its own assertion checking the NULL by name);
`202608260001_fix_row_history_actor_user_id.sql` (why the NULL is clean rather than an error);
§19 (who goes in an actor column, and why borrowing a capable name is the same mistake twice);
§20 (the general form — a deliberate absence needs a record or it reads as an omission);
`OPEN_ITEMS.md` item 152 (the correction this convention was extracted from) and item 181 below
(a real, non-test, capability-holding account for Mihai existed and was not used — corrected same
day after being first written with the wrong premise; the NULL this convention documents stays
correct regardless of which account a future correction chooses to use instead).
