/**
 * ONE-TIME VERIFICATION — not a repeatable pattern, not committed test
 * infra. Verifies OPEN_ITEMS.md item 66's fix (202609170001) actually
 * renders on /groups/[id] for a real trainer session, not just that the
 * RLS policy returns the right rows in isolation (already proven by
 * scripts/verify_clients_mywork_visibility.sql).
 *
 * No headless browser is available in this environment. Equivalent
 * verification: sign in as a real fixture trainer via a real magiclink
 * verifyOtp (same mechanism /auth/callback uses), carry the resulting
 * @supabase/ssr session cookie into a plain HTTP GET of the actual page,
 * and read the initial server-rendered HTML -- GroupHeader/
 * GroupInfoSection are "use client" but Next.js still SSRs them on first
 * load, so the real rendered text is present in this response, not just
 * in a post-hydration DOM a screenshot would show.
 *
 * Parameterized (env vars, defaults below match the original Test Org B
 * run) so the identical check can also be pointed at the real WOW LAB org
 * and https://app.wowlab.ro after deploy, using a `test+` fixture account
 * there (test+trainer-a@wowlab.dev) rather than any real named teammate.
 *
 * Creates one client + one group + one session, all prefixed DRYRUN-VERIFY,
 * tied to the trainer as trainer_principal_id. Deletes all three after.
 * Touches the trainer's auth.users.last_sign_in_at -- fine for a `test+`/
 * fixture account used for exactly this kind of scripted verification
 * already (docs/progress.md item 67/70), not a contamination concern the
 * way impersonating a real teammate's account would be.
 *
 * Run (Test Org B, local dev -- the original invocation):
 *   npx tsx --env-file=.env.local scripts/verify_group_detail_client_name_render_test_org_b.ts
 *
 * Run (real WOW LAB org, production, after deploy):
 *   VERIFY_ORG_NAME="WOW LAB" VERIFY_TRAINER_EMAIL="test+trainer-a@wowlab.dev" \
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_group_detail_client_name_render_test_org_b.ts
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_NAME = process.env.VERIFY_ORG_NAME ?? "WOW LAB Test Org B";
const TRAINER_EMAIL = process.env.VERIFY_TRAINER_EMAIL ?? "maxdigitalro+trainerb1@gmail.com";
const SITE_URL = process.env.VERIFY_SITE_URL ?? process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  if (!url || !key) throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY");
  return createSupabaseClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function main() {
  const a = admin();

  const { data: org, error: orgErr } = await a
    .from("organizations")
    .select("id")
    .eq("name", ORG_NAME)
    .single();
  if (orgErr || !org) throw new Error(`Org lookup failed: ${orgErr?.message}`);

  const { data: trainer, error: trainerErr } = await a
    .from("users")
    .select("id")
    .eq("email", TRAINER_EMAIL)
    .single();
  if (trainerErr || !trainer) throw new Error(`Trainer lookup failed: ${trainerErr?.message}`);

  const CLIENT_NAME = "DRYRUN-VERIFY item66 client";

  const { data: client, error: clientErr } = await a
    .from("clients")
    .insert({ organization_id: org.id, name: CLIENT_NAME, client_type: "corporate" })
    .select("id, name")
    .single();
  if (clientErr || !client) throw new Error(`Client insert failed: ${clientErr?.message}`);

  const { data: group, error: groupErr } = await a
    .from("groups")
    .insert({ organization_id: org.id, client_id: client.id, module: "gaga", delivery_format: "recurring" })
    .select("id")
    .single();
  if (groupErr || !group) throw new Error(`Group insert failed: ${groupErr?.message}`);

  const { data: session, error: sessionErr } = await a
    .from("sessions")
    .insert({
      organization_id: org.id,
      group_id: group.id,
      session_date: new Date().toISOString().slice(0, 10),
      trainer_principal_id: trainer.id,
      status: "planned",
    })
    .select("id")
    .single();
  if (sessionErr || !session) throw new Error(`Session insert failed: ${sessionErr?.message}`);

  console.log(`Fixture created: client=${client.id} group=${group.id} session=${session.id}`);

  try {
    // Real magiclink verifyOtp, same mechanism /auth/callback uses -- not a
    // shortcut around it.
    const { data: link, error: linkErr } = await a.auth.admin.generateLink({
      type: "magiclink",
      email: TRAINER_EMAIL,
    });
    if (linkErr || !link) throw new Error(`generateLink failed: ${linkErr?.message}`);
    const tokenHash = link.properties?.hashed_token;
    if (!tokenHash) throw new Error("No hashed_token on generated link.");

    // Cookie jar captured via @supabase/ssr's own storage logic, so the
    // cookie name/value/chunking exactly matches what lib/supabase/server.ts
    // (createServerClient) expects to read -- not hand-crafted.
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

    const { data: verified, error: verifyErr } = await authClient.auth.verifyOtp({
      token_hash: tokenHash,
      type: "magiclink",
    });
    if (verifyErr || !verified.session) throw new Error(`verifyOtp failed: ${verifyErr?.message}`);
    console.log(`Signed in as ${TRAINER_EMAIL} (user id ${verified.session.user.id}).`);

    const cookieHeader = [...jar.entries()].map(([name, value]) => `${name}=${value}`).join("; ");

    const res = await fetch(`${SITE_URL}/groups/${group.id}`, {
      headers: { Cookie: cookieHeader },
    });
    const html = await res.text();

    console.log(`GET /groups/${group.id} -> ${res.status}`);
    await import("node:fs/promises").then((fs) => fs.writeFile("/tmp/item66-group-detail.html", html));

    const report: string[] = [];

    if (res.status === 200) {
      report.push("1. PASS - page returned 200 for the allocated trainer (not AccessDenied)");
    } else {
      report.push(`1. FAIL - page returned ${res.status}, expected 200`);
    }

    if (html.includes(CLIENT_NAME)) {
      report.push("2. PASS - the real client name is present in the server-rendered HTML");
    } else {
      report.push("2. FAIL - the client name is NOT present in the rendered HTML");
    }

    // The client id legitimately appears in the RSC flight-data payload as
    // GroupInfoSection's `clientId` prop (needed for the edit form's
    // contract filtering) -- that is not the bug. The bug is the id
    // rendering as an element's visible TEXT content, standing in for the
    // name. Checking specifically for that shape: the id immediately
    // surrounded by `>` and `<`, the way React serializes text nodes.
    if (html.includes(`>${client.id}<`)) {
      report.push("3. FAIL - the raw client UUID renders as visible text content (the bug item 66 reports)");
    } else {
      report.push("3. PASS - the raw client UUID does not render as visible text anywhere (it still legitimately appears in the hydration payload as GroupInfoSection's clientId prop, used for the edit form's contract filtering -- not as display text)");
    }

    console.log("\n" + report.join("\n"));

    if (report.some((r) => r.startsWith("FAIL") || r.includes("FAIL"))) {
      throw new Error("One or more assertions failed -- see report above.");
    }
  } finally {
    await a.from("sessions").delete().eq("id", session.id);
    await a.from("groups").delete().eq("id", group.id);
    await a.from("clients").delete().eq("id", client.id);
    console.log("Fixture cleaned up (session, group, client deleted).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
