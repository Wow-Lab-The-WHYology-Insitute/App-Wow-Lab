/**
 * ONE-TIME PURGE — Tier 1 of docs/WOWLAB_Purge_Plan_Seed_Data.md.
 *
 * Deletes 11 confirmed-residue rows, in the exact order Mihai specified
 * (matches the plan's own dependency ordering — sessions before their
 * groups, the Maxdigital contract before the Maxdigital client):
 *
 *   1. suppliers  — 1 row  ("DELETE-ME-TEST-SUPPLIER")
 *   2. sessions   — 6 rows (all 6, against the 4 Cambridge groups)
 *   3. groups     — 4 rows (all 4 Cambridge groups)
 *   4. contracts  — 1 row  (Maxdigital's contract)
 *   5. clients    — 1 row  (Maxdigital)
 *
 * A full pre-delete backup of these rows (plus the 13 Tier 2 rows, not
 * touched here) already exists at scripts/purge_backup_2026-09-01.json.
 *
 * SERVICE-ROLE BYPASS, ON THE RECORD:
 *   - clients, groups, sessions, suppliers have NO DELETE policy at all
 *     (confirmed against pg_policies — zero rows for cmd='DELETE' on any
 *     of the four). There is no guard to satisfy; the app offers no
 *     delete path for these tables to any role.
 *   - contracts DOES have a DELETE policy
 *     (202608280001_contracts_delete.sql), but it requires status='draft'
 *     in addition to a capability check. The Maxdigital contract's status
 *     is 'signed' — the policy cannot be satisfied by any role. This
 *     script deletes it anyway, via the service_role client, which
 *     bypasses RLS entirely. That is a deliberate bypass of the
 *     draft-only guard, not a workaround of a bug in it — recorded here
 *     and in the commit message rather than left implicit in the fact
 *     that this script uses the admin client.
 *
 * This script only DELETEs the 11 rows above. It does not touch users,
 * user_org_roles, legal_entities, org_settings, or any Tier 2 row.
 * Independent verification (fresh queries, not this script's own output)
 * happens separately after this runs.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/purge_tier1_seed_data.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0"; // wow-lab

const SUPPLIER_ID = "47970148-fc65-4eb3-aa59-aefece8feffa";
const SESSION_IDS = [
  "72064917-da77-41de-b5c7-e59f8c2765e3",
  "ae36039d-1ed6-4e84-b681-f7f0394e7c54",
  "bd82b39d-7cf6-43b5-baec-3426509d17ae",
  "d9904c02-4ac7-4a67-8794-88018150770b",
  "4a09135a-6ddd-423e-a269-d18cb919d2e4",
  "16fae46c-48e3-403d-8140-d42b6fd346cc",
];
const GROUP_IDS = [
  "dc7fdf01-9859-4f82-a1ce-1e76f4fe2cbc",
  "c9a90921-423f-49dd-8f47-9815e28c2bba",
  "bf8b4848-47e4-4c88-95dc-7fff1400cd13",
  "dff71c2e-60e7-47a8-afe9-463a425554af",
];
const MAXDIGITAL_CONTRACT_ID = "b8951c03-611f-4bee-895e-d296c098efde";
const MAXDIGITAL_CLIENT_ID = "74cf4089-ab02-40c9-89bf-7988902e154b";

async function main() {
  const admin = createServiceRoleClient();

  // Defensive identity checks before deleting anything — confirm each row
  // is still what the purge plan says it is, not assumed from a stale id.
  const { data: supplier, error: supplierCheckErr } = await admin
    .from("suppliers")
    .select("id, name")
    .eq("id", SUPPLIER_ID)
    .single();
  if (supplierCheckErr || supplier?.name !== "DELETE-ME-TEST-SUPPLIER") {
    throw new Error(
      `Supplier identity check failed: expected DELETE-ME-TEST-SUPPLIER, got ${JSON.stringify(supplier)} (${supplierCheckErr?.message ?? ""})`,
    );
  }
  const { data: maxClient, error: maxClientCheckErr } = await admin
    .from("clients")
    .select("id, name")
    .eq("id", MAXDIGITAL_CLIENT_ID)
    .single();
  if (maxClientCheckErr || maxClient?.name !== "Maxdigital") {
    throw new Error(
      `Client identity check failed: expected Maxdigital, got ${JSON.stringify(maxClient)} (${maxClientCheckErr?.message ?? ""})`,
    );
  }
  console.log("Identity checks passed: supplier and client match the purge plan.");

  // 1. suppliers (1 row) — no DELETE policy exists for anyone; service-role only.
  const { error: supplierErr, count: supplierCount } = await admin
    .from("suppliers")
    .delete({ count: "exact" })
    .eq("id", SUPPLIER_ID)
    .eq("organization_id", ORG_ID);
  if (supplierErr) throw new Error(`suppliers delete failed: ${supplierErr.message}`);
  console.log(`suppliers: deleted ${supplierCount} row (expected 1)`);

  // 2. sessions (6 rows) — must precede their parent groups (sessions.group_id FK, NO ACTION).
  const { error: sessionsErr, count: sessionsCount } = await admin
    .from("sessions")
    .delete({ count: "exact" })
    .in("id", SESSION_IDS)
    .eq("organization_id", ORG_ID);
  if (sessionsErr) throw new Error(`sessions delete failed: ${sessionsErr.message}`);
  console.log(`sessions: deleted ${sessionsCount} rows (expected 6)`);

  // 3. groups (4 rows) — must precede clients.client_id FK, NO ACTION.
  const { error: groupsErr, count: groupsCount } = await admin
    .from("groups")
    .delete({ count: "exact" })
    .in("id", GROUP_IDS)
    .eq("organization_id", ORG_ID);
  if (groupsErr) throw new Error(`groups delete failed: ${groupsErr.message}`);
  console.log(`groups: deleted ${groupsCount} rows (expected 4)`);

  // 4. contracts — Maxdigital's contract only. status='signed', so the
  // draft-only DELETE policy cannot be satisfied by any role; this
  // service-role call bypasses it deliberately (see header comment).
  const { error: contractErr, count: contractCount } = await admin
    .from("contracts")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_CONTRACT_ID)
    .eq("organization_id", ORG_ID);
  if (contractErr) throw new Error(`contracts delete failed: ${contractErr.message}`);
  console.log(`contracts: deleted ${contractCount} row (expected 1) — draft-only DELETE policy bypassed via service_role`);

  // 5. clients — Maxdigital only. No DELETE policy exists for this table at all.
  const { error: clientErr, count: clientCount } = await admin
    .from("clients")
    .delete({ count: "exact" })
    .eq("id", MAXDIGITAL_CLIENT_ID)
    .eq("organization_id", ORG_ID);
  if (clientErr) throw new Error(`clients delete failed: ${clientErr.message}`);
  console.log(`clients: deleted ${clientCount} row (expected 1)`);

  console.log("Tier 1 purge complete. 11 rows deleted. Verify independently, not from this output.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
