"use client";

import { useTranslations } from "@/lib/i18n";
import { adminUsersDict } from "./i18n";

// page.tsx is a Server Component and can't call useTranslations() itself --
// same split as client-header.tsx/group-header.tsx/contract-header.tsx/
// supplier-header.tsx.
export function AdminUsersHeader({ orgName, orgSlug }: { orgName: string; orgSlug: string }) {
  const t = useTranslations(adminUsersDict);
  return (
    <div>
      <h1 className="font-display text-2xl text-brand-pink">{t("page_title")}</h1>
      <p className="font-body text-muted mt-1 text-sm">
        {t("org_prefix")}
        <span className="text-ink font-medium">{orgName}</span> ({orgSlug})
      </p>
    </div>
  );
}
