"use client";

import { useState, useTransition } from "react";
import Link from "next/link";
import { addClient } from "./actions";

type Client = {
  id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
};

const CLIENT_TYPE_LABELS: Record<string, string> = {
  private_school: "Private school",
  state_school: "State school",
  corporate: "Corporate",
  parent_b2c: "Parent B2C",
  special_project: "Special project",
};

export function ClientsClient({
  clients,
  createOrgId,
}: {
  clients: Client[];
  createOrgId: string | null;
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

      {/* clients.create capability gate — same pattern as admin/users'
          InviteForm, only rendered when the server already found an org
          the caller can create clients in. The RLS INSERT policy is the
          real gate; this just avoids showing a form that would 403. */}
      {createOrgId && (
        <NewClientForm
          orgId={createOrgId}
          isPending={isPending}
          onSubmit={(name, clientType, businessLine) => {
            setError(null);
            startTransition(async () => {
              const result = await addClient(
                createOrgId,
                name,
                clientType,
                businessLine,
              );
              if (!result.ok) setError(result.error);
            });
          }}
        />
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Clients ({clients.length})
        </h2>

        {clients.length === 0 ? (
          <p className="font-body text-muted text-sm">
            No clients visible for your role.
          </p>
        ) : (
          <>
            {/* Desktop/tablet: table, shown at md and up — same
                table->cards split as admin-users-client.tsx. */}
            <table className="hidden w-full border-collapse text-sm md:table">
              <thead>
                <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                  <th className="py-2 pr-4 font-bold">Name</th>
                  <th className="py-2 pr-4 font-bold">Type</th>
                  <th className="py-2 pr-4 font-bold">Status</th>
                  <th className="py-2 font-bold">Business line</th>
                </tr>
              </thead>
              <tbody>
                {clients.map((client) => (
                  <tr
                    key={client.id}
                    className="font-body text-ink border-b border-black/5 last:border-0"
                  >
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
                    <td className="text-muted py-3">
                      {client.business_line || "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Mobile: cards below md. */}
            <div className="flex flex-col gap-3 md:hidden">
              {clients.map((client) => (
                <Link
                  key={client.id}
                  href={`/clients/${client.id}`}
                  className="block rounded-xl border border-black/5 p-4"
                >
                  <p className="font-body text-brand-pink font-semibold">
                    {client.name}
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
                </Link>
              ))}
            </div>
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
  onSubmit: (name: string, clientType: string, businessLine: string) => void;
}) {
  const [name, setName] = useState("");
  const [clientType, setClientType] = useState("private_school");
  const [businessLine, setBusinessLine] = useState("");

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
        <button
          type="button"
          disabled={isPending || !name.trim()}
          onClick={() => onSubmit(name, clientType, businessLine)}
          className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          + New client
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
