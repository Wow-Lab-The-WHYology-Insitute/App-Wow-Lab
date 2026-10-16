import type { Dictionary } from "@/lib/i18n";

// Shared between groups-client.tsx and group-detail-panel.tsx — same
// one-dictionary-not-two reasoning as contracts/i18n.ts and clients/i18n.ts.
export const groupsDict: Dictionary = {
  page_title: { en: "Groups & Enrollment", ro: "Grupe și înscrieri" },
  page_title_trainer_view: { en: "Your Groups", ro: "Grupele tale" },
  page_subtitle: {
    en: "Enrollment containers by client and module. Trainer allocation and delivery live on each group's workshops.",
    ro: "Containere de înscriere pe client și modul. Alocarea trainerilor și livrarea se află pe atelierele fiecărei grupe.",
  },
  page_subtitle_trainer_view: {
    en: "Groups containing at least one workshop allocated to you, as principal or secundar trainer.",
    ro: "Grupele care conțin cel puțin un atelier alocat ție, ca trainer principal sau secundar.",
  },
  search_placeholder: { en: "Search by client or trainer…", ro: "Caută după client sau trainer…" },
  filter_module_all: { en: "All modules", ro: "Toate modulele" },
  filter_format_all: { en: "All formats", ro: "Toate formatele" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },
  new_group: { en: "+ New group", ro: "+ Grupă nouă" },
  columns: { en: "Columns", ro: "Coloane" },
  clear_all: { en: "Clear all", ro: "Șterge tot" },
  showing_count: { en: "Showing {{shown}} of {{total}} groups", ro: "Afișare {{shown}} din {{total}} grupe" },
  // Covers the gap between the create form closing and the new row
  // actually appearing -- isPending ends before that, by construction
  // (Next resolves the action's return value before applying the
  // refreshed tree). Cleared when the row is detected, not on a timer.
  saving_row: { en: "Saving the group for {{name}}…", ro: "Se salvează grupa pentru {{name}}…" },
  empty_no_groups: { en: "No groups visible for your role.", ro: "Nicio grupă vizibilă pentru rolul tău." },
  empty_no_groups_trainer: { en: "You have no allocated groups yet.", ro: "Nu ai încă nicio grupă alocată." },
  empty_no_match: { en: "No groups match your search or filters.", ro: "Nicio grupă nu corespunde căutării sau filtrelor." },

  col_client: { en: "Client", ro: "Client" },
  col_module: { en: "Module", ro: "Modul" },
  col_schedule: { en: "Schedule", ro: "Program" },

  // The schedule control, labelled. Until 2026-10-12 it was two unlabelled
  // inputs -- and for the nine non-recurring formats one of them was a native
  // date picker whose value went into free text and produced nothing. A group
  // created 2026-09-25 still holds schedule_pattern = "2026-09-26 15:52" with
  // zero workshops behind it, which is what a date picker promises and this
  // field never delivered.
  schedule_recurring_label: { en: "Weekly rhythm", ro: "Ritmul săptămânal" },
  schedule_recurring_hint: {
    en: "The day and time this club runs each week. It describes the rhythm only — it does not create workshops.",
    ro: "Ziua și ora la care clubul se ține în fiecare săptămână. Descrie doar ritmul — nu creează ateliere.",
  },
  schedule_oneoff_label: { en: "Workshop date and time", ro: "Data și ora atelierului" },
  schedule_oneoff_hint: {
    en: "A one-off workshop happens on a date, so this is a date. Tick the box below and the workshop itself is created with the group.",
    ro: "Un atelier unic are loc la o dată anume, deci acesta este o dată. Bifează mai jos și atelierul se creează împreună cu grupa.",
  },
  create_first_workshop_label: {
    en: "Also create the first workshop on this date",
    ro: "Creează și primul atelier la această dată",
  },
  create_first_workshop_hint: {
    en: "One workshop, not a series. Everything else about it — trainers, length, location — is filled in afterwards.",
    ro: "Un singur atelier, nu o serie. Restul — traineri, durată, locație — se completează după.",
  },
  // Sublabels under the group info panel's Schedule row, so the field says
  // what it is where it is read, not only where it is typed.
  schedule_kv_hint_recurring: {
    en: "Weekly rhythm — creates no workshops on its own.",
    ro: "Ritm săptămânal — nu creează ateliere de la sine.",
  },
  schedule_edit_placeholder: {
    en: "e.g. Tuesday 16:00, or 2026-11-04 14:00",
    ro: "ex. Tuesday 16:00, sau 2026-11-04 14:00",
  },
  schedule_kv_hint_oneoff: {
    en: "Intended date. Workshops are listed below.",
    ro: "Data prevăzută. Atelierele sunt listate mai jos.",
  },
  first_workshop_created: {
    en: "Group created, and the first workshop with it.",
    ro: "Grupa a fost creată, împreună cu primul atelier.",
  },
  first_workshop_not_created: {
    en: "Group created. The date was not a date, so no workshop was created.",
    ro: "Grupa a fost creată. Data nu era o dată, deci nu s-a creat niciun atelier.",
  },
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
  // Module 14, added 2026-10-07 (item 105) once its six lesson plans
  // actually existed -- item 103 had recorded Vet as a module with zero
  // plans and a hidden sheet. Identical in both languages, the same rule
  // the other thirteen follow. Label mirrors its sibling `doctor`; the
  // source sheet's own "I want to be a VET" is not the house style.
  module_vet: { en: "I Wanna Be a Vet", ro: "I Wanna Be a Vet" },
  // Module 15, added 2026-10-12 (item 110) -- the set is now complete.
  // Anca closed the standing objection (its six plans are shared with
  // `doctor`) by confirming that a plan belonging to several modules is
  // the designed shape of this catalogue, not a duplicate. Label follows
  // `Modul ANATOMY` -> "Anatomy", the same rule `module_astronomy` used,
  // NOT its siblings doctor/vet -- their "I Wanna Be a ..." labels come
  // from their sheets literally being that phrase. Identical in both
  // languages, like every module label above.
  module_anatomy: { en: "Anatomy", ro: "Anatomy" },

  // Anca's nine workshop types (2026-09-21, item 79/85), replacing the
  // prior six-value working list, plus custom restored as a tenth on
  // 2026-09-25 (item 102). Keys are ASCII snake_case (Mihai's
  // instruction); labels carry the diacritics, RO and EN. scoala_altfel/
  // saptamana_verde keep their old keys unchanged -- same program, same
  // key, only the surrounding list was confirmed. "Recurring," wherever
  // this app distinguishes it (the resources caption, the create form's
  // schedule-pattern shape), means format_scoli_private_recurente ONLY --
  // not custom either.
  //
  // Școala Altfel and Săptămâna Verde are IDENTICAL in both languages on
  // purpose, and this is not an untranslated string. They are Ministry of
  // Education national programmes -- proper nouns, not descriptions.
  // "School Differently" and "Green Week" would name nothing a user could
  // look up, would not match the name on the school's own calendar or
  // contract, and read as two variants of one thing when they are two
  // distinct programmes the pay grid already treats as one shared x2.0
  // context. This is the same rule the thirteen module_* labels above
  // already follow, in mirror: those are English-origin proper nouns kept
  // in the Romanian UI. A proper noun has one name.
  format_scoala_altfel: { en: "Școala Altfel", ro: "Școala Altfel" },
  format_saptamana_verde: { en: "Săptămâna Verde", ro: "Săptămâna Verde" },
  format_wow_lab_party: { en: "Wow Lab Party", ro: "Wow Lab Party" },
  format_parteneriate_companii: { en: "Company partnerships", ro: "Parteneriate cu companii" },
  format_cursuri_deschise: { en: "Open courses", ro: "Cursuri deschise" },
  format_scoli_private_ocazionale: {
    en: "Private schools (occasional collaboration)",
    ro: "Școli private (colaborări ocazionale)",
  },
  format_scoli_private_recurente: {
    en: "Private schools (recurring collaboration)",
    ro: "Școli private (colaborări recurente)",
  },
  format_evenimente_mall: { en: "Mall events/presentations", ro: "Evenimente/prezentări la mall" },
  // EN was "Company parties" until 2026-09-25. Anca's Romanian uses the
  // English loanword "party" deliberately: this is the SAME product as
  // wow_lab_party, delivered at a company instead of for a child's
  // birthday. "Company parties" severed that link -- an English reader saw
  // "Company partnerships" / "Company parties" as the matched pair and
  // "Wow Lab Party" as unrelated, which is backwards.
  format_party_companii: { en: "Wow Lab Party at a company", ro: "Party în companii" },
  // The tenth type (item 102). Anca restored it 2026-09-25, four days
  // after 202609210006 dropped it for having zero live rows. "Custom" in
  // both languages -- it is the word she confirmed, it is already a
  // Romanian loanword, and it is the same label the pre-2026-09-21
  // six-value list carried. "Other" would be clearer English but it is
  // not what she said.
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

  open_group: { en: "View workshops", ro: "Vezi atelierele" },

  new_group_form_title: { en: "New group", ro: "Grupă nouă" },
  select_client: { en: "Select client…", ro: "Alege clientul…" },
  select_contract: { en: "No contract yet", ro: "Fără contract deocamdată" },
  select_module: { en: "Select module…", ro: "Alege modulul…" },
  select_format: { en: "Select delivery format…", ro: "Alege formatul de livrare…" },
  contract_option_no_exit: { en: "(no exit number yet)", ro: "(fără număr de ieșire încă)" },
  // Group-level (202609240003 -- moved off sessions, entered once at
  // group creation and on the group edit form, not per session). Same
  // vocabulary/keys as the payment-config language_bonus grid and the
  // sessions.language_group column this replaced.
  select_language: { en: "Select language…", ro: "Alege limba…" },
  language_ro_en: { en: "Romanian / English", ro: "Română / Engleză" },
  language_fr_de_es: { en: "French / German / Spanish", ro: "Franceză / Germană / Spaniolă" },
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

  // "nou", not "nouă". `atelier` is neuter: masculine agreement in the
  // singular, feminine in the plural ("ateliere ... noi"). The feminine form
  // here is residue from thinking in `sedinta`, which IS feminine -- both this
  // key and new_session_title below were written with it in ba5bac9, the
  // rename commit itself.
  new_session_button: { en: "+ New workshop", ro: "+ Atelier nou" },
  sessions_heading: { en: "Workshops ({{count}})", ro: "Ateliere ({{count}})" },
  empty_no_sessions: { en: "No workshops yet.", ro: "Niciun atelier încă." },
  empty_no_sessions_trainer: {
    en: "No workshops allocated to you in this group.",
    ro: "Niciun atelier alocat ție în această grupă.",
  },

  col_date: { en: "Date", ro: "Data" },
  col_principal: { en: "Principal", ro: "Principal" },
  col_secundar: { en: "Secundar", ro: "Secundar" },
  col_duration: { en: "Duration", ro: "Durată" },
  col_location: { en: "Location", ro: "Locație" },
  col_present: { en: "Present", ro: "Prezenți" },
  col_experiment_delivered: { en: "Experiment delivered", ro: "Experiment livrat" },
  open_action: { en: "Open", ro: "Deschide" },

  save: { en: "Save", ro: "Salvează" },
  cancel: { en: "Cancel", ro: "Anulează" },
  network_error: {
    en: "The change was not saved. Check your connection and try again.",
    ro: "Modificarea nu a fost salvată. Verifică conexiunea și încearcă din nou.",
  },
  // Lowercase inline row action, distinct from reallocate_button's
  // capitalized full-width mobile button.
  reallocate_action: { en: "reallocate", ro: "realocă" },
  reallocate_button: { en: "Reallocate", ro: "Realocă" },

  // Same pairing, for the assigned trainer's own attendance_count/
  // experiment_delivered edit (Anca's 2026-09-11 decision) -- a
  // separate action from reallocate_action, shown to a different
  // audience (the assigned trainer, not Operations), sometimes on the
  // same row. attendance_placeholder/experiment_placeholder below
  // (NewSessionForm's own, at session creation) are reused here rather
  // than duplicated -- same fields, same wording fits both contexts.
  record_attendance_action: { en: "record attendance", ro: "înregistrează prezența" },
  record_attendance_button: { en: "Record attendance", ro: "Înregistrează prezența" },

  // The trainer's own confirmation checkbox (Anca's 2026-09-12 decision)
  // -- distinct from detail_confirmed above, which labels the group-level
  // children_confirmed count, a different field entirely.
  session_confirmed_status: { en: "Confirmed", ro: "Confirmat" },
  session_not_confirmed_status: { en: "Not confirmed", ro: "Neconfirmat" },
  // The action-worded case: an empty checkbox on the assigned trainer's
  // own, not-yet-confirmed slot. Deliberately not "Not confirmed" --
  // that's a state word sitting next to a box that hasn't been touched
  // yet, easy to misread as if the box itself asserts the state rather
  // than performs the action.
  confirmation_check_to_confirm: { en: "Check to confirm", ro: "Bifează pentru a confirma" },
  confirmation_month_closed_error: {
    en: "This month is closed. You can no longer change your confirmation.",
    ro: "Luna este închisă. Nu îți mai poți modifica confirmarea.",
  },
  confirmation_not_assigned_error: {
    en: "Not permitted (requires being the assigned trainer for this workshop).",
    ro: "Nepermis (necesită să fii trainerul alocat acestui atelier).",
  },
  // Recording attendance shares confirmation_not_assigned_error above (the
  // wording fits both writes) but needs its own month-closed message --
  // "your confirmation" doesn't describe attendance.
  attendance_month_closed_error: {
    en: "This month is closed. You can no longer change attendance for this workshop.",
    ro: "Luna este închisă. Nu mai poți modifica prezența pentru acest atelier.",
  },
  // Dead-zone cover, same reasoning as saving_row above: isPending ends
  // before the revalidated sessions prop actually reflects the write, so
  // these replace the checkbox/value for that gap instead of letting it
  // flash back to a possibly-stale state with nothing pending-looking
  // about it.
  saving_confirmation: { en: "Saving…", ro: "Se salvează…" },
  saving_attendance: { en: "Saving…", ro: "Se salvează…" },

  mobile_principal_prefix: { en: "Principal: ", ro: "Principal: " },
  mobile_secundar_prefix: { en: "Secundar: ", ro: "Secundar: " },
  mobile_duration_prefix: { en: "Duration: ", ro: "Durată: " },
  mobile_location_prefix: { en: "Location: ", ro: "Locație: " },
  mobile_present_prefix: { en: "Present: ", ro: "Prezenți: " },
  mobile_experiment_prefix: { en: "Experiment: ", ro: "Experiment: " },

  new_session_title: { en: "New workshop", ro: "Atelier nou" },   // see new_session_button above
  trainer_principal_label: { en: "Trainer principal", ro: "Trainer principal" },
  trainer_secundar_label: { en: "Trainer secundar", ro: "Trainer secundar" },
  // location_tier stays on the session (unlike language, above -- it
  // genuinely varies with who's assigned, item 95/96 report). Entered
  // here, at the same moment as trainer allocation; sometimes pre-filled
  // from the principal's known home city, never auto-submitted.
  location_tier_label: { en: "Location (travel)", ro: "Locație (deplasare)" },
  location_tier_placeholder: { en: "Choose one…", ro: "Alege una…" },
  location_tier_bucuresti: { en: "Bucharest", ro: "București" },
  location_tier_imprejurimi: { en: "Surrounding areas", ro: "Împrejurimi" },
  location_tier_alte_orase: { en: "Other cities", ro: "Alte orașe" },
  // Shown only when the app pre-filled the value below from the
  // principal's home city -- makes clear this is a suggestion, not a
  // confirmed entry, so the person creating the session knows to check
  // it rather than assume it was already verified.
  location_tier_prefilled_hint: {
    en: "Auto-suggested from the trainer's home city — confirm or change.",
    ro: "Sugerat automat din orașul de domiciliu al trainerului — confirmă sau schimbă.",
  },
  attendance_placeholder: { en: "Attendance count (optional)", ro: "Număr prezenți (opțional)" },
  experiment_placeholder: { en: "Experiment delivered (optional)", ro: "Experiment livrat (opțional)" },
  // A number input since 202610160004/6 rather than a four-option select:
  // the real schedule has 45- and 50-minute classes, which the select could
  // not even record. The label now carries the unit, because a bare number
  // field does not say minutes the way "90 min" in an option did.
  duration_label: { en: "Length (minutes)", ro: "Durată (minute)" },
  duration_placeholder: { en: "e.g. 45", ro: "ex. 45" },
  experiment_drive_link_placeholder: {
    en: "Experiment Drive link (optional)",
    ro: "Link Drive experiment (opțional)",
  },
  create_session_button: { en: "Create workshop", ro: "Creează atelierul" },

  // group-header.tsx / group-info-section.tsx (page.tsx's own markup,
  // closing the gap bucket C left open). col_client/col_module/col_schedule
  // above are reused as Kv labels here -- same text, same field.
  back_link: { en: "← Groups", ro: "← Grupe" },
  section_group_info_title: { en: "Group info", ro: "Informații grupă" },
  kv_delivery_format: { en: "Delivery format", ro: "Format livrare" },
  kv_language: { en: "Language", ro: "Limbă" },
  kv_age_range: { en: "Age range", ro: "Interval de vârstă" },
  kv_calendar: { en: "School-year calendar", ro: "Calendar an școlar" },
  open_link: { en: "Open link", ro: "Deschide link" },
  kv_children_confirmed: { en: "Children confirmed (per contract)", ro: "Copii confirmați (per contract)" },
  // GroupEditForm's input, contracts.* holders only (Anca's 2026-09-11
  // decision) -- distinct from kv_children_confirmed above, which labels
  // the read-only display everyone with group access sees.
  children_confirmed_placeholder: {
    en: "Children confirmed (per contract)",
    ro: "Copii confirmați (per contract)",
  },
  kv_children_billed: { en: "Children billed", ro: "Copii facturați" },
  kv_notes: { en: "Notes", ro: "Note" },

  // Lesson-plan proposal and validation (item 117, Anca 2026-10-12). RO is the
  // operator-facing language here: the two people who use this screen daily
  // are a trainer and Catalina.
  plans_section_title: { en: "Experiments and validation", ro: "Experimente și validare" },
  plans_empty: {
    en: "No workshops yet — an experiment is chosen per workshop, per trainer.",
    ro: "Încă nu există ateliere — experimentul se alege pe atelier, pentru fiecare trainer.",
  },
  plans_slot_principal: { en: "Principal", ro: "Trainer Principal" },
  plans_slot_secundar: { en: "Secondary", ro: "Trainer Secundar" },
  plans_unassigned: { en: "No trainer allocated", ro: "Niciun trainer alocat" },
  plans_none_chosen: { en: "No experiment chosen", ro: "Niciun experiment ales" },
  plans_choose: { en: "Choose an experiment", ro: "Alege experimentul" },
  plans_change: { en: "Change", ro: "Schimbă" },
  plans_search_placeholder: {
    en: "Search by name, topic or file…",
    ro: "Caută după nume, temă sau fișier…",
  },
  plans_search_no_match: { en: "No experiment matches.", ro: "Niciun experiment nu corespunde." },
  // Shown when the search matched one of a plan's OTHER titles. 68 of 286
  // plans carry more than one, so without this a search for "DNA extraction"
  // returns a row labelled "Seeing DNA" and reads as broken.
  plans_matched_as: { en: "matched", ro: "găsit ca" },
  plans_not_written_yet: { en: "plan not written yet", ro: "plan nescris încă" },
  plans_status_proposed: { en: "Awaiting validation", ro: "Așteaptă validarea" },
  plans_status_validated: { en: "Validated", ro: "Validat" },
  plans_status_changes_requested: { en: "Changes requested", ro: "Modificări cerute" },
  plans_validate: { en: "Validate", ro: "Validează" },
  plans_request_changes: { en: "Request changes", ro: "Cere modificări" },
  plans_note_placeholder: { en: "What needs changing?", ro: "Ce trebuie schimbat?" },
  plans_decided_by: { en: "by", ro: "de" },
  plans_cancel: { en: "Cancel", ro: "Anulează" },
  plans_saving: { en: "Saving…", ro: "Se salvează…" },
  // Stated on the screen, not only in the schema: a session can be delivered
  // without validation and the record still stands.
  plans_no_validation_hint: {
    en: "Not validated. The record of what was delivered does not depend on it.",
    ro: "Nevalidat. Înregistrarea a ceea ce s-a livrat nu depinde de asta.",
  },
  kv_contract: { en: "Contract", ro: "Contract" },
  contract_none: { en: "No contract linked yet", ro: "Niciun contract legat încă" },
  contract_hidden: {
    en: "Linked (not visible to your role)",
    ro: "Legat (nevizibil pentru rolul tău)",
  },
  // Same shape as contract_hidden above -- a client is always linked
  // (groups.client_id is not null), the id just isn't resolvable under
  // the viewer's own RLS. Never falls back to the raw id (OPEN_ITEMS.md
  // item 66). Reused as-is for on_site_contact_id below (contact_hidden
  // would just repeat the identical phrase under a new key).
  client_hidden: { en: "Not visible to your role", ro: "Nevizibil pentru rolul tău" },

  // Item 52's one-off-workshop extension fields: time range, address,
  // on-site contact.
  kv_start_time: { en: "Start time", ro: "Ora de start" },
  kv_address: { en: "Address", ro: "Adresă" },
  // Shown only when the group has its own address override (not the
  // client's default) -- see page.tsx's addressIsOverride.
  address_override_hint: {
    en: "Overrides the client's own address",
    ro: "Suprascrie adresa clientului",
  },
  address_override_placeholder: {
    en: "Address (leave blank to use the client's own)",
    ro: "Adresă (lasă gol pentru adresa clientului)",
  },
  kv_onsite_contact: { en: "On-site contact", ro: "Persoană de contact la fața locului" },
  select_onsite_contact: {
    en: "No on-site contact",
    ro: "Fără persoană de contact la fața locului",
  },
  // Shown next to the edit form's contact picker when the client has no
  // contacts to choose from yet -- creating a new client_contacts row
  // needs clients.create/contracts.* (item 52's design record), which
  // groups.create holders (Operations) don't necessarily hold, so this
  // form deliberately only links, never creates.
  no_contacts_for_client_hint: {
    en: "This client has no contacts yet -- add one from the client's own page first.",
    ro: "Acest client nu are încă niciun contact -- adaugă unul din pagina clientului mai întâi.",
  },
  // Shown when a linked contact exists but its own contact_purpose isn't
  // 'trainer_facing' yet -- the link and that flag are deliberately
  // independent (202609210002), so linking alone doesn't make a contact
  // trainer-visible.
  contact_not_trainer_facing_hint: {
    en: "Not yet visible to trainers -- mark this contact \"trainer-facing\" on the client's own page first.",
    ro: "Încă nevizibil pentru traineri -- marchează acest contact „vizibil pentru traineri” din pagina clientului mai întâi.",
  },

  // group-info-section.tsx's edit form (updateGroup) -- mirrors
  // clients/i18n.ts and contracts/i18n.ts's own edit/save/cancel/notes
  // naming exactly, not invented fresh for this file.
  edit: { en: "Edit", ro: "Editează" },
  edit_group_title: { en: "Edit group", ro: "Editează grupa" },
  notes_placeholder: { en: "Notes (optional)", ro: "Note (opțional)" },

  // trainer-resources-section.tsx -- Anca's two links (2026-09). Own
  // labels, not the documents' own titles: this app translates its own
  // UI copy everywhere else, and these describe what's linked rather
  // than quote it -- the Google Form/Doc behind each link is untouched,
  // in whatever language it already is.
  resources_heading: { en: "Resources", ro: "Resurse" },
  resources_feedback_form_label: {
    en: "Post-workshop feedback form",
    ro: "Formular de feedback post-atelier",
  },
  resources_feedback_form_required: {
    en: "Required for this workshop.",
    ro: "Obligatoriu pentru acest atelier.",
  },
  // Rewritten 2026-09-21 (item 79/85) -- the old text named specific
  // examples ("Școala Altfel, Săptămâna Verde, corporate, parties") that
  // no longer match the nine-value vocabulary (there is no "corporate" or
  // "parties" value now). Rephrased around the actual rule instead of an
  // example list that would drift again the next time the vocabulary
  // does -- "one-off" here means "every delivery_format except
  // scoli_private_recurente" (trainer-resources-section.tsx).
  resources_feedback_form_optional: {
    en: "Required for one-off workshops — optional only for recurring private-school collaborations.",
    ro: "Obligatoriu pentru atelierele unice — opțional doar pentru colaborările recurente cu școli private.",
  },
  resources_responsibilities_label: {
    en: "Trainer responsibilities: principal vs secundar",
    ro: "Responsabilități trainer: principal vs secundar",
  },
  resources_responsibilities_caption: {
    en: "What the principal and secundar trainer are each responsible for.",
    ro: "Ce răspunde trainerul principal și ce răspunde trainerul secundar.",
  },
  resources_open_action: { en: "Open", ro: "Deschide" },
};
