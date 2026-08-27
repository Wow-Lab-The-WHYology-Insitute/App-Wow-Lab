"use client";

import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "./i18n";

// Same reasoning as clients/access-denied.tsx.
export function AccessDenied({ reasonKey }: { reasonKey: string }) {
  const t = useTranslations(groupsDict);
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">{t("access_denied_heading")}</h1>
      <p className="font-body text-muted mt-1 text-sm">{t(reasonKey)}</p>
    </div>
  );
}
