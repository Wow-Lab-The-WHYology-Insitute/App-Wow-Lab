import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { ClientsClient } from "./clients-client";

type MembershipRow = { organization_id: string };
type ClientRow = {
  id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
  legal_name: string | null;
  cui: string | null;
  created_at: string;
};
type ContractLookupRow = { client_id: string; legal_entity_id: string };
type LegalEntityLookupRow = { id: string; name: string };

// C2: list page for the Clients & Contracts domain (C1 schema/RLS). No
// manual org-scoping on the fetch itself — clients' SELECT policy
// (202608100003) already resolves exactly which rows this session can
// see (record-level segregation for finance_operations/finance_admin_
// reporting included), so this is a plain select, same shape as
// whoami/page.tsx's RLS-proof queries.
export default async function ClientsPage() {
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

  // Only used to (a) decide whether "+ New Client" renders and (b) know
  // which org a newly created client should belong to — the RLS policy on
  // clients (clients.create) is what actually decides whether the insert
  // succeeds, same relationship as admin/users' assertCanManageOrg.
  let createOrgId: string | null = null;
  for (const m of memberships ?? []) {
    if (await checkCapability(supabase, "clients.create", m.organization_id)) {
      createOrgId = m.organization_id;
      break;
    }
  }

  const { data: clients } = await supabase
    .from("clients")
    .select("id, name, client_type, status, business_line, legal_name, cui, created_at")
    .order("name")
    .returns<ClientRow[]>();

  // Which legal entity(ies) bill a client — derived from their contracts,
  // same "Billed via" concept already computed on the client detail page
  // (a client isn't itself tied to one entity; it can have contracts
  // across several). Surfaced here too now that the list carries an
  // Entity column. RLS-scoped like everything else: a caller who can't
  // see a given contract can't derive its entity through this side
  // channel either — this can only ever show LESS than the client detail
  // page's own "Billed via", never more.
  const clientIds = (clients ?? []).map((c) => c.id);
  const { data: contractRows } =
    clientIds.length > 0
      ? await supabase
          .from("contracts")
          .select("client_id, legal_entity_id")
          .in("client_id", clientIds)
          .returns<ContractLookupRow[]>()
      : { data: [] as ContractLookupRow[] };
  const legalEntityIds = [...new Set((contractRows ?? []).map((c) => c.legal_entity_id))];
  const { data: legalEntityRows } =
    legalEntityIds.length > 0
      ? await supabase
          .from("legal_entities")
          .select("id, name")
          .in("id", legalEntityIds)
          .returns<LegalEntityLookupRow[]>()
      : { data: [] as LegalEntityLookupRow[] };
  const legalEntityNameById = new Map((legalEntityRows ?? []).map((e) => [e.id, e.name]));

  const billingEntitiesByClient = new Map<string, string[]>();
  for (const row of contractRows ?? []) {
    const name = legalEntityNameById.get(row.legal_entity_id);
    if (!name) continue;
    const list = billingEntitiesByClient.get(row.client_id) ?? [];
    if (!list.includes(name)) list.push(name);
    billingEntitiesByClient.set(row.client_id, list);
  }

  const rows = (clients ?? []).map((c) => ({
    ...c,
    billingEntities: (billingEntitiesByClient.get(c.id) ?? []).sort(),
  }));

  return (
    <div className="flex w-full flex-col gap-6">
      <ClientsClient clients={rows} createOrgId={createOrgId} />
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
