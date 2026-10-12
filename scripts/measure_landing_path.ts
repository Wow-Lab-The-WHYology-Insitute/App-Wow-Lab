/**
 * Times the post-sign-in landing resolution, end to end, against the real
 * deployment. Written for item 125's before/after pair; reusable for any later
 * change to app/auth/callback/route.ts or lib/landing.ts.
 *
 * WHAT IS TIMED: one GET of /auth/callback with a fresh magic-link token,
 * `redirect: "manual"` so the destination page's own render is NOT included --
 * the number is verifyOtp + whatever the callback does before it answers 307.
 *
 * Each token is single-use, so every sample needs its own generateLink. The
 * first sample per account is DISCARDED as the warm-up (cold function, cold
 * connection), then five are kept and the MEDIAN reported -- medians rather
 * than means because one slow sample on a shared platform otherwise moves the
 * answer more than the change being measured.
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/measure_landing_path.ts [label]
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

const SITE_URL = process.env.VERIFY_SITE_URL ?? "https://app.wowlab.ro";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const LABEL = process.argv[2] ?? "run";
const SAMPLES = 5;

const ACCOUNTS: [string, string][] = [
  ["trainer", "maxdigitalro+trainerb1@gmail.com"],
  ["owner", "test+user-b@wowlab.dev"],
  ["ops manager", "test+ui-ops-manager-b@wowlab.dev"],
];

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function oneCallback(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (error || !link) throw new Error(`generateLink failed for ${email}: ${error?.message}`);
  const url = `${SITE_URL}/auth/callback?token_hash=${link.properties!.hashed_token}&type=magiclink`;
  const t0 = performance.now();
  const res = await fetch(url, { redirect: "manual" });
  const ms = performance.now() - t0;
  return { ms, status: res.status, location: res.headers.get("location") ?? "" };
}

function median(xs: number[]) {
  const s = [...xs].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

async function main() {
  const a = admin();
  console.log(`\n=== landing path, ${LABEL} — ${SITE_URL} ===`);
  console.log(`warm-up discarded, median of ${SAMPLES}\n`);
  for (const [who, email] of ACCOUNTS) {
    await oneCallback(a, email); // warm-up, discarded
    const runs = [];
    let destination = "";
    for (let i = 0; i < SAMPLES; i++) {
      const r = await oneCallback(a, email);
      runs.push(r.ms);
      destination = r.location.replace(SITE_URL, "") || `HTTP ${r.status}`;
    }
    const ms = runs.map((r) => Math.round(r));
    console.log(
      `${who.padEnd(12)} median ${String(Math.round(median(runs))).padStart(5)} ms   ` +
      `[${ms.join(", ")}]   -> ${destination}`,
    );
  }
  console.log("");
}

main().catch((e) => { console.error(e); process.exit(1); });
