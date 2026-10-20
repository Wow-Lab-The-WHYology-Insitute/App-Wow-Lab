"use client";

import { useEffect, useState, useTransition, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useTranslations, useLocale } from "@/lib/i18n";
import { payrollDict } from "./i18n";
import { closePayrollPeriod } from "./actions";
import { PAYROLL_PERIOD_ALREADY_CLOSED_ERROR } from "./close-error";

type Period = { id: string; period: string; closedByName: string };
type SessionSlot = {
  id: string;
  name: string;
  // Whether `name` is a real readable name or the "Unknown" fallback. The
  // sums block groups by `id` and renders the unnamed case through its own
  // label rather than printing "Unknown" as if it were a person (item 122).
  named: boolean;
  confirmed: boolean;
  // Already rounded to 2 decimals in Postgres numeric, carried as integer
  // bani so the totals below are exact integer sums. Null exactly when
  // reasonCode is set.
  bani: number | null;
  reasonCode: string | null;
  errorText: string | null;
};
type Session = {
  id: string;
  sessionDate: string;
  clientName: string;
  // Which of WOW LAB's legal entities invoices this workshop, resolved on
  // the server through group -> contract -> legal_entity. `entityUnlinked`
  // is the broken chain: the group has no contract, so the amount is known
  // and the invoicing entity is not.
  entityId: string | null;
  entityName: string | null;
  entityUnlinked: boolean;
  principal: SessionSlot | null;
  secundar: SessionSlot | null;
};

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

function formatShortDate(iso: string, locale: "en" | "ro") {
  return new Date(iso).toLocaleDateString(locale === "ro" ? "ro-RO" : "en-GB", {
    day: "numeric",
    month: "short",
  });
}

// Integer bani in, two decimals out. The division by 100 is the ONLY
// arithmetic done on a float anywhere in the pay path: the per-row rounding
// happened in Postgres numeric (202610150003), and every total above is an
// integer sum of those rounded rows. Doing it the other way round -- float
// amounts summed in JS -- is what produces 552.4599999999999 for two rows
// of 276.23, and Anca adds these rows up by hand to issue the invoice.
function formatLei(bani: number, locale: "en" | "ro") {
  return new Intl.NumberFormat(locale === "ro" ? "ro-RO" : "en-GB", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(bani / 100);
}

export type UnpriceableReason = { key: string; name?: string };
export type UnpriceableWorkshop = {
  id: string;
  sessionDate: string;
  clientName: string;
  reasons: UnpriceableReason[];
};

export function PayrollClient({
  orgId,
  monthKey,
  periods,
  sessions,
  unpriceable,
  paySumsAvailable,
}: {
  orgId: string;
  // The month on display, "YYYY-MM", resolved on the server from
  // ?month= with the current month as the explicit fallback. Not state
  // here any more: changing it navigates, so a month can be linked to and
  // survives a refresh, and the server can ask the database for one month
  // instead of the whole org.
  monthKey: string;
  periods: Period[];
  sessions: Session[];
  unpriceable: UnpriceableWorkshop[];
  // False when the viewer cannot read the pay grids, or when the call
  // failed. The sums section then does not render at all -- rather than
  // rendering zeroes, which on this screen is a wrong number that becomes
  // a payment.
  paySumsAvailable: boolean;
}) {
  const t = useTranslations(payrollDict);
  const { locale } = useLocale();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const router = useRouter();
  const [isNavigating, startNavigation] = useTransition();
  const [confirming, setConfirming] = useState(false);
  // Same pendingCreate shape the create forms use, extended here: the
  // close action's own promise resolves (isPending ends) a microtask
  // before Next applies the revalidated `periods` prop, so clearing on
  // isPending alone would show the pre-close UI again for a real window
  // while the month isn't reliably closed yet from the UI's own point of
  // view. Cleared only once `periods` actually contains this period.
  const [pendingClose, setPendingClose] = useState<string | null>(null);

  const period = `${monthKey}-01`;
  const alreadyClosed = periods.some((p) => p.period === period);
  const monthLabel = formatPeriodLabel(period, locale);

  useEffect(() => {
    if (!pendingClose) return;
    if (periods.some((p) => p.period === pendingClose)) {
      setPendingClose(null);
      return;
    }
    const timeout = setTimeout(() => setPendingClose(null), 15000);
    return () => clearTimeout(timeout);
  }, [periods, pendingClose]);

  // Every trainer slot for the selected month, flattened from `sessions`
  // (fetched org-wide, once, in page.tsx) -- computed here rather than
  // re-fetched per month change, same reasoning the month <input>'s own
  // plain client state already relies on.
  const monthSlots = useMemo(() => {
    // No month filter here any more: `sessions` arrives already scoped to
    // the displayed month by the server, from the same [from, toExclusive)
    // bounds the pay call used. Filtering again on a prefix match would be
    // a second, weaker definition of "this month" sitting beside the real
    // one -- and the two could disagree.
    const monthSessions = sessions;
    const slots: { session: Session; slot: SessionSlot }[] = [];
    for (const s of monthSessions) {
      if (s.principal) slots.push({ session: s, slot: s.principal });
      if (s.secundar) slots.push({ session: s, slot: s.secundar });
    }
    return { sessionCount: monthSessions.length, slots };
  }, [sessions]);

  const unconfirmedSlots = monthSlots.slots.filter(({ slot }) => !slot.confirmed);

  // Already the month on display -- built on the server from the same
  // month-scoped `sessions` fetch, so no second filter here either.
  const reasonLabel = (r: UnpriceableReason) =>
    r.key === "no_grade" ? t("unpriceable_no_grade", { name: r.name ?? "" }) : t(`unpriceable_${r.key}`);

  // Which reason_codes are a missing FACT somebody can go and enter, and
  // which are a hole in the pay grid that nobody can close from a payroll
  // screen. This is the only new judgement in the consolidation below --
  // everything else is the same data presented once instead of twice.
  const FIXABLE_BY_ENTRY = new Set([
    "no_duration",
    "no_location",
    "no_language",
    "no_trainer",
    "no_grade",
  ]);

  // The raw SQL message is the fallback for an unmapped raise shape only.
  // It names table and column and sometimes a UUID, so it is never the
  // first choice -- but it is always better than silence, and 'unknown'
  // means a resolver's wording changed without this screen being told.
  const payReasonLabel = (reasonCode: string | null, errorText: string | null) => {
    if (!reasonCode) return null;
    if (reasonCode === "unknown") return t("pay_reason_unknown", { message: errorText ?? "" });
    return t(`pay_reason_${reasonCode}`);
  };

  // ---- What each trainer is owed for the month on display ----
  // Grouped by trainer because that is the unit of payment: the timesheet
  // closes at month end and the invoice is issued from it, per trainer
  // (Anca, 2026-09-11). Per workshop alone would leave Anka adding the rows
  // up by hand -- the spreadsheet work this screen replaces -- and a single
  // month total could not be checked against anything.
  //
  // Confirmed and unconfirmed are kept apart and NEVER summed together.
  // Anca's rule is explicit: a trainer who did not confirm is not paid for
  // that workshop. The close prompt already says so
  // (confirm_prompt_with_unconfirmed); one number mixing the two would
  // contradict the sentence on the button directly below it.
  //
  // A slot that raised keeps its row, with its reason, and contributes to
  // neither total -- so one 30-minute scoala_altfel workshop costs its own
  // row and nothing else. The trainer keeps every other workshop's money.
  // Grouped by ENTITY first, then by trainer. Anca's reason, verbatim:
  // "mai ales acum, cand facturam de pe trei entitati diferite, de multe ori
  // trebuie sa specificam ce suma se factureaza de pe fiecare entitate."
  // A trainer issues one invoice PER ENTITY, so (entity, trainer) is the
  // real unit and the entity is the outer heading -- which also makes
  // summing across entities structurally impossible rather than merely
  // discouraged. There is deliberately NO month-wide payable total for the
  // same reason: it is a number nobody invoices.
  const trainerSums = useMemo(() => {
    const byTrainer = new Map<
      string,
      {
        id: string;
        name: string;
        named: boolean;
        entityId: string | null;
        entityName: string | null;
        entityUnlinked: boolean;
        payableBani: number;
        pendingBani: number;
        rows: {
          key: string;
          clientName: string;
          sessionDate: string;
          confirmed: boolean;
          bani: number | null;
          reasonCode: string | null;
          errorText: string | null;
        }[];
      }
    >();

    for (const { session, slot } of monthSlots.slots) {
      const key = `${session.entityId ?? (session.entityUnlinked ? "__unlinked__" : "__unreadable__")}::${slot.id}`;
      let entry = byTrainer.get(key);
      if (!entry) {
        entry = {
          id: slot.id,
          name: slot.name,
          named: slot.named,
          entityId: session.entityId,
          entityName: session.entityName,
          entityUnlinked: session.entityUnlinked,
          payableBani: 0,
          pendingBani: 0,
          rows: [],
        };
        byTrainer.set(key, entry);
      }
      entry.rows.push({
        key: `${session.id}-${slot.id}`,
        clientName: session.clientName,
        sessionDate: session.sessionDate,
        confirmed: slot.confirmed,
        bani: slot.bani,
        reasonCode: slot.reasonCode,
        errorText: slot.errorText,
      });
      if (slot.bani !== null) {
        if (slot.confirmed) entry.payableBani += slot.bani;
        else entry.pendingBani += slot.bani;
      }
    }

    const trainers = [...byTrainer.values()].sort((a, b) =>
      a.name.localeCompare(b.name, locale === "ro" ? "ro-RO" : "en-GB"),
    );
    for (const tr of trainers) {
      tr.rows.sort((a, b) => (a.sessionDate < b.sessionDate ? -1 : a.sessionDate > b.sessionDate ? 1 : 0));
    }

    // Counted by distinct WORKSHOP, not by slot: two unpriceable slots on
    // one workshop are one workshop Anka has to go and look at, and the
    // total's caveat is about workshops.
    const uncalculableSessions = new Set(
      monthSlots.slots.filter(({ slot }) => slot.bani === null).map(({ session }) => session.id),
    );

    // One bucket per entity, each with its own totals. Entities are ordered
    // by name so the list is stable between months; the unattributable
    // bucket sorts last because it is an exception, not an entity.
    const buckets = new Map<
      string,
      { key: string; name: string | null; unlinked: boolean; trainers: typeof trainers; payableBani: number; pendingBani: number }
    >();
    for (const tr of trainers) {
      const key = tr.entityId ?? (tr.entityUnlinked ? "__unlinked__" : "__unreadable__");
      let b = buckets.get(key);
      if (!b) {
        b = { key, name: tr.entityName, unlinked: tr.entityUnlinked, trainers: [], payableBani: 0, pendingBani: 0 };
        buckets.set(key, b);
      }
      b.trainers.push(tr);
      b.payableBani += tr.payableBani;
      b.pendingBani += tr.pendingBani;
    }
    const entities = [...buckets.values()].sort((a, b) => {
      if (a.unlinked !== b.unlinked) return a.unlinked ? 1 : -1;
      return (a.name ?? "").localeCompare(b.name ?? "", locale === "ro" ? "ro-RO" : "en-GB");
    });

    return {
      entities,
      uncalculableCount: uncalculableSessions.size,
    };
  }, [monthSlots, locale]);

  // ---- One block, one number: every workshop that cannot be paid yet ----
  // Two sources genuinely cover different things, which is why this merges
  // rather than picks:
  //   * the calculation's own reason_codes are the superset -- they include
  //     gaps in the pay grid, which item 121's five-question mirror cannot
  //     see and provably missed.
  //   * the mirror sees one thing the calculation cannot: a workshop with
  //     NO trainer in either slot produces no pay rows at all, so there is
  //     no row to carry a reason. Nobody to pay is still a reason not to
  //     close the month.
  // So: the calculation for workshops that have slots, the mirror's
  // no_trainer for workshops that have none -- and the mirror alone when
  // the sums are unavailable, which is exactly the screen item 121 shipped.
  const unpayable = useMemo(() => {
    type Row = { id: string; clientName: string; sessionDate: string; reasons: string[] };

    if (!paySumsAvailable) {
      // Fallback: no grid access, so there are no reason_codes to merge and
      // the mirror is the whole answer. Its five reasons are all
      // fill-in-able by definition, so the second section stays empty.
      return {
        fixable: unpriceable.map((w) => ({
          id: w.id,
          clientName: w.clientName,
          sessionDate: w.sessionDate,
          reasons: w.reasons.map(reasonLabel),
        })),
        notFixableHere: [] as Row[],
        count: unpriceable.length,
      };
    }

    const bySession = new Map<string, { clientName: string; sessionDate: string; codes: Set<string>; labels: string[] }>();
    const note = (session: Session, code: string, label: string) => {
      let e = bySession.get(session.id);
      if (!e) {
        e = { clientName: session.clientName, sessionDate: session.sessionDate, codes: new Set(), labels: [] };
        bySession.set(session.id, e);
      }
      if (e.codes.has(code)) return;
      e.codes.add(code);
      e.labels.push(label);
    };

    for (const { session, slot } of monthSlots.slots) {
      if (slot.bani !== null || !slot.reasonCode) continue;
      note(session, slot.reasonCode, payReasonLabel(slot.reasonCode, slot.errorText) ?? "");
    }

    // The no-trainer case, from the mirror, for workshops the loop above
    // could not have reached because they contributed no slots.
    for (const w of unpriceable) {
      for (const r of w.reasons) {
        if (r.key !== "no_trainer") continue;
        const synthetic: Session = {
          id: w.id,
          sessionDate: w.sessionDate,
          clientName: w.clientName,
          // This path exists only for the no-trainer case, which contributes
          // no slots and so never reaches the per-entity grouping.
          entityId: null,
          entityName: null,
          entityUnlinked: false,
          principal: null,
          secundar: null,
        };
        note(synthetic, "no_trainer", reasonLabel(r));
      }
    }

    const all = [...bySession.entries()]
      .map(([id, e]) => ({
        id,
        clientName: e.clientName,
        sessionDate: e.sessionDate,
        reasons: e.labels,
        // A workshop goes in the second section only if NOTHING about it can
        // be fixed by entering something -- otherwise it belongs where
        // somebody can act on it, with the grid gap listed alongside.
        anyFixable: [...e.codes].some((c) => FIXABLE_BY_ENTRY.has(c)),
      }))
      .sort((a, b) => (a.sessionDate < b.sessionDate ? -1 : a.sessionDate > b.sessionDate ? 1 : 0));

    return {
      fixable: all.filter((w) => w.anyFixable),
      notFixableHere: all.filter((w) => !w.anyFixable),
      count: all.length,
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [monthSlots, unpriceable, paySumsAvailable, locale]);

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
          setPendingClose(period);
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

        {/* Navigation, not state. Changing the month pushes ?month=YYYY-MM
            so the view can be linked and survives a refresh, and so the
            server fetches one month rather than the org's whole history.
            An empty value (the native control allows clearing) is ignored
            rather than pushed -- /payroll with no month is the current
            month, and clearing the field is not a request to go there. */}
        <label className="font-body text-muted flex w-fit flex-col gap-1 text-xs">
          {t("month_label")}
          <input
            type="month"
            value={monthKey}
            onChange={(e) => {
              const next = e.target.value;
              if (!next) return;
              setConfirming(false);
              setError(null);
              startNavigation(() => router.push(`/payroll?month=${next}`));
            }}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
          {/* The month round-trips to the server now, so the wait is real
              and gets said out loud rather than leaving the old month's
              figures on screen looking like the new month's. */}
          {isNavigating && (
            <span className="font-body text-muted text-[11px] normal-case">{t("month_loading")}</span>
          )}
        </label>

        <div className="mt-4">
          {monthSlots.sessionCount === 0 ? (
            <p className="font-body text-muted text-sm">{t("summary_no_sessions", { month: monthLabel })}</p>
          ) : unconfirmedSlots.length === 0 ? (
            <p className="font-body text-muted text-sm">
              {t("summary_all_confirmed", { n: monthSlots.sessionCount, total: monthSlots.slots.length })}
            </p>
          ) : (
            <div className="flex flex-col gap-3 rounded-2xl border border-orange-200 bg-orange-50 px-5 py-4">
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <span className="font-body text-sm font-semibold text-orange-800">
                  {t("summary_unconfirmed_heading", { n: unconfirmedSlots.length, total: monthSlots.slots.length })}
                </span>
                <span className="font-body text-xs text-orange-700">
                  {t("summary_sessions_count", { n: monthSlots.sessionCount })}
                </span>
              </div>
              <div className="flex flex-col gap-1.5 border-t border-orange-200/70 pt-3">
                <span className="font-body text-xs font-bold tracking-wide text-orange-800 uppercase">
                  {t("summary_unconfirmed_list_heading")}
                </span>
                <ul className="flex flex-col gap-1">
                  {unconfirmedSlots.map(({ session, slot }, i) => (
                    <li
                      key={`${session.id}-${i}`}
                      className="font-body flex flex-wrap items-baseline justify-between gap-x-3 text-xs text-orange-900"
                    >
                      <span className="font-semibold">{slot.name}</span>
                      <span className="text-orange-700">
                        {session.clientName} · {formatShortDate(session.sessionDate, locale)}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          )}

          {/* ONE block, ONE number. This replaced two: item 121's five-question
              mirror and the sums total's own "excludes N workshops" line,
              which counted the same month by two different definitions and
              could therefore disagree in front of the person closing it.
              Same data, presented once, split by WHO CAN ACT rather than by
              where the fact happens to live.

              Rendered only when something is missing. There is deliberately
              no "everything can be paid" line: a line that is always there
              becomes a line nobody reads, and this earns attention by being
              absent most of the time. The unconfirmed block above does show
              a positive line, on purpose -- confirmation is something the
              closer is waiting for, while an unpayable workshop is an
              exception. */}
          {unpayable.count > 0 && (
            <div className="mt-3 flex flex-col gap-3 rounded-2xl border border-red-200 bg-red-50 px-5 py-4">
              <span className="font-body text-sm font-semibold text-red-800">
                {t("unpayable_heading", { n: unpayable.count, month: monthLabel })}
              </span>
              <p className="font-body text-xs text-red-700">{t("unpayable_hint")}</p>

              {unpayable.fixable.length > 0 && (
                <div className="flex flex-col gap-1.5 border-t border-red-200/70 pt-3">
                  <span className="font-body text-xs font-bold tracking-wide text-red-800 uppercase">
                    {t("unpayable_section_fixable")}
                  </span>
                  <ul className="flex flex-col gap-2">
                    {unpayable.fixable.map((w) => (
                      <li key={w.id} className="font-body text-xs text-red-900">
                        <span className="font-semibold">
                          {w.clientName} · {formatShortDate(w.sessionDate, locale)}
                        </span>
                        <ul className="mt-0.5 ml-4 list-disc text-red-700">
                          {w.reasons.map((r, i) => (
                            <li key={i}>{r}</li>
                          ))}
                        </ul>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* The second section exists so a grid gap is never filed under
                  "somebody forgot to type something". Nobody can close these
                  from a payroll screen, and saying so is the difference
                  between a task and a dead end. */}
              {unpayable.notFixableHere.length > 0 && (
                <div className="flex flex-col gap-1.5 border-t border-red-200/70 pt-3">
                  <span className="font-body text-xs font-bold tracking-wide text-red-800 uppercase">
                    {t("unpayable_section_not_fixable")}
                  </span>
                  <ul className="flex flex-col gap-2">
                    {unpayable.notFixableHere.map((w) => (
                      <li key={w.id} className="font-body text-xs text-red-900">
                        <span className="font-semibold">
                          {w.clientName} · {formatShortDate(w.sessionDate, locale)}
                        </span>
                        <ul className="mt-0.5 ml-4 list-disc text-red-700">
                          {w.reasons.map((r, i) => (
                            <li key={i}>{r}</li>
                          ))}
                        </ul>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>

        <div className="mt-4 flex flex-wrap items-end gap-3">
          {pendingClose === period ? (
            <p className="font-body text-muted text-sm italic">{t("closing_month", { month: monthLabel })}</p>
          ) : alreadyClosed ? (
            <p className="font-body text-muted text-sm">{t("already_closed_notice", { month: monthLabel })}</p>
          ) : confirming ? (
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-body text-ink text-sm">
                {unconfirmedSlots.length > 0
                  ? t("confirm_prompt_with_unconfirmed", { n: unconfirmedSlots.length, month: monthLabel })
                  : t("confirm_prompt", { month: monthLabel })}
              </span>
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

      {/* ---- The sums, per trainer ---- */}
      {paySumsAvailable && monthSlots.slots.length > 0 && (
        <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
          <h2 className="font-body text-muted mb-1 text-xs font-bold tracking-wide uppercase">
            {t("sums_heading", { month: monthLabel })}
          </h2>
          <p className="font-body text-muted mb-4 text-xs">{t("sums_hint")}</p>

          {/* One section per invoicing entity, each with its own total. There
              is no total across entities on purpose: a trainer bills each
              entity separately, so a combined figure is a number nobody
              invoices and the one most likely to be copied by mistake. */}
          <ul className="flex flex-col gap-6">
            {trainerSums.entities.map((ent) => (
              <li key={ent.key}>
                <div className="mb-3 flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1 border-b border-black/10 pb-2">
                  <span className="font-body text-ink text-sm font-bold">
                    {ent.unlinked
                      ? t("sums_entity_unlinked")
                      : ent.name ?? t("sums_entity_unreadable")}
                  </span>
                  <span className="font-body text-ink text-sm font-bold tabular-nums">
                    {t("sums_amount", { amount: formatLei(ent.payableBani, locale) })}
                  </span>
                </div>
                {/* Said once per entity, because "not payable yet" is a fact
                    about that entity's invoice, not about the month. */}
                {ent.pendingBani > 0 && (
                  <p className="font-body -mt-2 mb-2 text-xs text-orange-700">
                    {t("sums_entity_pending", { amount: formatLei(ent.pendingBani, locale) })}
                  </p>
                )}
                {ent.unlinked && (
                  <p className="font-body -mt-2 mb-2 text-xs text-red-700">{t("sums_entity_unlinked_hint")}</p>
                )}

          <ul className="flex flex-col gap-4">
            {ent.trainers.map((tr) => (
              <li key={tr.id} className="border-b border-black/5 pb-4 last:border-0 last:pb-0">
                <div className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
                  <span className="font-body text-ink text-sm font-semibold">
                    {tr.named ? tr.name : t("sums_trainer_unnamed")}
                  </span>
                  <span className="font-body text-ink text-sm font-bold tabular-nums">
                    {t("sums_amount", { amount: formatLei(tr.payableBani, locale) })}
                  </span>
                </div>

                {/* Stated as its own line, never folded into the figure above:
                    an unconfirmed workshop is not payable, and the close
                    prompt below says exactly that. */}
                {tr.pendingBani > 0 && (
                  <p className="font-body mt-0.5 text-xs text-orange-700">
                    {t("sums_pending", { amount: formatLei(tr.pendingBani, locale) })}
                  </p>
                )}

                <ul className="mt-2 flex flex-col gap-1">
                  {tr.rows.map((row) => (
                    <li
                      key={row.key}
                      className="font-body flex flex-wrap items-baseline justify-between gap-x-3 text-xs"
                    >
                      <span className="text-muted">
                        {row.clientName} · {formatShortDate(row.sessionDate, locale)}
                        {!row.confirmed && (
                          <span className="text-orange-700"> · {t("sums_row_unconfirmed")}</span>
                        )}
                      </span>
                      {row.bani !== null ? (
                        <span className="text-ink tabular-nums">
                          {t("sums_amount", { amount: formatLei(row.bani, locale) })}
                        </span>
                      ) : (
                        <span className="text-right text-red-700">
                          {payReasonLabel(row.reasonCode, row.errorText)}
                        </span>
                      )}
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ul>
              </li>
            ))}
          </ul>

          <div className="mt-5 flex flex-col gap-1 border-t border-black/10 pt-4">
            {/* The caveat now sits under the entity sections rather than under
                a combined total, because there is no combined total any more.
                It still REFERS to the single count in the block above instead
                of carrying one of its own -- one number, named once, pointed
                at from wherever else it matters. */}
            {unpayable.count > 0 && (
              <p className="font-body text-xs text-red-700">
                {t("sums_total_excludes", { n: unpayable.count })}
              </p>
            )}
          </div>
        </section>
      )}

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
