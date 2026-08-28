import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { ClientContactsClient } from "./client-contacts-client";
import { ClientInfoClient } from "./client-info-client";
import { ClientHeader } from "./client-header";
import { ClientContractsSection } from "./client-contracts-section";
import { AccessDenied } from "@/components/ui/access-denied";

type ClientRow = {
  id: string;
  organization_id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
  external_crm_ref: string | null;
  notes: string | null;
  legal_name: string | null;
  cui: string | null;
};
type ContactRow = {
  id: string;
  full_name: string;
  role_at_client: string | null;
  email: string | null;
  phone: string | null;
  is_billing_contact: boolean;
  is_primary: boolean;
  contact_purpose: string | null;
};
type ContractRow = {
  id: string;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
  legal_entity_id: string;
};
type LegalEntityLookupRow = { id: string; name: string };

// client_contacts INSERT/UPDATE policy (202608100003): org/platform owner,
// clients.create (sales_manager), or contracts.* excluding either finance
// role (contract_administrator) -- a THIRD alternative (clients.create)
// beyond contracts/[id]/page.tsx's own narrower canManageContracts, so
// this can't reuse that function; kept as its own local copy per this
// codebase's established convention of duplicating the has_capability-loop
// pattern per file rather than sharing it.
async function canManageContacts(
  supabase: Awaited<ReturnType<typeof createClient>>,
  org: string,
) {
  const [isOwner, hasClientsCreate, hasContractsStar, isFinanceReporting, isFinanceOps] =
    await Promise.all([
      checkCapability(supabase, "org.settings.manage", org),
      checkCapability(supabase, "clients.create", org),
      checkCapability(supabase, "contracts.*", org),
      checkCapability(supabase, "finance.reporting.*", org),
      checkCapability(supabase, "finance.operations.*", org),
    ]);
  return (
    isOwner ||
    hasClientsCreate ||
    (hasContractsStar && !isFinanceReporting && !isFinanceOps)
  );
}

export default async function ClientDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  const { data: client } = await supabase
    .from("clients")
    .select(
      "id, organization_id, name, client_type, status, business_line, external_crm_ref, notes, legal_name, cui",
    )
    .eq("id", id)
    .maybeSingle<ClientRow>();

  if (!client) {
    // Either genuinely missing, or RLS-filtered for this viewer (record-
    // level segregation) — a single-row RLS query can't distinguish the
    // two, and shouldn't: telling a finance_operations user "this
    // corporate client doesn't exist" is the correct behavior, not a bug.
    return <AccessDenied reasonKey="access_denied_not_found_client" />;
  }

  const { data: contacts } = await supabase
    .from("client_contacts")
    .select("id, full_name, role_at_client, email, phone, is_billing_contact, is_primary, contact_purpose")
    .eq("client_id", id)
    .order("is_primary", { ascending: false })
    .returns<ContactRow[]>();

  // billing_rule comes from the masked VIEW, never the raw contracts
  // table (confirmed live: the view already inherits contracts' own
  // record-level RLS via security_invoker, so this is not weaker than
  // querying the base table for row visibility — it only ALSO masks the
  // one column).
  const { data: contracts } = await supabase
    .from("contracts_billing_masked")
    .select("id, exit_number, contract_type, status, period_start, period_end, billing_rule, legal_entity_id")
    .eq("client_id", id)
    .returns<ContractRow[]>();

  // "Billed via": distinct legal entities across this client's contracts —
  // derived/computed, not a direct field on clients (a client can span
  // entities across different contracts, e.g. a recurring-school contract
  // via Experimente Wow and a one-off event via Brandine ADV for the same
  // school). Same two-lookup convention as contracts/page.tsx.
  const legalEntityIds = [...new Set((contracts ?? []).map((c) => c.legal_entity_id))];
  const { data: legalEntityRows } =
    legalEntityIds.length > 0
      ? await supabase
          .from("legal_entities")
          .select("id, name")
          .in("id", legalEntityIds)
          .returns<LegalEntityLookupRow[]>()
      : { data: [] as LegalEntityLookupRow[] };
  const billedViaNames = [...new Set((legalEntityRows ?? []).map((e) => e.name))].sort();

  // Distinguishes "masked because you lack the capability" from
  // "genuinely never set" for a null billing_rule — same has_capability
  // set the view itself unmasks on (202608100006), so this can't drift
  // out of sync with what the view actually decided for this session.
  let financeVisible = false;
  let canManage = false;
  let canConvert = false;
  // Distinct from canManage (client_contacts' own, broader gate) --
  // mirrors the actual clients UPDATE policy exactly (org.settings.manage
  // OR clients.create), confirmed live: contract_administrator satisfies
  // canManage via contracts.* but does not hold clients.create, so it
  // must not see this gate open even though it can manage contacts.
  let canEditClient = false;
  // Same non-discriminating-today caveat as the action itself: crm_link.*
  // is held by the identical three roles as clients.create right now, so
  // this never actually diverges from canEditClient in production yet.
  let canEditCrmLink = false;
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id);
  for (const m of memberships ?? []) {
    const org = (m as { organization_id: string }).organization_id;
    if (!financeVisible) {
      for (const cap of ["finance.operations.*", "finance.reporting.*", "clients.create"]) {
        if (await checkCapability(supabase, cap, org)) {
          financeVisible = true;
          break;
        }
      }
    }
    if (!canManage && (await canManageContacts(supabase, org))) canManage = true;
    if (!canConvert && (await checkCapability(supabase, "clients.convert", org))) {
      canConvert = true;
    }
    if (!canEditClient) {
      for (const cap of ["org.settings.manage", "clients.create"]) {
        if (await checkCapability(supabase, cap, org)) {
          canEditClient = true;
          break;
        }
      }
    }
    if (!canEditCrmLink && (await checkCapability(supabase, "crm_link.*", org))) {
      canEditCrmLink = true;
    }
    if (financeVisible && canManage && canConvert && canEditClient && canEditCrmLink) break;
  }

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6">
      <ClientHeader
        clientId={client.id}
        name={client.name}
        clientType={client.client_type}
        status={client.status}
        canConvert={canConvert}
      />

      <ClientInfoClient
        client={client}
        billedViaValue={billedViaNames.length > 0 ? billedViaNames.join(", ") : "—"}
        canEditClient={canEditClient}
        canEditCrmLink={canEditCrmLink}
      />

      <ClientContactsClient
        clientId={client.id}
        organizationId={client.organization_id}
        contacts={contacts ?? []}
        canManage={canManage}
      />

      <ClientContractsSection
        contracts={contracts ?? []}
        clientName={client.name}
        financeVisible={financeVisible}
      />
    </div>
  );
}
