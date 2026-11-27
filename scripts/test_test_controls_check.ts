/**
 * test_test_controls_check.ts — the §27 check's own test, no database.
 * Each case is a fixture of blocks as run_rls_suite.ts hands them over.
 * The SABOTAGE case is the one that matters: a probe with no control must
 * be flagged, or the check has no teeth.
 *   npx tsx scripts/test_test_controls_check.ts
 */
import { checkControls, againstBaseline, type CheckedBlock } from "./test_controls_check";

let failed = 0;
function expect(name: string, cond: boolean) {
  console.log(`${cond ? "PASS" : "FAIL"}  ${name}`);
  if (!cond) failed++;
}
const block = (index: number, header: string, rows: { check_name: string; expected?: string }[]): CheckedBlock =>
  ({ file: "f.sql", index, header, rows });

// 1. SABOTAGE of the check: a probe alone is flagged.
{
  const r = checkControls([block(1, "-- Point 2 -- PROBE", [{ check_name: "deleting X is refused", expected: "refused P0W01" }])]);
  expect("a probe with no control is flagged", r.violations.length === 1);
}
// 2. A probe whose refusal is only in `expected` is still a probe.
{
  const r = checkControls([block(1, "", [{ check_name: "the write", expected: "forbidden" }])]);
  expect("a refusal carried only by expected is detected", r.violations.length === 1);
}
// 3. A control row in the same block satisfies it.
{
  const r = checkControls([block(1, "", [
    { check_name: "CONTROL: the same write on an empty parent is accepted", expected: "accepted" },
    { check_name: "the write is refused", expected: "refused P0W01" },
  ])]);
  expect("a control in the same block satisfies the probe", r.violations.length === 0);
}
// 4. A declared control point that exists and holds a control row.
{
  const r = checkControls([
    block(1, "-- Point 1 -- CONTROL", [{ check_name: "CONTROL: accepted", expected: "accepted" }]),
    block(2, "-- Point 2 -- PROBE\n-- §27 control: point 1", [{ check_name: "x is refused", expected: "refused" }]),
  ]);
  expect("a declared control point with a control row satisfies the probe", r.violations.length === 0);
}
// 5. A declared control point that does not exist is flagged.
{
  const r = checkControls([block(2, "-- Point 2 -- PROBE\n-- §27 control: point 9", [{ check_name: "x is refused" }])]);
  expect("a declaration pointing nowhere is flagged", r.violations.length === 1 && /no such point/.test(r.violations[0].why));
}
// 6. A declared point whose block has no control row is flagged.
{
  const r = checkControls([
    block(1, "-- Point 1 -- something", [{ check_name: "a count is 3" }]),
    block(2, "-- Point 2 -- PROBE\n-- §27 control: point 1", [{ check_name: "x is refused" }]),
  ]);
  expect("a declaration pointing at a block without a control row is flagged", r.violations.length === 1);
}
// 7. "none -- reason" passes and is reported, never silent.
{
  const r = checkControls([block(1, "-- §27 control: none -- the refusal is the grant itself, measured as such", [{ check_name: "x is refused" }])]);
  expect("a declared none passes and is listed with its reason", r.violations.length === 0 && r.declaredNone.length === 1);
}
// 8. SABOTAGE blocks are exempt.
{
  const r = checkControls([block(1, "", [{ check_name: "SABOTAGE: x is refused, same assertion", expected: "refused" }])]);
  expect("a SABOTAGE block is exempt", r.violations.length === 0);
}
// 9. A block with no probe is not judged.
{
  const r = checkControls([block(1, "", [{ check_name: "twelve rates seeded", expected: "12" }])]);
  expect("a block with no refusal is not judged", r.violations.length === 0);
}
// 9b. The two false positives of the first run are not probes; the predicate form is.
{
  const r = checkControls([
    block(1, "", [{ check_name: "catalina (ops): row still visible (row count = 1, not blocked)" }]),
    block(2, "", [{ check_name: "the trainer retracts the rejected row explicitly" }]),
    block(3, "", [{ check_name: "sales_a: INSERT contracts is BLOCKED" }]),
  ]);
  expect("'not blocked' and 'the rejected row' are not probes; 'is BLOCKED' is", r.violations.length === 1 && r.violations[0].index === 3);
}
// 10-12. The baseline is exact: growth fails, a repair fails until lowered, equality passes.
{
  const v = checkControls([block(1, "", [{ check_name: "x is refused" }])]).violations;
  expect("a violation over the baseline fails", againstBaseline(v, {}).length === 1);
  expect("a baseline above the real count fails (lower it)", againstBaseline([], { "f.sql": 1 }).length === 1);
  expect("a baseline equal to the real count passes", againstBaseline(v, { "f.sql": 1 }).length === 0);
}

console.log(failed === 0 ? "\nall passed" : `\n${failed} FAILED`);
process.exit(failed === 0 ? 0 : 1);
