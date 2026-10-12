/**
 * ONE-TIME VERIFICATION (item 117). The whole loop against the REAL deployment,
 * in WOW LAB Test Org B only: a trainer proposes an experiment, the validator
 * decides, the trainer meets the notification on /my-work and marks it seen.
 *
 * Same two-sided honesty as scripts/verify_vet_module_test_org_b.ts about
 * language: the locale is a client-only localStorage preference, so a
 * server-side fetch always renders EN. EN is verified by RENDERING; RO is
 * verified by SHIPMENT in the client bundle, which is a weaker claim and said
 * to be one.
 *
 * Fixtures: Test Org B has no lesson_plans of its own (the catalogue was
 * imported for wow-lab), so this creates two, plus a client/group/session, and
 * deletes all of it in `finally` -- announcing whether cleanup ran, per item
 * 102's two standing fixtures left mutated by a silent finally.
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_lesson_plan_flow_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_SLUG = "wow-lab-test-b";
const TRAINER_EMAIL = "maxdigitalro+trainerb1@gmail.com";
const VALIDATOR_EMAIL = "test+user-b@wowlab.dev";
const SITE_URL = process.env.VERIFY_SITE_URL ?? "https://app.wowlab.ro";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function signIn(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (error || !link) throw new Error(`generateLink failed for ${email}: ${error?.message}`);
  const jar = new Map<string, string>();
  const c = createServerClient(SUPABASE_URL, ANON_KEY, {
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
  const { error: vErr } = await c.auth.verifyOtp({ token_hash: link.properties!.hashed_token!, type: "magiclink" });
  if (vErr) throw new Error(`verifyOtp failed for ${email}: ${vErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}

function visibleText(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/g, " ")
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
  let cleanup: (() => Promise<void>) | null = null;
  let ran = false;

  try {
    const { data: org } = await a.from("organizations").select("id").eq("slug", ORG_SLUG).single();
    const { data: trainer } = await a.from("users").select("id").eq("email", TRAINER_EMAIL).single();
    const { data: validator } = await a.from("users").select("id").eq("email", VALIDATOR_EMAIL).single();
    const { data: client } = await a
      .from("clients")
      .insert({ organization_id: org!.id, name: "VERIFY item 117 client", client_type: "corporate" })
      .select("id")
      .single();
    const { data: group } = await a
      .from("groups")
      .insert({
        organization_id: org!.id,
        client_id: client!.id,
        module: "anatomy",
        delivery_format: "scoli_private_recurente",
        status: "active",
        notes: "item 117 live verification -- deleted by this script",
      })
      .select("id")
      .single();
    const { data: session } = await a
      .from("sessions")
      .insert({
        organization_id: org!.id,
        group_id: group!.id,
        session_date: new Date().toISOString().slice(0, 10),
        trainer_principal_id: trainer!.id,
        status: "planned",
      })
      .select("id")
      .single();
    // Two plans, one of them with a SECOND title on a module sheet, so the
    // "matched as" path the 68-multi-title finding demands is exercised.
    const { data: plans } = await a
      .from("lesson_plans")
      .insert([
        { organization_id: org!.id, plan_ref: "verify_117_a", canonical_title: "Verify Volcano Alpha", status: "written", what_is_taught: "acid-base reaction" },
        { organization_id: org!.id, plan_ref: "verify_117_b", canonical_title: "Verify Lantern Beta", status: "written" },
      ])
      .select("id, plan_ref");
    const planA = plans!.find((p) => p.plan_ref === "verify_117_a")!;
    await a.from("lesson_plan_modules").insert([
      { organization_id: org!.id, lesson_plan_id: planA.id, module: "anatomy", ordinal: 1, title_on_sheet: "Verify Alternate Eruption Name" },
    ]);

    cleanup = async () => {
      await a.from("session_lesson_plans").delete().eq("session_id", session!.id);
      await a.from("lesson_plan_modules").delete().in("lesson_plan_id", plans!.map((p) => p.id));
      await a.from("lesson_plans").delete().in("id", plans!.map((p) => p.id));
      await a.from("sessions").delete().eq("id", session!.id);
      await a.from("groups").delete().eq("id", group!.id);
      await a.from("clients").delete().eq("id", client!.id);
    };

    // ---- 1. the group page renders the section and the catalogue reaches it ----
    const trainerCookie = await signIn(a, TRAINER_EMAIL);
    let res = await fetch(`${SITE_URL}/groups/${group!.id}`, { headers: { Cookie: trainerCookie } });
    let html = await res.text();
    let text = visibleText(html);
    report.push(`/groups/[id] as the allocated trainer: HTTP ${res.status}`);
    report.push("--- EN, verified by rendering ---");
    report.push(`  the section renders: ${text.includes("Experiments and validation")}`);
    report.push(`  the trainer's own slot is named: ${text.includes("Principal")}`);
    report.push(`  no experiment chosen yet: ${text.includes("No experiment chosen")}`);
    report.push(`  the trainer gets the chooser: ${text.includes("Choose an experiment")}`);
    report.push(`  a trainer does NOT get the validate control: ${!text.includes("Request changes")}`);

    // ---- 2. propose, as the trainer, through the real RPC ----
    const trainerDb = createSupabaseClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Cookie: trainerCookie } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    // The cookie-based client cannot carry the session for an RPC, so the
    // proposal is made with the trainer's own access token instead.
    const { data: linkT } = await a.auth.admin.generateLink({ type: "magiclink", email: TRAINER_EMAIL });
    const trainerSession = await createSupabaseClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } })
      .auth.verifyOtp({ token_hash: linkT!.properties!.hashed_token!, type: "magiclink" });
    const asTrainer = createSupabaseClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${trainerSession.data.session!.access_token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    void trainerDb;
    const { data: proposeResult } = await asTrainer.rpc("rpc_propose_session_lesson_plan", {
      p_session_id: session!.id,
      p_lesson_plan_id: planA.id,
    });
    report.push(`\n  trainer proposes via the real RPC: ${proposeResult === "ok"} (${proposeResult})`);

    // ---- 3. the validator sees it and can decide; the trainer cannot ----
    const { data: decideAsTrainer } = await asTrainer.rpc("rpc_decide_session_lesson_plan", {
      p_row_id: (await a.from("session_lesson_plans").select("id").eq("session_id", session!.id).single()).data!.id,
      p_status: "validated",
      p_note: null,
    });
    report.push(`  the trainer CANNOT validate their own plan: ${decideAsTrainer === "not_permitted"} (${decideAsTrainer})`);

    const validatorCookie = await signIn(a, VALIDATOR_EMAIL);
    res = await fetch(`${SITE_URL}/groups/${group!.id}`, { headers: { Cookie: validatorCookie } });
    text = visibleText(await res.text());
    report.push(`\n/groups/[id] as the curriculum.validate holder: HTTP ${res.status}`);
    report.push(`  the proposed plan renders: ${text.includes("Verify Volcano Alpha")}`);
    report.push(`  awaiting-validation state shows: ${text.includes("Awaiting validation")}`);
    report.push(`  the validator gets the controls: ${text.includes("Request changes") && text.includes("Validate")}`);
    report.push(`  the "record stands without validation" line shows: ${text.includes("The record of what was delivered does not depend on it")}`);

    const { data: linkV } = await a.auth.admin.generateLink({ type: "magiclink", email: VALIDATOR_EMAIL });
    const validatorSession = await createSupabaseClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } })
      .auth.verifyOtp({ token_hash: linkV!.properties!.hashed_token!, type: "magiclink" });
    const asValidator = createSupabaseClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${validatorSession.data.session!.access_token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const rowId = (await a.from("session_lesson_plans").select("id").eq("session_id", session!.id).single()).data!.id;
    const { data: noNote } = await asValidator.rpc("rpc_decide_session_lesson_plan", {
      p_row_id: rowId, p_status: "changes_requested", p_note: "  ",
    });
    report.push(`  changes_requested with a blank note is refused: ${noNote === "note_required"} (${noNote})`);
    const { data: decided } = await asValidator.rpc("rpc_decide_session_lesson_plan", {
      p_row_id: rowId, p_status: "changes_requested", p_note: "Too close to the other experiment.",
    });
    report.push(`  the validator requests changes: ${decided === "ok"} (${decided})`);

    // ---- 4. the trainer meets it on /my-work and marks it seen ----
    res = await fetch(`${SITE_URL}/my-work`, { headers: { Cookie: trainerCookie } });
    text = visibleText(await res.text());
    report.push(`\n/my-work as the trainer: HTTP ${res.status}`);
    report.push(`  the notification renders: ${text.includes("Experiment decisions")}`);
    report.push(`  it names the decision: ${text.includes("Changes requested")}`);
    report.push(`  it carries the note: ${text.includes("Too close to the other experiment.")}`);
    report.push(`  it offers "Mark seen": ${text.includes("Mark seen")}`);

    const { data: markResult } = await asTrainer.rpc("rpc_mark_session_lesson_plan_seen", { p_row_id: rowId });
    report.push(`  the trainer marks it seen: ${markResult === "ok"} (${markResult})`);
    res = await fetch(`${SITE_URL}/my-work`, { headers: { Cookie: trainerCookie } });
    text = visibleText(await res.text());
    report.push(`  and the notification is GONE afterwards: ${!text.includes("Experiment decisions")}`);

    // ---- 5. RO, by shipment ----
    res = await fetch(`${SITE_URL}/groups/${group!.id}`, { headers: { Cookie: trainerCookie } });
    html = await res.text();
    const srcs = [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    let bundle = "";
    for (const s of srcs) {
      const url = s.startsWith("http") ? s : `${SITE_URL}${s}`;
      try { bundle += await (await fetch(url)).text(); } catch { /* a chunk that fails contributes nothing */ }
    }
    const decoded = bundle
      .replace(/\\x([0-9a-fA-F]{2})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)))
      .replace(/\\u([0-9a-fA-F]{4})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)));
    report.push("\n--- RO, verified by shipment in the client bundle (NOT by rendering) ---");
    report.push(`  chunks fetched: ${srcs.length}, bytes: ${bundle.length}`);
    report.push(`  section title ships RO: ${decoded.includes("Experimente și validare")}`);
    report.push(`  "Cere modificări" ships: ${decoded.includes("Cere modificări")}`);
    report.push(`  the search placeholder ships RO: ${decoded.includes("Caută după nume, temă sau fișier…")}`);

    console.log("\n" + report.join("\n"));
    const failed = report.some((r) => r.includes(": false"));
    console.log(failed ? "\nAt least one expectation FAILED." : "\nAll expectations held.");
    if (failed) process.exitCode = 1;
  } finally {
    if (cleanup) { await cleanup(); ran = true; }
    console.log(ran
      ? "\nCLEANUP: the verification client, group, session, plans and proposal were deleted. Test Org B is as it was found."
      : "\nCLEANUP: NOTHING TO CLEAN UP (no fixture was created).");
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
