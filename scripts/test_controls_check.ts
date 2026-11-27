/**
 * test_controls_check.ts — §27, made executable (OPEN_ITEMS item 210,
 * Mihai 2026-11-27): "a probe without a control measures nothing".
 *
 * §27 caught four mistakes in its first day and nothing checked that it was
 * applied. This is that check. It runs inside run_rls_suite.ts on the rows
 * every block actually returned (not on a guess from the SQL text), and
 * fails the suite when a block asserts a refusal with no control beside it.
 *
 * A PROBE row asserts that something was refused or hidden: its `expected`
 * starts with refused / forbidden / not_permitted / denied / rejected, or
 * its check_name says so (PROBE_NAME below). A CONTROL row is one whose
 * check_name contains the word "control" -- the label the newer files lead
 * with and several older ones already use inside the name ("accepted --
 * control for the one above").
 *
 * A block with a probe passes if ANY of:
 *   - it has a control row of its own;
 *   - its header comment declares `§27 control: point N`, and the block
 *     headed "Point N" in the same file has a control row;
 *   - its header declares `§27 control: none -- <reason>`. Visible, never
 *     silent: the reason is printed on every run.
 * SABOTAGE blocks are exempt: they ARE the test's own control.
 *
 * What this cannot see, named: §27's other direction ("a pass on an empty
 * band is not a pass" -- the precondition that the probe COULD have been
 * refused) has no textual signature; a probe phrased without any refusal
 * word is not detected. Both stay habits.
 *
 * The files written before this check carry a BASELINE: the exact number of
 * probe blocks without a control, counted 2026-11-27. Exact, not a ceiling:
 * a new block without a control fails, and so does a repaired one until
 * its baseline is lowered -- so a fix cannot hide a new violation under the
 * old count.
 *
 * Its own test: npx tsx scripts/test_test_controls_check.ts (no database).
 */

export type CheckedRow = { check_name?: string; expected?: unknown };
export type CheckedBlock = { file: string; index: number; header: string; rows: CheckedRow[] };
export type Violation = { file: string; index: number; point: string | null; why: string; probes: string[] };
export type DeclaredNone = { file: string; index: number; point: string | null; reason: string };

const PROBE_EXPECTED = /^(refused|forbidden|not_permitted|denied|rejected)\b/i;
// The refusal word counts as a PREDICATE ("is refused", "is BLOCKED"), not
// anywhere: the first run flagged "(row count = 1, not blocked)" and "retracts
// the rejected row", neither of them a refusal (2026-11-27).
const PROBE_NAME =
  /\b(is|are|be|gets?|was) (REFUSED|refused|rejected|denied|forbidden|blocked|BLOCKED|REJECTED)\b|\bREFUSED\b|\bcannot\b|\bCANNOT\b|\bsees? (0|no|nothing|none)\b|\bnot visible\b|\binvisible\b/i;
const CONTROL_NAME = /\bcontrol\b/i;
const DECLARATION = /§27 control:\s*(?:point\s+(\d+[a-z]?)|none\s*[-—–]+\s*(.+))/i;
const POINT_LABEL = /\bpoint\s+(\d+[a-z]?)\s*[-—–]+/i;

// Counted 2026-11-27 on the first run of this check (item 210). Exact.
// Every file here predates §27 (2026-11-16). Many of these probes have a
// control in spirit (another row of the same block, another point) that is
// not labelled; each one fixed lowers its file's number here.
export const BASELINE: Record<string, number> = {
  "arc_duration_hazard.sql": 1,
  "calculate_session_pay.sql": 1,
  "cancel_session_pay_rule.sql": 2,
  "confirmation_future_guard.sql": 2,
  "custom_workshop_type.sql": 1,
  "duration_multiplier_rate_immutability.sql": 1,
  "grid_confirmed_pay_guard.sql": 6,
  "grid_correction.sql": 4,
  "lesson_plan_catalogue.sql": 3,
  "payroll_period_totals_rls.sql": 1,
  "rls_clients_contracts.sql": 3,
  "rls_groups_sessions.sql": 3,
  "rls_write_routing_functions.sql": 6,
  "rls_ws_d_write.sql": 3,
  "session_lesson_plans_one_to_many.sql": 1,
  "session_pay_approval.sql": 1,
  "supplier_contracts.sql": 1,
  "trainer_grade_rate_immutability.sql": 1,
  "vet_module.sql": 1,
};

const isSabotage = (r: CheckedRow) => (r.check_name ?? "").startsWith("SABOTAGE");
export const isProbe = (r: CheckedRow) =>
  !isSabotage(r) &&
  ((typeof r.expected === "string" && PROBE_EXPECTED.test(r.expected)) || PROBE_NAME.test(r.check_name ?? ""));
export const isControl = (r: CheckedRow) => !isSabotage(r) && CONTROL_NAME.test(r.check_name ?? "");

const pointOf = (header: string) => header.match(POINT_LABEL)?.[1]?.toLowerCase() ?? null;

export function checkControls(blocks: CheckedBlock[]): { violations: Violation[]; declaredNone: DeclaredNone[] } {
  const violations: Violation[] = [];
  const declaredNone: DeclaredNone[] = [];
  for (const b of blocks) {
    if (b.rows.some(isSabotage)) continue;
    const probes = b.rows.filter(isProbe).map((r) => r.check_name ?? "(unnamed)");
    if (probes.length === 0 || b.rows.some(isControl)) continue;
    const point = pointOf(b.header);
    const decl = b.header.match(DECLARATION);
    if (decl?.[2]) {
      declaredNone.push({ file: b.file, index: b.index, point, reason: decl[2].trim() });
      continue;
    }
    if (decl?.[1]) {
      const target = blocks.find((o) => o.file === b.file && pointOf(o.header) === decl[1].toLowerCase());
      if (target && target.rows.some(isControl)) continue;
      violations.push({
        file: b.file, index: b.index, point, probes,
        why: target ? `declares point ${decl[1]} as its control, and that block has no control row` : `declares point ${decl[1]} as its control, and no such point exists in the file`,
      });
      continue;
    }
    violations.push({ file: b.file, index: b.index, point, probes, why: "asserts a refusal with no control (none in the block, none declared)" });
  }
  return { violations, declaredNone };
}

/** Compare against the baseline. Returns the lines that fail the suite. */
export function againstBaseline(violations: Violation[], baseline: Record<string, number> = BASELINE): string[] {
  const byFile = new Map<string, number>();
  for (const v of violations) byFile.set(v.file, (byFile.get(v.file) ?? 0) + 1);
  const out: string[] = [];
  for (const file of new Set([...byFile.keys(), ...Object.keys(baseline)])) {
    const actual = byFile.get(file) ?? 0;
    const allowed = baseline[file] ?? 0;
    if (actual > allowed) out.push(`${file}: ${actual} probe block(s) without a control, baseline ${allowed} -- a new probe has no control`);
    if (actual < allowed) out.push(`${file}: ${actual} probe block(s) without a control, baseline ${allowed} -- lower the baseline to ${actual}`);
  }
  return out;
}
