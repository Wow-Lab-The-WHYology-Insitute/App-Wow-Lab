"use client";

import { useEffect, useState } from "react";

// ============================================================================
// DataTable — a reusable list-page table primitive. Built for /contracts
// (15 flat columns forced ~300px-tall wrapped rows and sideways page
// scroll) but column-definition-driven specifically so /clients and
// /groups can adopt it later without a second bespoke implementation.
//
// Ownership split, load-bearing for the "page must never scroll
// horizontally" requirement: THIS component's wrapper div owns
// overflow-x, via table-layout:fixed + an explicit <colgroup> (no browser
// width-guessing). The page/section around it must stay a normal block
// container — never wrap <DataTable> in something that also tries to
// manage horizontal scroll, or the requirement silently breaks.
// ============================================================================

export type DataTableColumn<T> = {
  key: string;
  header: string; // pre-translated by the caller (this component has no i18n opinion)
  width: number; // px — drives the <col>, matches table-layout:fixed
  align?: "left" | "right";
  /** Sticky-left. At most the row-number column (always sticky) plus one data column should set this — stacking more than that isn't visually meaningful. */
  sticky?: boolean;
  /** Column is omitted below this viewport width; still available in the expanded row detail. */
  hideBelowPx?: number;
  render: (row: T, index: number) => React.ReactNode;
};

const ROW_NUMBER_WIDTH = 32;
const CHEVRON_WIDTH = 32;

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  renderExpanded,
  expandedRowKey,
  onToggleRow,
  emptyMessage,
  rowAriaLabel,
}: {
  columns: DataTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  renderExpanded?: (row: T) => React.ReactNode;
  expandedRowKey?: string | null;
  onToggleRow?: (key: string) => void;
  emptyMessage: string;
  rowAriaLabel?: (row: T) => string;
}) {
  if (rows.length === 0) {
    return <p className="font-body text-muted text-sm">{emptyMessage}</p>;
  }

  // Sticky-left offsets: row-number column is always sticky at 0; the
  // first column with sticky:true (by convention, the first data column)
  // stacks right after it. Anything past that isn't tracked — the spec
  // only asks for these two.
  let stickyOffset = ROW_NUMBER_WIDTH;

  return (
    <div className="overflow-x-auto rounded-xl border border-black/5">
      <table className="w-full border-collapse text-sm" style={{ tableLayout: "fixed" }}>
        <colgroup>
          <col style={{ width: ROW_NUMBER_WIDTH }} />
          {columns.map((c) => (
            <col key={c.key} style={{ width: c.width }} />
          ))}
          <col style={{ width: CHEVRON_WIDTH }} />
        </colgroup>
        <thead>
          <tr>
            <th
              scope="col"
              className="border-b border-black/5 bg-white sticky top-0 left-0 z-20"
              aria-hidden="true"
            />
            {columns.map((c) => {
              const isSticky = c.sticky;
              const thisOffset = isSticky ? stickyOffset : undefined;
              if (isSticky) stickyOffset += c.width;
              return (
                <th
                  key={c.key}
                  scope="col"
                  className={`font-body text-muted sticky top-0 z-10 border-b border-black/5 bg-white px-3 py-2 text-[11px] font-medium tracking-[0.04em] uppercase ${
                    c.align === "right" ? "text-right" : "text-left"
                  } ${isSticky ? "z-20" : ""} ${
                    c.hideBelowPx ? hideBelowClass(c.hideBelowPx) : ""
                  }`}
                  style={isSticky ? { left: thisOffset } : undefined}
                >
                  {c.header}
                </th>
              );
            })}
            <th
              scope="col"
              className="border-b border-black/5 bg-white sticky top-0 z-10"
              aria-hidden="true"
            />
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => {
            const key = rowKey(row);
            return (
              <DataTableRow
                key={key}
                row={row}
                index={index}
                columns={columns}
                expanded={expandedRowKey === key}
                onToggle={onToggleRow ? () => onToggleRow(key) : undefined}
                renderExpanded={renderExpanded}
                ariaLabel={rowAriaLabel?.(row)}
              />
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

function hideBelowClass(px: number) {
  // Only the two breakpoints the /contracts spec actually needs (Entity,
  // Value hidden under 1024px) — extend this map if a future column needs
  // a different cutoff.
  if (px <= 768) return "max-[768px]:hidden";
  if (px <= 1024) return "max-[1024px]:hidden";
  return "";
}

export function DataTableRow<T>({
  row,
  index,
  columns,
  expanded,
  onToggle,
  renderExpanded,
  ariaLabel,
}: {
  row: T;
  index: number;
  columns: DataTableColumn<T>[];
  expanded: boolean;
  onToggle?: () => void;
  renderExpanded?: (row: T) => React.ReactNode;
  ariaLabel?: string;
}) {
  const totalCols = columns.length + 2;
  let stickyOffset = ROW_NUMBER_WIDTH;

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!onToggle) return;
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      onToggle();
    }
  };

  return (
    <>
      <tr
        className={`font-body text-ink border-b border-black/5 last:border-0 ${
          onToggle
            ? "hover:bg-ink/[0.02] focus-visible:outline-brand-pink cursor-pointer focus-visible:-outline-offset-2 focus-visible:outline-2 focus-visible:outline"
            : ""
        }`}
        onClick={onToggle}
        onKeyDown={handleKeyDown}
        tabIndex={onToggle ? 0 : undefined}
        role={onToggle ? "button" : undefined}
        aria-expanded={onToggle ? expanded : undefined}
        aria-label={ariaLabel}
        style={{ height: 56 }}
      >
        <td className="text-muted focus-visible:ring-brand-pink sticky left-0 z-10 bg-white px-2 py-1 text-right text-xs tabular-nums focus-visible:ring-2 focus-visible:outline-none">
          {index + 1}
        </td>
        {columns.map((c) => {
          const isSticky = c.sticky;
          const thisOffset = isSticky ? stickyOffset : undefined;
          if (isSticky) stickyOffset += c.width;
          return (
            <td
              key={c.key}
              className={`px-3 py-1 align-middle ${c.align === "right" ? "text-right" : "text-left"} ${
                isSticky ? "sticky z-10 bg-white" : ""
              } ${c.hideBelowPx ? hideBelowClass(c.hideBelowPx) : ""}`}
              style={isSticky ? { left: thisOffset } : undefined}
            >
              {c.render(row, index)}
            </td>
          );
        })}
        <td className="px-2 py-1 text-center">
          {onToggle && (
            <span
              aria-hidden="true"
              className={`text-muted inline-block motion-safe:transition-transform motion-safe:duration-150 ${expanded ? "rotate-180" : ""}`}
            >
              <ChevronIcon />
            </span>
          )}
        </td>
      </tr>
      {onToggle && renderExpanded && (
        <tr>
          <td colSpan={totalCols} className="p-0">
            <div
              className={`grid motion-safe:transition-[grid-template-rows] motion-safe:duration-200 motion-reduce:transition-none ${
                expanded ? "grid-rows-[1fr]" : "grid-rows-[0fr]"
              }`}
            >
              <div className="overflow-hidden">
                {expanded && (
                  <div className="border-b border-black/5 bg-ink/[0.015] px-4 py-4">
                    {renderExpanded(row)}
                  </div>
                )}
              </div>
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

// Text cell with the required nowrap/ellipsis/title treatment — a small
// shared helper so every column doesn't hand-repeat the same three
// utilities plus a title attribute.
export function TruncatedText({
  value,
  className,
}: {
  value: string;
  className?: string;
}) {
  return (
    <span
      title={value}
      className={`block overflow-hidden text-ellipsis whitespace-nowrap ${className ?? ""}`}
    >
      {value}
    </span>
  );
}

// ValueCell — the three-state rule this page didn't previously honor:
// null (nobody set it) vs. masked (you're not allowed to see it) vs. zero
// (a real value that happens to be 0) must never look the same.
export function ValueCell({
  value,
  visible,
  maskedLabel,
  maskedTitle,
  format,
}: {
  value: string | number | null;
  /** false = this value is masked for the current viewer (not merely absent) */
  visible: boolean;
  maskedLabel: string;
  maskedTitle: string;
  format?: (v: string | number) => string;
}) {
  if (value === null) {
    if (visible) {
      return <span className="text-muted">—</span>;
    }
    return (
      <span
        title={maskedTitle}
        className="text-muted inline-flex items-center gap-1 text-xs"
      >
        <LockIcon />
        {maskedLabel}
      </span>
    );
  }
  return (
    <span className="tabular-nums" style={{ fontVariantNumeric: "tabular-nums" }}>
      {format ? format(value) : value}
    </span>
  );
}

function LockIcon() {
  return (
    <svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true">
      <rect x="2" y="4.5" width="6" height="4.5" rx="1" stroke="currentColor" strokeWidth="1" />
      <path d="M3.2 4.5V3a1.8 1.8 0 0 1 3.6 0v1.5" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}

function ChevronIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
      <path d="M3 4.5 6 7.5 9 4.5" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

// ============================================================================
// DataTableToolbar — search (max-w-sm, never half the page) + filters +
// dismissible chips + a Columns dropdown slot + the page's primary action.
// Layout-only: filter controls, the columns dropdown, and the primary
// action button are all supplied by the caller as nodes — this component
// has no opinion on what a "filter" is, only where it sits.
// ============================================================================

export type FilterChip = { key: string; label: string; onRemove: () => void };

export function DataTableToolbar({
  searchValue,
  onSearchChange,
  searchPlaceholder,
  filters,
  chips,
  onClearAll,
  clearAllLabel,
  columnsToggle,
  primaryAction,
}: {
  searchValue?: string;
  onSearchChange?: (v: string) => void;
  searchPlaceholder?: string;
  filters?: React.ReactNode;
  chips?: FilterChip[];
  onClearAll?: () => void;
  clearAllLabel?: string;
  columnsToggle?: React.ReactNode;
  primaryAction?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="flex min-w-0 flex-1 flex-wrap items-center gap-2">
          {onSearchChange && (
            <input
              type="text"
              value={searchValue}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={searchPlaceholder}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 w-full max-w-sm rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none transition-colors focus:ring-2"
            />
          )}
          {filters}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          {columnsToggle}
          {primaryAction}
        </div>
      </div>

      {chips && chips.length > 0 && (
        <div className="flex flex-wrap items-center gap-1.5">
          {chips.map((chip) => (
            <button
              key={chip.key}
              type="button"
              onClick={chip.onRemove}
              className="font-body text-ink inline-flex items-center gap-1 rounded-full bg-ink/5 px-2.5 py-1 text-xs font-medium hover:bg-ink/10"
            >
              {chip.label}
              <span aria-hidden="true">×</span>
            </button>
          ))}
          {onClearAll && (
            <button
              type="button"
              onClick={onClearAll}
              className="font-body text-muted hover:text-ink text-xs font-medium underline"
            >
              {clearAllLabel}
            </button>
          )}
        </div>
      )}
    </div>
  );
}

// Columns visibility dropdown — a native <details>/<summary> rather than a
// hand-rolled popover: free keyboard support (Enter/Space toggles,
// focusable), no outside-click listener to wire up, matches this
// codebase's "don't add abstractions beyond what's needed" bias (no
// existing dropdown/popover primitive to build on anyway).
export function ColumnsDropdown({
  label,
  options,
}: {
  label: string;
  options: { key: string; label: string; checked: boolean; onChange: (checked: boolean) => void }[];
}) {
  return (
    <details className="group relative">
      <summary className="font-body text-ink focus-visible:ring-brand-pink flex cursor-pointer list-none items-center gap-1.5 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium focus-visible:ring-2 focus-visible:outline-none [&::-webkit-details-marker]:hidden">
        {label}
        <ChevronIcon />
      </summary>
      <div className="absolute right-0 z-30 mt-1 w-56 rounded-lg border border-black/10 bg-white p-2 shadow-lg">
        {options.map((opt) => (
          <label
            key={opt.key}
            className="font-body text-ink flex items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-ink/5"
          >
            <input
              type="checkbox"
              checked={opt.checked}
              onChange={(e) => opt.onChange(e.target.checked)}
              className="accent-[#EC008C]"
            />
            {opt.label}
          </label>
        ))}
      </div>
    </details>
  );
}

// Small hook: persist an array of visible-column keys to localStorage
// under a page-scoped key, hydration-safe (reads after mount — same
// reasoning as LocaleProvider in lib/i18n.tsx: reading localStorage in the
// initial useState would produce a client/server markup mismatch).
export function usePersistedColumns(pageKey: string, defaultVisible: string[]) {
  const storageKey = `wowlab.columns.${pageKey}`;
  const [visible, setVisibleState] = useState<string[]>(defaultVisible);

  useEffect(() => {
    try {
      const stored = window.localStorage.getItem(storageKey);
      if (stored) {
        const parsed = JSON.parse(stored);
        if (Array.isArray(parsed)) setVisibleState(parsed);
      }
    } catch {
      // Corrupt localStorage value — fall back to defaultVisible, already set.
    }
  }, [storageKey]);

  function setVisible(next: string[]) {
    setVisibleState(next);
    window.localStorage.setItem(storageKey, JSON.stringify(next));
  }

  return [visible, setVisible] as const;
}
