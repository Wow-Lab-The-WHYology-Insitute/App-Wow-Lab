"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { contractsDict } from "../i18n";
import { markContractSigned } from "../actions";

// UI gate is "canManage && status is draft or sent" (see page.tsx) — a
// convenience, not the enforcement. markContractSigned() itself re-checks
// status server-side (won't move an already-signed/expired/renewed
// contract) and surfaces RLS's "0 rows affected" as a real error here
// rather than silently no-op'ing.
export function MarkSignedButton({ contractId }: { contractId: string }) {
  const t = useTranslations(contractsDict);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  return (
    <span className="inline-flex items-center gap-2">
      <button
        type="button"
        disabled={isPending}
        onClick={() => {
          setError(null);
          startTransition(async () => {
            const result = await markContractSigned(contractId);
            if (!result.ok) setError(result.error);
          });
        }}
        className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        {t("mark_as_signed")}
      </button>
      {error && <span className="text-brand-pink text-xs">{error}</span>}
    </span>
  );
}
