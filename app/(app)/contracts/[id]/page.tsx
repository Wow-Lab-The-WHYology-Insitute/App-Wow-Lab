import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { isDemoRecord } from "../format";
import { MarkSignedButton } from "./mark-signed-button";
import { DeleteContractButton } from "./delete-contract-button";
import { ContractDetailClient } from "./contract-detail-client";

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
    return <AccessDenied reason="Not signed in." />;
  }

  const { data: contract } = await supabase
    .from("contracts_billing_masked")
    .select(
      "id, client_id, legal_entity_id, entry_number, exit_number, contract_type, status, period_start, period_end, renewal_of, billing_rule, estimated_value, previous_year_value, drive_ref, notes, offer_structure, ac_link",
    )
    .eq("id", id)
    .maybeSingle<ContractRow>();

  if (!contract) {
    return <AccessDenied reason="Contract not found, or not visible to your role." />;
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

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <div>
        <Link href="/contracts" className="font-body text-muted text-xs hover:underline">
          ← Contracts
        </Link>
        <h1
          className={`font-display text-2xl ${contract.exit_number ? "text-brand-pink" : "text-muted italic"}`}
        >
          {contract.exit_number || `No exit number yet — ${client?.name ?? contract.client_id}`}
        </h1>
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          <Badge>{contract.contract_type}</Badge>
          <Badge tone={contract.status === "signed" ? "neutral" : "pink"}>
            {contract.status}
          </Badge>
          {isDemoRecord(contract.notes) && (
            <span
              title="Example seed record — not a verified real contract."
              className="font-body inline-flex w-fit items-center gap-1 rounded-full bg-orange-100 px-2.5 py-0.5 text-xs font-medium text-orange-700"
            >
              ⚠ Demo data
            </span>
          )}
          {canManage && (contract.status === "draft" || contract.status === "sent") && (
            <MarkSignedButton contractId={contract.id} />
          )}
        </div>
        {canManage && contract.status === "draft" && (
          <div className="mt-2">
            <DeleteContractButton
              contractId={contract.id}
              label={contract.exit_number || contract.entry_number || "this draft"}
            />
          </div>
        )}
      </div>

      <ContractDetailClient
        contract={contract}
        clientName={client?.name ?? contract.client_id}
        legalEntityName={legalEntity?.name ?? contract.legal_entity_id}
        financeVisible={financeVisible}
        canManage={canManage}
        clientOptions={clientOptions}
        legalEntityOptions={legalEntityOptions}
      />
    </div>
  );
}

function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink" ? "bg-brand-pink/10 text-brand-pink" : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}

function AccessDenied({ reason }: { reason: string }) {
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">Access denied</h1>
      <p className="font-body text-muted mt-1 text-sm">{reason}</p>
    </div>
  );
}
