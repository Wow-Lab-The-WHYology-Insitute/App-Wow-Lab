import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

type ClientRow = {
  id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
  external_crm_ref: string | null;
  notes: string | null;
};
type ContactRow = {
  id: string;
  full_name: string;
  role_at_client: string | null;
  email: string | null;
  phone: string | null;
  is_billing_contact: boolean;
  is_primary: boolean;
};
type ContractRow = {
  id: string;
  contract_number: string;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
};

const CLIENT_TYPE_LABELS: Record<string, string> = {
  private_school: "Private school",
  state_school: "State school",
  corporate: "Corporate",
  parent_b2c: "Parent B2C",
  special_project: "Special project",
};

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
    return <AccessDenied reason="Not signed in." />;
  }

  const { data: client } = await supabase
    .from("clients")
    .select(
      "id, name, client_type, status, business_line, external_crm_ref, notes",
    )
    .eq("id", id)
    .maybeSingle<ClientRow>();

  if (!client) {
    // Either genuinely missing, or RLS-filtered for this viewer (record-
    // level segregation) — a single-row RLS query can't distinguish the
    // two, and shouldn't: telling a finance_operations user "this
    // corporate client doesn't exist" is the correct behavior, not a bug.
    return <AccessDenied reason="Client not found, or not visible to your role." />;
  }

  const { data: contacts } = await supabase
    .from("client_contacts")
    .select("id, full_name, role_at_client, email, phone, is_billing_contact, is_primary")
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
    .select("id, contract_number, contract_type, status, period_start, period_end, billing_rule")
    .eq("client_id", id)
    .returns<ContractRow[]>();

  // Distinguishes "masked because you lack the capability" from
  // "genuinely never set" for a null billing_rule — same has_capability
  // set the view itself unmasks on (202608100006), so this can't drift
  // out of sync with what the view actually decided for this session.
  let financeVisible = false;
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id);
  for (const m of memberships ?? []) {
    for (const cap of ["finance.operations.*", "finance.reporting.*", "clients.create"]) {
      const { data: allowed } = await supabase.rpc("has_capability", {
        cap,
        org: (m as { organization_id: string }).organization_id,
      });
      if (allowed) {
        financeVisible = true;
        break;
      }
    }
    if (financeVisible) break;
  }

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6">
      <div>
        <Link href="/clients" className="font-body text-muted text-xs hover:underline">
          ← Clients
        </Link>
        <h1 className="font-display text-2xl text-brand-pink">{client.name}</h1>
        <div className="mt-2 flex flex-wrap gap-1.5">
          <Badge>{CLIENT_TYPE_LABELS[client.client_type] ?? client.client_type}</Badge>
          <Badge tone={client.status === "active" ? "neutral" : "pink"}>
            {client.status}
          </Badge>
        </div>
      </div>

      <Section title="Client info">
        <Kv label="Business line" value={client.business_line || "—"} />
        <Kv label="External CRM ref" value={client.external_crm_ref || "—"} mono />
        <Kv label="Notes" value={client.notes || "—"} />
      </Section>

      <Section title={`Contacts (${contacts?.length ?? 0})`}>
        {(contacts ?? []).length === 0 ? (
          <Empty>No contacts on file.</Empty>
        ) : (
          <ul className="flex flex-col gap-3">
            {(contacts ?? []).map((c) => (
              <li key={c.id} className="border-b border-black/5 pb-3 last:border-0 last:pb-0">
                <p className="font-body text-ink font-semibold">
                  {c.full_name}
                  {c.role_at_client && (
                    <span className="text-muted ml-2 font-normal">
                      {c.role_at_client}
                    </span>
                  )}
                </p>
                <p className="font-body text-muted mt-1 text-xs">
                  {c.email || "—"} {c.phone ? `· ${c.phone}` : ""}
                </p>
                <div className="mt-1.5 flex gap-1.5">
                  {c.is_primary && <Badge>Primary</Badge>}
                  {c.is_billing_contact && <Badge>Billing contact</Badge>}
                </div>
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section title={`Contracts (${contracts?.length ?? 0})`}>
        {(contracts ?? []).length === 0 ? (
          <Empty>No contracts on file.</Empty>
        ) : (
          <ul className="flex flex-col gap-3">
            {(contracts ?? []).map((c) => (
              <li key={c.id} className="border-b border-black/5 pb-3 last:border-0 last:pb-0">
                <Link
                  href={`/contracts/${c.id}`}
                  className="font-body text-brand-pink font-mono text-sm font-semibold hover:underline"
                >
                  {c.contract_number}
                </Link>
                <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
                  <Badge>{c.contract_type}</Badge>
                  <Badge tone={c.status === "signed" ? "neutral" : "pink"}>
                    {c.status}
                  </Badge>
                  <span className="font-body text-muted text-xs">
                    {c.period_start ?? "—"} → {c.period_end ?? "—"}
                  </span>
                </div>
                <p className="font-body text-ink mt-1.5 text-sm">
                  <MaskedValue value={c.billing_rule} financeVisible={financeVisible} />
                </p>
              </li>
            ))}
          </ul>
        )}
      </Section>
    </div>
  );
}

// Mirrors the mockup's own masked-field treatment (docs/mockup/
// wow_lab_os_mockup.html: `.masked{font-family:monospace;...}`, "••••• 🔒")
// — a blank cell would read as missing data, not intentional masking.
function MaskedValue({
  value,
  financeVisible,
}: {
  value: string | null;
  financeVisible: boolean;
}) {
  if (value !== null) return <span>{value}</span>;
  if (financeVisible) return <span className="text-muted">Not set</span>;
  return (
    <span className="text-muted font-mono tracking-wide">••••• 🔒</span>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

function Kv({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className={`text-ink ${mono ? "font-mono text-xs" : "font-body font-medium"}`}>
        {value}
      </span>
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

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="font-body text-muted text-sm">{children}</p>;
}

function AccessDenied({ reason }: { reason: string }) {
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">Access denied</h1>
      <p className="font-body text-muted mt-1 text-sm">{reason}</p>
    </div>
  );
}
