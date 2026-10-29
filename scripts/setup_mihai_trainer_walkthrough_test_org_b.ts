/**
 * ONE-TIME SETUP — not a repeatable pattern, not something to run again.
 *
 * Gives Mihai his own real trainer account in wow-lab-test-b (organization
 * 09098278-4abc-4de6-a21f-5dc044d15ec4), so he can walk the trainer path on
 * his own phone end-to-end before inviting Lorina/Cătălina for real. Asked
 * for directly, in support of the "Readiness before invitation" standing
 * decision in docs/OPEN_ITEMS.md (the four-condition phone check).
 *
 * Nothing in wow-lab production (8e0dcc53-062f-4664-907d-826b9f45bec0) is
 * touched -- asserted at the end, not just assumed.
 *
 * Real auth row, not an RLS impersonation fixture (docs/DATABASE_CONVENTIONS.md
 * §11): admin.auth.admin.createUser with email_confirm:true and a generated
 * password creates the auth.users row directly; handle_new_auth_user()
 * creates the matching public.users row via its AFTER INSERT trigger
 * (same mechanism scripts/seed_test_org_b_trainers.ts already relies on).
 *
 * IMPORTANT, found while writing this: app/login/actions.ts only calls
 * signInWithOtp -- there is no password field anywhere in this app's UI.
 * The password this script sets satisfies "a real row in auth.users that
 * can authenticate" and is saved for completeness, but the actual sign-in
 * path on the phone is the same magic link every real trainer will use:
 * open /login, enter this account's email, open the email, tap the link.
 *
 * Run (never via `next dev`/a route -- standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/setup_mihai_trainer_walkthrough_test_org_b.ts
 */

import { randomBytes } from "crypto";
import { writeFileSync } from "fs";
import { createServiceRoleClient } from "../lib/supabase-admin";

const TEST_B_ORG_ID = "09098278-4abc-4de6-a21f-5dc044d15ec4";
const WOW_LAB_ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0";
const TRAINER_ROLE_ID = "c5d74a38-2612-49de-ae8f-1024d7b87e3e";
const OWNER_EMAIL = "test+user-b@wowlab.dev"; // acts as assigned_by / set_by / audit actor, same as seed_test_org_b_trainers.ts

const NEW_TRAINER_EMAIL = "maxdigitalro+trainerwalk@gmail.com";
const NEW_TRAINER_FULL_NAME = "Mihai — Trainer Walkthrough (Test Org B)";
const GRADE_LEVEL = 3; // mid-tier of the 1-6 scale, rate 200 in Test Org B's standing grid
const GRADE_EFFECTIVE_FROM = "2026-09-01"; // before every session date below

// "doctor" module group on the MAX client -- currently zero sessions, so
// this walkthrough's rows don't mix with trainerb1's existing confirmed
// ones on the other MAX group.
const GROUP_ID = "c4e3ba3d-c634-4414-b65d-0edc4ff41c91";

const SESSIONS = [
  { label: "past, unconfirmed", date: "2026-10-20" },
  { label: "today", date: "2026-10-27" },
  { label: "future", date: "2026-11-10" },
];

const PASSWORD_FILE = `${__dirname}/../mihai-trainer-walkthrough-password.secret`;

function generatePassword(): string {
  // 24 random bytes, base64url -- well above any Supabase Auth minimum,
  // no characters that need escaping if pasted into a shell or URL.
  return randomBytes(24).toString("base64url");
}

async function main() {
  const admin = createServiceRoleClient();

  const { data: owner, error: ownerError } = await admin
    .from("users")
    .select("id")
    .eq("email", OWNER_EMAIL)
    .single();
  if (ownerError || !owner) {
    throw new Error(`Could not find org owner ${OWNER_EMAIL}: ${ownerError?.message ?? "no row"}`);
  }
  console.log(`Acting as org owner ${OWNER_EMAIL} (${owner.id}) for assigned_by/set_by/audit fields.`);

  // Pre-flight: snapshot wow-lab (real org) row counts so the end-of-script
  // assertion has something to compare against, not just a bare "== 0".
  const PROD_TABLES = ["clients", "contracts", "groups", "sessions", "suppliers"] as const;
  const beforeCounts: Record<string, number> = {};
  for (const table of PROD_TABLES) {
    const { count, error } = await admin
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("organization_id", WOW_LAB_ORG_ID);
    if (error) throw new Error(`Pre-flight count failed for wow-lab.${table}: ${error.message}`);
    beforeCounts[table] = count ?? 0;
  }

  const password = generatePassword();

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: NEW_TRAINER_EMAIL,
    password,
    email_confirm: true,
    user_metadata: { full_name: NEW_TRAINER_FULL_NAME },
  });
  if (createError || !created.user) {
    throw new Error(`createUser failed for ${NEW_TRAINER_EMAIL}: ${createError?.message ?? "no user returned"}`);
  }
  const userId = created.user.id;
  console.log(`${NEW_TRAINER_EMAIL}: auth.users + public.users created, id=${userId}`);

  const { error: flagError } = await admin
    .from("users")
    .update({ is_test_account: true, status: "active" })
    .eq("id", userId);
  if (flagError) {
    throw new Error(`users update (is_test_account/status) failed: ${flagError.message}`);
  }
  console.log(`${NEW_TRAINER_EMAIL}: is_test_account=true, status=active.`);

  const { error: roleError } = await admin.from("user_org_roles").insert({
    organization_id: TEST_B_ORG_ID,
    user_id: userId,
    role_id: TRAINER_ROLE_ID,
    assigned_by: owner.id,
  });
  if (roleError) {
    throw new Error(`user_org_roles insert failed: ${roleError.message}`);
  }
  console.log(`${NEW_TRAINER_EMAIL}: Trainer role granted in wow-lab-test-b.`);

  const { error: gradeError } = await admin.from("trainer_grade_assignments").insert({
    organization_id: TEST_B_ORG_ID,
    trainer_id: userId,
    grade_level: GRADE_LEVEL,
    effective_from: GRADE_EFFECTIVE_FROM,
    set_by: owner.id,
    source: "manual",
  });
  if (gradeError) {
    throw new Error(`trainer_grade_assignments insert failed: ${gradeError.message}`);
  }
  console.log(`${NEW_TRAINER_EMAIL}: grade_level=${GRADE_LEVEL} effective ${GRADE_EFFECTIVE_FROM}.`);

  const createdSessionIds: string[] = [];
  for (const session of SESSIONS) {
    const { data: row, error } = await admin
      .from("sessions")
      .insert({
        organization_id: TEST_B_ORG_ID,
        group_id: GROUP_ID,
        session_date: session.date,
        trainer_principal_id: userId,
        status: "planned",
      })
      .select("id")
      .single();
    if (error || !row) {
      throw new Error(`session insert failed (${session.label}, ${session.date}): ${error?.message ?? "no row"}`);
    }
    createdSessionIds.push(row.id);
    console.log(`Session created (${session.label}): ${session.date}, id=${row.id}, principal=${userId}, unconfirmed.`);
  }

  await admin.from("audit_log").insert({
    organization_id: TEST_B_ORG_ID,
    actor_user_id: owner.id,
    event_type: "user.created_test_fixture",
    target_table: "users",
    target_id: userId,
    payload: { email: NEW_TRAINER_EMAIL, roleIds: [TRAINER_ROLE_ID], reason: "Mihai's own trainer-path walkthrough" },
  });

  writeFileSync(
    PASSWORD_FILE,
    `email: ${NEW_TRAINER_EMAIL}\npassword: ${password}\n\nNote: app/login has no password field (signInWithOtp only).\nSign in on the phone with a magic link to this same email, same as any real trainer.\n`,
    { mode: 0o600 },
  );
  console.log(`\nPassword written to ${PASSWORD_FILE} (not printed here, not committed).`);

  console.log("\n--- Assertions ---");

  const { data: membershipRows, error: membershipError } = await admin
    .from("user_org_roles")
    .select("user_id, organization_id")
    .eq("user_id", userId);
  if (membershipError) throw new Error(`Could not verify membership: ${membershipError.message}`);
  const memberships = membershipRows ?? [];
  const inTestB = memberships.filter((r) => r.organization_id === TEST_B_ORG_ID).length;
  const inWowLab = memberships.filter((r) => r.organization_id === WOW_LAB_ORG_ID).length;
  if (memberships.length !== 1 || inTestB !== 1 || inWowLab !== 0) {
    throw new Error(
      `Membership assertion FAILED: total=${memberships.length} testB=${inTestB} wowLab=${inWowLab}`,
    );
  }
  console.log("PASS: exactly one user_org_roles row, in wow-lab-test-b, none in wow-lab.");

  const { data: sessionRows, error: sessionCheckError } = await admin
    .from("sessions")
    .select("id, session_date, organization_id, trainer_principal_id, trainer_principal_confirmed_at")
    .in("id", createdSessionIds);
  if (sessionCheckError) throw new Error(`Could not verify sessions: ${sessionCheckError.message}`);
  for (const row of sessionRows ?? []) {
    if (row.organization_id !== TEST_B_ORG_ID) throw new Error(`Session ${row.id} is not in wow-lab-test-b.`);
    if (row.trainer_principal_id !== userId) throw new Error(`Session ${row.id} principal mismatch.`);
    if (row.trainer_principal_confirmed_at !== null) throw new Error(`Session ${row.id} was unexpectedly pre-confirmed.`);
  }
  console.log(`PASS: all ${sessionRows?.length ?? 0} sessions are in wow-lab-test-b, principal=this account, unconfirmed.`);

  for (const table of PROD_TABLES) {
    const { count, error } = await admin
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("organization_id", WOW_LAB_ORG_ID);
    if (error) throw new Error(`Post-flight count failed for wow-lab.${table}: ${error.message}`);
    if ((count ?? 0) !== beforeCounts[table]) {
      throw new Error(
        `Assertion FAILED: wow-lab.${table} count changed (${beforeCounts[table]} -> ${count}).`,
      );
    }
    console.log(`PASS: wow-lab.${table} count unchanged (${count}).`);
  }

  console.log(`\nDone. Trainer id: ${userId}, email: ${NEW_TRAINER_EMAIL}`);
  console.log("Sessions: " + SESSIONS.map((s) => `${s.label} (${s.date})`).join(", "));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
