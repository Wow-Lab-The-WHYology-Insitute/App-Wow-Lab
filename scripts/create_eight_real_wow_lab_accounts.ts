/**
 * ONE-TIME SEED — not a repeatable pattern, not something to run again.
 *
 * Creates real accounts for eight named team members, in wow-lab only,
 * single org membership each. Explicitly does NOT send any invitation
 * email: uses admin.auth.admin.createUser() (never emails), not
 * inviteUserByEmail() (always emails) — Mihai's own instruction was to
 * create and verify, then stop, so roles can be checked with Anca before
 * anyone gets an email.
 *
 * Mirrors the real admin invite flow's two writes (app/(app)/admin/users/
 * actions.ts inviteUser()), just via createUser instead of
 * inviteUserByEmail: (1) auth.users insert fires handle_new_auth_user()
 * (202608200003), which writes ONLY full_name (from
 * raw_user_meta_data->>'full_name') onto the new public.users row —
 * first_name/last_name are never touched by the trigger; (2) a follow-up
 * UPDATE on public.users sets first_name/last_name explicitly, exactly as
 * inviteUser() does when the admin UI form supplies them. Skipping step
 * (2) here would leave /profile falling back to splitting full_name
 * (cd7860f) instead of using real structured names — avoided deliberately.
 *
 * Raluca Margean is created with NO role/membership row, on Mihai's
 * explicit instruction after evidence (progress.md line 128, Appendix A of
 * WOWLAB_SAD_Contracte_Trainer_Furnizor.md) contradicted his original
 * "trainer" proposal and no confirmed alternative role exists yet. She is
 * therefore the one account of the eight with zero org membership until
 * Anca confirms her actual role.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/create_eight_real_wow_lab_accounts.ts
 *
 * First live run (2026-09-03): all 8 creates + name updates + role inserts
 * succeeded; the assertion below then failed on a bug in the assertion
 * itself (it compared wow-lab row count to a hardcoded 1, but Cătălina
 * legitimately holds 3 role rows) — not a data problem. Fixed in this file
 * (now compares to `person.roleKeys.length`) and re-verified live in a
 * separate pass with the corrected logic; all 8 accounts + the six
 * wow-lab-test-b sanity checks passed. Re-running this whole script now
 * would fail on every createUser() call with "already registered".
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const WOW_LAB_ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0";
const TEST_B_ORG_ID = "09098278-4abc-4de6-a21f-5dc044d15ec4";
// maxdigitalro@gmail.com — the real (non-test) organization_owner for
// wow-lab, live-confirmed this session — used as assigned_by/actor for
// this script's writes since there is no real admin UI session here.
const ACTOR_USER_ID = "def47f4b-4452-49c5-bcea-a35b06dddfa3";

const ROLE_IDS: Record<string, string> = {
  operations_manager: "91366159-880c-4c90-b6b5-6f47753d7e6b",
  curriculum_manager: "0ebcad05-2151-4556-9bcc-7f512200a679",
  evaluator: "d7934b5f-274c-4306-8580-8bfb51a6cfa6",
  finance_operations: "8f3a9c5f-0759-44ed-af50-a83e43dd8017",
  community_people: "e13f910b-fb51-4a70-9ccc-ebaeeb3b7849",
  inventory_custodian: "3c7d0202-d5bb-4008-8a47-348614b03c7f",
  trainer: "c5d74a38-2612-49de-ae8f-1024d7b87e3e",
};

type Person = {
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  roleKeys: string[];
};

const PEOPLE: Person[] = [
  {
    email: "catalina_moale@yahoo.com",
    firstName: "Cătălina",
    lastName: "Trușan",
    fullName: "Cătălina Trușan",
    // Corrected from the "operations_manager"-only proposal: her own
    // existing fixture (test+catalina@wowlab.dev) already holds exactly
    // this three-role set live, confirmed by direct query this session.
    roleKeys: ["operations_manager", "curriculum_manager", "evaluator"],
  },
  {
    email: "lauraflorentinaa220@gmail.com",
    firstName: "Laura",
    lastName: "Moale",
    fullName: "Laura Moale",
    roleKeys: ["finance_operations"],
  },
  {
    email: "alexandra.nutu2010@gmail.com",
    firstName: "Alexandra",
    lastName: "Nuțu",
    fullName: "Alexandra Nuțu",
    // Corrected from "community_people"-only: progress.md line 126 names
    // her explicitly as one of three trainer+admin hybrids, and Appendix A
    // confirms 89 career workshops under her name (grade 3). Flagged for
    // Anca to confirm, not a certainty on the level of Laura/Cătălina.
    roleKeys: ["community_people", "trainer"],
  },
  {
    email: "merisanteodora@gmail.com",
    firstName: "Teodora",
    lastName: "Merișan",
    fullName: "Teodora Merișan",
    roleKeys: ["inventory_custodian", "trainer"],
  },
  {
    email: "rabalasov@gmail.com",
    firstName: "Răzvan Alexandru",
    lastName: "Bălașov",
    fullName: "Răzvan Alexandru Bălașov",
    roleKeys: ["trainer"],
  },
  {
    email: "popar216@gmail.com",
    firstName: "Raluca",
    lastName: "Popa",
    fullName: "Raluca Popa",
    roleKeys: ["trainer"],
  },
  {
    email: "luiza.mirt8@gmail.com",
    firstName: "Luiza",
    lastName: "Mirt",
    fullName: "Luiza Mirt",
    roleKeys: ["trainer"],
  },
  {
    email: "ralucamargean@yahoo.com",
    firstName: "Raluca",
    lastName: "Margean",
    fullName: "Raluca Margean",
    // No role/membership row — see header comment. Evidence contradicted
    // the original "trainer" proposal; no confirmed alternative exists.
    roleKeys: [],
  },
];

async function main() {
  const admin = createServiceRoleClient();
  const createdIds: { email: string; id: string; roleKeys: string[] }[] = [];

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

    if (person.roleKeys.length > 0) {
      const { error: rolesError } = await admin.from("user_org_roles").insert(
        person.roleKeys.map((roleKey) => ({
          organization_id: WOW_LAB_ORG_ID,
          user_id: userId,
          role_id: ROLE_IDS[roleKey],
          assigned_by: ACTOR_USER_ID,
        })),
      );

      if (rolesError) {
        throw new Error(`user_org_roles insert failed for ${person.email}: ${rolesError.message}`);
      }

      console.log(`${person.email}: user_org_roles inserted (${person.roleKeys.join(", ")}, wow-lab).`);
    } else {
      console.log(`${person.email}: NO role inserted — pending role decision (Raluca Margean, see header comment).`);
    }

    await admin.from("audit_log").insert({
      organization_id: WOW_LAB_ORG_ID,
      actor_user_id: ACTOR_USER_ID,
      event_type: "user.account_created",
      target_table: "users",
      target_id: userId,
      payload: {
        email: person.email,
        roleKeys: person.roleKeys,
        invited: false,
        note: "Created ahead of role confirmation with Anca; no invitation email sent.",
      },
    });

    createdIds.push({ email: person.email, id: userId, roleKeys: person.roleKeys });
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

  const countsByUser = new Map<string, { total: number; wowLab: number; testB: number }>();
  for (const id of allIds) countsByUser.set(id, { total: 0, wowLab: 0, testB: 0 });
  for (const row of membershipRows ?? []) {
    const entry = countsByUser.get(row.user_id);
    if (!entry) continue;
    entry.total += 1;
    if (row.organization_id === WOW_LAB_ORG_ID) entry.wowLab += 1;
    if (row.organization_id === TEST_B_ORG_ID) entry.testB += 1;
  }

  for (const person of createdIds) {
    const counts = countsByUser.get(person.id)!;
    // "Single org membership" means one ORG, not one ROW — Cătălina
    // legitimately holds 3 role rows, all in wow-lab. Row count isn't the
    // right thing to assert; org membership is.
    const expectedWowLabRows = person.roleKeys.length; // 0 for Raluca Margean, pending role decision
    if (counts.testB !== 0) {
      throw new Error(`Assertion FAILED: ${person.email} holds ${counts.testB} row(s) in wow-lab-test-b, expected 0.`);
    }
    if (counts.wowLab !== expectedWowLabRows) {
      throw new Error(
        `Assertion FAILED: ${person.email} holds ${counts.wowLab} role row(s) in wow-lab, expected ${expectedWowLabRows}.`,
      );
    }
  }

  console.log(
    "PASS: none of the eight holds any role in wow-lab-test-b; each holds exactly their expected role rows, all in wow-lab (0 for Raluca Margean, pending role decision).",
  );

  // Sanity check: the six wow-lab-test-b trainer fixtures from a prior
  // session still hold zero roles in wow-lab (unrelated to this script's
  // writes, but asserted per Mihai's explicit instruction).
  const TEST_B_TRAINER_EMAILS = [1, 2, 3, 4, 5, 6].map((n) => `maxdigitalro+trainerb${n}@gmail.com`);
  const { data: testBUsers, error: testBUsersError } = await admin
    .from("users")
    .select("id, email")
    .in("email", TEST_B_TRAINER_EMAILS);

  if (testBUsersError || !testBUsers) {
    throw new Error(`Could not look up wow-lab-test-b trainer fixtures: ${testBUsersError?.message}`);
  }

  const { data: testBWowLabRoles, error: testBWowLabRolesError } = await admin
    .from("user_org_roles")
    .select("user_id")
    .eq("organization_id", WOW_LAB_ORG_ID)
    .in(
      "user_id",
      testBUsers.map((u) => u.id),
    );

  if (testBWowLabRolesError) {
    throw new Error(`Could not verify wow-lab-test-b trainers' wow-lab roles: ${testBWowLabRolesError.message}`);
  }

  if ((testBWowLabRoles ?? []).length !== 0) {
    throw new Error(
      `Assertion FAILED: ${testBWowLabRoles!.length} of the six wow-lab-test-b trainer fixtures now hold a role in wow-lab.`,
    );
  }

  console.log("PASS: the six seeded wow-lab-test-b trainer fixtures still hold zero roles in wow-lab.");

  console.log("\nDone. Created accounts:");
  for (const person of createdIds) {
    console.log(`  ${person.email}: ${person.id} — roles: ${person.roleKeys.join(", ") || "(none)"}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
