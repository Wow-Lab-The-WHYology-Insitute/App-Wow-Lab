/**
 * test_rls_suite_lock.ts -- proves run_rls_suite.ts refuses a concurrent run.
 *   npx tsx scripts/test_rls_suite_lock.ts
 *
 * Case 1 runs the REAL runner while this process holds the real lock: it
 * must exit 2 naming this pid, before running any block (a refused run
 * never reaches the database, so this is safe against the live project).
 * Cases 2-4 drive the lock module on a throwaway path.
 */

import { spawnSync } from "child_process";
import { openSync, writeSync, closeSync, readFileSync, writeFileSync, existsSync, unlinkSync, mkdtempSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { acquireSuiteLock, suiteLockPath } from "./rls_suite_lock";

const results: { name: string; pass: boolean; detail: string }[] = [];
const check = (name: string, pass: boolean, detail = "") => results.push({ name, pass, detail });

function deadPid(): number {
  const child = spawnSync(process.execPath, ["-e", ""]);
  return child.pid!;
}

// Case 1 -- the real entry point, real lock path.
const realLock = suiteLockPath();
let fd: number;
try {
  fd = openSync(realLock, "wx");
} catch {
  console.error(`A real suite holds ${realLock} right now -- not touching it. Re-run this test when it finishes.`);
  process.exit(2);
}
writeSync(fd, `${process.pid}\n${new Date().toISOString()}\n`);
closeSync(fd);
try {
  const t0 = Date.now();
  const run = spawnSync("npx", ["tsx", "scripts/run_rls_suite.ts"], { encoding: "utf8", timeout: 120_000 });
  const elapsed = Date.now() - t0;
  check("second run exits with code 2", run.status === 2, `status=${run.status}`);
  check("refusal names the holder's pid", run.stderr.includes(`pid ${process.pid}`), run.stderr.trim());
  check("no test file was started", !/\.sql \(\d+ blocks?\)/.test(run.stdout), run.stdout.slice(0, 200));
  check("refused promptly, not after waiting", elapsed < 60_000, `${elapsed} ms`);
  check(
    "the holder's lock is untouched by the refused run",
    existsSync(realLock) && readFileSync(realLock, "utf8").startsWith(`${process.pid}\n`),
  );
} finally {
  if (existsSync(realLock) && readFileSync(realLock, "utf8").startsWith(`${process.pid}\n`)) unlinkSync(realLock);
}

const dir = mkdtempSync(join(tmpdir(), "rls-lock-test-"));
try {
  const p = join(dir, "suite.lock");

  // Case 2 -- a live holder (our parent shell) is refused, not reclaimed.
  writeFileSync(p, `${process.ppid}\n2026-01-01T00:00:00.000Z\n`);
  const live = acquireSuiteLock(p);
  check("a live holder is refused", !live.ok && live.holderPid === process.ppid);

  // Case 3 -- a dead holder (a crash / Ctrl-C) is reclaimed.
  const dead = deadPid();
  writeFileSync(p, `${dead}\n2026-01-01T00:00:00.000Z\n`);
  const reclaimed = acquireSuiteLock(p);
  check("a stale lock (dead pid) is reclaimed", reclaimed.ok && readFileSync(p, "utf8").startsWith(`${process.pid}\n`), `dead pid ${dead}`);

  // Case 4 -- release only removes a lock this process still owns.
  if (reclaimed.ok) {
    writeFileSync(p, `${process.ppid}\n2026-01-01T00:00:00.000Z\n`);
    reclaimed.release();
    check("release leaves someone else's lock alone", existsSync(p));
    writeFileSync(p, `${process.pid}\n2026-01-01T00:00:00.000Z\n`);
    reclaimed.release();
    check("release removes its own lock", !existsSync(p));
  }
} finally {
  rmSync(dir, { recursive: true, force: true });
}

for (const r of results) console.log(`  ${r.pass ? "PASS" : "FAIL"}  ${r.name}${r.pass ? "" : `  (${r.detail})`}`);
const failed = results.filter((r) => !r.pass).length;
console.log(`\n${results.length - failed} passed, ${failed} failed.`);
process.exit(failed > 0 ? 1 : 0);
