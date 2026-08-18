"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addClient } from "./actions";
import { useLocale, useTranslations, LOCALE_SWITCHER_ENABLED } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { clientsDict } from "./i18n";
import { ClientDetailPanel } from "./client-detail-panel";
import { entityShortCode, formatDate } from "@/lib/format";
import {
  DataTable,
  DataTableToolbar,
  ColumnsDropdown,
  TruncatedText,
  usePersistedColumns,
  type DataTableColumn,
  type FilterChip,
} from "@/components/ui/data-table";

type Client = {
  id: string;
  name: string;
  client_type: string;
  status: string;
  business_line: string | null;
  legal_name: string | null;
  cui: string | null;
  created_at: string;
  billingEntities: string[];
};

const CLIENT_TYPES = ["private_school", "state_school", "corporate", "parent_b2c", "special_project"];

// Matches the clients.status check constraint (202608100001) exactly —
// keep in sync if that constraint ever changes.
const CLIENT_STATUSES = ["prospect", "active", "paused", "churned"];

// Nulls always sort last regardless of direction — a missing legal_name/
// cui shouldn't dominate either end of the list, it should just fall out
// of the way. Unchanged from the pre-DataTable implementation.
function compareValues(a: string | number | null, b: string | number | null, dir: "asc" | "desc") {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  const cmp =
    typeof a === "number" && typeof b === "number" ? a - b : String(a).localeCompare(String(b));
  return dir === "asc" ? cmp : -cmp;
}

type SortKey = "name" | "client_type" | "status" | "business_line" | "legal_name" | "cui" | "created_at";

// Preserves the pre-DataTable interactive column-sort feature (Step 9's
// own "keep the existing sort behaviour" requirement) — DataTableColumn's
// header now accepts a ReactNode specifically so this can be passed as a
// column header instead of a plain label.
function SortableHeader({
  label,
  sortKey,
  activeKey,
  dir,
  onSort,
}: {
  label: string;
  sortKey: SortKey;
  activeKey: SortKey;
  dir: "asc" | "desc";
  onSort: (key: SortKey) => void;
}) {
  const active = sortKey === activeKey;
  return (
    <button type="button" onClick={() => onSort(sortKey)} className="inline-flex items-center gap-1">
      {label}
      <span className="text-[10px]" aria-hidden="true">
        {active ? (dir === "asc" ? "▲" : "▼") : ""}
      </span>
    </button>
  );
}

function StatusChip({ status, label }: { status: string; label: string }) {
  return (
    <span
      className={`font-body inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium ${
        status === "active" ? "bg-ink/5 text-ink" : "bg-brand-pink/10 text-brand-pink"
      }`}
    >
      {label}
    </span>
  );
}

function EntityChips({ names, emptyLabel }: { names: string[]; emptyLabel: string }) {
  if (names.length === 0) {
    return <span className="text-muted text-xs">{emptyLabel}</span>;
  }
  return (
    <div className="flex flex-wrap gap-1">
      {names.map((name) => (
        <span
          key={name}
          title={name}
          className="font-mono text-ink inline-flex w-fit items-center rounded bg-ink/5 px-1.5 py-0.5 text-[11px] font-medium"
        >
          {entityShortCode(name)}
        </span>
      ))}
    </div>
  );
}

// The 4 fields moved out of the default column set — each an opt-in extra
// column via the Columns dropdown, same dual pattern /contracts uses
// (compact-by-default, full column on demand), plus each keeps its own
// sort capability once toggled visible.
function buildExtraColumns(
  t: (key: string, vars?: Record<string, string | number>) => string,
  locale: "en" | "ro",
  sortKey: SortKey,
  sortDir: "asc" | "desc",
  onSort: (key: SortKey) => void,
): DataTableColumn<Client>[] {
  return [
    {
      key: "business_line",
      header: (
        <SortableHeader
          label={t("detail_business_line")}
          sortKey="business_line"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 160,
      render: (c) => <TruncatedText value={c.business_line || "—"} className="text-ink text-sm" />,
    },
    {
      key: "legal_name",
      header: (
        <SortableHeader
          label={t("detail_legal_name")}
          sortKey="legal_name"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 200,
      render: (c) => <TruncatedText value={c.legal_name || "—"} className="text-ink text-sm" />,
    },
    {
      key: "cui",
      header: (
        <SortableHeader label={t("detail_cui")} sortKey="cui" activeKey={sortKey} dir={sortDir} onSort={onSort} />
      ),
      width: 100,
      render: (c) => <span className="font-mono text-xs">{c.cui || "—"}</span>,
    },
    {
      key: "created_at",
      header: (
        <SortableHeader
          label={t("detail_added")}
          sortKey="created_at"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 100,
      render: (c) => <span className="text-xs tabular-nums">{formatDate(c.created_at, locale)}</span>,
    },
  ];
}

export function ClientsClient({
  clients,
  createOrgId,
}: {
  clients: Client[];
  createOrgId: string | null;
}) {
  const t = useTranslations(clientsDict);
  const { locale } = useLocale();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [sortKey, setSortKey] = useState<SortKey>("name");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [extraColumns, setExtraColumns] = usePersistedColumns("clients", []);

  function onSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  // Widened from name-only: legal_name and cui are both real identifiers
  // for a client (a school's legal entity name/registration number),
  // same reasoning /contracts' search widened to entry/exit number.
  const filteredClients = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return clients.filter((client) => {
      if (
        q &&
        !client.name.toLowerCase().includes(q) &&
        !(client.legal_name ?? "").toLowerCase().includes(q) &&
        !(client.cui ?? "").toLowerCase().includes(q)
      ) {
        return false;
      }
      if (typeFilter !== "all" && client.client_type !== typeFilter) return false;
      if (statusFilter !== "all" && client.status !== statusFilter) return false;
      return true;
    });
  }, [clients, searchQuery, typeFilter, statusFilter]);

  const sortedClients = useMemo(() => {
    return [...filteredClients].sort((a, b) => compareValues(a[sortKey], b[sortKey], sortDir));
  }, [filteredClients, sortKey, sortDir]);

  const chips: FilterChip[] = [];
  if (typeFilter !== "all") {
    chips.push({ key: "type", label: t(`client_type_${typeFilter}`), onRemove: () => setTypeFilter("all") });
  }
  if (statusFilter !== "all") {
    chips.push({ key: "status", label: t(`status_${statusFilter}`), onRemove: () => setStatusFilter("all") });
  }

  function clearAllFilters() {
    setTypeFilter("all");
    setStatusFilter("all");
  }

  const extraColumnDefs = buildExtraColumns(t, locale, sortKey, sortDir, onSort);
  const activeExtraColumns = extraColumnDefs.filter((c) => extraColumns.includes(c.key));

  const baseColumns: DataTableColumn<Client>[] = [
    {
      key: "client",
      header: (
        <SortableHeader label={t("col_client")} sortKey="name" activeKey={sortKey} dir={sortDir} onSort={onSort} />
      ),
      width: 220,
      sticky: true,
      render: (c) => (
        <div className="flex flex-col justify-center gap-0.5">
          <Link
            href={`/clients/${c.id}`}
            onClick={(e) => e.stopPropagation()}
            title={c.name}
            className="text-brand-pink focus-visible:ring-brand-pink block overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap hover:underline focus-visible:rounded focus-visible:ring-2 focus-visible:outline-none"
          >
            {c.name}
          </Link>
          <TruncatedText
            value={[c.legal_name, c.cui].filter(Boolean).join(" · ") || "—"}
            className="text-muted text-xs"
          />
        </div>
      ),
    },
    {
      key: "type",
      header: (
        <SortableHeader
          label={t("col_type")}
          sortKey="client_type"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 130,
      render: (c) => (
        <span className="font-body bg-ink/5 text-ink inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium">
          {t(`client_type_${c.client_type}`)}
        </span>
      ),
    },
    {
      key: "status",
      header: (
        <SortableHeader label={t("col_status")} sortKey="status" activeKey={sortKey} dir={sortDir} onSort={onSort} />
      ),
      width: 100,
      render: (c) => <StatusChip status={c.status} label={t(`status_${c.status}`)} />,
    },
    {
      key: "entity",
      header: t("col_entity"),
      width: 120,
      render: (c) => <EntityChips names={c.billingEntities} emptyLabel={t("no_entity_yet")} />,
    },
  ];

  const columns = [...baseColumns, ...activeExtraColumns];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl text-brand-pink">{t("page_title")}</h1>
          <p className="font-body text-muted mt-1 text-sm">{t("page_subtitle")}</p>
        </div>
        {LOCALE_SWITCHER_ENABLED && <LocaleSwitcher />}
      </div>

      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">{error}</p>
      )}

      {createOrgId && (
        <div className="flex flex-col gap-4">
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body focus-visible:ring-brand-pink w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90 focus-visible:ring-2 focus-visible:outline-none"
          >
            {t("new_client")}
          </button>
          {isFormOpen && (
            <NewClientForm
              isPending={isPending}
              t={t}
              onSubmit={(name, clientType, businessLine, legalName, cui) => {
                setError(null);
                startTransition(async () => {
                  const result = await addClient(createOrgId, name, clientType, businessLine, legalName, cui);
                  if (!result.ok) setError(result.error);
                  else setIsFormOpen(false);
                });
              }}
            />
          )}
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        {clients.length === 0 ? (
          <p className="font-body text-muted text-sm">{t("empty_no_clients")}</p>
        ) : (
          <div className="flex flex-col gap-4">
            <DataTableToolbar
              searchValue={searchQuery}
              onSearchChange={setSearchQuery}
              searchPlaceholder={t("search_placeholder")}
              filters={
                <>
                  <select
                    value={typeFilter}
                    onChange={(e) => setTypeFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_type_all")}</option>
                    {CLIENT_TYPES.map((ty) => (
                      <option key={ty} value={ty}>
                        {t(`client_type_${ty}`)}
                      </option>
                    ))}
                  </select>
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_status_all")}</option>
                    {/* "Prospect" excluded from the filter's practical option
                        list — AC owns the pre-collaboration funnel, unchanged
                        from the pre-DataTable behaviour. */}
                    {CLIENT_STATUSES.filter((s) => s !== "prospect").map((s) => (
                      <option key={s} value={s}>
                        {t(`status_${s}`)}
                      </option>
                    ))}
                  </select>
                </>
              }
              chips={chips}
              onClearAll={chips.length > 0 ? clearAllFilters : undefined}
              clearAllLabel={t("clear_all")}
              columnsToggle={
                <ColumnsDropdown
                  label={t("columns")}
                  options={extraColumnDefs.map((def) => ({
                    key: def.key,
                    label:
                      def.key === "business_line"
                        ? t("detail_business_line")
                        : def.key === "legal_name"
                          ? t("detail_legal_name")
                          : def.key === "cui"
                            ? t("detail_cui")
                            : t("detail_added"),
                    checked: extraColumns.includes(def.key),
                    onChange: (checked) =>
                      setExtraColumns(
                        checked ? [...extraColumns, def.key] : extraColumns.filter((k) => k !== def.key),
                      ),
                  }))}
                />
              }
            />

            <p className="font-body text-muted text-xs">
              {t("showing_count", { shown: sortedClients.length, total: clients.length })}
            </p>

            {sortedClients.length === 0 ? (
              <p className="font-body text-muted text-sm">{t("empty_no_match")}</p>
            ) : (
              <>
                <div className="hidden md:block">
                  <DataTable
                    columns={columns}
                    rows={sortedClients}
                    rowKey={(c) => c.id}
                    expandedRowKey={expandedId}
                    onToggleRow={(key) => setExpandedId((cur) => (cur === key ? null : key))}
                    emptyMessage={t("empty_no_match")}
                    rowAriaLabel={(c) => c.name}
                    renderExpanded={(c) => <ClientDetailPanel client={c} locale={locale} />}
                  />
                </div>

                <div className="flex flex-col gap-3 md:hidden">
                  {sortedClients.map((c) => (
                    <ClientCard
                      key={c.id}
                      client={c}
                      t={t}
                      expanded={expandedId === c.id}
                      onToggle={() => setExpandedId((cur) => (cur === c.id ? null : c.id))}
                      locale={locale}
                    />
                  ))}
                </div>
              </>
            )}
          </div>
        )}
      </section>
    </div>
  );
}

// Below 768px: cards, not a shrunk table — same pattern as /contracts.
function ClientCard({
  client,
  t,
  expanded,
  onToggle,
  locale,
}: {
  client: Client;
  t: (key: string, vars?: Record<string, string | number>) => string;
  expanded: boolean;
  onToggle: () => void;
  locale: "en" | "ro";
}) {
  return (
    <div className="rounded-xl border border-black/5">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={expanded}
        className="focus-visible:ring-brand-pink flex w-full flex-col gap-2 p-4 text-left focus-visible:ring-2 focus-visible:outline-none"
      >
        <div className="flex items-start justify-between gap-2">
          <p className="font-body text-brand-pink text-sm font-semibold">{client.name}</p>
          <span
            aria-hidden="true"
            className={`text-muted motion-safe:transition-transform ${expanded ? "rotate-180" : ""}`}
          >
            ▾
          </span>
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="font-body bg-ink/5 text-ink inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium">
            {t(`client_type_${client.client_type}`)}
          </span>
          <StatusChip status={client.status} label={t(`status_${client.status}`)} />
        </div>
        <EntityChips names={client.billingEntities} emptyLabel={t("no_entity_yet")} />
      </button>
      {expanded && (
        <div className="border-t border-black/5 px-4 py-4">
          <ClientDetailPanel client={client} locale={locale} />
        </div>
      )}
    </div>
  );
}

function NewClientForm({
  isPending,
  onSubmit,
  t,
}: {
  isPending: boolean;
  t: (key: string, vars?: Record<string, string | number>) => string;
  onSubmit: (name: string, clientType: string, businessLine: string, legalName: string, cui: string) => void;
}) {
  const [name, setName] = useState("");
  const [clientType, setClientType] = useState(CLIENT_TYPES[0]);
  const [businessLine, setBusinessLine] = useState("");
  const [legalName, setLegalName] = useState("");
  const [cui, setCui] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("new_client_form_title")}
      </h2>
      <div className="flex flex-col gap-3 md:flex-row md:flex-wrap md:items-end">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder={t("name_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:flex-1"
        />
        <select
          value={clientType}
          onChange={(e) => setClientType(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2"
        >
          {CLIENT_TYPES.map((ty) => (
            <option key={ty} value={ty}>
              {t(`client_type_${ty}`)}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={businessLine}
          onChange={(e) => setBusinessLine(e.target.value)}
          placeholder={t("business_line_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:flex-1"
        />
        <input
          type="text"
          value={legalName}
          onChange={(e) => setLegalName(e.target.value)}
          placeholder={t("legal_name_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:flex-1"
        />
        <input
          type="text"
          value={cui}
          onChange={(e) => setCui(e.target.value)}
          placeholder={t("cui_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:w-40"
        />
        <button
          type="button"
          disabled={isPending || !name.trim()}
          onClick={() => onSubmit(name, clientType, businessLine, legalName, cui)}
          className="font-body focus-visible:ring-brand-pink w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity focus-visible:ring-2 focus-visible:outline-none disabled:opacity-50"
        >
          {t("create_client")}
        </button>
      </div>
    </section>
  );
}
