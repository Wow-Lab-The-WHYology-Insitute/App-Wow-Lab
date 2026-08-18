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

  return (
    <div className="flex w-full flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl text-brand-pink">Clients</h1>
        <p className="font-body text-muted mt-1 text-sm">
          Operational client accounts. Sales pipeline stays in
          ActiveCampaign — this is the handoff point from &quot;Won&quot;
          onward.
        </p>
      </div>
      <ClientsClient clients={clients ?? []} createOrgId={createOrgId} />
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
