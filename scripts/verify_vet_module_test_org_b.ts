/**
 * ONE-TIME VERIFICATION (item 105). Module 14, `vet`, end to end against the
 * real deployment, in WOW LAB Test Org B only.
 *
 * On the two languages, stated honestly rather than faked: the locale is a
 * CLIENT-ONLY, localStorage-persisted preference (lib/i18n.tsx --
 * useState<Locale>("en"), then localStorage after mount). A server-side fetch
 * always renders EN and no cookie or header changes that. So:
 *   - EN is verified by RENDERING -- the real label in the real page HTML.
 *   - RO is verified by SHIPMENT -- the dictionary entry present in the
 *     deployed client bundle the locale switch reads from. That is a weaker
 *     claim and is labelled as such, not reported as if it were the same.
 * For this label the two sides are byte-identical by design, so the strongest
 * single assertion is the whole entry shipping with BOTH sides present.
 *
 * The module FILTER is data-driven (moduleOptions = new Set(groups.map(...))),
 * so a vet group must exist for the label to render at all -- the first run of
 * the custom-workshop-type verification failed for exactly this reason.
 *
 * Cleanup runs in `finally` AND says out loud whether it ran (item 102: two
 * standing fixtures were left mutated by runs whose silent finally never
 * fired).
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_vet_module_test_org_b.ts
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
    const { data: org } = await a.from("organizations").select("id").eq("name", ORG_NAME).single();
    const { data: client } = await a.from("clients").select("id").eq("organization_id", org!.id).eq("name", "MAX").single();

    const { data: created, error: cErr } = await a
      .from("groups")
      .insert({
        organization_id: org!.id,
        client_id: client!.id,
        module: "vet",
        delivery_format: "scoli_private_recurente",
        status: "active",
        notes: "item 105 live verification -- deleted by this script",
      })
      .select("id, module")
      .single();
    if (cErr) throw new Error(`creating a vet group FAILED: ${cErr.message}`);
    cleanup = async () => { await a.from("groups").delete().eq("id", created!.id); };
    report.push(`group created with module=vet: ${created!.module === "vet"}`);

    const cookie = await signIn(a, OWNER_EMAIL);
    const res = await fetch(`${SITE_URL}/groups`, { headers: { Cookie: cookie } });
    const html = await res.text();
    const text = visibleText(html);

    report.push(`\n/groups HTTP ${res.status}`);
    report.push("--- EN, verified by rendering ---");
    report.push(`  "I Wanna Be a Vet" renders: ${text.includes("I Wanna Be a Vet")}`);
    report.push(`  raw key "vet" is NOT shown to the user: ${!/module_vet|>vet</.test(html)}`);
    report.push(`  the sheet's shouty "VET" form is absent: ${!/I want to be a VET/.test(html)}`);
    report.push(`  CONTROL: sibling "I Wanna Be a Doctor" still renders: ${text.includes("I Wanna Be a Doctor")}`);

    report.push("--- RO, verified by shipment in the client bundle (NOT by rendering) ---");
    const srcs = [...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map((m) => m[1]);
    let bundle = "";
    for (const s of srcs) {
      const url = s.startsWith("http") ? s : `${SITE_URL}${s}`;
      try { bundle += await (await fetch(url)).text(); } catch { /* a chunk that fails contributes nothing */ }
    }
    const decoded = bundle
      .replace(/\\x([0-9a-fA-F]{2})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)))
      .replace(/\\u([0-9a-fA-F]{4})/g, (_m, h) => String.fromCharCode(parseInt(h, 16)));
    report.push(`  chunks fetched: ${srcs.length}, bytes: ${bundle.length}`);
    report.push(
      `  the full entry ships with BOTH sides: ${decoded.includes('module_vet:{en:"I Wanna Be a Vet",ro:"I Wanna Be a Vet"}')}`,
    );
    report.push(`  "vet" is in the create-form key list: ${/"doctor","vet"|"doctor",\s*"vet"/.test(decoded)}`);

    console.log("\n" + report.join("\n"));
    const failed = report.some((r) => r.includes(": false"));
    console.log(failed ? "\nAt least one expectation FAILED." : "\nAll expectations held.");
    if (failed) process.exitCode = 1;
  } finally {
    if (cleanup) { await cleanup(); ran = true; }
    console.log(ran
      ? "\nCLEANUP: the verification group was deleted. Test Org B is as it was found."
      : "\nCLEANUP: NOTHING TO CLEAN UP (no group was created).");
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
