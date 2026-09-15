"use client";

import { useState, useTransition } from "react";
import { useTranslations, useLocale } from "@/lib/i18n";
import { payrollDict } from "./i18n";
import { closePayrollPeriod } from "./actions";
import { PAYROLL_PERIOD_ALREADY_CLOSED_ERROR } from "./close-error";

type Period = { id: string; period: string; closedByName: string };

function currentMonthValue() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

// period is always "YYYY-MM-01" (the CHECK constraint on payroll_periods
// enforces this) -- parsed as local-time y/m/1 rather than through the
// ISO string directly, so the displayed month never shifts a day for a
// timezone west of UTC.
function formatPeriodLabel(period: string, locale: "en" | "ro") {
  const [year, month] = period.split("-").map(Number);
  return new Date(year, month - 1, 1).toLocaleDateString(locale === "ro" ? "ro-RO" : "en-GB", {
    month: "long",
    year: "numeric",
  });
}

export function PayrollClient({ orgId, periods }: { orgId: string; periods: Period[] }) {
  const t = useTranslations(payrollDict);
  const { locale } = useLocale();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [monthValue, setMonthValue] = useState(currentMonthValue());
  const [confirming, setConfirming] = useState(false);

  const period = `${monthValue}-01`;
  const alreadyClosed = periods.some((p) => p.period === period);
  const monthLabel = formatPeriodLabel(period, locale);

  function handleClose() {
    setError(null);
    startTransition(async () => {
      try {
        const result = await closePayrollPeriod(orgId, period);
        if (!result.ok) {
          setError(
            result.error === PAYROLL_PERIOD_ALREADY_CLOSED_ERROR
              ? t("already_closed_error")
              : result.error,
          );
        } else {
          setConfirming(false);
        }
      } catch {
        setError(t("network_error"));
      }
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-2xl text-ink">{t("page_title")}</h1>

      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">{error}</p>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          {t("close_section_heading")}
        </h2>
        <div className="flex flex-wrap items-end gap-3">
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            {t("month_label")}
            <input
              type="month"
              value={monthValue}
              onChange={(e) => {
                setMonthValue(e.target.value);
                setConfirming(false);
                setError(null);
              }}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          </label>

          {alreadyClosed ? (
            <p className="font-body text-muted text-sm">{t("already_closed_notice", { month: monthLabel })}</p>
          ) : confirming ? (
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-body text-ink text-sm">{t("confirm_prompt", { month: monthLabel })}</span>
              <button
                type="button"
                disabled={isPending}
                onClick={handleClose}
                className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-2 text-xs font-bold text-white uppercase disabled:opacity-50"
              >
                {t("confirm_close_button")}
              </button>
              <button
                type="button"
                onClick={() => setConfirming(false)}
                className="font-body text-muted rounded-full border border-black/10 px-4 py-2 text-xs font-semibold uppercase"
              >
                {t("cancel")}
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setConfirming(true)}
              className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
            >
              {t("close_month_button", { month: monthLabel })}
            </button>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          {t("history_heading")}
        </h2>
        {periods.length === 0 ? (
          <p className="font-body text-muted text-sm">{t("history_empty")}</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {periods.map((p) => (
              <li
                key={p.id}
                className="font-body text-ink flex items-center justify-between border-b border-black/5 py-2 text-sm last:border-0"
              >
                <span>{formatPeriodLabel(p.period, locale)}</span>
                <span className="text-muted text-xs">
                  {t("closed_by_prefix")}
                  {p.closedByName}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
