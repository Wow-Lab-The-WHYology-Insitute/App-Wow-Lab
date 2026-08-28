"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "../i18n";
import { contractsDict } from "../../contracts/i18n";

type ContractRow = {
  id: string;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
  legal_entity_id: string;
};

// This client's own contracts sub-list, embedded in the client detail page
// -- same Server/Client split reasoning as client-header.tsx. contract_type
// and status are genuinely CONTRACT vocabulary, not client vocabulary --
// imported from contractsDict (the one place those translations live)
// rather than copied into clientsDict a third time, same principle as
// app/(app)/i18n.ts borrowing page_title instead of redeclaring it.
export function ClientContractsSection({
  contracts,
  clientName,
  financeVisible,
}: {
  contracts: ContractRow[];
  clientName: string;
  financeVisible: boolean;
}) {
  const t = useTranslations(clientsDict);
  const tContract = useTranslations(contractsDict);

  return (
    <Section title={t("contracts_heading", { count: contracts.length })}>
      {contracts.length === 0 ? (
        <Empty>{t("empty_no_contracts_on_file")}</Empty>
      ) : (
        <ul className="flex flex-col gap-3">
          {contracts.map((c) => (
            <li key={c.id} className="border-b border-black/5 pb-3 last:border-0 last:pb-0">
              <Link
                href={`/contracts/${c.id}`}
                className={`font-body font-mono text-sm font-semibold hover:underline ${
                  c.exit_number ? "text-brand-pink" : "text-muted italic"
                }`}
              >
                {c.exit_number || tContract("no_exit_number", { client: clientName })}
              </Link>
              <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
                <Badge>{tContract(`contract_type_${c.contract_type}`)}</Badge>
                <Badge tone={c.status === "signed" ? "neutral" : "pink"}>
                  {tContract(`status_${c.status}`)}
                </Badge>
                <span className="font-body text-muted text-xs">
                  {c.period_start ?? "—"} → {c.period_end ?? "—"}
                </span>
              </div>
              <p className="font-body text-ink mt-1.5 text-sm">
                <MaskedValue value={c.billing_rule} financeVisible={financeVisible} tContract={tContract} />
              </p>
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

// Mirrors the mockup's own masked-field treatment, same as
// clients/[id]/page.tsx originally had inline.
function MaskedValue({
  value,
  financeVisible,
  tContract,
}: {
  value: string | null;
  financeVisible: boolean;
  tContract: (key: string) => string;
}) {
  if (value !== null) return <span>{value}</span>;
  if (financeVisible) return <span className="text-muted">{tContract("masked_not_set")}</span>;
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
