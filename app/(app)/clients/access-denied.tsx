"use client";

import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "./i18n";

// page.tsx (and [id]/page.tsx) are Server Components -- they can't call
// useTranslations() themselves, since the locale lives only in client-side
// state (localStorage + React Context, see lib/i18n.tsx). This is the
// smallest possible client boundary: a reasonKey in, a translated string
// out, shared between clients/page.tsx and clients/[id]/page.tsx the same
// way clientsDict itself already is.
export function AccessDenied({ reasonKey }: { reasonKey: string }) {
  const t = useTranslations(clientsDict);
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">{t("access_denied_heading")}</h1>
      <p className="font-body text-muted mt-1 text-sm">{t(reasonKey)}</p>
    </div>
  );
}
