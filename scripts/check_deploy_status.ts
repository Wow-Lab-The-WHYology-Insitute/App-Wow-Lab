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

function resolveSha(arg: string | undefined): string {
  if (arg) return arg;
  return execSync("git rev-parse HEAD", { encoding: "utf8" }).trim();
}

async function fetchStatus(sha: string): Promise<{
  state: string;
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
  const latest = data.statuses?.[0];
  return {
    state: data.state ?? "unknown",
    description: latest?.description ?? null,
    targetUrl: latest?.target_url ?? null,
  };
}

async function main() {
  const sha = resolveSha(process.argv[2]);
  console.log(`Checking deploy status for ${sha}...`);

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const { state, description, targetUrl } = await fetchStatus(sha);

    if (state === "pending") {
      console.log(`  [${attempt}/${MAX_ATTEMPTS}] pending...`);
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
