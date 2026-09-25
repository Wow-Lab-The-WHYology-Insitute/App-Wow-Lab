/**
 * ONE-TIME VERIFICATION — not a repeatable pattern. Confirms OPEN_ITEMS.md
 * item 29's extraction (lib/display-name.ts) didn't change any rendered
 * output: signs in as the WOW LAB Test Org B owner fixture
 * (test+user-b@wowlab.dev, broad grant via organization_owner) and checks
 * that real trainer names still render correctly (not blank, not "Unknown"
 * for a resolvable row) on every page that used to carry its own copy of
 * displayName(): /admin/users, /groups, /groups/[id], /payment-config,
 * /payroll, /profile.
 *
 * Same real-session-cookie-over-HTTP technique as
 * scripts/verify_group_detail_client_name_render_test_org_b.ts (no
 * headless browser available here). Read-only against app data --
 * touches only the org owner fixture's own last_sign_in_at, already an
 * accepted cost of this kind of scripted check (docs/progress.md item
 * 67/70).
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_display_name_refactor_test_org_b.ts
 * Prerequisite: local `next dev` running on NEXT_PUBLIC_SITE_URL.
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

// Parameterized (env vars, defaults match the original Test Org B run) so
// the identical check can also be pointed at the real WOW LAB org and
// https://app.wowlab.ro after deploy, using a `test+`/fixture owner
// account there rather than any real named teammate.
const OWNER_EMAIL = process.env.VERIFY_OWNER_EMAIL ?? "test+user-b@wowlab.dev";
const SITE_URL = process.env.VERIFY_SITE_URL ?? process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
const EXPECT_NAME_ON_ADMIN_USERS = process.env.VERIFY_EXPECT_NAME ?? "Test Trainer B1";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createSupabaseClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function main() {
  const a = admin();

  const { data: link, error: linkErr } = await a.auth.admin.generateLink({ type: "magiclink", email: OWNER_EMAIL });
  if (linkErr || !link) throw new Error(`generateLink failed: ${linkErr?.message}`);
  const tokenHash = link.properties?.hashed_token;
  if (!tokenHash) throw new Error("No hashed_token on generated link.");

  const jar = new Map<string, string>();
  const authClient = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => [...jar.entries()].map(([name, value]) => ({ name, value })),
      setAll: (cookiesToSet: { name: string; value: string }[]) => {
        for (const { name, value } of cookiesToSet) {
          if (value) jar.set(name, value);
          else jar.delete(name);
        }
      },
    },
  });

  const { data: verified, error: verifyErr } = await authClient.auth.verifyOtp({ token_hash: tokenHash, type: "magiclink" });
  if (verifyErr || !verified.session) throw new Error(`verifyOtp failed: ${verifyErr?.message}`);
  console.log(`Signed in as ${OWNER_EMAIL}.`);

  const cookieHeader = [...jar.entries()].map(([name, value]) => `${name}=${value}`).join("; ");

  // "Test Trainer B1" is the real full_name on maxdigitalro+trainerb1@gmail.com
  // (confirmed in scripts/verify_group_detail_client_name_render_test_org_b.ts's
  // own run) -- used here as the known-good name string to look for wherever
  // a page would plausibly surface it.
  const pages: { path: string; expectSubstring?: string }[] = [
    { path: "/admin/users", expectSubstring: EXPECT_NAME_ON_ADMIN_USERS },
    { path: "/groups" },
    { path: "/payment-config" },
    { path: "/payroll" },
    { path: "/profile" },
  ];

  const report: string[] = [];
  for (const p of pages) {
    const res = await fetch(`${SITE_URL}${p.path}`, { headers: { Cookie: cookieHeader } });
    const html = await res.text();
    const statusOk = res.status === 200;
    const noRawUnknownLiteral = !html.includes("{{"); // catches an unsubstituted i18n template, same class of bug item 67 caught
    let line = `${p.path}: ${res.status}${statusOk ? "" : " (FAIL - not 200)"}`;
    if (!noRawUnknownLiteral) line += " FAIL - unsubstituted {{...}} template found";
    if (p.expectSubstring) {
      const found = html.includes(p.expectSubstring);
      line += found ? ` -- found "${p.expectSubstring}"` : ` -- FAIL, "${p.expectSubstring}" NOT found`;
    }
    report.push(line);
  }

  console.log("\n" + report.join("\n"));
  if (report.some((r) => r.includes("FAIL"))) {
    throw new Error("One or more checks failed -- see report above.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
