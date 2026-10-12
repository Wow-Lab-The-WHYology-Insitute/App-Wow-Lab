"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { myWorkDict } from "./i18n";
import { markSessionLessonPlanSeen } from "../groups/actions";

export type PlanDecision = {
  rowId: string;
  groupId: string;
  sessionDate: string;
  planTitle: string;
  status: string;
  note: string | null;
};

// The notification Anca asked for: the trainer meets it on entering, and it can
// be marked seen. There is no notifications table -- "unseen" is
// decision_seen_at compared against decided_at on the proposal row itself,
// which already has exactly one addressee (item 117).
//
// Separate component rather than more props on MyWorkClient, which documents
// itself as "no interactivity: every figure is read-only". This part is a
// button, so it does not belong there.
export function PlanDecisionsNotice({ decisions }: { decisions: PlanDecision[] }) {
  const t = useTranslations(myWorkDict);
  const [dismissed, setDismissed] = useState<string[]>([]);
  // `leaving` fades the row out; `dismissed` removes it once the fade is done.
  // Two states rather than one because unmounting in the same render as the
  // opacity change means there is nothing left to fade — the same mistake the
  // expandable row makes with its content (audited, deliberately left alone).
  const [leaving, setLeaving] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const open = decisions.filter((d) => !dismissed.includes(d.rowId));
  if (open.length === 0) return null;

  return (
    <section className="rounded-2xl border border-brand-pink/20 bg-brand-pink/5 p-6 shadow-sm">
      <h2 className="font-body text-brand-pink mb-4 text-xs font-bold tracking-wide uppercase">
        {t("decisions_title")} ({open.length})
      </h2>
      <ul className="flex flex-col gap-3">
        {open.map((d) => (
          <li
            key={d.rowId}
            // The one animation added rather than removed in the 2026-10-12
            // pass, and justified by frequency: a trainer marks a decision seen
            // a handful of times a month, so 150ms of fade is noticed as
            // acknowledgement rather than endured as lag. Everything that
            // happens dozens of times a day in this app stays instant.
            className={`flex flex-wrap items-start justify-between gap-3 motion-safe:transition-opacity motion-safe:duration-[var(--duration-fast)] ${
              leaving.includes(d.rowId) ? "opacity-0" : "opacity-100"
            }`}
          >
            <div className="min-w-0">
              <p className="font-body text-ink text-sm">
                <span className="font-bold">
                  {d.status === "validated" ? t("decisions_validated") : t("decisions_changes_requested")}
                </span>
                {" — "}
                {d.planTitle}
              </p>
              <p className="text-muted font-body text-xs">{d.sessionDate}</p>
              {d.note && <p className="font-body mt-1 text-xs text-amber-800">“{d.note}”</p>}
            </div>
            <div className="flex shrink-0 gap-2">
              <a
                href={`/groups/${d.groupId}`}
                className="text-brand-pink font-body self-center text-xs font-semibold underline"
              >
                {t("decisions_open_group")}
              </a>
              <button
                type="button"
                disabled={isPending}
                onClick={() => {
                  setError(null);
                  startTransition(async () => {
                    const result = await markSessionLessonPlanSeen(d.rowId);
                    if (!result.ok) setError(result.error);
                    // Hidden locally as well as server-side: revalidatePath
                    // refreshes the page data, but the row has to disappear
                    // even if this viewer's cache is stale.
                    else {
                      setLeaving((prev) => [...prev, d.rowId]);
                      setTimeout(
                        () => setDismissed((prev) => [...prev, d.rowId]),
                        150,
                      );
                    }
                  });
                }}
                className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
              >
                {isPending ? t("decisions_marking") : t("decisions_mark_seen")}
              </button>
            </div>
          </li>
        ))}
      </ul>
      {error && <p className="font-body mt-3 text-xs text-red-600">{error}</p>}
    </section>
  );
}
