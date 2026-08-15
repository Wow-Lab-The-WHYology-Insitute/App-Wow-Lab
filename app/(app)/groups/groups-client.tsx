"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { addGroup } from "./actions";

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

// Keys taken verbatim from docs/mockup/wow_lab_os_mockup.html's MODULES
// object — the same 13 real curriculum-module keys the groups.module CHECK
// constraint (202608130001) enforces. Reused here rather than re-deriving a
// second mapping.
const MODULE_LABELS: Record<string, string> = {
  gaga: "GAGA",
  green_energy: "Green Energy",
  wow_mix: "Wow Lab Mix",
  tiktok: "Wow TikTok Science",
  food_science: "Wow Food Science",
  lotions: "Wow Lotions and Potions",
  magic_physics: "Magic of Physics",
  chem_me: "Chemistry for Me",
  chem_hs: "Chemistry for Highschool",
  lights: "Lights and Colours",
  detective: "Detective Science",
  astronomy: "Astronomy",
  doctor: "I Wanna Be a Doctor",
};

// Label TEXT reused from the mockup's DELIVERY_FORMAT object where the
// concept matches (recurring/party/corporate/custom share the mockup's
// keys exactly). scoala_altfel/saptamana_verde use the real DB CHECK
// constraint's full-word keys (202608130001) rather than the mockup's
// abbreviated sa/sv keys — a working decision flagged in that migration's
// own column comment, not something this UI silently reinvents; the
// display TEXT itself ("Școala Altfel" / "Săptămâna Verde") is still the
// mockup's own text, unchanged.
const DELIVERY_FORMAT_LABELS: Record<string, string> = {
  recurring: "Recurring (school club)",
  scoala_altfel: "Școala Altfel",
  saptamana_verde: "Săptămâna Verde",
  party: "Party",
  corporate: "Corporate",
  custom: "Custom",
};

// Matches the groups.status check constraint (202608130001) exactly.
const GROUP_STATUS_LABELS: Record<string, string> = {
  active: "Active",
  paused: "Paused",
  ended: "Ended",
};

// Nulls always sort last regardless of direction — same convention as
// clients-client.tsx / contracts-client.tsx.
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
  | "clientName"
  | "clientLegalName"
  | "module"
  | "delivery_format"
  | "schedule_pattern"
  | "children_confirmed"
  | "children_billed"
  | "status";

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
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [sortKey, setSortKey] = useState<SortKey>("clientName");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [moduleFilter, setModuleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [formatFilter, setFormatFilter] = useState("all");

  function onSort(key: SortKey) {
    if (key === sortKey) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  // Module/format filter options come from the already-fetched, RLS-scoped
  // groups themselves, not the full label catalogs — same reasoning as
  // contracts-client.tsx's entityOptions: guarantees the filter can never
  // offer a value RLS didn't already surface.
  const moduleOptions = useMemo(() => {
    return [...new Set(groups.map((g) => g.module))].sort();
  }, [groups]);
  const formatOptions = useMemo(() => {
    return [...new Set(groups.map((g) => g.delivery_format))].sort();
  }, [groups]);

  // Search + filters run over the same already-fetched, RLS-scoped array
  // sorting already used — client-side over the array in hand, never a
  // re-query, so this can only narrow what RLS already returned. Search
  // covers client name AND the current allocation's trainer names (the
  // "current allocation" — most recent session — is all this list ever
  // has to search against; see groups/page.tsx's own comment on that
  // interpretation call).
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

  return (
    <div className="flex flex-col gap-6">
      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {/* groups.create capability gate — same relationship as /clients'
          createOrgId. Collapsed by default, same gradient-pill disclosure
          pattern as /clients and /contracts. */}
      {createOrgId && (
        <div className="flex flex-col gap-4">
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
          >
            + New group
          </button>
          {isFormOpen && (
            <NewGroupForm
              clientOptions={clientOptions}
              isPending={isPending}
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
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Groups ({groups.length})
        </h2>

        {groups.length === 0 ? (
          <p className="font-body text-muted text-sm">
            {isTrainerView
              ? "You have no allocated groups yet."
              : "No groups visible for your role."}
          </p>
        ) : (
          <>
            <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by client or trainer…"
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
              />
              <select
                value={moduleFilter}
                onChange={(e) => setModuleFilter(e.target.value)}
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
              >
                <option value="all">All modules</option>
                {moduleOptions.map((m) => (
                  <option key={m} value={m}>
                    {MODULE_LABELS[m] ?? m}
                  </option>
                ))}
              </select>
              <select
                value={formatFilter}
                onChange={(e) => setFormatFilter(e.target.value)}
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
              >
                <option value="all">All formats</option>
                {formatOptions.map((f) => (
                  <option key={f} value={f}>
                    {DELIVERY_FORMAT_LABELS[f] ?? f}
                  </option>
                ))}
              </select>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
              >
                <option value="all">All statuses</option>
                {Object.entries(GROUP_STATUS_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            {sortedGroups.length === 0 ? (
              <p className="font-body text-muted text-sm">
                No groups match your search or filters.
              </p>
            ) : (
              <>
                <table className="hidden w-full border-collapse text-sm md:table">
                  <thead>
                    <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                      <SortHeader label="School/Parent" sortKey="clientName" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Company" sortKey="clientLegalName" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Module" sortKey="module" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Format" sortKey="delivery_format" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Schedule" sortKey="schedule_pattern" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <th className="py-2 pr-4 font-bold">Trainers</th>
                      <SortHeader label="Confirmed" sortKey="children_confirmed" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Billed" sortKey="children_billed" activeKey={sortKey} dir={sortDir} onSort={onSort} />
                      <SortHeader label="Status" sortKey="status" activeKey={sortKey} dir={sortDir} onSort={onSort} className="py-2" />
                    </tr>
                  </thead>
                  <tbody>
                    {sortedGroups.map((g) => (
                      <tr
                        key={g.id}
                        className="font-body text-ink border-b border-black/5 last:border-0"
                      >
                        <td className="py-3 pr-4">
                          <Link
                            href={`/groups/${g.id}`}
                            className="text-brand-pink font-semibold hover:underline"
                          >
                            {g.clientName}
                          </Link>
                        </td>
                        <td className="text-muted py-3 pr-4">{g.clientLegalName || "—"}</td>
                        <td className="py-3 pr-4">
                          <Badge>{MODULE_LABELS[g.module] ?? g.module}</Badge>
                        </td>
                        <td className="py-3 pr-4">
                          <Badge>{DELIVERY_FORMAT_LABELS[g.delivery_format] ?? g.delivery_format}</Badge>
                        </td>
                        <td className="text-muted py-3 pr-4">
                          {g.schedule_pattern || "—"}
                        </td>
                        <td className="text-muted py-3 pr-4 text-xs">
                          {g.trainerPrincipalName || g.trainerSecundarName ? (
                            <>
                              {g.trainerPrincipalName || "—"}
                              {g.trainerSecundarName ? ` / ${g.trainerSecundarName}` : ""}
                            </>
                          ) : (
                            "—"
                          )}
                        </td>
                        <td className="text-muted py-3 pr-4">
                          {g.children_confirmed ?? "—"}
                        </td>
                        <td className="text-muted py-3 pr-4">
                          {g.children_billed ?? "—"}
                        </td>
                        <td className="py-3">
                          <Badge tone={g.status === "active" ? "neutral" : "pink"}>
                            {GROUP_STATUS_LABELS[g.status] ?? g.status}
                          </Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                <div className="flex flex-col gap-3 md:hidden">
                  {sortedGroups.map((g) => (
                    <Link
                      key={g.id}
                      href={`/groups/${g.id}`}
                      className="block rounded-xl border border-black/5 p-4"
                    >
                      <p className="font-body text-brand-pink font-semibold">
                        {g.clientName}
                      </p>
                      {g.clientLegalName && (
                        <p className="font-body text-muted text-xs">{g.clientLegalName}</p>
                      )}
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        <Badge>{MODULE_LABELS[g.module] ?? g.module}</Badge>
                        <Badge>{DELIVERY_FORMAT_LABELS[g.delivery_format] ?? g.delivery_format}</Badge>
                        <Badge tone={g.status === "active" ? "neutral" : "pink"}>
                          {GROUP_STATUS_LABELS[g.status] ?? g.status}
                        </Badge>
                      </div>
                      {g.schedule_pattern && (
                        <p className="font-body text-muted mt-2 text-xs">
                          {g.schedule_pattern}
                        </p>
                      )}
                      {(g.trainerPrincipalName || g.trainerSecundarName) && (
                        <p className="font-body text-muted mt-1 text-xs">
                          Trainers: {g.trainerPrincipalName || "—"}
                          {g.trainerSecundarName ? ` / ${g.trainerSecundarName}` : ""}
                        </p>
                      )}
                      <p className="font-body text-muted mt-1 text-xs">
                        Confirmed {g.children_confirmed ?? "—"} · Billed {g.children_billed ?? "—"}
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

const DAYS_OF_WEEK = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

function NewGroupForm({
  clientOptions,
  isPending,
  onSubmit,
}: {
  clientOptions: ClientOption[];
  isPending: boolean;
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
  const [module, setModule] = useState(Object.keys(MODULE_LABELS)[0]);
  const [deliveryFormat, setDeliveryFormat] = useState(
    Object.keys(DELIVERY_FORMAT_LABELS)[0],
  );
  const [status, setStatus] = useState("active");
  const [ageRange, setAgeRange] = useState("");
  const [calendarLink, setCalendarLink] = useState("");

  // Structured, format-aware schedule input — recurring groups get a
  // day-of-week + time picker, one-off formats (party/corporate/scoala_
  // altfel/etc.) get a calendar date + time picker — both still compose
  // into schedule_pattern's existing free-text shape (matches the "Tuesday
  // 14:00" style already used by real data) rather than a new structured
  // column, per the task's explicit "still writing into the existing
  // schedule_pattern text field" instruction.
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
        New group
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
          value={module}
          onChange={(e) => setModule(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(MODULE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <select
          value={deliveryFormat}
          onChange={(e) => setDeliveryFormat(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(DELIVERY_FORMAT_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(GROUP_STATUS_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
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
          placeholder="Age range (e.g. 6-9 ani — optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={calendarLink}
          onChange={(e) => setCalendarLink(e.target.value)}
          placeholder="School-year calendar link (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !clientId || !module || !deliveryFormat}
        onClick={() =>
          onSubmit(clientId, module, deliveryFormat, schedulePattern, status, ageRange, calendarLink)
        }
        className="font-body mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        Create group
      </button>
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
