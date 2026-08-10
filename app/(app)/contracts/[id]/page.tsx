import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { MarkSignedButton } from "./mark-signed-button";

type ContractRow = {
  id: string;
  client_id: string;
  legal_entity_id: string;
  contract_number: string;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  renewal_of: string | null;
  billing_rule: string | null;
  drive_ref: string | null;
  notes: string | null;
};

// Same branching as contracts/page.tsx's canManageContracts() — kept as
// its own local copy rather than a shared import, matching this
// codebase's existing convention (the has_capability-loop pattern is
// duplicated per-file throughout, e.g. layout.tsx / admin/users/page.tsx
// / whoami/page.tsx all carry their own copy).
async function canManageContracts(
  supabase: Awaited<ReturnType<typeof createClient>>,
  org: string,
) {
  const [{ data: isOwner }, { data: hasContractsStar }, { data: isFinanceReporting }, { data: isFinanceOps }] =
    await Promise.all([
      supabase.rpc("has_capability", { cap: "org.settings.manage", org }),
      supabase.rpc("has_capability", { cap: "contracts.*", org }),
      supabase.rpc("has_capability", { cap: "finance.reporting.*", org }),
      supabase.rpc("has_capability", { cap: "finance.operations.*", org }),
    ]);
  return Boolean(isOwner) || (Boolean(hasContractsStar) && !isFinanceReporting && !isFinanceOps);
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
      "id, client_id, legal_entity_id, contract_number, contract_type, status, period_start, period_end, renewal_of, billing_rule, drive_ref, notes",
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
  let financeVisible = false;
  for (const m of memberships ?? []) {
    const org = (m as { organization_id: string }).organization_id;
    if (!canManage && (await canManageContracts(supabase, org))) canManage = true;
    if (!financeVisible) {
      for (const cap of ["finance.operations.*", "finance.reporting.*", "clients.create"]) {
        const { data: allowed } = await supabase.rpc("has_capability", { cap, org });
        if (allowed) {
          financeVisible = true;
          break;
        }
      }
    }
    if (canManage && financeVisible) break;
  }

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <div>
        <Link href="/contracts" className="font-body text-muted text-xs hover:underline">
          ← Contracts
        </Link>
        <h1 className="font-display text-2xl text-brand-pink">
          {contract.contract_number}
        </h1>
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          <Badge>{contract.contract_type}</Badge>
          <Badge tone={contract.status === "signed" ? "neutral" : "pink"}>
            {contract.status}
          </Badge>
          {canManage && contract.status !== "signed" && (
            <MarkSignedButton contractId={contract.id} />
          )}
        </div>
      </div>

      <Section title="Details">
        <Kv
          label="Client"
          value={client?.name ?? contract.client_id}
          href={client ? `/clients/${client.id}` : undefined}
        />
        <Kv label="Legal entity" value={legalEntity?.name ?? contract.legal_entity_id} />
        <Kv label="Period" value={`${contract.period_start ?? "—"} → ${contract.period_end ?? "—"}`} />
        <Kv label="Renewal of" value={contract.renewal_of ?? "—"} mono={Boolean(contract.renewal_of)} />
        <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
          <span className="font-body text-muted">Billing rule</span>
          <span className="text-ink font-body font-medium">
            <MaskedValue value={contract.billing_rule} financeVisible={financeVisible} />
          </span>
        </div>
        <Kv
          label="Drive archive"
          value={contract.drive_ref ? "Open link" : "—"}
          href={contract.drive_ref ?? undefined}
          external
        />
        <Kv label="Notes" value={contract.notes || "—"} />
      </Section>
    </div>
  );
}

function MaskedValue({
  value,
  financeVisible,
}: {
  value: string | null;
  financeVisible: boolean;
}) {
  if (value !== null) return <span>{value}</span>;
  if (financeVisible) return <span className="text-muted">Not set</span>;
  return <span className="text-muted font-mono tracking-wide">••••• 🔒</span>;
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

function Kv({
  label,
  value,
  mono,
  href,
  external,
}: {
  label: string;
  value: string;
  mono?: boolean;
  href?: string;
  external?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      {href ? (
        <a
          href={href}
          target={external ? "_blank" : undefined}
          rel={external ? "noreferrer" : undefined}
          className="text-brand-pink font-body font-medium hover:underline"
        >
          {value}
        </a>
      ) : (
        <span className={`text-ink ${mono ? "font-mono text-xs" : "font-body font-medium"}`}>
          {value}
        </span>
      )}
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
