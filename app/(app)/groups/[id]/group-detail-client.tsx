"use client";

import { useState, useTransition } from "react";
import { addSession, updateSessionAllocation } from "../actions";

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
};
type TrainerOption = { id: string; name: string };

// Matches the sessions.status check constraint (202608160004) exactly —
// 'confirmed' added between planned and delivered (trainer allocated,
// date locked, but not yet run).
const SESSION_STATUS_LABELS: Record<string, string> = {
  planned: "Planned",
  confirmed: "Confirmed",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

// Anca's color scheme for the 4-value status.
const SESSION_STATUS_TONES: Record<string, string> = {
  planned: "bg-orange-100 text-orange-700",
  confirmed: "bg-green-50 text-green-700",
  delivered: "bg-green-700 text-white",
  cancelled: "bg-red-100 text-red-700",
};

function formatShortDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", {
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
  trainerOptions,
}: {
  groupId: string;
  organizationId: string;
  sessions: Session[];
  canManageSessions: boolean;
  trainerOptions: TrainerOption[];
}) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingSessionId, setEditingSessionId] = useState<string | null>(null);
  const [principalDraft, setPrincipalDraft] = useState<Record<string, string>>({});
  const [secundarDraft, setSecundarDraft] = useState<Record<string, string>>({});

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
      const result = await updateSessionAllocation(groupId, s.id, principal, secundar);
      if (!result.ok) setError(result.error);
    });
    setEditingSessionId(null);
  }

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
            + New session
          </button>
          {isFormOpen && (
            <NewSessionForm
              trainerOptions={trainerOptions}
              isPending={isPending}
              onSubmit={(date, principalId, secundarId, status, attendance, experiment, duration, experimentDriveLink) => {
                setError(null);
                startTransition(async () => {
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
                  );
                  if (!result.ok) setError(result.error);
                  else setIsFormOpen(false);
                });
              }}
            />
          )}
        </div>
      )}

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Sessions ({sessions.length})
        </h2>

        {sessions.length === 0 ? (
          <p className="font-body text-muted text-sm">
            {canManageSessions
              ? "No sessions yet."
              : "No sessions allocated to you in this group."}
          </p>
        ) : (
          <>
            <table className="hidden w-full border-collapse text-sm md:table">
              <thead>
                <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
                  <th className="py-2 pr-4 font-bold">Date</th>
                  <th className="py-2 pr-4 font-bold">Principal</th>
                  <th className="py-2 pr-4 font-bold">Secundar</th>
                  <th className="py-2 pr-4 font-bold">Status</th>
                  <th className="py-2 pr-4 font-bold">Duration</th>
                  {/* "Present" (not "Attendance") — the post-workshop
                      ACTUAL headcount for this occurrence, distinct from
                      the group's own "Children confirmed" (contract-time
                      headcount, shown on Group info above). Same field as
                      before, relabeled for clarity per Anca's request —
                      investigated, no new column needed. */}
                  <th className="py-2 pr-4 font-bold">Present</th>
                  <th className="py-2 font-bold">Experiment delivered</th>
                </tr>
              </thead>
              <tbody>
                {sessions.map((s) => (
                  <SessionTableRow
                    key={s.id}
                    session={s}
                    editing={editingSessionId === s.id}
                    canManageSessions={canManageSessions}
                    isPending={isPending}
                    trainerOptions={trainerOptions}
                    principalValue={principalDraft[s.id] ?? s.trainer_principal_id ?? ""}
                    secundarValue={secundarDraft[s.id] ?? s.trainer_secundar_id ?? ""}
                    onChangePrincipal={(v) => setPrincipalDraft((prev) => ({ ...prev, [s.id]: v }))}
                    onChangeSecundar={(v) => setSecundarDraft((prev) => ({ ...prev, [s.id]: v }))}
                    onStartEditing={() => startEditing(s)}
                    onCancelEditing={() => cancelEditing(s)}
                    onSave={() => saveEditing(s)}
                  />
                ))}
              </tbody>
            </table>

            <div className="flex flex-col gap-3 md:hidden">
              {sessions.map((s) => (
                <SessionCard
                  key={s.id}
                  session={s}
                  editing={editingSessionId === s.id}
                  canManageSessions={canManageSessions}
                  isPending={isPending}
                  trainerOptions={trainerOptions}
                  principalValue={principalDraft[s.id] ?? s.trainer_principal_id ?? ""}
                  secundarValue={secundarDraft[s.id] ?? s.trainer_secundar_id ?? ""}
                  onChangePrincipal={(v) => setPrincipalDraft((prev) => ({ ...prev, [s.id]: v }))}
                  onChangeSecundar={(v) => setSecundarDraft((prev) => ({ ...prev, [s.id]: v }))}
                  onStartEditing={() => startEditing(s)}
                  onCancelEditing={() => cancelEditing(s)}
                  onSave={() => saveEditing(s)}
                />
              ))}
            </div>
          </>
        )}
      </section>
    </div>
  );
}

type SessionRowProps = {
  session: Session;
  editing: boolean;
  canManageSessions: boolean;
  isPending: boolean;
  trainerOptions: TrainerOption[];
  principalValue: string;
  secundarValue: string;
  onChangePrincipal: (v: string) => void;
  onChangeSecundar: (v: string) => void;
  onStartEditing: () => void;
  onCancelEditing: () => void;
  onSave: () => void;
};

// Inline reallocate — the "rotation" case (task spec): only
// trainer_principal_id/trainer_secundar_id are editable here, matching
// admin-users-client.tsx's MemberTableRow edit/Save/Cancel pattern. Not
// rendered at all for a Trainer/Senior Trainer viewer — read-only for them
// by design, not just visually disabled.
function SessionTableRow({
  session,
  editing,
  canManageSessions,
  isPending,
  trainerOptions,
  principalValue,
  secundarValue,
  onChangePrincipal,
  onChangeSecundar,
  onStartEditing,
  onCancelEditing,
  onSave,
}: SessionRowProps) {
  return (
    <tr className="font-body text-ink border-b border-black/5 align-top last:border-0">
      <td className="py-3 pr-4 text-xs whitespace-nowrap">{formatShortDate(session.session_date)}</td>
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
          <td className="py-3 pr-4">{session.trainerPrincipalName ?? "—"}</td>
          <td className="py-3 pr-4">{session.trainerSecundarName ?? "—"}</td>
        </>
      )}
      <td className="py-3 pr-4">
        <Badge tone={SESSION_STATUS_TONES[session.status]}>
          {SESSION_STATUS_LABELS[session.status] ?? session.status}
        </Badge>
      </td>
      <td className="text-muted py-3 pr-4">
        {session.duration_minutes ? `${session.duration_minutes} min` : "—"}
      </td>
      <td className="text-muted py-3 pr-4">{session.attendance_count ?? "—"}</td>
      <td className="text-muted py-3">
        <div className="flex items-center justify-between gap-3">
          <span>
            {session.experiment_delivered || "—"}
            {session.experiment_drive_link && (
              <a
                href={session.experiment_drive_link}
                target="_blank"
                rel="noreferrer"
                className="text-brand-pink ml-2 text-xs font-semibold hover:underline"
              >
                Open
              </a>
            )}
          </span>
          {canManageSessions &&
            (editing ? (
              <span className="flex shrink-0 gap-2">
                <button
                  type="button"
                  disabled={isPending}
                  onClick={onSave}
                  className="rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
                >
                  Save
                </button>
                <button
                  type="button"
                  onClick={onCancelEditing}
                  className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
                >
                  Cancel
                </button>
              </span>
            ) : (
              <button
                type="button"
                onClick={onStartEditing}
                className="text-brand-pink shrink-0 text-xs font-semibold underline"
              >
                reallocate
              </button>
            ))}
        </div>
      </td>
    </tr>
  );
}

function SessionCard({
  session,
  editing,
  canManageSessions,
  isPending,
  trainerOptions,
  principalValue,
  secundarValue,
  onChangePrincipal,
  onChangeSecundar,
  onStartEditing,
  onCancelEditing,
  onSave,
}: SessionRowProps) {
  return (
    <div className="rounded-xl border border-black/5 p-4">
      <div className="flex items-center justify-between">
        <p className="font-body text-ink text-sm font-semibold">
          {formatShortDate(session.session_date)}
        </p>
        <Badge tone={SESSION_STATUS_TONES[session.status]}>
          {SESSION_STATUS_LABELS[session.status] ?? session.status}
        </Badge>
      </div>

      {editing ? (
        <div className="mt-3 flex flex-col gap-2">
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            Principal
            <TrainerSelect value={principalValue} options={trainerOptions} onChange={onChangePrincipal} />
          </label>
          <label className="font-body text-muted flex flex-col gap-1 text-xs">
            Secundar
            <TrainerSelect value={secundarValue} options={trainerOptions} onChange={onChangeSecundar} />
          </label>
          <div className="mt-1 flex gap-2">
            <button
              type="button"
              disabled={isPending}
              onClick={onSave}
              className="flex-1 rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-2 text-xs font-bold text-white uppercase disabled:opacity-50"
            >
              Save
            </button>
            <button
              type="button"
              onClick={onCancelEditing}
              className="text-muted flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <>
          <p className="font-body text-muted mt-2 text-xs">
            Principal: {session.trainerPrincipalName ?? "—"}
          </p>
          <p className="font-body text-muted mt-1 text-xs">
            Secundar: {session.trainerSecundarName ?? "—"}
          </p>
          <p className="font-body text-muted mt-1 text-xs">
            Duration: {session.duration_minutes ? `${session.duration_minutes} min` : "—"}
          </p>
          <p className="font-body text-muted mt-1 text-xs">
            Present: {session.attendance_count ?? "—"}
          </p>
          {session.experiment_delivered && (
            <p className="font-body text-muted mt-1 text-xs">
              Experiment: {session.experiment_delivered}
              {session.experiment_drive_link && (
                <a
                  href={session.experiment_drive_link}
                  target="_blank"
                  rel="noreferrer"
                  className="text-brand-pink ml-2 font-semibold hover:underline"
                >
                  Open
                </a>
              )}
            </p>
          )}
          {canManageSessions && (
            <button
              type="button"
              onClick={onStartEditing}
              className="text-brand-pink mt-3 w-full rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              Reallocate
            </button>
          )}
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
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="font-body text-ink w-full rounded-lg border border-gray-300 px-2 py-1.5 text-xs outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
    >
      <option value="">Unassigned</option>
      {options.map((t) => (
        <option key={t.id} value={t.id}>
          {t.name}
        </option>
      ))}
    </select>
  );
}

function NewSessionForm({
  trainerOptions,
  isPending,
  onSubmit,
}: {
  trainerOptions: TrainerOption[];
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
  ) => void;
}) {
  const [date, setDate] = useState("");
  const [principalId, setPrincipalId] = useState("");
  const [secundarId, setSecundarId] = useState("");
  const [status, setStatus] = useState("planned");
  const [attendance, setAttendance] = useState("");
  const [experiment, setExperiment] = useState("");
  const [duration, setDuration] = useState("");
  const [experimentDriveLink, setExperimentDriveLink] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        New session
      </h2>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Date
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(SESSION_STATUS_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Trainer principal
          <select
            value={principalId}
            onChange={(e) => setPrincipalId(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          >
            <option value="">Unassigned</option>
            {trainerOptions.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Trainer secundar
          <select
            value={secundarId}
            onChange={(e) => setSecundarId(e.target.value)}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          >
            <option value="">Unassigned</option>
            {trainerOptions.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        </label>
        <input
          type="number"
          min="0"
          value={attendance}
          onChange={(e) => setAttendance(e.target.value)}
          placeholder="Attendance count (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={experiment}
          onChange={(e) => setExperiment(e.target.value)}
          placeholder="Experiment delivered (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <select
          value={duration}
          onChange={(e) => setDuration(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          <option value="">Duration (optional)</option>
          <option value="30">30 min</option>
          <option value="60">60 min</option>
          <option value="90">90 min</option>
          <option value="120">120 min</option>
        </select>
        <input
          type="text"
          value={experimentDriveLink}
          onChange={(e) => setExperimentDriveLink(e.target.value)}
          placeholder="Experiment Drive link (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
      </div>
      <button
        type="button"
        disabled={isPending || !date}
        onClick={() =>
          onSubmit(date, principalId, secundarId, status, attendance, experiment, duration, experimentDriveLink)
        }
        className="font-body mt-3 w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        Create session
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
