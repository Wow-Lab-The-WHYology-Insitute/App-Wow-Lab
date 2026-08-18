"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addGroup } from "./actions";
import { useTranslations, LOCALE_SWITCHER_ENABLED } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { groupsDict } from "./i18n";
import { GroupDetailPanel } from "./group-detail-panel";
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

type Group = {
  id: string;
  clientName: string;
  clientLegalName: string | null;
  module: string;
  delivery_format: string;
  schedule_pattern: string | null;
  children_confirmed: number | null;
  children_billed: number | null;
  status: string;
  trainerPrincipalName: string | null;
  trainerSecundarName: string | null;
};
type ClientOption = { id: string; name: string };

const MODULE_KEYS = [
  "gaga",
  "green_energy",
  "wow_mix",
  "tiktok",
  "food_science",
  "lotions",
  "magic_physics",
  "chem_me",
  "chem_hs",
  "lights",
  "detective",
  "astronomy",
  "doctor",
];
const FORMAT_KEYS = ["recurring", "scoala_altfel", "saptamana_verde", "party", "corporate", "custom"];
const STATUS_KEYS = ["active", "paused", "ended"];

// Nulls always sort last regardless of direction — same convention as
// clients-client.tsx / contracts-client.tsx.
function compareValues(a: string | number | null, b: string | number | null, dir: "asc" | "desc") {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  const cmp =
    typeof a === "number" && typeof b === "number" ? a - b : String(a).localeCompare(String(b));
  return dir === "asc" ? cmp : -cmp;
}

type SortKey =
  | "clientName"
  | "clientLegalName"
  | "module"
  | "delivery_format"
  | "schedule_pattern"
  | "children_confirmed"
  | "children_billed"
  | "status";

// Preserves the pre-DataTable interactive column-sort feature — same
// SortableHeader approach as clients-client.tsx, passed as a column's
// `header` (now a ReactNode, not just a string).
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

function TrainersLine({ principal, secundar, none }: { principal: string | null; secundar: string | null; none: string }) {
  if (!principal && !secundar) return <span className="text-muted text-xs">{none}</span>;
  return (
    <span className="text-ink text-xs">
      {principal || none}
      {secundar ? ` / ${secundar}` : ""}
    </span>
  );
}

// The 6 fields moved out of the default column set — same dual pattern
// (compact-by-default, full column on demand) /contracts and /clients use.
// Trainer Principal/Secundar have no original sort key (they were only
// ever shown combined) so their headers stay plain labels; the rest keep
// their pre-DataTable sort capability once toggled visible.
function buildExtraColumns(
  t: (key: string, vars?: Record<string, string | number>) => string,
  sortKey: SortKey,
  sortDir: "asc" | "desc",
  onSort: (key: SortKey) => void,
): DataTableColumn<Group>[] {
  return [
    {
      key: "clientLegalName",
      header: (
        <SortableHeader
          label={t("detail_legal_name")}
          sortKey="clientLegalName"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 200,
      render: (g) => <TruncatedText value={g.clientLegalName || "—"} className="text-ink text-sm" />,
    },
    {
      key: "delivery_format",
      header: (
        <SortableHeader
          label={t("col_module") + " · " + t("filter_format_all").replace(/^All /, "")}
          sortKey="delivery_format"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 170,
      render: (g) => <TruncatedText value={t(`format_${g.delivery_format}`)} className="text-ink text-sm" />,
    },
    {
      key: "trainer_principal",
      header: t("detail_trainer_principal"),
      width: 150,
      render: (g) => <TruncatedText value={g.trainerPrincipalName || t("no_trainer")} className="text-ink text-sm" />,
    },
    {
      key: "trainer_secundar",
      header: t("detail_trainer_secundar"),
      width: 150,
      render: (g) => <TruncatedText value={g.trainerSecundarName || t("no_trainer")} className="text-ink text-sm" />,
    },
    {
      key: "confirmed_full",
      header: (
        <SortableHeader
          label={t("detail_confirmed")}
          sortKey="children_confirmed"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 100,
      align: "right",
      render: (g) => <ValueCell value={g.children_confirmed} visible={true} maskedLabel="" maskedTitle="" />,
    },
    {
      key: "billed_full",
      header: (
        <SortableHeader
          label={t("detail_billed")}
          sortKey="children_billed"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 100,
      align: "right",
      render: (g) => <ValueCell value={g.children_billed} visible={true} maskedLabel="" maskedTitle="" />,
    },
  ];
}

export function GroupsClient({
  groups,
  createOrgId,
  clientOptions,
  isTrainerView,
}: {
  groups: Group[];
  createOrgId: string | null;
  clientOptions: ClientOption[];
  isTrainerView: boolean;
}) {
  const t = useTranslations(groupsDict);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [sortKey, setSortKey] = useState<SortKey>("clientName");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [moduleFilter, setModuleFilter] = useState("all");
  const [formatFilter, setFormatFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [extraColumns, setExtraColumns] = usePersistedColumns("groups", []);

  function onSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  // Module/format filter options come from the already-fetched, RLS-scoped
  // groups themselves, not the full label catalogs — unchanged from the
  // pre-DataTable implementation, guarantees the filter can never offer a
  // value RLS didn't already surface.
  const moduleOptions = useMemo(() => [...new Set(groups.map((g) => g.module))].sort(), [groups]);
  const formatOptions = useMemo(() => [...new Set(groups.map((g) => g.delivery_format))].sort(), [groups]);

  const filteredGroups = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return groups.filter((g) => {
      if (q) {
        const matchesClient = g.clientName.toLowerCase().includes(q);
        const matchesTrainer =
          (g.trainerPrincipalName?.toLowerCase().includes(q) ?? false) ||
          (g.trainerSecundarName?.toLowerCase().includes(q) ?? false);
        if (!matchesClient && !matchesTrainer) return false;
      }
      if (moduleFilter !== "all" && g.module !== moduleFilter) return false;
      if (formatFilter !== "all" && g.delivery_format !== formatFilter) return false;
      if (statusFilter !== "all" && g.status !== statusFilter) return false;
      return true;
    });
  }, [groups, searchQuery, moduleFilter, formatFilter, statusFilter]);

  const sortedGroups = useMemo(() => {
    return [...filteredGroups].sort((a, b) => compareValues(a[sortKey], b[sortKey], sortDir));
  }, [filteredGroups, sortKey, sortDir]);

  const chips: FilterChip[] = [];
  if (moduleFilter !== "all") {
    chips.push({ key: "module", label: t(`module_${moduleFilter}`), onRemove: () => setModuleFilter("all") });
  }
  if (formatFilter !== "all") {
    chips.push({ key: "format", label: t(`format_${formatFilter}`), onRemove: () => setFormatFilter("all") });
  }
  if (statusFilter !== "all") {
    chips.push({ key: "status", label: t(`status_${statusFilter}`), onRemove: () => setStatusFilter("all") });
  }

  function clearAllFilters() {
    setModuleFilter("all");
    setFormatFilter("all");
    setStatusFilter("all");
  }

  const extraColumnDefs = buildExtraColumns(t, sortKey, sortDir, onSort);
  const activeExtraColumns = extraColumnDefs.filter((c) => extraColumns.includes(c.key));

  const baseColumns: DataTableColumn<Group>[] = [
    {
      key: "client",
      header: (
        <SortableHeader
          label={t("col_client")}
          sortKey="clientName"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 200,
      sticky: true,
      render: (g) => (
        <div className="flex flex-col justify-center gap-0.5">
          <Link
            href={`/groups/${g.id}`}
            onClick={(e) => e.stopPropagation()}
            title={g.clientName}
            className="text-brand-pink focus-visible:ring-brand-pink block overflow-hidden text-sm font-medium text-ellipsis whitespace-nowrap hover:underline focus-visible:rounded focus-visible:ring-2 focus-visible:outline-none"
          >
            {g.clientName}
          </Link>
          <TruncatedText value={g.clientLegalName || "—"} className="text-muted text-xs" />
        </div>
      ),
    },
    {
      key: "module",
      header: (
        <SortableHeader label={t("col_module")} sortKey="module" activeKey={sortKey} dir={sortDir} onSort={onSort} />
      ),
      width: 160,
      render: (g) => (
        <div className="flex flex-col justify-center gap-1">
          <span className="font-body bg-brand-pink/10 text-brand-pink inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium">
            {t(`module_${g.module}`)}
          </span>
          <span className="text-muted text-[11px]">{t(`format_${g.delivery_format}`)}</span>
        </div>
      ),
    },
    {
      key: "schedule",
      header: (
        <SortableHeader
          label={t("col_schedule")}
          sortKey="schedule_pattern"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 140,
      render: (g) => <TruncatedText value={g.schedule_pattern || "—"} className="text-ink text-sm" />,
    },
    {
      key: "trainers",
      header: t("col_trainers"),
      width: 170,
      render: (g) => (
        <TrainersLine principal={g.trainerPrincipalName} secundar={g.trainerSecundarName} none={t("no_trainer")} />
      ),
    },
    {
      key: "enrollment",
      header: (
        <SortableHeader
          label={t("col_enrollment")}
          sortKey="children_confirmed"
          activeKey={sortKey}
          dir={sortDir}
          onSort={onSort}
        />
      ),
      width: 100,
      align: "right",
      render: (g) => (
        <div className="flex flex-col items-end gap-0.5">
          <ValueCell value={g.children_confirmed} visible={true} maskedLabel="" maskedTitle="" />
          <span className="text-muted text-[11px]">
            <ValueCell value={g.children_billed} visible={true} maskedLabel="" maskedTitle="" />
          </span>
        </div>
      ),
    },
    {
      key: "status",
      header: (
        <SortableHeader label={t("col_status")} sortKey="status" activeKey={sortKey} dir={sortDir} onSort={onSort} />
      ),
      width: 100,
      render: (g) => <StatusChip status={g.status} label={t(`status_${g.status}`)} />,
    },
  ];

  const columns = [...baseColumns, ...activeExtraColumns];
  const extraColumnLabels: Record<string, string> = {
    clientLegalName: t("detail_legal_name"),
    delivery_format: t("col_module") + " (full)",
    trainer_principal: t("detail_trainer_principal"),
    trainer_secundar: t("detail_trainer_secundar"),
    confirmed_full: t("detail_confirmed") + " (full)",
    billed_full: t("detail_billed") + " (full)",
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl text-brand-pink">
            {isTrainerView ? t("page_title_trainer_view") : t("page_title")}
          </h1>
          <p className="font-body text-muted mt-1 text-sm">
            {isTrainerView ? t("page_subtitle_trainer_view") : t("page_subtitle")}
          </p>
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
            {t("new_group")}
          </button>
          {isFormOpen && (
            <NewGroupForm
              clientOptions={clientOptions}
              isPending={isPending}
              t={t}
              onSubmit={(clientId, module, deliveryFormat, schedulePattern, status, ageRange, schoolYearCalendarLink) => {
                setError(null);
                startTransition(async () => {
                  const result = await addGroup(
                    createOrgId,
                    clientId,
                    module,
                    deliveryFormat,
                    schedulePattern,
                    status,
                    ageRange,
                    schoolYearCalendarLink,
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
        {groups.length === 0 ? (
          <p className="font-body text-muted text-sm">
            {isTrainerView ? t("empty_no_groups_trainer") : t("empty_no_groups")}
          </p>
        ) : (
          <div className="flex flex-col gap-4">
            <DataTableToolbar
              searchValue={searchQuery}
              onSearchChange={setSearchQuery}
              searchPlaceholder={t("search_placeholder")}
              filters={
                <>
                  <select
                    value={moduleFilter}
                    onChange={(e) => setModuleFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_module_all")}</option>
                    {moduleOptions.map((m) => (
                      <option key={m} value={m}>
                        {t(`module_${m}`)}
                      </option>
                    ))}
                  </select>
                  <select
                    value={formatFilter}
                    onChange={(e) => setFormatFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_format_all")}</option>
                    {formatOptions.map((f) => (
                      <option key={f} value={f}>
                        {t(`format_${f}`)}
                      </option>
                    ))}
                  </select>
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
                  >
                    <option value="all">{t("filter_status_all")}</option>
                    {STATUS_KEYS.map((s) => (
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
                    label: extraColumnLabels[def.key] ?? def.key,
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
              {t("showing_count", { shown: sortedGroups.length, total: groups.length })}
            </p>

            {sortedGroups.length === 0 ? (
              <p className="font-body text-muted text-sm">{t("empty_no_match")}</p>
            ) : (
              <>
                <div className="hidden md:block">
                  <DataTable
                    columns={columns}
                    rows={sortedGroups}
                    rowKey={(g) => g.id}
                    expandedRowKey={expandedId}
                    onToggleRow={(key) => setExpandedId((cur) => (cur === key ? null : key))}
                    emptyMessage={t("empty_no_match")}
                    rowAriaLabel={(g) => g.clientName}
                    renderExpanded={(g) => <GroupDetailPanel group={g} />}
                  />
                </div>

                <div className="flex flex-col gap-3 md:hidden">
                  {sortedGroups.map((g) => (
                    <GroupCard
                      key={g.id}
                      group={g}
                      t={t}
                      expanded={expandedId === g.id}
                      onToggle={() => setExpandedId((cur) => (cur === g.id ? null : g.id))}
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

// Below 768px: cards, not a shrunk table — same pattern as /contracts and
// /clients.
function GroupCard({
  group,
  t,
  expanded,
  onToggle,
}: {
  group: Group;
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
          <p className="font-body text-brand-pink text-sm font-semibold">{group.clientName}</p>
          <span
            aria-hidden="true"
            className={`text-muted motion-safe:transition-transform ${expanded ? "rotate-180" : ""}`}
          >
            ▾
          </span>
        </div>
        {group.clientLegalName && <p className="font-body text-muted text-xs">{group.clientLegalName}</p>}
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="font-body bg-brand-pink/10 text-brand-pink inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-medium">
            {t(`module_${group.module}`)}
          </span>
          <StatusChip status={group.status} label={t(`status_${group.status}`)} />
        </div>
        {group.schedule_pattern && <p className="font-body text-muted mt-1 text-xs">{group.schedule_pattern}</p>}
        <TrainersLine principal={group.trainerPrincipalName} secundar={group.trainerSecundarName} none={t("no_trainer")} />
      </button>
      {expanded && (
        <div className="border-t border-black/5 px-4 py-4">
          <GroupDetailPanel group={group} />
        </div>
      )}
    </div>
  );
}

const DAYS_OF_WEEK = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function NewGroupForm({
  clientOptions,
  isPending,
  onSubmit,
  t,
}: {
  clientOptions: ClientOption[];
  isPending: boolean;
  t: (key: string, vars?: Record<string, string | number>) => string;
  onSubmit: (
    clientId: string,
    module: string,
    deliveryFormat: string,
    schedulePattern: string,
    status: string,
    ageRange: string,
    schoolYearCalendarLink: string,
  ) => void;
}) {
  const [clientId, setClientId] = useState(clientOptions[0]?.id ?? "");
  const [module, setModule] = useState(MODULE_KEYS[0]);
  const [deliveryFormat, setDeliveryFormat] = useState(FORMAT_KEYS[0]);
  const [status, setStatus] = useState("active");
  const [ageRange, setAgeRange] = useState("");
  const [calendarLink, setCalendarLink] = useState("");

  const isRecurring = deliveryFormat === "recurring";
  const [scheduleDay, setScheduleDay] = useState(DAYS_OF_WEEK[0]);
  const [scheduleDate, setScheduleDate] = useState("");
  const [scheduleTime, setScheduleTime] = useState("");
  const schedulePattern = isRecurring
    ? scheduleTime
      ? `${scheduleDay} ${scheduleTime}`
      : ""
    : scheduleDate
      ? `${scheduleDate}${scheduleTime ? ` ${scheduleTime}` : ""}`
      : "";

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("new_group_form_title")}
      </h2>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <select
          value={clientId}
          onChange={(e) => setClientId(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          <option value="">{t("select_client")}</option>
          {clientOptions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={module}
          onChange={(e) => setModule(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {MODULE_KEYS.map((value) => (
            <option key={value} value={value}>
              {t(`module_${value}`)}
            </option>
          ))}
        </select>
        <select
          value={deliveryFormat}
          onChange={(e) => setDeliveryFormat(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {FORMAT_KEYS.map((value) => (
            <option key={value} value={value}>
              {t(`format_${value}`)}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {STATUS_KEYS.map((value) => (
            <option key={value} value={value}>
              {t(`status_${value}`)}
            </option>
          ))}
        </select>
        {isRecurring ? (
          <>
            <select
              value={scheduleDay}
              onChange={(e) => setScheduleDay(e.target.value)}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            >
              {DAYS_OF_WEEK.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
            <input
              type="time"
              value={scheduleTime}
              onChange={(e) => setScheduleTime(e.target.value)}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          </>
        ) : (
          <>
            <input
              type="date"
              value={scheduleDate}
              onChange={(e) => setScheduleDate(e.target.value)}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
            <input
              type="time"
              value={scheduleTime}
              onChange={(e) => setScheduleTime(e.target.value)}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          </>
        )}
        <input
          type="text"
          value={ageRange}
          onChange={(e) => setAgeRange(e.target.value)}
          placeholder={t("age_range_placeholder")}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={calendarLink}
          onChange={(e) => setCalendarLink(e.target.value)}
          placeholder={t("calendar_link_placeholder")}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !clientId || !module || !deliveryFormat}
        onClick={() => onSubmit(clientId, module, deliveryFormat, schedulePattern, status, ageRange, calendarLink)}
        className="font-body focus-visible:ring-brand-pink mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity focus-visible:ring-2 focus-visible:outline-none disabled:opacity-50"
      >
        {t("create_group")}
      </button>
    </section>
  );
}
