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
  error_date_taken: {
    en: "A version with this effective date already exists. Choose another date.",
    ro: "Există deja o versiune cu această dată efectivă. Alege altă dată.",
  },
  error_missing_bands: {
    en: "A new version cannot drop rows the version it replaces has. Missing: {{list}}.",
    ro: "O versiune nouă nu poate pierde rânduri pe care le are versiunea pe care o înlocuiește. Lipsesc: {{list}}.",
  },
  // Says what the refusal protects, in money, or it reads as bureaucracy and
  // gets worked around (202611120001, item 194).
  error_would_change_confirmed_pay: {
    en: "Refused: this version would change the pay of {{sessions}} ({{months}}), from {{before}} to {{after}} lei ({{delta}}). Confirmed pay is not changed retroactively. Choose an effective date after the last confirmed session; if a rate already used was wrong, use “Correct this version” on the version in question.",
    ro: "Refuzat: această versiune ar schimba plata pentru {{sessions}} ({{months}}), de la {{before}} la {{after}} lei ({{delta}}). Plata unei sesiuni confirmate nu se schimbă retroactiv. Alege o dată efectivă de după ultima sesiune confirmată; dacă o rată deja folosită a fost greșită, folosește „Corectează această versiune” pe versiunea respectivă.",
  },
  sessions_one: {
    en: "one confirmed, not-yet-approved session",
    ro: "o sesiune deja confirmată și încă neaprobată",
  },
  sessions_many: {
    en: "{{n}} confirmed, not-yet-approved sessions",
    ro: "{{n}} {{de}}sesiuni deja confirmate și încă neaprobate",
  },
  sessions_short_one: { en: "1 session", ro: "1 sesiune" },
  sessions_short_many: { en: "{{n}} sessions", ro: "{{n}} {{de}}sesiuni" },
  error_unpriceable_suffix: {
    en: "{{n}} pay slot(s) would also become impossible to price.",
    ro: "{{n}} poziții de plată ar rămâne, în plus, fără preț.",
  },

  // Correcting a version (item 195, 202611140001). The statement is the
  // database's own; this copy only frames it. The confirm button carries the
  // statement's numbers (§21): what is confirmed is the statement, not "are
  // you sure?".
  correct_version_button: { en: "Correct this version", ro: "Corectează această versiune" },
  correct_form_title: {
    en: "Correction of the version effective from {{date}}",
    ro: "Corecție pentru versiunea efectivă din {{date}}",
  },
  correct_form_hint: {
    en: "A correction replaces this version's values for the same period, sessions already confirmed included. Nothing is written until you have read exactly which confirmed sessions change pay, and by how much, and confirmed that.",
    ro: "O corecție înlocuiește valorile acestei versiuni pentru aceeași perioadă, inclusiv pentru sesiunile deja confirmate. Nu se scrie nimic până nu citești exact ce sesiuni confirmate își schimbă plata, și cu cât, și confirmi asta.",
  },
  correct_note_placeholder: {
    en: "Why — who asked for it, and what was wrong",
    ro: "De ce — cine a cerut-o și ce era greșit",
  },
  correct_preview_button: { en: "Calculate the impact", ro: "Calculează impactul" },
  decl_title: {
    en: "What this correction changes — calculated by the same function that pays",
    ro: "Ce schimbă corecția — calculat de aceeași funcție care calculează plata",
  },
  decl_summary: {
    en: "{{sessions}} ({{months}}): from {{before}} to {{after}} lei ({{delta}}).",
    ro: "{{sessions}} ({{months}}): de la {{before}} la {{after}} lei ({{delta}}).",
  },
  decl_no_affected: {
    en: "No confirmed, not-yet-approved session changes pay.",
    ro: "Nicio sesiune confirmată și neaprobată nu își schimbă plata.",
  },
  decl_col_month: { en: "Month", ro: "Luna" },
  decl_col_trainer: { en: "Trainer", ro: "Trainer" },
  decl_col_slots: { en: "Slots", ro: "Poziții" },
  decl_col_before: { en: "Before", ro: "Înainte" },
  decl_col_after: { en: "After", ro: "După" },
  decl_sessions_toggle_one: { en: "Show the pay slot", ro: "Arată poziția de plată" },
  decl_sessions_toggle: { en: "Show the {{n}} pay slots, one by one", ro: "Arată cele {{n}} {{de}}poziții de plată, una câte una" },
  decl_frozen_heading_one: {
    en: "1 approved pay slot does NOT change: its amount was frozen at approval ({{frozen}} lei; at the corrected rate it would be {{would}} lei).",
    ro: "1 poziție de plată aprobată NU se schimbă: suma ei a fost înghețată la aprobare ({{frozen}} lei; cu rata corectată ar fi {{would}} lei).",
  },
  decl_frozen_heading: {
    en: "{{n}} approved pay slots do NOT change: their amount was frozen at approval ({{frozen}} lei; at the corrected rate it would be {{would}} lei).",
    ro: "{{n}} {{de}}poziții de plată aprobate NU se schimbă: suma lor a fost înghețată la aprobare ({{frozen}} lei; cu rata corectată ar fi {{would}} lei).",
  },
  decl_frozen_line: { en: "approved {{frozen}} lei; would be {{would}}", ro: "aprobat {{frozen}} lei; ar fi fost {{would}}" },
  decl_frozen_note: {
    en: "An approved amount changes only by withdrawing the approval first — and that path does not exist yet.",
    ro: "O sumă aprobată se schimbă doar retrăgând întâi aprobarea — iar drumul ăsta încă nu există.",
  },
  decl_confirm_button: {
    en: "Confirm the correction: {{sessions}}, {{before}} → {{after}} lei",
    ro: "Confirm corecția: {{sessions}}, {{before}} → {{after}} lei",
  },
  decl_confirm_button_none: {
    en: "Confirm the correction (no confirmed pay changes)",
    ro: "Confirm corecția (nu schimbă nicio plată confirmată)",
  },
  decl_confirm_frozen_suffix_one: { en: " · 1 approved stays unchanged", ro: " · 1 aprobată rămâne neschimbată" },
  decl_confirm_frozen_suffix: { en: " · {{n}} approved stay unchanged", ro: " · {{n}} {{de}}aprobate rămân neschimbate" },
  decl_stale: {
    en: "The impact changed while you were reading it — someone confirmed or approved a session, or a session changed. This is the new statement; read it and confirm again.",
    ro: "Impactul s-a schimbat cât timp îl citeai — cineva a confirmat sau a aprobat o sesiune, ori o sesiune s-a modificat. Aceasta e declarația nouă; citește-o și confirm-o din nou.",
  },
  correction_badge: {
    en: "Correction — replaces the earlier version with the same date",
    ro: "Corecție — înlocuiește versiunea anterioară cu aceeași dată",
  },
  corrected_badge: {
    en: "Replaced by a correction — no longer used",
    ro: "Înlocuită printr-o corecție — nu mai e folosită",
  },
  error_correction_forbidden: {
    en: "Correcting a version needs the approval capability.",
    ro: "Corectarea unei versiuni cere capabilitatea de aprobare.",
  },
  error_already_corrected: {
    en: "This version has already been corrected — correct the correction instead.",
    ro: "Versiunea a fost deja corectată — corectează corecția.",
  },
  error_version_not_found: {
    en: "This version no longer exists. Reload the page.",
    ro: "Versiunea nu mai există. Reîncarcă pagina.",
  },

  // Missing-grids banner: only rendered when at least one of the five
  // grids below has zero versions. Absent entirely once all five have a
  // version -- not a suppressed/empty version of the same box, so it
  // never becomes a warning someone learns to click past.
  // A version dated ahead of today. The screen now has three states where it
  // had two, because "current" is resolved by the pay engine's own function
  // (202610260001) rather than by taking the newest row -- so a row entered
  // early is visible AND is not mislabelled as the one being paid.
  scheduled_banner: {
    en: "{{n}} version(s) scheduled, not yet in use",
    ro: "{{n}} versiune/versiuni programate, încă nefolosite",
  },
  scheduled_from: { en: "From {{date}}", ro: "De la {{date}}" },
  missing_grids_banner_line: {
    en: "{{n}} of {{total}} grids below have no version yet:",
    ro: "{{n}} din {{total}} grile de mai jos nu au nicio versiune încă:",
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
    en: "Bonus percentage per tier. The tier itself is recorded per workshop by whoever enters it -- this grid only holds what each tier pays.",
    // "îl introduce": the thing being entered is `nivelul`, masculine. "o"
    // was agreeing with nothing in the sentence.
    ro: "Procentul de bonus per nivel. Nivelul se înregistrează per atelier de către cine îl introduce — grila asta ține doar cât plătește fiecare nivel.",
  },
  tier_bucuresti: { en: "Bucharest", ro: "București" },
  tier_imprejurimi: { en: "Surroundings", ro: "Împrejurimi" },
  tier_alte_orase: { en: "Other cities", ro: "Alte orașe" },
  bonus_percent_placeholder: { en: "Bonus (%)", ro: "Bonus (%)" },

  // 3. language_bonuses
  section_language_bonuses_title: { en: "Language bonuses", ro: "Bonusuri de limbă" },
  section_language_bonuses_subtitle: {
    en: "Bonus percentage per language group, recorded per workshop.",
    ro: "Procentul de bonus per grup de limbă, înregistrat per atelier.",
  },
  group_ro_en: { en: "Romanian or English", ro: "Română sau engleză" },
  group_fr_de_es: { en: "French, German, Spanish", ro: "Franceză, germană, spaniolă" },

  // 4. duration_multipliers
  section_duration_multipliers_title: { en: "Duration multipliers", ro: "Coeficienți de durată" },
  section_duration_multipliers_subtitle: {
    en: "Coefficient per workshop duration. 120 minutes has two rows -- standard, and the Scoala Altfel / Saptamana Verde exception, which uses ×2 instead of the standard ×1.5.",
    // "120 de minute au", plural subject.
    ro: "Coeficientul per durata atelierului. 120 de minute au două rânduri — standard, și excepția Școala Altfel / Săptămâna Verde, care folosește ×2 în loc de ×1.5 standard.",
  },
  duration_30: { en: "30 min", ro: "30 min" },
  duration_60: { en: "60 min", ro: "60 min" },
  duration_90: { en: "90 min", ro: "90 min" },
  duration_120: { en: "120 min", ro: "120 min" },
  context_standard: { en: "Standard", ro: "Standard" },
  context_scoala_altfel: { en: "Scoala Altfel / Saptamana Verde", ro: "Școala Altfel / Săptămâna Verde" },
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
