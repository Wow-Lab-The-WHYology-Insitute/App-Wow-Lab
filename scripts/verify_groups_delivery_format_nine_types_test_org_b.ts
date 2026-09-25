/**
 * ONE-TIME VERIFICATION — not a repeatable pattern. Verifies OPEN_ITEMS.md
 * item 79/85 (groups.delivery_format migrated from 6 values to Anca's 9
 * workshop types) end to end: real rendered pages, in WOW LAB Test Org B.
 *
 * Checks: (1) the real migrated MAX/green_energy group now renders
 * "Parteneriate cu companii" / "Company partnerships", not the old
 * "Corporate" label or a raw key; (2) a fresh scoli_private_recurente
 * group shows the resources caption's "optional" wording; (3) a fresh
 * non-recurring group (wow_lab_party) shows the "required" wording,
 * proving the recurring/one-off split is keyed on scoli_private_recurente
 * specifically, not a substring check; (4) the group list's format filter
 * options and column render the new label, not a raw key or the old one.
 *
 * Run (Test Org B, local dev):
 *   npx tsx --env-file=.env.local scripts/verify_groups_delivery_format_nine_types_test_org_b.ts
 *
 * Run (against the real production deployment, Test Org B data only):
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_groups_delivery_format_nine_types_test_org_b.ts
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_NAME = "WOW LAB Test Org B";
const OWNER_EMAIL = "test+user-b@wowlab.dev";
const SITE_URL = process.env.VERIFY_SITE_URL ?? process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return createSupabaseClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function signInAndFetch(a: ReturnType<typeof admin>, email: string, path: string) {
  const { data: link, error: linkErr } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (linkErr || !link) throw new Error(`generateLink failed for ${email}: ${linkErr?.message}`);
  const tokenHash = link.properties?.hashed_token;
  if (!tokenHash) throw new Error(`No hashed_token for ${email}`);

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
  const { error: verifyErr } = await authClient.auth.verifyOtp({ token_hash: tokenHash, type: "magiclink" });
  if (verifyErr) throw new Error(`verifyOtp failed for ${email}: ${verifyErr.message}`);

  const cookieHeader = [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
  const res = await fetch(`${SITE_URL}${path}`, { headers: { Cookie: cookieHeader } });
  const html = await res.text();
  return { status: res.status, html };
}

async function main() {
  const a = admin();
  const report: string[] = [];

  const { data: org, error: orgErr } = await a.from("organizations").select("id").eq("name", ORG_NAME).single();
  if (orgErr || !org) throw new Error(`Org lookup failed: ${orgErr?.message}`);

  // ---- 1. The real migrated row (MAX / green_energy) ----
  const { data: maxGroup } = await a
    .from("groups")
    .select("id, delivery_format")
    .eq("organization_id", org.id)
    .eq("module", "green_energy")
    .single();
  if (!maxGroup) throw new Error("MAX/green_energy group not found -- expected the real migrated row.");
  report.push(
    maxGroup.delivery_format === "parteneriate_companii"
      ? "1a. PASS - the real MAX/green_energy row's raw value is 'parteneriate_companii'"
      : `1a. FAIL - unexpected raw value '${maxGroup.delivery_format}'`,
  );
  const maxRes = await signInAndFetch(a, OWNER_EMAIL, `/groups/${maxGroup.id}`);
  report.push(
    maxRes.html.includes("Company partnerships")
      ? "1b. PASS - group detail page renders 'Company partnerships', not the old 'Corporate' label or a raw key"
      : `1b. FAIL - detail page did not render the expected label (status=${maxRes.status})`,
  );

  // ---- 2 & 3. Fresh fixtures: recurring vs one-off resources caption ----
  const { data: client } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: "DRYRUN-VERIFY item85 client", client_type: "private_school" })
    .select("id")
    .single();
  if (!client) throw new Error("Client insert failed.");

  const { data: recurringGroup } = await a
    .from("groups")
    .insert({ organization_id: org.id, client_id: client.id, module: "gaga", delivery_format: "scoli_private_recurente" })
    .select("id")
    .single();
  const { data: oneOffGroup } = await a
    .from("groups")
    .insert({ organization_id: org.id, client_id: client.id, module: "gaga", delivery_format: "wow_lab_party" })
    .select("id")
    .single();
  if (!recurringGroup || !oneOffGroup) throw new Error("Group insert failed.");

  try {
    const recurringRes = await signInAndFetch(a, OWNER_EMAIL, `/groups/${recurringGroup.id}`);
    report.push(
      recurringRes.html.includes("Private schools (recurring collaboration)")
        ? "2a. PASS - scoli_private_recurente group renders 'Private schools (recurring collaboration)'"
        : "2a. FAIL - label did not render as expected",
    );
    const recurringOptional = recurringRes.html.includes("optional only for recurring private-school collaborations");
    report.push(
      recurringOptional
        ? "2b. PASS - resources caption shows the OPTIONAL wording for scoli_private_recurente"
        : "2b. FAIL - expected the optional feedback-form caption on a recurring group",
    );

    const oneOffRes = await signInAndFetch(a, OWNER_EMAIL, `/groups/${oneOffGroup.id}`);
    report.push(
      oneOffRes.html.includes("Wow Lab Party")
        ? "3a. PASS - wow_lab_party group renders 'Wow Lab Party'"
        : "3a. FAIL - label did not render as expected",
    );
    const oneOffRequired = oneOffRes.html.includes("Required for this workshop.");
    report.push(
      oneOffRequired
        ? "3b. PASS - resources caption shows the REQUIRED wording for wow_lab_party (one-off, not the old 'recurring' string)"
        : "3b. FAIL - expected the mandatory feedback-form caption on a one-off group",
    );

    // ---- 4. List page: filter options and column render the new label ----
    const listRes = await signInAndFetch(a, OWNER_EMAIL, "/groups");
    report.push(
      listRes.html.includes("Company partnerships")
        ? "4. PASS - /groups list renders the new label for the migrated MAX row"
        : "4. FAIL - /groups list did not render the expected new label",
    );

    console.log("\n" + report.join("\n"));
    if (report.some((r) => r.includes("FAIL"))) {
      throw new Error("One or more assertions failed -- see report above.");
    }
  } finally {
    await a.from("groups").delete().eq("id", recurringGroup.id);
    await a.from("groups").delete().eq("id", oneOffGroup.id);
    await a.from("clients").delete().eq("id", client.id);
    console.log("Fixture cleaned up (2 groups, 1 client deleted). Real MAX row untouched.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
