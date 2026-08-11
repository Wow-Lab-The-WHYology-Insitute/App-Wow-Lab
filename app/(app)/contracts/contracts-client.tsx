"use client";

import { useMemo, useState, useTransition } from "react";
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
  client_contract_number: string | null;
  signed_date: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  clientName: string;
  legalEntityName: string;
};
type Option = { id: string; name: string };

const CONTRACT_TYPES = ["recurring_annual", "one_off_event", "framework"];

// Nulls always sort last regardless of direction — an indefinite end date
// or an as-yet-unset field shouldn't dominate either end of the list.
function compareValues(
  a: string | number | null,
  b: string | number | null,
  dir: "asc" | "desc",
) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  const cmp =
    typeof a === "number" && typeof b === "number"
      ? a - b
      : String(a).localeCompare(String(b));
  return dir === "asc" ? cmp : -cmp;
}

type SortKey =
  | "contract_number"
  | "clientName"
  | "contract_type"
  | "status"
  | "period_start"
  | "period_end"
  | "legalEntityName"
  | "client_contract_number"
  | "signed_date"
  | "estimated_value"
  | "previous_year_value";

function SortHeader({
  label,
  sortKey,
  activeKey,
  dir,
  onSort,
  className,
}: {
  label: string;
  sortKey: SortKey;
  activeKey: SortKey;
  dir: "asc" | "desc";
  onSort: (key: SortKey) => void;
  className?: string;
}) {
  const active = sortKey === activeKey;
  return (
    <th className={`py-2 font-bold ${className ?? "pr-4"}`}>
      <button
        type="button"
        onClick={() => onSort(sortKey)}
        className="font-body inline-flex items-center gap-1 text-left text-xs font-bold tracking-wide uppercase"
      >
        {label}
        <span className="text-[10px]" aria-hidden="true">
          {active ? (dir === "asc" ? "▲" : "▼") : ""}
        </span>
      </button>
    </th>
  );
}

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
  // Default: End Date ascending (soonest-expiring first).
  const [sortKey, setSortKey] = useState<SortKey>("period_end");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");

  function onSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  const sortedContracts = useMemo(() => {
    return [...contracts].sort((a, b) => compareValues(a[sortKey], b[sortKey], sortDir));
  }, [contracts, sortKey, sortDir]);

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
          onSubmit={(
            clientId,
            legalEntityId,
            number,
            type,
            start,
            end,
            rule,
            clientContractNumber,
            signedDate,
            estimatedValue,
            previousYearValue,
          ) => {
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
                clientContractNumber,
                signedDate,
                estimatedValue,
                previousYearValue,
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
                  <SortHeader label="Number" sortKey="contract_number" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Client" sortKey="clientName" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Type" sortKey="contract_type" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Status" sortKey="status" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Start Date" sortKey="period_start" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="End Date" sortKey="period_end" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Entity" sortKey="legalEntityName" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Client contract #" sortKey="client_contract_number" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Signed date" sortKey="signed_date" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Est. value" sortKey="estimated_value" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <SortHeader label="Prev. yr value" sortKey="previous_year_value" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                  <th className="py-2 font-bold">Billing rule</th>
                </tr>
              </thead>
              <tbody>
                {sortedContracts.map((c) => (
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
                    <td className="text-muted py-3 pr-4 text-xs">{c.period_start ?? "—"}</td>
                    <td className="text-muted py-3 pr-4 text-xs">{c.period_end ?? "—"}</td>
                    <td className="text-muted py-3 pr-4 text-xs">{c.legalEntityName}</td>
                    <td className="text-muted py-3 pr-4 text-xs">{c.client_contract_number ?? "—"}</td>
                    <td className="text-muted py-3 pr-4 text-xs">{c.signed_date ?? "—"}</td>
                    <td className="py-3 pr-4 text-xs">
                      <MaskedValue value={c.estimated_value} financeVisible={financeVisible} />
                    </td>
                    <td className="py-3 pr-4 text-xs">
                      <MaskedValue value={c.previous_year_value} financeVisible={financeVisible} />
                    </td>
                    <td className="py-3">
                      <MaskedValue value={c.billing_rule} financeVisible={financeVisible} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="flex flex-col gap-3 md:hidden">
              {sortedContracts.map((c) => (
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
                    Start {c.period_start ?? "—"} → End {c.period_end ?? "—"} ·{" "}
                    {c.legalEntityName}
                  </p>
                  {(c.client_contract_number || c.signed_date) && (
                    <p className="font-body text-muted mt-1 text-xs">
                      {c.client_contract_number ? `Ref ${c.client_contract_number}` : ""}
                      {c.client_contract_number && c.signed_date ? " · " : ""}
                      {c.signed_date ? `Signed ${c.signed_date}` : ""}
                    </p>
                  )}
                  <p className="font-body text-ink mt-1 text-sm">
                    <MaskedValue value={c.billing_rule} financeVisible={financeVisible} />
                  </p>
                  <p className="font-body text-muted mt-1 flex gap-2 text-xs">
                    <span>
                      Est: <MaskedValue value={c.estimated_value} financeVisible={financeVisible} />
                    </span>
                    <span>
                      Prev yr: <MaskedValue value={c.previous_year_value} financeVisible={financeVisible} />
                    </span>
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
    clientContractNumber: string,
    signedDate: string,
    estimatedValue: string,
    previousYearValue: string,
  ) => void;
}) {
  const [clientId, setClientId] = useState(clientOptions[0]?.id ?? "");
  const [legalEntityId, setLegalEntityId] = useState(legalEntityOptions[0]?.id ?? "");
  const [number, setNumber] = useState("");
  const [type, setType] = useState(CONTRACT_TYPES[0]);
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [rule, setRule] = useState("");
  const [clientContractNumber, setClientContractNumber] = useState("");
  const [signedDate, setSignedDate] = useState("");
  const [estimatedValue, setEstimatedValue] = useState("");
  const [previousYearValue, setPreviousYearValue] = useState("");

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
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Start Date
          <input
            type="date"
            value={start}
            onChange={(e) => setStart(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          End Date
          <input
            type="date"
            value={end}
            onChange={(e) => setEnd(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <input
          type="text"
          value={rule}
          onChange={(e) => setRule(e.target.value)}
          placeholder="Billing rule (e.g. 95 lei/child/session)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
        <input
          type="text"
          value={clientContractNumber}
          onChange={(e) => setClientContractNumber(e.target.value)}
          placeholder="Client's own contract # (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Signed Date
          <input
            type="date"
            value={signedDate}
            onChange={(e) => setSignedDate(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <input
          type="number"
          step="0.01"
          value={estimatedValue}
          onChange={(e) => setEstimatedValue(e.target.value)}
          placeholder="Estimated value (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="number"
          step="0.01"
          value={previousYearValue}
          onChange={(e) => setPreviousYearValue(e.target.value)}
          placeholder="Previous year value (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !clientId || !legalEntityId || !number.trim()}
        onClick={() =>
          onSubmit(
            clientId,
            legalEntityId,
            number,
            type,
            start,
            end,
            rule,
            clientContractNumber,
            signedDate,
            estimatedValue,
            previousYearValue,
          )
        }
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
  value: string | number | null;
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
