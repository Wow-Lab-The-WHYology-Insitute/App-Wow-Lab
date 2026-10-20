# supabase/proposed/

Migrations that are written, reviewed and **deliberately not applied**, waiting
on a decision rather than on effort.

They live here rather than in `supabase/migrations/` for a mechanical reason
found the hard way: `supabase db push` selects files by the leading timestamp
alone and ignores the rest of the filename, so a `..._PROPOSED_...` marker in
the name does **not** stop it — the file was listed as pending with the marker
in place. A separate directory is the only reliable guard.

To arm one: move it to `supabase/migrations/<timestamp>_<name>.sql` and its
rollback to `supabase/rollbacks/<same timestamp>_<name>_rollback.sql`.

Each file's own header says what decision it is waiting on, and
`docs/OPEN_ITEMS.md` carries the argument. The rule itself is
`docs/DATABASE_CONVENTIONS.md` §15 — including the general form: a marker the
tool does not read is not a marker.

Armed so far: `restate_trainer_grade_scale.sql`, on 2026-10-20 — now
`supabase/migrations/202610200001_restate_trainer_grade_scale.sql`.

Waiting, both from 2026-10-20 (OPEN_ITEMS item 155):

- `cancel_19_21_october_school_holidays.sql` — cancels the six workshops of
  19–21 October as `vacanta`. All three schools were on their autumn holiday;
  the week we protected was the wrong one.
- `schedule_28_october_avenor_and_german.sql` — inserts the four of Wednesday
  28 October that the same wrong reading withheld. Deliberately a **second**
  file: cancelling removes something known to be false, inserting writes
  something forward on a published calendar alone. Arm the cancellation
  first; this one asserts that it ran.
