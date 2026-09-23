/**
 * ONE-OFF: re-extracts current Next.js Server Action ids from the live
 * deployed bundle (build-specific hex ids change on every redeploy).
 * Run before reusing verify_item91_write_paths_through_app.ts or any
 * script that hardcodes ACTION_IDS.
 *
 * Run: npx tsx --env-file=.env.local scripts/extract_fresh_action_ids.ts
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

async function extractActionIdsFromPage(pageUrl: string, cookieHeader: string, names: string[]) {
  const res = await fetch(pageUrl, { headers: { Cookie: cookieHeader } });
  const html = await res.text();
  const chunkPaths = [...html.matchAll(/"(\/_next\/static\/chunks\/[^"]+\.js)"/g)].map((m) => m[1]);
  const uniqueChunks = [...new Set(chunkPaths)];
  const found: Record<string, string> = {};
  for (const chunkPath of uniqueChunks) {
    const chunkRes = await fetch(`${SITE_URL}${chunkPath}`);
    const chunkText = await chunkRes.text();
    for (const name of names) {
      if (found[name]) continue;
      const re = new RegExp(`createServerReference\\)\\("([0-9a-f]{20,})"[^)]*?,\\s*"${name}"`);
      const m = chunkText.match(re);
      if (m) found[name] = m[1];
    }
  }
  return found;
}

async function main() {
  const a = admin();
  const cookie = await signIn(a, "test+user-b@wowlab.dev");

  const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
  const { data: group } = await a.from("groups").select("id").eq("organization_id", org!.id).limit(1).single();
  const { data: legalEntity } = await a.from("legal_entities").select("id").eq("organization_id", org!.id).limit(1).single();
  const { data: client } = await a.from("clients").select("id").eq("organization_id", org!.id).limit(1).single();

  const groupIds = await extractActionIdsFromPage(
    `${SITE_URL}/groups/${group!.id}`,
    cookie,
    ["addSession", "updateSessionAllocation", "updateSessionAttendance", "confirmSessionAttendance", "correctSessionConfirmation", "updateGroup"],
  );

  // Temp contract just to load a /contracts/[id] page and extract updateContract's id.
  const { data: contract } = await a.from("contracts").insert({ organization_id: org!.id, client_id: client!.id, legal_entity_id: legalEntity!.id, exit_number: "EXTRACT-IDS-TEMP", contract_type: "one_off_event", status: "signed" }).select("id").single();
  const contractIds = await extractActionIdsFromPage(`${SITE_URL}/contracts/${contract!.id}`, cookie, ["updateContract"]);
  await a.from("contracts").delete().eq("id", contract!.id);

  console.log(JSON.stringify({ ...groupIds, ...contractIds }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
