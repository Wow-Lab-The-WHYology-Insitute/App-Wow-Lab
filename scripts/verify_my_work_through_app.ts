/**
 * ONE-TIME VERIFICATION (item 101). Fetches /my-work from the deployed
 * app as two real trainer sessions in wow-lab-test-b:
 *   - Test Trainer B1, set up with one confirmed and one unconfirmed
 *     session, so both the count and the unconfirmed warning have
 *     something real to say
 *   - Test Trainer B3, who has a grade but no allocations at all, so the
 *     empty state is exercised for real rather than reasoned about
 *
 * B1's second session is un-confirmed at the start and restored at the
 * end -- the standing fixtures are left exactly as they were found.
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_my_work_through_app.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
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
  const { error: verifyErr } = await authClient.auth.verifyOtp({
    token_hash: link.properties!.hashed_token!,
    type: "magiclink",
  });
  if (verifyErr) throw new Error(`verifyOtp failed for ${email}: ${verifyErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}

// Strips tags AND decodes entities, so an assertion tests the text a
// person reads. Without the decode, "aren't" renders as "aren&#x27;t"
// and a regex containing an apostrophe silently fails to match -- which
// it did on the first run here, reporting a missing warning that was
// present, and passing the mirror-image check on the other fixture for
// the same wrong reason.
function visibleText(html: string): string {
  const body = html.replace(/<script[\s\S]*?<\/script>/g, "");
  return body
    .replace(/<[^>]+>/g, " ")
    .replace(/&#x27;|&#39;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, "&")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ");
}

async function main() {
  const a = admin();
  const report: string[] = [];
  let restore: (() => Promise<void>) | null = null;

  try {
    const { data: b1 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();

    // Make B1's picture interesting: leave the earlier session confirmed,
    // un-confirm the later one so the warning has a real subject.
    const { data: b1Sessions } = await a
      .from("sessions")
      .select("id, session_date, trainer_principal_confirmed_at")
      .eq("trainer_principal_id", b1!.id)
      .order("session_date", { ascending: true });

    const target = (b1Sessions ?? [])[0];
    if (!target) throw new Error("B1 has no sessions to work with");
    const originalConfirmedAt = target.trainer_principal_confirmed_at;
    await a.from("sessions").update({ trainer_principal_confirmed_at: null }).eq("id", target.id);
    restore = async () => {
      await a.from("sessions").update({ trainer_principal_confirmed_at: originalConfirmedAt }).eq("id", target.id);
    };

    // ---- B1: one confirmed, one unconfirmed ----
    const b1Cookie = await signIn(a, "maxdigitalro+trainerb1@gmail.com");
    const b1Res = await fetch(`${SITE_URL}/my-work`, { headers: { Cookie: b1Cookie } });
    const b1Text = visibleText(await b1Res.text());
    report.push(`B1 HTTP ${b1Res.status}`);
    report.push(`  unconfirmed warning present: ${/aren't confirmed yet|not confirmed/i.test(b1Text)}`);
    report.push(`  names the month + open state: ${/is still open/i.test(b1Text)}`);
    report.push(`  hours caveat present ("not your pay"): ${/not your pay/i.test(b1Text)}`);
    report.push(`  grade shown (B1 is grade 1 = Junior): ${/Junior/.test(b1Text)}`);
    report.push(`  did NOT fall back to the empty state: ${!/no sessions allocated yet/i.test(b1Text)}`);
    const b1Excerpt = b1Text.match(/My work[\s\S]{0,420}/);
    report.push(`  --- what B1 reads ---\n  ${b1Excerpt ? b1Excerpt[0].trim() : "(not found)"}`);

    // ---- B3: a grade, no allocations ----
    const b3Cookie = await signIn(a, "maxdigitalro+trainerb3@gmail.com");
    const b3Res = await fetch(`${SITE_URL}/my-work`, { headers: { Cookie: b3Cookie } });
    const b3Text = visibleText(await b3Res.text());
    report.push(`\nB3 HTTP ${b3Res.status}`);
    report.push(`  shows the one-line empty state: ${/no sessions allocated yet/i.test(b3Text)}`);
    report.push(`  shows NO zero-figure grid: ${!/Sessions confirmed this month/i.test(b3Text)}`);
    report.push(`  still shows grade (B3 is grade 3): ${/Enthusiastic Mid 1/.test(b3Text)}`);
    report.push(`  no unconfirmed warning: ${!/aren't confirmed yet/i.test(b3Text)}`);
    const b3Excerpt = b3Text.match(/My work[\s\S]{0,320}/);
    report.push(`  --- what B3 reads ---\n  ${b3Excerpt ? b3Excerpt[0].trim() : "(not found)"}`);

    console.log("\n" + report.join("\n"));
    console.log(
      report.some((r) => r.includes(": false")) ? "\nAt least one expectation failed." : "\nAll expectations held.",
    );
  } finally {
    if (restore) {
      await restore();
      console.log("\nB1's confirmation restored to its original value.");
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
