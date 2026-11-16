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
 *   4. (2026-11-16, OPEN_ITEMS item 200) Items whose STATE has drifted from
 *      the work, in both directions. Informational: printed, never a
 *      failure, and meant to be read at the START of a session, not only
 *      after an edit.
 *        - DECIDED, NOT DONE: a decision with an action, nothing blocking
 *          it, and the action never happened. Item 149 sat 27 days like
 *          this; nothing read the register for it, because an item with no
 *          blocker never comes back up on its own.
 *        - DONE, NOT MARKED: the work exists in code, the register still
 *          reads open (160, 188). Costs no money; makes the register read
 *          more open than it is, which teaches people to skim it.
 *      Detection is a heuristic and is noisy on this file's history (27
 *      candidates on its first run, most of them notes or already-built
 *      items whose heading says "built" in lower case). So a candidate is
 *      TRIAGED ONCE, below, with a reason -- the same discipline as
 *      KNOWN_DELIBERATELY_ABSENT_FILES -- and a session sees: every tracked
 *      item still not marked done, and only the NEW untriaged candidates.
 *      An item leaves the tracked list when its own heading carries a done
 *      word; the script then says so, and the entry below is removed.
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

// Check 4's triage. Every candidate the heuristics below have ever raised
// is listed here exactly once. `fallen` and `unmarked` are reprinted on
// every run until the item's heading carries a done word; everything else
// is a reason the candidate is NOT drift, so it stops being reprinted.
type Triage =
  | { kind: "fallen"; why: string }
  | { kind: "unmarked"; why: string }
  | { kind: "not-drift"; why: string };

const TRIAGE: Record<number, Triage> = {
  // Decided, actionable, not done -- measured 2026-11-16 (item 200).
  5: { kind: "fallen", why: "audit_log.payload convention: 'nothing except doing it'; never written; event types went 5 -> 8" },
  21: { kind: "fallen", why: "remove users.status (decided 2026-09-02), deferred to the screen's next rework; 6 commits on that screen since, column untouched" },
  149: { kind: "fallen", why: "Alexandra Nutu's grade correction, 'Blocked on: nothing' from 2026-10-20; still 2 from 01.09 (date now needs Anca, item 197)" },
  153: { kind: "fallen", why: "'Anka has to be told the answer is NOT YET' -- an action on Mihai; no record anywhere that it happened" },
  // Done in code, still reads open.
  160: { kind: "unmarked", why: "/my-work has upcomingSessions (item 187 point 3)" },
  188: { kind: "unmarked", why: "the location/language 'next wave' was superseded by items 194/195" },
  // Raised by the heuristics, read, and not drift -- with the reason.
  45: { kind: "not-drift", why: "built; its heading says so in its own words" },
  53: { kind: "not-drift", why: "a citation, not a completion" },
  77: { kind: "not-drift", why: "built; heading says 'built' in lower case" },
  85: { kind: "not-drift", why: "built; heading says 'built' in lower case" },
  91: { kind: "not-drift", why: "'fixed same day' in its heading" },
  95: { kind: "not-drift", why: "seeded; done" },
  118: { kind: "not-drift", why: "a proposal with no decision taken -- open, not fallen" },
  119: { kind: "not-drift", why: "moved to fra1 and measured 2026-10-12; done, by its own heading's words" },
  122: { kind: "not-drift", why: "waits on a wording decision -- open, not fallen" },
  133: { kind: "not-drift", why: "built" },
  134: { kind: "not-drift", why: "cleaned by 202610130002" },
  135: { kind: "not-drift", why: "waits on a Skew Protection decision" },
  140: { kind: "not-drift", why: "waits on Anca (the 45-minute band)" },
  141: { kind: "not-drift", why: "a record, by its own words" },
  142: { kind: "not-drift", why: "open review work, no decision to have fallen" },
  143: { kind: "not-drift", why: "'nothing but a decision to do it' -- undecided" },
  144: { kind: "not-drift", why: "the model change waits on a decision" },
  147: { kind: "not-drift", why: "resolved (111-150, confirmed by Anca)" },
  150: { kind: "not-drift", why: "a rule; the rule is the deliverable" },
  152: { kind: "not-drift", why: "imported; done" },
  161: { kind: "not-drift", why: "a ranked list, nothing decided to build" },
  168: { kind: "not-drift", why: "a record" },
  174: { kind: "not-drift", why: "noted, deliberately not scoped" },
  175: { kind: "not-drift", why: "built" },
  177: { kind: "not-drift", why: "built" },
  186: { kind: "not-drift", why: "built" },
  189: { kind: "not-drift", why: "a record" },
  190: { kind: "not-drift", why: "a record" },
  192: { kind: "not-drift", why: "parked on purpose, named, unscheduled" },
  196: { kind: "not-drift", why: "decided, in flight (item 198 wave 1 first)" },
  200: { kind: "not-drift", why: "the check itself is built; the four it tracks are listed above under DECIDED, NOT DONE" },
};

const DONE_WORD = /\b(RESOLVED|CLOSED|BUILT|FIXED|APPLIED|DONE|PUSHED|WITHDRAWN|SUPERSEDED|DISCARDED|cut deliberately)\b/;

type ItemSpan = { heading: string; body: string; start: number; end: number };

function itemSpans(lines: string[], itemPos: Map<number, number>): Map<number, ItemSpan> {
  const starts = [...itemPos.entries()].sort((a, b) => a[1] - b[1]);
  const spans = new Map<number, ItemSpan>();
  starts.forEach(([n, line], k) => {
    const start = line - 1;
    let end = k + 1 < starts.length ? starts[k + 1][1] - 1 : lines.length;
    for (let j = start + 1; j < end; j++) {
      if (lines[j].startsWith("## ")) {
        end = j;
        break;
      }
    }
    spans.set(n, { heading: lines[start], body: lines.slice(start, end).join("\n"), start, end });
  });
  return spans;
}

// Candidate "decided, not done": the item's LAST "Blocked on:" says nothing
// blocks it, it does not describe itself as a note/record/rule, and its
// heading carries no done word.
function fallenCandidates(spans: Map<number, ItemSpan>): number[] {
  const out: number[] = [];
  for (const [n, s] of spans) {
    if (DONE_WORD.test(s.heading)) continue;
    const blocked = [...s.body.matchAll(/\*\*Blocked on:\*\*\s*(.+)/g)].map((m) => m[1]);
    const last = blocked.at(-1);
    if (!last || !/^(nothing|nimic|none)\b/i.test(last)) continue;
    if (/note, not work|this is a (note|report|rule|record|measurement)|nothing to fix|nothing to build|the record, not the work|closed|done|deployed|applied|built|resolved|confirmed\./i.test(last)) continue;
    out.push(n);
  }
  return out;
}

// Candidate "done, not marked": the item says of itself that something is
// not built / not fixed, says nothing later in its own body about that
// changing, and another line of the register cites it next to a done word.
function unmarkedCandidates(lines: string[], spans: Map<number, ItemSpan>): number[] {
  const selfOpen = /not built|NOT built|unbuilt|NOT fixed|[Nn]ot fixed|nothing below is built|nothing here is built|Read only/g;
  const laterDone = /\b(FIXED|BUILT|built|fixed|repaired|superseded|SUPERSEDED|closed by|CLOSED)\b/;
  const out: number[] = [];
  for (const [n, s] of spans) {
    if (DONE_WORD.test(s.heading)) continue;
    const hits = [...s.body.matchAll(selfOpen)];
    if (hits.length === 0) continue;
    const last = hits[hits.length - 1];
    if (laterDone.test(s.body.slice((last.index ?? 0) + last[0].length))) continue;
    const cite = new RegExp(`\\bitems? ${n}\\b`);
    const citedDone = lines.some((l, i) => {
      if (i >= s.start && i < s.end) return false;
      const m = cite.exec(l);
      if (!m) return false;
      return laterDone.test(l.slice(Math.max(0, m.index - 100), m.index + m[0].length + 100));
    });
    if (citedDone) out.push(n);
  }
  return out;
}

function reportDrift(lines: string[], itemPos: Map<number, number>): void {
  const spans = itemSpans(lines, itemPos);
  const short = (n: number) => (spans.get(n)?.heading ?? `### ${n}. (missing)`).replace(/^### /, "").slice(0, 90);

  console.log("\n--- item state drift (informational, check 4) ---");
  for (const [label, kind] of [
    ["DECIDED, NOT DONE", "fallen"],
    ["DONE IN CODE, NOT MARKED", "unmarked"],
  ] as const) {
    const tracked = Object.entries(TRIAGE).filter(([, t]) => t.kind === kind).map(([n, t]) => [Number(n), t.why] as const);
    console.log(`\n${label}:`);
    for (const [n, why] of tracked) {
      const s = spans.get(n);
      if (s && DONE_WORD.test(s.heading)) {
        console.log(`  now marked  ${n} -- its heading carries a done word; remove it from TRIAGE`);
      } else {
        console.log(`  ${String(n).padStart(4)}  ${short(n)}\n        ${why}`);
      }
    }
  }

  const fresh = [...new Set([...fallenCandidates(spans), ...unmarkedCandidates(lines, spans)])]
    .filter((n) => !(n in TRIAGE))
    .sort((a, b) => a - b);
  console.log(`\nNEW, UNTRIAGED candidates: ${fresh.length === 0 ? "none" : ""}`);
  for (const n of fresh) {
    console.log(`  ${String(n).padStart(4)}  ${short(n)}\n        read it; add it to TRIAGE as fallen / unmarked / not-drift, with the reason`);
  }
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
  reportDrift(lines, itemPos);

  console.log(`\n${directionFailures} direction/reference failure(s); ${migrationConfirms} migration filename(s) needing confirmation.`);
  if (directionFailures > 0) {
    process.exit(1);
  }
}

main();
