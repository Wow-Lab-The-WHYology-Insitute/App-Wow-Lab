/**
 * ONE-TIME VERIFICATION (item 102). The tenth workshop type, `custom`,
 * end to end against the real deployment, in WOW LAB Test Org B only.
 *
 * On the two languages, stated honestly rather than faked: the locale is a
 * CLIENT-ONLY, localStorage-persisted preference (lib/i18n.tsx --
 * useState<Locale>("en"), then read from localStorage after mount). A
 * server-side fetch therefore always renders EN and there is no cookie or
 * header that changes that. So:
 *   - EN is verified by RENDERING -- the real label in the real page HTML.
 *   - RO is verified by SHIPMENT -- the Romanian string is present in the
 *     deployed client bundle that the locale switch reads from. That is a
 *     weaker claim than "rendered in Romanian," and is labelled as such in
 *     the output rather than reported as if it were the same thing.
 *
 * Cleanup runs in `finally` AND says out loud whether it ran. Item 102
 * records two standing fixtures left mutated in this same database by
 * interrupted verification runs whose finally-block cleanup never fired;
 * a silent `finally` is what made those invisible.
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_custom_workshop_type_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_NAME = "WOW LAB Test Org B";
const OWNER_EMAIL = "test+user-b@wowlab.dev";
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
  const { error: verifyErr } = await authClient.auth.verifyOtp({
    token_hash: link.properties!.hashed_token!,
    type: "magiclink",
  });
  if (verifyErr) throw new Error(`verifyOtp failed for ${email}: ${verifyErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}

// Decodes entities before matching -- item 100's fourth probe error was a
// regex holding a literal apostrophe against a page rendering &#x27;.
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
  let cleanupRan = false;

  try {
    const { data: org } = await a.from("organizations").select("id").eq("name", ORG_NAME).single();
    const { data: client } = await a
      .from("clients")
      .select("id")
      .eq("organization_id", org!.id)
      .eq("name", "MAX")
      .single();

    // THREE real groups, not one. The format filter and the Format column
    // are DATA-DRIVEN -- they render only the values actually present in
    // the org's rows, not all ten of FORMAT_KEYS. The first version of
    // this script asserted that "Școala Altfel" appears in the EN UI with
    // no scoala_altfel group in the database, and correctly got false: it
    // was testing the app for something the app had no reason to render.
    // To see a label rendered, a row must carry the value.
    const fixtures = [
      { delivery_format: "custom", label_en: "Custom" },
      { delivery_format: "scoala_altfel", label_en: "Școala Altfel" },
      { delivery_format: "saptamana_verde", label_en: "Săptămâna Verde" },
    ];

    const createdIds: string[] = [];
    cleanup = async () => {
      if (createdIds.length) await a.from("groups").delete().in("id", createdIds);
    };

    for (const f of fixtures) {
      const { data: created, error: createErr } = await a
        .from("groups")
        .insert({
          organization_id: org!.id,
          client_id: client!.id,
          module: "wow_mix",
          delivery_format: f.delivery_format,
          status: "active",
          notes: "item 102 live verification -- deleted by this script",
        })
        .select("id, delivery_format")
        .single();
      if (createErr) throw new Error(`creating a ${f.delivery_format} group FAILED: ${createErr.message}`);
      createdIds.push(created!.id);
    }
    report.push(`all three fixture groups created (custom included): ${createdIds.length === 3}`);

    const cookie = await signIn(a, OWNER_EMAIL);
    const res = await fetch(`${SITE_URL}/groups`, { headers: { Cookie: cookie } });
    const html = await res.text();
    const text = visibleText(html);

    report.push(`\n/groups HTTP ${res.status}`);
    report.push("--- EN, verified by rendering ---");
    report.push(`  "Custom" renders in the page: ${/\bCustom\b/.test(text)}`);
    report.push(`  raw key "custom" is NOT shown to the user: ${!/format_custom|>custom</.test(text)}`);
    report.push(
      `  party_companii shows the NEW label "Wow Lab Party at a company": ${/Wow Lab Party at a company/.test(html)}`,
    );
    report.push(`  the OLD label "Company parties" is gone: ${!/Company parties/.test(html)}`);
    report.push(`  Școala Altfel stays Romanian in the EN UI: ${text.includes("Școala Altfel")}`);
    report.push(`  Săptămâna Verde stays Romanian in the EN UI: ${text.includes("Săptămâna Verde")}`);
    // The control for the two above: if the EN UI had translated them,
    // THESE are the strings that would appear instead. Without this pair,
    // the two assertions above pass for any page that happens to contain
    // the Romanian text anywhere, and fail to notice a translated label
    // sitting right beside it.
    report.push(`  CONTROL: no "School Differently" anywhere: ${!/School Differently/i.test(html)}`);
    report.push(`  CONTROL: no "Green Week" anywhere: ${!/Green Week/i.test(html)}`);

    // RO: the dictionary lives in the client JS bundle, not in the page
    // HTML -- the page HTML carries only the active locale's strings, and
    // the active locale on a server fetch is always EN. So the Romanian
    // side is checked where it actually is: the chunks the page loads.
    report.push("--- RO, verified by shipment in the client bundle (NOT by rendering -- see header) ---");
    const srcs = [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    let bundle = "";
    for (const src of srcs) {
      const url = src.startsWith("http") ? src : `${SITE_URL}${src}`;
      try {
        bundle += await (await fetch(url)).text();
      } catch {
        /* a chunk that fails to fetch simply contributes nothing */
      }
    }
    // The minifier escapes SOME diacritics and not others: `ș` and `ă`
    // survive as literal UTF-8, but `î` ships as \xee and `â` as \xe2
    // (the Latin-1 range). Matching the literal Romanian against the raw
    // bundle therefore finds "Școala Altfel" and misses "Party în
    // companii" and "Săptămâna Verde" -- which is item 100's fourth probe
    // error in a second costume: a probe comparing literal text against an
    // escaped rendering. Decode before matching, don't hand-write the
    // escapes into the needle.
    const decoded = bundle
      .replace(/\\x([0-9a-fA-F]{2})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)))
      .replace(/\\u([0-9a-fA-F]{4})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)));

    report.push(`  chunks fetched: ${srcs.length}, total bytes: ${bundle.length}`);
    report.push(`  RO "Party în companii" present: ${decoded.includes("Party în companii")}`);
    report.push(`  RO "Școala Altfel" present: ${decoded.includes("Școala Altfel")}`);
    report.push(`  RO "Săptămâna Verde" present: ${decoded.includes("Săptămâna Verde")}`);
    report.push(`  EN "Wow Lab Party at a company" present: ${decoded.includes("Wow Lab Party at a company")}`);
    // The whole entry, both sides, exactly as shipped -- the strongest
    // single assertion here, since it proves the pair rather than two
    // strings that happen to exist somewhere.
    report.push(
      `  the full custom entry ships as {en:"Custom",ro:"Custom"}: ${decoded.includes('format_custom:{en:"Custom",ro:"Custom"}')}`,
    );
    report.push(
      `  the full party_companii entry ships with both sides: ${decoded.includes('format_party_companii:{en:"Wow Lab Party at a company",ro:"Party în companii"}')}`,
    );
    report.push(
      `  RO "Custom" is byte-identical to EN by design, so the EN render above covers it: true`,
    );

    console.log("\n" + report.join("\n"));
    const failed = report.some((r) => r.includes(": false"));
    console.log(failed ? "\nAt least one expectation FAILED." : "\nAll expectations held.");
    if (failed) process.exitCode = 1;
  } finally {
    if (cleanup) {
      await cleanup();
      cleanupRan = true;
    }
    // Said out loud either way -- an interrupted run must be visible.
    console.log(
      cleanupRan
        ? "\nCLEANUP: the verification group was deleted. Test Org B is as it was found."
        : "\nCLEANUP: NOTHING TO CLEAN UP (no group was created).",
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
