import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { ContractHeader } from "./contract-header";
import { ContractDetailClient } from "./contract-detail-client";
import { AccessDenied } from "@/components/ui/access-denied";

type ContractRow = {
  id: string;
  client_id: string;
  legal_entity_id: string;
  entry_number: string | null;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  renewal_of: string | null;
  billing_rule: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  drive_ref: string | null;
  notes: string | null;
  offer_structure: string | null;
  ac_link: string | null;
};
type ClientOptionRow = { id: string; name: string };
type LegalEntityOptionRow = { id: string; name: string };

// Same branching as contracts/page.tsx's canManageContracts() — kept as
// its own local copy rather than a shared import, matching this
// codebase's existing convention (the has_capability-loop pattern is
// duplicated per-file throughout, e.g. layout.tsx / admin/users/page.tsx
// / profile/page.tsx (né whoami) all carry their own copy).
async function canManageContracts(
  supabase: Awaited<ReturnType<typeof createClient>>,
  org: string,
) {
  const [isOwner, hasContractsStar, isFinanceReporting, isFinanceOps] =
    await Promise.all([
      checkCapability(supabase, "org.settings.manage", org),
      checkCapability(supabase, "contracts.*", org),
      checkCapability(supabase, "finance.reporting.*", org),
      checkCapability(supabase, "finance.operations.*", org),
    ]);
  return isOwner || (hasContractsStar && !isFinanceReporting && !isFinanceOps);
}

export default async function ContractDetailPage({
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

  const { data: contract } = await supabase
    .from("contracts_billing_masked")
    .select(
      "id, client_id, legal_entity_id, entry_number, exit_number, contract_type, status, period_start, period_end, renewal_of, billing_rule, estimated_value, previous_year_value, drive_ref, notes, offer_structure, ac_link",
    )
    .eq("id", id)
    .maybeSingle<ContractRow>();

  if (!contract) {
    return <AccessDenied reasonKey="access_denied_not_found_contract" />;
  }

  const [{ data: client }, { data: legalEntity }] = await Promise.all([
    supabase.from("clients").select("id, name").eq("id", contract.client_id).maybeSingle(),
    supabase
      .from("legal_entities")
      .select("id, name")
      .eq("id", contract.legal_entity_id)
      .maybeSingle(),
  ]);

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id);

  let canManage = false;
  let manageOrgId: string | null = null;
  let financeVisible = false;
  for (const m of memberships ?? []) {
    const org = (m as { organization_id: string }).organization_id;
    if (!canManage && (await canManageContracts(supabase, org))) {
      canManage = true;
      manageOrgId = org;
    }
    if (!financeVisible) {
      for (const cap of ["finance.operations.*", "finance.reporting.*", "clients.create"]) {
        if (await checkCapability(supabase, cap, org)) {
          financeVisible = true;
          break;
        }
      }
    }
    if (canManage && financeVisible) break;
  }

  // Edit-form dropdown options: clients + legal entities in the org this
  // caller can manage contracts in — only fetched when the Edit button
  // will actually render, same convention as contracts/page.tsx's "+ New
  // Contract" form options.
  let clientOptions: ClientOptionRow[] = [];
  let legalEntityOptions: LegalEntityOptionRow[] = [];
  if (manageOrgId) {
    const [{ data: co }, { data: leo }] = await Promise.all([
      supabase
        .from("clients")
        .select("id, name")
        .eq("organization_id", manageOrgId)
        .order("name")
        .returns<ClientOptionRow[]>(),
      supabase
        .from("legal_entities")
        .select("id, name")
        .eq("organization_id", manageOrgId)
        .order("name")
        .returns<LegalEntityOptionRow[]>(),
    ]);
    clientOptions = co ?? [];
    legalEntityOptions = leo ?? [];
  }

  const clientName = client?.name ?? contract.client_id;

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <ContractHeader
        contractId={contract.id}
        exitNumber={contract.exit_number}
        entryNumber={contract.entry_number}
        clientName={clientName}
        contractType={contract.contract_type}
        status={contract.status}
        notes={contract.notes}
        canManage={canManage}
      />

      <ContractDetailClient
        contract={contract}
        clientName={clientName}
        legalEntityName={legalEntity?.name ?? contract.legal_entity_id}
        financeVisible={financeVisible}
        canManage={canManage}
        clientOptions={clientOptions}
        legalEntityOptions={legalEntityOptions}
      />
    </div>
  );
}
