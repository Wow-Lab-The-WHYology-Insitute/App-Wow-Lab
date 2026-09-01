/**
 * ONE-TIME PURGE — Tier 2 of docs/WOWLAB_Purge_Plan_Seed_Data.md.
 *
 * Deletes the 11 remaining confirmed-residue rows, in the order Mihai
 * specified: the 5 demo contracts, then Vlad Rasnoveanu's client_contacts
 * row, then the 5 demo clients. Both contracts and the client contact must
 * clear before their parent client (client_id FK, NO ACTION, no CASCADE).
 *
 *   1. contracts        — 5 rows (Lycée Français, IBSB, Cambridge School,
 *                          King's Oak, Zitec — all from 202608100007)
 *   2. client_contacts  — 1 row  (Vlad Rasnoveanu, Lycée Français's contact)
 *   3. clients          — 5 rows (the same five)
 *
 * A full pre-delete backup of these rows (plus Tier 1's 11, already
 * deleted) already exists at scripts/purge_backup_2026-09-01.json.
 *
 * SERVICE-ROLE BYPASS, ON THE RECORD (same as Tier 1):
 *   - clients has NO DELETE policy at all for any role — nothing to
 *     satisfy, the app offers no delete path for this table.
 *   - contracts DOES have a DELETE policy
 *     (202608280001_contracts_delete.sql), gated on status='draft'. All 5
 *     of these contracts are 'signed' or 'sent' — none 'draft' — so the
 *     policy cannot be satisfied by any role. This script deletes them
 *     anyway via the service_role client, bypassing that guard
 *     deliberately, exactly as it did for the Maxdigital contract in
 *     Tier 1.
 *   - client_contacts DOES have a DELETE policy
 *     (202608270001_client_contacts_delete.sql) with no status condition
 *     — Vlad Rasnoveanu's row could in principle clear it under a normal
 *     authenticated session with the right capability. Deleted here via
 *     service_role anyway, for procedural consistency with the rest of
 *     this batch, not because the policy blocked it.
 *
 * This script only DELETEs the 11 rows above. It does not touch users,
 * user_org_roles, legal_entities, or org_settings. Independent
 * verification (fresh queries, not this script's own output) happens
 * separately after this runs.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/purge_tier2_seed_data.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const ORG_ID = "8e0dcc53-062f-4664-907d-826b9f45bec0"; // wow-lab

const CONTRACT_IDS = [
  "bb8cf3ac-023c-4455-a63b-b0030af94570", // Lycée Français
  "723722c8-c0a4-411b-92c9-e3bb4713a316", // IBSB
  "db4d6266-2090-458a-9234-ea96f03b10de", // Cambridge School
  "7d671add-6b46-44c7-b085-a997ff2cf13a", // King's Oak
  "08e6d216-4c0e-442b-a36e-e323f5c66229", // Zitec
];
const CLIENT_CONTACT_ID = "ae291c55-6ebc-486e-adcd-d467b923f89d"; // Vlad Rasnoveanu
const CLIENT_IDS = [
  "0440552d-5664-49c6-a606-8b47ca073631", // Lycée Français
  "5b94eeeb-0ab3-4fae-aac3-867ae8fa71b5", // IBSB
  "a2a35e51-0dd6-4e61-8e31-aad5e0c2bfee", // Cambridge School
  "fe355b09-3d31-48b0-82b5-5c0405a0a0eb", // King's Oak
  "c83342e4-5a0c-4bbe-b7ea-ed654a131a19", // Zitec
];

async function main() {
  const admin = createServiceRoleClient();

  // Defensive identity check before deleting anything.
  const { data: contact, error: contactCheckErr } = await admin
    .from("client_contacts")
    .select("id, full_name")
    .eq("id", CLIENT_CONTACT_ID)
    .single();
  if (contactCheckErr || contact?.full_name !== "Vlad Rasnoveanu") {
    throw new Error(
      `client_contacts identity check failed: expected Vlad Rasnoveanu, got ${JSON.stringify(contact)} (${contactCheckErr?.message ?? ""})`,
    );
  }
  const { data: clientsBefore, error: clientsCheckErr } = await admin
    .from("clients")
    .select("id, name")
    .in("id", CLIENT_IDS);
  if (clientsCheckErr || clientsBefore?.length !== 5) {
    throw new Error(
      `clients identity check failed: expected 5 rows, got ${JSON.stringify(clientsBefore)} (${clientsCheckErr?.message ?? ""})`,
    );
  }
  console.log("Identity checks passed:", clientsBefore.map((c) => c.name).sort().join(", "));

  // 1. contracts (5 rows) — must precede their parent clients.
  const { error: contractsErr, count: contractsCount } = await admin
    .from("contracts")
    .delete({ count: "exact" })
    .in("id", CONTRACT_IDS)
    .eq("organization_id", ORG_ID);
  if (contractsErr) throw new Error(`contracts delete failed: ${contractsErr.message}`);
  console.log(`contracts: deleted ${contractsCount} rows (expected 5) — draft-only DELETE policy bypassed via service_role`);

  // 2. client_contacts (1 row) — must precede its parent client.
  const { error: contactErr, count: contactCount } = await admin
    .from("client_contacts")
    .delete({ count: "exact" })
    .eq("id", CLIENT_CONTACT_ID)
    .eq("organization_id", ORG_ID);
  if (contactErr) throw new Error(`client_contacts delete failed: ${contactErr.message}`);
  console.log(`client_contacts: deleted ${contactCount} row (expected 1)`);

  // 3. clients (5 rows) — last, now that contracts and the contact are gone.
  const { error: clientsErr, count: clientsCount } = await admin
    .from("clients")
    .delete({ count: "exact" })
    .in("id", CLIENT_IDS)
    .eq("organization_id", ORG_ID);
  if (clientsErr) throw new Error(`clients delete failed: ${clientsErr.message}`);
  console.log(`clients: deleted ${clientsCount} rows (expected 5) — no DELETE policy exists for this table at all`);

  console.log("Tier 2 purge complete. 11 rows deleted. Verify independently, not from this output.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
