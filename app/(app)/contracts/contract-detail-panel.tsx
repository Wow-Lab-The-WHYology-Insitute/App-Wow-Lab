"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { ValueCell } from "@/components/ui/data-table";
import { contractsDict } from "./i18n";
import { formatMoney } from "./format";

export type ContractDetail = {
  id: string;
  clientLegalName: string | null;
  clientCui: string | null;
  client_contract_number: string | null;
  billing_rule: string | null;
  signed_date: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  legalEntityName: string;
  drive_ref: string | null;
  notes: string | null;
  offer_structure: string | null;
  ac_link: string | null;
};

// Matches contracts.offer_structure's check constraint (202608160002).
const OFFER_STRUCTURE_LABELS: Record<string, { en: string; ro: string }> = {
  fixed_price_group_workshop: { en: "Fixed price per group workshop", ro: "Preț fix pe atelier de grup" },
  price_per_child_present: { en: "Price per child present", ro: "Preț per copil prezent" },
  price_per_child_enrolled: { en: "Price per child enrolled", ro: "Preț per copil înscris" },
  price_per_contract: { en: "Price per contract", ro: "Preț per contract" },
};

// Extracted into its own file, not inlined into contracts-client.tsx, so
// the future /contracts/[id] page can reuse it verbatim (per the task
// spec) instead of re-implementing the same field list a second time.
//
// offer_structure/ac_link are NOT in the task's literal field list for
// this panel — added anyway (flagged in the build report) because both
// are real, already-shipped columns (added in the prior Anca-feedback
// pass); dropping them from every visible surface on this page would
// silently orphan live data, not just tidy up an old spec.
export function ContractDetailPanel({
  contract,
  financeVisible,
  locale,
}: {
  contract: ContractDetail;
  financeVisible: boolean;
  locale: "en" | "ro";
}) {
  const t = useTranslations(contractsDict);

  return (
    <div className="flex flex-col gap-4">
      <dl
        className="grid gap-x-6 gap-y-3"
        style={{ gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))" }}
      >
        <DetailField label={t("detail_legal_name")}>{contract.clientLegalName || "—"}</DetailField>
        <DetailField label={t("detail_cui")} mono>
          {contract.clientCui || "—"}
        </DetailField>
        <DetailField label={t("detail_client_contract_number")}>
          {contract.client_contract_number || "—"}
        </DetailField>
        <DetailField label={t("detail_billing_rule")}>
          <ValueCell
            value={contract.billing_rule}
            visible={financeVisible}
            maskedLabel={t("masked_label")}
            maskedTitle={t("masked_title")}
          />
        </DetailField>
        <DetailField label={t("detail_signed_date")}>{contract.signed_date || "—"}</DetailField>
        <DetailField label={t("detail_estimated_value")}>
          <ValueCell
            value={contract.estimated_value}
            visible={financeVisible}
            maskedLabel={t("masked_label")}
            maskedTitle={t("masked_title")}
            format={(v) => formatMoney(v, locale)}
          />
        </DetailField>
        <DetailField label={t("detail_previous_year_value")}>
          <ValueCell
            value={contract.previous_year_value}
            visible={financeVisible}
            maskedLabel={t("masked_label")}
            maskedTitle={t("masked_title")}
            format={(v) => formatMoney(v, locale)}
          />
        </DetailField>
        <DetailField label={t("detail_legal_entity")}>{contract.legalEntityName}</DetailField>
        <DetailField label={t("detail_drive_link")}>
          {contract.drive_ref ? (
            <a
              href={contract.drive_ref}
              target="_blank"
              rel="noreferrer"
              className="text-brand-pink font-medium hover:underline"
            >
              {t("open_link")}
            </a>
          ) : (
            "—"
          )}
        </DetailField>
        <DetailField label={locale === "ro" ? "Structură ofertă" : "Offer structure"}>
          {contract.offer_structure
            ? (OFFER_STRUCTURE_LABELS[contract.offer_structure]?.[locale] ?? contract.offer_structure)
            : "—"}
        </DetailField>
        <DetailField label="AC">
          {contract.ac_link ? (
            <a
              href={contract.ac_link}
              target="_blank"
              rel="noreferrer"
              className="text-brand-pink font-medium hover:underline"
            >
              {t("open_link")}
            </a>
          ) : (
            "—"
          )}
        </DetailField>
        <DetailField label={t("detail_notes")} wide>
          {contract.notes || "—"}
        </DetailField>
      </dl>

      {/* "Edit" removed — two buttons pointing at the same destination
          (no standalone edit form exists yet) was worse than one. Re-add
          once a real edit form exists, gated the same way as everywhere
          else in this app: a checkCapability(supabase, "contracts.*",
          org) check computed server-side in page.tsx. */}
      <div className="flex gap-3 border-t border-black/5 pt-3">
        <Link
          href={`/contracts/${contract.id}`}
          className="font-body text-ink focus-visible:ring-brand-pink rounded-full border border-black/10 px-4 py-1.5 text-xs font-medium hover:bg-ink/5 focus-visible:ring-2 focus-visible:outline-none"
        >
          {t("open_contract")}
        </Link>
      </div>
    </div>
  );
}

function DetailField({
  label,
  children,
  mono,
  wide,
}: {
  label: string;
  children: React.ReactNode;
  mono?: boolean;
  wide?: boolean;
}) {
  return (
    <div className={wide ? "col-span-full" : undefined}>
      <dt className="font-body text-muted text-xs">{label}</dt>
      <dd className={`font-body text-ink mt-0.5 text-sm ${mono ? "font-mono" : ""}`}>{children}</dd>
    </div>
  );
}
