"use client";

import { useTranslations, type Dictionary } from "@/lib/i18n";

// Shared by every domain's page.tsx (and [id]/page.tsx) access-fallback --
// page.tsx files are Server Components and can't call useTranslations()
// themselves, since the locale lives only in client-side state (see
// lib/i18n.tsx). This used to be five near-identical per-domain copies
// (clients/contracts/groups/suppliers/admin/users), each pairing this same
// component with the same 3-4 strings inside its own dict. None of that
// varied by domain except the entity noun in the not-found message, and
// the Server/Client boundary already forced a separate file regardless of
// the extraction decision -- so unlike this codebase's usual duplicate-
// per-domain convention, keeping five copies here bought nothing.
const accessDeniedDict: Dictionary = {
  access_denied_heading: { en: "Access denied", ro: "Acces interzis" },
  access_denied_not_signed_in: { en: "Not signed in.", ro: "Nu ești autentificat." },
  access_denied_not_found_client: {
    en: "Client not found, or not visible to your role.",
    ro: "Clientul nu a fost găsit sau nu este vizibil pentru rolul tău.",
  },
  access_denied_not_found_contract: {
    en: "Contract not found, or not visible to your role.",
    ro: "Contractul nu a fost găsit sau nu este vizibil pentru rolul tău.",
  },
  access_denied_not_found_group: {
    en: "Group not found, or not visible to your role.",
    ro: "Grupa nu a fost găsită sau nu este vizibilă pentru rolul tău.",
  },
  access_denied_not_found_supplier: {
    en: "Supplier not found, or not visible to your role.",
    ro: "Furnizorul nu a fost găsit sau nu este vizibil pentru rolul tău.",
  },
  access_denied_no_capability: {
    en: "You don't have org.members.manage in any organization.",
    ro: "Nu deții org.members.manage în nicio organizație.",
  },
  access_denied_no_finance_capability: {
    en: "You don't have finance.operations.* or finance.reporting.* in any organization.",
    ro: "Nu deții finance.operations.* sau finance.reporting.* în nicio organizație.",
  },
};

export function AccessDenied({ reasonKey }: { reasonKey: string }) {
  const t = useTranslations(accessDeniedDict);
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h1 className="font-display text-xl text-brand-pink">{t("access_denied_heading")}</h1>
      <p className="font-body text-muted mt-1 text-sm">{t(reasonKey)}</p>
    </div>
  );
}
