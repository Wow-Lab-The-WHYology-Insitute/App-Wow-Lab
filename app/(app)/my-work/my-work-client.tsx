"use client";

import { useTranslations, useLocale } from "@/lib/i18n";
import { myWorkDict } from "./i18n";

// Client only because useTranslations needs LocaleContext -- same split
// as profile-heading.tsx. No interactivity: every figure is read-only.
export function MyWorkClient({
  hasAnySessions,
  confirmedThisMonth,
  unconfirmedCount,
  monthClosed,
  monthStart,
  groupsAssigned,
  minutesThisMonth,
  sessionsMissingDuration,
  gradeLevel,
}: {
  hasAnySessions: boolean;
  confirmedThisMonth: number;
  unconfirmedCount: number;
  monthClosed: boolean;
  monthStart: string;
  groupsAssigned: number;
  minutesThisMonth: number;
  sessionsMissingDuration: number;
  gradeLevel: number | null;
}) {
  const t = useTranslations(myWorkDict);
  const { locale } = useLocale();

  const monthName = new Date(`${monthStart}T00:00:00Z`).toLocaleDateString(
    locale === "ro" ? "ro-RO" : "en-GB",
    { month: "long", year: "numeric", timeZone: "UTC" },
  );

  const hours = minutesThisMonth / 60;
  // One decimal only when it isn't whole -- "2 h" reads better than
  // "2.0 h", and "1.5 h" must not round to "2 h".
  const hoursLabel = `${Number.isInteger(hours) ? hours : hours.toFixed(1)} h`;

  const gradeName = gradeLevel !== null ? t(`grade_name_${gradeLevel}`) : null;

  return (
    <div className="flex w-full flex-col gap-6">
      <div>
        <h1 className="font-display text-brand-pink text-2xl">{t("page_title")}</h1>
        <p className="font-body text-muted mt-1 text-sm">{t("page_subtitle")}</p>
      </div>

      {/* The one thing on this page with a consequence, so it sits above
          the figures and spans the full width rather than becoming a
          fourth small number. At zero it stays a quiet muted line -- a
          green success banner would celebrate an ordinary state. */}
      {unconfirmedCount > 0 ? (
        <p className="font-body text-ink bg-brand-pink/10 rounded-lg px-4 py-3 text-sm">
          {monthClosed
            ? t("unconfirmed_closed", { count: unconfirmedCount, month: monthName })
            : t("unconfirmed_open", { count: unconfirmedCount, month: monthName })}
        </p>
      ) : (
        hasAnySessions && (
          <p className="font-body text-muted text-sm">{t("unconfirmed_none")}</p>
        )
      )}

      {!hasAnySessions ? (
        // One plain line, not a grid of five zeros: zeros read as a
        // broken page, a sentence reads as a true one. The grade still
        // shows below when set -- it's true regardless of allocation.
        <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
          <p className="font-body text-muted text-sm">{t("nothing_allocated")}</p>
        </section>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Figure label={t("confirmed_this_month")} value={String(confirmedThisMonth)} hint={t("confirmed_hint")} />
          <Figure label={t("groups_assigned")} value={String(groupsAssigned)} />
          <Figure
            label={t("hours_this_month")}
            value={hoursLabel}
            hint={t("hours_caveat")}
            note={
              sessionsMissingDuration > 0
                ? t("hours_incomplete", { count: sessionsMissingDuration })
                : undefined
            }
          />
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <p className="font-body text-muted text-xs font-bold tracking-wide uppercase">
          {t("grade_label")}
        </p>
        {gradeLevel === null ? (
          <p className="font-body text-muted mt-2 text-sm">{t("grade_unset")}</p>
        ) : (
          <div className="mt-2 flex items-baseline gap-2">
            <span className="font-display text-ink text-xl">{gradeName}</span>
            <span className="font-body text-muted text-xs">
              {t("grade_level", { level: gradeLevel })}
            </span>
          </div>
        )}
      </section>
    </div>
  );
}

// The caveat under `hours` is the reason `hint` renders at text-xs rather
// than as a footnote: on a card this small it lands at roughly the same
// visual weight as the number itself, which is the point -- it is not
// fine print, it is part of what the figure means.
function Figure({
  label,
  value,
  hint,
  note,
}: {
  label: string;
  value: string;
  hint?: string;
  note?: string;
}) {
  return (
    <section className="flex flex-col rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <p className="font-body text-muted text-xs font-bold tracking-wide uppercase">{label}</p>
      <p className="font-display text-ink mt-2 text-3xl">{value}</p>
      {hint && <p className="font-body text-muted mt-2 text-xs">{hint}</p>}
      {note && <p className="font-body text-muted mt-1 text-xs italic">{note}</p>}
    </section>
  );
}
