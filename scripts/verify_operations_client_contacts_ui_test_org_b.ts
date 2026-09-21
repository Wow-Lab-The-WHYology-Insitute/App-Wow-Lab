/**
 * ONE-TIME VERIFICATION — not a repeatable pattern. Verifies OPEN_ITEMS.md
 * item 80 (Catalina/operations_manager can create+edit client_contacts,
 * Anca 2026-09-21) end to end: real rendered pages as the operations
 * manager and as a trainer, in WOW LAB Test Org B. The write-path RLS
 * itself is proven by scripts/verify_operations_client_contacts_write.sql
 * (6/6, dry run); this proves the same thing reaches the actual rendered
 * page controls (create button shown/hidden, edit shown, delete NOT
 * shown), the same discipline as verify_one_off_workshop_extension_fields_test_org_b.ts.
 *
 * Run (Test Org B, local dev):
 *   npx tsx --env-file=.env.local scripts/verify_operations_client_contacts_ui_test_org_b.ts
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_NAME = "WOW LAB Test Org B";
const OPS_EMAIL = "test+ui-ops-manager-b@wowlab.dev";
const TRAINER_EMAIL = "maxdigitalro+trainerb1@gmail.com";
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

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

  const CLIENT_NAME = "DRYRUN-VERIFY item80 client";
  const CONTACT_NAME = "DRYRUN-VERIFY item80 existing contact";
  const { data: client, error: cErr } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: CLIENT_NAME, client_type: "corporate" })
    .select("id")
    .single();
  if (cErr || !client) throw new Error(`Client insert failed: ${cErr?.message}`);

  const { data: contact, error: ctErr } = await a
    .from("client_contacts")
    .insert({ organization_id: org.id, client_id: client.id, full_name: CONTACT_NAME, phone: "0711111111", contact_purpose: "general" })
    .select("id")
    .single();
  if (ctErr || !contact) throw new Error(`Contact insert failed: ${ctErr?.message}`);

  try {
    // ---- 1. Ops manager: sees the "+ New contact" button (canEdit) and an edit action, but NOT a delete action ----
    const opsRes = await signInAndFetch(a, OPS_EMAIL, `/clients/${client.id}`);
    report.push(opsRes.status === 200 ? "1. PASS - ops manager: page returned 200" : `1. FAIL - ops manager: page returned ${opsRes.status}`);
    report.push(
      opsRes.html.includes(CONTACT_NAME)
        ? "2. PASS - ops manager: sees the existing contact"
        : "2. FAIL - ops manager: does not see the existing contact",
    );
    const opsShowsCreate = opsRes.html.includes("New contact") || opsRes.html.includes("Contact nou");
    report.push(opsShowsCreate ? "3. PASS - ops manager sees the create-contact button" : "3. FAIL - ops manager does not see the create-contact button");
    const opsShowsEdit = opsRes.html.includes(">edit<") || opsRes.html.includes(">editează<");
    report.push(opsShowsEdit ? "4. PASS - ops manager sees an edit action on the contact row" : "4. FAIL - ops manager does not see an edit action");
    const opsShowsDelete = opsRes.html.includes(">delete<") || opsRes.html.includes(">șterge<");
    report.push(!opsShowsDelete ? "5. PASS - ops manager does NOT see a delete action (not granted, item 80)" : "5. FAIL - ops manager sees a delete action it should not have");

    // ---- 2. Trainer: cannot reach this client at all (no allocated session -- clients' own mywork.* branch doesn't apply), so a fortiori no contact controls ----
    const trainerRes = await signInAndFetch(a, TRAINER_EMAIL, `/clients/${client.id}`);
    report.push(
      trainerRes.status !== 200 || !trainerRes.html.includes(CONTACT_NAME)
        ? "6. PASS - a trainer with no allocated session at this client cannot see it or its contacts at all"
        : "6. FAIL - a trainer unexpectedly saw this client's contact",
    );

    console.log("\n" + report.join("\n"));
    if (report.some((r) => r.startsWith("FAIL") || r.includes("FAIL"))) {
      throw new Error("One or more assertions failed -- see report above.");
    }
  } finally {
    await a.from("client_contacts").delete().eq("client_id", client.id);
    await a.from("clients").delete().eq("id", client.id);
    console.log("Fixture cleaned up (contact, client deleted).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
