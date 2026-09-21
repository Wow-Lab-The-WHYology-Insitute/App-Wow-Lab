/**
 * ONE-TIME VERIFICATION — not a repeatable pattern. Verifies OPEN_ITEMS.md
 * item 83 (clients.status renamed to status_override, item 78's derivation
 * unchanged) end to end: real rendered pages AND the raw column's actual
 * stored value, for all 5 named cases -- prospect, signed-contract
 * (active), paused, churned, reactivated -- in WOW LAB Test Org B.
 *
 * The point of checking status_override directly (not just the rendered
 * page) is the whole reason item 83 exists: the acceptance test isn't
 * just "the UI looks right," it's "the raw column never holds a status
 * word that means something other than its name" -- NULL or a real
 * override, nothing else, at every step.
 *
 * Run (Test Org B, local dev):
 *   npx tsx --env-file=.env.local scripts/verify_clients_status_override_rename_test_org_b.ts
 *
 * Run (against the real production deployment, Test Org B data only):
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_clients_status_override_rename_test_org_b.ts
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

function rawColumnIsClean(raw: string | null): boolean {
  // Never a status word -- only NULL or a real override.
  return raw === null || raw === "paused" || raw === "churned";
}

async function main() {
  const a = admin();
  const report: string[] = [];

  const { data: org, error: orgErr } = await a.from("organizations").select("id").eq("name", ORG_NAME).single();
  if (orgErr || !org) throw new Error(`Org lookup failed: ${orgErr?.message}`);
  const { data: entity } = await a.from("legal_entities").select("id").eq("organization_id", org.id).limit(1).single();

  const CLIENT_NAME = "DRYRUN-VERIFY item83 rename client";
  const { data: client, error: cErr } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: CLIENT_NAME, client_type: "corporate" })
    .select("id")
    .single();
  if (cErr || !client) throw new Error(`Client insert failed: ${cErr?.message}`);

  async function checkRawAndRendered(step: string, expectedLabel: string) {
    const { data: row } = await a.from("clients").select("status_override").eq("id", client!.id).single();
    const raw = row?.status_override ?? null;
    const cleanRaw = rawColumnIsClean(raw);
    report.push(
      cleanRaw
        ? `${step}a. PASS - raw status_override is clean (${raw === null ? "NULL" : `'${raw}'`}), never a status word`
        : `${step}a. FAIL - raw status_override holds '${raw}', a status word that means something else`,
    );
    const res = await signInAndFetch(a, OWNER_EMAIL, `/clients/${client!.id}`);
    const rendersExpected = res.html.includes(`>${expectedLabel}<`);
    report.push(
      rendersExpected
        ? `${step}b. PASS - page renders ${expectedLabel}`
        : `${step}b. FAIL - page does not render ${expectedLabel} (status=${res.status})`,
    );
  }

  try {
    // ---- 1. Prospect: no override, no signed contract ----
    await checkRawAndRendered("1", "Prospect");

    // ---- 2. Signed-contract client: no override, contract signed -> Active ----
    const { data: contract } = await a
      .from("contracts")
      .insert({
        organization_id: org.id,
        client_id: client.id,
        legal_entity_id: entity!.id,
        contract_type: "recurring_annual",
        status: "signed",
        signed_date: new Date().toISOString().slice(0, 10),
      })
      .select("id")
      .single();
    void contract;
    await checkRawAndRendered("2", "Active");

    // ---- 3. Paused: override set, still has a signed contract underneath ----
    await a.from("clients").update({ status_override: "paused" }).eq("id", client.id);
    await checkRawAndRendered("3", "Paused");

    // ---- 4. Churned: override changed directly (paused -> churned edge) ----
    await a.from("clients").update({ status_override: "churned" }).eq("id", client.id);
    await checkRawAndRendered("4", "Churned");

    // ---- 5. Reactivated: override cleared (NULL) -- re-derives to Active since the contract is still signed ----
    await a.from("clients").update({ status_override: null }).eq("id", client.id);
    await checkRawAndRendered("5", "Active");

    console.log("\n" + report.join("\n"));
    if (report.some((r) => r.includes("FAIL"))) {
      throw new Error("One or more assertions failed -- see report above.");
    }
  } finally {
    await a.from("contracts").delete().eq("client_id", client.id);
    await a.from("clients").delete().eq("id", client.id);
    console.log("Fixture cleaned up (contract, client deleted).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
