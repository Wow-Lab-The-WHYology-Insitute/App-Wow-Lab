"use client";

import { useMemo, useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";
import {
  proposeSessionLessonPlan,
  decideSessionLessonPlan,
  removeSessionLessonPlan,
  updateSessionLessonPlanDelivered,
} from "../actions";

export type CataloguePlan = {
  id: string;
  canonical_title: string;
  plan_ref: string | null;
  status: string;
  what_is_taught: string | null;
  // Every title this plan carries across its module sheets, canonical first.
  titles: string[];
  modules: string[];
};
export type PlanRow = {
  id: string;
  session_id: string;
  trainer_id: string;
  lesson_plan_id: string;
  status: string;
  decision_note: string | null;
  decided_at: string | null;
  decided_by_name: string | null;
  // One-to-many (item 179, B1): a session+trainer can now carry several
  // of these rows, each an independent plan. Pre-checked true -- see
  // 202610300007's own header for why that default is safe: it is only a
  // real assertion once the SESSION ITSELF is confirmed.
  delivered: boolean;
};
export type PlanSession = {
  id: string;
  session_date: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainer_principal_name: string | null;
  trainer_secundar_name: string | null;
};

// Accent- and case-insensitive. Deliberately done here rather than in SQL: the
// catalogue is 288 plans (~60 KB), which is the same reason /payroll fetches
// org-wide and filters client-side, and `unaccent`/`pg_trgm` are not installed
// on this project. String.normalize("NFD") folds diacritics for free, which
// matters because the source mixes "Saptamana"/"Săptămâna" spellings and the
// house convention is to type names without diacritics (item 42).
function fold(v: string): string {
  return v
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();
}

export function SessionPlansSection({
  groupId,
  sessions,
  catalogue,
  rows,
  viewerId,
  canValidate,
}: {
  groupId: string;
  sessions: PlanSession[];
  catalogue: CataloguePlan[];
  rows: PlanRow[];
  viewerId: string;
  canValidate: boolean;
}) {
  const t = useTranslations(groupsDict);

  const planById = useMemo(() => new Map(catalogue.map((p) => [p.id, p])), [catalogue]);
  // One-to-many (item 179, B1): ALL of a session+trainer's plans now,
  // not just the first.
  const rowsFor = (sessionId: string, trainerId: string) =>
    rows.filter((r) => r.session_id === sessionId && r.trainer_id === trainerId);

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("plans_section_title")}
      </h2>

      {sessions.length === 0 ? (
        <p className="text-muted font-body text-sm">{t("plans_empty")}</p>
      ) : (
        <ul className="flex flex-col gap-5">
          {sessions.map((s) => (
            <li key={s.id} className="border-b border-black/5 pb-5 last:border-0 last:pb-0">
              <p className="font-body text-ink mb-3 text-sm font-bold">{s.session_date}</p>
              <div className="flex flex-col gap-3">
                {([
                  ["principal", s.trainer_principal_id, s.trainer_principal_name] as const,
                  ["secundar", s.trainer_secundar_id, s.trainer_secundar_name] as const,
                ]).map(([slot, trainerId, trainerName]) => (
                  <Slot
                    key={slot}
                    groupId={groupId}
                    sessionId={s.id}
                    slotLabel={slot === "principal" ? t("plans_slot_principal") : t("plans_slot_secundar")}
                    trainerId={trainerId}
                    trainerName={trainerName}
                    rows={trainerId ? rowsFor(s.id, trainerId) : []}
                    planById={planById}
                    catalogue={catalogue}
                    isMine={trainerId !== null && trainerId === viewerId}
                    canValidate={canValidate}
                  />
                ))}
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Slot({
  groupId,
  sessionId,
  slotLabel,
  trainerId,
  trainerName,
  rows,
  planById,
  catalogue,
  isMine,
  canValidate,
}: {
  groupId: string;
  sessionId: string;
  slotLabel: string;
  trainerId: string | null;
  trainerName: string | null;
  rows: PlanRow[];
  planById: Map<string, CataloguePlan>;
  catalogue: CataloguePlan[];
  isMine: boolean;
  canValidate: boolean;
}) {
  const t = useTranslations(groupsDict);
  // Picking is shared across the whole slot, not per row -- "add another"
  // is one action for this trainer on this session, same picker either way.
  const [picking, setPicking] = useState(false);
  const [pickError, setPickError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  return (
    <div className="rounded-xl bg-gray-50/70 p-3">
      <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
        <span className="font-body text-muted text-xs font-bold uppercase">{slotLabel}</span>
        <span className="font-body text-ink text-sm">{trainerName ?? t("plans_unassigned")}</span>
      </div>

      {trainerId === null ? null : (
        <div className="mt-2 flex flex-col gap-2">
          {rows.length === 0 ? (
            <p className="font-body text-muted text-sm italic">{t("plans_none_chosen")}</p>
          ) : (
            rows.map((row) => (
              <PlanRowCard
                key={row.id}
                groupId={groupId}
                row={row}
                plan={planById.get(row.lesson_plan_id) ?? null}
                isMine={isMine}
                canValidate={canValidate}
              />
            ))
          )}

          <div className="flex flex-wrap items-center gap-2">
            {isMine && !picking && (
              <button
                type="button"
                onClick={() => setPicking(true)}
                className="text-brand-pink font-body text-xs font-semibold underline"
              >
                {rows.length > 0 ? t("plans_add_another") : t("plans_choose")}
              </button>
            )}
          </div>

          {picking && (
            <PlanPicker
              catalogue={catalogue}
              onCancel={() => setPicking(false)}
              onPick={(planId) => {
                setPickError(null);
                startTransition(async () => {
                  const result = await proposeSessionLessonPlan(groupId, sessionId, planId);
                  if (!result.ok) setPickError(result.error);
                  else setPicking(false);
                });
              }}
            />
          )}

          {pickError && <p className="font-body mt-1 text-xs text-red-600">{pickError}</p>}
          {isPending && <p className="font-body text-muted text-xs italic">{t("plans_saving")}</p>}
        </div>
      )}
    </div>
  );
}

// One proposed/validated plan, with its own decide/note/remove/delivered
// state -- independent of its siblings in the same slot (item 179, B1:
// one session+trainer can carry several of these now).
function PlanRowCard({
  groupId,
  row,
  plan,
  isMine,
  canValidate,
}: {
  groupId: string;
  row: PlanRow;
  plan: CataloguePlan | null;
  isMine: boolean;
  canValidate: boolean;
}) {
  const t = useTranslations(groupsDict);
  const [noting, setNoting] = useState(false);
  const [note, setNote] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const statusLabel =
    row.status === "validated"
      ? t("plans_status_validated")
      : row.status === "changes_requested"
        ? t("plans_status_changes_requested")
        : t("plans_status_proposed");
  const statusTone =
    row.status === "validated"
      ? "bg-emerald-50 text-emerald-700"
      : row.status === "changes_requested"
        ? "bg-amber-50 text-amber-800"
        : "bg-gray-100 text-gray-600";

  function decide(status: "validated" | "changes_requested") {
    setError(null);
    startTransition(async () => {
      const result = await decideSessionLessonPlan(groupId, row.id, status, note);
      if (!result.ok) setError(result.error);
      else {
        setNoting(false);
        setNote("");
      }
    });
  }

  function remove() {
    setError(null);
    startTransition(async () => {
      const result = await removeSessionLessonPlan(groupId, row.id);
      if (!result.ok) setError(result.error);
    });
  }

  function toggleDelivered(checked: boolean) {
    setError(null);
    startTransition(async () => {
      const result = await updateSessionLessonPlanDelivered(groupId, row.id, checked);
      if (!result.ok) setError(result.error);
    });
  }

  return (
    <div className="rounded-lg border border-black/5 bg-white p-2.5">
      <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
        <span className={`font-body rounded-full px-2 py-0.5 text-xs font-semibold ${statusTone}`}>
          {statusLabel}
        </span>
        <p className="font-body text-ink text-sm">
          {plan ? (
            <>
              {plan.canonical_title}
              {plan.status === "planned" && (
                <span className="text-muted ml-2 text-xs italic">({t("plans_not_written_yet")})</span>
              )}
            </>
          ) : (
            <span className="text-muted italic">{t("plans_unknown_plan")}</span>
          )}
        </p>
      </div>

      {row.decision_note && (
        <p className="font-body mt-1 text-xs text-amber-800">
          “{row.decision_note}”
          {row.decided_by_name && (
            <span className="text-muted">
              {" "}
              — {t("plans_decided_by")} {row.decided_by_name}
            </span>
          )}
        </p>
      )}
      {row.status === "proposed" && (
        <p className="text-muted font-body mt-1 text-xs">{t("plans_no_validation_hint")}</p>
      )}

      <div className="mt-2 flex flex-wrap items-center gap-2">
        {isMine && (
          <label className="font-body text-muted flex items-center gap-1.5 text-xs">
            <input
              type="checkbox"
              checked={row.delivered}
              disabled={isPending}
              onChange={(e) => toggleDelivered(e.target.checked)}
              className="accent-brand-pink h-4 w-4"
            />
            {t("plans_delivered_label")}
          </label>
        )}
        {canValidate && !noting && (
          <>
            <button
              type="button"
              disabled={isPending}
              onClick={() => decide("validated")}
              className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
            >
              {isPending ? t("plans_saving") : t("plans_validate")}
            </button>
            <button
              type="button"
              onClick={() => setNoting(true)}
              className="text-muted font-body rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
            >
              {t("plans_request_changes")}
            </button>
          </>
        )}
        {isMine && (
          <button
            type="button"
            disabled={isPending}
            onClick={remove}
            className="text-muted font-body rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
          >
            {t("plans_remove")}
          </button>
        )}
      </div>

      {noting && (
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <input
            type="text"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder={t("plans_note_placeholder")}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 min-w-56 flex-1 rounded-lg border border-gray-300 px-2 py-1 text-sm outline-none focus:ring-2"
          />
          <button
            type="button"
            disabled={isPending}
            onClick={() => decide("changes_requested")}
            className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
          >
            {isPending ? t("plans_saving") : t("plans_request_changes")}
          </button>
          <button
            type="button"
            onClick={() => {
              setNoting(false);
              setNote("");
            }}
            className="text-muted font-body rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
          >
            {t("plans_cancel")}
          </button>
        </div>
      )}

      {error && <p className="font-body mt-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}

// The search Anca asked for. Matches across every title a plan carries, its
// what-is-taught text and its filename -- not only the canonical title, because
// 68 of 286 plans carry more than one and a trainer knows a plan by whichever
// sheet they met it on. When the hit comes from an alternate title, the result
// says so.
function PlanPicker({
  catalogue,
  onPick,
  onCancel,
}: {
  catalogue: CataloguePlan[];
  onPick: (planId: string) => void;
  onCancel: () => void;
}) {
  const t = useTranslations(groupsDict);
  const [query, setQuery] = useState("");

  const haystacks = useMemo(
    () =>
      catalogue.map((p) => ({
        plan: p,
        titles: p.titles.map((title) => ({ title, folded: fold(title) })),
        rest: fold([p.what_is_taught ?? "", p.plan_ref ?? "", p.modules.join(" ")].join(" ")),
      })),
    [catalogue],
  );

  const results = useMemo(() => {
    const q = fold(query.trim());
    if (q.length < 2) return [] as { plan: CataloguePlan; matchedAs: string | null }[];
    const out: { plan: CataloguePlan; matchedAs: string | null }[] = [];
    for (const h of haystacks) {
      const hit = h.titles.find((x) => x.folded.includes(q));
      if (hit) {
        // Only call it a match-as when it is NOT the title already shown.
        out.push({ plan: h.plan, matchedAs: hit.title === h.plan.canonical_title ? null : hit.title });
      } else if (h.rest.includes(q)) {
        out.push({ plan: h.plan, matchedAs: null });
      }
      if (out.length >= 25) break;
    }
    return out;
  }, [haystacks, query]);

  return (
    <div className="mt-2 rounded-xl border border-black/10 bg-white p-3">
      <div className="flex items-center gap-2">
        <input
          autoFocus
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={t("plans_search_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 flex-1 rounded-lg border border-gray-300 px-2 py-1 text-sm outline-none focus:ring-2"
        />
        <button
          type="button"
          onClick={onCancel}
          className="text-muted font-body rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
        >
          {t("plans_cancel")}
        </button>
      </div>

      {query.trim().length >= 2 && results.length === 0 && (
        <p className="text-muted font-body mt-2 text-xs">{t("plans_search_no_match")}</p>
      )}

      <ul className="mt-2 flex max-h-72 flex-col gap-1 overflow-y-auto">
        {results.map(({ plan, matchedAs }) => (
          <li key={plan.id}>
            <button
              type="button"
              onClick={() => onPick(plan.id)}
              className="hover:bg-brand-pink/5 w-full rounded-lg px-2 py-1.5 text-left"
            >
              <span className="font-body text-ink block text-sm">
                {plan.canonical_title}
                {plan.status === "planned" && (
                  <span className="text-muted ml-2 text-xs italic">({t("plans_not_written_yet")})</span>
                )}
              </span>
              <span className="text-muted font-body block text-xs">
                {plan.modules.join(" · ")}
                {matchedAs && (
                  <>
                    {" — "}
                    <span className="italic">
                      {t("plans_matched_as")}: {matchedAs}
                    </span>
                  </>
                )}
              </span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
