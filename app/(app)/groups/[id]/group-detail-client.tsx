"use client";

import { useEffect, useState, useTransition } from "react";
import { useTranslations, useLocale } from "@/lib/i18n";
import { groupsDict } from "../i18n";
import {
  addSession,
  updateSessionAllocation,
  updateSessionAttendance,
  confirmSessionAttendance,
  correctSessionConfirmation,
} from "../actions";
import {
  SESSION_CONFIRMATION_MONTH_CLOSED_ERROR,
  SESSION_ATTENDANCE_MONTH_CLOSED_ERROR,
  SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR,
  SESSION_CONFIRMATION_FUTURE_ERROR,
} from "../session-write-errors";

type Session = {
  id: string;
  session_date: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainerPrincipalName: string | null;
  trainerSecundarName: string | null;
  status: string;
  attendance_count: number | null;
  experiment_delivered: string | null;
  duration_minutes: number | null;
  experiment_drive_link: string | null;
  trainer_principal_confirmed_at: string | null;
  trainer_secundar_confirmed_at: string | null;
  start_time: string | null;
  location_tier: string | null;
};

// start_time is "HH:MM:SS" (Postgres time, no timezone -- local clock
// time, matching session_date's own plain-date shape). End is derived
// here, never stored (item 52's time-range design: same precedent as
// contract expiry and children_billed) -- null whenever either half is
// missing, not a guess.
function formatTimeRange(startTime: string | null, durationMinutes: number | null): string | null {
  if (!startTime) return null;
  const start = startTime.slice(0, 5);
  if (!durationMinutes) return start;
  const [h, m] = startTime.split(":").map(Number);
  const endTotalMinutes = h * 60 + m + durationMinutes;
  const endH = Math.floor(endTotalMinutes / 60) % 24;
  const endM = endTotalMinutes % 60;
  const end = `${String(endH).padStart(2, "0")}:${String(endM).padStart(2, "0")}`;
  return `${start} – ${end}`;
}
type TrainerOption = { id: string; name: string };

// Matches the sessions.status check constraint (202608160004) exactly —
// 'confirmed' added between planned and delivered (trainer allocated,
// date locked, but not yet run).
const SESSION_STATUS_KEYS: Record<string, string> = {
  planned: "session_status_planned",
  confirmed: "session_status_confirmed",
  delivered: "session_status_delivered",
  cancelled: "session_status_cancelled",
};

// Anca's color scheme for the 4-value status.
const SESSION_STATUS_TONES: Record<string, string> = {
  planned: "bg-orange-100 text-orange-700",
  confirmed: "bg-green-50 text-green-700",
  delivered: "bg-green-700 text-white",
  cancelled: "bg-red-100 text-red-700",
};

// Locale-aware -- takes the same "en" | "ro" shape as lib/format.ts's
// formatDate/formatMoney, kept as its own function (not a call to
// formatDate) because this table's day/month/year format is deliberately
// longer ("15 Aug 2026") than formatDate's compact "15.08.26", not a
// duplicate of it.
function formatShortDate(iso: string, locale: "en" | "ro") {
  return new Date(iso).toLocaleDateString(locale === "ro" ? "ro-RO" : "en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

// Sessions sub-section of the group detail page. Simple ordered list (no
// sortable headers / search+filter) — matches clients/[id]/page.tsx's
// Contacts/Contracts sub-sections, the established "detail-page sub-list"
// convention, distinct from the sortable+searchable top-level /groups and
// /clients list pages.
export function GroupDetailClient({
  groupId,
  organizationId,
  sessions,
  canManageSessions,
  canCorrectConfirmation,
  trainerOptions,
  trainerHomeCities,
  groupAddress,
  viewerId,
  todayIso,
}: {
  groupId: string;
  organizationId: string;
  sessions: Session[];
  canManageSessions: boolean;
  canCorrectConfirmation: boolean;
  trainerOptions: TrainerOption[];
  trainerHomeCities: Record<string, string>;
  groupAddress: string | null;
  viewerId: string;
  todayIso: string;
}) {
  const t = useTranslations(groupsDict);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingSessionId, setEditingSessionId] = useState<string | null>(null);
  const [principalDraft, setPrincipalDraft] = useState<Record<string, string>>({});
  const [secundarDraft, setSecundarDraft] = useState<Record<string, string>>({});
  // Separate edit mode from the reallocate one above -- different
  // audience (the assigned trainer, not Operations), different fields,
  // different RLS branch (202609110003, a row match, not a capability).
  // A row could theoretically be in both edit modes for the rare person
  // who is both Operations and the assigned trainer on the same session.
  const [editingAttendanceId, setEditingAttendanceId] = useState<string | null>(null);
  const [attendanceDraft, setAttendanceDraft] = useState<Record<string, string>>({});
  const [experimentDraft, setExperimentDraft] = useState<Record<string, string>>({});
  // Collapsed by default, both of them. See the ordering block below.
  const [showAllUpcoming, setShowAllUpcoming] = useState(false);
  const [showSettled, setShowSettled] = useState(false);

  // Same pendingCreate shape the create forms use (contracts-client.tsx
  // etc.), extended to two more writes that had the identical dead-zone
  // gap: isPending ends (the action's own promise resolves) a microtask
  // before Next actually applies the revalidated `sessions` prop, so a
  // naive "clear on success" leaves a window where the UI shows stale
  // data with nothing pending-looking about it. Both effects below clear
  // only once the specific field they're watching actually changed to
  // the expected value, with the same 15s ceiling as a safety net, not
  // the real signal.
  const [pendingConfirmation, setPendingConfirmation] = useState<{
    sessionId: string;
    slot: "principal" | "secundar";
    expectedConfirmed: boolean;
  } | null>(null);
  const [pendingAttendance, setPendingAttendance] = useState<{
    sessionId: string;
    expectedAttendanceCount: number | null;
    expectedExperimentDelivered: string | null;
  } | null>(null);

  useEffect(() => {
    if (!pendingConfirmation) return;
    const session = sessions.find((s) => s.id === pendingConfirmation.sessionId);
    const confirmedAt =
      pendingConfirmation.slot === "principal"
        ? session?.trainer_principal_confirmed_at
        : session?.trainer_secundar_confirmed_at;
    if (session && Boolean(confirmedAt) === pendingConfirmation.expectedConfirmed) {
      setPendingConfirmation(null);
      return;
    }
    const timeout = setTimeout(() => setPendingConfirmation(null), 15000);
    return () => clearTimeout(timeout);
  }, [sessions, pendingConfirmation]);

  useEffect(() => {
    if (!pendingAttendance) return;
    const session = sessions.find((s) => s.id === pendingAttendance.sessionId);
    if (
      session &&
      session.attendance_count === pendingAttendance.expectedAttendanceCount &&
      session.experiment_delivered === pendingAttendance.expectedExperimentDelivered
    ) {
      setPendingAttendance(null);
      return;
    }
    const timeout = setTimeout(() => setPendingAttendance(null), 15000);
    return () => clearTimeout(timeout);
  }, [sessions, pendingAttendance]);

  function startEditing(s: Session) {
    setPrincipalDraft((prev) => ({ ...prev, [s.id]: s.trainer_principal_id ?? "" }));
    setSecundarDraft((prev) => ({ ...prev, [s.id]: s.trainer_secundar_id ?? "" }));
    setEditingSessionId(s.id);
  }

  function cancelEditing(s: Session) {
    setPrincipalDraft((prev) => ({ ...prev, [s.id]: s.trainer_principal_id ?? "" }));
    setSecundarDraft((prev) => ({ ...prev, [s.id]: s.trainer_secundar_id ?? "" }));
    setEditingSessionId(null);
  }

  function saveEditing(s: Session) {
    setError(null);
    const principal = principalDraft[s.id] ?? s.trainer_principal_id ?? "";
    const secundar = secundarDraft[s.id] ?? s.trainer_secundar_id ?? "";
    startTransition(async () => {
      try {
        const result = await updateSessionAllocation(groupId, s.id, principal, secundar);
        if (!result.ok) setError(result.error);
        else setEditingSessionId(null);
      } catch {
        setError(t("network_error"));
      }
    });
  }

  function startEditingAttendance(s: Session) {
    setAttendanceDraft((prev) => ({ ...prev, [s.id]: s.attendance_count?.toString() ?? "" }));
    setExperimentDraft((prev) => ({ ...prev, [s.id]: s.experiment_delivered ?? "" }));
    setEditingAttendanceId(s.id);
  }

  function cancelEditingAttendance(s: Session) {
    setAttendanceDraft((prev) => ({ ...prev, [s.id]: s.attendance_count?.toString() ?? "" }));
    setExperimentDraft((prev) => ({ ...prev, [s.id]: s.experiment_delivered ?? "" }));
    setEditingAttendanceId(null);
  }

  function saveEditingAttendance(s: Session) {
    setError(null);
    const attendance = attendanceDraft[s.id] ?? s.attendance_count?.toString() ?? "";
    const experiment = experimentDraft[s.id] ?? s.experiment_delivered ?? "";
    startTransition(async () => {
      try {
        const result = await updateSessionAttendance(groupId, s.id, attendance, experiment);
        if (!result.ok) {
          if (result.error === SESSION_ATTENDANCE_MONTH_CLOSED_ERROR) {
            setError(t("attendance_month_closed_error"));
          } else if (result.error === SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR) {
            setError(t("confirmation_not_assigned_error"));
          } else {
            setError(result.error);
          }
        } else {
          setEditingAttendanceId(null);
          setPendingAttendance({
            sessionId: s.id,
            expectedAttendanceCount: attendance.trim() ? Number(attendance) : null,
            expectedExperimentDelivered: experiment.trim() || null,
          });
        }
      } catch {
        setError(t("network_error"));
      }
    });
  }

  // Instant toggle, no draft/edit-mode state -- a single boolean fires
  // the action directly, same reasoning as any other checkbox. The two
  // sentinel error strings (SESSION_CONFIRMATION_MONTH_CLOSED_ERROR /
  // SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR) are matched here and
  // resolved to the translated (RO/EN) text -- any other string this
  // action could theoretically return falls back to the raw text, same
  // as every other error in this file.
  function toggleConfirmation(s: Session, slot: "principal" | "secundar", confirmed: boolean) {
    setError(null);
    startTransition(async () => {
      try {
        const result = await confirmSessionAttendance(groupId, s.id, confirmed);
        if (!result.ok) {
          if (result.error === SESSION_CONFIRMATION_MONTH_CLOSED_ERROR) {
            setError(t("confirmation_month_closed_error"));
          } else if (result.error === SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR) {
            setError(t("confirmation_not_assigned_error"));
          } else if (result.error === SESSION_CONFIRMATION_FUTURE_ERROR) {
            setError(t("confirmation_future_error"));
          } else {
            setError(result.error);
          }
        } else {
          setPendingConfirmation({ sessionId: s.id, slot, expectedConfirmed: confirmed });
        }
      } catch {
        setError(t("network_error"));
      }
    });
  }

  // Anka's correction path (correctSessionConfirmation) -- unlike
  // toggleConfirmation above, the server can't infer which slot from the
  // caller's own identity (Anka isn't the trainer on the row), so this
  // passes both booleans every call: the slot being corrected gets the
  // new value, the other slot is re-sent unchanged from its current
  // state, matching the action's own "writes both columns every call"
  // contract (groups/actions.ts).
  function toggleCorrection(s: Session, slot: "principal" | "secundar", confirmed: boolean) {
    setError(null);
    const principalConfirmed = slot === "principal" ? confirmed : Boolean(s.trainer_principal_confirmed_at);
    const secundarConfirmed = slot === "secundar" ? confirmed : Boolean(s.trainer_secundar_confirmed_at);
    startTransition(async () => {
      try {
        const result = await correctSessionConfirmation(groupId, s.id, principalConfirmed, secundarConfirmed);
        if (!result.ok) {
          // Operations carries the same future-date guard (202610220001) and
          // reaches it through a different action, so the sentinel has to be
          // matched here too rather than only in toggleConfirmation.
          setError(
            result.error === SESSION_CONFIRMATION_FUTURE_ERROR
              ? t("confirmation_future_error")
              : result.error,
          );
        } else {
          setPendingConfirmation({ sessionId: s.id, slot, expectedConfirmed: confirmed });
        }
      } catch {
        setError(t("network_error"));
      }
    });
  }

  // ==========================================================================
  // ORDERING. The page used to render every session newest-first, which was
  // right while the furthest row was a week out. After 202610200009 generated
  // the school year, a trainer's group page OPENED ON 30 JUNE 2027 and the
  // workshop they had just taught was the 31st card of 35 -- so the sort was
  // burying the only two questions the page is ever opened to answer.
  //
  // Those two questions are "what do I still owe" and "what is next". Four
  // buckets, in that order:
  //
  //   overdue  past, not cancelled, still unconfirmed -- THE DEBT. First
  //            because it is the only bucket with a consequence: pay follows
  //            the confirmation timestamp.
  //   today    confirmable right now. Its own bucket rather than the head of
  //            `upcoming`, because on the day it is a different act.
  //   upcoming ASCENDING -- nearest first. Previewed, not listed: three rows
  //            answers "what is next", and the remaining 27 are a scroll
  //            nobody asked for.
  //   settled  past and done with. Collapsed entirely; it is a record, not a
  //            task.
  //
  // MEASURED FIRST, because reordering alone would not have been enough: the
  // six live groups carry 34-38 sessions each (6-7 past, 27-31 upcoming, 1
  // cancelled), which is ~19 phone screens of cards if all of them render.
  // Collapsing is what makes the page short; the ordering is what makes the
  // top of it right. Not pagination -- every row is already in hand from one
  // query, so a round trip would buy nothing.
  //
  // NOTE: `overdue` is EMPTY in every live group today, and that is the
  // correct result rather than a broken selector -- nothing past is
  // unconfirmed. It is first precisely so that the day it stops being empty,
  // it is the first thing on the screen.
  const needsConfirmation = (s: Session) => {
    if (s.status === "cancelled") return false;
    // The viewer's OWN slot when they hold one -- a co-trainer's missing
    // confirmation is not this trainer's debt. For Operations (no slot), any
    // assigned-but-unconfirmed slot counts, which is their version of the
    // same question.
    if (s.trainer_principal_id === viewerId) return s.trainer_principal_confirmed_at === null;
    if (s.trainer_secundar_id === viewerId) return s.trainer_secundar_confirmed_at === null;
    return (
      (s.trainer_principal_id !== null && s.trainer_principal_confirmed_at === null) ||
      (s.trainer_secundar_id !== null && s.trainer_secundar_confirmed_at === null)
    );
  };

  const byDateAsc = (a: Session, b: Session) => a.session_date.localeCompare(b.session_date);
  const byDateDesc = (a: Session, b: Session) => b.session_date.localeCompare(a.session_date);

  const buckets = {
    overdue: sessions.filter((s) => s.session_date < todayIso && needsConfirmation(s)).sort(byDateAsc),
    today: sessions.filter((s) => s.session_date === todayIso).sort(byDateAsc),
    upcoming: sessions.filter((s) => s.session_date > todayIso).sort(byDateAsc),
    settled: sessions.filter((s) => s.session_date < todayIso && !needsConfirmation(s)).sort(byDateDesc),
  };

  // One place that builds a row and one that builds a card, so the twenty-odd
  // props below are written once instead of once per bucket.
  const rowProps = (s: Session) => ({
    session: s,
    editing: editingSessionId === s.id,
    canManageSessions,
    canCorrectConfirmation,
    canEditAttendance: s.trainer_principal_id === viewerId || s.trainer_secundar_id === viewerId,
    editingAttendance: editingAttendanceId === s.id,
    isPending,
    isSavingAttendance: pendingAttendance?.sessionId === s.id,
    savingConfirmationSlot:
      pendingConfirmation?.sessionId === s.id ? pendingConfirmation.slot : null,
    trainerOptions,
    viewerId,
    isFuture: s.session_date > todayIso,
    principalValue: principalDraft[s.id] ?? s.trainer_principal_id ?? "",
    secundarValue: secundarDraft[s.id] ?? s.trainer_secundar_id ?? "",
    attendanceValue: attendanceDraft[s.id] ?? s.attendance_count?.toString() ?? "",
    experimentValue: experimentDraft[s.id] ?? s.experiment_delivered ?? "",
    onChangePrincipal: (v: string) => setPrincipalDraft((prev) => ({ ...prev, [s.id]: v })),
    onChangeSecundar: (v: string) => setSecundarDraft((prev) => ({ ...prev, [s.id]: v })),
    onChangeAttendance: (v: string) => setAttendanceDraft((prev) => ({ ...prev, [s.id]: v })),
    onChangeExperiment: (v: string) => setExperimentDraft((prev) => ({ ...prev, [s.id]: v })),
    onStartEditing: () => startEditing(s),
    onCancelEditing: () => cancelEditing(s),
    onSave: () => saveEditing(s),
    onStartEditingAttendance: () => startEditingAttendance(s),
    onCancelEditingAttendance: () => cancelEditingAttendance(s),
    onSaveAttendance: () => saveEditingAttendance(s),
    onToggleConfirmation: (slot: "principal" | "secundar", checked: boolean) =>
      toggleConfirmation(s, slot, checked),
    onCorrectConfirmation: (slot: "principal" | "secundar", checked: boolean) =>
      toggleCorrection(s, slot, checked),
  });
  const renderRow = (s: Session) => <SessionTableRow key={s.id} {...rowProps(s)} />;
  const renderCard = (s: Session) => <SessionCard key={s.id} {...rowProps(s)} />;

  return (
    <div className="flex flex-col gap-4">
      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {/* sessions.create capability gate — same relationship as
          groups-client.tsx's createOrgId, RLS is the real gate. */}
      {canManageSessions && (
        <div className="flex flex-col gap-4">
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
          >
            {t("new_session_button")}
          </button>
          {isFormOpen && (
            <NewSessionForm
              trainerOptions={trainerOptions}
              trainerHomeCities={trainerHomeCities}
              groupAddress={groupAddress}
              isPending={isPending}
              onSubmit={(date, principalId, secundarId, status, attendance, experiment, duration, experimentDriveLink, startTime, locationTier) => {
                setError(null);
                startTransition(async () => {
                  try {
                    const result = await addSession(
                      organizationId,
                      groupId,
                      date,
                      principalId,
                      secundarId,
                      status,
                      attendance,
                      experiment,
                      duration,
                      experimentDriveLink,
                      startTime,
                      locationTier,
                    );
                    if (!result.ok) setError(result.error);
                    else setIsFormOpen(false);
                  } catch {
                    setError(t("network_error"));
                  }
                });
              }}
            />
          )}
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          {t("sessions_heading", { count: sessions.length })}
        </h2>

        {sessions.length === 0 ? (
          <p className="font-body text-muted text-sm">
            {canManageSessions
              ? t("empty_no_sessions")
              : t("empty_no_sessions_trainer")}
          </p>
        ) : (
          <div className="flex flex-col gap-6">
            {buckets.overdue.length > 0 && (
              <Bucket
                title={t("bucket_overdue", { count: buckets.overdue.length })}
                hint={t("bucket_overdue_hint")}
                tone="debt"
                sessions={buckets.overdue}
                renderRow={renderRow}
                renderCard={renderCard}
              />
            )}

            {buckets.today.length > 0 && (
              <Bucket
                title={t("bucket_today", { count: buckets.today.length })}
                tone="today"
                sessions={buckets.today}
                renderRow={renderRow}
                renderCard={renderCard}
              />
            )}

            {buckets.upcoming.length > 0 && (
              <Bucket
                title={t("bucket_upcoming", { count: buckets.upcoming.length })}
                sessions={showAllUpcoming ? buckets.upcoming : buckets.upcoming.slice(0, UPCOMING_PREVIEW)}
                renderRow={renderRow}
                renderCard={renderCard}
                footer={
                  buckets.upcoming.length > UPCOMING_PREVIEW ? (
                    <DisclosureButton
                      onClick={() => setShowAllUpcoming((v) => !v)}
                      label={
                        showAllUpcoming
                          ? t("bucket_upcoming_collapse")
                          : t("bucket_upcoming_expand", {
                              count: buckets.upcoming.length - UPCOMING_PREVIEW,
                            })
                      }
                    />
                  ) : undefined
                }
              />
            )}

            {buckets.settled.length > 0 && (
              <Bucket
                title={t("bucket_settled", { count: buckets.settled.length })}
                sessions={showSettled ? buckets.settled : []}
                renderRow={renderRow}
                renderCard={renderCard}
                footer={
                  <DisclosureButton
                    onClick={() => setShowSettled((v) => !v)}
                    label={
                      showSettled
                        ? t("bucket_settled_collapse")
                        : t("bucket_settled_expand", { count: buckets.settled.length })
                    }
                  />
                }
              />
            )}
          </div>
        )}
      </section>
    </div>
  );
}

// Three rows of "what is next" -- enough to answer the question, short enough
// that the bucket below it is still on the screen. Four groups out of six have
// a second workshop the same afternoon, so a preview of 2 would cut a pair in
// half and a preview of 3 never does.
const UPCOMING_PREVIEW = 3;

// One bucket: a heading, the desktop table, the mobile cards, an optional
// disclosure under it. The table/cards split is the one the page already had
// -- `hidden md:table` and `md:hidden` -- lifted in here so every bucket gets
// both without repeating the pair four times.
function Bucket({
  title,
  hint,
  tone,
  sessions,
  renderRow,
  renderCard,
  footer,
}: {
  title: string;
  hint?: string;
  tone?: "debt" | "today";
  sessions: Session[];
  renderRow: (s: Session) => React.ReactNode;
  renderCard: (s: Session) => React.ReactNode;
  footer?: React.ReactNode;
}) {
  const t = useTranslations(groupsDict);
  return (
    <div>
      <h3
        className={`font-body text-xs font-bold tracking-wide uppercase ${
          tone === "debt" ? "text-brand-pink" : tone === "today" ? "text-ink" : "text-muted"
        }`}
      >
        {title}
      </h3>
      {hint && <p className="font-body text-muted mt-0.5 text-xs">{hint}</p>}

      {sessions.length > 0 && (
        <>
          <table className="mt-3 hidden w-full border-collapse text-sm md:table">
            {/* Repeated per bucket rather than once above all four: the
                buckets are separate tables now, and a header row that
                scrolled away four sections ago is not a header. */}
            <thead>
              <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                <th className="py-2 pr-4 font-bold">{t("col_date")}</th>
                <th className="py-2 pr-4 font-bold">{t("col_principal")}</th>
                <th className="py-2 pr-4 font-bold">{t("col_secundar")}</th>
                <th className="py-2 pr-4 font-bold">{t("col_status")}</th>
                <th className="py-2 pr-4 font-bold">{t("col_duration")}</th>
                <th className="py-2 pr-4 font-bold">{t("col_location")}</th>
                {/* "Present" (not "Attendance") — the post-workshop ACTUAL
                    headcount for this occurrence, distinct from the group's
                    own "Children confirmed" (contract-time headcount, shown
                    on Group info above). Same field, relabeled per Anca's
                    request — investigated, no new column needed. */}
                <th className="py-2 pr-4 font-bold">{t("col_present")}</th>
                <th className="py-2 font-bold">{t("col_experiment_delivered")}</th>
              </tr>
            </thead>
            <tbody>{sessions.map(renderRow)}</tbody>
          </table>
          <div className="mt-3 flex flex-col gap-3 md:hidden">{sessions.map(renderCard)}</div>
        </>
      )}

      {footer}
    </div>
  );
}

// 44px tall, which is the floor for a target a thumb has to hit (Apple's HIG
// says 44pt, Material says 48dp). Everything on this page that a trainer
// taps now clears it; see ConfirmationControl for the one that did not.
function DisclosureButton({ onClick, label }: { onClick: () => void; label: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="font-body text-muted mt-3 flex min-h-11 w-full items-center justify-center rounded-full border border-black/10 px-4 text-xs font-semibold uppercase"
    >
      {label}
    </button>
  );
}

type SessionRowProps = {
  session: Session;
  editing: boolean;
  canManageSessions: boolean;
  canCorrectConfirmation: boolean;
  canEditAttendance: boolean;
  editingAttendance: boolean;
  isPending: boolean;
  isSavingAttendance: boolean;
  savingConfirmationSlot: "principal" | "secundar" | null;
  trainerOptions: TrainerOption[];
  viewerId: string;
  // Resolved on the server (page.tsx's todayIso) and threaded down, never
  // computed from new Date() in here -- see the prop's comment there.
  isFuture: boolean;
  principalValue: string;
  secundarValue: string;
  attendanceValue: string;
  experimentValue: string;
  onChangePrincipal: (v: string) => void;
  onChangeSecundar: (v: string) => void;
  onChangeAttendance: (v: string) => void;
  onChangeExperiment: (v: string) => void;
  onStartEditing: () => void;
  onCancelEditing: () => void;
  onSave: () => void;
  onStartEditingAttendance: () => void;
  onCancelEditingAttendance: () => void;
  onSaveAttendance: () => void;
  onToggleConfirmation: (slot: "principal" | "secundar", checked: boolean) => void;
  onCorrectConfirmation: (slot: "principal" | "secundar", checked: boolean) => void;
};

// Beside each trainer's own name. Five render shapes, not three --
// state and action used to share one widget (a checkbox whose CHECKED
// attribute mirrored the state while its LABEL TEXT also swapped between
// "Confirmed"/"Not confirmed" -- an empty box next to "Not confirmed"
// reads as ambiguous: is checking it the action, or is the box itself
// asserting "not confirmed" is already true?). Now state and action are
// never both live in the same rendering: a checkbox never appears next
// to text that names the state it's already in.
//
// Checked in this order (same precedence as before -- a viewer who is
// both the assigned trainer AND finance-capable on the same session
// must hit their own-slot case first, or they could bypass their own
// close-gate restriction through their own correction capability):
//   1. Saving -- transient, covers the dead-zone gap where isPending
//      ends before the revalidated `sessions` prop actually lands, so
//      nothing here ever flashes a stale checked/unchecked value.
//   2. Own slot, already confirmed -- a plain label, not a control
//      anymore. Confirming your own delivery is a one-way action; a
//      mistake is fixed through the correction path below (finance/
//      owner), not by self-unchecking, so there is nothing left to
//      offer here once it's done.
//   3. Own slot, not yet confirmed -- the one real action this shape
//      offers, worded as an action ("Check to confirm"), not as a
//      state, so an empty box never sits next to a claim about what's
//      already true.
//   4. Correction (canCorrect, not the assigned trainer) -- genuinely
//      bidirectional, fixing a wrong confirmation either way is the
//      whole point, so this never collapses to a label. The checkbox's
//      own checked/unchecked state carries the boolean; the text beside
//      it stays the constant "Confirmed" (what's being toggled) instead
//      of swapping to "Not confirmed", which is what made the box and
//      the words redundant-but-conflicting in the old shape.
//   5. Read-only (neither of the above) -- a plain state label, always,
//      confirmed or not. Deliberately visible either way: the state
//      isn't private between the two trainers on a session, only the
//      control is.
function ConfirmationControl({
  confirmedAt,
  isOwnSlot,
  canCorrect,
  isFuture,
  isPending,
  isSaving,
  onToggle,
  onCorrect,
}: {
  confirmedAt: string | null;
  isOwnSlot: boolean;
  canCorrect: boolean;
  isFuture: boolean;
  isPending: boolean;
  isSaving: boolean;
  onToggle: (checked: boolean) => void;
  onCorrect: (checked: boolean) => void;
}) {
  const t = useTranslations(groupsDict);
  const confirmed = Boolean(confirmedAt);

  if (isSaving) {
    return <span className="font-body text-muted mt-1 block text-xs italic">{t("saving_confirmation")}</span>;
  }

  // ---- The trainer's own slot ----------------------------------------------
  if (isOwnSlot) {
    // Not yet confirmable. A disabled button would be a target that teaches
    // nothing on being tapped; a sentence says what to do instead, and it is
    // the SAME fact 202610220001's guard enforces -- the screen and the
    // database refusing for one reason rather than two.
    if (!confirmed && isFuture) {
      return (
        <p className="font-body text-muted mt-1 text-xs">{t("confirmation_not_yet")}</p>
      );
    }

    if (!confirmed) {
      // A BUTTON, not an 11px checkbox. min-h-11 is 44px, the floor for a
      // thumb target (Apple HIG 44pt / Material 48dp); the old control was a
      // 13px box next to text-[11px] type and was never a button in any sense
      // except that tapping it wrote to the database.
      return (
        <button
          type="button"
          disabled={isPending}
          onClick={() => onToggle(true)}
          className="font-body mt-1.5 flex min-h-11 w-full items-center justify-center rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 text-xs font-bold text-white uppercase disabled:opacity-50"
        >
          {t("confirmation_confirm_button")}
        </button>
      );
    }

    // Confirmed, and now undoable from the screen. The RPC has always
    // accepted p_confirmed = false; only the UI never offered it, so a
    // mis-tap meant asking Operations. Clearing is never date-guarded
    // (202610220001), so this works on a future row too -- which is exactly
    // the row most likely to have been tapped by accident.
    return (
      <div className="mt-1.5 flex items-center justify-between gap-2">
        <span className="font-body text-ink text-xs font-semibold">
          {t("session_confirmed_status")}
        </span>
        <button
          type="button"
          disabled={isPending}
          onClick={() => onToggle(false)}
          className="font-body text-muted flex min-h-11 items-center rounded-full border border-black/10 px-4 text-xs font-semibold uppercase disabled:opacity-50"
        >
          {t("confirmation_undo_button")}
        </button>
      </div>
    );
  }

  // ---- Operations' correction path -----------------------------------------
  // Still a checkbox: this is a two-state field somebody sets deliberately on
  // behalf of another person, not a one-way act, and Operations is on a
  // desktop. It gets the 44px row anyway -- the label is the target.
  if (canCorrect) {
    return (
      <label className="font-body text-muted mt-1 flex min-h-11 items-center gap-2 text-xs">
        <input
          type="checkbox"
          checked={confirmed}
          disabled={isPending}
          onChange={(e) => onCorrect(e.target.checked)}
          className="accent-brand-pink h-5 w-5"
        />
        {t("session_confirmed_status")}
      </label>
    );
  }

  // ---- Everyone else: read-only --------------------------------------------
  return (
    <span className="font-body text-muted block text-xs">
      {confirmed ? t("session_confirmed_status") : t("session_not_confirmed_status")}
    </span>
  );
}

// Inline reallocate — the "rotation" case (task spec): only
// trainer_principal_id/trainer_secundar_id are editable here, matching
// admin-users-client.tsx's MemberTableRow edit/Save/Cancel pattern. Not
// rendered at all for a Trainer/Senior Trainer viewer — read-only for them
// by design, not just visually disabled.
function SessionTableRow({
  session,
  editing,
  canManageSessions,
  canCorrectConfirmation,
  canEditAttendance,
  editingAttendance,
  isPending,
  isSavingAttendance,
  savingConfirmationSlot,
  trainerOptions,
  viewerId,
  isFuture,
  principalValue,
  secundarValue,
  attendanceValue,
  experimentValue,
  onChangePrincipal,
  onChangeSecundar,
  onChangeAttendance,
  onChangeExperiment,
  onStartEditing,
  onCancelEditing,
  onSave,
  onStartEditingAttendance,
  onCancelEditingAttendance,
  onSaveAttendance,
  onToggleConfirmation,
  onCorrectConfirmation,
}: SessionRowProps) {
  const t = useTranslations(groupsDict);
  const { locale } = useLocale();
  return (
    <tr className="font-body text-ink border-b border-black/5 align-top last:border-0">
      <td className="py-3 pr-4 text-xs whitespace-nowrap">
        {formatShortDate(session.session_date, locale)}
        <span className="text-muted block">
          {formatTimeRange(session.start_time, session.duration_minutes) ?? "—"}
        </span>
      </td>
      {editing ? (
        <>
          <td className="py-3 pr-4">
            <TrainerSelect
              value={principalValue}
              options={trainerOptions}
              onChange={onChangePrincipal}
            />
          </td>
          <td className="py-3 pr-4">
            <TrainerSelect
              value={secundarValue}
              options={trainerOptions}
              onChange={onChangeSecundar}
            />
          </td>
        </>
      ) : (
        <>
          <td className="py-3 pr-4">
            {session.trainerPrincipalName || "—"}
            {session.trainer_principal_id && (
              <ConfirmationControl
                confirmedAt={session.trainer_principal_confirmed_at}
                isOwnSlot={session.trainer_principal_id === viewerId}
                canCorrect={canCorrectConfirmation}
                isFuture={isFuture}
                isPending={isPending}
                isSaving={savingConfirmationSlot === "principal"}
                onToggle={(checked) => onToggleConfirmation("principal", checked)}
                onCorrect={(checked) => onCorrectConfirmation("principal", checked)}
              />
            )}
          </td>
          <td className="py-3 pr-4">
            {session.trainerSecundarName || "—"}
            {session.trainer_secundar_id && (
              <ConfirmationControl
                confirmedAt={session.trainer_secundar_confirmed_at}
                isOwnSlot={session.trainer_secundar_id === viewerId}
                canCorrect={canCorrectConfirmation}
                isFuture={isFuture}
                isPending={isPending}
                isSaving={savingConfirmationSlot === "secundar"}
                onToggle={(checked) => onToggleConfirmation("secundar", checked)}
                onCorrect={(checked) => onCorrectConfirmation("secundar", checked)}
              />
            )}
          </td>
        </>
      )}
      <td className="py-3 pr-4">
        <Badge tone={SESSION_STATUS_TONES[session.status]}>
          {SESSION_STATUS_KEYS[session.status] ? t(SESSION_STATUS_KEYS[session.status]) : session.status}
        </Badge>
      </td>
      <td className="text-muted py-3 pr-4">
        {session.duration_minutes ? `${session.duration_minutes} min` : "—"}
      </td>
      <td className="text-muted py-3 pr-4">
        {session.location_tier ? t(`location_tier_${session.location_tier}`) : "—"}
      </td>
      <td className="text-muted py-3 pr-4">
        {editingAttendance ? (
          <input
            type="number"
            min="0"
            value={attendanceValue}
            onChange={(e) => onChangeAttendance(e.target.value)}
            placeholder={t("attendance_placeholder")}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 w-20 rounded-lg border border-gray-300 px-2 py-1 text-sm outline-none focus:ring-2"
          />
        ) : isSavingAttendance ? (
          <span className="italic">{t("saving_attendance")}</span>
        ) : (
          (session.attendance_count ?? "—")
        )}
      </td>
      <td className="text-muted py-3">
        <div className="flex items-center justify-between gap-3">
          {editingAttendance ? (
            <input
              type="text"
              value={experimentValue}
              onChange={(e) => onChangeExperiment(e.target.value)}
              placeholder={t("experiment_placeholder")}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 w-full rounded-lg border border-gray-300 px-2 py-1 text-sm outline-none focus:ring-2"
            />
          ) : isSavingAttendance ? (
            <span className="italic">{t("saving_attendance")}</span>
          ) : (
            <span>
              {session.experiment_delivered || "—"}
              {session.experiment_drive_link && (
                <a
                  href={session.experiment_drive_link}
                  target="_blank"
                  rel="noreferrer"
                  className="text-brand-pink ml-2 text-xs font-semibold hover:underline"
                >
                  {t("open_action")}
                </a>
              )}
            </span>
          )}
          <span className="flex shrink-0 gap-2">
            {canManageSessions &&
              (editing ? (
                <>
                  <button
                    type="button"
                    disabled={isPending}
                    onClick={onSave}
                    className="rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
                  >
                    {t("save")}
                  </button>
                  <button
                    type="button"
                    onClick={onCancelEditing}
                    className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
                  >
                    {t("cancel")}
                  </button>
                </>
              ) : (
                <button
                  type="button"
                  onClick={onStartEditing}
                  className="text-brand-pink shrink-0 text-xs font-semibold underline"
                >
                  {t("reallocate_action")}
                </button>
              ))}
            {canEditAttendance &&
              !isSavingAttendance &&
              (editingAttendance ? (
                <>
                  <button
                    type="button"
                    disabled={isPending}
                    onClick={onSaveAttendance}
                    className="rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
                  >
                    {t("save")}
                  </button>
                  <button
                    type="button"
                    onClick={onCancelEditingAttendance}
                    className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
                  >
                    {t("cancel")}
                  </button>
                </>
              ) : (
                <button
                  type="button"
                  onClick={onStartEditingAttendance}
                  className="text-brand-pink shrink-0 text-xs font-semibold underline"
                >
                  {t("record_attendance_action")}
                </button>
              ))}
          </span>
        </div>
      </td>
    </tr>
  );
}

function SessionCard({
  session,
  editing,
  canManageSessions,
  canCorrectConfirmation,
  canEditAttendance,
  editingAttendance,
  isPending,
  isSavingAttendance,
  savingConfirmationSlot,
  trainerOptions,
  viewerId,
  isFuture,
  principalValue,
  secundarValue,
  attendanceValue,
  experimentValue,
  onChangePrincipal,
  onChangeSecundar,
  onChangeAttendance,
  onChangeExperiment,
  onStartEditing,
  onCancelEditing,
  onSave,
  onStartEditingAttendance,
  onCancelEditingAttendance,
  onSaveAttendance,
  onToggleConfirmation,
  onCorrectConfirmation,
}: SessionRowProps) {
  const t = useTranslations(groupsDict);
  const { locale } = useLocale();
  return (
    <div className="rounded-xl border border-black/5 p-4">
      <div className="flex items-center justify-between">
        <p className="font-body text-ink text-sm font-semibold">
          {formatShortDate(session.session_date, locale)}
          <span className="text-muted ml-1.5 text-xs font-normal">
            {formatTimeRange(session.start_time, session.duration_minutes) ?? "—"}
          </span>
        </p>
        <Badge tone={SESSION_STATUS_TONES[session.status]}>
          {SESSION_STATUS_KEYS[session.status] ? t(SESSION_STATUS_KEYS[session.status]) : session.status}
        </Badge>
      </div>

      {editing ? (
        <div className="mt-3 flex flex-col gap-2">
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            {t("col_principal")}
            <TrainerSelect value={principalValue} options={trainerOptions} onChange={onChangePrincipal} />
          </label>
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            {t("col_secundar")}
            <TrainerSelect value={secundarValue} options={trainerOptions} onChange={onChangeSecundar} />
          </label>
          <div className="mt-1 flex gap-2">
            <button
              type="button"
              disabled={isPending}
              onClick={onSave}
              className="flex-1 rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-2 text-xs font-bold text-white uppercase disabled:opacity-50"
            >
              {t("save")}
            </button>
            <button
              type="button"
              onClick={onCancelEditing}
              className="text-muted flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              {t("cancel")}
            </button>
          </div>
        </div>
      ) : editingAttendance ? (
        <div className="mt-3 flex flex-col gap-2">
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            {t("col_present")}
            <input
              type="number"
              min="0"
              value={attendanceValue}
              onChange={(e) => onChangeAttendance(e.target.value)}
              placeholder={t("attendance_placeholder")}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-2 py-1.5 text-xs outline-none focus:ring-2"
            />
          </label>
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            {t("col_experiment_delivered")}
            <input
              type="text"
              value={experimentValue}
              onChange={(e) => onChangeExperiment(e.target.value)}
              placeholder={t("experiment_placeholder")}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-2 py-1.5 text-xs outline-none focus:ring-2"
            />
          </label>
          <div className="mt-1 flex gap-2">
            <button
              type="button"
              disabled={isPending}
              onClick={onSaveAttendance}
              className="flex-1 rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-2 text-xs font-bold text-white uppercase disabled:opacity-50"
            >
              {t("save")}
            </button>
            <button
              type="button"
              onClick={onCancelEditingAttendance}
              className="text-muted flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              {t("cancel")}
            </button>
          </div>
        </div>
      ) : (
        <>
          <p className="font-body text-muted mt-2 text-xs">
            {t("mobile_principal_prefix")}{session.trainerPrincipalName || "—"}
          </p>
          {session.trainer_principal_id && (
            <ConfirmationControl
              confirmedAt={session.trainer_principal_confirmed_at}
              isOwnSlot={session.trainer_principal_id === viewerId}
              canCorrect={canCorrectConfirmation}
              isFuture={isFuture}
              isPending={isPending}
              isSaving={savingConfirmationSlot === "principal"}
              onToggle={(checked) => onToggleConfirmation("principal", checked)}
              onCorrect={(checked) => onCorrectConfirmation("principal", checked)}
            />
          )}
          <p className="font-body text-muted mt-1 text-xs">
            {t("mobile_secundar_prefix")}{session.trainerSecundarName || "—"}
          </p>
          {session.trainer_secundar_id && (
            <ConfirmationControl
              confirmedAt={session.trainer_secundar_confirmed_at}
              isOwnSlot={session.trainer_secundar_id === viewerId}
              canCorrect={canCorrectConfirmation}
              isFuture={isFuture}
              isPending={isPending}
              isSaving={savingConfirmationSlot === "secundar"}
              onToggle={(checked) => onToggleConfirmation("secundar", checked)}
              onCorrect={(checked) => onCorrectConfirmation("secundar", checked)}
            />
          )}
          <p className="font-body text-muted mt-1 text-xs">
            {t("mobile_duration_prefix")}{session.duration_minutes ? `${session.duration_minutes} min` : "—"}
          </p>
          <p className="font-body text-muted mt-1 text-xs">
            {t("mobile_location_prefix")}{session.location_tier ? t(`location_tier_${session.location_tier}`) : "—"}
          </p>
          {isSavingAttendance ? (
            <p className="font-body text-muted mt-1 text-xs italic">{t("saving_attendance")}</p>
          ) : (
            <>
              <p className="font-body text-muted mt-1 text-xs">
                {t("mobile_present_prefix")}{session.attendance_count ?? "—"}
              </p>
              {session.experiment_delivered && (
                <p className="font-body text-muted mt-1 text-xs">
                  {t("mobile_experiment_prefix")}{session.experiment_delivered}
                  {session.experiment_drive_link && (
                    <a
                      href={session.experiment_drive_link}
                      target="_blank"
                      rel="noreferrer"
                      className="text-brand-pink ml-2 font-semibold hover:underline"
                    >
                      {t("open_action")}
                    </a>
                  )}
                </p>
              )}
            </>
          )}
          <div className="mt-3 flex flex-col gap-2">
            {canManageSessions && (
              <button
                type="button"
                onClick={onStartEditing}
                className="text-brand-pink w-full rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
              >
                {t("reallocate_button")}
              </button>
            )}
            {canEditAttendance && !isSavingAttendance && (
              <button
                type="button"
                onClick={onStartEditingAttendance}
                className="text-brand-pink w-full rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
              >
                {t("record_attendance_button")}
              </button>
            )}
          </div>
        </>
      )}
    </div>
  );
}

function TrainerSelect({
  value,
  options,
  onChange,
}: {
  value: string;
  options: TrainerOption[];
  onChange: (v: string) => void;
}) {
  const t = useTranslations(groupsDict);
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="font-body text-ink w-full rounded-lg border border-gray-300 px-2 py-1.5 text-xs outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
    >
      <option value="">{t("no_trainer")}</option>
      {options.map((opt) => (
        <option key={opt.id} value={opt.id}>
          {opt.name}
        </option>
      ))}
    </select>
  );
}

function NewSessionForm({
  trainerOptions,
  trainerHomeCities,
  groupAddress,
  isPending,
  onSubmit,
}: {
  trainerOptions: TrainerOption[];
  trainerHomeCities: Record<string, string>;
  groupAddress: string | null;
  isPending: boolean;
  onSubmit: (
    date: string,
    principalId: string,
    secundarId: string,
    status: string,
    attendance: string,
    experiment: string,
    duration: string,
    experimentDriveLink: string,
    startTime: string,
    locationTier: string,
  ) => void;
}) {
  const t = useTranslations(groupsDict);
  const [date, setDate] = useState("");
  const [principalId, setPrincipalId] = useState("");
  const [secundarId, setSecundarId] = useState("");
  const [status, setStatus] = useState("planned");
  const [attendance, setAttendance] = useState("");
  const [experiment, setExperiment] = useState("");
  const [duration, setDuration] = useState("");
  const [experimentDriveLink, setExperimentDriveLink] = useState("");
  const [startTime, setStartTime] = useState("");
  const [locationTier, setLocationTier] = useState("");
  const [locationTierTouched, setLocationTierTouched] = useState(false);
  const [locationTierPrefilled, setLocationTierPrefilled] = useState(false);

  // Entered, never derived (item 95/96 report) -- this only ever
  // suggests. Fires while the principal is the only trainer picked so
  // far and the person hasn't touched the field themselves; stops for
  // good the moment they do, even if they change the trainer again
  // afterward, so it never silently overwrites a real choice. Both the
  // trainer's home city AND the resolved address need to say Bucharest
  // -- the school side is free text with no structured city, so a
  // missing or unrecognized address leaves this unset rather than
  // guessed, reading as "choose one," not a default that looks chosen.
  useEffect(() => {
    if (locationTierTouched) return;
    const homeCity = trainerHomeCities[principalId]?.trim().toLowerCase();
    const addressLooksLikeBucharest = (groupAddress ?? "").toLowerCase().includes("bucur");
    if (homeCity === "bucuresti" && addressLooksLikeBucharest) {
      setLocationTier("bucuresti");
      setLocationTierPrefilled(true);
    } else {
      setLocationTier("");
      setLocationTierPrefilled(false);
    }
  }, [principalId, trainerHomeCities, groupAddress, locationTierTouched]);

  function handleLocationTierChange(value: string) {
    setLocationTier(value);
    setLocationTierTouched(true);
    setLocationTierPrefilled(false);
  }

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("new_session_title")}
      </h2>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("col_date")}
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("kv_start_time")}
          <input
            type="time"
            value={startTime}
            onChange={(e) => setStartTime(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(SESSION_STATUS_KEYS).map(([value, key]) => (
            <option key={value} value={value}>
              {t(key)}
            </option>
          ))}
        </select>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("trainer_principal_label")}
          <select
            value={principalId}
            onChange={(e) => setPrincipalId(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          >
            <option value="">{t("no_trainer")}</option>
            {trainerOptions.map((opt) => (
              <option key={opt.id} value={opt.id}>
                {opt.name}
              </option>
            ))}
          </select>
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("trainer_secundar_label")}
          <select
            value={secundarId}
            onChange={(e) => setSecundarId(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          >
            <option value="">{t("no_trainer")}</option>
            {trainerOptions.map((opt) => (
              <option key={opt.id} value={opt.id}>
                {opt.name}
              </option>
            ))}
          </select>
        </label>
        <input
          type="number"
          min="0"
          value={attendance}
          onChange={(e) => setAttendance(e.target.value)}
          placeholder={t("attendance_placeholder")}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={experiment}
          onChange={(e) => setExperiment(e.target.value)}
          placeholder={t("experiment_placeholder")}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        {/* A number input, not a wider select. Until 202610160004 the pay
            grid was read with an equality key, so the only enterable
            lengths were the four it held -- and the real 2026-2027
            schedule has classes of 45 and 50 minutes, which could not be
            RECORDED at all, let alone priced. The resolver now bands
            (smallest band at or above the actual length), so the honest
            control is the real number of minutes rather than a longer
            list of someone's guesses. min/max mirror
            sessions_duration_minutes_range_check (15..480) so the form
            refuses what the column would refuse; the ceiling sits well
            above the grid's top band on purpose, because a workshop
            longer than the grid prices must stay recordable and merely
            unpayable. */}
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("duration_label")}
          <input
            type="number"
            inputMode="numeric"
            min="15"
            max="480"
            step="5"
            value={duration}
            onChange={(e) => setDuration(e.target.value)}
            placeholder={t("duration_placeholder")}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <input
          type="text"
          value={experimentDriveLink}
          onChange={(e) => setExperimentDriveLink(e.target.value)}
          placeholder={t("experiment_drive_link_placeholder")}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          {t("location_tier_label")}
          <select
            value={locationTier}
            onChange={(e) => handleLocationTierChange(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          >
            <option value="">{t("location_tier_placeholder")}</option>
            <option value="bucuresti">{t("location_tier_bucuresti")}</option>
            <option value="imprejurimi">{t("location_tier_imprejurimi")}</option>
            <option value="alte_orase">{t("location_tier_alte_orase")}</option>
          </select>
          {locationTierPrefilled && (
            <span className="font-body text-muted text-[11px] normal-case">
              {t("location_tier_prefilled_hint")}
            </span>
          )}
        </label>
      </div>
      <button
        type="button"
        disabled={isPending || !date}
        onClick={() =>
          onSubmit(
            date,
            principalId,
            secundarId,
            status,
            attendance,
            experiment,
            duration,
            experimentDriveLink,
            startTime,
            locationTier,
          )
        }
        className="font-body mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        {t("create_session_button")}
      </button>
    </section>
  );
}

function Badge({
  children,
  tone,
}: {
  children: React.ReactNode;
  tone?: string;
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${tone ?? "bg-ink/5 text-ink"}`}
    >
      {children}
    </span>
  );
}
