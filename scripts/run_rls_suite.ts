/**
 * run_rls_suite.ts — the one command that runs every db/tests/*.sql file
 * against the live linked database and prints pass/fail per assertion.
 *
 * Built 2026-09-22 (OPEN_ITEMS.md item 86/88) because the suite had no
 * runner at all before this -- every file's own header said "run
 * block-by-block in the SQL Editor," which is exactly why
 * rls_clients_contracts.sql (broken since 2026-08-18) and
 * rls_ws_d_write.sql (silently giving false-positive passes since
 * 2026-08-21, including on its own sabotage self-check) went unnoticed
 * for a month: nothing ever ran them, so nothing could fail loudly.
 *
 * What it does: for every db/tests/*.sql file, splits on the file's own
 * `begin;` / `rollback;` block convention (every block already rolls
 * back on its own -- this script never commits anything), runs each
 * block through `supabase db query --linked --file`, and parses the
 * result. A block can fail two different ways, both reported distinctly:
 *   - HARD ERROR: the block itself didn't run (a broken column
 *     reference, a missing fixture, a syntax error) -- this is what
 *     rls_clients_contracts.sql did for a month.
 *   - ASSERTION FAILURE: the block ran fine but returned one or more
 *     rows with pass = false.
 * Both count as a suite failure. Exit code is 1 if EITHER kind of
 * failure occurred anywhere, 0 only if every block ran AND every
 * assertion passed -- a broken suite cannot read as passing.
 *
 * Run after any migration that touches CREATE POLICY / DROP POLICY /
 * ALTER POLICY, or any migration that renames/drops a column a policy or
 * a test reads (that's what broke it twice already):
 *   npx tsx scripts/run_rls_suite.ts
 */

import { readFileSync, writeFileSync, mkdtempSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { execFileSync } from "child_process";

const TESTS_DIR = "db/tests";

type Row = { check_name?: string; pass?: boolean; actual?: unknown; expected?: unknown };
type BlockResult =
  | { kind: "error"; message: string }
  | { kind: "rows"; rows: Row[] };

function splitBlocks(sql: string): string[] {
  const lines = sql.split("\n");
  const blocks: string[] = [];
  let current: string[] | null = null;
  for (const line of lines) {
    if (/^begin;\s*$/.test(line)) {
      current = [line];
    } else if (current) {
      current.push(line);
      if (/^rollback;\s*$/.test(line)) {
        blocks.push(current.join("\n"));
        current = null;
      }
    }
  }
  return blocks;
}

function runBlock(blockSql: string, tmpDir: string, index: number): BlockResult {
  const path = join(tmpDir, `block_${index}.sql`);
  writeFileSync(path, blockSql);
  let stdout: string;
  try {
    stdout = execFileSync("npx", ["supabase", "db", "query", "--linked", "--file", path], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (err: unknown) {
    // Non-zero exit -- supabase CLI writes its JSON error to stdout, but
    // execFileSync throws with it on .stdout of the error object.
    const e = err as { stdout?: string; stderr?: string; message?: string };
    stdout = e.stdout ?? e.stderr ?? e.message ?? String(err);
  }
  const m = stdout.match(/\{[\s\S]*\}/);
  if (!m) {
    return { kind: "error", message: stdout.trim().slice(0, 500) };
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(m[0]);
  } catch {
    return { kind: "error", message: `Could not parse response JSON: ${stdout.trim().slice(0, 500)}` };
  }
  const obj = parsed as { rows?: Row[]; error?: { message?: string } };
  if (obj.error) {
    // A block that ends in `raise exception '%', report;` as its own
    // reporting convention surfaces here as a P0001 error whose message
    // IS the report -- extract embedded PASS/FAIL lines rather than
    // treating this as a hard failure.
    const msg = obj.error.message ?? "";
    const passFailLines = msg.match(/\d+[a-z]?\.\s*(PASS|FAIL)[^\n]*/g);
    if (passFailLines && passFailLines.length > 0) {
      const rows: Row[] = passFailLines.map((line) => ({
        check_name: line.replace(/^\d+[a-z]?\.\s*(PASS|FAIL)\s*-\s*/, ""),
        pass: /^\d+[a-z]?\.\s*PASS/.test(line),
      }));
      return { kind: "rows", rows };
    }
    return { kind: "error", message: msg.slice(0, 500) };
  }
  return { kind: "rows", rows: obj.rows ?? [] };
}

function main() {
  const { readdirSync } = require("fs") as typeof import("fs");
  const files = readdirSync(TESTS_DIR)
    .filter((f: string) => f.endsWith(".sql"))
    .sort();

  const tmpDir = mkdtempSync(join(tmpdir(), "rls-suite-"));
  let totalPass = 0;
  let totalFail = 0;
  let totalErrors = 0;
  const failures: string[] = [];

  try {
    for (const file of files) {
      const fullPath = join(TESTS_DIR, file);
      const sql = readFileSync(fullPath, "utf8");
      const blocks = splitBlocks(sql);
      console.log(`\n${file} (${blocks.length} block${blocks.length === 1 ? "" : "s"})`);

      blocks.forEach((block, i) => {
        const result = runBlock(block, tmpDir, i);
        if (result.kind === "error") {
          totalErrors++;
          const msg = `  block ${i + 1}: ERROR — ${result.message}`;
          console.log(msg);
          failures.push(`${file} block ${i + 1}: ERROR — ${result.message.split("\n")[0]}`);
          return;
        }
        if (result.rows.length === 0) {
          const msg = `  block ${i + 1}: ERROR — no rows returned (block produced no assertions)`;
          console.log(msg);
          totalErrors++;
          failures.push(`${file} block ${i + 1}: no rows returned`);
          return;
        }
        for (const row of result.rows) {
          const name = row.check_name ?? "(unnamed check)";
          // SABOTAGE checks deliberately break a policy and assert the
          // suite's OWN assertion then fails (pass: false in the raw
          // row) -- that's the suite having teeth, a runner-level PASS.
          // A sabotage row reading pass: true means the suite did NOT
          // notice the policy was broken -- exactly the rls_ws_d_write.sql
          // bug this runner exists to catch -- a runner-level FAIL.
          const isSabotage = name.startsWith("SABOTAGE");
          const suitePassed = isSabotage ? row.pass !== true : row.pass === true;
          if (suitePassed) {
            totalPass++;
            console.log(`  PASS  ${name}${isSabotage ? "  (correctly flipped to false under a broken policy)" : ""}`);
          } else {
            totalFail++;
            const detail = isSabotage
              ? `  (sabotage did NOT flip to false — this check has no teeth: actual=${JSON.stringify(row.actual)}, expected=${JSON.stringify(row.expected)})`
              : `  (actual=${JSON.stringify(row.actual)}, expected=${JSON.stringify(row.expected)})`;
            console.log(`  FAIL  ${name}${detail}`);
            failures.push(`${file}: ${name}`);
          }
        }
      });
    }
  } finally {
    rmSync(tmpDir, { recursive: true, force: true });
  }

  console.log(`\n${"=".repeat(70)}`);
  console.log(`${totalPass} passed, ${totalFail} failed, ${totalErrors} block error(s) across ${files.length} files.`);
  if (failures.length > 0) {
    console.log("\nFailures:");
    for (const f of failures) console.log(`  - ${f}`);
    console.log("\nSuite FAILED.");
    process.exit(1);
  }
  console.log("\nSuite PASSED.");
}

main();
