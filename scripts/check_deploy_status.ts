/**
 * check_deploy_status.ts — polls GitHub's commit-status API for the real
 * Vercel deployment outcome of a commit. `git push` succeeding only
 * confirms the git operation, never the build: main silently failed to
 * deploy for 25h8m (2026-09-23 08:34 UTC -> 2026-09-24 09:42 UTC, item
 * 94) because nothing checked this, and every push in that window
 * reported success on its own terms.
 *
 * Unauthenticated GET against a public repo -- no token, no Vercel CLI
 * link (not available in every environment this runs in; this endpoint
 * doesn't need it). Polls until the state is no longer "pending" (real
 * builds on this project have completed in under a minute every time
 * this was checked by hand); exits 0 only on "success", 1 on anything
 * else including a timeout still pending.
 *
 * TWO FAILURES WORE ONE NAME, fixed 2026-10-08 (OPEN_ITEMS item 108).
 * GitHub's combined `state` is "pending" BOTH when a build is genuinely
 * running AND when no status context has reported at all -- the second
 * being what happens if nothing was queued or the Vercel<->GitHub
 * integration stops posting. This script originally treated both as
 * "still building" and polled for the full five minutes before giving up,
 * which is how it behaved on 2026-10-08: thirty polls, `total_count` 0
 * throughout, while every commit through the previous day showed
 * `total_count` 1 and `success`. The integration had stopped reporting.
 *
 * That is item 94's own failure mode -- a deploy that never happened
 * reading as something other than failure -- reappearing INSIDE the
 * script written to catch item 94. `total_count` is the discriminator: a
 * real pending build has at least one context. Zero contexts now exits
 * non-zero after ~30s rather than ~5min.
 *
 * AND ZERO CONTEXTS HAS TWO CAUSES, which GitHub cannot distinguish and
 * this script now can. The endpoint answers 200 with `total_count: 0` for
 * a well-formed 40-char sha it has NEVER SEEN, exactly as it does for a
 * pushed commit nothing reported on. On 2026-10-08 the real cause turned
 * out to be the first: `main`'s remote tip was still the previous day's
 * commit and the two new commits were on no remote branch -- they had
 * never been pushed, so nothing was ever queued. The first diagnosis
 * written here ("the integration stopped posting") was wrong. So the zero-
 * context path now asks git whether the sha is on any remote branch, after
 * fetching, and says which of the two it is -- "never pushed, run git
 * push" versus "pushed, nothing reported, check the integration".
 *
 * Run by hand, same as check_open_items_register.ts and run_rls_suite.ts
 * -- no CI exists in this repo to run it automatically. Run it after any
 * push meant to reach app.wowlab.ro, before trusting any "verified on
 * app.wowlab.ro" claim made afterward:
 *
 *   npx tsx scripts/check_deploy_status.ts        # checks HEAD
 *   npx tsx scripts/check_deploy_status.ts <sha>   # checks a specific commit
 */
import { execSync } from "node:child_process";

const REPO = "Wow-Lab-The-WHYology-Insitute/App-Wow-Lab";
const POLL_INTERVAL_MS = 10_000;
const MAX_ATTEMPTS = 30; // ~5 minutes
// How long to allow for the FIRST status context to appear before declaring
// that none is coming. Not zero, deliberately: run within seconds of a push,
// Vercel legitimately has not posted yet, and failing on the first observation
// would cry wolf on every fast run. Three checks (~30s) is short enough that a
// genuinely absent integration is reported in half a minute instead of five.
const ZERO_CONTEXT_GRACE_ATTEMPTS = 3;

// Always resolve through git rev-parse, including an explicit argument.
// GitHub's commit-status endpoint 404s on an ABBREVIATED sha (verified
// 2026-10-08: /commits/311cddc/status -> 404, /commits/311cddc1a9d...e/status
// -> 200), and a 404 reads as "that commit does not exist" rather than "you
// pasted the short form from git log --oneline". Running everything through
// rev-parse also accepts a branch name or tag for free.
function resolveSha(arg: string | undefined): string {
  const rev = arg ?? "HEAD";
  try {
    return execSync(`git rev-parse ${rev}`, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    throw new Error(`not a revision this repo knows: ${rev}`);
  }
}

// Is this commit on ANY remote branch? Zero status contexts has two causes
// and they need completely different actions: the commit was never pushed, or
// it was pushed and nothing reported. Asked locally because GitHub's combined-
// status endpoint does NOT distinguish them -- it answers 200 with
// total_count 0 for a well-formed 40-char sha it has never seen, which is how
// a never-pushed commit masqueraded as a reporting failure on 2026-10-08
// (item 108). Fetches first, because a stale remote-tracking ref would answer
// from yesterday; tolerates being offline by saying so rather than guessing.
function remoteBranchesContaining(sha: string): { known: boolean; branches: string[] } {
  try {
    execSync("git fetch --quiet origin", { stdio: "ignore" });
  } catch {
    return { known: false, branches: [] };
  }
  try {
    const out = execSync(`git branch -r --contains ${sha}`, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const branches = out
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0 && !l.includes("->"));
    return { known: true, branches };
  } catch {
    // `--contains` exits non-zero when the object is missing locally.
    return { known: true, branches: [] };
  }
}

async function fetchStatus(sha: string): Promise<{
  state: string;
  totalCount: number;
  description: string | null;
  targetUrl: string | null;
}> {
  const res = await fetch(`https://api.github.com/repos/${REPO}/commits/${sha}/status`);
  if (!res.ok) {
    throw new Error(`GitHub API returned HTTP ${res.status} for commit ${sha}`);
  }
  const data = await res.json();
  // Vercel posts exactly one status context ("Vercel") on this repo --
  // data.state is GitHub's own combined state across all contexts, which
  // is exactly that one here. data.statuses[0] carries the per-context
  // description/target_url (the vercel inspect command on failure).
  //
  // total_count is the number of contexts that have reported AT ALL, and it
  // is the difference between "a build is running" and "nothing was ever
  // queued" -- see the header. GitHub reports state "pending" for both.
  const latest = data.statuses?.[0];
  return {
    state: data.state ?? "unknown",
    totalCount: data.total_count ?? (data.statuses?.length ?? 0),
    description: latest?.description ?? null,
    targetUrl: latest?.target_url ?? null,
  };
}

async function main() {
  const sha = resolveSha(process.argv[2]);
  console.log(`Checking deploy status for ${sha}...`);

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const { state, totalCount, description, targetUrl } = await fetchStatus(sha);

    // NO CONTEXT REPORTED AT ALL -- not a build in progress. GitHub returns
    // state "pending" with total_count 0 when nothing has posted a status,
    // which is a permanent condition this script used to spend five minutes
    // waiting out. A real pending build has at least one context.
    if (totalCount === 0) {
      if (attempt <= ZERO_CONTEXT_GRACE_ATTEMPTS) {
        console.log(
          `  [${attempt}/${ZERO_CONTEXT_GRACE_ATTEMPTS}] no context has reported yet; allowing for the first status to post...`,
        );
        await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
        continue;
      }
      // Zero contexts, so this is NOT a build in progress. Which of the two
      // causes it is can be settled locally, and they need different actions.
      const { known, branches } = remoteBranchesContaining(sha);
      if (known && branches.length === 0) {
        console.error(
          `commit is NOT on the remote -- it was never pushed.\n` +
            `  ${sha} is on no remote branch, so nothing was ever queued to build and no status ` +
            `will ever appear. GitHub answers 200 with total_count 0 for a sha it has never seen, ` +
            `which is why this looks identical to a reporting failure.\n` +
            `  Run: git push origin <branch>   then re-run this.\n` +
            `  Treat as NOT deployed.`,
        );
      } else if (known) {
        console.error(
          `no deployment reported -- check the Vercel integration.\n` +
            `  ${sha} IS on the remote (${branches.join(", ")}) but GitHub has ZERO status contexts ` +
            `for it after ${ZERO_CONTEXT_GRACE_ATTEMPTS} checks -- so it was pushed and nothing reported, ` +
            `which is a permanent condition, not a build in progress.\n` +
            `  Compare a known-good commit: ` +
            `https://api.github.com/repos/${REPO}/commits/<older-full-sha>/status should show total_count 1.\n` +
            `  Treat as NOT deployed.`,
        );
      } else {
        console.error(
          `no status context for ${sha}, and could not reach the remote to tell why.\n` +
            `  Either it was never pushed or nothing reported -- re-run with network access to ` +
            `distinguish them.\n  Treat as NOT deployed.`,
        );
      }
      process.exit(1);
    }

    if (state === "pending") {
      console.log(`  [${attempt}/${MAX_ATTEMPTS}] pending (${totalCount} context reporting)...`);
      if (attempt === MAX_ATTEMPTS) {
        console.error(
          `Still pending after ${MAX_ATTEMPTS} checks (~${(MAX_ATTEMPTS * POLL_INTERVAL_MS) / 60000} min) -- not confirmed, treat as not deployed.`,
        );
        process.exit(1);
      }
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
      continue;
    }

    if (state === "success") {
      console.log(`success -- ${description ?? "Deployment has completed"}`);
      process.exit(0);
    }

    console.error(`${state} -- ${description ?? "no description"}${targetUrl ? `\n  ${targetUrl}` : ""}`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
