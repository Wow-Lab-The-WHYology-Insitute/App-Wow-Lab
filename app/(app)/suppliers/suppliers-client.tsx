"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addSupplier } from "./actions";
import { useTranslations, LOCALE_SWITCHER_ENABLED } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { suppliersDict } from "./i18n";
import {
  DataTable,
  DataTableToolbar,
  TruncatedText,
  type DataTableColumn,
  type FilterChip,
} from "@/components/ui/data-table";

type Supplier = {
  id: string;
  name: string;
  legal_name: string | null;
  cui: string | null;
  service_type: string | null;
  status: string;
  notes: string | null;
};

const STATUSES = ["active", "inactive"];

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

// Only 4 real columns exist on this table -- no ColumnsDropdown/
// usePersistedColumns ceremony the way /clients and /groups have, since
// there's nothing here worth progressively disclosing. Notes lives in the
// expanded row detail instead of a 5th always-visible column.
export function SuppliersClient({
  suppliers,
  createOrgId,
}: {
  suppliers: Supplier[];
  createOrgId: string | null;
}) {
  const t = useTranslations(suppliersDict);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filteredSuppliers = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return suppliers.filter((s) => {
      if (
        q &&
        !s.name.toLowerCase().includes(q) &&
        !(s.legal_name ?? "").toLowerCase().includes(q) &&
        !(s.cui ?? "").toLowerCase().includes(q)
      ) {
        return false;
      }
      if (statusFilter !== "all" && s.status !== statusFilter) return false;
      return true;
    });
  }, [suppliers, searchQuery, statusFilter]);

  const chips: FilterChip[] = [];
  if (statusFilter !== "all") {
    chips.push({ key: "status", label: t(`status_${statusFilter}`), onRemove: () => setStatusFilter("all") });
  }

  function clearAllFilters() {
    setStatusFilter("all");
  }

  const columns: DataTableColumn<Supplier>[] = [
    {
      key: "supplier",
      header: t("col_supplier"),
      width: 240,
      sticky: true,
      render: (s) => (
        <div className="flex flex-col justify-center gap-0.5">
          <Link
            href={`/suppliers/${s.id}`}
            onClick={(e) => e.stopPropagation()}
            title={s.name}
            className="text-brand-pink focus-visible:ring-brand-pink block overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap hover:underline focus-visible:rounded focus-visible:ring-2 focus-visible:outline-none"
          >
            {s.name}
          </Link>
          <TruncatedText
            value={[s.legal_name, s.cui].filter(Boolean).join(" · ") || "—"}
            className="text-muted text-xs"
          />
        </div>
      ),
    },
    {
      key: "service_type",
      header: t("col_service_type"),
      width: 180,
      render: (s) => <TruncatedText value={s.service_type || "—"} className="text-ink text-sm" />,
    },
    {
      key: "status",
      header: t("col_status"),
      width: 100,
      render: (s) => <StatusChip status={s.status} label={t(`status_${s.status}`)} />,
    },
  ];

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
            {t("new_supplier")}
          </button>
          {isFormOpen && (
            <NewSupplierForm
              isPending={isPending}
              t={t}
              onSubmit={(name, legalName, cui, serviceType, notes) => {
                setError(null);
                startTransition(async () => {
                  const result = await addSupplier(createOrgId, name, legalName, cui, serviceType, notes);
                  if (!result.ok) setError(result.error);
                  else setIsFormOpen(false);
                });
              }}
            />
          )}
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        {suppliers.length === 0 ? (
          <p className="font-body text-muted text-sm">{t("empty_no_suppliers")}</p>
        ) : (
          <div className="flex flex-col gap-4">
            <DataTableToolbar
              searchValue={searchQuery}
              onSearchChange={setSearchQuery}
              searchPlaceholder={t("search_placeholder")}
              filters={
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                >
                  <option value="all">{t("filter_status_all")}</option>
                  {STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {t(`status_${s}`)}
                    </option>
                  ))}
                </select>
              }
              chips={chips}
              onClearAll={chips.length > 0 ? clearAllFilters : undefined}
              clearAllLabel={t("clear_all")}
            />

            <p className="font-body text-muted text-xs">
              {t("showing_count", { shown: filteredSuppliers.length, total: suppliers.length })}
            </p>

            {filteredSuppliers.length === 0 ? (
              <p className="font-body text-muted text-sm">{t("empty_no_match")}</p>
            ) : (
              <>
                <div className="hidden md:block">
                  <DataTable
                    columns={columns}
                    rows={filteredSuppliers}
                    rowKey={(s) => s.id}
                    expandedRowKey={expandedId}
                    onToggleRow={(key) => setExpandedId((cur) => (cur === key ? null : key))}
                    emptyMessage={t("empty_no_match")}
                    rowAriaLabel={(s) => s.name}
                    renderExpanded={(s) => <SupplierDetailPanel supplier={s} t={t} />}
                  />
                </div>

                <div className="flex flex-col gap-3 md:hidden">
                  {filteredSuppliers.map((s) => (
                    <SupplierCard
                      key={s.id}
                      supplier={s}
                      t={t}
                      expanded={expandedId === s.id}
                      onToggle={() => setExpandedId((cur) => (cur === s.id ? null : s.id))}
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

function SupplierDetailPanel({
  supplier,
  t,
}: {
  supplier: Supplier;
  t: (key: string, vars?: Record<string, string | number>) => string;
}) {
  return (
    <div className="flex flex-col gap-1 text-sm">
      <Kv label={t("detail_legal_name")} value={supplier.legal_name || "—"} />
      <Kv label={t("detail_cui")} value={supplier.cui || "—"} />
      <Kv label={t("detail_notes")} value={supplier.notes || "—"} />
    </div>
  );
}

function Kv({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-1.5 last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className="font-body text-ink font-medium">{value}</span>
    </div>
  );
}

// Below 768px: cards, not a shrunk table -- same pattern as /clients,
// /contracts, /groups.
function SupplierCard({
  supplier,
  t,
  expanded,
  onToggle,
}: {
  supplier: Supplier;
  t: (key: string, vars?: Record<string, string | number>) => string;
  expanded: boolean;
  onToggle: () => void;
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
          <p className="font-body text-brand-pink text-sm font-semibold">{supplier.name}</p>
          <span
            aria-hidden="true"
            className={`text-muted motion-safe:transition-transform ${expanded ? "rotate-180" : ""}`}
          >
            ▾
          </span>
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          {supplier.service_type && (
            <span className="font-body bg-ink/5 text-ink inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium">
              {supplier.service_type}
            </span>
          )}
          <StatusChip status={supplier.status} label={t(`status_${supplier.status}`)} />
        </div>
      </button>
      {expanded && (
        <div className="border-t border-black/5 px-4 py-4">
          <SupplierDetailPanel supplier={supplier} t={t} />
        </div>
      )}
    </div>
  );
}

function NewSupplierForm({
  isPending,
  onSubmit,
  t,
}: {
  isPending: boolean;
  t: (key: string, vars?: Record<string, string | number>) => string;
  onSubmit: (name: string, legalName: string, cui: string, serviceType: string, notes: string) => void;
}) {
  const [name, setName] = useState("");
  const [legalName, setLegalName] = useState("");
  const [cui, setCui] = useState("");
  const [serviceType, setServiceType] = useState("");
  const [notes, setNotes] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("new_supplier_form_title")}
      </h2>
      <div className="flex flex-col gap-3 md:flex-row md:flex-wrap md:items-end">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder={t("name_placeholder")}
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
        <input
          type="text"
          value={serviceType}
          onChange={(e) => setServiceType(e.target.value)}
          placeholder={t("service_type_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:flex-1"
        />
        <input
          type="text"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder={t("notes_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:ring-2 md:flex-1"
        />
        <button
          type="button"
          disabled={isPending || !name.trim()}
          onClick={() => onSubmit(name, legalName, cui, serviceType, notes)}
          className="font-body focus-visible:ring-brand-pink w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity focus-visible:ring-2 focus-visible:outline-none disabled:opacity-50"
        >
          {t("create_supplier")}
        </button>
      </div>
    </section>
  );
}
