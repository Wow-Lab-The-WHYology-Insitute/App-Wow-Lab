/**
 * ONE-TIME INVESTIGATION, not a repeatable pattern. Empirically tests
 * whether an authenticated trainer can bypass confirmSessionAttendance's
 * own column-narrowing logic by issuing a raw PATCH directly against
 * PostgREST, using their own real session access_token (the same one
 * @supabase/ssr stores in a non-httpOnly cookie, per its own
 * DEFAULT_COOKIE_OPTIONS) and the public anon key.
 *
 * Fixture: wow-lab-test-b, a fresh disposable client/group/session with
 * trainerb1 as principal and trainerb2 as secundar. Signs in as
 * trainerb1 (the REAL magic-link + verifyOtp flow, same access_token
 * shape a real browser session would have), then attempts to PATCH
 * trainer_secundar_confirmed_at directly -- a column
 * confirmSessionAttendance would NEVER let trainerb1 (the principal)
 * touch.
 *
 * Run: npx tsx --env-file=.env.local scripts/investigate_direct_postgrest_write.ts
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function signInAndGetAccessToken(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error: linkErr } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (linkErr || !link) throw new Error(`generateLink failed for ${email}: ${linkErr?.message}`);
  const tokenHash = link.properties?.hashed_token;
  if (!tokenHash) throw new Error(`No hashed_token for ${email}`);

  // Real @supabase/ssr client, real cookie jar -- exactly the mechanism
  // this app's own middleware.ts/server.ts use. httpOnly is NOT set here
  // (this app never overrides it) -- @supabase/ssr's own
  // DEFAULT_COOKIE_OPTIONS sets httpOnly: false, confirmed by reading
  // node_modules/@supabase/ssr/src/utils/constants.ts directly.
  const cookieStore = new Map<string, { value: string; options: Record<string, unknown> }>();
  const authClient = createServerClient(SUPABASE_URL, ANON_KEY, {
    cookies: {
      getAll: () => [...cookieStore.entries()].map(([name, { value }]) => ({ name, value })),
      setAll: (toSet: { name: string; value: string; options: Record<string, unknown> }[]) => {
        for (const { name, value, options } of toSet) {
          if (value) cookieStore.set(name, { value, options });
          else cookieStore.delete(name);
        }
      },
    },
  });
  const { data: verifyData, error: verifyErr } = await authClient.auth.verifyOtp({ token_hash: tokenHash, type: "magiclink" });
  if (verifyErr || !verifyData.session) throw new Error(`verifyOtp failed for ${email}: ${verifyErr?.message}`);

  // Report the cookie's own httpOnly flag, as actually set for this real
  // session -- not assumed from the library default alone.
  const authCookie = [...cookieStore.entries()].find(([name]) => name.includes("auth-token"));
  const httpOnlyFlag = authCookie ? (authCookie[1].options as { httpOnly?: boolean }).httpOnly : undefined;

  return { accessToken: verifyData.session.access_token, cookieHttpOnly: httpOnlyFlag, cookieNames: [...cookieStore.keys()] };
}

async function main() {
  const a = admin();
  const report: string[] = [];

  const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
  if (!org) throw new Error("Org not found");

  const { data: principal } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
  const { data: secundar } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb2@gmail.com").single();
  if (!principal || !secundar) throw new Error("Trainer fixtures not found");

  const { data: client } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: "DRYRUN-VERIFY direct-postgrest-write client", client_type: "corporate" })
    .select("id")
    .single();
  const { data: group } = await a
    .from("groups")
    .insert({ organization_id: org.id, client_id: client!.id, module: "gaga", delivery_format: "wow_lab_party" })
    .select("id")
    .single();
  const { data: session } = await a
    .from("sessions")
    .insert({
      organization_id: org.id,
      group_id: group!.id,
      session_date: new Date().toISOString().slice(0, 10),
      trainer_principal_id: principal.id,
      trainer_secundar_id: secundar.id,
      status: "planned",
    })
    .select("id")
    .single();
  if (!session) throw new Error("Session insert failed");

  console.log(`Fixture created: client=${client!.id} group=${group!.id} session=${session.id}`);
  console.log(`Principal (signing in): maxdigitalro+trainerb1@gmail.com (${principal.id})`);
  console.log(`Secundar (NOT signing in, being written to): maxdigitalro+trainerb2@gmail.com (${secundar.id})\n`);

  try {
    // ---- (a) part 1: sign in as the REAL app flow would, inspect the actual cookie ----
    const { accessToken, cookieHttpOnly, cookieNames } = await signInAndGetAccessToken(a, "maxdigitalro+trainerb1@gmail.com");
    report.push(`1. Anon key exposed to the browser: YES (bundled as NEXT_PUBLIC_SUPABASE_ANON_KEY, present in every page's JS/network traffic by Next.js's own NEXT_PUBLIC_ convention) -- confirmed by reading lib/supabase/client.ts and the build-time env convention, not assumed.`);
    report.push(`2. Session cookie(s) actually set for this real sign-in: ${cookieNames.join(", ")}`);
    report.push(`3. That cookie's httpOnly flag, as actually set (not the library default alone): ${cookieHttpOnly === undefined ? "flag absent from options (defaults to false per Set-Cookie semantics)" : cookieHttpOnly} -- ${cookieHttpOnly ? "NOT readable by client-side JS" : "READABLE by client-side JS (document.cookie)"}`);

    // ---- (a) part 2: raw PATCH to PostgREST, bypassing confirmSessionAttendance entirely ----
    const forbiddenPatch = { trainer_secundar_confirmed_at: new Date().toISOString() };
    const res = await fetch(`${SUPABASE_URL}/rest/v1/sessions?id=eq.${session.id}`, {
      method: "PATCH",
      headers: {
        apikey: ANON_KEY,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        Prefer: "return=representation",
      },
      body: JSON.stringify(forbiddenPatch),
    });
    const body = await res.text();
    report.push(`\n4. Raw PATCH /rest/v1/sessions?id=eq.${session.id} as the PRINCIPAL, setting trainer_secundar_confirmed_at (the SECUNDAR's own slot -- confirmSessionAttendance would never let the principal touch this column):`);
    report.push(`   HTTP status: ${res.status}`);
    report.push(`   Body: ${body}`);

    // Confirm server-side what actually landed.
    const { data: after } = await a.from("sessions").select("trainer_principal_confirmed_at, trainer_secundar_confirmed_at").eq("id", session.id).single();
    report.push(`\n5. Row state after the raw PATCH, read via service role (ground truth): trainer_principal_confirmed_at=${after?.trainer_principal_confirmed_at}, trainer_secundar_confirmed_at=${after?.trainer_secundar_confirmed_at}`);
    report.push(res.status >= 200 && res.status < 300 && after?.trainer_secundar_confirmed_at
      ? "   => THE RAW PATCH SUCCEEDED. The principal wrote the secundar's confirmation timestamp directly, bypassing confirmSessionAttendance's column restriction entirely."
      : "   => The raw PATCH did NOT take effect (rejected or silently matched 0 rows).");

    console.log(report.join("\n"));
  } finally {
    await a.from("sessions").delete().eq("id", session.id);
    await a.from("groups").delete().eq("id", group!.id);
    await a.from("clients").delete().eq("id", client!.id);
    console.log("\nFixture cleaned up (session, group, client deleted).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
