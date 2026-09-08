/**
 * ONE-TIME SEED — not a repeatable pattern, not something to run again.
 *
 * Same procedure as scripts/create_eight_real_wow_lab_accounts.ts: five
 * more real trainers from Anca's current active roster (item 34,
 * OPEN_ITEMS.md), each with a real email now on file for the first time.
 * createUser() (never emails), a follow-up UPDATE for first_name/
 * last_name, then a single trainer role in wow-lab. No invitation sent
 * here — that's a separate step, one at a time, through the real admin
 * UI, after this script's assertions pass.
 *
 * Deliberately NOT included: Lorina Ciurușniuc — Anca says she is not
 * confirmed yet (item 34).
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/create_five_more_wow_lab_trainers.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const WOW_LAB_ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0";
const TEST_B_ORG_ID = "09098278-4abc-4de6-a21f-5dc044d15ec4";
const TRAINER_ROLE_ID = "c5d74a38-2612-49de-ae8f-1024d7b87e3e";
// maxdigitalro@gmail.com — the real organization_owner, same actor used
// for every other script-driven write this session.
const ACTOR_USER_ID = "def47f4b-4452-49c5-bcea-a35b06dddfa3";

type Person = {
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
};

const PEOPLE: Person[] = [
  {
    email: "soniaganea05@gmail.com",
    firstName: "Sonia",
    lastName: "Ganea",
    fullName: "Sonia Ganea",
  },
  {
    email: "irinaeremia160@gmail.com",
    firstName: "Andrada",
    lastName: "Eremia",
    fullName: "Andrada Eremia",
  },
  {
    email: "alina.garofil@outlook.com",
    firstName: "Alina",
    lastName: "Garofil",
    fullName: "Alina Garofil",
  },
  {
    email: "elena.bacalum@gmail.com",
    firstName: "Elena",
    lastName: "Bacalum",
    fullName: "Elena Bacalum",
  },
  {
    email: "v.tobosaru@yahoo.com",
    firstName: "Viorel",
    lastName: "Toboșaru",
    fullName: "Viorel Toboșaru",
  },
];

async function main() {
  const admin = createServiceRoleClient();
  const createdIds: { email: string; id: string }[] = [];

  for (const person of PEOPLE) {
    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: person.email,
      email_confirm: true,
      user_metadata: { full_name: person.fullName },
    });

    if (createError || !created.user) {
      throw new Error(`createUser failed for ${person.email}: ${createError?.message ?? "no user returned"}`);
    }

    const userId = created.user.id;
    console.log(`${person.email}: auth.users + public.users created, id=${userId}`);

    const { error: nameError } = await admin
      .from("users")
      .update({ first_name: person.firstName, last_name: person.lastName })
      .eq("id", userId);

    if (nameError) {
      throw new Error(`first_name/last_name update failed for ${person.email}: ${nameError.message}`);
    }

    console.log(`${person.email}: first_name/last_name set (${person.firstName} / ${person.lastName}).`);

    const { error: rolesError } = await admin.from("user_org_roles").insert({
      organization_id: WOW_LAB_ORG_ID,
      user_id: userId,
      role_id: TRAINER_ROLE_ID,
      assigned_by: ACTOR_USER_ID,
    });

    if (rolesError) {
      throw new Error(`user_org_roles insert failed for ${person.email}: ${rolesError.message}`);
    }

    console.log(`${person.email}: user_org_roles inserted (trainer, wow-lab).`);

    await admin.from("audit_log").insert({
      organization_id: WOW_LAB_ORG_ID,
      actor_user_id: ACTOR_USER_ID,
      event_type: "user.account_created",
      target_table: "users",
      target_id: userId,
      payload: {
        email: person.email,
        roleKeys: ["trainer"],
        invited: false,
        note: "Created ahead of sending invitations; no invitation email sent.",
      },
    });

    createdIds.push({ email: person.email, id: userId });
  }

  console.log("\n--- Assertions ---");

  const allIds = createdIds.map((p) => p.id);
  const { data: membershipRows, error: membershipError } = await admin
    .from("user_org_roles")
    .select("user_id, organization_id")
    .in("user_id", allIds);

  if (membershipError) {
    throw new Error(`Could not verify memberships: ${membershipError.message}`);
  }

  const countsByUser = new Map<string, { wowLab: number; testB: number }>();
  for (const id of allIds) countsByUser.set(id, { wowLab: 0, testB: 0 });
  for (const row of membershipRows ?? []) {
    const entry = countsByUser.get(row.user_id);
    if (!entry) continue;
    if (row.organization_id === WOW_LAB_ORG_ID) entry.wowLab += 1;
    if (row.organization_id === TEST_B_ORG_ID) entry.testB += 1;
  }

  for (const person of createdIds) {
    const counts = countsByUser.get(person.id)!;
    if (counts.testB !== 0) {
      throw new Error(`Assertion FAILED: ${person.email} holds ${counts.testB} row(s) in wow-lab-test-b, expected 0.`);
    }
    if (counts.wowLab !== 1) {
      throw new Error(`Assertion FAILED: ${person.email} holds ${counts.wowLab} role row(s) in wow-lab, expected exactly 1.`);
    }
  }

  console.log("PASS: all five hold exactly one role row, in wow-lab, none in wow-lab-test-b.");

  console.log("\nDone. Created accounts:");
  for (const person of createdIds) {
    console.log(`  ${person.email}: ${person.id} — role: trainer`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
