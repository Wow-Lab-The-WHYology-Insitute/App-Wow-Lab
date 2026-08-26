import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { ContractsClient } from "./contracts-client";

type MembershipRow = { organization_id: string };
type ContractRow = {
  id: string;
  organization_id: string;
  client_id: string;
  legal_entity_id: string;
  entry_number: string | null;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
  signed_date: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  offer_structure: string | null;
  ac_link: string | null;
  drive_ref: string | null;
  notes: string | null;
};
type ClientLookupRow = { id: string; name: string; legal_name: string | null; cui: string | null };
type LegalEntityLookupRow = { id: string; name: string };
type ClientOptionRow = { id: string; name: string; organization_id: string };
type LegalEntityOptionRow = { id: string; name: string; organization_id: string };

// Mirrors the exact branching in the contracts RLS policy
// (202608100003): contract_administrator (contracts.* without either
// finance capability) or an organization_owner/platform_owner (via
// has_capability's own is_platform_owner() bypass + org.settings.manage
// for the owner) can write. finance_admin_reporting shares the identical
// contracts.* key but is deliberately excluded here, same as in the
// policy — this is a UI convenience, not the real gate, so it has to
// agree with the policy or the button lies about what will happen.
//
// Gates "+ New Contract" (createOrgId). Routed through the shared
// checkCapability() helper (lib/capabilities.ts, retry-once + logged-on-
// failure) rather than a bare supabase.rpc() call — a capability-gating
// audit found this was the one direct-RPC call backing an actual write
// affordance (the detail panel's former "Edit" button also used this
// function's result before that button was removed); every OTHER direct-
// RPC capability check elsewhere in the app (clients/page.tsx, groups/
// page.tsx, etc.) still calls the RPC directly and was deliberately left
// alone, per that audit's own scope.
async function canManageContracts(
  supabase: Awaited<ReturnType<typeof createClient>>,
  org: string,
) {
  const [isOwner, hasContractsStar, isFinanceReporting, isFinanceOps] = await Promise.all([
    checkCapability(supabase, "org.settings.manage", org),
    checkCapability(supabase, "contracts.*", org),
    checkCapability(supabase, "finance.reporting.*", org),
    checkCapability(supabase, "finance.operations.*", org),
  ]);
  return isOwner || (hasContractsStar && !isFinanceReporting && !isFinanceOps);
}

// Mirrors the exact non-finance branch of the contracts SELECT policy
// (202608100003) that returns the FULL, unsegmented set -- broader than
// canManageContracts above (which is about edit rights and requires
// contracts.*), this also admits contracts.read-only holders (Sales
// Manager, Operations Manager), since they see the same unsegmented set
// through the identical policy branch. finance.operations.*/
// finance.reporting.* holders are excluded on purpose: they satisfy a
// DIFFERENT, client-type-segmented branch of the same policy (confirmed
// live, see docs/OPEN_ITEMS.md), so the same COUNT query would silently
// return a partial number for their session. This gates the overdue/
// renewal-pressure banner -- a role that would get a wrong number doesn't
// get the banner at all.
async function seesUnsegmentedContracts(
  supabase: Awaited<ReturnType<typeof createClient>>,
  org: string,
) {
  const [isOwner, hasContractsStar, hasContractsRead, isFinanceReporting, isFinanceOps] =
    await Promise.all([
      checkCapability(supabase, "org.settings.manage", org),
      checkCapability(supabase, "contracts.*", org),
      checkCapability(supabase, "contracts.read", org),
      checkCapability(supabase, "finance.reporting.*", org),
      checkCapability(supabase, "finance.operations.*", org),
    ]);
  return (
    isOwner || ((hasContractsStar || hasContractsRead) && !isFinanceReporting && !isFinanceOps)
  );
}

export default async function ContractsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reason="Not signed in." />;
  }

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  let createOrgId: string | null = null;
  for (const m of memberships ?? []) {
    if (await canManageContracts(supabase, m.organization_id)) {
      createOrgId = m.organization_id;
      break;
    }
  }

  // billing_rule always read from the masked view — same reasoning as
  // clients/[id]/page.tsx.
  const { data: contracts } = await supabase
    .from("contracts_billing_masked")
    .select(
      "id, organization_id, client_id, legal_entity_id, entry_number, exit_number, contract_type, status, period_start, period_end, billing_rule, signed_date, estimated_value, previous_year_value, offer_structure, ac_link, drive_ref, notes",
    )
    .order("exit_number", { ascending: true, nullsFirst: false })
    .returns<ContractRow[]>();

  // Two follow-up lookups rather than a PostgREST embed through the view
  // (views don't reliably expose the FK relationships PostgREST needs for
  // `contracts_billing_masked(clients(name))`-style embedding) — both
  // small, RLS-filtered on their own terms, joined by id below.
  const clientIds = [...new Set((contracts ?? []).map((c) => c.client_id))];
  const legalEntityIds = [...new Set((contracts ?? []).map((c) => c.legal_entity_id))];

  const { data: clientRows } =
    clientIds.length > 0
      ? await supabase
          .from("clients")
          .select("id, name, legal_name, cui")
          .in("id", clientIds)
          .returns<ClientLookupRow[]>()
      : { data: [] as ClientLookupRow[] };
  const { data: legalEntityRows } =
    legalEntityIds.length > 0
      ? await supabase
          .from("legal_entities")
          .select("id, name")
          .in("id", legalEntityIds)
          .returns<LegalEntityLookupRow[]>()
      : { data: [] as LegalEntityLookupRow[] };

  const clientNameById = new Map((clientRows ?? []).map((c) => [c.id, c.name]));
  const clientLegalNameById = new Map((clientRows ?? []).map((c) => [c.id, c.legal_name]));
  const clientCuiById = new Map((clientRows ?? []).map((c) => [c.id, c.cui]));
  const legalEntityNameById = new Map(
    (legalEntityRows ?? []).map((e) => [e.id, e.name]),
  );

  // Financial-visibility flag for the masked-vs-not-set distinction, same
  // approach as clients/[id]/page.tsx.
  let financeVisible = false;
  let bannerEligible = false;
  for (const m of memberships ?? []) {
    for (const cap of ["finance.operations.*", "finance.reporting.*", "clients.create"]) {
      if (await checkCapability(supabase, cap, m.organization_id)) {
        financeVisible = true;
        break;
      }
    }
    if (!bannerEligible && (await seesUnsegmentedContracts(supabase, m.organization_id))) {
      bannerEligible = true;
    }
    if (financeVisible && bannerEligible) break;
  }

  // Form options for "+ New Contract": clients + legal entities in the
  // org the caller can create contracts in (only fetched when that org is
  // known, i.e. the button will actually render).
  let clientOptions: ClientOptionRow[] = [];
  let legalEntityOptions: LegalEntityOptionRow[] = [];
  if (createOrgId) {
    const [{ data: co }, { data: leo }] = await Promise.all([
      supabase
        .from("clients")
        .select("id, name, organization_id")
        .eq("organization_id", createOrgId)
        .order("name")
        .returns<ClientOptionRow[]>(),
      supabase
        .from("legal_entities")
        .select("id, name, organization_id")
        .eq("organization_id", createOrgId)
        .order("name")
        .returns<LegalEntityOptionRow[]>(),
    ]);
    clientOptions = co ?? [];
    legalEntityOptions = leo ?? [];
  }

  const rows = (contracts ?? []).map((c) => ({
    ...c,
    clientName: clientNameById.get(c.client_id) ?? c.client_id,
    clientLegalName: clientLegalNameById.get(c.client_id) ?? null,
    clientCui: clientCuiById.get(c.client_id) ?? null,
    legalEntityName: legalEntityNameById.get(c.legal_entity_id) ?? c.legal_entity_id,
  }));

  return (
    <div className="flex w-full flex-col gap-6">
      <ContractsClient
        contracts={rows}
        financeVisible={financeVisible}
        bannerEligible={bannerEligible}
        createOrgId={createOrgId}
        clientOptions={clientOptions}
        legalEntityOptions={legalEntityOptions}
      />
    </div>
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
