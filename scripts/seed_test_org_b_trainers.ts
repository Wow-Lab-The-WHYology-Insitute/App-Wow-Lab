/**
 * ONE-TIME SEED — not a repeatable pattern, not something to run again.
 *
 * Populates wow-lab-test-b (organization_id 09098278-4abc-4de6-a21f-
 * 5dc044d15ec4) with six permanent trainer accounts, one per grade level
 * 1-6, so app.resolve_trainer_grade() has real rows to resolve against in
 * this org. Nothing in wow-lab production (8e0dcc53-062f-4664-907d-
 * 826b9f45bec0) is touched.
 *
 * Real invite flow (mirrors inviteUser() in
 * app/(app)/admin/users/actions.ts): inviteUserByEmail creates the
 * auth.users row; handle_new_auth_user() creates the matching public.users
 * row synchronously via its AFTER INSERT trigger, confirmed by that same
 * action's own header comment, not re-verified here since it's read-only
 * behavior of code already live in this app.
 *
 * Emails: maxdigitalro+trainerb<N>@gmail.com, N=1..6, N == grade_level.
 * "b" suffix avoids collision with the existing maxdigitalro+trainer@
 * gmail.com production fixture and self-documents the org (test org B).
 *
 * Hard requirement asserted at the end, not just hoped for: each of the
 * six holds exactly one user_org_roles row, and it is in wow-lab-test-b,
 * none in wow-lab. Per this session's own investigation, a user in both
 * orgs would see their rows merged in /clients, /contracts, /groups with
 * no per-row org indicator -- so single membership here is a correctness
 * requirement, not a tidiness preference. Also asserted: wow-lab's own
 * clients/contracts/groups/sessions/suppliers counts are unchanged (zero)
 * after seeding.
 *
 * Run (never via `next dev`/a route -- standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/seed_test_org_b_trainers.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const TEST_B_ORG_ID = "09098278-4abc-4de6-a21f-5dc044d15ec4";
const WOW_LAB_ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0";
const TRAINER_ROLE_ID = "c5d74a38-2612-49de-ae8f-1024d7b87e3e";
const OWNER_EMAIL = "test+user-b@wowlab.dev"; // acts as assigned_by / set_by / audit actor

const TRAINERS = [1, 2, 3, 4, 5, 6].map((grade) => ({
  grade,
  email: `maxdigitalro+trainerb${grade}@gmail.com`,
  fullName: `Test Trainer B${grade}`,
}));

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

  const createdIds: string[] = [];

  for (const trainer of TRAINERS) {
    const { data: invited, error: inviteError } = await admin.auth.admin.inviteUserByEmail(
      trainer.email,
      {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
        data: { full_name: trainer.fullName },
      },
    );

    if (inviteError || !invited.user) {
      throw new Error(`inviteUserByEmail failed for ${trainer.email}: ${inviteError?.message ?? "no user returned"}`);
    }

    const userId = invited.user.id;
    console.log(`${trainer.email}: auth.users + public.users created, id=${userId}`);

    const { error: rolesError } = await admin.from("user_org_roles").insert({
      organization_id: TEST_B_ORG_ID,
      user_id: userId,
      role_id: TRAINER_ROLE_ID,
      assigned_by: owner.id,
    });

    if (rolesError) {
      throw new Error(`user_org_roles insert failed for ${trainer.email}: ${rolesError.message}`);
    }

    console.log(`${trainer.email}: user_org_roles inserted (trainer, wow-lab-test-b).`);

    const effectiveFrom = new Date().toISOString().slice(0, 10);
    const { error: gradeError } = await admin.from("trainer_grade_assignments").insert({
      organization_id: TEST_B_ORG_ID,
      trainer_id: userId,
      grade_level: trainer.grade,
      effective_from: effectiveFrom,
      set_by: owner.id,
      source: "manual",
    });

    if (gradeError) {
      throw new Error(`trainer_grade_assignments insert failed for ${trainer.email}: ${gradeError.message}`);
    }

    console.log(`${trainer.email}: trainer_grade_assignments inserted (grade_level=${trainer.grade}, source=manual).`);

    await admin.from("audit_log").insert({
      organization_id: TEST_B_ORG_ID,
      actor_user_id: owner.id,
      event_type: "user.invited",
      target_table: "users",
      target_id: userId,
      payload: { email: trainer.email, roleIds: [TRAINER_ROLE_ID] },
    });

    createdIds.push(userId);
  }

  console.log("\n--- Assertions ---");

  // Hard requirement: exactly one user_org_roles row per new trainer, and
  // it must be in wow-lab-test-b -- none in wow-lab.
  const { data: membershipRows, error: membershipError } = await admin
    .from("user_org_roles")
    .select("user_id, organization_id")
    .in("user_id", createdIds);

  if (membershipError) {
    throw new Error(`Could not verify memberships: ${membershipError.message}`);
  }

  const countsByUser = new Map<string, { total: number; testB: number; wowLab: number }>();
  for (const id of createdIds) countsByUser.set(id, { total: 0, testB: 0, wowLab: 0 });
  for (const row of membershipRows ?? []) {
    const entry = countsByUser.get(row.user_id);
    if (!entry) continue;
    entry.total += 1;
    if (row.organization_id === TEST_B_ORG_ID) entry.testB += 1;
    if (row.organization_id === WOW_LAB_ORG_ID) entry.wowLab += 1;
  }

  for (const [userId, counts] of countsByUser) {
    if (counts.total !== 1 || counts.testB !== 1 || counts.wowLab !== 0) {
      throw new Error(
        `Membership assertion FAILED for ${userId}: total=${counts.total} testB=${counts.testB} wowLab=${counts.wowLab}`,
      );
    }
  }

  console.log(
    `PASS: all ${createdIds.length} trainers hold exactly one user_org_roles row, in wow-lab-test-b, none in wow-lab.`,
  );

  // Hard requirement: wow-lab production tables still empty.
  const tables = ["clients", "contracts", "groups", "sessions", "suppliers"] as const;
  for (const table of tables) {
    const { count, error: countError } = await admin
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("organization_id", WOW_LAB_ORG_ID);

    if (countError) {
      throw new Error(`Could not count wow-lab ${table}: ${countError.message}`);
    }

    if (count !== 0) {
      throw new Error(`Assertion FAILED: wow-lab.${table} has ${count} rows, expected 0.`);
    }

    console.log(`PASS: wow-lab.${table} count is 0.`);
  }

  console.log("\nDone. Created trainer ids:");
  for (const trainer of TRAINERS) {
    console.log(`  grade ${trainer.grade}: ${trainer.email}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
