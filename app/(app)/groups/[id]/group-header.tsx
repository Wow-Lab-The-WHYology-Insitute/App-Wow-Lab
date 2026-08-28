"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";

// page.tsx is a Server Component and can't call useTranslations() itself --
// same split as client-header.tsx. module_${x}/format_${x}/status_${x}
// match the exact template-key convention groups-client.tsx already uses
// for the same fields.
export function GroupHeader({
  clientName,
  module,
  deliveryFormat,
  status,
}: {
  clientName: string;
  module: string;
  deliveryFormat: string;
  status: string;
}) {
  const t = useTranslations(groupsDict);
  return (
    <div>
      <Link href="/groups" className="font-body text-muted text-xs hover:underline">
        {t("back_link")}
      </Link>
      <h1 className="font-display text-2xl text-brand-pink">
        {clientName} · {t(`module_${module}`)}
      </h1>
      <div className="mt-2 flex flex-wrap gap-1.5">
        <Badge>{t(`format_${deliveryFormat}`)}</Badge>
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
