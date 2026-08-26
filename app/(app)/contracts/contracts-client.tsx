"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addContract } from "./actions";
import { useLocale, useTranslations, LOCALE_SWITCHER_ENABLED } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { contractsDict } from "./i18n";
import { TermBar, getTermStatus } from "./term-bar";
import { ContractDetailPanel } from "./contract-detail-panel";
import { formatMoney, formatDate, entityShortCode, isDemoRecord } from "./format";
import {
  DataTable,
  DataTableToolbar,
  ColumnsDropdown,
  ValueCell,
  TruncatedText,
  usePersistedColumns,
  type DataTableColumn,
  type FilterChip,
} from "@/components/ui/data-table";

type Contract = {
  id: string;
  entry_number: string | null;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  billing_rule: string | null;
  signed_date: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  offer_structure: string | null;
  ac_link: string | null;
  drive_ref: string | null;
  notes: string | null;
  clientName: string;
  clientLegalName: string | null;
  clientCui: string | null;
  legalEntityName: string;
};
type Option = { id: string; name: string };

const CONTRACT_TYPES = ["recurring_annual", "one_off_event", "framework"];

// Matches the contracts.status check constraint (202608100001) exactly —
// keep in sync if that constraint ever changes.
const CONTRACT_STATUSES = ["draft", "sent", "signed", "expired", "renewed"];

const STATUS_TONE: Record<string, string> = {
  draft: "bg-ink/5 text-ink",
  sent: "bg-brand-orange/15 text-brand-orange",
  // Deliberate exception to "magenta is reserved" — signed status uses a
  // semantic green, not the brand palette, per the task's own note.
  signed: "bg-green-100 text-green-700",
  expired: "border border-black/15 text-muted",
  renewed: "bg-brand-pink/10 text-brand-pink",
};

function StatusChip({ status, label }: { status: string; label: string }) {
  return (
    <span
      className={`font-body inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium ${
        STATUS_TONE[status] ?? "bg-ink/5 text-ink"
      }`}
    >
      {label}
    </span>
  );
}

// Promoted from a sentence buried in the detail panel's notes field to a
// visible badge (task requirement) — contract_number's own "DEMO-2026-"
// prefix used to be the safety marker visible in every collapsed row;
// now that contract_number is gone, this badge is the only thing left
// doing that job, so it has to be visible without expanding the row.
function DemoBadge({ label, title }: { label: string; title: string }) {
  return (
    <span
      title={title}
      className="font-body inline-flex w-fit items-center gap-1 rounded-full bg-brand-orange/15 px-2 py-0.5 text-[11px] font-medium text-brand-orange"
    >
      ⚠ {label}
    </span>
  );
}

// The 10 fields moved out of the default column set (task step 2) — each
// available as an opt-in extra column via the Columns dropdown, so a
// Finance user can pull e.g. billing_rule back into the table without it
// crowding every other role's view by default. offer_structure/ac_link
// are NOT in the task's literal list (same gap as the detail panel — see
// contract-detail-panel.tsx's own comment) but are included here too, for
// the same reason: real, already-shipped fields shouldn't become
// unreachable from the list surface entirely.
function buildExtraColumns(
  t: (key: string, vars?: Record<string, string | number>) => string,
  locale: "en" | "ro",
  financeVisible: boolean,
): DataTableColumn<Contract>[] {
  return [
    {
      key: "legal_name",
      header: t("detail_legal_name"),
      width: 180,
      render: (c) => <TruncatedText value={c.clientLegalName || "—"} className="text-ink text-sm" />,
    },
    {
      key: "cui",
      header: t("detail_cui"),
      width: 100,
      render: (c) => <span className="font-mono text-xs">{c.clientCui || "—"}</span>,
    },
    {
      key: "entry_number",
      header: t("detail_entry_number"),
      width: 140,
      render: (c) => <TruncatedText value={c.entry_number || "—"} className="text-ink text-xs" />,
    },
    {
      key: "signed_date",
      header: t("detail_signed_date"),
      width: 100,
      render: (c) => (
        <span className="text-xs tabular-nums">{c.signed_date ? formatDate(c.signed_date, locale) : "—"}</span>
      ),
    },
    {
      key: "billing_rule",
      header: t("detail_billing_rule"),
      width: 200,
      render: (c) => (
        <ValueCell
          value={c.billing_rule}
          visible={financeVisible}
          maskedLabel={t("masked_label")}
          maskedTitle={t("masked_title")}
        />
      ),
    },
    {
      key: "estimated_value",
      header: t("detail_estimated_value"),
      width: 110,
      align: "right",
      render: (c) => (
        <ValueCell
          value={c.estimated_value}
          visible={financeVisible}
          maskedLabel={t("masked_label")}
          maskedTitle={t("masked_title")}
          format={(v) => formatMoney(v, locale)}
        />
      ),
    },
    {
      key: "previous_year_value",
      header: t("detail_previous_year_value"),
      width: 110,
      align: "right",
      render: (c) => (
        <ValueCell
          value={c.previous_year_value}
          visible={financeVisible}
          maskedLabel={t("masked_label")}
          maskedTitle={t("masked_title")}
          format={(v) => formatMoney(v, locale)}
        />
      ),
    },
    {
      key: "legal_entity",
      header: t("detail_legal_entity"),
      width: 160,
      render: (c) => <TruncatedText value={c.legalEntityName} className="text-ink text-xs" />,
    },
    {
      key: "drive_ref",
      header: t("detail_drive_link"),
      width: 90,
      render: (c) =>
        c.drive_ref ? (
          <a
            href={c.drive_ref}
            target="_blank"
            rel="noreferrer"
            onClick={(e) => e.stopPropagation()}
            className="text-brand-pink text-xs font-medium hover:underline"
          >
            {t("open_link")}
          </a>
        ) : (
          <span className="text-muted text-xs">—</span>
        ),
    },
    {
      key: "notes",
      header: t("detail_notes"),
      width: 200,
      render: (c) => <TruncatedText value={c.notes || "—"} className="text-ink text-xs" />,
    },
  ];
}

export function ContractsClient({
  contracts,
  financeVisible,
  bannerEligible,
  createOrgId,
  clientOptions,
  legalEntityOptions,
}: {
  contracts: Contract[];
  financeVisible: boolean;
  bannerEligible: boolean;
  createOrgId: string | null;
  clientOptions: Option[];
  legalEntityOptions: Option[];
}) {
  const t = useTranslations(contractsDict);
  const { locale } = useLocale();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [entityFilter, setEntityFilter] = useState("all");
  const [overdueOnly, setOverdueOnly] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [extraColumns, setExtraColumns] = usePersistedColumns("contracts", []);

  // Stable "now" for the whole render pass — every row's term bar agrees
  // with every other row's, and re-renders from filtering/sorting don't
  // shift the reference point mid-session.
  const [now] = useState(() => new Date());

  const entityOptions = useMemo(
    () => [...new Set(contracts.map((c) => c.legalEntityName))].sort(),
    [contracts],
  );

  // Same math TermBar renders per row (app/(app)/contracts/term-bar.tsx),
  // reused rather than re-derived, so the banner's counts can never drift
  // from what the bars on screen actually show. Only meaningful when
  // bannerEligible -- for a finance session, `contracts` here is already
  // the client-type-segmented subset RLS returned, so counting over it
  // would silently be a partial number, not the org-wide one the banner
  // claims. isPast/critical requires a real period_start/period_end pair
  // (a one_off_event contract with no range has neither).
  const { overdueCount, criticalCount } = useMemo(() => {
    if (!bannerEligible) return { overdueCount: 0, criticalCount: 0 };
    let overdue = 0;
    let critical = 0;
    for (const c of contracts) {
      if (c.status !== "signed" || !c.period_start || !c.period_end) continue;
      const { isPast, isRenewalCritical } = getTermStatus(
        c.period_start,
        c.period_end,
        c.status,
        now,
      );
      if (isPast) overdue += 1;
      else if (isRenewalCritical) critical += 1;
    }
    return { overdueCount: overdue, criticalCount: critical };
  }, [contracts, bannerEligible, now]);

  const filteredContracts = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return contracts.filter((c) => {
      if (
        q &&
        !c.clientName.toLowerCase().includes(q) &&
        !(c.exit_number ?? "").toLowerCase().includes(q) &&
        !(c.entry_number ?? "").toLowerCase().includes(q)
      ) {
        return false;
      }
      if (typeFilter !== "all" && c.contract_type !== typeFilter) return false;
      if (statusFilter !== "all" && c.status !== statusFilter) return false;
      if (entityFilter !== "all" && c.legalEntityName !== entityFilter) return false;
      if (overdueOnly) {
        if (c.status !== "signed" || !c.period_start || !c.period_end) return false;
        if (!getTermStatus(c.period_start, c.period_end, c.status, now).isPast) return false;
      }
      return true;
    });
  }, [contracts, searchQuery, typeFilter, statusFilter, entityFilter, overdueOnly, now]);

  // Soonest-expiring first — same default the flat-column table used
  // (period_end ascending, nulls last).
  const sortedContracts = useMemo(() => {
    return [...filteredContracts].sort((a, b) => {
      if (a.period_end == null && b.period_end == null) return 0;
      if (a.period_end == null) return 1;
      if (b.period_end == null) return -1;
      return a.period_end.localeCompare(b.period_end);
    });
  }, [filteredContracts]);

  const chips: FilterChip[] = [];
  if (typeFilter !== "all") {
    chips.push({
      key: "type",
      label: t(`contract_type_${typeFilter}`),
      onRemove: () => setTypeFilter("all"),
    });
  }
  if (statusFilter !== "all") {
    chips.push({
      key: "status",
      label: t(`status_${statusFilter}`),
      onRemove: () => setStatusFilter("all"),
    });
  }
  if (entityFilter !== "all") {
    chips.push({
      key: "entity",
      label: entityShortCode(entityFilter),
      onRemove: () => setEntityFilter("all"),
    });
  }
  if (overdueOnly) {
    chips.push({
      key: "overdue",
      label: t("overdue_filter_chip"),
      onRemove: () => setOverdueOnly(false),
    });
  }

  function clearAllFilters() {
    setTypeFilter("all");
    setStatusFilter("all");
    setEntityFilter("all");
    setOverdueOnly(false);
  }

  const extraColumnDefs = buildExtraColumns(t, locale, financeVisible);
  const activeExtraColumns = extraColumnDefs.filter((c) => extraColumns.includes(c.key));

  const baseColumns: DataTableColumn<Contract>[] = [
    {
      key: "contract",
      header: t("col_contract"),
      width: 120,
      sticky: true,
      render: (c) => {
        const label = c.exit_number || t("no_exit_number", { client: c.clientName });
        return (
          <div className="flex flex-col justify-center gap-0.5">
            <Link
              href={`/contracts/${c.id}`}
              onClick={(e) => e.stopPropagation()}
              title={label}
              className={
                c.exit_number
                  ? "text-brand-pink focus-visible:ring-brand-pink block overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap hover:underline focus-visible:rounded focus-visible:ring-2 focus-visible:outline-none"
                  : "text-muted focus-visible:ring-brand-pink block overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap italic hover:underline focus-visible:rounded focus-visible:ring-2 focus-visible:outline-none"
              }
            >
              {label}
            </Link>
            <TruncatedText value={c.entry_number || "—"} className="text-muted text-xs" />
          </div>
        );
      },
    },
    {
      key: "client",
      header: t("col_client"),
      width: 200,
      render: (c) => (
        <div className="flex flex-col justify-center gap-0.5">
          <TruncatedText value={c.clientName} className="text-ink text-sm font-medium" />
          <TruncatedText
            value={[c.clientLegalName, c.clientCui].filter(Boolean).join(" · ") || "—"}
            className="text-muted text-xs"
          />
        </div>
      ),
    },
    {
      key: "type",
      header: t("col_type"),
      width: 120,
      render: (c) => (
        <div className="flex flex-col justify-center gap-1">
          <span className="text-ink text-sm">{t(`contract_type_${c.contract_type}`)}</span>
          <div className="flex flex-wrap items-center gap-1">
            <StatusChip status={c.status} label={t(`status_${c.status}`)} />
            {isDemoRecord(c.notes) && <DemoBadge label={t("demo_badge_label")} title={t("demo_badge_title")} />}
          </div>
        </div>
      ),
    },
    {
      key: "term",
      header: t("col_term"),
      width: 170,
      render: (c) => <TermCell contract={c} now={now} locale={locale} t={t} />,
    },
    {
      key: "entity",
      header: t("col_entity"),
      width: 64,
      hideBelowPx: 1024,
      render: (c) => (
        <span
          title={c.legalEntityName}
          className="font-mono text-ink inline-flex w-fit items-center rounded bg-ink/5 px-1.5 py-0.5 text-[11px] font-medium"
        >
          {entityShortCode(c.legalEntityName)}
        </span>
      ),
    },
    {
      key: "value",
      header: t("col_value"),
      width: 100,
      align: "right",
      hideBelowPx: 1024,
      render: (c) => (
        <div className="flex flex-col items-end gap-0.5">
          <ValueCell
            value={c.estimated_value}
            visible={financeVisible}
            maskedLabel={t("masked_label")}
            maskedTitle={t("masked_title")}
            format={(v) => formatMoney(v, locale)}
          />
          <span className="text-muted text-[11px]">
            <ValueCell
              value={c.previous_year_value}
              visible={financeVisible}
              maskedLabel={t("masked_label")}
              maskedTitle={t("masked_title")}
              format={(v) => formatMoney(v, locale)}
            />
          </span>
        </div>
      ),
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
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {bannerEligible && (overdueCount > 0 || criticalCount > 0) && (
        <div className="flex flex-col gap-1 rounded-2xl border border-orange-200 bg-orange-50 px-5 py-4">
          {overdueCount > 0 && (
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="font-body text-sm font-medium text-orange-800">
                {t("overdue_banner_line", { n: overdueCount })}
              </span>
              <button
                type="button"
                onClick={() => setOverdueOnly(true)}
                className="font-body text-xs font-bold tracking-wide text-orange-800 uppercase underline"
              >
                {t("overdue_banner_show")}
              </button>
            </div>
          )}
          {criticalCount > 0 && (
            <span className="font-body text-xs text-orange-700">
              {t("overdue_banner_critical_line", { n: criticalCount })}
            </span>
          )}
        </div>
      )}

      {createOrgId && (
        <div className="flex flex-col gap-4">
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body focus-visible:ring-brand-pink w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90 focus-visible:ring-2 focus-visible:outline-none"
          >
            {t("new_contract")}
          </button>
          {isFormOpen && (
            <NewContractForm
              clientOptions={clientOptions}
              legalEntityOptions={legalEntityOptions}
              isPending={isPending}
              t={t}
              onSubmit={(
                clientId,
                legalEntityId,
                entryNumber,
                exitNumber,
                type,
                start,
                end,
                rule,
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
                    entryNumber,
                    exitNumber,
                    type,
                    start,
                    end,
                    rule,
                    signedDate,
                    estimatedValue,
                    previousYearValue,
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
        {contracts.length === 0 ? (
          <p className="font-body text-muted text-sm">{t("empty_no_contracts")}</p>
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
                    {CONTRACT_TYPES.map((ty) => (
                      <option key={ty} value={ty}>
                        {t(`contract_type_${ty}`)}
                      </option>
                    ))}
                  </select>
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_status_all")}</option>
                    {CONTRACT_STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {t(`status_${s}`)}
                      </option>
                    ))}
                  </select>
                  <select
                    value={entityFilter}
                    onChange={(e) => setEntityFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_entity_all")}</option>
                    {entityOptions.map((name) => (
                      <option key={name} value={name}>
                        {entityShortCode(name)}
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
                    label: def.header,
                    checked: extraColumns.includes(def.key),
                    onChange: (checked) =>
                      setExtraColumns(
                        checked
                          ? [...extraColumns, def.key]
                          : extraColumns.filter((k) => k !== def.key),
                      ),
                  }))}
                />
              }
            />

            <p className="font-body text-muted text-xs">
              {t("showing_count", { shown: sortedContracts.length, total: contracts.length })}
            </p>

            {sortedContracts.length === 0 ? (
              <p className="font-body text-muted text-sm">{t("empty_no_match")}</p>
            ) : (
              <>
                {/* Table: md and up. Below that, step 7 abandons the table
                    for a card list entirely rather than shrinking columns
                    further. */}
                <div className="hidden md:block">
                  <DataTable
                    columns={columns}
                    rows={sortedContracts}
                    rowKey={(c) => c.id}
                    expandedRowKey={expandedId}
                    onToggleRow={(key) => setExpandedId((cur) => (cur === key ? null : key))}
                    emptyMessage={t("empty_no_match")}
                    rowAriaLabel={(c) => c.exit_number || c.clientName}
                    renderExpanded={(c) => (
                      <ContractDetailPanel
                        contract={c}
                        financeVisible={financeVisible}
                        locale={locale}
                      />
                    )}
                  />
                </div>

                <div className="flex flex-col gap-3 md:hidden">
                  {sortedContracts.map((c) => (
                    <ContractCard
                      key={c.id}
                      contract={c}
                      now={now}
                      locale={locale}
                      t={t}
                      expanded={expandedId === c.id}
                      onToggle={() => setExpandedId((cur) => (cur === c.id ? null : c.id))}
                      financeVisible={financeVisible}
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

function TermCell({
  contract,
  now,
  locale,
  t,
}: {
  contract: Contract;
  now: Date;
  locale: "en" | "ro";
  t: (key: string, vars?: Record<string, string | number>) => string;
}) {
  const { period_start, period_end, status } = contract;

  if (!period_start && !period_end) {
    return <span className="text-muted text-xs">—</span>;
  }
  // one_off_event contracts (and any other row) where start === end, or
  // where only one bound is known, render a single date — a "range" bar
  // over a zero-width or half-known range would be meaningless.
  if (!period_start || !period_end || period_start === period_end) {
    const single = period_start ?? period_end!;
    return <span className="text-ink text-xs tabular-nums">{formatDate(single, locale)}</span>;
  }

  return (
    <div className="flex flex-col gap-1">
      <span className="text-ink text-xs tabular-nums whitespace-nowrap">
        {formatDate(period_start, locale)} – {formatDate(period_end, locale)}
      </span>
      <TermBar
        periodStart={period_start}
        periodEnd={period_end}
        status={status}
        now={now}
        labels={{
          endsIn: (n) => t("term_ends_in", { n }),
          endedAgo: (n) => t("term_ended_ago", { n }),
          startsIn: (n) => t("term_starts_in", { n }),
        }}
      />
    </div>
  );
}

// Below 768px: cards, not a shrunk table (task step 7). Same expand
// affordance and detail panel as the desktop table.
function ContractCard({
  contract,
  now,
  locale,
  t,
  expanded,
  onToggle,
  financeVisible,
}: {
  contract: Contract;
  now: Date;
  locale: "en" | "ro";
  t: (key: string, vars?: Record<string, string | number>) => string;
  expanded: boolean;
  onToggle: () => void;
  financeVisible: boolean;
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
          <p
            className={`font-body text-sm font-semibold ${contract.exit_number ? "text-brand-pink" : "text-muted italic"}`}
          >
            {contract.exit_number || t("no_exit_number", { client: contract.clientName })}
          </p>
          <span
            aria-hidden="true"
            className={`text-muted motion-safe:transition-transform ${expanded ? "rotate-180" : ""}`}
          >
            ▾
          </span>
        </div>
        <p className="font-body text-ink text-sm font-medium">{contract.clientName}</p>
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="font-body text-muted text-xs">{t(`contract_type_${contract.contract_type}`)}</span>
          <StatusChip status={contract.status} label={t(`status_${contract.status}`)} />
          {isDemoRecord(contract.notes) && <DemoBadge label={t("demo_badge_label")} title={t("demo_badge_title")} />}
        </div>
        <TermCell contract={contract} now={now} locale={locale} t={t} />
      </button>
      {expanded && (
        <div className="border-t border-black/5 px-4 py-4">
          <ContractDetailPanel
            contract={contract}
            financeVisible={financeVisible}
            locale={locale}
          />
        </div>
      )}
    </div>
  );
}

function NewContractForm({
  clientOptions,
  legalEntityOptions,
  isPending,
  onSubmit,
  t,
}: {
  clientOptions: Option[];
  legalEntityOptions: Option[];
  isPending: boolean;
  t: (key: string, vars?: Record<string, string | number>) => string;
  onSubmit: (
    clientId: string,
    legalEntityId: string,
    entryNumber: string,
    exitNumber: string,
    type: string,
    start: string,
    end: string,
    rule: string,
    signedDate: string,
    estimatedValue: string,
    previousYearValue: string,
  ) => void;
}) {
  const [clientId, setClientId] = useState(clientOptions[0]?.id ?? "");
  const [legalEntityId, setLegalEntityId] = useState(legalEntityOptions[0]?.id ?? "");
  const [entryNumber, setEntryNumber] = useState("");
  const [exitNumber, setExitNumber] = useState("");
  const [type, setType] = useState(CONTRACT_TYPES[0]);
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [rule, setRule] = useState("");
  const [signedDate, setSignedDate] = useState("");
  const [estimatedValue, setEstimatedValue] = useState("");
  const [previousYearValue, setPreviousYearValue] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("new_contract_form_title")}
      </h2>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <select
          value={clientId}
          onChange={(e) => setClientId(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          <option value="">{t("select_client")}</option>
          {clientOptions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={legalEntityId}
          onChange={(e) => setLegalEntityId(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          <option value="">{t("select_entity")}</option>
          {legalEntityOptions.map((e) => (
            <option key={e.id} value={e.id}>
              {e.name}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={entryNumber}
          onChange={(e) => setEntryNumber(e.target.value)}
          placeholder={t("entry_number_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="text"
          value={exitNumber}
          onChange={(e) => setExitNumber(e.target.value)}
          placeholder={t("exit_number_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {CONTRACT_TYPES.map((ty) => (
            <option key={ty} value={ty}>
              {t(`contract_type_${ty}`)}
            </option>
          ))}
        </select>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("start_date")}
          <input
            type="date"
            value={start}
            onChange={(e) => setStart(e.target.value)}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("end_date")}
          <input
            type="date"
            value={end}
            onChange={(e) => setEnd(e.target.value)}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        </label>
        <input
          type="text"
          value={rule}
          onChange={(e) => setRule(e.target.value)}
          placeholder={t("billing_rule_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        />
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("signed_date_label")}
          <input
            type="date"
            value={signedDate}
            onChange={(e) => setSignedDate(e.target.value)}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        </label>
        <input
          type="number"
          step="0.01"
          value={estimatedValue}
          onChange={(e) => setEstimatedValue(e.target.value)}
          placeholder={t("estimated_value_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="number"
          step="0.01"
          value={previousYearValue}
          onChange={(e) => setPreviousYearValue(e.target.value)}
          placeholder={t("previous_year_value_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !clientId || !legalEntityId}
        onClick={() =>
          onSubmit(
            clientId,
            legalEntityId,
            entryNumber,
            exitNumber,
            type,
            start,
            end,
            rule,
            signedDate,
            estimatedValue,
            previousYearValue,
          )
        }
        className="font-body focus-visible:ring-brand-pink mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity focus-visible:ring-2 focus-visible:outline-none disabled:opacity-50"
      >
        {t("create_contract")}
      </button>
    </section>
  );
}
