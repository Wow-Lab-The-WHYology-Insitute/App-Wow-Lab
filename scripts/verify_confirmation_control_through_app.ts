/**
 * ONE-TIME VERIFICATION (item 97). Confirms the redesigned confirmation
 * control's five render shapes through the real app on app.wowlab.ro, in
 * wow-lab-test-b, as both trainer fixtures and as a finance/owner-level
 * viewer -- not by reading the code, by fetching the real rendered HTML
 * of a real authenticated session after real writes.
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_confirmation_control_through_app.ts
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

async function extractActionIds(pageUrl: string, cookieHeader: string, names: string[]) {
  const res = await fetch(pageUrl, { headers: { Cookie: cookieHeader } });
  const html = await res.text();
  const chunkPaths = [...new Set([...html.matchAll(/"(\/_next\/static\/chunks\/[^"]+\.js)"/g)].map((m) => m[1]))];
  const found: Record<string, string> = {};
  for (const chunkPath of chunkPaths) {
    const chunkText = await (await fetch(`${SITE_URL}${chunkPath}`)).text();
    for (const name of names) {
      if (found[name]) continue;
      const m = chunkText.match(new RegExp(`createServerReference\\)\\("([0-9a-f]{20,})"[^)]*?,\\s*"${name}"`));
      if (m) found[name] = m[1];
    }
  }
  return found;
}

async function callAction(pagePath: string, actionId: string, args: unknown[], cookieHeader: string) {
  const res = await fetch(`${SITE_URL}${pagePath}`, {
    method: "POST",
    headers: { Cookie: cookieHeader, "Next-Action": actionId, Accept: "text/x-component", "Content-Type": "text/plain;charset=UTF-8" },
    body: JSON.stringify(args),
  });
  return { status: res.status, text: await res.text() };
}

function extractWindow(html: string, needle: string, span = 260): string {
  const idx = html.indexOf(needle);
  return idx === -1 ? `NOT FOUND: "${needle}"` : html.slice(idx, idx + span);
}

async function main() {
  const a = admin();
  const report: string[] = [];

  const opsCookie = await signIn(a, "test+ui-ops-manager-b@wowlab.dev");
  const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
  const orgId = org!.id;
  const { data: trainerB1 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
  const { data: trainerB2 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb2@gmail.com").single();

  // Isolated client+group, not the shared MAX group -- MAX has
  // accumulated standing fixture sessions from earlier verification
  // rounds, and a fresh session created under it can't be reliably
  // isolated by simple text search once several sessions share the same
  // two trainer names. A self-contained group makes this session the
  // only one on the page.
  const { data: client } = await a
    .from("clients")
    .insert({ organization_id: orgId, name: "DRYRUN item97 confirmation-control client", client_type: "private_school" })
    .select("id")
    .single();
  const { data: newGroup } = await a
    .from("groups")
    .insert({ organization_id: orgId, client_id: client!.id, module: "gaga", delivery_format: "wow_lab_party" })
    .select("id")
    .single();
  const groupId = newGroup!.id;

  const ids = await extractActionIds(`${SITE_URL}/groups/${groupId}`, opsCookie, ["addSession", "confirmSessionAttendance", "correctSessionConfirmation"]);
  report.push(`Extracted action ids: ${JSON.stringify(ids)}`);

  try {
    // ---- Fresh, unconfirmed session, alone in this group ----
    const rCreate = await callAction(`/groups/${groupId}`, ids.addSession, [orgId, groupId, new Date().toISOString().slice(0, 10), trainerB1!.id, trainerB2!.id, "planned", "", "", "", "", "", ""], opsCookie);
    const { data: created } = await a.from("sessions").select("id").eq("group_id", groupId).maybeSingle();
    if (!created) throw new Error(`Could not create a fresh unconfirmed session. HTTP ${rCreate.status}: ${rCreate.text}`);
    const sessionId = created.id;
    report.push(`Fresh unconfirmed session created: ${sessionId}, alone in group ${groupId}`);

    // ---- As B1: own slot unconfirmed -> "Check to confirm" ----
    const b1Cookie = await signIn(a, "maxdigitalro+trainerb1@gmail.com");
    const b1PageBefore = await (await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: b1Cookie } })).text();
    report.push(`\n[B1, own slot, BEFORE confirming]\n${extractWindow(b1PageBefore, "Test Trainer B1<")}`);

    // ---- As B2: own slot unconfirmed -> "Check to confirm"; B1's slot (colleague, unconfirmed) -> plain "Not confirmed" ----
    const b2Cookie = await signIn(a, "maxdigitalro+trainerb2@gmail.com");
    const b2Page = await (await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: b2Cookie } })).text();
    report.push(`\n[B2, viewing B1's slot (colleague, unconfirmed, read-only)]\n${extractWindow(b2Page, "Test Trainer B1<")}`);
    report.push(`\n[B2, own slot, BEFORE confirming]\n${extractWindow(b2Page, "Test Trainer B2<")}`);

    // ---- B1 actually confirms their own slot ----
    const rConfirm = await callAction(`/groups/${groupId}`, ids.confirmSessionAttendance, [groupId, sessionId, true], b1Cookie);
    const { data: afterConfirm } = await a.from("sessions").select("trainer_principal_confirmed_at").eq("id", sessionId).single();
    report.push(`\nB1 confirms own slot: HTTP ${rConfirm.status}, DB principal_confirmed_at=${afterConfirm?.trainer_principal_confirmed_at} -> ${afterConfirm?.trainer_principal_confirmed_at ? "PASS" : "FAIL"}`);

    // ---- As B1: own slot now confirmed -> plain label, no checkbox ----
    const b1PageAfter = await (await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: b1Cookie } })).text();
    report.push(`\n[B1, own slot, AFTER confirming]\n${extractWindow(b1PageAfter, "Test Trainer B1<")}`);

    // ---- As B2: viewing B1's slot, now confirmed (colleague, read-only) ----
    const b2PageAfter = await (await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: b2Cookie } })).text();
    report.push(`\n[B2, viewing B1's slot (colleague, NOW confirmed, read-only)]\n${extractWindow(b2PageAfter, "Test Trainer B1<")}`);

    // ---- As finance/owner-level viewer: correction control, bidirectional, constant label ----
    const financeCookie = await signIn(a, "test+ui-contract-admin-b@wowlab.dev");
    const financePage = await (await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: financeCookie } })).text();
    report.push(`\n[Finance/owner viewer, B1's slot (confirmed) -- correction control]\n${extractWindow(financePage, "Test Trainer B1<")}`);
    report.push(`\n[Finance/owner viewer, B2's slot (never confirmed) -- correction control]\n${extractWindow(financePage, "Test Trainer B2<")}`);

    console.log("\n" + report.join("\n"));
  } finally {
    await a.from("sessions").delete().eq("group_id", groupId);
    await a.from("groups").delete().eq("id", groupId);
    await a.from("clients").delete().eq("id", client!.id);
    console.log(`\nFixtures (session, group, client) deleted.`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
