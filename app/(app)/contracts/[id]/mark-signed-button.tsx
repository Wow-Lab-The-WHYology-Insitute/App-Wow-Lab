"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { contractsDict } from "../i18n";
import { markContractSigned } from "../actions";

function today() {
  return new Date().toISOString().slice(0, 10);
}

// UI gate is "canManage && status is draft or sent" (see page.tsx) — a
// convenience, not the enforcement. markContractSigned() itself re-checks
// status server-side (won't move an already-signed/expired/renewed
// contract) and surfaces RLS's "0 rows affected" as a real error here
// rather than silently no-op'ing.
//
// Trigger -> inline confirm pill, same two-state shape as
// DeleteContractButton right below this component on the same header —
// not a new pattern introduced for this field. The date input defaults
// to today (matching the server's own fallback when nothing is
// supplied) but is editable, so a contract signed before it entered the
// platform can carry its real date instead of the moment someone
// happened to click the button. No upper bound on the date is enforced
// here, deliberately — see docs/OPEN_ITEMS.md for the open question of
// whether a future date should be rejected at all, and where.
export function MarkSignedButton({ contractId }: { contractId: string }) {
  const t = useTranslations(contractsDict);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const [signedDate, setSignedDate] = useState(today);
  const [isPending, startTransition] = useTransition();

  if (!confirming) {
    return (
      <span className="inline-flex items-center gap-2">
        <button
          type="button"
          onClick={() => setConfirming(true)}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {t("mark_as_signed")}
        </button>
        {error && <span className="text-brand-pink text-xs">{error}</span>}
      </span>
    );
  }

  return (
    <span className="font-body text-ink inline-flex flex-wrap items-center gap-2 rounded-lg bg-brand-pink/10 px-3 py-1.5 text-xs">
      {t("mark_signed_date_label")}
      <input
        type="date"
        value={signedDate}
        onChange={(e) => setSignedDate(e.target.value)}
        className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 bg-white px-2 py-1 text-xs outline-none focus:ring-2"
      />
      <button
        type="button"
        disabled={isPending}
        onClick={() => {
          setError(null);
          startTransition(async () => {
            try {
              const result = await markContractSigned(contractId, signedDate);
              if (!result.ok) setError(result.error);
              else setConfirming(false);
            } catch {
              setError(t("network_error"));
            }
          });
        }}
        className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        {t("confirm_mark_signed")}
      </button>
      <button
        type="button"
        onClick={() => setConfirming(false)}
        className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
      >
        {t("cancel")}
      </button>
      {error && <span className="text-brand-pink w-full text-xs font-semibold">{error}</span>}
    </span>
  );
}
