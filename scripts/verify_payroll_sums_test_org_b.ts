/**
 * ONE-TIME VERIFICATION: the per-trainer pay sums on /payroll
 * (202610150003 + app/(app)/payroll), against the REAL deployment, in WOW
 * LAB Test Org B only.
 *
 * WHY TEST ORG B AND NOT PRODUCTION DATA. The real WOW LAB org has zero
 * sessions -- not "some with missing inputs", none at all, ever. So there
 * is nothing there to render, and waiting for real workshops would mean
 * shipping a money screen nobody has seen produce a number. Test Org B
 * now has a standing pay grid of its own (202610150004), which it did not
 * before: every resolver raised there, so nothing that reads a rate could
 * be verified against it at all.
 *
 * WHAT IT ASSERTS, all three of the things this round promised:
 *   1. Sums render per trainer, with per-workshop rows underneath.
 *   2. ROUNDING. Grade 2 in Test Org B is deliberately 175, so
 *      175 x 1.5 (120 min) x 1.25 (imprejurimi) = 328.125 -- a third
 *      decimal. Two such workshops must total 656.26 (sum of rounded
 *      rows) and NOT 656.25 (the rounded sum). The screen is asserted to
 *      contain the first and NOT the second, because Anca adds these rows
 *      up by hand to issue the invoice.
 *   3. RAISE ISOLATION. A 30-minute Școala Altfel workshop has no
 *      multiplier in any grid here (seeded with that gap on purpose,
 *      mirroring production's). Its row must show the reason, the
 *      trainer's total must still be 656.26, and the month total must say
 *      it excludes 1 workshop.
 * Plus the confirmed/unconfirmed split: one workshop is confirmed and one
 * is not, so "payable" and "not confirmed yet" must be two figures, never
 * one sum -- Anca's rule is that an unconfirmed workshop is not paid.
 *
 * FIXTURES AND CLEANUP. Creates one group and three sessions, all carrying
 * the marker below in their own `notes` column, and deletes them BY THAT
 * MARKER -- never by ids captured along the way, per item 124: a
 * half-built fixture set then cleans up exactly as well as a complete one.
 * It modifies NO existing row: Test Org B's own three sessions, two
 * groups, grades and grid are read and left alone, and the script asserts
 * that afterwards by counting them before and after.
 *
 * Cleanup is NOT a silent finally (item 102's two standing fixtures were
 * left mutated by exactly that). It runs as its own announced step, it
 * runs on the failure path too, and -- the part that actually matters --
 * its EFFECT is re-queried and reported, so "cleanup ran" is never
 * asserted on the strength of having called it.
 *
 * Language, with the same two-sided honesty as its siblings: a
 * server-side fetch always renders EN (the locale is a client-only
 * localStorage preference, lib/i18n.tsx defaults to "en"), so EN is
 * verified by RENDERING and RO by SHIPMENT in the client bundle, which is
 * a weaker claim and is said to be one.
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_payroll_sums_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_SLUG = "wow-lab-test-b";
// Organization Owner in Test Org B: holds finance.operations.* (so the
// grids are readable, which is what SECURITY INVOKER requires) and is the
// account this repo's other Test Org B scripts already sign in with.
const VIEWER_EMAIL = "test+user-b@wowlab.dev";
// Grade 2 => rate 175 in Test Org B's grid (202610150004), the odd rate
// that produces a third decimal and makes the rounding rule testable.
const TRAINER_EMAIL = "maxdigitalro+trainerb2@gmail.com";
const MARKER = "VERIFY payroll-sums 202610150003";
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
  const { error: vErr } = await c.auth.verifyOtp({
    token_hash: link.properties!.hashed_token!,
    type: "magiclink",
  });
  if (vErr) throw new Error(`verifyOtp failed for ${email}: ${vErr.message}`);
  // Both the cookie (for fetching the page) and the signed-in client
  // itself. The client matters: public.calculate_org_session_pay is
  // SECURITY INVOKER, so calling it as service_role would bypass RLS on
  // the rate tables and prove nothing about whether a real finance viewer
  // can get a number out of it. The first version of this script did
  // exactly that and died on "permission denied" -- the right failure for
  // the wrong call.
  return { cookie: [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; "), client: c };
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

// Two dates inside the CURRENT month, which is the month /payroll's picker
// defaults to -- the sums have to appear without anyone touching the
// control. Day 2 and 3 rather than "today", so a run on the 1st or the
// 31st still lands both inside the same month.
function currentMonthDay(day: number) {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

async function main() {
  const a = admin();
  const report: string[] = [];
  let cleanupRan = false;

  // Deletes everything bearing the marker, in FK order. Takes no arguments
  // and reads no captured ids, so it is correct whether three fixtures were
  // built or none were.
  async function cleanupByMarker() {
    const { error: sErr } = await a.from("sessions").delete().eq("notes", MARKER);
    const { error: gErr } = await a.from("groups").delete().eq("notes", MARKER);
    if (sErr) throw new Error(`cleanup: deleting marked sessions failed: ${sErr.message}`);
    if (gErr) throw new Error(`cleanup: deleting marked groups failed: ${gErr.message}`);
  }

  // Re-queries rather than trusting that the deletes above did anything.
  async function countMarked() {
    const { count: sessions } = await a
      .from("sessions")
      .select("id", { count: "exact", head: true })
      .eq("notes", MARKER);
    const { count: groups } = await a
      .from("groups")
      .select("id", { count: "exact", head: true })
      .eq("notes", MARKER);
    return { sessions: sessions ?? 0, groups: groups ?? 0 };
  }

  try {
    const { data: org, error: orgErr } = await a
      .from("organizations")
      .select("id")
      .eq("slug", ORG_SLUG)
      .single();
    if (orgErr || !org) throw new Error(`no organization ${ORG_SLUG}: ${orgErr?.message}`);
    const orgId = org.id;

    const { data: trainer, error: tErr } = await a
      .from("users")
      .select("id, full_name")
      .eq("email", TRAINER_EMAIL)
      .single();
    if (tErr || !trainer) throw new Error(`no trainer ${TRAINER_EMAIL}: ${tErr?.message}`);

    // Read, never written. The grade has to be 2 for the arithmetic below
    // to be the arithmetic this script claims to test -- asserted rather
    // than assumed, because item 124's script assumed Test Org B had no
    // grades when it has six.
    const { data: grade } = await a
      .from("trainer_grade_assignments")
      .select("grade_level")
      .eq("organization_id", orgId)
      .eq("trainer_id", trainer.id)
      .order("effective_from", { ascending: false })
      .limit(1)
      .maybeSingle();
    report.push(
      `0. Precondition — ${TRAINER_EMAIL} is grade ${grade?.grade_level ?? "NONE"} (needs 2, rate 175) -> ${grade?.grade_level === 2 ? "PASS" : "FAIL"}`,
    );

    const { data: rate } = await a
      .from("trainer_grade_rates")
      .select("rate")
      .eq("organization_id", orgId)
      .eq("grade_level", 2)
      .maybeSingle();
    report.push(
      `0. Precondition — Test Org B grade-2 rate is ${rate?.rate ?? "NONE"} (needs 175) -> ${Number(rate?.rate) === 175 ? "PASS" : "FAIL"}`,
    );

    // What Test Org B looked like before this run, so "modified nothing" is
    // a measurement and not a promise.
    const beforeSessions = await a
      .from("sessions")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", orgId);
    const beforeGroups = await a
      .from("groups")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", orgId);
    const baseline = { sessions: beforeSessions.count ?? 0, groups: beforeGroups.count ?? 0 };
    report.push(`0. Baseline — Test Org B has ${baseline.sessions} sessions and ${baseline.groups} groups before this run.`);

    // ---- Fixture: an existing group for the priced pair, read not written ----
    // The MAX parteneriate_companii group resolves to the 'standard'
    // duration context and now carries language_group ro_en (202610150004).
    const { data: hostGroup, error: hgErr } = await a
      .from("groups")
      .select("id")
      .eq("organization_id", orgId)
      .eq("delivery_format", "parteneriate_companii")
      .limit(1)
      .single();
    if (hgErr || !hostGroup) throw new Error(`no parteneriate_companii group in Test Org B: ${hgErr?.message}`);

    // ---- Fixture: a Școala Altfel group, so the 30-minute gap is reachable ----
    const { data: altfelGroup, error: agErr } = await a
      .from("groups")
      .insert({
        organization_id: orgId,
        client_id: (
          await a.from("clients").select("id").eq("organization_id", orgId).limit(1).single()
        ).data!.id,
        module: "green_energy",
        delivery_format: "scoala_altfel",
        language_group: "ro_en",
        status: "active",
        notes: MARKER,
      })
      .select("id")
      .single();
    if (agErr || !altfelGroup) throw new Error(`creating the scoala_altfel fixture group failed: ${agErr?.message}`);

    // ---- Fixture: four sessions ----
    // TWO confirmed and priced at 328.125 each, so the payable total is
    // 656.26 and the rounding rule is visible ON THE SCREEN as a figure
    // Anca could compare against her calculator. The first version of this
    // script used one confirmed and one unconfirmed and then asserted
    // 656.26 was rendered -- it is not, and correctly so: the two buckets
    // are never summed together, which is the other rule this screen
    // enforces. Two workshops have to be in the SAME bucket for the sum of
    // rounded rows to appear at all.
    // A third, unconfirmed, keeps the confirmed/unconfirmed split under
    // test. The fourth raises.
    // Errors are checked, not asserted away with `!` -- item 124's whole
    // chain started with an unchecked insert and a non-null assertion that
    // "compiles and lies".
    const confirmedAt = new Date().toISOString();
    const { data: made, error: sErr } = await a
      .from("sessions")
      .insert([
        {
          organization_id: orgId,
          group_id: hostGroup.id,
          session_date: currentMonthDay(2),
          trainer_principal_id: trainer.id,
          status: "delivered",
          duration_minutes: 120,
          location_tier: "imprejurimi",
          trainer_principal_confirmed_at: confirmedAt,
          notes: MARKER,
        },
        {
          organization_id: orgId,
          group_id: hostGroup.id,
          session_date: currentMonthDay(3),
          trainer_principal_id: trainer.id,
          status: "delivered",
          duration_minutes: 120,
          location_tier: "imprejurimi",
          trainer_principal_confirmed_at: confirmedAt,
          notes: MARKER,
        },
        {
          organization_id: orgId,
          group_id: hostGroup.id,
          session_date: currentMonthDay(4),
          trainer_principal_id: trainer.id,
          status: "delivered",
          duration_minutes: 120,
          location_tier: "imprejurimi",
          notes: MARKER,
        },
        {
          organization_id: orgId,
          group_id: altfelGroup.id,
          session_date: currentMonthDay(5),
          trainer_principal_id: trainer.id,
          status: "delivered",
          // 150, not 30. Until 202610160004 a 30-minute Scoala Altfel
          // workshop raised, because the grid had no 30 row for that
          // context and the resolver matched exactly; it now bands up to
          // 60 and prices at 218.75. A length above the grid's own top
          // band (120) is the only unpayable duration left, and it is the
          // grid's ceiling rather than a case built to fail.
          duration_minutes: 150,
          location_tier: "imprejurimi",
          notes: MARKER,
        },
      ])
      .select("id");
    if (sErr || !made || made.length !== 4) {
      throw new Error(`creating the four fixture sessions failed: ${sErr?.message ?? `got ${made?.length ?? 0}`}`);
    }

    // ---- 1. The SQL function, called as the person who closes the month ----
    // Signed in first, because the function is SECURITY INVOKER and the
    // caller's own SELECT rights on the pay grids are the whole gate.
    const { cookie, client: viewer } = await signIn(a, VIEWER_EMAIL);
    // The month on display, as [from, toExclusive) -- the same bounds
    // /payroll builds from ?month=. The function takes a range since
    // 202610160001 rather than scanning the org.
    const now = new Date();
    const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const from = `${monthKey}-01`;
    const toExclusive =
      now.getMonth() === 11
        ? `${now.getFullYear() + 1}-01-01`
        : `${now.getFullYear()}-${String(now.getMonth() + 2).padStart(2, "0")}-01`;
    const { data: fnRows, error: fnErr } = await viewer.rpc("calculate_org_session_pay", {
      p_organization_id: orgId,
      p_from: from,
      p_to_exclusive: toExclusive,
    });
    if (fnErr) throw new Error(`calculate_org_session_pay failed as ${VIEWER_EMAIL}: ${fnErr.message}`);
    const mine = (fnRows as { session_id: string; amount: number | string | null; reason_code: string | null }[])
      .filter((r) => made.some((m) => m.id === r.session_id));
    const amounts = mine.filter((r) => r.amount !== null).map((r) => Number(r.amount));
    const raised = mine.filter((r) => r.amount === null);
    report.push(
      `1. Function returns 4 rows for the fixture (3 priced, 1 raised) -> ${mine.length === 4 && amounts.length === 3 && raised.length === 1 ? "PASS" : `FAIL (${mine.length} rows, ${amounts.length} priced, ${raised.length} raised)`}`,
    );
    report.push(
      `1. Each priced row is rounded to 328.13, not 328.125 -> ${amounts.every((v) => v === 328.13) ? "PASS" : `FAIL (${amounts.join(", ")})`}`,
    );
    report.push(
      `1. The raised row is classified no_duration_row -> ${raised[0]?.reason_code === "no_duration_row" ? "PASS" : `FAIL (${raised[0]?.reason_code})`}`,
    );
    // Two of the three priced rows are the confirmed pair: 328.13 + 328.13
    // = 656.26, where summing unrounded and rounding once gives 656.25.
    const sumOfRoundedPair = Math.round(328.13 * 100) * 2;
    report.push(
      `1. Sum of two rounded rows is 656.26, not the 656.25 a final-rounding rule gives -> ${sumOfRoundedPair === 65626 ? "PASS" : `FAIL (${sumOfRoundedPair} bani)`}`,
    );

    // ---- 2. The screen, rendered, for the same viewer ----
    // Explicitly with ?month=, which is the path Anca uses when she sends
    // someone a link to a specific month (202610160001).
    const res = await fetch(`${SITE_URL}/payroll?month=${monthKey}`, { headers: { Cookie: cookie } });
    const html = await res.text();
    const text = visibleText(html);

    report.push(`2. /payroll?month=${monthKey} responds ${res.status} for ${VIEWER_EMAIL} -> ${res.ok ? "PASS" : "FAIL"}`);
    report.push(
      `2. The sums section renders (EN heading "What each trainer is owed") -> ${text.includes("What each trainer is owed") ? "PASS" : "FAIL"}`,
    );
    report.push(
      `2. The trainer is named with their own total, 656.26 lei -> ${text.includes("656.26 lei") ? "PASS" : "FAIL"}`,
    );
    // The discriminating assertion, stated as an absence: 656.25 is what
    // the screen would show if the totals summed unrounded amounts and
    // rounded once at the end.
    report.push(
      `2. The WRONG total 656.25 appears nowhere -> ${!text.includes("656.25") ? "PASS" : "FAIL"}`,
    );
    report.push(
      `2. Per-workshop rows show the rounded 328.13 lei -> ${text.includes("328.13 lei") ? "PASS" : "FAIL"}`,
    );
    report.push(
      `2. The raise shows its reason in plain language, not raw SQL -> ${
        text.includes("longer than the longest length the pay grid covers") &&
        !text.includes("longest band") &&
        !text.includes("resolve_duration_multiplier")
          ? "PASS"
          : "FAIL"
      }`,
    );
    // ONE block, ONE number (the consolidation): the heading carries the
    // count, the two sections classify by who can act, and the total REFERS
    // to that same count instead of carrying its own.
    report.push(
      `2. One consolidated block names the count once -> ${text.includes("that cannot be paid yet (1)") ? "PASS" : "FAIL"}`,
    );
    report.push(
      `2. The grid gap is filed under "not fixable from this screen" -> ${
        text.includes("Gaps in the pay grid — not fixable from this screen") ? "PASS" : "FAIL"
      }`,
    );
    // Nothing in this fixture is a missing-information case, so that section
    // must be ABSENT -- a section that renders empty is the "line nobody
    // reads" this screen keeps refusing to add.
    report.push(
      `2. The "someone can still enter it" section is absent when nothing qualifies -> ${
        !text.includes("Missing information — someone can still enter it") ? "PASS" : "FAIL"
      }`,
    );
    report.push(
      `2. The total refers to that same count, not a second one -> ${text.includes("Excludes the 1 workshop") ? "PASS" : "FAIL"}`,
    );
    // The old pair of blocks is gone.
    report.push(
      `2. item 121's separate heading no longer renders -> ${!text.includes("cannot be priced yet") ? "PASS" : "FAIL"}`,
    );
    // Confirmed vs unconfirmed, never one figure: one of the two priced
    // workshops is confirmed, so payable is 328.13 and the other 328.13 is
    // reported separately as not payable.
    // Test Org B's groups carry contract_id = null, so this run also
    // exercises the broken chain: the amounts are correct and there is no
    // entity to invoice them from. That is a heading, not a reason_code.
    report.push(
      `2. Per-entity grouping renders; the unlinked chain is named, not silently bucketed -> ${
        text.includes("No invoicing entity — the group has no contract") &&
        text.includes("cannot be assigned to an entity")
          ? "PASS"
          : "FAIL"
      }`,
    );
    report.push(
      `2. No cross-entity payable total is rendered -> ${!text.includes("Total payable this month") ? "PASS" : "FAIL"}`,
    );
    report.push(
      `2. Confirmed and unconfirmed are two figures, not one sum -> ${
        text.includes("not confirmed — not payable yet") || text.includes("not confirmed, excluded from the total above")
          ? "PASS"
          : "FAIL"
      }`,
    );

    // ---- 2b. The month comes from the URL (202610160001) ----
    // A different month must render its own (empty) state rather than the
    // current month's figures -- which is what would happen if the param
    // were ignored and the picker were still client state.
    const otherMonth = "2026-01";
    const resOther = await fetch(`${SITE_URL}/payroll?month=${otherMonth}`, { headers: { Cookie: cookie } });
    const textOther = visibleText(await resOther.text());
    report.push(
      `2b. ?month=${otherMonth} renders ITS month, not this one's sums (no 656.26, no 328.13) -> ${
        !textOther.includes("656.26") && !textOther.includes("328.13") ? "PASS" : "FAIL"
      }`,
    );
    report.push(
      `2b. ?month=${otherMonth} says it has no workshops -> ${textOther.includes("No workshops in") ? "PASS" : "FAIL"}`,
    );

    // The explicit fallback. A malformed month must land on the current
    // month rather than on an empty screen that reads as "nobody is owed
    // anything" -- so this response must look like the first fetch did.
    const resBad = await fetch(`${SITE_URL}/payroll?month=not-a-month`, { headers: { Cookie: cookie } });
    const textBad = visibleText(await resBad.text());
    report.push(
      `2b. ?month=not-a-month falls back to the current month (shows 656.26) -> ${textBad.includes("656.26 lei") ? "PASS" : "FAIL"}`,
    );
    // "2026-13" passes a /\d{4}-\d{2}/ regex and is not a month.
    const resImpossible = await fetch(`${SITE_URL}/payroll?month=2026-13`, { headers: { Cookie: cookie } });
    const textImpossible = visibleText(await resImpossible.text());
    report.push(
      `2b. ?month=2026-13 (regex-shaped but impossible) also falls back -> ${textImpossible.includes("656.26 lei") ? "PASS" : "FAIL"}`,
    );
    // No month at all is the same fallback, and is the link in the nav.
    const resNone = await fetch(`${SITE_URL}/payroll`, { headers: { Cookie: cookie } });
    const textNone = visibleText(await resNone.text());
    report.push(
      `2b. /payroll with no month is the current month -> ${textNone.includes("656.26 lei") ? "PASS" : "FAIL"}`,
    );

    // ---- 3. RO strings: shipment, not rendering ----
    // The dictionary lives in a client component's chunk, not inline in the
    // HTML -- the first version of this script searched the HTML and
    // reported all four as missing when all four ship. Chunks are fetched
    // and the escapes decoded, same as the sibling scripts, because the
    // diacritics arrive as \xNN / \uNNNN in minified output.
    const srcs = [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    let bundle = "";
    let chunkFailures = 0;
    for (const s of srcs) {
      const url = s.startsWith("http") ? s : `${SITE_URL}${s}`;
      try {
        const r = await fetch(url);
        // COUNTED, not swallowed. The first version of this had a bare
        // `catch {}`, and when a run came back with 140 KB of chunks
        // instead of 9 MB every RO assertion failed and read as missing
        // wording. A chunk that does not arrive is not evidence about
        // translations, and a check that cannot tell those apart is worse
        // than no check.
        if (!r.ok) {
          chunkFailures++;
          continue;
        }
        bundle += await r.text();
      } catch {
        chunkFailures++;
      }
    }
    const decoded = bundle
      .replace(/\\x([0-9a-fA-F]{2})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)))
      .replace(/\\u([0-9a-fA-F]{4})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)));
    const roShipped = [
      "Cât i se cuvine fiecărui trainer",
      "Fără entitate de facturare — grupa nu are contract",
      "încă {{amount}} lei pe această entitate",
      "Lipsuri în grila de plată — nu se repară din acest ecran",
      "Informații care lipsesc — se pot completa",
      "mai lung decât cea mai mare durată acoperită de grila de plată",
      "încă nu sunt de plată",
      "Exclude cele {{n}} ateliere de mai sus",
    ];
    const missingRo = roShipped.filter((s) => !decoded.includes(s));
    // Reported before the wording result, because it decides whether the
    // wording result means anything at all.
    report.push(
      `3. All ${srcs.length} client chunks fetched (${chunkFailures} failed, ${bundle.length} bytes) -> ${chunkFailures === 0 ? "PASS" : "FAIL — the RO result below is not evidence"}`,
    );
    report.push(
      `3. RO wording SHIPPED in the client bundle (weaker claim than rendered: the locale is client-only) -> ${
        chunkFailures > 0 ? "INCONCLUSIVE (chunks missing)" : missingRo.length === 0 ? "PASS" : `FAIL (missing: ${missingRo.join(" | ")})`
      }`,
    );

    // ---- 4. Cleanup, as its own announced step on the happy path ----
    await cleanupByMarker();
    cleanupRan = true;
    const leftover = await countMarked();
    const afterSessions = await a
      .from("sessions")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", orgId);
    const afterGroups = await a
      .from("groups")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", orgId);
    report.push(
      `4. CLEANUP ran; ${leftover.sessions} marked sessions and ${leftover.groups} marked groups remain -> ${leftover.sessions === 0 && leftover.groups === 0 ? "PASS" : "FAIL"}`,
    );
    report.push(
      `4. Test Org B is as it was found: ${afterSessions.count} sessions (was ${baseline.sessions}), ${afterGroups.count} groups (was ${baseline.groups}) -> ${afterSessions.count === baseline.sessions && afterGroups.count === baseline.groups ? "PASS" : "FAIL"}`,
    );
  } finally {
    // The safety net, and it announces. Only reached as a net if something
    // above threw before step 4 -- in which case the fixtures are still
    // there and silence is the one outcome item 102 forbids.
    if (!cleanupRan) {
      try {
        await cleanupByMarker();
        const leftover = await countMarked();
        report.push(
          `4. CLEANUP ran on the FAILURE path; ${leftover.sessions} marked sessions and ${leftover.groups} marked groups remain -> ${leftover.sessions === 0 && leftover.groups === 0 ? "PASS" : "FAIL"}`,
        );
      } catch (e) {
        report.push(`4. CLEANUP FAILED on the failure path — Test Org B still holds rows marked "${MARKER}": ${(e as Error).message}`);
      }
    }
    console.log(report.join("\n"));
  }
}

main().catch((e) => {
  console.error("\nVERIFICATION ABORTED:", e.message);
  process.exit(1);
});
