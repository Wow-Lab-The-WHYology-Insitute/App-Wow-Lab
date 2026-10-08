import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { displayName } from "@/lib/display-name";
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
  user_id: string | null;
};

type UserLookupRow = {
  id: string;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
};

type MembershipUserRow = { user_id: string };

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
    .select("id, name, legal_name, cui, service_type, status, notes, user_id")
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

  // The linked person's name for the READ view. Fetched on its own, by id,
  // rather than reading it out of memberOptions below -- the read view
  // renders for every viewer who can see the row, including the supplier
  // themselves via the self-read branch (202610070002), who does not get
  // memberOptions at all. One row, only when there is a link to resolve.
  let linkedUserName: string | null = null;
  if (supplier.user_id) {
    const { data: linked } = await supabase
      .from("users")
      .select("id, full_name, first_name, last_name")
      .eq("id", supplier.user_id)
      .maybeSingle<UserLookupRow>();
    // Null when the viewer cannot read that user's row under users' own
    // SELECT RLS. Left as null rather than substituted with the raw uuid:
    // a viewer who may not see who someone is should not be handed their id.
    linkedUserName = linked ? displayName(linked) || null : null;
  }

  // Picker options for the EDIT form only -- the same "only fetch what the
  // button needs" discipline as groups/[id]/page.tsx's trainerOptions.
  // Every org member, not just trainers: a person-supplier is whoever
  // invoices us, and three of the five seeded by 202610070003 hold no
  // trainer role at all (Anka Orban, Cătălina Trușan, Raluca Margean).
  // Scoping by role here would hide exactly the people this field exists
  // for. Cannot come back empty for anyone who reaches this form --
  // org.members.read is a strict superset of finance.reporting.*, verified
  // live.
  let memberOptions: { id: string; name: string }[] = [];
  if (canEdit) {
    const { data: memberRows } = await supabase
      .from("user_org_roles")
      .select("user_id")
      .returns<MembershipUserRow[]>();
    const memberIds = [...new Set((memberRows ?? []).map((m) => m.user_id))];
    const { data: memberUsers } =
      memberIds.length > 0
        ? await supabase
            .from("users")
            .select("id, full_name, first_name, last_name")
            .in("id", memberIds)
            .returns<UserLookupRow[]>()
        : { data: [] as UserLookupRow[] };
    memberOptions = (memberUsers ?? [])
      .map((u) => ({ id: u.id, name: displayName(u) || "Unnamed" }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6">
      <SupplierHeader name={supplier.name} status={supplier.status} />

      <SupplierInfoClient
        supplier={supplier}
        canEdit={canEdit}
        linkedUserName={linkedUserName}
        memberOptions={memberOptions}
      />
    </div>
  );
}
