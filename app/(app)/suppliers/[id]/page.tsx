import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { SupplierInfoClient } from "./supplier-info-client";
import { SupplierHeader } from "./supplier-header";
import { AccessDenied } from "@/components/ui/access-denied";

type SupplierRow = {
  id: string;
  name: string;
  legal_name: string | null;
  cui: string | null;
  service_type: string | null;
  status: string;
  notes: string | null;
};

export default async function SupplierDetailPage({
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

  const { data: supplier } = await supabase
    .from("suppliers")
    .select("id, name, legal_name, cui, service_type, status, notes")
    .eq("id", id)
    .maybeSingle<SupplierRow>();

  if (!supplier) {
    // Either genuinely missing, or RLS-filtered for this viewer -- a
    // single-row RLS query can't distinguish the two, and shouldn't, same
    // reasoning as clients/[id]/page.tsx.
    return <AccessDenied reasonKey="access_denied_not_found_supplier" />;
  }

  // Single capability, both the edit gate here and the table's own
  // INSERT/UPDATE/SELECT predicate (202608300001) -- no split the way
  // clients has (clients.create for general fields vs crm_link.* for one
  // field). Everything on this table is Anca/Anka's, uniformly.
  let canEdit = false;
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id);
  for (const m of memberships ?? []) {
    const org = (m as { organization_id: string }).organization_id;
    if (await checkCapability(supabase, "finance.reporting.*", org)) {
      canEdit = true;
      break;
    }
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6">
      <SupplierHeader name={supplier.name} status={supplier.status} />

      <SupplierInfoClient supplier={supplier} canEdit={canEdit} />
    </div>
  );
}
