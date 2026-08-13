"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addClient } from "./actions";

type Client = {
  id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
  legal_name: string | null;
  cui: string | null;
  created_at: string;
};

const CLIENT_TYPE_LABELS: Record<string, string> = {
  private_school: "Private school",
  state_school: "State school",
  corporate: "Corporate",
  parent_b2c: "Parent B2C",
  special_project: "Special project",
};

// Matches the clients.status check constraint (202608100001) exactly —
// keep in sync if that constraint ever changes.
const CLIENT_STATUS_LABELS: Record<string, string> = {
  prospect: "Prospect",
  active: "Active",
  paused: "Paused",
  churned: "Churned",
};

// Nulls always sort last regardless of direction — a missing legal_name/
// cui shouldn't dominate either end of the list, it should just fall out
// of the way.
function compareValues(a: string | number | null, b: string | number | null, dir: "asc" | "desc") {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  const cmp =
    typeof a === "number" && typeof b === "number"
      ? a - b
      : String(a).localeCompare(String(b));
  return dir === "asc" ? cmp : -cmp;
}

function formatShortDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

type SortKey = "name" | "client_type" | "status" | "business_line" | "legal_name" | "cui" | "created_at";

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

export function ClientsClient({
  clients,
  createOrgId,
}: {
  clients: Client[];
  createOrgId: string | null;
}) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [sortKey, setSortKey] = useState<SortKey>("name");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");

  function onSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  // Search + filters run over the same already-fetched, RLS-scoped array
  // sorting already used (server fetches once in page.tsx; everything past
  // that is client-side over the array in hand) — this can only ever
  // narrow what RLS already returned, never reach past it.
  const filteredClients = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return clients.filter((client) => {
      if (q && !client.name.toLowerCase().includes(q)) return false;
      if (typeFilter !== "all" && client.client_type !== typeFilter) return false;
      if (statusFilter !== "all" && client.status !== statusFilter) return false;
      return true;
    });
  }, [clients, searchQuery, typeFilter, statusFilter]);

  const sortedClients = useMemo(() => {
    return [...filteredClients].sort((a, b) => compareValues(a[sortKey], b[sortKey], sortDir));
  }, [filteredClients, sortKey, sortDir]);

  return (
    <div className="flex flex-col gap-6">
      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {/* clients.create capability gate — same pattern as admin/users'
          InviteForm, only rendered when the server already found an org
          the caller can create clients in. The RLS INSERT policy is the
          real gate; this just avoids showing a form that would 403.
          Collapsed by default (no established pattern to match — /admin/
          users' InviteForm is always-expanded) — inline disclosure, no
          modal, so the list below never leaves view. */}
      {createOrgId && (
        <div className="flex flex-col gap-4">
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
          >
            + New client
          </button>
          {isFormOpen && (
            <NewClientForm
              orgId={createOrgId}
              isPending={isPending}
              onSubmit={(name, clientType, businessLine, legalName, cui) => {
                setError(null);
                startTransition(async () => {
                  const result = await addClient(
                    createOrgId,
                    name,
                    clientType,
                    businessLine,
                    legalName,
                    cui,
                  );
                  if (!result.ok) setError(result.error);
                  else setIsFormOpen(false);
                });
              }}
            />
          )}
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Clients (
          {sortedClients.length !== clients.length
            ? `${sortedClients.length} of ${clients.length}`
            : clients.length}
          )
        </h2>

        {clients.length === 0 ? (
          <p className="font-body text-muted text-sm">
            No clients visible for your role.
          </p>
        ) : (
          <>
            <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by name…"
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
              />
              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
              >
                <option value="all">All types</option>
                {Object.entries(CLIENT_TYPE_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
              >
                <option value="all">All statuses</option>
                {Object.entries(CLIENT_STATUS_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            {sortedClients.length === 0 ? (
              <p className="font-body text-muted text-sm">
                No clients match your search or filters.
              </p>
            ) : (
              <>
                {/* Desktop/tablet: table, shown at md and up — same
                    table->cards split as admin-users-client.tsx. */}
                <table className="hidden w-full border-collapse text-sm md:table">
                  <thead>
                    <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                      <th className="py-2 pr-2 font-bold">#</th>
                      <SortHeader label="Name" sortKey="name" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Type" sortKey="client_type" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Status" sortKey="status" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Business line" sortKey="business_line" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Legal name" sortKey="legal_name" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="CUI" sortKey="cui" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Added" sortKey="created_at" activeKey={sortKey} dir={sortDir} onSort={onSort} className="py-2" />
                    </tr>
                  </thead>
                  <tbody>
                    {sortedClients.map((client, index) => (
                      <tr
                        key={client.id}
                        className="font-body text-ink border-b border-black/5 last:border-0"
                      >
                        <td className="text-muted py-3 pr-2">{index + 1}</td>
                        <td className="py-3 pr-4">
                          <Link
                            href={`/clients/${client.id}`}
                            className="text-brand-pink font-semibold hover:underline"
                          >
                            {client.name}
                          </Link>
                        </td>
                        <td className="py-3 pr-4">
                          <Badge>
                            {CLIENT_TYPE_LABELS[client.client_type] ??
                              client.client_type}
                          </Badge>
                        </td>
                        <td className="py-3 pr-4">
                          <Badge tone={client.status === "active" ? "neutral" : "pink"}>
                            {client.status}
                          </Badge>
                        </td>
                        <td className="text-muted py-3 pr-4">
                          {client.business_line || "—"}
                        </td>
                        <td className="text-muted py-3 pr-4">
                          {client.legal_name || "—"}
                        </td>
                        <td className="text-muted py-3 pr-4 font-mono text-xs">
                          {client.cui || "—"}
                        </td>
                        <td className="text-muted py-3 text-xs">
                          {formatShortDate(client.created_at)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {/* Mobile: cards below md. */}
                <div className="flex flex-col gap-3 md:hidden">
                  {sortedClients.map((client, index) => (
                    <Link
                      key={client.id}
                      href={`/clients/${client.id}`}
                      className="block rounded-xl border border-black/5 p-4"
                    >
                      <p className="font-body text-brand-pink font-semibold">
                        <span className="text-muted font-normal">#{index + 1}</span> {client.name}
                      </p>
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        <Badge>
                          {CLIENT_TYPE_LABELS[client.client_type] ??
                            client.client_type}
                        </Badge>
                        <Badge tone={client.status === "active" ? "neutral" : "pink"}>
                          {client.status}
                        </Badge>
                      </div>
                      {client.business_line && (
                        <p className="font-body text-muted mt-2 text-xs">
                          {client.business_line}
                        </p>
                      )}
                      {(client.legal_name || client.cui) && (
                        <p className="font-body text-muted mt-1 text-xs">
                          {client.legal_name || "—"}
                          {client.cui ? ` · ${client.cui}` : ""}
                        </p>
                      )}
                      <p className="font-body text-muted mt-1 text-xs">
                        Added {formatShortDate(client.created_at)}
                      </p>
                    </Link>
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </section>
    </div>
  );
}

function NewClientForm({
  orgId,
  isPending,
  onSubmit,
}: {
  orgId: string;
  isPending: boolean;
  onSubmit: (
    name: string,
    clientType: string,
    businessLine: string,
    legalName: string,
    cui: string,
  ) => void;
}) {
  const [name, setName] = useState("");
  const [clientType, setClientType] = useState("private_school");
  const [businessLine, setBusinessLine] = useState("");
  const [legalName, setLegalName] = useState("");
  const [cui, setCui] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        New client
      </h2>
      <div className="flex flex-col gap-3 md:flex-row md:items-end md:flex-wrap">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Client name"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
        />
        <select
          value={clientType}
          onChange={(e) => setClientType(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(CLIENT_TYPE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={businessLine}
          onChange={(e) => setBusinessLine(e.target.value)}
          placeholder="Business line (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
        />
        <input
          type="text"
          value={legalName}
          onChange={(e) => setLegalName(e.target.value)}
          placeholder="Legal name (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
        />
        <input
          type="text"
          value={cui}
          onChange={(e) => setCui(e.target.value)}
          placeholder="CUI (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:w-40"
        />
        <button
          type="button"
          disabled={isPending || !name.trim()}
          onClick={() => onSubmit(name, clientType, businessLine, legalName, cui)}
          className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          Create client
        </button>
      </div>
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
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
