import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { SuppliersClient } from "./suppliers-client";
import { AccessDenied } from "@/components/ui/access-denied";

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
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
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

  // Contract counts, and the gate on them is deliberately STRICTER than the
  // lock on the supplier sheet. There the section renders for everyone and
  // says it is withholding something; here the column must not exist at all
  // for a viewer without the capability -- not empty, and not offered in the
  // Columns dropdown either. A count IS information: "3" tells Laura exactly
  // what the lock on the sheet refuses to tell her.
  //
  // Counted here rather than in the client because the counts must not reach
  // a browser that is not allowed to have them. canSeeContracts is the server
  // capability check, never contracts.length -- three suppliers really do have
  // zero, and that must not read as a refusal.
  const canSeeContracts = createOrgId !== null;
  let contractCounts: Record<string, number> | null = null;
  if (canSeeContracts) {
    const { data: contractRows } = await supabase
      .from("supplier_contracts")
      // Only the roots: an amendment belongs to the contract it amends and is
      // not one of its own, so Raluca's three rows are one contract. Same
      // count the supplier sheet's heading shows.
      .select("supplier_id")
      .is("amends_contract_id", null)
      .returns<{ supplier_id: string }[]>();
    contractCounts = {};
    for (const row of contractRows ?? []) {
      contractCounts[row.supplier_id] = (contractCounts[row.supplier_id] ?? 0) + 1;
    }
  }

  return (
    <div className="gap-page flex w-full flex-col">
      <SuppliersClient
        suppliers={suppliers ?? []}
        createOrgId={createOrgId}
        contractCounts={contractCounts}
      />
    </div>
  );
}
