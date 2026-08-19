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
};
