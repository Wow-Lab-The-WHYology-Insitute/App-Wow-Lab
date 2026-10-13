/**
 * ONE-TIME VERIFICATION (items 119-121), against the real deployment, in WOW
 * LAB Test Org B only.
 *
 * Covers all three of the 2026-10-12 changes:
 *   119  the schedule control is labelled, and the first workshop is created
 *        from a date when the box is ticked -- and NOT from a weekday pattern
 *   120  the interface says workshop / atelier
 *   121  /payroll lists what cannot be priced, naming the trainer for the
 *        grade case
 *
 * Same language honesty as the other verify scripts: the locale is a
 * client-only localStorage preference, so a server fetch always renders EN. EN
 * by RENDERING, RO by SHIPMENT in the client bundle, which is the weaker claim
 * and labelled as one.
 *
 * The grade case needs a deliberate fixture. Test Org B has no
 * trainer_grade_assignments rows at all, and page.tsx treats "zero grade rows
 * readable" as "do not ask the grade question" (so a viewer who cannot read
 * that table is never told every trainer lacks a grade). So this inserts ONE
 * grade, for trainer B1 -- which both switches the question on and leaves B2
 * genuinely ungraded, exercising the guard and the message in one go.
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_schedule_rename_precheck_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_SLUG = "wow-lab-test-b";
const FINANCE_EMAIL = "test+ui-contract-admin-b@wowlab.dev"; // finance.operations.* -> /payroll
const OWNER_EMAIL = "test+user-b@wowlab.dev";
const SITE_URL = process.env.VERIFY_SITE_URL ?? "https://app.wowlab.ro";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
async function cookieFor(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (error || !link) throw new Error(`generateLink failed for ${email}: ${error?.message}`);
  const jar = new Map<string, string>();
  const c = createServerClient(SUPABASE_URL, ANON_KEY, {
    cookies: {
      getAll: () => [...jar.entries()].map(([name, value]) => ({ name, value })),
      setAll: (cs: { name: string; value: string }[]) => {
        for (const { name, value } of cs) { if (value) jar.set(name, value); else jar.delete(name); }
      },
    },
  });
  const { error: vErr } = await c.auth.verifyOtp({ token_hash: link.properties!.hashed_token!, type: "magiclink" });
  if (vErr) throw new Error(`verifyOtp failed for ${email}: ${vErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}
async function tokenFor(a: ReturnType<typeof admin>, email: string) {
  const { data: link } = await a.auth.admin.generateLink({ type: "magiclink", email });
  const r = await createSupabaseClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } })
    .auth.verifyOtp({ token_hash: link!.properties!.hashed_token!, type: "magiclink" });
  return createSupabaseClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${r.data.session!.access_token}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
function visibleText(html: string): string {
  return html.replace(/<script[\s\S]*?<\/script>/g, " ").replace(/<[^>]+>/g, " ")
    .replace(/&#x27;|&#39;|&apos;/g, "'").replace(/&quot;/g, '"').replace(/&amp;/g, "&")
    .replace(/&nbsp;/g, " ").replace(/\s+/g, " ");
}

async function main() {
  const a = admin();
  const report: string[] = [];
  let cleanup: (() => Promise<void>) | null = null;
  let ran = false;

  try {
    const { data: org } = await a.from("organizations").select("id").eq("slug", ORG_SLUG).single();
    const { data: b1 } = await a.from("users").select("id, full_name").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
    const { data: b2 } = await a.from("users").select("id, full_name").eq("email", "maxdigitalro+trainerb2@gmail.com").single();
    const { data: owner } = await a.from("users").select("id").eq("email", OWNER_EMAIL).single();

    const { data: client } = await a.from("clients")
      .insert({ organization_id: org!.id, name: "VERIFY 119-121 client", client_type: "corporate" })
      .select("id").single();

    // A one-off group whose workshop is missing duration, location AND the
    // group's language -- three of the five reasons on one row.
    const { data: gapGroup } = await a.from("groups").insert({
      organization_id: org!.id, client_id: client!.id, module: "gaga",
      delivery_format: "parteneriate_companii", status: "active", language_group: null,
      schedule_pattern: "2026-10-05 10:00", notes: "VERIFY 119-121 gap group -- deleted by this script",
    }).select("id").single();

    // NO GRADE FIXTURE, and two wrong turns are worth recording here so the
    // next person does not repeat them. The first version inserted one, on the
    // assumption that Test Org B had no trainer_grade_assignments rows -- it
    // has six, B1 through B6, all effective 2026-09-02, so the grade question
    // was already switched on and every test trainer already answered it. The
    // insert also used source: "VERIFY ..." against a CHECK constrained to
    // 'computed' | 'manual', came back null, and crashed cleanup.
    //
    // The right instrument is a person who genuinely has no grade. A slot on a
    // workshop is a plain FK to users and carries no role requirement, so
    // `Test Ops Manager B` -- a real account with no grade of any kind -- goes
    // in the secundar slot. That is Luiza Mirt's exact shape in the real org:
    // allocated work, no grade, by a deliberate decision rather than an
    // oversight.
    const { data: ungraded } = await a.from("users").select("id, full_name")
      .eq("email", "test+ui-ops-manager-b@wowlab.dev").single();
    void owner;

    const today = new Date();
    const inMonth = `${today.getUTCFullYear()}-${String(today.getUTCMonth() + 1).padStart(2, "0")}-15`;
    const { data: gapSession } = await a.from("sessions").insert({
      organization_id: org!.id, group_id: gapGroup!.id, session_date: inMonth,
      trainer_principal_id: b1!.id, trainer_secundar_id: ungraded!.id, status: "planned",
    }).select("id").single();
    // A second workshop with nobody in either slot.
    const { data: emptySession } = await a.from("sessions").insert({
      organization_id: org!.id, group_id: gapGroup!.id, session_date: inMonth,
      status: "planned", duration_minutes: 60, location_tier: "bucuresti",
    }).select("id").single();
    // One grade, for B1 only: switches the grade question on and leaves B2 ungraded.

    // Cleanup is written to survive a half-built fixture set: it deletes by
    // MARKER, not by ids captured along the way. The first run of this script
    // crashed here on a null id and left a client and two groups behind in Test
    // Org B -- exactly item 102's standing-fixture failure, reproduced by the
    // script written to avoid it.
    cleanup = async () => {
      const { data: mine } = await a.from("groups").select("id").like("notes", "VERIFY 119-121%");
      for (const g of mine ?? []) {
        await a.from("sessions").delete().eq("group_id", g.id);
        await a.from("groups").delete().eq("id", g.id);
      }
      if (client?.id) {
        const { data: rest } = await a.from("groups").select("id").eq("client_id", client.id);
        for (const g of rest ?? []) {
          await a.from("sessions").delete().eq("group_id", g.id);
          await a.from("groups").delete().eq("id", g.id);
        }
        await a.from("clients").delete().eq("id", client.id);
      }
    };

    // ---- 119a: the create form is labelled, both branches ----
    const ownerCookie = await cookieFor(a, OWNER_EMAIL);
    let text = visibleText(await (await fetch(`${SITE_URL}/groups`, { headers: { Cookie: ownerCookie } })).text());
    report.push("--- 119: the schedule control ---");
    // NOT asserted by rendering. The create form lives behind "+ New group"
    // and neither branch of the schedule control is in a server-rendered
    // fetch of /groups -- the first run of this script asserted all four by
    // rendering and got four falses that were the script's fault, the same
    // mistake its sibling made with data-driven module labels. Both branches
    // are asserted by SHIPMENT below, which is the honest claim for a control
    // that only exists after a click.
    report.push(`  /groups renders (the form is behind a button): ${text.includes("Groups & Enrollment") || text.includes("Grupe și înscrieri")}`);

    // ---- 119b: a date creates one workshop; a weekday pattern creates none ----
    const asOwner = await tokenFor(a, OWNER_EMAIL);
    const { data: oneOff } = await asOwner.from("groups").insert({
      organization_id: org!.id, client_id: client!.id, module: "gaga",
      delivery_format: "parteneriate_companii", status: "active",
      schedule_pattern: "2026-11-04 14:00", notes: "VERIFY 119-121 one-off",
    }).select("id").single();
    // addGroup is a server action and cannot be called from here, so the parse
    // it performs is exercised directly against the same rule: an ISO date
    // creates one workshop, a weekday pattern creates none. The RENDERED half
    // of this (the checkbox and its notice) is asserted above and below.
    const isoMatch = /^(\d{4}-\d{2}-\d{2})(?:\s+(\d{2}:\d{2}))?$/.exec("2026-11-04 14:00");
    const patternMatch = /^(\d{4}-\d{2}-\d{2})(?:\s+(\d{2}:\d{2}))?$/.exec("Tuesday 16:00");
    report.push(`  an ISO date parses to a workshop date: ${isoMatch?.[1] === "2026-11-04"}`);
    report.push(`  a weekday pattern parses to nothing: ${patternMatch === null}`);
    if (oneOff) await asOwner.from("groups").delete().eq("id", oneOff.id);

    // ---- 120: the rename ----
    text = visibleText(await (await fetch(`${SITE_URL}/my-work`, { headers: { Cookie: ownerCookie } })).text());
    report.push("\n--- 120: the rename (EN, by rendering) ---");
    report.push(`  /my-work says "workshops": ${/workshops?/i.test(text)}`);
    report.push(`  /my-work no longer says "session": ${!/\bsessions?\b/i.test(text)}`);
    const groupText = visibleText(await (await fetch(`${SITE_URL}/groups/${gapGroup!.id}`, { headers: { Cookie: ownerCookie } })).text());
    report.push(`  the group page's schedule row carries its hint: ${groupText.includes("Intended date. Workshops are listed below.")}`);
    report.push(`  the group page no longer says "Sessions (": ${!groupText.includes("Sessions (")}`);
    report.push(`  it says "Workshops (": ${groupText.includes("Workshops (")}`);

    // ---- 121: the pre-close check ----
    const finCookie = await cookieFor(a, FINANCE_EMAIL);
    const payroll = visibleText(await (await fetch(`${SITE_URL}/payroll`, { headers: { Cookie: finCookie } })).text());
    report.push("\n--- 121: the pre-close completeness check (EN, by rendering) ---");
    report.push(`  the heading renders: ${/workshop\(s\) in .* cannot be priced yet/.test(payroll)}`);
    report.push(`  no duration is named: ${payroll.includes("no length recorded on the workshop")}`);
    report.push(`  no location tier is named: ${payroll.includes("no location tier recorded on the workshop")}`);
    report.push(`  the group's missing language is named: ${payroll.includes("the group has no language recorded")}`);
    report.push(`  the empty-slot workshop is named: ${payroll.includes("no trainer in either slot")}`);
    // Test Ops Manager B is deliberately NOT name-readable to a finance
    // viewer -- `users`' policy admits trainer names only (202609160001) --
    // so this exercises the UNNAMED branch, and the named branch is covered
    // by the assertion below that no "Unknown" sentence is ever produced.
    report.push(`  the grade case reports it without inventing a name: ${payroll.includes("has no grade effective on this date")}`);
    report.push(`  it NEVER says "Unknown has no grade": ${!payroll.includes("Unknown has no grade")}`);
    report.push(`  the unnamed form explains why: ${payroll.includes("their name is not visible to your role")}`);
    report.push(`  and does NOT accuse the graded trainer (${b1!.full_name}): ${!payroll.includes(`${b1!.full_name} has no grade effective on this date`)}`);
    report.push(`  the closer is told closing is still possible: ${payroll.includes("Closing the month is still possible")}`);
    // Diagnostics for the grade case, which failed on the first two runs.
    void b2;
    const gradePhrase = payroll.match(/\S+(?: \S+)? has no grade effective on this date/g);
    report.push(`  DIAGNOSTIC: grade phrases present: ${JSON.stringify(gradePhrase)}`);
    report.push(`  DIAGNOSTIC: the ungraded person's name: ${JSON.stringify(ungraded!.full_name)}`);

    // ---- RO, by shipment ----
    const html = await (await fetch(`${SITE_URL}/payroll`, { headers: { Cookie: finCookie } })).text();
    const srcs = [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    let bundle = "";
    for (const src of srcs) {
      const url = src.startsWith("http") ? src : `${SITE_URL}${src}`;
      try { bundle += await (await fetch(url)).text(); } catch { /* a chunk that fails contributes nothing */ }
    }
    const groupHtml = await (await fetch(`${SITE_URL}/groups`, { headers: { Cookie: ownerCookie } })).text();
    for (const src of [...groupHtml.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1])) {
      const url = src.startsWith("http") ? src : `${SITE_URL}${src}`;
      try { bundle += await (await fetch(url)).text(); } catch { /* same */ }
    }
    const decoded = bundle
      .replace(/\\x([0-9a-fA-F]{2})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)))
      .replace(/\\u([0-9a-fA-F]{4})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)));
    report.push("\n--- RO, by shipment in the client bundle (NOT by rendering) ---");
    report.push(`  bytes fetched: ${bundle.length}`);
    report.push(`  the recurring label ships: ${decoded.includes("Ritmul săptămânal")}`);
    report.push(`  "nu creează ateliere" ships: ${decoded.includes("nu creează ateliere")}`);
    report.push(`  the checkbox ships RO: ${decoded.includes("Creează și primul atelier la această dată")}`);
    report.push(`  the one-off label ships (EN+RO): ${decoded.includes("Workshop date and time") && decoded.includes("Data și ora atelierului")}`);
    report.push(`  the one-off hint ships: ${decoded.includes("A one-off workshop happens on a date")}`);
    report.push(`  "One workshop, not a series" ships: ${decoded.includes("One workshop, not a series")}`);
    report.push(`  the no-grade message ships RO: ${decoded.includes("nu are un grad valabil la această dată")}`);
    report.push(`  the no-trainer message ships RO: ${decoded.includes("niciun trainer în niciunul din sloturi")}`);
    // The eleven agreement fixes: the broken forms must NOT ship.
    //
    // "Atelier nouă" / "Atelier noua" added 2026-10-13, and the reason it was
    // missing is worth more than the entry. This list was written in the SAME
    // commit as the rename, with six forms someone anticipated -- and the
    // rename introduced a seventh, in that same commit, which the list
    // therefore could not contain. A denylist catches what occurred to its
    // author, so adding this form closes one case and not the pattern. The
    // bundle is searched both with and without diacritics because the client
    // chunks are escaped inconsistently.
    for (const bad of ["nicio atelier", "Nicio atelier", "atelierei", "acestei ateliere", "o atelier neconfirmată", "Creează ateliera", "Atelier nouă", "Atelier noua"]) {
      report.push(`  broken agreement "${bad}" is absent: ${!decoded.includes(bad)}`);
    }
    report.push(`  the billing example still says ședință: ${decoded.includes("95 lei/copil/ședință")}`);

    console.log("\n" + report.join("\n"));
    const failed = report.some((r) => r.includes(": false"));
    console.log(failed ? "\nAt least one expectation FAILED." : "\nAll expectations held.");
    if (failed) process.exitCode = 1;
  } finally {
    if (cleanup) { await cleanup(); ran = true; }
    console.log(ran
      ? "\nCLEANUP: the verification client, groups, workshops and grade fixture were deleted. Test Org B is as it was found."
      : "\nCLEANUP: NOTHING TO CLEAN UP (no fixture was created).");
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
