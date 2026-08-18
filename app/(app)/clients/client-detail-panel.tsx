"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "./i18n";
import { formatDate } from "@/lib/format";

export type ClientDetail = {
  id: string;
  business_line: string | null;
  legal_name: string | null;
  cui: string | null;
  created_at: string;
};

// Scalar fields only, same boundary /contracts' ContractDetailPanel draws:
// the relational content for a client — contacts, contracts (with their
// own masked billing_rule) — lives on /clients/[id], not duplicated into
// this flat expand row. The footer link says exactly that instead of a
// generic "Open client".
export function ClientDetailPanel({
  client,
  locale,
}: {
  client: ClientDetail;
  locale: "en" | "ro";
}) {
  const t = useTranslations(clientsDict);

  return (
    <div className="flex flex-col gap-4">
      <dl
        className="grid gap-x-6 gap-y-3"
        style={{ gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))" }}
      >
        <DetailField label={t("detail_business_line")}>{client.business_line || "—"}</DetailField>
        <DetailField label={t("detail_legal_name")}>{client.legal_name || "—"}</DetailField>
        <DetailField label={t("detail_cui")} mono>
          {client.cui || "—"}
        </DetailField>
        <DetailField label={t("detail_added")}>{formatDate(client.created_at, locale)}</DetailField>
      </dl>

      <div className="flex gap-3 border-t border-black/5 pt-3">
        <Link
          href={`/clients/${client.id}`}
          className="font-body text-ink focus-visible:ring-brand-pink rounded-full border border-black/10 px-4 py-1.5 text-xs font-medium hover:bg-ink/5 focus-visible:ring-2 focus-visible:outline-none"
        >
          {t("open_client")}
        </Link>
      </div>
    </div>
  );
}

function DetailField({
  label,
  children,
  mono,
}: {
  label: string;
  children: React.ReactNode;
  mono?: boolean;
}) {
  return (
    <div>
      <dt className="font-body text-muted text-xs">{label}</dt>
      <dd className={`font-body text-ink mt-0.5 text-sm ${mono ? "font-mono" : ""}`}>{children}</dd>
    </div>
  );
}
