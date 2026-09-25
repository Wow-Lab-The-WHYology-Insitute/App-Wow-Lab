/**
 * Run by hand — not wired into CI (none exists in this repo). Same reason
 * scripts/check_operator_guide.ts exists: a claim in a document, checked
 * against something real, instead of trusted because it reads well.
 *
 * Checks docs/OPEN_ITEMS.md for three classes of mechanically-checkable
 * error. All three were tested against this file on 2026-09-18; check 1
 * found nine real errors on its first run, two of them in text written
 * the same day this script was written.
 *
 *   1. "item N above/below" pointing the wrong direction — N's own
 *      "### N." heading sits on the other side of the citing line from
 *      what the word claims. Natural-language list forms ("items 19, 39,
 *      and 45's corrections below", "item 35 above and item 48 below")
 *      are handled heuristically, not by a full parser — this can miss a
 *      malformed phrasing, but should not flag a correct one. Read the
 *      output; don't assume silence on a line means every reference on
 *      it was actually checked.
 *   2. "item N" citing a number with no "### N." heading anywhere in the
 *      file — a typo, or a reference to an item that was renumbered or
 *      never created.
 *   3. A migration/rollback filename (bare 12-14 digit prefix or full
 *      `..._name.sql`) cited in backticks with no matching file in
 *      supabase/migrations/ or supabase/rollbacks/. Reported as CONFIRM,
 *      not FAIL — a cited file can be legitimately gone on purpose (see
 *      KNOWN_DELIBERATELY_ABSENT_FILES below, a real case this file
 *      itself narrates: a rollback-drill migration, pushed for real then
 *      deleted to prove the rollback procedure works end to end). Add to
 *      that list only with a comment saying why, same discipline as
 *      everywhere else in this project that suppresses a real finding.
 *
 * Deliberately NOT checked: whether a RESOLVED item's cited commit hash
 * exists in git history. Tested by hand against this file's current 20
 * candidate hashes — all present, zero findings — and this project's own
 * discipline (new commits, never amend or rebase published history,
 * hashes pasted from real command output rather than typed) makes the
 * failure mode this would catch rare. The other three checks were judged
 * worth building at low cost for a plausible, sometimes-already-real
 * error; this one adds real implementation cost (shelling to git, telling
 * a hash apart from a migration timestamp, handling a shallow clone) for
 * a class of error this project's own habits mostly prevent. Not built.
 *
 * What none of this can check, and no script could without re-deriving
 * the investigation: whether a claim like "nobody can record X on any
 * layer" is still true. That kind of staleness — a blocker cleared by
 * adjacent, unrelated work that had no reason to know this register
 * existed — leaves the citing text perfectly well-formed. Nothing here
 * reads code semantics; it only checks whether this document is
 * internally consistent and whether the filenames/numbers it cites still
 * exist. See item 71 in the file this checks.
 *
 * Run:
 *   npx tsx scripts/check_open_items_register.ts
 */

import { readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..");
const REGISTER_PATH = path.join(REPO_ROOT, "docs/OPEN_ITEMS.md");

// Filenames known to be cited on purpose after being deliberately removed
// from disk. Confirmed against this specific entry before being added
// here, not assumed:
const KNOWN_DELIBERATELY_ABSENT_FILES = new Set<string>([
  // "Migration history was missing 3 applied migrations" — a throwaway
  // migration (202609010002, kept permanently) was rolled back through
  // WOWLAB_SAD_Field_Masking.md §6.2's own documented procedure, which
  // copies a rollback file to a new timestamp, pushes it, then removes
  // the copy once applied. 202609010003 is that copy — its absence from
  // supabase/migrations/ is the point of the entry, not a staleness bug.
  "202609010003",
]);

// A direction word ("above"/"below") counts as attached to a preceding
// "item N" only if it appears before a sentence boundary or the next
// "item"/"items" reference -- otherwise a direction meant for a later
// item in the same sentence would get misattributed backwards.
const STOP_PATTERN = /[.;]|(?:\bitems?\b)/i;
const DIRECTION_WINDOW = 70;

type Ref = { number: number; direction: "above" | "below" | null; line: number };

function findReferences(lines: string[]): Ref[] {
  const refs: Ref[] = [];

  lines.forEach((line, idx) => {
    const lineNo = idx + 1;

    // Plural list form: "items 19, 39, and 45's corrections below",
    // "items 21 and 40 above", "item 43/44 below" -- one or more numbers
    // joined by , / or "and", followed (allowing a short possessive/noun
    // phrase) by a single trailing direction shared by all of them.
    const listRe = /\bitems?\s+((?:\d+\s*(?:[,/]|\s+and\s+)\s*)+\d+)('s)?\b/gi;
    let lm: RegExpExecArray | null;
    while ((lm = listRe.exec(line))) {
      const numbers = (lm[1].match(/\d+/g) ?? []).map(Number);
      if (numbers.length < 2) continue; // single number -- handled below
      const after = line.slice(lm.index + lm[0].length, lm.index + lm[0].length + DIRECTION_WINDOW);
      const stopAt = after.search(STOP_PATTERN);
      const window = stopAt === -1 ? after : after.slice(0, stopAt);
      const dm = /\b(above|below)\b/i.exec(window);
      const direction = dm ? (dm[1].toLowerCase() as "above" | "below") : null;
      for (const n of numbers) refs.push({ number: n, direction, line: lineNo });
    }

    // Singular form, including each "item N" inside a repeated-keyword
    // list ("item 19, item 39, item 45 below"): find every standalone
    // "item N", look ahead up to the next item reference or sentence end
    // for the first direction word.
    const singleRe = /\bitem\s+(\d+)\b/gi;
    let sm: RegExpExecArray | null;
    while ((sm = singleRe.exec(line))) {
      const n = Number(sm[1]);
      const after = line.slice(sm.index + sm[0].length, sm.index + sm[0].length + DIRECTION_WINDOW);
      const stopAt = after.search(STOP_PATTERN);
      const window = stopAt === -1 ? after : after.slice(0, stopAt);
      const dm = /\b(above|below)\b/i.exec(window);
      const direction = dm ? (dm[1].toLowerCase() as "above" | "below") : null;
      refs.push({ number: n, direction, line: lineNo });
    }
  });

  return refs;
}

function checkDirectionsAndExistence(lines: string[], itemPos: Map<number, number>): number {
  let failures = 0;
  const refs = findReferences(lines);
  const seen = new Set<string>();

  for (const ref of refs) {
    const key = `${ref.line}:${ref.number}:${ref.direction ?? ""}`;
    if (seen.has(key)) continue; // the two passes above can both match the same reference
    seen.add(key);

    if (!itemPos.has(ref.number)) {
      console.error(`FAIL  line ${ref.line}: references item ${ref.number}, no "### ${ref.number}." heading exists anywhere in the file`);
      failures++;
      continue;
    }
    if (!ref.direction) continue; // a bare "item N" with no direction word attached -- nothing to check

    const targetLine = itemPos.get(ref.number)!;
    const actual = targetLine > ref.line ? "below" : targetLine < ref.line ? "above" : null;
    if (actual && actual !== ref.direction) {
      console.error(
        `FAIL  line ${ref.line}: "item ${ref.number} ${ref.direction}" but item ${ref.number}'s heading is at line ${targetLine}, which is ${actual}`,
      );
      failures++;
    }
  }
  return failures;
}

function checkMigrationCitations(text: string): number {
  const migDir = path.join(REPO_ROOT, "supabase/migrations");
  const rbDir = path.join(REPO_ROOT, "supabase/rollbacks");
  const allFiles = [...readdirSync(migDir), ...readdirSync(rbDir)];

  const cited = new Set<string>();
  for (const m of text.matchAll(/`(\d{12,14})(?:_[A-Za-z0-9_]+\.sql)?`/g)) {
    cited.add(m[1]);
  }

  let confirmCount = 0;
  for (const prefix of [...cited].sort()) {
    const hasFile = allFiles.some((f) => f.startsWith(prefix));
    if (hasFile) continue;
    if (KNOWN_DELIBERATELY_ABSENT_FILES.has(prefix)) {
      console.log(`ok    ${prefix} — absent on purpose (KNOWN_DELIBERATELY_ABSENT_FILES)`);
      continue;
    }
    console.error(
      `CONFIRM  ${prefix} is cited but no file in supabase/migrations/ or supabase/rollbacks/ starts with it -- verify this is a real gap, not a file deliberately removed after being cited, before treating it as stale`,
    );
    confirmCount++;
  }
  return confirmCount;
}

function main() {
  const text = readFileSync(REGISTER_PATH, "utf8");
  const lines = text.split("\n");

  const itemPos = new Map<number, number>();
  lines.forEach((line, idx) => {
    const m = /^### (\d+)\./.exec(line);
    if (m) {
      const n = Number(m[1]);
      if (!itemPos.has(n)) itemPos.set(n, idx + 1);
    }
  });
  console.log(`${itemPos.size} numbered items found.\n`);

  const directionFailures = checkDirectionsAndExistence(lines, itemPos);
  const migrationConfirms = checkMigrationCitations(text);

  console.log(`\n${directionFailures} direction/reference failure(s); ${migrationConfirms} migration filename(s) needing confirmation.`);
  if (directionFailures > 0) {
    process.exit(1);
  }
}

main();
