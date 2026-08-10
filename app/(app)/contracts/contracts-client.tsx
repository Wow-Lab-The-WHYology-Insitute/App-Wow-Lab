"use client";

import { useState, useTransition } from "react";
import Link from "next/link";
import { addContract } from "./actions";

type Contract = {
  id: string;
  contract_number: string;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
  clientName: string;
  legalEntityName: string;
};
type Option = { id: string; name: string };

const CONTRACT_TYPES = ["recurring_annual", "one_off_event", "framework"];

export function ContractsClient({
  contracts,
  financeVisible,
  createOrgId,
  clientOptions,
  legalEntityOptions,
}: {
  contracts: Contract[];
  financeVisible: boolean;
  createOrgId: string | null;
  clientOptions: Option[];
  legalEntityOptions: Option[];
}) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex flex-col gap-6">
      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {/* contract_administrator (+Master)-gated, same capability logic as
          the RLS INSERT policy — see canManageContracts() in page.tsx. */}
      {createOrgId && (
        <NewContractForm
          clientOptions={clientOptions}
          legalEntityOptions={legalEntityOptions}
          isPending={isPending}
          onSubmit={(clientId, legalEntityId, number, type, start, end, rule) => {
            setError(null);
            startTransition(async () => {
              const result = await addContract(
                createOrgId,
                clientId,
                legalEntityId,
                number,
                type,
                start,
                end,
                rule,
              );
              if (!result.ok) setError(result.error);
            });
          }}
        />
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Contracts ({contracts.length})
        </h2>

        {contracts.length === 0 ? (
          <p className="font-body text-muted text-sm">
            No contracts visible for your role.
          </p>
        ) : (
          <>
            <table className="hidden w-full border-collapse text-sm md:table">
              <thead>
                <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                  <th className="py-2 pr-4 font-bold">Number</th>
                  <th className="py-2 pr-4 font-bold">Client</th>
                  <th className="py-2 pr-4 font-bold">Type</th>
                  <th className="py-2 pr-4 font-bold">Status</th>
                  <th className="py-2 pr-4 font-bold">Period</th>
                  <th className="py-2 pr-4 font-bold">Entity</th>
                  <th className="py-2 font-bold">Billing rule</th>
                </tr>
              </thead>
              <tbody>
                {contracts.map((c) => (
                  <tr
                    key={c.id}
                    className="font-body text-ink border-b border-black/5 last:border-0"
                  >
                    <td className="py-3 pr-4">
                      <Link
                        href={`/contracts/${c.id}`}
                        className="text-brand-pink font-mono text-xs font-semibold hover:underline"
                      >
                        {c.contract_number}
                      </Link>
                    </td>
                    <td className="py-3 pr-4">{c.clientName}</td>
                    <td className="py-3 pr-4">
                      <Badge>{c.contract_type}</Badge>
                    </td>
                    <td className="py-3 pr-4">
                      <Badge tone={c.status === "signed" ? "neutral" : "pink"}>
                        {c.status}
                      </Badge>
                    </td>
                    <td className="text-muted py-3 pr-4 text-xs">
                      {c.period_start ?? "—"} → {c.period_end ?? "—"}
                    </td>
                    <td className="text-muted py-3 pr-4 text-xs">{c.legalEntityName}</td>
                    <td className="py-3">
                      <MaskedValue value={c.billing_rule} financeVisible={financeVisible} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="flex flex-col gap-3 md:hidden">
              {contracts.map((c) => (
                <Link
                  key={c.id}
                  href={`/contracts/${c.id}`}
                  className="block rounded-xl border border-black/5 p-4"
                >
                  <p className="font-body text-brand-pink font-mono text-xs font-semibold">
                    {c.contract_number}
                  </p>
                  <p className="font-body text-ink mt-1 text-sm font-semibold">
                    {c.clientName}
                  </p>
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    <Badge>{c.contract_type}</Badge>
                    <Badge tone={c.status === "signed" ? "neutral" : "pink"}>
                      {c.status}
                    </Badge>
                  </div>
                  <p className="font-body text-muted mt-2 text-xs">
                    {c.period_start ?? "—"} → {c.period_end ?? "—"} ·{" "}
                    {c.legalEntityName}
                  </p>
                  <p className="font-body text-ink mt-1 text-sm">
                    <MaskedValue value={c.billing_rule} financeVisible={financeVisible} />
                  </p>
                </Link>
              ))}
            </div>
          </>
        )}
      </section>
    </div>
  );
}

function NewContractForm({
  clientOptions,
  legalEntityOptions,
  isPending,
  onSubmit,
}: {
  clientOptions: Option[];
  legalEntityOptions: Option[];
  isPending: boolean;
  onSubmit: (
    clientId: string,
    legalEntityId: string,
    number: string,
    type: string,
    start: string,
    end: string,
    rule: string,
  ) => void;
}) {
  const [clientId, setClientId] = useState(clientOptions[0]?.id ?? "");
  const [legalEntityId, setLegalEntityId] = useState(legalEntityOptions[0]?.id ?? "");
  const [number, setNumber] = useState("");
  const [type, setType] = useState(CONTRACT_TYPES[0]);
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [rule, setRule] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        New contract
      </h2>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <select
          value={clientId}
          onChange={(e) => setClientId(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          <option value="">Select client…</option>
          {clientOptions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={legalEntityId}
          onChange={(e) => setLegalEntityId(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          <option value="">Select legal entity…</option>
          {legalEntityOptions.map((e) => (
            <option key={e.id} value={e.id}>
              {e.name}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={number}
          onChange={(e) => setNumber(e.target.value)}
          placeholder="Contract number"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {CONTRACT_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
        <input
          type="date"
          value={start}
          onChange={(e) => setStart(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="date"
          value={end}
          onChange={(e) => setEnd(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={rule}
          onChange={(e) => setRule(e.target.value)}
          placeholder="Billing rule (e.g. 95 lei/child/session)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !clientId || !legalEntityId || !number.trim()}
        onClick={() => onSubmit(clientId, legalEntityId, number, type, start, end, rule)}
        className="font-body mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        + New contract
      </button>
    </section>
  );
}

// Same treatment as clients/[id]/page.tsx's MaskedValue — duplicated
// locally rather than shared, matching this codebase's existing
// convention of not centralizing small per-screen presentational helpers
// (see Badge/Section/Kv repeated across admin-users-client.tsx and
// whoami/page.tsx already).
function MaskedValue({
  value,
  financeVisible,
}: {
  value: string | null;
  financeVisible: boolean;
}) {
  if (value !== null) return <span>{value}</span>;
  if (financeVisible) return <span className="text-muted text-xs">Not set</span>;
  return <span className="text-muted font-mono text-xs tracking-wide">••••• 🔒</span>;
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
