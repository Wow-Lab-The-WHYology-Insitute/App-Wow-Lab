/**
 * ONE-TIME VERIFICATION — not a repeatable pattern. Verifies OPEN_ITEMS.md
 * item 52's extension build (time range, address, on-site contact) end to
 * end: real rendered pages, real sign-ins, both as the org owner and as an
 * allocated trainer fixture, in WOW LAB Test Org B.
 *
 * Fixture setup uses the service-role client directly (creating rows, not
 * exercising the app's own write actions) -- the point of this script is
 * verifying READ paths (RLS + rendering), which the earlier dry-run SQL
 * script (verify_client_contacts_trainer_facing_scoping.sql) already
 * proved for the RLS layer alone; this proves the same thing reaches the
 * actual rendered page, the same discipline as
 * verify_group_detail_client_name_render_test_org_b.ts.
 *
 * Run:
 *   npx tsx --env-file=.env.local scripts/verify_one_off_workshop_extension_fields_test_org_b.ts
 * Prerequisite: a local `next dev` server already running on
 * NEXT_PUBLIC_SITE_URL (http://localhost:3000).
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const OWNER_EMAIL = "test+user-b@wowlab.dev";
const PRINCIPAL_EMAIL = "maxdigitalro+trainerb1@gmail.com";
const OTHER_TRAINER_EMAIL = "maxdigitalro+trainerb3@gmail.com"; // not allocated to this session
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

  const { data: org, error: orgErr } = await a
    .from("organizations")
    .select("id")
    .eq("name", "WOW LAB Test Org B")
    .single();
  if (orgErr || !org) throw new Error(`Org lookup failed: ${orgErr?.message}`);

  const { data: principal, error: pErr } = await a.from("users").select("id").eq("email", PRINCIPAL_EMAIL).single();
  if (pErr || !principal) throw new Error(`Principal lookup failed: ${pErr?.message}`);

  const CLIENT_NAME = "DRYRUN-VERIFY item52ext client";
  const CLIENT_ADDRESS = "Str. Exemplu 12, Sector 1, București (client default)";
  const CONTACT_NAME = "DRYRUN Verify Onsite Contact";
  const CONTACT_PHONE = "0722000000";

  const { data: client, error: cErr } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: CLIENT_NAME, client_type: "corporate", address: CLIENT_ADDRESS })
    .select("id")
    .single();
  if (cErr || !client) throw new Error(`Client insert failed: ${cErr?.message}`);

  const { data: contact, error: ctErr } = await a
    .from("client_contacts")
    .insert({
      organization_id: org.id,
      client_id: client.id,
      full_name: CONTACT_NAME,
      phone: CONTACT_PHONE,
      contact_purpose: "trainer_facing",
    })
    .select("id")
    .single();
  if (ctErr || !contact) throw new Error(`Contact insert failed: ${ctErr?.message}`);

  const { data: group, error: gErr } = await a
    .from("groups")
    .insert({
      organization_id: org.id,
      client_id: client.id,
      module: "gaga",
      delivery_format: "party",
      on_site_contact_id: contact.id,
      // No group.address set -- exercises the COALESCE-to-client-default
      // path, not the override path (the override path is already
      // covered directly by the dry-run assertion in the RLS script).
    })
    .select("id")
    .single();
  if (gErr || !group) throw new Error(`Group insert failed: ${gErr?.message}`);

  const { data: session, error: sErr } = await a
    .from("sessions")
    .insert({
      organization_id: org.id,
      group_id: group.id,
      session_date: new Date().toISOString().slice(0, 10),
      trainer_principal_id: principal.id,
      status: "planned",
      start_time: "16:00:00",
      duration_minutes: 90,
    })
    .select("id")
    .single();
  if (sErr || !session) throw new Error(`Session insert failed: ${sErr?.message}`);

  console.log(`Fixture created: client=${client.id} contact=${contact.id} group=${group.id} session=${session.id}`);

  try {
    // ---- 1. Owner view: address (client default), contact name+phone, time range ----
    const ownerRes = await signInAndFetch(a, OWNER_EMAIL, `/groups/${group.id}`);
    report.push(ownerRes.status === 200 ? "1. PASS - owner: page returned 200" : `1. FAIL - owner: page returned ${ownerRes.status}`);
    report.push(
      ownerRes.html.includes(CLIENT_ADDRESS)
        ? "2. PASS - owner: sees the client's default address (no group override set)"
        : "2. FAIL - owner: does not see the client default address",
    );
    report.push(
      ownerRes.html.includes(CONTACT_NAME) && ownerRes.html.includes(CONTACT_PHONE)
        ? "3. PASS - owner: sees the on-site contact's name and phone"
        : "3. FAIL - owner: does not see the on-site contact's name/phone",
    );
    report.push(
      ownerRes.html.includes("16:00") && ownerRes.html.includes("17:30")
        ? "4. PASS - owner: sees the derived time range 16:00 – 17:30"
        : "4. FAIL - owner: does not see the derived 16:00–17:30 time range",
    );

    // ---- 2. Allocated trainer view: same three fields, on their own session ----
    const trainerRes = await signInAndFetch(a, PRINCIPAL_EMAIL, `/groups/${group.id}`);
    report.push(trainerRes.status === 200 ? "5. PASS - allocated trainer: page returned 200" : `5. FAIL - allocated trainer: page returned ${trainerRes.status}`);
    report.push(
      trainerRes.html.includes(CLIENT_ADDRESS)
        ? "6. PASS - allocated trainer: sees the address"
        : "6. FAIL - allocated trainer: does not see the address",
    );
    report.push(
      trainerRes.html.includes(CONTACT_NAME) && trainerRes.html.includes(CONTACT_PHONE)
        ? "7. PASS - allocated trainer: sees the on-site contact's name and phone (narrowed RLS branch, 202609210002)"
        : "7. FAIL - allocated trainer: does not see the on-site contact",
    );
    report.push(
      trainerRes.html.includes("16:00") && trainerRes.html.includes("17:30")
        ? "8. PASS - allocated trainer: sees the derived time range on their own session"
        : "8. FAIL - allocated trainer: does not see the time range",
    );

    // ---- 3. Unrelated trainer: page itself is inaccessible (groups' own mywork.* branch requires an allocated session) ----
    const otherRes = await signInAndFetch(a, OTHER_TRAINER_EMAIL, `/groups/${group.id}`);
    report.push(
      otherRes.status !== 200 || otherRes.html.includes("access_denied") || !otherRes.html.includes(CONTACT_NAME)
        ? "9. PASS - unrelated trainer: does not see the on-site contact's name anywhere in the response"
        : "9. FAIL - unrelated trainer can see the on-site contact -- leaks beyond their own sessions",
    );

    console.log("\n" + report.join("\n"));
    if (report.some((r) => r.startsWith("FAIL") || r.includes("FAIL"))) {
      throw new Error("One or more assertions failed -- see report above.");
    }
  } finally {
    await a.from("sessions").delete().eq("id", session.id);
    await a.from("groups").delete().eq("id", group.id);
    await a.from("client_contacts").delete().eq("id", contact.id);
    await a.from("clients").delete().eq("id", client.id);
    console.log("Fixture cleaned up (session, group, contact, client deleted).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
