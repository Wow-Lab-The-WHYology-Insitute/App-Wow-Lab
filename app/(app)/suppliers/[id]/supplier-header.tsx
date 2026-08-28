"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { suppliersDict } from "../i18n";

// page.tsx is a Server Component and can't call useTranslations() itself --
// same split as client-header.tsx/group-header.tsx/contract-header.tsx.
// status_${x} matches the same template-key convention those files use.
export function SupplierHeader({ name, status }: { name: string; status: string }) {
  const t = useTranslations(suppliersDict);
  return (
    <div>
      <Link href="/suppliers" className="font-body text-muted text-xs hover:underline">
        {t("back_link")}
      </Link>
      <h1 className="font-display text-2xl text-brand-pink">{name}</h1>
      <div className="mt-2 flex flex-wrap items-center gap-1.5">
        <Badge tone={status === "active" ? "neutral" : "pink"}>{t(`status_${status}`)}</Badge>
      </div>
    </div>
  );
}

function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink" ? "bg-brand-pink/10 text-brand-pink" : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
