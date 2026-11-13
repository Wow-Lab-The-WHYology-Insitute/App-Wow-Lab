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
  previewGridCorrection,
  applyGridCorrection,
  type ActionResult,
  type CorrectableGrid,
  type CorrectionError,
  type Declaration,
} from "./actions";

type Version = { id: string; effective_date: string; created_by: string; note: string | null; corrects_version_id?: string | null };
type GradeRate = { version_id: string; grade_level: number; rate: number };
type LocationRate = { version_id: string; location_tier: string; bonus_percent: number };
type LanguageRate = { version_id: string; language_group: string; bonus_percent: number };
type DurationRate = { version_id: string; duration_minutes: number; delivery_context: string; multiplier: number };
type UpliftRate = { version_id: string; contract_type: string; uplift_percent: number };

const GRADE_LEVELS = [1, 2, 3, 4, 5, 6];
const LOCATION_TIERS = ["bucuresti", "imprejurimi", "alte_orase"] as const;
const LANGUAGE_GROUPS = ["ro_en", "fr_de_es"] as const;
// Used only when an org has no duration version yet. Otherwise the form and
// the display take their bands from the grid's own rows: a fixed list here
// once silently dropped two bands from every version saved (item 194).
const DEFAULT_DURATION_KEYS = ["30:standard", "60:standard", "90:standard", "120:standard", "120:scoala_altfel_saptamana_verde"];
const CONTRACT_TYPES = ["pfa", "srl", "drepturi_autor"] as const;

function durationBandKeys(rows: DurationRate[]): string[] {
  const keys = [...new Set(rows.map((r) => `${r.duration_minutes}:${r.delivery_context}`))];
  return keys.sort((a, b) => {
    const [am, ac] = a.split(":");
    const [bm, bc] = b.split(":");
    if (ac !== bc) return ac === "standard" ? -1 : 1;
    return Number(am) - Number(bm);
  });
}

// Money, months and counts the way the refusal and the correction statement
// both say them -- one set of formatters, so the two never read differently.
function useFormatters() {
  const t = useTranslations(paymentConfigDict);
  const { locale } = useLocale();
  const tag = locale === "ro" ? "ro-RO" : "en-GB";
  const lei = (n: number | null) =>
    n === null ? "—" : new Intl.NumberFormat(tag, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
  const month = (ym: string) => new Intl.DateTimeFormat(tag, { month: "long", year: "numeric" }).format(new Date(`${ym}-01T12:00:00`));
  const delta = (n: number) => `${n >= 0 ? "+" : "−"}${lei(Math.abs(n))}`;
  // Romanian puts "de" between a number and its noun from 20 up ("20 de sesiuni").
  const de = (n: number) => (n % 100 === 0 || n % 100 >= 20 ? "de " : "");
  const confirmedSessions = (n: number) => (n === 1 ? t("sessions_one") : t("sessions_many", { n, de: de(n) }));
  const sessionsShort = (n: number) => (n === 1 ? t("sessions_short_one") : t("sessions_short_many", { n, de: de(n) }));
  return { locale, lei, month, delta, de, confirmedSessions, sessionsShort };
}

function useDescribeError(labelFor?: (key: string) => string) {
  const t = useTranslations(paymentConfigDict);
  const fmt = useFormatters();

  return function describe(result: Exclude<ActionResult, { ok: true }>): string {
    switch (result.error) {
      case "incomplete_form":
        return t("error_incomplete_form");
      case "date_taken":
        return t("error_date_taken");
      case "missing_bands":
        return t("error_missing_bands", { list: result.missing.map((k) => labelFor?.(k) ?? k).join(", ") });
      case "would_change_confirmed_pay": {
        const d = result.detail;
        const message = t("error_would_change_confirmed_pay", {
          sessions: fmt.confirmedSessions(d.sessions),
          months: d.months.map(fmt.month).join(", "),
          before: fmt.lei(d.total_before),
          after: fmt.lei(d.total_after),
          delta: fmt.delta(d.delta),
        });
        return d.unpriceable_slots > 0 ? `${message} ${t("error_unpriceable_suffix", { n: d.unpriceable_slots })}` : message;
      }
      default:
        return t("error_save_failed");
    }
  };
}

function useDescribeCorrectionError(labelFor?: (key: string) => string) {
  const t = useTranslations(paymentConfigDict);
  return function describe(result: Exclude<CorrectionError, { error: "declaration_stale" }>): string {
    switch (result.error) {
      case "incomplete_form":
        return t("error_incomplete_form");
      case "missing_bands":
        return t("error_missing_bands", { list: result.missing.map((k) => labelFor?.(k) ?? k).join(", ") });
      case "forbidden":
        return t("error_correction_forbidden");
      case "already_corrected":
        return t("error_already_corrected");
      case "not_found":
        return t("error_version_not_found");
      default:
        return t("error_save_failed");
    }
  };
}

// A correction shares its target's effective date (item 195), so the date
// alone no longer tells two versions apart on screen: say which is which.
function correctionHelpers(versions: Version[], t: (key: string, vars?: Record<string, string | number>) => string) {
  const isCorrected = (v: Version) => versions.some((o) => o.corrects_version_id === v.id);
  const correctionBadge = (v: Version) =>
    isCorrected(v) ? t("corrected_badge") : v.corrects_version_id ? t("correction_badge") : null;
  return { isCorrected, correctionBadge };
}

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
  canCorrect,
  creatorNameById,
  trainerGrades,
  locationBonuses,
  languageBonuses,
  durationMultipliers,
  contractTypeUplifts,
}: {
  orgId: string;
  canCorrect: boolean;
  creatorNameById: Record<string, string>;
  trainerGrades: { versions: Version[]; rates: GradeRate[]; currentVersionId: string | null };
  locationBonuses: { versions: Version[]; rates: LocationRate[]; currentVersionId: string | null };
  languageBonuses: { versions: Version[]; rates: LanguageRate[]; currentVersionId: string | null };
  durationMultipliers: { versions: Version[]; rates: DurationRate[]; currentVersionId: string | null };
  contractTypeUplifts: { versions: Version[]; rates: UpliftRate[]; currentVersionId: string | null };
}) {
  const t = useTranslations(paymentConfigDict);

  const grids = [
    { key: "trainer_grades", label: t("section_trainer_grades_title"), empty: trainerGrades.versions.length === 0 },
    { key: "location_bonuses", label: t("section_location_bonuses_title"), empty: locationBonuses.versions.length === 0 },
    { key: "language_bonuses", label: t("section_language_bonuses_title"), empty: languageBonuses.versions.length === 0 },
    { key: "duration_multipliers", label: t("section_duration_multipliers_title"), empty: durationMultipliers.versions.length === 0 },
    { key: "contract_type_uplifts", label: t("section_contract_type_uplifts_title"), empty: contractTypeUplifts.versions.length === 0 },
  ];
  const missingGrids = grids.filter((g) => g.empty);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl text-brand-pink">{t("page_title")}</h1>
        <p className="font-body text-muted mt-1 text-sm">{t("page_subtitle")}</p>
      </div>

      {missingGrids.length > 0 && (
        <div className="flex flex-col gap-1 rounded-2xl border border-orange-200 bg-orange-50 px-5 py-4">
          <span className="font-body text-sm font-medium text-orange-800">
            {t("missing_grids_banner_line", { n: missingGrids.length, total: grids.length })}
          </span>
          <ul className="font-body list-disc pl-4 text-xs text-orange-700">
            {missingGrids.map((g) => (
              <li key={g.key}>{g.label}</li>
            ))}
          </ul>
        </div>
      )}

      <TrainerGradesSection orgId={orgId} canCorrect={canCorrect} creatorNameById={creatorNameById} {...trainerGrades} />
      <LocationBonusesSection orgId={orgId} canCorrect={canCorrect} creatorNameById={creatorNameById} {...locationBonuses} />
      <LanguageBonusesSection orgId={orgId} canCorrect={canCorrect} creatorNameById={creatorNameById} {...languageBonuses} />
      <DurationMultipliersSection orgId={orgId} canCorrect={canCorrect} creatorNameById={creatorNameById} {...durationMultipliers} />
      <ContractTypeUpliftsSection orgId={orgId} creatorNameById={creatorNameById} {...contractTypeUplifts} />
    </div>
  );
}

// ============================================================================
// 1. Trainer grades
// ============================================================================

function TrainerGradesSection({
  orgId,
  canCorrect,
  creatorNameById,
  versions,
  currentVersionId,
  rates,
}: {
  orgId: string;
  canCorrect: boolean;
  creatorNameById: Record<string, string>;
  versions: Version[];
  currentVersionId: string | null;
  rates: GradeRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const describeError = useDescribeError();
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<number, string>>(
    Object.fromEntries(GRADE_LEVELS.map((n) => [n, ""])),
  );

  // THE VERSION IN FORCE, resolved by app.resolve_grid_version through
  // public.current_grid_versions -- the same function the pay engine asks.
  // `versions[0]` was the newest row that EXISTS, which is a different
  // question and silently a different answer the moment anything is dated
  // ahead (§22, and item 147 schedules exactly such a row).
  const current = versions.find((v) => v.id === currentVersionId) ?? null;
  // A version dated ahead is neither current nor history: it is SCHEDULED,
  // and showing it in either of the other two would be the original bug with
  // a different label.
  const scheduled = current
    ? versions.filter((v) => v.effective_date > current.effective_date)
    : versions;
  const history = versions.filter(
    (v) => v.id !== currentVersionId && !scheduled.some((sv) => sv.id === v.id),
  );
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];
  const { isCorrected, correctionBadge } = correctionHelpers(versions, t);

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createTrainerGradeVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(describeError(result));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(GRADE_LEVELS.map((n) => [n, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_trainer_grades_title")} subtitle={t("section_trainer_grades_subtitle")}>
      <ScheduledVersions versions={scheduled} />

      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]} badge={correctionBadge(current)}>
          {GRADE_LEVELS.map((level) => (
            <Kv key={level} label={t("grade_level_label", { n: level })} value={currentRows.find((r) => r.grade_level === level)?.rate.toString() ?? "—"} />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      {canCorrect && current && (
        <CorrectVersion
          grid="trainer_grade"
          version={current}
          keys={GRADE_LEVELS.map(String)}
          labelFor={(k) => t("grade_level_label", { n: k })}
          valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.grade_level === Number(k))?.rate.toString() ?? ""}
        />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        badgeFor={correctionBadge}
        renderActions={(v) =>
          canCorrect && !isCorrected(v) ? (
            <CorrectVersion
              grid="trainer_grade"
              version={v}
              keys={GRADE_LEVELS.map(String)}
              labelFor={(k) => t("grade_level_label", { n: k })}
              valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.grade_level === Number(k))?.rate.toString() ?? ""}
            />
          ) : null
        }
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
  canCorrect,
  creatorNameById,
  versions,
  currentVersionId,
  rates,
}: {
  orgId: string;
  canCorrect: boolean;
  creatorNameById: Record<string, string>;
  versions: Version[];
  currentVersionId: string | null;
  rates: LocationRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const describeError = useDescribeError();
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(LOCATION_TIERS.map((tier) => [tier, ""])),
  );

  const tierLabel = (tier: string) => t(`tier_${tier}`);

  // THE VERSION IN FORCE, resolved by app.resolve_grid_version through
  // public.current_grid_versions -- the same function the pay engine asks.
  // `versions[0]` was the newest row that EXISTS, which is a different
  // question and silently a different answer the moment anything is dated
  // ahead (§22, and item 147 schedules exactly such a row).
  const current = versions.find((v) => v.id === currentVersionId) ?? null;
  // A version dated ahead is neither current nor history: it is SCHEDULED,
  // and showing it in either of the other two would be the original bug with
  // a different label.
  const scheduled = current
    ? versions.filter((v) => v.effective_date > current.effective_date)
    : versions;
  const history = versions.filter(
    (v) => v.id !== currentVersionId && !scheduled.some((sv) => sv.id === v.id),
  );
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];
  const { isCorrected, correctionBadge } = correctionHelpers(versions, t);

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createLocationBonusVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(describeError(result));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(LOCATION_TIERS.map((tier) => [tier, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_location_bonuses_title")} subtitle={t("section_location_bonuses_subtitle")}>
      <ScheduledVersions versions={scheduled} />

      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]} badge={correctionBadge(current)}>
          {LOCATION_TIERS.map((tier) => (
            <Kv key={tier} label={tierLabel(tier)} value={currentRows.find((r) => r.location_tier === tier)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      {canCorrect && current && (
        <CorrectVersion
          grid="location_bonus"
          version={current}
          keys={[...LOCATION_TIERS]}
          labelFor={tierLabel}
          valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.location_tier === k)?.bonus_percent.toString() ?? ""}
        />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        badgeFor={correctionBadge}
        renderActions={(v) =>
          canCorrect && !isCorrected(v) ? (
            <CorrectVersion
              grid="location_bonus"
              version={v}
              keys={[...LOCATION_TIERS]}
              labelFor={tierLabel}
              valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.location_tier === k)?.bonus_percent.toString() ?? ""}
            />
          ) : null
        }
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
  canCorrect,
  creatorNameById,
  versions,
  currentVersionId,
  rates,
}: {
  orgId: string;
  canCorrect: boolean;
  creatorNameById: Record<string, string>;
  versions: Version[];
  currentVersionId: string | null;
  rates: LanguageRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const describeError = useDescribeError();
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(LANGUAGE_GROUPS.map((g) => [g, ""])),
  );

  const groupLabel = (group: string) => t(`group_${group}`);

  // THE VERSION IN FORCE, resolved by app.resolve_grid_version through
  // public.current_grid_versions -- the same function the pay engine asks.
  // `versions[0]` was the newest row that EXISTS, which is a different
  // question and silently a different answer the moment anything is dated
  // ahead (§22, and item 147 schedules exactly such a row).
  const current = versions.find((v) => v.id === currentVersionId) ?? null;
  // A version dated ahead is neither current nor history: it is SCHEDULED,
  // and showing it in either of the other two would be the original bug with
  // a different label.
  const scheduled = current
    ? versions.filter((v) => v.effective_date > current.effective_date)
    : versions;
  const history = versions.filter(
    (v) => v.id !== currentVersionId && !scheduled.some((sv) => sv.id === v.id),
  );
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];
  const { isCorrected, correctionBadge } = correctionHelpers(versions, t);

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createLanguageBonusVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(describeError(result));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(LANGUAGE_GROUPS.map((g) => [g, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_language_bonuses_title")} subtitle={t("section_language_bonuses_subtitle")}>
      <ScheduledVersions versions={scheduled} />

      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]} badge={correctionBadge(current)}>
          {LANGUAGE_GROUPS.map((group) => (
            <Kv key={group} label={groupLabel(group)} value={currentRows.find((r) => r.language_group === group)?.bonus_percent.toString() ?? "—"} suffix="%" />
          ))}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      {canCorrect && current && (
        <CorrectVersion
          grid="language_bonus"
          version={current}
          keys={[...LANGUAGE_GROUPS]}
          labelFor={groupLabel}
          valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.language_group === k)?.bonus_percent.toString() ?? ""}
        />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        badgeFor={correctionBadge}
        renderActions={(v) =>
          canCorrect && !isCorrected(v) ? (
            <CorrectVersion
              grid="language_bonus"
              version={v}
              keys={[...LANGUAGE_GROUPS]}
              labelFor={groupLabel}
              valueFor={(versionId, k) => rates.find((r) => r.version_id === versionId && r.language_group === k)?.bonus_percent.toString() ?? ""}
            />
          ) : null
        }
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
  canCorrect,
  creatorNameById,
  versions,
  currentVersionId,
  rates,
}: {
  orgId: string;
  canCorrect: boolean;
  creatorNameById: Record<string, string>;
  versions: Version[];
  currentVersionId: string | null;
  rates: DurationRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const describeError = useDescribeError(keyLabel);
  const currentBandKeys = durationBandKeys(rates.filter((r) => r.version_id === currentVersionId));
  const formKeys = currentBandKeys.length > 0 ? currentBandKeys : DEFAULT_DURATION_KEYS;
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(formKeys.map((k) => [k, ""])),
  );

  function keyLabel(key: string) {
    const [minutes, context] = key.split(":");
    return `${t(`duration_${minutes}`)} — ${t(context === "standard" ? "context_standard" : "context_scoala_altfel")}`;
  }

  // THE VERSION IN FORCE, resolved by app.resolve_grid_version through
  // public.current_grid_versions -- the same function the pay engine asks.
  // `versions[0]` was the newest row that EXISTS, which is a different
  // question and silently a different answer the moment anything is dated
  // ahead (§22, and item 147 schedules exactly such a row).
  const current = versions.find((v) => v.id === currentVersionId) ?? null;
  // A version dated ahead is neither current nor history: it is SCHEDULED,
  // and showing it in either of the other two would be the original bug with
  // a different label.
  const scheduled = current
    ? versions.filter((v) => v.effective_date > current.effective_date)
    : versions;
  const history = versions.filter(
    (v) => v.id !== currentVersionId && !scheduled.some((sv) => sv.id === v.id),
  );
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];
  const { isCorrected, correctionBadge } = correctionHelpers(versions, t);

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createDurationMultiplierVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(describeError(result));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(formKeys.map((k) => [k, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_duration_multipliers_title")} subtitle={t("section_duration_multipliers_subtitle")}>
      <ScheduledVersions versions={scheduled} />

      {current ? (
        <CurrentVersionBox version={current} creatorName={creatorNameById[current.created_by]} badge={correctionBadge(current)}>
          {durationBandKeys(currentRows).map((key) => {
            const [minutes, context] = key.split(":");
            const row = currentRows.find((r) => r.duration_minutes === Number(minutes) && r.delivery_context === context);
            return <Kv key={key} label={keyLabel(key)} value={row?.multiplier.toString() ?? "—"} suffix="×" />;
          })}
        </CurrentVersionBox>
      ) : (
        <EmptyVersion />
      )}

      {canCorrect && current && (
        <CorrectVersion
          grid="duration_multiplier"
          version={current}
          keysFor={(versionId) => durationBandKeys(rates.filter((r) => r.version_id === versionId))}
          labelFor={keyLabel}
          valueFor={(versionId, k) => {
            const [minutes, context] = k.split(":");
            return rates.find((r) => r.version_id === versionId && r.duration_minutes === Number(minutes) && r.delivery_context === context)?.multiplier.toString() ?? "";
          }}
        />
      )}

      <HistoryToggle
        versions={history}
        creatorNameById={creatorNameById}
        badgeFor={correctionBadge}
        renderActions={(v) =>
          canCorrect && !isCorrected(v) ? (
            <CorrectVersion
              grid="duration_multiplier"
              version={v}
              keysFor={(versionId) => durationBandKeys(rates.filter((r) => r.version_id === versionId))}
              labelFor={keyLabel}
              valueFor={(versionId, k) => {
                const [minutes, context] = k.split(":");
                return rates.find((r) => r.version_id === versionId && r.duration_minutes === Number(minutes) && r.delivery_context === context)?.multiplier.toString() ?? "";
              }}
            />
          ) : null
        }
        renderRows={(versionId) =>
          durationBandKeys(rates.filter((r) => r.version_id === versionId)).map((key) => {
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
          {formKeys.map((key) => (
            <input
              key={key}
              type="number"
              step="0.01"
              value={values[key] ?? ""}
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
  currentVersionId,
  rates,
}: {
  orgId: string;
  creatorNameById: Record<string, string>;
  versions: Version[];
  currentVersionId: string | null;
  rates: UpliftRate[];
}) {
  const t = useTranslations(paymentConfigDict);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const describeError = useDescribeError();
  const [effectiveDate, setEffectiveDate] = useState(todayIso());
  const [note, setNote] = useState("");
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(CONTRACT_TYPES.map((ty) => [ty, ""])),
  );

  const typeLabel = (ty: string) => t(`type_${ty}`);

  // THE VERSION IN FORCE, resolved by app.resolve_grid_version through
  // public.current_grid_versions -- the same function the pay engine asks.
  // `versions[0]` was the newest row that EXISTS, which is a different
  // question and silently a different answer the moment anything is dated
  // ahead (§22, and item 147 schedules exactly such a row).
  const current = versions.find((v) => v.id === currentVersionId) ?? null;
  // A version dated ahead is neither current nor history: it is SCHEDULED,
  // and showing it in either of the other two would be the original bug with
  // a different label.
  const scheduled = current
    ? versions.filter((v) => v.effective_date > current.effective_date)
    : versions;
  const history = versions.filter(
    (v) => v.id !== currentVersionId && !scheduled.some((sv) => sv.id === v.id),
  );
  const currentRows = current ? rates.filter((r) => r.version_id === current.id) : [];

  function handleSubmit() {
    setError(null);
    setIsPending(true);
    createContractTypeUpliftVersion(orgId, effectiveDate, note, values).then((result: ActionResult) => {
      setIsPending(false);
      if (!result.ok) {
        setError(describeError(result));
      } else {
        setIsFormOpen(false);
        setValues(Object.fromEntries(CONTRACT_TYPES.map((ty) => [ty, ""])));
        setNote("");
      }
    });
  }

  return (
    <Section title={t("section_contract_type_uplifts_title")} subtitle={t("section_contract_type_uplifts_subtitle")}>
      <ScheduledVersions versions={scheduled} />

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
  badge,
  children,
}: {
  version: Version;
  creatorName: string | undefined;
  badge?: string | null;
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
      {badge && <p className="font-body mb-2 text-xs font-semibold text-amber-800">{badge}</p>}
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

// A version dated ahead. It is neither "current" (the engine is not using it)
// nor "history" (it has not been used), and before 202610260001 the screen
// had no third state -- it called the newest row current and the two
// disagreed silently.
//
// Rendered rather than hidden, because somebody deliberately entered it: a
// scheduled rate change that vanished from the screen would be the same
// class of failure pointed the other way.
function ScheduledVersions({ versions }: { versions: Version[] }) {
  const t = useTranslations(paymentConfigDict);
  const { locale } = useLocale();
  if (versions.length === 0) return null;
  return (
    <div className="mb-4 flex flex-col gap-1 rounded-xl border border-blue-200 bg-blue-50 px-4 py-3">
      <span className="font-body text-sm font-medium text-blue-900">
        {t("scheduled_banner", { n: versions.length })}
      </span>
      <ul className="font-body list-disc pl-4 text-xs text-blue-800">
        {versions.map((v) => (
          <li key={v.id}>
            {t("scheduled_from", {
              date: new Date(`${v.effective_date}T00:00:00Z`).toLocaleDateString(
                locale === "ro" ? "ro-RO" : "en-GB",
                { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" },
              ),
            })}
            {v.note ? ` — ${v.note}` : ""}
          </li>
        ))}
      </ul>
    </div>
  );
}

function HistoryToggle({
  versions,
  creatorNameById,
  renderRows,
  badgeFor,
  renderActions,
}: {
  versions: Version[];
  creatorNameById: Record<string, string>;
  renderRows: (versionId: string) => React.ReactNode;
  badgeFor?: (v: Version) => string | null;
  renderActions?: (v: Version) => React.ReactNode;
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
              {badgeFor?.(v) && <p className="font-body mb-2 text-xs font-semibold text-amber-800">{badgeFor(v)}</p>}
              <div className="flex flex-col">{renderRows(v.id)}</div>
              {v.note && <p className="font-body text-muted mt-2 text-xs italic">{v.note}</p>}
              {renderActions && <div className="mt-3">{renderActions(v)}</div>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// Correcting a version (item 195, 202611140001). Three steps, never two:
// edit the values -> read the impact statement the database computed -> confirm
// THAT statement (the button says its numbers, §21). If the pay it describes
// moved meanwhile, the database refuses and hands back the new statement,
// which replaces the old one on screen to be confirmed again.
// ============================================================================

function CorrectVersion({
  grid,
  version,
  keys,
  keysFor,
  labelFor,
  valueFor,
}: {
  grid: CorrectableGrid;
  version: Version;
  keys?: string[];
  keysFor?: (versionId: string) => string[];
  labelFor: (key: string) => string;
  valueFor: (versionId: string, key: string) => string;
}) {
  const t = useTranslations(paymentConfigDict);
  const fmt = useFormatters();
  const describe = useDescribeCorrectionError(labelFor);
  const fieldKeys = keys ?? keysFor?.(version.id) ?? [];
  const [isOpen, setIsOpen] = useState(false);
  const [values, setValues] = useState<Record<string, string>>({});
  const [note, setNote] = useState("");
  const [declaration, setDeclaration] = useState<Declaration | null>(null);
  const [stale, setStale] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isPending, setIsPending] = useState(false);

  function open() {
    setValues(Object.fromEntries(fieldKeys.map((k) => [k, valueFor(version.id, k)])));
    setNote("");
    setDeclaration(null);
    setStale(false);
    setError(null);
    setIsOpen(true);
  }

  // Any edit invalidates the statement: what gets confirmed must be what was computed.
  function edit(key: string, value: string) {
    setValues((prev) => ({ ...prev, [key]: value }));
    setDeclaration(null);
    setStale(false);
  }

  function preview() {
    setError(null);
    setIsPending(true);
    previewGridCorrection(grid, version.id, note, values).then((result) => {
      setIsPending(false);
      if (result.ok) {
        setDeclaration(result.declaration);
        setStale(false);
      } else if (result.error === "declaration_stale") {
        setDeclaration(result.declaration);
      } else {
        setError(describe(result));
      }
    });
  }

  function apply() {
    if (!declaration) return;
    setError(null);
    setIsPending(true);
    applyGridCorrection(grid, version.id, note, values, declaration).then((result) => {
      setIsPending(false);
      if (result.ok) {
        setIsOpen(false);
        setDeclaration(null);
      } else if (result.error === "declaration_stale") {
        setDeclaration(result.declaration);
        setStale(true);
      } else {
        setError(describe(result));
      }
    });
  }

  if (!isOpen) {
    return (
      <button
        type="button"
        onClick={open}
        className="font-body text-brand-pink w-fit rounded-full border border-brand-pink/40 px-4 py-1.5 text-xs font-bold tracking-wide uppercase"
      >
        {t("correct_version_button")}
      </button>
    );
  }

  const s = declaration?.summary;
  const frozenSlots = declaration?.frozen_summary.slots ?? 0;
  const confirmLabel = !s
    ? ""
    : (s.slots === 0
        ? t("decl_confirm_button_none")
        : t("decl_confirm_button", { sessions: fmt.sessionsShort(s.sessions), before: fmt.lei(s.total_before), after: fmt.lei(s.total_after) })) +
      (frozenSlots === 1 ? t("decl_confirm_frozen_suffix_one") : frozenSlots > 1 ? t("decl_confirm_frozen_suffix", { n: frozenSlots, de: fmt.de(frozenSlots) }) : "");

  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50/40 p-4">
      <h3 className="font-body text-muted mb-1 text-xs font-bold tracking-wide uppercase">
        {t("correct_form_title", { date: formatDate(version.effective_date, fmt.locale) })}
      </h3>
      <p className="font-body text-muted mb-3 text-xs">{t("correct_form_hint")}</p>
      {error && <p className="font-body text-ink mb-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">{error}</p>}
      <div className="grid grid-cols-1 gap-2.5 md:grid-cols-2">
        {fieldKeys.map((key) => (
          <label key={key} className="font-body text-muted flex flex-col gap-1 text-xs">
            {labelFor(key)}
            <input
              type="number"
              step="0.01"
              value={values[key] ?? ""}
              onChange={(e) => edit(key, e.target.value)}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
            />
          </label>
        ))}
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder={t("correct_note_placeholder")}
          rows={2}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:col-span-2"
        />
      </div>

      {declaration && (
        <div className="mt-4 flex flex-col gap-3 rounded-xl border border-black/5 bg-white p-4">
          {stale && <p className="font-body rounded-lg bg-orange-50 px-3 py-2 text-xs font-semibold text-orange-800">{t("decl_stale")}</p>}
          <DeclarationView declaration={declaration} />
        </div>
      )}

      <div className="mt-3 flex flex-wrap gap-2">
        {declaration ? (
          <button
            type="button"
            disabled={isPending}
            onClick={apply}
            className="font-body rounded-full bg-amber-700 px-4 py-1.5 text-xs font-bold text-white disabled:opacity-50"
          >
            {confirmLabel}
          </button>
        ) : (
          <button
            type="button"
            disabled={isPending}
            onClick={preview}
            className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase disabled:opacity-50"
          >
            {t("correct_preview_button")}
          </button>
        )}
        <button
          type="button"
          onClick={() => setIsOpen(false)}
          className="text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold uppercase"
        >
          {t("cancel")}
        </button>
      </div>
    </div>
  );
}

// The impact statement, exactly as the database computed it. Everything the
// person confirms is on this card: the unapproved pay that moves (by trainer
// and month, then slot by slot), and the approved pay that does NOT move,
// with what the corrected rate would have computed.
function DeclarationView({ declaration }: { declaration: Declaration }) {
  const t = useTranslations(paymentConfigDict);
  const fmt = useFormatters();
  const s = declaration.summary;
  const fs = declaration.frozen_summary;
  const date = (iso: string) => formatDate(iso, fmt.locale);

  return (
    <div className="flex flex-col gap-3">
      <span className="font-body text-muted text-xs font-bold tracking-wide uppercase">{t("decl_title")}</span>
      {s.slots === 0 ? (
        <p className="font-body text-ink text-sm">{t("decl_no_affected")}</p>
      ) : (
        <p className="font-body text-ink text-sm font-semibold">
          {t("decl_summary", {
            sessions: fmt.confirmedSessions(s.sessions),
            months: s.months.map(fmt.month).join(", "),
            before: fmt.lei(s.total_before),
            after: fmt.lei(s.total_after),
            delta: fmt.delta(s.delta),
          })}
        </p>
      )}
      {s.unpriceable_slots > 0 && (
        <p className="font-body text-xs font-semibold text-red-700">{t("error_unpriceable_suffix", { n: s.unpriceable_slots })}</p>
      )}

      {declaration.by_trainer_month.length > 0 && (
        <table className="font-body w-full text-xs">
          <thead>
            <tr className="text-muted text-left">
              <th className="py-1 font-semibold">{t("decl_col_month")}</th>
              <th className="py-1 font-semibold">{t("decl_col_trainer")}</th>
              <th className="py-1 text-right font-semibold">{t("decl_col_slots")}</th>
              <th className="py-1 text-right font-semibold">{t("decl_col_before")}</th>
              <th className="py-1 text-right font-semibold">{t("decl_col_after")}</th>
            </tr>
          </thead>
          <tbody>
            {declaration.by_trainer_month.map((row) => (
              <tr key={`${row.month}:${row.trainer_id}`} className="border-t border-black/5">
                <td className="py-1">{fmt.month(row.month)}</td>
                <td className="py-1">{row.trainer ?? t("unknown_user")}</td>
                <td className="py-1 text-right">{row.slots}</td>
                <td className="py-1 text-right">{fmt.lei(row.before)}</td>
                <td className="py-1 text-right font-semibold">{fmt.lei(row.after)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {declaration.affected.length > 0 && (
        <details className="font-body text-xs">
          <summary className="text-brand-pink cursor-pointer font-semibold">
            {declaration.affected.length === 1
              ? t("decl_sessions_toggle_one")
              : t("decl_sessions_toggle", { n: declaration.affected.length, de: fmt.de(declaration.affected.length) })}
          </summary>
          <ul className="mt-2 flex flex-col gap-1">
            {declaration.affected.map((a) => (
              <li key={`${a.session_id}:${a.slot}`} className="flex flex-wrap justify-between gap-x-3">
                <span>
                  {date(a.date)} · {a.client ?? "—"} · {a.trainer ?? t("unknown_user")}
                </span>
                <span>
                  {fmt.lei(a.before)} → <strong>{fmt.lei(a.after)}</strong>
                </span>
              </li>
            ))}
          </ul>
        </details>
      )}

      {fs.slots > 0 && (
        <div className="flex flex-col gap-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2">
          <p className="font-body text-xs font-semibold text-amber-900">
            {t(fs.slots === 1 ? "decl_frozen_heading_one" : "decl_frozen_heading", {
              n: fs.slots,
              de: fmt.de(fs.slots),
              frozen: fmt.lei(fs.frozen_total),
              would: fmt.lei(fs.would_be_total),
            })}
          </p>
          <ul className="font-body flex flex-col gap-1 text-xs text-amber-900">
            {declaration.frozen.map((f) => (
              <li key={`${f.session_id}:${f.slot}`} className="flex flex-wrap justify-between gap-x-3">
                <span>
                  {date(f.date)} · {f.client ?? "—"} · {f.trainer ?? t("unknown_user")}
                </span>
                <span>{t("decl_frozen_line", { frozen: fmt.lei(f.frozen), would: fmt.lei(f.would_be) })}</span>
              </li>
            ))}
          </ul>
          <p className="font-body text-xs text-amber-800">{t("decl_frozen_note")}</p>
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
