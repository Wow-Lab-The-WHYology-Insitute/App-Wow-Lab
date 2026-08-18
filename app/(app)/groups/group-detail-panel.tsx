"use client";

import Link from "next/link";
import { useTranslations } from "@/lib/i18n";
import { ValueCell } from "@/components/ui/data-table";
import { groupsDict } from "./i18n";

export type GroupDetail = {
  id: string;
  clientLegalName: string | null;
  trainerPrincipalName: string | null;
  trainerSecundarName: string | null;
  children_confirmed: number | null;
  children_billed: number | null;
};

// Scalar fields only, same boundary /contracts' and /clients' detail panels
// draw: the relational content for a group — the Sessions sub-table, plus
// notes/age_range/calendar link this list doesn't even fetch — lives on
// /groups/[id]. The footer link says "View sessions", not a generic "Open
// group", because sessions are specifically what's on the other side.
//
// ValueCell here has no capability/masking dimension (visible is always
// true) — it's used purely for the null-vs-zero distinction: a group with
// 0 confirmed children is a real fact, not "nobody filled this in yet",
// and those two states must not look the same.
export function GroupDetailPanel({ group }: { group: GroupDetail }) {
  const t = useTranslations(groupsDict);

  return (
    <div className="flex flex-col gap-4">
      <dl
        className="grid gap-x-6 gap-y-3"
        style={{ gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))" }}
      >
        <DetailField label={t("detail_legal_name")}>{group.clientLegalName || "—"}</DetailField>
        <DetailField label={t("detail_trainer_principal")}>
          {group.trainerPrincipalName || t("no_trainer")}
        </DetailField>
        <DetailField label={t("detail_trainer_secundar")}>
          {group.trainerSecundarName || t("no_trainer")}
        </DetailField>
        <DetailField label={t("detail_confirmed")}>
          <ValueCell value={group.children_confirmed} visible={true} maskedLabel="" maskedTitle="" />
        </DetailField>
        <DetailField label={t("detail_billed")}>
          <ValueCell value={group.children_billed} visible={true} maskedLabel="" maskedTitle="" />
        </DetailField>
      </dl>

      <div className="flex gap-3 border-t border-black/5 pt-3">
        <Link
          href={`/groups/${group.id}`}
          className="font-body text-ink focus-visible:ring-brand-pink rounded-full border border-black/10 px-4 py-1.5 text-xs font-medium hover:bg-ink/5 focus-visible:ring-2 focus-visible:outline-none"
        >
          {t("open_group")}
        </Link>
      </div>
    </div>
  );
}

function DetailField({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="font-body text-muted text-xs">{label}</dt>
      <dd className="font-body text-ink mt-0.5 text-sm">{children}</dd>
    </div>
  );
}
