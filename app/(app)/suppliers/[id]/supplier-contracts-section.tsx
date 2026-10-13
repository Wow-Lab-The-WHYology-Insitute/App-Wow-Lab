"use client";

import { useState } from "react";
import { useTranslations } from "@/lib/i18n";
import { suppliersDict } from "../i18n";
import { contractsDict } from "../../contracts/i18n";
import { entityShortCode } from "@/lib/format";

export type SupplierContractRow = {
  id: string;
  exit_number: string | null;
  signed_date: string | null;
  period_start: string | null;
  period_end: string | null;
  is_open_ended: boolean;
  amends_contract_id: string | null;
  status: string;
  price_text: string | null;
  contract_value: string | number | null;
  drive_ref: string | null;
  notes: string | null;
  legalEntityName: string | null;
};

// ============================================================================
// This supplier's contracts, as a section on its sheet rather than a list page
// of its own. 30 rows across 19 of the 22 suppliers, at most 4 on any one of
// them, so this is a sheet-sized problem; and the amendment chains only mean
// anything inside a single supplier, where a flat sortable list would break a
// contract and its two amendments into three equal rows.
//
// THE SECTION RENDERS FOR EVERY VIEWER, WITH NO EXCEPTION. For someone without
// finance.reporting.* it shows a lock instead of contracts, on every supplier
// including the three that have none. Rendering it only where rows exist would
// make its presence the signal — the lock would say "this one has contracts",
// which is the one thing it is there to withhold.
// ============================================================================
export function SupplierContractsSection({
  contracts,
  canSeeContracts,
}: {
  contracts: SupplierContractRow[];
  /** From a server-side capability check, NEVER from contracts.length — three
      suppliers genuinely have zero rows and must not look like a refusal. */
  canSeeContracts: boolean;
}) {
  const t = useTranslations(suppliersDict);

  if (!canSeeContracts) {
    return (
      <Section title={t("contracts_heading", { count: "—" })}>
        <p className="font-body text-muted flex items-center gap-2 text-sm">
          <LockIcon />
          {t("contracts_locked")}
        </p>
      </Section>
    );
  }

  // Roots are the contracts; everything with amends_contract_id hangs off the
  // one it amends. The count in the heading is roots.length for that reason —
  // Raluca has three rows and one contract.
  const roots = contracts.filter((c) => !c.amends_contract_id);
  const byParent = new Map<string, SupplierContractRow[]>();
  for (const c of contracts) {
    if (!c.amends_contract_id) continue;
    const siblings = byParent.get(c.amends_contract_id) ?? [];
    siblings.push(c);
    byParent.set(c.amends_contract_id, siblings);
  }
  for (const list of byParent.values()) {
    list.sort((a, b) => (a.period_start ?? "").localeCompare(b.period_start ?? ""));
  }

  return (
    <Section title={t("contracts_heading", { count: roots.length })}>
      {roots.length === 0 ? (
        <p className="font-body text-muted text-sm">{t("empty_no_supplier_contracts")}</p>
      ) : (
        // A rule between contracts, and only between CONTRACTS -- the chain
        // inside one of them is held together by its indent instead. Without
        // it two roots with no number and no dates ran straight into each
        // other: the first one's notes sat 16px above the second one's title
        // and nothing said where one ended. This is the one place in this pass
        // where a line earns its keep, and it is the same treatment the client
        // sheet's contracts list already uses.
        <ul className="gap-section flex flex-col">
          {roots.map((c) => (
            <li key={c.id} className="pb-section border-b border-black/5 last:border-0 last:pb-0">
              <ContractNode contract={c} byParent={byParent} depth={0} />
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

// Recursive, not one level of grouping. Raluca's chain is already two deep —
// the original is amended by one act, and that act is amended by a second —
// so "parent plus its children" would have rendered the third as a sibling of
// the first. Nothing in the schema caps the depth either.
function ContractNode({
  contract,
  byParent,
  depth,
}: {
  contract: SupplierContractRow;
  byParent: Map<string, SupplierContractRow[]>;
  depth: number;
}) {
  const children = byParent.get(contract.id) ?? [];
  return (
    <>
      <ContractCard contract={contract} isAmendment={depth > 0} />
      {children.length > 0 && (
        <ul className="border-black/8 mt-snug ml-tight flex flex-col gap-snug border-l pl-snug">
          {children.map((child) => (
            <li key={child.id}>
              <ContractNode contract={child} byParent={byParent} depth={depth + 1} />
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

function ContractCard({
  contract: c,
  isAmendment,
}: {
  contract: SupplierContractRow;
  isAmendment: boolean;
}) {
  const t = useTranslations(suppliersDict);
  const tContract = useTranslations(contractsDict);

  return (
    <div className="flex flex-col gap-tight">
      <div className="flex flex-wrap items-center gap-tight">
        {isAmendment && (
          <span className="font-body bg-brand-pink/10 text-brand-pink inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium">
            {t("amendment_label")}
          </span>
        )}
        <span
          className={`font-body font-mono text-sm font-semibold ${
            c.exit_number ? "text-ink" : "text-muted italic"
          }`}
        >
          {c.exit_number || t("no_exit_number_supplier")}
        </span>
        {c.legalEntityName && (
          <span
            title={c.legalEntityName}
            className="font-mono text-ink bg-ink/5 inline-flex items-center rounded px-1.5 py-0.5 text-[11px] font-medium"
          >
            {entityShortCode(c.legalEntityName)}
          </span>
        )}
        <span className="font-body bg-ink/5 text-ink inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium">
          {tContract(`status_${c.status}`)}
        </span>
      </div>

      <Period start={c.period_start} end={c.period_end} isOpenEnded={c.is_open_ended} />
      <Price priceText={c.price_text} value={c.contract_value} />

      {c.notes && <p className="font-body text-muted text-xs">{c.notes}</p>}

      {c.drive_ref && (
        <a
          href={c.drive_ref}
          target="_blank"
          rel="noreferrer"
          className="text-brand-pink font-body w-fit text-xs font-medium hover:underline"
        >
          {t("open_drive")}
        </a>
      )}
    </div>
  );
}

// THREE states, and the third is the biggest. A date is a date; `is_open_ended`
// gets the WORD, because a contract that runs until someone ends it is a fact
// somebody recorded; and period_end null with is_open_ended false is nobody
// having written it down, which gets the muted dash this app already uses for
// an unset field. Seven rows are that third case against five of the second,
// so collapsing them into one glyph would mislead on the larger half.
// period_start is null on four rows too and takes the same dash.
function Period({
  start,
  end,
  isOpenEnded,
}: {
  start: string | null;
  end: string | null;
  isOpenEnded: boolean;
}) {
  const t = useTranslations(suppliersDict);
  return (
    <p className="font-body text-ink text-sm">
      {start ? <span className="tabular-nums">{start}</span> : <Unknown />}
      <span className="text-muted mx-1.5">→</span>
      {end ? (
        <span className="tabular-nums">{end}</span>
      ) : isOpenEnded ? (
        <span className="text-ink">{t("period_open_ended")}</span>
      ) : (
        <Unknown />
      )}
    </p>
  );
}

function Unknown() {
  return <span className="text-muted font-normal">—</span>;
}

// ONE field, not a price column beside a value column. Of the thirty rows, ten
// carry contract_value and on nine of those price_text is the same number as a
// string ("800.0"), while fourteen have only text that the number could not
// hold ("80 RON/ORA, 90 RON/ORA", "180 EURO +TVA", "1000 ron/trimestru") and
// six have neither. Two fields would have meant twenty empty cells next to
// nine that repeat each other.
//
// The text wins whenever it says more than the bare number: EDUKIWI's value is
// 10099.87 and its text is "10099.87 ron/curs", where the unit lives only in
// the text. contract_value stays in the row for arithmetic and is never summed
// here — the migration states the ten are implicitly RON and that United
// Media's "1928 EUR" was deliberately left out of that column, so a total
// across it would be adding euros to lei.
function Price({
  priceText,
  value,
}: {
  priceText: string | null;
  value: string | number | null;
}) {
  const t = useTranslations(suppliersDict);
  const [expanded, setExpanded] = useState(false);

  const numeric = value === null || value === undefined ? null : Number(value);
  const textIsJustTheNumber =
    priceText !== null && numeric !== null && Number(priceText) === numeric;

  let display: string | null = null;
  if (priceText !== null && !textIsJustTheNumber) display = priceText;
  else if (numeric !== null) display = `${formatRon(numeric)} RON`;
  else if (priceText !== null) display = priceText;

  if (display === null) {
    return (
      <p className="font-body text-muted text-sm">
        {t("price_label")}: <span className="font-normal">{t("price_unrecorded")}</span>
      </p>
    );
  }

  // Raluca's 2025 contract carries its own tier table as 173 characters of
  // bulleted prose, so this clamps like the group sheet's notes rather than
  // letting one row set the height of the section.
  const long = display.length > 60 || display.includes("\n");
  return (
    <p className="font-body text-ink text-sm">
      <span className="text-muted">{t("price_label")}: </span>
      <span
        onClick={long ? () => setExpanded((v) => !v) : undefined}
        className={`whitespace-pre-line ${long ? "cursor-pointer" : ""} ${
          long && !expanded ? "line-clamp-3" : ""
        }`}
      >
        {display}
      </span>
      {long && (
        <button
          type="button"
          onClick={() => setExpanded((v) => !v)}
          className="text-brand-pink font-body ml-1 text-xs font-medium hover:underline"
        >
          {expanded ? t("show_less") : t("show_more")}
        </button>
      )}
    </p>
  );
}

// No decimals when there are none to show: nine of the ten values are round
// (800, 1000, 650), and "800.00 RON" reads like a figure that was computed.
function formatRon(n: number) {
  return Number.isInteger(n) ? String(n) : n.toFixed(2);
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="p-section rounded-2xl border border-black/5 bg-white shadow-sm">
      <h2 className="font-body text-muted mb-snug text-xs font-bold tracking-wide uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

function LockIcon() {
  return (
    <svg width="11" height="11" viewBox="0 0 10 10" fill="none" aria-hidden="true">
      <rect x="2" y="4.5" width="6" height="4.5" rx="1" stroke="currentColor" strokeWidth="1" />
      <path d="M3.2 4.5V3a1.8 1.8 0 0 1 3.6 0v1.5" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}
