"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "../i18n";
import { changeClientStatus } from "../actions";
import { CLIENT_STATUS_TRANSITIONS } from "../status";

const STATUS_ACTION_KEYS: Record<string, string> = {
  active: "status_action_active",
  paused: "status_action_paused",
  churned: "status_action_churned",
};

export function ClientStatusControl({
  clientId,
  status,
  canConvert,
}: {
  clientId: string;
  status: string;
  canConvert: boolean;
}) {
  const t = useTranslations(clientsDict);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  if (!canConvert) return null;

  const nextOptions = CLIENT_STATUS_TRANSITIONS[status] ?? [];
  if (nextOptions.length === 0) return null;

  return (
    <span className="inline-flex items-center gap-2">
      {nextOptions.map((next) => (
        <button
          key={next}
          type="button"
          disabled={isPending}
          onClick={() => {
            setError(null);
            startTransition(async () => {
              const result = await changeClientStatus(clientId, next);
              if (!result.ok) setError(result.error);
            });
          }}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {STATUS_ACTION_KEYS[next] ? t(STATUS_ACTION_KEYS[next]) : next}
        </button>
      ))}
      {error && <span className="text-brand-pink text-xs">{error}</span>}
    </span>
  );
}
