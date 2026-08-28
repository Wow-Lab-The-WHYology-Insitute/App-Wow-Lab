"use client";

import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";

// Same split as group-header.tsx.
export function GroupInfoSection({
  clientName,
  module,
  deliveryFormat,
  schedulePattern,
  ageRange,
  calendarLink,
  childrenConfirmed,
  childrenBilled,
  notes,
}: {
  clientName: string;
  module: string;
  deliveryFormat: string;
  schedulePattern: string | null;
  ageRange: string | null;
  calendarLink: string | null;
  childrenConfirmed: number | null;
  childrenBilled: number | null;
  notes: string | null;
}) {
  const t = useTranslations(groupsDict);
  return (
    <Section title={t("section_group_info_title")}>
      <Kv label={t("col_client")} value={clientName} />
      <Kv label={t("col_module")} value={t(`module_${module}`)} />
      <Kv label={t("kv_delivery_format")} value={t(`format_${deliveryFormat}`)} />
      <Kv label={t("col_schedule")} value={schedulePattern || "—"} />
      <Kv label={t("kv_age_range")} value={ageRange || "—"} />
      <Kv
        label={t("kv_calendar")}
        value={calendarLink ? t("open_link") : "—"}
        href={calendarLink ?? undefined}
        external
      />
      {/* "Confirmed" here is the CONTRACT-TIME headcount (per enrollment,
          at signup) — distinct from each session's own "Present" count
          on GroupDetailClient (who actually showed up to THAT occurrence).
          Two different attendance concepts already existed as separate
          fields -- only the labeling changed here, no new column. */}
      <Kv label={t("kv_children_confirmed")} value={childrenConfirmed?.toString() ?? "—"} />
      <Kv label={t("kv_children_billed")} value={childrenBilled?.toString() ?? "—"} />
      <Kv label={t("kv_notes")} value={notes || "—"} />
    </Section>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

function Kv({
  label,
  value,
  href,
  external,
}: {
  label: string;
  value: string;
  href?: string;
  external?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      {href ? (
        <a
          href={href}
          target={external ? "_blank" : undefined}
          rel={external ? "noreferrer" : undefined}
          className="text-brand-pink font-body font-medium hover:underline"
        >
          {value}
        </a>
      ) : (
        <span className="font-body text-ink font-medium">{value}</span>
      )}
    </div>
  );
}
