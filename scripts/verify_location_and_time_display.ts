/**
 * ONE-TIME VERIFICATION (item 98). Confirms live, as a trainer fixture,
 * that location_tier now shows (translated label or em dash) and the
 * time line always renders (range or em dash), on app.wowlab.ro in
 * wow-lab-test-b. Uses the two standing fixture sessions already in the
 * MAX group -- one has both fields set, the other has neither -- rather
 * than creating new fixtures, since that split already exists naturally.
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_location_and_time_display.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";
const GROUP_ID = "bda1f577-f381-4ced-a7f4-4d3399175e95";

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function signIn(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (error || !link) throw new Error(`generateLink failed for ${email}: ${error?.message}`);
  const jar = new Map<string, string>();
  const authClient = createServerClient(SUPABASE_URL, ANON_KEY, {
    cookies: {
      getAll: () => [...jar.entries()].map(([name, value]) => ({ name, value })),
      setAll: (cs: { name: string; value: string }[]) => {
        for (const { name, value } of cs) {
          if (value) jar.set(name, value);
          else jar.delete(name);
        }
      },
    },
  });
  const { error: verifyErr } = await authClient.auth.verifyOtp({ token_hash: link.properties!.hashed_token!, type: "magiclink" });
  if (verifyErr) throw new Error(`verifyOtp failed for ${email}: ${verifyErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}

async function main() {
  const a = admin();
  const b1Cookie = await signIn(a, "maxdigitalro+trainerb1@gmail.com");
  const res = await fetch(`${SITE_URL}/groups/${GROUP_ID}`, { headers: { Cookie: b1Cookie } });
  const html = await res.text();
  console.log(`HTTP ${res.status}\n`);

  // Isolate each session's own <tr> by its unique session_date text, then
  // check within that slice only -- the group has two sessions sharing
  // the same two trainer names, so a bare substring search on the name
  // would grab the wrong row (the mistake made and fixed earlier this
  // session, in scripts/verify_confirmation_control_through_app.ts).
  function rowFor(dateNeedle: string): string {
    const idx = html.indexOf(dateNeedle);
    if (idx === -1) return `NOT FOUND: "${dateNeedle}"`;
    const rowStart = html.lastIndexOf("<tr", idx);
    const rowEnd = html.indexOf("</tr>", idx);
    return html.slice(rowStart, rowEnd + 5);
  }

  // session_date values rendered via formatShortDate -- find the actual
  // formatted strings first by checking both plausible dates.
  const row30Sep = rowFor("Sep 30") !== 'NOT FOUND: "Sep 30"' ? rowFor("Sep 30") : rowFor("30 Sep");
  const row23Sep = rowFor("Sep 23") !== 'NOT FOUND: "Sep 23"' ? rowFor("Sep 23") : rowFor("23 Sep");

  console.log("--- Session with location_tier='imprejurimi', start_time='18:40:00' (2026-09-30 row) ---");
  console.log(row30Sep);
  console.log("\n--- Session with location_tier=NULL, start_time=NULL (2026-09-23 row) ---");
  console.log(row23Sep);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
