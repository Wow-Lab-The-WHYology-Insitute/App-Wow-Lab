import type { Dictionary } from "@/lib/i18n";

// Shared between page.tsx's client leaf and payment-config-client.tsx --
// one dictionary for the whole route, same as every other domain's single
// i18n.ts. Covers five grids (trainer_grades, location_bonuses,
// language_bonuses, duration_multipliers, contract_type_uplifts) --
// trainer_grade_assignments has no section here on purpose (SAD Sec12:
// it's per-contract data, belongs on the trainer contract, not on this
// page).
export const paymentConfigDict: Dictionary = {
  page_title: { en: "Payment configuration", ro: "Configurare plăți" },
  page_subtitle: {
    en: "The values the trainer payment formula resolves from. Every grid is versioned by effective date -- changing a value creates a new version, it never edits history.",
    ro: "Valorile din care se rezolvă formula de plată a trainerilor. Fiecare grilă e versionată pe dată efectivă — o schimbare de valoare creează o versiune nouă, nu editează istoricul.",
  },

  // Shared across all five sections.
  current_version_title: { en: "Current version", ro: "Versiunea curentă" },
  effective_from_label: { en: "Effective from", ro: "Efectivă din" },
  created_by_label: { en: "Created by", ro: "Creat de" },
  history_title: { en: "History", ro: "Istoric" },
  history_toggle_show: { en: "Show history ({{count}})", ro: "Arată istoricul ({{count}})" },
  history_toggle_hide: { en: "Hide history", ro: "Ascunde istoricul" },
  empty_no_version: { en: "No version exists yet.", ro: "Nu există nicio versiune încă." },
  new_version_button: { en: "+ New version", ro: "+ Versiune nouă" },
  new_version_form_title: { en: "New version", ro: "Versiune nouă" },
  effective_date_label: { en: "Effective date", ro: "Data efectivă" },
  note_placeholder: { en: "Note (optional)", ro: "Notă (opțional)" },
  create_version_button: { en: "Create version", ro: "Creează versiunea" },
  cancel: { en: "Cancel", ro: "Anulează" },
  unknown_user: { en: "Unknown", ro: "Necunoscut" },

  // Curated, user-facing error copy -- deliberately NOT the resolver's or
  // Postgres's own error text (that stays English, developer-facing, per
  // Sec12.9). The action layer returns a stable error code; this is the
  // only place that code gets turned into something a Finance user reads.
  error_incomplete_form: {
    en: "Enter every value before creating the version -- an incomplete version can never be corrected by editing, only by creating another one.",
    ro: "Completează toate valorile înainte de a crea versiunea — o versiune incompletă nu poate fi corectată prin editare, doar prin crearea alteia.",
  },
  error_save_failed: {
    en: "Could not save this version. Check the values and try again.",
    ro: "Versiunea nu a putut fi salvată. Verifică valorile și încearcă din nou.",
  },

  // 1. trainer_grades
  section_trainer_grades_title: { en: "Trainer grades", ro: "Grade traineri" },
  section_trainer_grades_subtitle: {
    en: "Net hourly rate per grade level (1-6). Feeds trainer_contracts.initial_grade_level and every trainer's progression.",
    ro: "Tariful net pe oră per nivel de grad (1-6). Alimentează trainer_contracts.initial_grade_level și progresia fiecărui trainer.",
  },
  grade_level_label: { en: "Grade {{n}}", ro: "Gradul {{n}}" },
  rate_placeholder: { en: "Net rate (lei/hour)", ro: "Tarif net (lei/oră)" },

  // 2. location_bonuses
  section_location_bonuses_title: { en: "Location bonuses", ro: "Bonusuri de locație" },
  section_location_bonuses_subtitle: {
    en: "Bonus percentage per tier. The tier itself is recorded per session by whoever enters it -- this grid only holds what each tier pays.",
    ro: "Procentul de bonus per nivel. Nivelul se înregistrează per sesiune de către cine o introduce — grila asta ține doar cât plătește fiecare nivel.",
  },
  tier_bucuresti: { en: "Bucharest", ro: "București" },
  tier_imprejurimi: { en: "Surroundings", ro: "Împrejurimi" },
  tier_alte_orase: { en: "Other cities", ro: "Alte orașe" },
  bonus_percent_placeholder: { en: "Bonus (%)", ro: "Bonus (%)" },

  // 3. language_bonuses
  section_language_bonuses_title: { en: "Language bonuses", ro: "Bonusuri de limbă" },
  section_language_bonuses_subtitle: {
    en: "Bonus percentage per language group, recorded per session.",
    ro: "Procentul de bonus per grup de limbă, înregistrat per sesiune.",
  },
  group_ro_en: { en: "Romanian or English", ro: "Română sau engleză" },
  group_fr_de_es: { en: "French, German, Spanish", ro: "Franceză, germană, spaniolă" },

  // 4. duration_multipliers
  section_duration_multipliers_title: { en: "Duration multipliers", ro: "Coeficienți de durată" },
  section_duration_multipliers_subtitle: {
    en: "Coefficient per session duration. 120 minutes has two rows -- standard, and the Scoala Altfel / Saptamana Verde exception, which uses ×2 instead of the standard ×1.5.",
    ro: "Coeficientul per durata sesiunii. 120 de minute are două rânduri — standard, și excepția Școala Altfel / Săptămâna Verde, care folosește ×2 în loc de ×1.5 standard.",
  },
  duration_30: { en: "30 min", ro: "30 min" },
  duration_60: { en: "60 min", ro: "60 min" },
  duration_90: { en: "90 min", ro: "90 min" },
  duration_120: { en: "120 min", ro: "120 min" },
  context_standard: { en: "Standard", ro: "Standard" },
  context_extended: {
    en: "120 min — Scoala Altfel / Saptamana Verde (×2 exception)",
    ro: "120 min — Școala Altfel / Săptămâna Verde (excepția ×2)",
  },
  multiplier_placeholder: { en: "Multiplier", ro: "Coeficient" },

  // 5. contract_type_uplifts
  section_contract_type_uplifts_title: { en: "Contract type uplifts", ro: "Uplift pe tip de contract" },
  section_contract_type_uplifts_subtitle: {
    en: "Uplift percentage on top of the net grid. One net grid (trainer_grades), plus this percentage per contract type -- not duplicate grids per type.",
    ro: "Procentul de uplift peste grila netă. O singură grilă netă (trainer_grades), plus acest procent per tip de contract — nu grile duplicate per tip.",
  },
  type_pfa: { en: "PFA", ro: "PFA" },
  type_srl: { en: "SRL", ro: "SRL" },
  type_drepturi_autor: { en: "Copyright (drepturi de autor)", ro: "Drepturi de autor" },
  uplift_percent_placeholder: { en: "Uplift (%)", ro: "Uplift (%)" },
};
