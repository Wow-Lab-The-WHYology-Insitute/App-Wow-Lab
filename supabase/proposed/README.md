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

Also armed 2026-10-20, both within hours of being written (OPEN_ITEMS items
155 and 158):

- `cancel_19_21_october_school_holidays.sql` →
  `supabase/migrations/202610200005_...`
- `schedule_28_october_avenor_and_german.sql` →
  `supabase/migrations/202610200006_...`

Worth recording because it is the first time this directory did the job it
exists for rather than holding something back: both files were written,
reviewed, dry-run against the live database inside `begin; … rollback;`,
and only then applied — with the second one left as a separate file after
approval, because cancelling removes something known to be false while
inserting writes something forward on a published calendar alone.

Currently empty.
