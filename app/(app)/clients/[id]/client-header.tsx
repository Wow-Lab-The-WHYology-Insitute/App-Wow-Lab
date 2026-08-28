"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "../i18n";
import { ClientStatusControl } from "./client-status-control";

// page.tsx is a Server Component and can't call useTranslations() itself
// (see components/ui/access-denied.tsx's own comment on this) -- this
// wraps the back-link, heading, and type/status badges, the one piece of
// this page's own markup (not delegated to ClientInfoClient/
// ClientContactsClient) that renders literal copy. client_type_${x}/
// status_${x} match the exact template-key convention clients-client.tsx
// already uses for the same fields, so this detail page's badges read the
// same as the list's.
export function ClientHeader({
  clientId,
  name,
  clientType,
  status,
  canConvert,
}: {
  clientId: string;
  name: string;
  clientType: string;
  status: string;
  canConvert: boolean;
}) {
  const t = useTranslations(clientsDict);
  return (
    <div>
      <Link href="/clients" className="font-body text-muted text-xs hover:underline">
        {t("back_link")}
      </Link>
      <h1 className="font-display text-2xl text-brand-pink">{name}</h1>
      <div className="mt-2 flex flex-wrap items-center gap-1.5">
        <Badge>{t(`client_type_${clientType}`)}</Badge>
        <Badge tone={status === "active" ? "neutral" : "pink"}>{t(`status_${status}`)}</Badge>
        <ClientStatusControl clientId={clientId} status={status} canConvert={canConvert} />
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
