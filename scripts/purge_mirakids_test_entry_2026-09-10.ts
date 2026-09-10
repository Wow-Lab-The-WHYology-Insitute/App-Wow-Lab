/**
 * ONE-TIME PURGE — Mirakids test entry, Mihai's second today after
 * Maxdigital (scripts/purge_maxdigital_test_entry_2026-09-10.ts). Mihai
 * confirms this client/contract/group is his own test entry from
 * exercising the create forms, not real client data. This one's own
 * backup is scripts/purge_backup_2026-09-10-mirakids.json.
 *
 * Deletes 3 rows, in dependency order:
 *
 *   1. groups     — 1 row (Mirakids' "lights" group)
 *   2. contracts  — 1 row (Mirakids' contract)
 *   3. clients    — 1 row (Mirakids)
 *
 * client_contacts checked live BEFORE writing this script, not discovered
 * via an FK failure the way the Maxdigital purge found its contact row:
 * zero client_contacts rows reference the Mirakids client id. No
 * client_contacts step in this script.
 *
 * SERVICE-ROLE, ON THE RECORD:
 *   - clients and groups have NO DELETE policy at all (confirmed against
 *     pg_policies, same as every prior purge this month -- zero rows for
 *     cmd='DELETE' on either table). There is no guard to satisfy for
 *     these; the app offers no delete path for them to any role.
 *   - contracts DOES have a DELETE policy
 *     (202608280001_contracts_delete.sql): capability AND status='draft'.
 *     This contract's status is 'draft' -- checked live immediately before
 *     writing this script -- so that guard IS satisfiable; this delete is
 *     not bypassing anything the app itself would refuse. It runs through
 *     the service-role client anyway, for one consistent path across all
 *     three rows.
 *
 * Every id below is matched exactly, never by name pattern or a broader
 * WHERE clause -- Anca (and possibly others; see docs/OPEN_ITEMS.md's
 * most recent entries) is actively entering real data in this same
 * organization while this script exists. Does not touch anything
 * belonging to the Lycee Francais client, its contract, or its two
 * groups -- confirmed by id in the identity checks below, not by table
 * scope alone.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/purge_mirakids_test_entry_2026-09-10.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0"; // wow-lab

const MIRAKIDS_CLIENT_ID = "6ea14c3f-1dfa-488a-88d9-2f0fbc079be5";
const MIRAKIDS_CONTRACT_ID = "03aede9d-4b66-4d7d-8fd3-8e3cef722157";
const MIRAKIDS_GROUP_ID = "769b2963-6ce7-4753-ab9c-984d19c34d31";

async function main() {
  const admin = createServiceRoleClient();

  // Defensive identity checks before deleting anything — confirm each row
  // is still what this script says it is, not assumed from a stale id.
  const { data: client, error: clientCheckErr } = await admin
    .from("clients")
    .select("id, name, status")
    .eq("id", MIRAKIDS_CLIENT_ID)
    .single();
  if (clientCheckErr || client?.name !== "Mirakids") {
    throw new Error(
      `Client identity check failed: expected Mirakids, got ${JSON.stringify(client)} (${clientCheckErr?.message ?? ""})`,
    );
  }

  const { data: contract, error: contractCheckErr } = await admin
    .from("contracts")
    .select("id, client_id, status")
    .eq("id", MIRAKIDS_CONTRACT_ID)
    .single();
  if (contractCheckErr || contract?.client_id !== MIRAKIDS_CLIENT_ID) {
    throw new Error(
      `Contract identity check failed: expected client_id=${MIRAKIDS_CLIENT_ID}, got ${JSON.stringify(contract)} (${contractCheckErr?.message ?? ""})`,
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
    .eq("id", MIRAKIDS_GROUP_ID)
    .single();
  if (
    groupCheckErr ||
    group?.client_id !== MIRAKIDS_CLIENT_ID ||
    group?.contract_id !== MIRAKIDS_CONTRACT_ID ||
    group?.module !== "lights"
  ) {
    throw new Error(
      `Group identity check failed: expected client_id=${MIRAKIDS_CLIENT_ID}, contract_id=${MIRAKIDS_CONTRACT_ID}, module=lights, got ${JSON.stringify(group)} (${groupCheckErr?.message ?? ""})`,
    );
  }

  // Proactive client_contacts check -- the Maxdigital purge found its
  // contact row only when the clients delete failed on an FK. Not
  // repeating that here: check first, unconditionally.
  const { data: contacts, error: contactsCheckErr } = await admin
    .from("client_contacts")
    .select("id")
    .eq("client_id", MIRAKIDS_CLIENT_ID);
  if (contactsCheckErr) {
    throw new Error(`client_contacts check failed: ${contactsCheckErr.message}`);
  }
  if (contacts && contacts.length > 0) {
    throw new Error(
      `Found ${contacts.length} client_contacts row(s) referencing Mirakids that this script does not account for. Stopping -- back these up and add a delete step before re-running.`,
    );
  }

  console.log("Identity checks passed: group, contract (draft), and client all match. Zero client_contacts rows found.");

  // 1. groups (1 row) — no DELETE policy exists for anyone; service-role only.
  const { error: groupErr, count: groupCount } = await admin
    .from("groups")
    .delete({ count: "exact" })
    .eq("id", MIRAKIDS_GROUP_ID)
    .eq("organization_id", ORG_ID);
  if (groupErr) throw new Error(`groups delete failed: ${groupErr.message}`);
  console.log(`groups: deleted ${groupCount} row (expected 1)`);

  // 2. contracts — status='draft', so the draft-only DELETE policy is
  // satisfiable; not a bypass, just run through service-role for one
  // consistent path with the other two deletes.
  const { error: contractErr, count: contractCount } = await admin
    .from("contracts")
    .delete({ count: "exact" })
    .eq("id", MIRAKIDS_CONTRACT_ID)
    .eq("organization_id", ORG_ID);
  if (contractErr) throw new Error(`contracts delete failed: ${contractErr.message}`);
  console.log(`contracts: deleted ${contractCount} row (expected 1) — draft-only DELETE policy was satisfiable, not bypassed`);

  // 3. clients — Mirakids only. No DELETE policy exists for this table at all.
  const { error: clientErr, count: clientCount } = await admin
    .from("clients")
    .delete({ count: "exact" })
    .eq("id", MIRAKIDS_CLIENT_ID)
    .eq("organization_id", ORG_ID);
  if (clientErr) throw new Error(`clients delete failed: ${clientErr.message}`);
  console.log(`clients: deleted ${clientCount} row (expected 1)`);

  console.log("Purge complete. 3 rows deleted. Verify independently, not from this output.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
