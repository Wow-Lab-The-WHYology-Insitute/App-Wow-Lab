"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { contractsDict } from "../i18n";
import { isDemoRecord } from "../format";
import { MarkSignedButton } from "./mark-signed-button";
import { DeleteContractButton } from "./delete-contract-button";

// page.tsx is a Server Component and can't call useTranslations() itself --
// same split as client-header.tsx/group-header.tsx. contract_type_${x}/
// status_${x} match the exact template-key convention contracts-client.tsx
// already uses; demo_badge_label/title reuse the SAME keys (and the same
// tooltip-span shape) that file's own DemoBadge renders, though this page
// kept its own slightly different className rather than unifying the two
// (a pre-existing visual inconsistency, not introduced here).
export function ContractHeader({
  contractId,
  exitNumber,
  entryNumber,
  clientName,
  contractType,
  status,
  notes,
  canManage,
}: {
  contractId: string;
  exitNumber: string | null;
  entryNumber: string | null;
  clientName: string;
  contractType: string;
  status: string;
  notes: string | null;
  canManage: boolean;
}) {
  const t = useTranslations(contractsDict);
  return (
    <div>
      <Link href="/contracts" className="font-body text-muted text-xs hover:underline">
        {t("back_link")}
      </Link>
      <h1
        className={`font-display text-2xl ${exitNumber ? "text-brand-pink" : "text-muted italic"}`}
      >
        {exitNumber || t("no_exit_number", { client: clientName })}
      </h1>
      <div className="mt-2 flex flex-wrap items-center gap-1.5">
        <Badge>{t(`contract_type_${contractType}`)}</Badge>
        <Badge tone={status === "signed" ? "neutral" : "pink"}>{t(`status_${status}`)}</Badge>
        {isDemoRecord(notes) && (
          <span
            title={t("demo_badge_title")}
            className="font-body inline-flex w-fit items-center gap-1 rounded-full bg-orange-100 px-2.5 py-0.5 text-xs font-medium text-orange-700"
          >
            ⚠ {t("demo_badge_label")}
          </span>
        )}
        {canManage && (status === "draft" || status === "sent") && (
          <MarkSignedButton contractId={contractId} />
        )}
      </div>
      {canManage && status === "draft" && (
        <div className="mt-2">
          <DeleteContractButton
            contractId={contractId}
            label={exitNumber || entryNumber || t("draft_fallback_label")}
          />
        </div>
      )}
    </div>
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
        tone === "pink" ? "bg-brand-pink/10 text-brand-pink" : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
