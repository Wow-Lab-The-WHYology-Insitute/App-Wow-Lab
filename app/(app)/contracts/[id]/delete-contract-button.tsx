"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { useTranslations } from "@/lib/i18n";
import { contractsDict } from "../i18n";
import { deleteContract } from "../actions";

// UI gate is "canManage && status === 'draft'" (see page.tsx) -- absent
// for every other status, not disabled, same discipline as
// MarkSignedButton. deleteContract() itself re-checks both halves of the
// predicate server-side, so a stale render of this button (e.g. two tabs,
// one just marked the contract signed) still can't delete anything RLS
// wouldn't already allow.
export function DeleteContractButton({
  contractId,
  label,
}: {
  contractId: string;
  label: string;
}) {
  const router = useRouter();
  const t = useTranslations(contractsDict);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const [isPending, startTransition] = useTransition();

  if (!confirming) {
    return (
      <span className="inline-flex items-center gap-2">
        <button
          type="button"
          onClick={() => setConfirming(true)}
          className="font-body text-brand-pink text-xs font-semibold underline"
        >
          {t("delete_draft")}
        </button>
        {error && <span className="text-brand-pink text-xs">{error}</span>}
      </span>
    );
  }

  return (
    <span className="font-body text-ink inline-flex flex-wrap items-center gap-2 rounded-lg bg-brand-pink/10 px-3 py-1.5 text-xs">
      {t("delete_confirm_prefix")}
      <strong>{label}</strong>
      {t("delete_confirm_suffix")}
      <button
        type="button"
        disabled={isPending}
        onClick={() => {
          setError(null);
          startTransition(async () => {
            const result = await deleteContract(contractId);
            if (!result.ok) {
              setError(result.error);
            } else {
              router.push("/contracts");
            }
          });
        }}
        className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        {t("confirm_delete")}
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
