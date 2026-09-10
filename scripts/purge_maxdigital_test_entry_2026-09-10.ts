/**
 * ONE-TIME PURGE — the second "Maxdigital" test entry, nine days after the
 * first (scripts/purge_tier1_seed_data.ts, 2026-09-01). Mihai confirms this
 * is his own test entry from exercising the client/contract/group create
 * forms, not real client data. Not part of the September purge plan doc --
 * this one's own backup is scripts/purge_backup_2026-09-10.json.
 *
 * Deletes 4 rows, in dependency order:
 *
 *   1. client_contacts — 1 row (Mihai's own signing-authority contact on
 *      the client -- client_contacts.client_id FK. Not planned for up
 *      front: this session's own client-contacts UI (client-contacts-
 *      client.tsx) was never exercised against this test client, so the
 *      row wasn't visible from clients/contracts/groups alone. Found live,
 *      the hard way -- the first run of this script got as far as deleting
 *      the group and the contract, then failed on `clients` with
 *      `client_contacts_client_id_fkey`. This script now includes the step
 *      that first run was missing.)
 *   2. groups     — 1 row (Maxdigital's "magic_physics" group)
 *   3. contracts  — 1 row (Maxdigital's contract)
 *   4. clients    — 1 row (Maxdigital)
 *
 * SERVICE-ROLE, ON THE RECORD:
 *   - clients, groups, and client_contacts have NO DELETE policy at all
 *     (confirmed against pg_policies, same shape as 2026-09-01 -- zero
 *     rows for cmd='DELETE' on any of the three). There is no guard to
 *     satisfy for these; the app offers no delete path for them to any
 *     role (client_contacts UI only ever edits/creates, never deletes).
 *   - contracts DOES have a DELETE policy
 *     (202608280001_contracts_delete.sql): capability AND status='draft'.
 *     This contract's status is 'draft' -- checked live immediately before
 *     writing this script -- so that guard IS satisfiable; unlike the
 *     2026-09-01 Maxdigital contract (which was 'signed' and needed a
 *     genuine bypass), this delete is not bypassing anything the app
 *     itself would refuse. It runs through the service-role client anyway,
 *     for one consistent path across all four rows rather than mixing the
 *     app's deleteContract() action with three service-role deletes.
 *
 * Does not touch anything belonging to the Lycee Francais client, its
 * contract, or its two groups -- confirmed by id, not by table scope
 * alone, in the identity checks below.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/purge_maxdigital_test_entry_2026-09-10.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0"; // wow-lab

const MAXDIGITAL_CLIENT_ID = "0cb08ddc-6990-4f68-a66c-f79018dc6aa4";
const MAXDIGITAL_CONTRACT_ID = "47beb018-6a36-413e-b694-93cad3ed6aae";
const MAXDIGITAL_GROUP_ID = "3808c34d-f8c5-4cb6-9221-86293b2c7bf3";
const MAXDIGITAL_CONTACT_ID = "ab915392-2216-47cf-8537-c6010d2b2280";

async function main() {
  const admin = createServiceRoleClient();

  // Defensive identity checks before deleting anything — confirm each row
  // is still what this script says it is, not assumed from a stale id.
  const { data: client, error: clientCheckErr } = await admin
    .from("clients")
    .select("id, name, status")
    .eq("id", MAXDIGITAL_CLIENT_ID)
    .single();
  if (clientCheckErr || client?.name !== "Maxdigital") {
    throw new Error(
      `Client identity check failed: expected Maxdigital, got ${JSON.stringify(client)} (${clientCheckErr?.message ?? ""})`,
    );
  }

  const { data: contract, error: contractCheckErr } = await admin
    .from("contracts")
    .select("id, client_id, status")
    .eq("id", MAXDIGITAL_CONTRACT_ID)
    .single();
  if (contractCheckErr || contract?.client_id !== MAXDIGITAL_CLIENT_ID) {
    throw new Error(
      `Contract identity check failed: expected client_id=${MAXDIGITAL_CLIENT_ID}, got ${JSON.stringify(contract)} (${contractCheckErr?.message ?? ""})`,
    );
  }
  if (contract.status !== "draft") {
    throw new Error(
      `Contract status changed since this script was written: expected 'draft', got '${contract.status}'. Stopping -- re-check before deleting.`,
    );
  }

  const { data: group, error: groupCheckErr } = await admin
    .from("groups")
    .select("id, client_id, contract_id, module")
    .eq("id", MAXDIGITAL_GROUP_ID)
    .single();
  if (
    groupCheckErr ||
    group?.client_id !== MAXDIGITAL_CLIENT_ID ||
    group?.contract_id !== MAXDIGITAL_CONTRACT_ID ||
    group?.module !== "magic_physics"
  ) {
    throw new Error(
      `Group identity check failed: expected client_id=${MAXDIGITAL_CLIENT_ID}, contract_id=${MAXDIGITAL_CONTRACT_ID}, module=magic_physics, got ${JSON.stringify(group)} (${groupCheckErr?.message ?? ""})`,
    );
  }

  const { data: contact, error: contactCheckErr } = await admin
    .from("client_contacts")
    .select("id, client_id, full_name")
    .eq("id", MAXDIGITAL_CONTACT_ID)
    .single();
  if (
    contactCheckErr ||
    contact?.client_id !== MAXDIGITAL_CLIENT_ID ||
    contact?.full_name !== "Mihai Constantinescu"
  ) {
    throw new Error(
      `Contact identity check failed: expected client_id=${MAXDIGITAL_CLIENT_ID}, full_name=Mihai Constantinescu, got ${JSON.stringify(contact)} (${contactCheckErr?.message ?? ""})`,
    );
  }

  console.log("Identity checks passed: contact, group, contract (draft), and client all match.");

  // 1. client_contacts (1 row) — no DELETE policy exists for anyone;
  // service-role only. Must precede clients (client_contacts.client_id FK).
  const { error: contactErr, count: contactCount } = await admin
    .from("client_contacts")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_CONTACT_ID)
    .eq("organization_id", ORG_ID);
  if (contactErr) throw new Error(`client_contacts delete failed: ${contactErr.message}`);
  console.log(`client_contacts: deleted ${contactCount} row (expected 1)`);

  // 2. groups (1 row) — no DELETE policy exists for anyone; service-role only.
  const { error: groupErr, count: groupCount } = await admin
    .from("groups")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_GROUP_ID)
    .eq("organization_id", ORG_ID);
  if (groupErr) throw new Error(`groups delete failed: ${groupErr.message}`);
  console.log(`groups: deleted ${groupCount} row (expected 1)`);

  // 3. contracts — status='draft', so the draft-only DELETE policy is
  // satisfiable; this is not a bypass, just run through service-role for
  // one consistent path with the other two deletes.
  const { error: contractErr, count: contractCount } = await admin
    .from("contracts")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_CONTRACT_ID)
    .eq("organization_id", ORG_ID);
  if (contractErr) throw new Error(`contracts delete failed: ${contractErr.message}`);
  console.log(`contracts: deleted ${contractCount} row (expected 1) — draft-only DELETE policy was satisfiable, not bypassed`);

  // 4. clients — Maxdigital only. No DELETE policy exists for this table at all.
  const { error: clientErr, count: clientCount } = await admin
    .from("clients")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_CLIENT_ID)
    .eq("organization_id", ORG_ID);
  if (clientErr) throw new Error(`clients delete failed: ${clientErr.message}`);
  console.log(`clients: deleted ${clientCount} row (expected 1)`);

  console.log("Purge complete. 4 rows deleted. Verify independently, not from this output.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
