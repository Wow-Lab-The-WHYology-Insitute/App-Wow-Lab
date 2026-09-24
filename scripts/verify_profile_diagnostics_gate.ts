/**
 * ONE-TIME VERIFICATION (item 93). Confirms /profile on app.wowlab.ro, for
 * a real session (magic-link sign-in, not SQL impersonation):
 *  - a plain trainer (wow-lab-test-b) sees the new plain-language subtitle
 *    and NOT the technical details toggle/panel
 *  - the org owner (wow-lab-test-b, org.settings.manage via
 *    organization_owner) still sees the technical details toggle
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_profile_diagnostics_gate.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";

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

async function fetchProfileHtml(cookieHeader: string) {
  const res = await fetch(`${SITE_URL}/profile`, { headers: { Cookie: cookieHeader } });
  return { status: res.status, html: await res.text() };
}

async function main() {
  const a = admin();
  const report: string[] = [];

  // ---- Trainer fixture ----
  const trainerCookie = await signIn(a, "maxdigitalro+trainerb1@gmail.com");
  const trainerPage = await fetchProfileHtml(trainerCookie);
  const trainerHasPlainSubtitle = trainerPage.html.includes("Update your name, phone, or photo below");
  const trainerHasOldDiagnosticSubtitle = trainerPage.html.includes("Diagnostic view");
  const trainerHasTechnicalToggle = trainerPage.html.includes("Show technical details") || trainerPage.html.includes("Hide technical details");
  report.push(`Trainer (maxdigitalro+trainerb1@gmail.com): HTTP ${trainerPage.status}, plain subtitle present=${trainerHasPlainSubtitle}, old diagnostic subtitle present=${trainerHasOldDiagnosticSubtitle}, technical-details toggle present=${trainerHasTechnicalToggle} -> ${trainerHasPlainSubtitle && !trainerHasOldDiagnosticSubtitle && !trainerHasTechnicalToggle ? "PASS (plain profile page)" : "FAIL"}`);

  // ---- Owner fixture ----
  const ownerCookie = await signIn(a, "test+user-b@wowlab.dev");
  const ownerPage = await fetchProfileHtml(ownerCookie);
  const ownerHasPlainSubtitle = ownerPage.html.includes("Update your name, phone, or photo below");
  const ownerHasTechnicalToggle = ownerPage.html.includes("Show technical details") || ownerPage.html.includes("Hide technical details");
  report.push(`Owner (test+user-b@wowlab.dev): HTTP ${ownerPage.status}, plain subtitle present=${ownerHasPlainSubtitle}, technical-details toggle present=${ownerHasTechnicalToggle} -> ${ownerHasPlainSubtitle && ownerHasTechnicalToggle ? "PASS (still has diagnostics)" : "FAIL"}`);

  console.log("\n" + report.join("\n"));
  const anyFail = report.some((r) => r.includes("FAIL"));
  process.exit(anyFail ? 1 : 0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
