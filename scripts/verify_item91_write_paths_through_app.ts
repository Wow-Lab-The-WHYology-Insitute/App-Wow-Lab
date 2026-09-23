/**
 * ONE-TIME VERIFICATION, not a repeatable pattern. Walks every write path
 * item 91 touched THROUGH THE REAL APP on app.wowlab.ro -- not via
 * supabase.rpc(), not via SQL impersonation -- by extracting the real
 * Next.js Server Action ids from the deployed JS bundle and issuing the
 * exact POST protocol a browser click would (Next-Action header, the
 * same body encoding). Every result is confirmed by reading the row back
 * via service role, per Mihai's own instruction: a 200 response proves
 * nothing on its own (item 90 -- a failed write can render as silent
 * success).
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_item91_write_paths_through_app.ts
 */

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";

// Extracted live from the deployed bundle immediately before this run --
// see the report for how (createServerReference ids in the page chunks
// for /groups/[id], /contracts/[id]). These are build-specific; if the
// app is redeployed, re-extract before reusing this script.
const ACTION_IDS = {
  updateSessionAllocation: "78beff3ec97af5ceaf789f7ca782ece67774e0929c",
  updateSessionAttendance: "7805c45ef125150e4463ba7a1d1b1b427e1f8ba275",
  confirmSessionAttendance: "70d172b6af426f3d8a12d6563e48d6108eee9b6083",
  correctSessionConfirmation: "7855a6aa17d90c3f2f2f5761b94763dcd137ee895e",
  updateContract: "7fb43e5cc8a6e38f978d41e9f872eafdaa3d5d3b63",
  updateGroup: "7ea089c4c3c41b361cb12edb666ae2a3cba3fc8a15",
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
  const report: string[] = [];
  const cleanup: (() => Promise<void>)[] = [];

  try {
    const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
    const { data: legalEntity } = await a.from("legal_entities").select("id").eq("organization_id", org!.id).limit(1).single();
    const { data: principal } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
    const { data: secundar } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb2@gmail.com").single();
    const { data: other } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb3@gmail.com").single();

    // ---- Fixtures ----
    // client_type: private_school, not corporate -- test+ui-contract-admin-b
    // holds BOTH contracts.* (contract_administrator) AND
    // finance_operations, and the finance.operations.* SELECT branch on
    // contracts (client-type-scoped to private_school/parent_b2c) takes
    // priority over the general contracts.*/contracts.read branch (which
    // is itself excluded "AND NOT finance.operations.*"). A 'corporate'
    // client's contract is genuinely invisible to this actor via RLS --
    // confirmed live while building this script (updateContract/
    // updateGroup both correctly returned ok:false, "not visible", not a
    // silent success -- item 91 behaving correctly, the first fixture
    // choice was just wrong for this specific actor).
    const { data: client } = await a.from("clients").insert({ organization_id: org!.id, name: "DRYRUN item91 through-app client", client_type: "private_school" }).select("id").single();
    cleanup.push(async () => { await a.from("clients").delete().eq("id", client!.id); });

    const { data: group } = await a.from("groups").insert({ organization_id: org!.id, client_id: client!.id, module: "gaga", delivery_format: "wow_lab_party" }).select("id").single();
    cleanup.push(async () => { await a.from("groups").delete().eq("id", group!.id); });

    const { data: contract } = await a.from("contracts").insert({ organization_id: org!.id, client_id: client!.id, legal_entity_id: legalEntity!.id, exit_number: "ITEM91-THROUGH-APP-001", contract_type: "one_off_event", status: "signed" }).select("id").single();
    cleanup.push(async () => { await a.from("contracts").delete().eq("id", contract!.id); });

    const { data: session1 } = await a.from("sessions").insert({ organization_id: org!.id, group_id: group!.id, session_date: new Date().toISOString().slice(0, 10), trainer_principal_id: principal!.id, trainer_secundar_id: secundar!.id, status: "planned" }).select("id").single();
    cleanup.push(async () => { await a.from("sessions").delete().eq("id", session1!.id); });

    // ---- 1. Operations reassigns a trainer on a session ----
    const opsCookie = await signIn(a, "test+ui-ops-manager-b@wowlab.dev");
    const r1 = await callAction(`/groups/${group!.id}`, "updateSessionAllocation", [group!.id, session1!.id, secundar!.id, other!.id], opsCookie);
    const { data: afterAllocation } = await a.from("sessions").select("trainer_principal_id, trainer_secundar_id").eq("id", session1!.id).single();
    const allocationLanded = afterAllocation?.trainer_principal_id === secundar!.id && afterAllocation?.trainer_secundar_id === other!.id;
    report.push(`1. Operations reassigns trainer (updateSessionAllocation): HTTP ${r1.status}, DB shows principal=${afterAllocation?.trainer_principal_id === secundar!.id ? "swapped-in-secundar" : "UNCHANGED"}, secundar=${afterAllocation?.trainer_secundar_id === other!.id ? "swapped-in-other" : "UNCHANGED"} -> ${allocationLanded ? "PASS" : "FAIL (rendered as if OK but did not land, or genuinely rejected)"}`);
    // Put it back for the next steps (principal=secundar now, secundar=other) -- restore original for clarity of the next tests.
    await a.from("sessions").update({ trainer_principal_id: principal!.id, trainer_secundar_id: secundar!.id }).eq("id", session1!.id);

    // ---- 2. A trainer records attendance and experiment ----
    const principalCookie = await signIn(a, "maxdigitalro+trainerb1@gmail.com");
    const r2 = await callAction(`/groups/${group!.id}`, "updateSessionAttendance", [group!.id, session1!.id, "9", "gaga"], principalCookie);
    const { data: afterAttendance } = await a.from("sessions").select("attendance_count, experiment_delivered").eq("id", session1!.id).single();
    const attendanceLanded = afterAttendance?.attendance_count === 9 && afterAttendance?.experiment_delivered === "gaga";
    report.push(`2. Trainer records attendance+experiment (updateSessionAttendance): HTTP ${r2.status}, DB shows attendance_count=${afterAttendance?.attendance_count}, experiment_delivered=${afterAttendance?.experiment_delivered} -> ${attendanceLanded ? "PASS" : "FAIL"}`);

    // ---- 3. A trainer confirms their own slot ----
    const r3 = await callAction(`/groups/${group!.id}`, "confirmSessionAttendance", [group!.id, session1!.id, true], principalCookie);
    const { data: afterConfirm } = await a.from("sessions").select("trainer_principal_confirmed_at, trainer_secundar_confirmed_at").eq("id", session1!.id).single();
    const confirmLanded = afterConfirm?.trainer_principal_confirmed_at !== null && afterConfirm?.trainer_secundar_confirmed_at === null;
    report.push(`3. Trainer confirms own slot (confirmSessionAttendance): HTTP ${r3.status}, DB shows principal_confirmed_at=${afterConfirm?.trainer_principal_confirmed_at}, secundar_confirmed_at=${afterConfirm?.trainer_secundar_confirmed_at} -> ${confirmLanded ? "PASS" : "FAIL"}`);

    // ---- 4a. Finance corrects a confirmation, BEFORE month close ----
    const financeCookie = await signIn(a, "test+ui-contract-admin-b@wowlab.dev");
    const r4a = await callAction(`/groups/${group!.id}`, "correctSessionConfirmation", [group!.id, session1!.id, false, true], financeCookie);
    const { data: afterCorrectionOpen } = await a.from("sessions").select("trainer_principal_confirmed_at, trainer_secundar_confirmed_at").eq("id", session1!.id).single();
    const correctionOpenLanded = afterCorrectionOpen?.trainer_principal_confirmed_at === null && afterCorrectionOpen?.trainer_secundar_confirmed_at !== null;
    report.push(`4a. Finance corrects confirmation, month OPEN (correctSessionConfirmation): HTTP ${r4a.status}, DB shows principal_confirmed_at=${afterCorrectionOpen?.trainer_principal_confirmed_at}, secundar_confirmed_at=${afterCorrectionOpen?.trainer_secundar_confirmed_at} -> ${correctionOpenLanded ? "PASS" : "FAIL"}`);

    // ---- 4b. Finance corrects a confirmation, AFTER month close ----
    const period = `${session1!.session_date?.slice(0, 7) ?? new Date().toISOString().slice(0, 7)}-01`;
    const { data: closedPeriod } = await a.from("payroll_periods").insert({ organization_id: org!.id, period, closed_at: new Date().toISOString() }).select("id").single();
    if (closedPeriod) cleanup.push(async () => { await a.from("payroll_periods").delete().eq("id", closedPeriod.id); });
    const r4b = await callAction(`/groups/${group!.id}`, "correctSessionConfirmation", [group!.id, session1!.id, true, true], financeCookie);
    const { data: afterCorrectionClosed } = await a.from("sessions").select("trainer_principal_confirmed_at, trainer_secundar_confirmed_at").eq("id", session1!.id).single();
    const correctionClosedLanded = afterCorrectionClosed?.trainer_principal_confirmed_at !== null && afterCorrectionClosed?.trainer_secundar_confirmed_at !== null;
    report.push(`4b. Finance corrects confirmation, month CLOSED (correctSessionConfirmation): HTTP ${r4b.status}, DB shows principal_confirmed_at=${afterCorrectionClosed?.trainer_principal_confirmed_at}, secundar_confirmed_at=${afterCorrectionClosed?.trainer_secundar_confirmed_at} -> ${correctionClosedLanded ? "PASS (correction path is NOT month-gated, by design)" : "FAIL"}`);

    // ---- 5. A contract administrator sets a contract's financial fields ----
    const r5 = await callAction(`/contracts/${contract!.id}`, "updateContract", [
      contract!.id, client!.id, legalEntity!.id, "one_off_event", "", "", "", "ITEM91-THROUGH-APP-001", "", "", "", "",
      { billingRule: "100 lei/copil", estimatedValue: "5000", previousYearValue: "4500" },
    ], financeCookie);
    const { data: afterFinancials } = await a.from("contracts").select("billing_rule, estimated_value, previous_year_value").eq("id", contract!.id).single();
    const financialsLanded = afterFinancials?.billing_rule === "100 lei/copil" && Number(afterFinancials?.estimated_value) === 5000 && Number(afterFinancials?.previous_year_value) === 4500;
    report.push(`5. Contract admin (+finance) sets financial fields (updateContract): HTTP ${r5.status}, DB shows billing_rule=${afterFinancials?.billing_rule}, estimated_value=${afterFinancials?.estimated_value}, previous_year_value=${afterFinancials?.previous_year_value} -> ${financialsLanded ? "PASS" : "FAIL"}`);

    // ---- 6. A contracts.* holder sets children_confirmed ----
    const r6 = await callAction(`/groups/${group!.id}`, "updateGroup", [group!.id, "", contract!.id, "17", "", ""], financeCookie);
    const { data: afterChildren } = await a.from("groups").select("children_confirmed").eq("id", group!.id).single();
    const childrenLanded = afterChildren?.children_confirmed === 17;
    report.push(`6. contracts.* holder sets children_confirmed (updateGroup): HTTP ${r6.status}, DB shows children_confirmed=${afterChildren?.children_confirmed} -> ${childrenLanded ? "PASS" : "FAIL"}`);

    console.log("\n" + report.join("\n"));
    const anyFail = report.some((r) => r.includes("FAIL"));
    if (anyFail) {
      console.log("\nAt least one path showed success on screen (HTTP 200) but did not write -- see FAIL lines above.");
    } else {
      console.log("\nAll 6 write paths confirmed: HTTP response AND the value actually landed, for every one.");
    }
  } finally {
    for (const fn of cleanup.reverse()) {
      await fn();
    }
    console.log("\nFixtures cleaned up.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
