import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { isDemoRecord } from "../format";
import { MarkSignedButton } from "./mark-signed-button";

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
  drive_ref: string | null;
  notes: string | null;
  offer_structure: string | null;
  ac_link: string | null;
};

// Matches the contracts.offer_structure check constraint (202608160002)
// exactly.
const OFFER_STRUCTURE_LABELS: Record<string, string> = {
  fixed_price_group_workshop: "Fixed price per group workshop",
  price_per_child_present: "Price per child present",
  price_per_child_enrolled: "Price per child enrolled",
  price_per_contract: "Price per contract",
};

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
      "id, client_id, legal_entity_id, entry_number, exit_number, contract_type, status, period_start, period_end, renewal_of, billing_rule, drive_ref, notes, offer_structure, ac_link",
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
        if (await checkCapability(supabase, cap, org)) {
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
      </div>

      <Section title="Details">
        <Kv
          label="Client"
          value={client?.name ?? contract.client_id}
          href={client ? `/clients/${client.id}` : undefined}
        />
        <Kv label="Legal entity" value={legalEntity?.name ?? contract.legal_entity_id} />
        <Kv label="Entry number" value={contract.entry_number || "—"} />
        <Kv label="Exit number" value={contract.exit_number || "—"} />
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
        <Kv
          label="Offer structure"
          value={
            contract.offer_structure
              ? (OFFER_STRUCTURE_LABELS[contract.offer_structure] ?? contract.offer_structure)
              : "—"
          }
        />
        <Kv
          label="AC link"
          value={contract.ac_link ? "Open link" : "—"}
          href={contract.ac_link ?? undefined}
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
