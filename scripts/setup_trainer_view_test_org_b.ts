/**
 * Sets up a persistent, visible trainer-view fixture in wow-lab-test-b for
 * a human walkthrough (Mihai clicking a real magic link on app.wowlab.ro),
 * NOT a self-cleaning verification script -- the session this creates is
 * meant to stay in place.
 *
 * Creates a session on the existing "MAX" group (client MAX, module
 * green_energy) via the real addSession Server Action, called as the
 * owner-b fixture through the actual Next.js wire protocol -- same
 * methodology as verify_item91_write_paths_through_app.ts. Then generates
 * a real magic-link token_hash for Test Trainer B1 and prints the
 * /auth/callback URL for a human to click (this script never calls
 * verifyOtp itself for B1 -- that's the whole point, Mihai does it).
 *
 * Run: npx tsx --env-file=.env.local scripts/setup_trainer_view_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";

const ACTION_IDS = {
  addSession: "7f822372abe1d9258785ff62d822a4b93cb0404bcf",
};

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

async function callAction(pagePath: string, actionName: keyof typeof ACTION_IDS, args: unknown[], cookieHeader: string) {
  const res = await fetch(`${SITE_URL}${pagePath}`, {
    method: "POST",
    headers: {
      Cookie: cookieHeader,
      "Next-Action": ACTION_IDS[actionName],
      Accept: "text/x-component",
      "Content-Type": "text/plain;charset=UTF-8",
    },
    body: JSON.stringify(args),
  });
  const text = await res.text();
  return { status: res.status, text };
}

async function main() {
  const a = admin();

  const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
  const { data: group } = await a.from("groups").select("id, delivery_format").eq("organization_id", org!.id).limit(1).single();
  const { data: b1 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
  const { data: b2 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb2@gmail.com").single();

  const ownerCookie = await signIn(a, "test+user-b@wowlab.dev");
  const sessionDate = "2026-09-23";

  const r = await callAction(
    `/groups/${group!.id}`,
    "addSession",
    [org!.id, group!.id, sessionDate, b1!.id, b2!.id, "planned", "", "", "", "", ""],
    ownerCookie,
  );
  console.log(`addSession: HTTP ${r.status}`);

  const { data: created } = await a
    .from("sessions")
    .select("id, session_date, trainer_principal_id, trainer_secundar_id, status")
    .eq("group_id", group!.id)
    .eq("session_date", sessionDate)
    .eq("trainer_principal_id", b1!.id)
    .eq("trainer_secundar_id", b2!.id)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!created) {
    console.log("FAIL: session did not land after addSession -- response body follows:\n" + r.text);
    process.exit(1);
  }
  console.log(`Session landed: id=${created.id}, date=${created.session_date}, principal=${created.trainer_principal_id === b1!.id ? "B1" : "?"}, secundar=${created.trainer_secundar_id === b2!.id ? "B2" : "?"}, status=${created.status}`);

  // Real magic-link token for B1 -- Mihai clicks this himself, this script
  // never calls verifyOtp for B1.
  const { data: b1Link, error: linkErr } = await a.auth.admin.generateLink({ type: "magiclink", email: "maxdigitalro+trainerb1@gmail.com" });
  if (linkErr || !b1Link) throw new Error(`generateLink failed for B1: ${linkErr?.message}`);
  const callbackUrl = `${SITE_URL}/auth/callback?token_hash=${b1Link.properties!.hashed_token}&type=magiclink&next=${encodeURIComponent("/groups")}`;

  console.log(`\nGroup detail URL (for reference): ${SITE_URL}/groups/${group!.id}`);
  console.log(`\nB1 magic link (valid 24h from now, single use):\n${callbackUrl}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
