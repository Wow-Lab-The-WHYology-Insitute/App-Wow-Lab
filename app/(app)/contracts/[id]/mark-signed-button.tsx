"use client";

import { useState, useTransition } from "react";
import { markContractSigned } from "../actions";

// UI gate is only "canManage && status !== 'signed'" (see page.tsx) —
// the actual enforcement is the contracts UPDATE RLS policy
// (202608100003). markContractSigned() surfaces RLS's "0 rows affected"
// as a real error here rather than silently no-op'ing.
export function MarkSignedButton({ contractId }: { contractId: string }) {
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
        Mark as signed
      </button>
      {error && <span className="text-brand-pink text-xs">{error}</span>}
    </span>
  );
}
