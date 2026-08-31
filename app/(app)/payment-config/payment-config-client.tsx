"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "@/lib/i18n";
import { formatDate } from "@/lib/format";
import { paymentConfigDict } from "./i18n";
import {
  createTrainerGradeVersion,
  createLocationBonusVersion,
  createLanguageBonusVersion,
  createDurationMultiplierVersion,
  createContractTypeUpliftVersion,
  type ActionResult,
} from "./actions";

type Version = { id: string; effective_date: string; created_by: string; note: string | null };
type GradeRate = { version_id: string; grade_level: number; rate: number };
type LocationRate = { version_id: string; location_tier: string; bonus_percent: number };
type LanguageRate = { version_id: string; language_group: string; bonus_percent: number };
type DurationRate = { version_id: string; duration_minutes: number; delivery_context: string; multiplier: number };
type UpliftRate = { version_id: string; contract_type: string; uplift_percent: number };

const GRADE_LEVELS = [1, 2, 3, 4, 5, 6];
const LOCATION_TIERS = ["bucuresti", "imprejurimi", "alte_orase"] as const;
const LANGUAGE_GROUPS = ["ro_en", "fr_de_es"] as const;
const DURATION_KEYS = ["30:standard", "60:standard", "90:standard", "120:standard", "120:scoala_altfel_saptamana_verde"];
const CONTRACT_TYPES = ["pfa", "srl", "drepturi_autor"] as const;

// Today's date as a plain component, not new Date() reached for inside a
// render path repeatedly -- computed once per mount for each form's
// initial effective-date value. This is ordinary client component state,
// not a Workflow script, so new Date() itself is fine here; it's only
// captured once, not re-evaluated on every keystroke.
function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

export function PaymentConfigClient({
  orgId,
  creatorNameById,
  trainerGrades,
  locationBonuses,
  languageBonuses,
  durationMultipliers,
  contractTypeUplifts,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  trainerGrades: { versions: Version[]; rates: GradeRate[] };
  locationBonuses: { versions: Version[]; rates: LocationRate[] };
  languageBonuses: { versions: Version[]; rates: LanguageRate[] };
  durationMultipliers: { versions: Version[]; rates: DurationRate[] };
  contractTypeUplifts: { versions: Version[]; rates: UpliftRate[] };
}) {
  const t = useTranslations(paymentConfigDict);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl text-brand-pink">{t("page_title")}</h1>
        <p className="font-body text-muted mt-1 text-sm">{t("page_subtitle")}</p>
      </div>

      <TrainerGradesSection orgId={orgId} creatorNameById={creatorNameById} {...trainerGrades} />
      <LocationBonusesSection orgId={orgId} creatorNameById={creatorNameById} {...locationBonuses} />
      <LanguageBonusesSection orgId={orgId} creatorNameById={creatorNameById} {...languageBonuses} />
      <DurationMultipliersSection orgId={orgId} creatorNameById={creatorNameById} {...durationMultipliers} />
      <ContractTypeUpliftsSection orgId={orgId} creatorNameById={creatorNameById} {...contractTypeUplifts} />
    </div>
  );
}

// ============================================================================
// 1. Trainer grades
// ============================================================================

function TrainerGradesSection({
  orgId,
  creatorNameById,
  versions,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  rates: GradeRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<number, string>>(
    Object.fromEntries(GRADE_LEVELS.map((n) => [n, ""])),
  );

  const current = versions[0];
  const history = versions.slice(1);
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createTrainerGradeVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(t(result.error === "incomplete_form" ? "error_incomplete_form" : "error_save_failed"));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(GRADE_LEVELS.map((n) => [n, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_trainer_grades_title")} subtitle={t("section_trainer_grades_subtitle")}>
      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]}>
          {GRADE_LEVELS.map((level) => (
            <Kv key={level} label={t("grade_level_label", { n: level })} value={currentRows.find((r) => r.grade_level === level)?.rate.toString() ?? "—"} />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        renderRows={(versionId) =>
          GRADE_LEVELS.map((level) => (
            <Kv key={level} label={t("grade_level_label", { n: level })} value={rates.find((r) => r.version_id === versionId && r.grade_level === level)?.rate.toString() ?? "—"} />
          ))
        }
      />

      {isFormOpen ? (
        <NewVersionForm
          effectiveDate={effectiveDate}
          onEffectiveDateChange={setEffectiveDate}
          note={note}
          onNoteChange={setNote}
          isPending={isPending}
          error={error}
          onCancel={() => setIsFormOpen(false)}
          onSubmit={handleSubmit}
        >
          {GRADE_LEVELS.map((level) => (
            <input
              key={level}
              type="number"
              step="0.01"
              value={values[level]}
              onChange={(e) => setValues((prev) => ({ ...prev, [level]: e.target.value }))}
              placeholder={`${t("grade_level_label", { n: level })} — ${t("rate_placeholder")}`}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          ))}
        </NewVersionForm>
      ) : (
        <NewVersionButton onClick={() => setIsFormOpen(true)} />
      )}
    </Section>
  );
}

// ============================================================================
// 2. Location bonuses
// ============================================================================

function LocationBonusesSection({
  orgId,
  creatorNameById,
  versions,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  rates: LocationRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(LOCATION_TIERS.map((tier) => [tier, ""])),
  );

  const tierLabel = (tier: string) => t(`tier_${tier}`);

  const current = versions[0];
  const history = versions.slice(1);
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createLocationBonusVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(t(result.error === "incomplete_form" ? "error_incomplete_form" : "error_save_failed"));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(LOCATION_TIERS.map((tier) => [tier, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_location_bonuses_title")} subtitle={t("section_location_bonuses_subtitle")}>
      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]}>
          {LOCATION_TIERS.map((tier) => (
            <Kv key={tier} label={tierLabel(tier)} value={currentRows.find((r) => r.location_tier === tier)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        renderRows={(versionId) =>
          LOCATION_TIERS.map((tier) => (
            <Kv key={tier} label={tierLabel(tier)} value={rates.find((r) => r.version_id === versionId && r.location_tier === tier)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))
        }
      />

      {isFormOpen ? (
        <NewVersionForm
          effectiveDate={effectiveDate}
          onEffectiveDateChange={setEffectiveDate}
          note={note}
          onNoteChange={setNote}
          isPending={isPending}
          error={error}
          onCancel={() => setIsFormOpen(false)}
          onSubmit={handleSubmit}
        >
          {LOCATION_TIERS.map((tier) => (
            <input
              key={tier}
              type="number"
              step="0.01"
              value={values[tier]}
              onChange={(e) => setValues((prev) => ({ ...prev, [tier]: e.target.value }))}
              placeholder={`${tierLabel(tier)} — ${t("bonus_percent_placeholder")}`}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          ))}
        </NewVersionForm>
      ) : (
        <NewVersionButton onClick={() => setIsFormOpen(true)} />
      )}
    </Section>
  );
}

// ============================================================================
// 3. Language bonuses
// ============================================================================

function LanguageBonusesSection({
  orgId,
  creatorNameById,
  versions,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  rates: LanguageRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(LANGUAGE_GROUPS.map((g) => [g, ""])),
  );

  const groupLabel = (group: string) => t(`group_${group}`);

  const current = versions[0];
  const history = versions.slice(1);
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createLanguageBonusVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(t(result.error === "incomplete_form" ? "error_incomplete_form" : "error_save_failed"));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(LANGUAGE_GROUPS.map((g) => [g, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_language_bonuses_title")} subtitle={t("section_language_bonuses_subtitle")}>
      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]}>
          {LANGUAGE_GROUPS.map((group) => (
            <Kv key={group} label={groupLabel(group)} value={currentRows.find((r) => r.language_group === group)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        renderRows={(versionId) =>
          LANGUAGE_GROUPS.map((group) => (
            <Kv key={group} label={groupLabel(group)} value={rates.find((r) => r.version_id === versionId && r.language_group === group)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))
        }
      />

      {isFormOpen ? (
        <NewVersionForm
          effectiveDate={effectiveDate}
          onEffectiveDateChange={setEffectiveDate}
          note={note}
          onNoteChange={setNote}
          isPending={isPending}
          error={error}
          onCancel={() => setIsFormOpen(false)}
          onSubmit={handleSubmit}
        >
          {LANGUAGE_GROUPS.map((group) => (
            <input
              key={group}
              type="number"
              step="0.01"
              value={values[group]}
              onChange={(e) => setValues((prev) => ({ ...prev, [group]: e.target.value }))}
              placeholder={`${groupLabel(group)} — ${t("bonus_percent_placeholder")}`}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          ))}
        </NewVersionForm>
      ) : (
        <NewVersionButton onClick={() => setIsFormOpen(true)} />
      )}
    </Section>
  );
}

// ============================================================================
// 4. Duration multipliers
// ============================================================================

function DurationMultipliersSection({
  orgId,
  creatorNameById,
  versions,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  rates: DurationRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(DURATION_KEYS.map((k) => [k, ""])),
  );

  function keyLabel(key: string) {
    const [minutes, context] = key.split(":");
    if (context === "scoala_altfel_saptamana_verde") return t("context_extended");
    return `${t(`duration_${minutes}`)} — ${t("context_standard")}`;
  }

  const current = versions[0];
  const history = versions.slice(1);
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createDurationMultiplierVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(t(result.error === "incomplete_form" ? "error_incomplete_form" : "error_save_failed"));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(DURATION_KEYS.map((k) => [k, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_duration_multipliers_title")} subtitle={t("section_duration_multipliers_subtitle")}>
      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]}>
          {DURATION_KEYS.map((key) => {
            const [minutes, context] = key.split(":");
            const row = currentRows.find((r) => r.duration_minutes === Number(minutes) && r.delivery_context === context);
            return <Kv key={key} label={keyLabel(key)} value={row?.multiplier.toString() ?? "—"} suffix="×" />;
          })}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        renderRows={(versionId) =>
          DURATION_KEYS.map((key) => {
            const [minutes, context] = key.split(":");
            const row = rates.find((r) => r.version_id === versionId && r.duration_minutes === Number(minutes) && r.delivery_context === context);
            return <Kv key={key} label={keyLabel(key)} value={row?.multiplier.toString() ?? "—"} suffix="×" />;
          })
        }
      />

      {isFormOpen ? (
        <NewVersionForm
          effectiveDate={effectiveDate}
          onEffectiveDateChange={setEffectiveDate}
          note={note}
          onNoteChange={setNote}
          isPending={isPending}
          error={error}
          onCancel={() => setIsFormOpen(false)}
          onSubmit={handleSubmit}
        >
          {DURATION_KEYS.map((key) => (
            <input
              key={key}
              type="number"
              step="0.01"
              value={values[key]}
              onChange={(e) => setValues((prev) => ({ ...prev, [key]: e.target.value }))}
              placeholder={`${keyLabel(key)} — ${t("multiplier_placeholder")}`}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          ))}
        </NewVersionForm>
      ) : (
        <NewVersionButton onClick={() => setIsFormOpen(true)} />
      )}
    </Section>
  );
}

// ============================================================================
// 5. Contract type uplifts
// ============================================================================

function ContractTypeUpliftsSection({
  orgId,
  creatorNameById,
  versions,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  rates: UpliftRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(CONTRACT_TYPES.map((ty) => [ty, ""])),
  );

  const typeLabel = (ty: string) => t(`type_${ty}`);

  const current = versions[0];
  const history = versions.slice(1);
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createContractTypeUpliftVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(t(result.error === "incomplete_form" ? "error_incomplete_form" : "error_save_failed"));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(CONTRACT_TYPES.map((ty) => [ty, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_contract_type_uplifts_title")} subtitle={t("section_contract_type_uplifts_subtitle")}>
      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]}>
          {CONTRACT_TYPES.map((ty) => (
            <Kv key={ty} label={typeLabel(ty)} value={currentRows.find((r) => r.contract_type === ty)?.uplift_percent.toString() ?? "—"} suffix="%" />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        renderRows={(versionId) =>
          CONTRACT_TYPES.map((ty) => (
            <Kv key={ty} label={typeLabel(ty)} value={rates.find((r) => r.version_id === versionId && r.contract_type === ty)?.uplift_percent.toString() ?? "—"} suffix="%" />
          ))
        }
      />

      {isFormOpen ? (
        <NewVersionForm
          effectiveDate={effectiveDate}
          onEffectiveDateChange={setEffectiveDate}
          note={note}
          onNoteChange={setNote}
          isPending={isPending}
          error={error}
          onCancel={() => setIsFormOpen(false)}
          onSubmit={handleSubmit}
        >
          {CONTRACT_TYPES.map((ty) => (
            <input
              key={ty}
              type="number"
              step="0.01"
              value={values[ty]}
              onChange={(e) => setValues((prev) => ({ ...prev, [ty]: e.target.value }))}
              placeholder={`${typeLabel(ty)} — ${t("uplift_percent_placeholder")}`}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          ))}
        </NewVersionForm>
      ) : (
        <NewVersionButton onClick={() => setIsFormOpen(true)} />
      )}
    </Section>
  );
}

// ============================================================================
// Shared presentational pieces -- pure layout/chrome, no domain logic of
// their own (the field lists above are what actually differ per grid),
// same "shared plumbing is fine, shared domain shape is not" line the
// schema itself draws (Sec12.9's rejection of one shared version table).
// ============================================================================

function Section({ title, subtitle, children }: { title: string; subtitle: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-4 rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <div>
        <h2 className="font-display text-lg text-brand-pink">{title}</h2>
        <p className="font-body text-muted mt-1 text-xs">{subtitle}</p>
      </div>
      {children}
    </section>
  );
}

function CurrentVersionBox({
  version,
  creatorName,
  children,
}: {
  version: Version;
  creatorName: string | undefined;
  children: React.ReactNode;
}) {
  const t = useTranslations(paymentConfigDict);
  const { locale } = useLocale();
  return (
    <div className="rounded-xl border border-black/5 bg-ink/[0.02] p-4">
      <div className="mb-2 flex items-baseline justify-between">
        <span className="font-body text-muted text-xs font-bold tracking-wide uppercase">{t("current_version_title")}</span>
        <span className="font-body text-muted text-xs">
          {t("effective_from_label")} {formatDate(version.effective_date, locale)} · {t("created_by_label")} {creatorName || t("unknown_user")}
        </span>
      </div>
      <div className="flex flex-col">{children}</div>
      {version.note && <p className="font-body text-muted mt-2 text-xs italic">{version.note}</p>}
    </div>
  );
}

function EmptyVersion() {
  const t = useTranslations(paymentConfigDict);
  return (
    <div className="rounded-xl border border-dashed border-gray-300 p-4">
      <p className="font-body text-muted text-sm">{t("empty_no_version")}</p>
    </div>
  );
}

function HistoryToggle({
  versions,
  creatorNameById,
  renderRows,
}: {
  versions: Version[];
  creatorNameById: Record<string, string>;
  renderRows: (versionId: string) => React.ReactNode;
}) {
  const t = useTranslations(paymentConfigDict);
  const { locale } = useLocale();
  const [isOpen, setIsOpen] = useState(false);

  if (versions.length === 0) return null;

  return (
    <div>
      <button
        type="button"
        onClick={() => setIsOpen((open) => !open)}
        className="font-body text-brand-pink text-xs font-semibold underline"
      >
        {isOpen ? t("history_toggle_hide") : t("history_toggle_show", { count: versions.length })}
      </button>
      {isOpen && (
        <div className="mt-2 flex flex-col gap-3">
          {versions.map((v) => (
            <div key={v.id} className="rounded-xl border border-black/5 p-4">
              <div className="mb-2 flex items-baseline justify-between">
                <span className="font-body text-muted text-xs">
                  {t("effective_from_label")} {formatDate(v.effective_date, locale)} · {t("created_by_label")} {creatorNameById[v.created_by] || t("unknown_user")}
                </span>
              </div>
              <div className="flex flex-col">{renderRows(v.id)}</div>
              {v.note && <p className="font-body text-muted mt-2 text-xs italic">{v.note}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function NewVersionButton({ onClick }: { onClick: () => void }) {
  const t = useTranslations(paymentConfigDict);
  return (
    <button
      type="button"
      onClick={onClick}
      className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
    >
      {t("new_version_button")}
    </button>
  );
}

function NewVersionForm({
  effectiveDate,
  onEffectiveDateChange,
  note,
  onNoteChange,
  isPending,
  error,
  onCancel,
  onSubmit,
  children,
}: {
  effectiveDate: string;
  onEffectiveDateChange: (v: string) => void;
  note: string;
  onNoteChange: (v: string) => void;
  isPending: boolean;
  error: string | null;
  onCancel: () => void;
  onSubmit: () => void;
  children: React.ReactNode;
}) {
  const t = useTranslations(paymentConfigDict);
  return (
    <div className="rounded-xl border border-black/5 bg-ink/[0.02] p-4">
      <h3 className="font-body text-muted mb-3 text-xs font-bold tracking-wide uppercase">{t("new_version_form_title")}</h3>
      {error && (
        <p className="font-body text-ink mb-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">{error}</p>
      )}
      <div className="grid grid-cols-1 gap-2.5 md:grid-cols-2">
        <label className="font-body text-muted flex flex-col gap-1 text-xs md:col-span-2">
          {t("effective_date_label")}
          <input
            type="date"
            value={effectiveDate}
            onChange={(e) => onEffectiveDateChange(e.target.value)}
            className="font-body text-ink w-fit rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
        </label>
        {children}
        <textarea
          value={note}
          onChange={(e) => onNoteChange(e.target.value)}
          placeholder={t("note_placeholder")}
          rows={2}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
      </div>
      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending}
          onClick={onSubmit}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {t("create_version_button")}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold uppercase"
        >
          {t("cancel")}
        </button>
      </div>
    </div>
  );
}

function Kv({ label, value, suffix }: { label: string; value: string; suffix?: string }) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-1.5 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className="font-body text-ink font-medium">
        {value}
        {value !== "—" && suffix ? suffix : ""}
      </span>
    </div>
  );
}
