"use client";

import { useTranslations } from "@/lib/i18n";
import { profileDict } from "./i18n";

// Same split as profile-heading.tsx: page.tsx is a Server Component and
// can't call useTranslations() itself.
export function DiagnosticIntro() {
  const t = useTranslations(profileDict);
  return (
    <p className="font-body text-muted mt-1 text-sm">{t("diagnostic_intro")}</p>
  );
}
