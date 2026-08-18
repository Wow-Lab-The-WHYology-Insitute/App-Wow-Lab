"use client";

import { useTranslations } from "@/lib/i18n";
import { profileDict } from "./i18n";

// Split out of page.tsx (a server component) purely because useTranslations
// needs LocaleContext, which requires "use client" — this is the smallest
// possible client boundary for the one string the rename asked to go
// through i18n, not a signal to convert the rest of the page.
export function ProfileHeading() {
  const t = useTranslations(profileDict);
  return <h1 className="font-display text-2xl text-brand-pink">{t("page_title")}</h1>;
}
