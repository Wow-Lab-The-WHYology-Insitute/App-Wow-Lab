import type { Dictionary } from "@/lib/i18n";

// Shared between groups-client.tsx and group-detail-panel.tsx — same
// one-dictionary-not-two reasoning as contracts/i18n.ts and clients/i18n.ts.
export const groupsDict: Dictionary = {
  page_title: { en: "Groups & Enrollment", ro: "Grupe și înscrieri" },
  page_title_trainer_view: { en: "Your Groups", ro: "Grupele tale" },
  page_subtitle: {
    en: "Enrollment containers by client and module. Trainer allocation and delivery live on each group's sessions.",
    ro: "Containere de înscriere pe client și modul. Alocarea trainerilor și livrarea se află pe sesiunile fiecărei grupe.",
  },
  page_subtitle_trainer_view: {
    en: "Groups containing at least one session allocated to you, as principal or secundar trainer.",
    ro: "Grupele care conțin cel puțin o sesiune alocată ție, ca trainer principal sau secundar.",
  },
  search_placeholder: { en: "Search by client or trainer…", ro: "Caută după client sau trainer…" },
  filter_module_all: { en: "All modules", ro: "Toate modulele" },
  filter_format_all: { en: "All formats", ro: "Toate formatele" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },
  new_group: { en: "+ New group", ro: "+ Grupă nouă" },
  columns: { en: "Columns", ro: "Coloane" },
  clear_all: { en: "Clear all", ro: "Șterge tot" },
  showing_count: { en: "Showing {{shown}} of {{total}} groups", ro: "Afișare {{shown}} din {{total}} grupe" },
  empty_no_groups: { en: "No groups visible for your role.", ro: "Nicio grupă vizibilă pentru rolul tău." },
  empty_no_groups_trainer: { en: "You have no allocated groups yet.", ro: "Nu ai încă nicio grupă alocată." },
  empty_no_match: { en: "No groups match your search or filters.", ro: "Nicio grupă nu corespunde căutării sau filtrelor." },

  col_client: { en: "Client", ro: "Client" },
  col_module: { en: "Module", ro: "Modul" },
  col_schedule: { en: "Schedule", ro: "Program" },
  col_trainers: { en: "Trainers", ro: "Traineri" },
  col_enrollment: { en: "Enrollment", ro: "Înscriere" },
  col_status: { en: "Status", ro: "Status" },

  module_gaga: { en: "GAGA", ro: "GAGA" },
  module_green_energy: { en: "Green Energy", ro: "Green Energy" },
  module_wow_mix: { en: "Wow Lab Mix", ro: "Wow Lab Mix" },
  module_tiktok: { en: "Wow TikTok Science", ro: "Wow TikTok Science" },
  module_food_science: { en: "Wow Food Science", ro: "Wow Food Science" },
  module_lotions: { en: "Wow Lotions and Potions", ro: "Wow Lotions and Potions" },
  module_magic_physics: { en: "Magic of Physics", ro: "Magic of Physics" },
  module_chem_me: { en: "Chemistry for Me", ro: "Chemistry for Me" },
  module_chem_hs: { en: "Chemistry for Highschool", ro: "Chemistry for Highschool" },
  module_lights: { en: "Lights and Colours", ro: "Lights and Colours" },
  module_detective: { en: "Detective Science", ro: "Detective Science" },
  module_astronomy: { en: "Astronomy", ro: "Astronomy" },
  module_doctor: { en: "I Wanna Be a Doctor", ro: "I Wanna Be a Doctor" },

  format_recurring: { en: "Recurring (school club)", ro: "Recurent (club școlar)" },
  format_scoala_altfel: { en: "Școala Altfel", ro: "Școala Altfel" },
  format_saptamana_verde: { en: "Săptămâna Verde", ro: "Săptămâna Verde" },
  format_party: { en: "Party", ro: "Party" },
  format_corporate: { en: "Corporate", ro: "Corporate" },
  format_custom: { en: "Custom", ro: "Custom" },

  status_active: { en: "Active", ro: "Activă" },
  status_paused: { en: "Paused", ro: "Suspendată" },
  status_ended: { en: "Ended", ro: "Încheiată" },

  detail_legal_name: { en: "Legal name", ro: "Denumire legală" },
  detail_trainer_principal: { en: "Trainer — Principal", ro: "Trainer — Principal" },
  detail_trainer_secundar: { en: "Trainer — Secundar", ro: "Trainer — Secundar" },
  detail_confirmed: { en: "Confirmed", ro: "Confirmați" },
  detail_billed: { en: "Billed", ro: "Facturați" },
  no_trainer: { en: "Unassigned", ro: "Nealocat" },
  // Distinct from no_trainer: a trainer IS assigned, but has neither a
  // first/last name nor a usable full_name -- displayName() (page.tsx)
  // returns "" for this case specifically so it can't be confused with
  // "no trainer assigned at all" (null). Part of removing email as a
  // display-name fallback (users field-masking prep) -- unreachable with
  // today's real data (all 4 previously-unnamed trainer/senior_trainer
  // accounts were backfilled in 202608200002), kept as a forward-looking
  // non-PII placeholder for any future account invited without a name.
  unnamed_user: { en: "Unnamed user", ro: "Utilizator fără nume" },

  open_group: { en: "View sessions", ro: "Vezi sesiunile" },

  new_group_form_title: { en: "New group", ro: "Grupă nouă" },
  select_client: { en: "Select client…", ro: "Alege clientul…" },
  status_label: { en: "Status", ro: "Status" },
  age_range_placeholder: { en: "Age range (e.g. 6-9 ani — optional)", ro: "Interval de vârstă (ex. 6-9 ani — opțional)" },
  calendar_link_placeholder: {
    en: "School-year calendar link (optional)",
    ro: "Link calendar an școlar (opțional)",
  },
  create_group: { en: "Create group", ro: "Creează grupa" },

  // group-detail-client.tsx (the sessions sub-section). Matches the
  // sessions.status check constraint (202608160004) exactly.
  session_status_planned: { en: "Planned", ro: "Planificată" },
  session_status_confirmed: { en: "Confirmed", ro: "Confirmată" },
  session_status_delivered: { en: "Delivered", ro: "Livrată" },
  session_status_cancelled: { en: "Cancelled", ro: "Anulată" },

  new_session_button: { en: "+ New session", ro: "+ Sesiune nouă" },
  sessions_heading: { en: "Sessions ({{count}})", ro: "Sesiuni ({{count}})" },
  empty_no_sessions: { en: "No sessions yet.", ro: "Nicio sesiune încă." },
  empty_no_sessions_trainer: {
    en: "No sessions allocated to you in this group.",
    ro: "Nicio sesiune alocată ție în această grupă.",
  },

  col_date: { en: "Date", ro: "Data" },
  col_principal: { en: "Principal", ro: "Principal" },
  col_secundar: { en: "Secundar", ro: "Secundar" },
  col_duration: { en: "Duration", ro: "Durată" },
  col_present: { en: "Present", ro: "Prezenți" },
  col_experiment_delivered: { en: "Experiment delivered", ro: "Experiment livrat" },
  open_action: { en: "Open", ro: "Deschide" },

  save: { en: "Save", ro: "Salvează" },
  cancel: { en: "Cancel", ro: "Anulează" },
  // Lowercase inline row action, distinct from reallocate_button's
  // capitalized full-width mobile button.
  reallocate_action: { en: "reallocate", ro: "realocă" },
  reallocate_button: { en: "Reallocate", ro: "Realocă" },

  mobile_principal_prefix: { en: "Principal: ", ro: "Principal: " },
  mobile_secundar_prefix: { en: "Secundar: ", ro: "Secundar: " },
  mobile_duration_prefix: { en: "Duration: ", ro: "Durată: " },
  mobile_present_prefix: { en: "Present: ", ro: "Prezenți: " },
  mobile_experiment_prefix: { en: "Experiment: ", ro: "Experiment: " },

  new_session_title: { en: "New session", ro: "Sesiune nouă" },
  trainer_principal_label: { en: "Trainer principal", ro: "Trainer principal" },
  trainer_secundar_label: { en: "Trainer secundar", ro: "Trainer secundar" },
  attendance_placeholder: { en: "Attendance count (optional)", ro: "Număr prezenți (opțional)" },
  experiment_placeholder: { en: "Experiment delivered (optional)", ro: "Experiment livrat (opțional)" },
  duration_placeholder: { en: "Duration (optional)", ro: "Durată (opțional)" },
  experiment_drive_link_placeholder: {
    en: "Experiment Drive link (optional)",
    ro: "Link Drive experiment (opțional)",
  },
  create_session_button: { en: "Create session", ro: "Creează sesiunea" },

  // group-header.tsx / group-info-section.tsx (page.tsx's own markup,
  // closing the gap bucket C left open). col_client/col_module/col_schedule
  // above are reused as Kv labels here -- same text, same field.
  back_link: { en: "← Groups", ro: "← Grupe" },
  section_group_info_title: { en: "Group info", ro: "Informații grupă" },
  kv_delivery_format: { en: "Delivery format", ro: "Format livrare" },
  kv_age_range: { en: "Age range", ro: "Interval de vârstă" },
  kv_calendar: { en: "School-year calendar", ro: "Calendar an școlar" },
  open_link: { en: "Open link", ro: "Deschide link" },
  kv_children_confirmed: { en: "Children confirmed (per contract)", ro: "Copii confirmați (per contract)" },
  kv_children_billed: { en: "Children billed", ro: "Copii facturați" },
  kv_notes: { en: "Notes", ro: "Note" },
};
