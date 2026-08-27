import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { SuppliersClient } from "./suppliers-client";

type MembershipRow = { organization_id: string };
type SupplierRow = {
  id: string;
  name: string;
  legal_name: string | null;
  cui: string | null;
  service_type: string | null;
  status: string;
  notes: string | null;
};

// finance.reporting.* is the entire gate -- SELECT/INSERT/UPDATE on
// suppliers all share the identical predicate (202608300001:
// is_platform_owner() OR finance.reporting.*), confirmed live before
// writing that migration. Checking finance.reporting.* alone is enough
// here even for platform_owner: confirmed live that role holds
// finance.reporting.* directly too, so there's no case in production
// today this single check would miss.
export default async function SuppliersPage() {
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
    if (await checkCapability(supabase, "finance.reporting.*", m.organization_id)) {
      createOrgId = m.organization_id;
      break;
    }
  }

  const { data: suppliers } = await supabase
    .from("suppliers")
    .select("id, name, legal_name, cui, service_type, status, notes")
    .order("name")
    .returns<SupplierRow[]>();

  return (
    <div className="flex w-full flex-col gap-6">
      <SuppliersClient suppliers={suppliers ?? []} createOrgId={createOrgId} />
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
