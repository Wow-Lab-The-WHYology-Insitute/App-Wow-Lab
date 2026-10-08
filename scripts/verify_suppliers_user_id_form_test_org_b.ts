/**
 * ONE-TIME VERIFICATION (item 105). `suppliers.user_id` in the supplier
 * detail/edit screen, against the real deployment, in WOW LAB Test Org B only.
 *
 * WHAT EACH CLAIM IS WORTH, stated rather than blended -- same discipline as
 * verify_vet_module_test_org_b.ts:
 *   - The READ view is verified by RENDERING: the "Linked person" row and the
 *     resolved name appear in the real server-rendered HTML.
 *   - The PICKER is verified by SHIPMENT, not by rendering. The edit form sits
 *     behind `isEditing` React state, so a server fetch never renders it. What
 *     a fetch CAN prove is that `memberOptions` crossed the server/client
 *     boundary -- the names are serialized into the RSC flight payload -- and
 *     that the "No linked person" option label ships. That is strictly weaker
 *     than seeing the <select>, and is labelled as such.
 *   - PERSISTENCE is verified through the real authorization path: the update
 *     runs through a USER-SCOPED client carrying the signed-in owner's
 *     cookies, which is the identical RLS path `updateSupplier` takes. Not via
 *     the service role, which would bypass the policy and prove nothing.
 *
 * Test Org B only. The 22 real suppliers in `wow-lab` are never read or
 * written here.
 *
 * Cleanup runs in `finally` AND says out loud whether it ran (item 102: two
 * standing fixtures were left mutated by runs whose silent finally never
 * fired).
 *
 * Run:
 *   VERIFY_SITE_URL="https://app.wowlab.ro" \
 *   npx tsx --env-file=.env.local scripts/verify_suppliers_user_id_form_test_org_b.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const ORG_NAME = "WOW LAB Test Org B";
// organization_owner in Test Org B -> holds finance.reporting.*, so canEdit
// and createOrgId are both true for this viewer. Confirmed live.
const OWNER_EMAIL = "test+user-b@wowlab.dev";
// A second real member of the same org, to be the link target. operations_manager
// only -- deliberately NOT a finance.reporting.* holder, so this also confirms
// the picker offers people who cannot themselves see the suppliers screen.
const LINK_TARGET_EMAIL = "test+ui-ops-manager-b@wowlab.dev";
const SUPPLIER_NAME = "ZZ VERIFY user_id form";

const SITE_URL = process.env.VERIFY_SITE_URL ?? "https://app.wowlab.ro";
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

// Returns both the cookie header (for page fetches) and a user-scoped
// supabase client (for the RLS-path write), from one sign-in.
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

async function main() {
  const a = admin();
  const report: string[] = [];
  const fail: string[] = [];
  let supplierId: string | null = null;
  let cleanupRan = false;

  try {
    const { data: org, error: oErr } = await a
      .from("organizations").select("id").eq("name", ORG_NAME).single();
    if (oErr || !org) throw new Error(`org ${ORG_NAME} not found: ${oErr?.message}`);

    const { data: target, error: tErr } = await a
      .from("users").select("id, full_name, first_name, last_name")
      .eq("email", LINK_TARGET_EMAIL).single();
    if (tErr || !target) throw new Error(`link target ${LINK_TARGET_EMAIL} not found: ${tErr?.message}`);
    const targetName =
      [target.first_name, target.last_name].filter(Boolean).join(" ") ||
      (target.full_name && !target.full_name.includes("@") ? target.full_name : "");
    if (!targetName) throw new Error(`link target has no displayable name -- cannot assert rendering`);

    // Fixture: unlinked to start, so the "no link" state is asserted first.
    const { data: created, error: cErr } = await a
      .from("suppliers")
      .insert({
        organization_id: org.id,
        name: SUPPLIER_NAME,
        service_type: "verification fixture",
        status: "active",
        user_id: null,
      })
      .select("id").single();
    if (cErr || !created) throw new Error(`fixture insert failed: ${cErr?.message}`);
    supplierId = created.id;

    const { cookie, client } = await signIn(a, OWNER_EMAIL);
    const url = `${SITE_URL}/suppliers/${supplierId}`;

    // ---- 1. READ VIEW, no link (rendering) -----------------------------
    const r1 = await fetch(url, { headers: { cookie }, redirect: "manual" });
    if (r1.status !== 200) throw new Error(`GET ${url} -> HTTP ${r1.status}`);
    const html1 = await r1.text();
    const text1 = visibleText(html1);

    if (text1.includes("Linked person")) report.push('OK   read view renders the "Linked person" row');
    else fail.push('MISS read view does not render "Linked person" -- deploy may be stale');

    if (text1.includes("Edit")) report.push("OK   Edit control renders (canEdit true for an org owner)");
    else fail.push("MISS Edit control absent -- finance.reporting.* gate not satisfied?");

    // ---- 2. PICKER DATA SHIPPED (shipment, not rendering) --------------
    // memberOptions is a server->client prop, so it is serialized into the
    // flight payload even though the <select> itself never renders server-side.
    if (html1.includes(targetName)) {
      report.push(`OK   memberOptions shipped -- link target "${targetName}" present in the payload`);
    } else {
      fail.push(`MISS "${targetName}" absent from the payload -- memberOptions not reaching the client`);
    }
    if (html1.includes("No linked person")) {
      report.push('OK   "No linked person" option label shipped (the selectable no-link value)');
    } else {
      fail.push('MISS "No linked person" absent -- the i18n key did not ship');
    }

    // ---- 3. PERSISTENCE through the real RLS path ----------------------
    // Identical call to updateSupplier's: user-scoped client, not the service
    // role. If the UPDATE policy rejected it, this returns 0 rows rather than
    // throwing -- which is exactly the case the action treats as "Not permitted".
    const { data: upd, error: uErr } = await client
      .from("suppliers")
      .update({ user_id: target.id })
      .eq("id", supplierId)
      .select("id");
    if (uErr) fail.push(`MISS RLS-path update errored: ${uErr.message}`);
    else if (!upd || upd.length === 0) fail.push("MISS RLS-path update affected 0 rows -- policy rejected the write");
    else report.push("OK   link saved through the owner's own session (the policy path the form uses)");

    // ---- 4. READ VIEW, link persisted (rendering) ----------------------
    const r2 = await fetch(url, { headers: { cookie }, redirect: "manual", cache: "no-store" });
    const text2 = visibleText(await r2.text());
    if (text2.includes(targetName)) {
      report.push(`OK   persisted link renders the resolved name "${targetName}"`);
    } else {
      fail.push(`MISS persisted link does not render "${targetName}" in the read view`);
    }
    if (!text2.includes(supplierId!)) {
      report.push("OK   raw uuid not rendered anywhere in the read view");
    } else {
      fail.push("MISS the supplier uuid is visible in rendered text");
    }

    // ---- 5. CLEARING the link, back to NULL ----------------------------
    const { data: cleared, error: clErr } = await client
      .from("suppliers")
      .update({ user_id: null })
      .eq("id", supplierId)
      .select("id");
    if (clErr || !cleared || cleared.length === 0) {
      fail.push(`MISS could not clear the link back to NULL: ${clErr?.message ?? "0 rows"}`);
    } else {
      report.push("OK   link clearable back to NULL (the 17 company suppliers' correct value)");
    }
  } finally {
    if (supplierId) {
      const { error } = await admin().from("suppliers").delete().eq("id", supplierId);
      cleanupRan = !error;
      console.log(
        cleanupRan
          ? `cleanup: fixture supplier ${supplierId} deleted`
          : `cleanup: FAILED to delete fixture supplier ${supplierId} -- ${error?.message}`,
      );
    } else {
      console.log("cleanup: nothing to delete (no fixture was created)");
    }
  }

  console.log("\n" + report.join("\n"));
  if (fail.length > 0) {
    console.error("\n" + fail.join("\n"));
    process.exit(1);
  }
  console.log("\nAll assertions passed.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
