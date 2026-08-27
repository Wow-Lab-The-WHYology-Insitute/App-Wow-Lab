"use client";

import { useTranslations } from "@/lib/i18n";
import { profileDict } from "./i18n";
import { chromeDict } from "../i18n";

// Same Server/Client split as profile-heading.tsx and diagnostic-intro.tsx.
// navKeys are chromeDict keys, not display strings -- page.tsx computes
// WHICH sections this session can reach (server-side capability checks),
// this component resolves each key to its already-established nav label
// (chromeDict.nav_clients etc.), rather than page.tsx pushing a second,
// hardcoded copy of strings chromeDict already owns.
export function AccessSummary({
  roleLabel,
  navKeys,
}: {
  roleLabel: string;
  navKeys: string[];
}) {
  const t = useTranslations(profileDict);
  const tChrome = useTranslations(chromeDict);

  return (
    <p className="font-body text-ink text-sm">
      {t("you_are_prefix")}
      <span className="font-semibold">{roleLabel || t("unassigned_role_label")}</span>.{" "}
      {navKeys.length > 0 ? (
        <>
          {t("access_to_prefix")}
          <span className="font-semibold">{navKeys.map((k) => tChrome(k)).join(", ")}</span>.
        </>
      ) : (
        t("no_additional_access")
      )}
    </p>
  );
}
