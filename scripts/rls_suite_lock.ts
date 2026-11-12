/**
 * rls_suite_lock.ts -- refuses a second concurrent run_rls_suite.ts against
 * the same linked project, immediately and loudly, instead of waiting.
 *
 * Why refuse rather than wait: the failure this prevents is not "the suite
 * takes longer," it is "RLS tests fail to connect, and green stops meaning
 * what it looks like" (2026-11-10: two concurrent runs, two isolation tests
 * -- rls_users.sql, rls_ws_d_read.sql -- errored on "failed to connect as
 * temp role"). On a multi-tenant app with money in it, an isolation test
 * that sometimes doesn't run is worse than one that's missing: the missing
 * one is visible. A waiting run looks hung and gets killed; a refused one
 * says why in one line.
 *
 * Atomic create (`wx`) is the lock. A lock whose pid is no longer alive is
 * stale (Ctrl-C kills node without running exit handlers -- deliberately no
 * SIGINT handler, since main() is synchronous and a handler would keep the
 * suite running past Ctrl-C) and is reclaimed exactly once.
 */

import { openSync, writeSync, closeSync, readFileSync, unlinkSync, existsSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

export type LockResult =
  | { ok: true; release: () => void }
  | { ok: false; holderPid: number | null; holderStartedAt: string | null; lockPath: string };

export function suiteLockPath(): string {
  const refFile = join("supabase", ".temp", "project-ref");
  const ref = existsSync(refFile) ? readFileSync(refFile, "utf8").trim() : "unlinked";
  return join(tmpdir(), `wowlab-rls-suite-${ref}.lock`);
}

function pidAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch (err) {
    // EPERM: the process exists but belongs to someone else -- still alive.
    return (err as NodeJS.ErrnoException).code === "EPERM";
  }
}

function readHolder(lockPath: string): { pid: number | null; startedAt: string | null } {
  try {
    const [pidLine, startedAt] = readFileSync(lockPath, "utf8").split("\n");
    const pid = Number.parseInt(pidLine, 10);
    return { pid: Number.isFinite(pid) ? pid : null, startedAt: startedAt?.trim() || null };
  } catch {
    return { pid: null, startedAt: null };
  }
}

function tryCreate(lockPath: string): boolean {
  try {
    const fd = openSync(lockPath, "wx");
    writeSync(fd, `${process.pid}\n${new Date().toISOString()}\n`);
    closeSync(fd);
    return true;
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === "EEXIST") return false;
    throw err;
  }
}

export function acquireSuiteLock(lockPath: string = suiteLockPath()): LockResult {
  for (let attempt = 0; attempt < 2; attempt++) {
    if (tryCreate(lockPath)) {
      const release = () => {
        if (readHolder(lockPath).pid === process.pid) {
          try {
            unlinkSync(lockPath);
          } catch {
            // already gone
          }
        }
      };
      process.on("exit", release);
      return { ok: true, release };
    }
    const holder = readHolder(lockPath);
    // An unreadable/half-written pid is treated as live: refusing a run
    // wrongly costs one re-run; reclaiming a live lock wrongly is the bug.
    if (holder.pid === null || pidAlive(holder.pid)) {
      return { ok: false, holderPid: holder.pid, holderStartedAt: holder.startedAt, lockPath };
    }
    if (attempt === 0) {
      try {
        unlinkSync(lockPath);
      } catch {
        // someone else reclaimed it first; the retry's wx decides
      }
    }
  }
  const holder = readHolder(lockPath);
  return { ok: false, holderPid: holder.pid, holderStartedAt: holder.startedAt, lockPath };
}
