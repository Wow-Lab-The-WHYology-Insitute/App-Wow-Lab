import type { Dictionary } from "@/lib/i18n";

// Shared between clients-client.tsx and client-detail-panel.tsx — same
// one-dictionary-not-two reasoning as contracts/i18n.ts.
export const clientsDict: Dictionary = {
  page_title: { en: "Clients", ro: "Clienți" },
  page_subtitle: {
    en: "Operational client accounts. Sales pipeline stays in ActiveCampaign — this is the handoff point from “Won” onward.",
    ro: "Conturi operaționale de client. Pipeline-ul de vânzări rămâne în ActiveCampaign — acesta e punctul de preluare de la stadiul „Câștigat” înainte.",
  },
  search_placeholder: { en: "Search by name, legal name, or CUI…", ro: "Caută după nume, denumire legală sau CUI…" },
  filter_type_all: { en: "All types", ro: "Toate tipurile" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },
  new_client: { en: "+ New client", ro: "+ Client nou" },
  columns: { en: "Columns", ro: "Coloane" },
  clear_all: { en: "Clear all", ro: "Șterge tot" },
  showing_count: { en: "Showing {{shown}} of {{total}} clients", ro: "Afișare {{shown}} din {{total}} clienți" },
  empty_no_clients: { en: "No clients visible for your role.", ro: "Niciun client vizibil pentru rolul tău." },
  empty_no_match: { en: "No clients match your search or filters.", ro: "Niciun client nu corespunde căutării sau filtrelor." },

  col_client: { en: "Client", ro: "Client" },
  col_type: { en: "Type", ro: "Tip" },
  col_status: { en: "Status", ro: "Status" },
  col_entity: { en: "Entity", ro: "Entitate" },

  client_type_private_school: { en: "Private school", ro: "Școală privată" },
  client_type_state_school: { en: "State school", ro: "Școală de stat" },
  client_type_corporate: { en: "Corporate", ro: "Corporate" },
  client_type_parent_b2c: { en: "Parent B2C", ro: "Părinte B2C" },
  client_type_special_project: { en: "Special project", ro: "Proiect special" },

  status_prospect: { en: "Prospect", ro: "Prospect" },
  status_active: { en: "Active", ro: "Activ" },
  status_paused: { en: "Paused", ro: "Suspendat" },
  status_churned: { en: "Churned", ro: "Pierdut" },

  // Verb-form action labels on ClientStatusControl's transition buttons --
  // distinct from the status_* noun labels above (e.g. "Mark active" is the
  // button that moves a client TO active, not a display of its current
  // status).
  status_action_active: { en: "Mark active", ro: "Marchează activ" },
  status_action_paused: { en: "Pause", ro: "Suspendă" },
  status_action_churned: { en: "Mark churned", ro: "Marchează pierdut" },

  detail_business_line: { en: "Business line", ro: "Linie de business" },
  detail_legal_name: { en: "Legal name", ro: "Denumire legală" },
  detail_cui: { en: "CUI", ro: "CUI" },
  detail_added: { en: "Added", ro: "Adăugat" },
  no_entity_yet: { en: "No contracts yet", ro: "Fără contracte încă" },

  open_client: {
    en: "View contacts & contracts",
    ro: "Vezi contactele și contractele",
  },

  new_client_form_title: { en: "New client", ro: "Client nou" },
  name_placeholder: { en: "Client name", ro: "Numele clientului" },
  business_line_placeholder: { en: "Business line (optional)", ro: "Linie de business (opțional)" },
  legal_name_placeholder: { en: "Legal name (optional)", ro: "Denumire legală (opțional)" },
  cui_placeholder: { en: "CUI (optional)", ro: "CUI (opțional)" },
  create_client: { en: "Create client", ro: "Creează clientul" },

  // client-info-client.tsx (detail page's own "Client info" card, distinct
  // from the create-form fields above -- e.g. edit_name_placeholder is
  // "Name", not name_placeholder's "Client name", matching this edit form's
  // actual pre-existing text rather than unifying it with the create form's).
  client_info_title: { en: "Client info", ro: "Informații client" },
  edit_client_title: { en: "Edit client", ro: "Editează clientul" },
  detail_external_crm_ref: { en: "External CRM ref", ro: "Referință CRM externă" },
  detail_billed_via: { en: "Billed via", ro: "Facturat prin" },
  detail_notes: { en: "Notes", ro: "Note" },
  edit: { en: "Edit", ro: "Editează" },
  edit_name_placeholder: { en: "Name", ro: "Nume" },
  notes_placeholder: { en: "Notes (optional)", ro: "Note (opțional)" },
  external_crm_ref_placeholder: {
    en: "External CRM ref (ActiveCampaign)",
    ro: "Referință CRM externă (ActiveCampaign)",
  },
  crm_ref_locked_prefix: { en: "External CRM ref: ", ro: "Referință CRM externă: " },
  crm_ref_locked_suffix: {
    en: " — your role can't edit the CRM link, so this form leaves it untouched.",
    ro: " — rolul tău nu poate edita linkul CRM, așa că acest formular îl lasă neschimbat.",
  },
  save: { en: "Save", ro: "Salvează" },
  cancel: { en: "Cancel", ro: "Anulează" },

  // client-contacts-client.tsx
  contacts_heading: { en: "Contacts ({{count}})", ro: "Contacte ({{count}})" },
  new_contact_button: { en: "+ New contact", ro: "+ Contact nou" },
  empty_no_contacts: { en: "No contacts on file.", ro: "Niciun contact înregistrat." },
  create_contact: { en: "Create contact", ro: "Creează contactul" },
  confirm_delete: { en: "Confirm delete", ro: "Confirmă ștergerea" },
  delete_confirm_prefix: { en: "Delete ", ro: "Șterge " },
  delete_confirm_suffix: { en: "? This cannot be undone.", ro: "? Nu poate fi anulat." },

  // Matches the client_contacts.contact_purpose check constraint
  // (202608160002) exactly.
  contact_purpose_signing_authority: { en: "Signing authority", ro: "Autoritate de semnătură" },
  contact_purpose_trainer_facing: { en: "Trainer-facing", ro: "Interfață cu trainerul" },
  contact_purpose_finance_facing: { en: "Finance-facing", ro: "Interfață cu Finance" },
  contact_purpose_general: { en: "General", ro: "General" },

  badge_primary: { en: "Primary", ro: "Principal" },
  badge_billing_contact: { en: "Billing contact", ro: "Contact de facturare" },
  // Lowercase in the UI on purpose (small inline row actions), distinct
  // from the capitalized "Edit"/edit key used as a section-header action.
  contact_edit_action: { en: "edit", ro: "editează" },
  contact_delete_action: { en: "delete", ro: "șterge" },

  full_name_placeholder: { en: "Full name", ro: "Nume complet" },
  role_at_client_placeholder: { en: "Role at client (optional)", ro: "Rol la client (opțional)" },
  email_placeholder: { en: "Email (optional)", ro: "Email (opțional)" },
  phone_placeholder: { en: "Phone (optional)", ro: "Telefon (opțional)" },

  // client-header.tsx / client-contracts-section.tsx (page.tsx's own
  // markup, closing the gap bucket C left open).
  back_link: { en: "← Clients", ro: "← Clienți" },
  // Parallel to contacts_heading above -- "this client's contracts",
  // distinct from contractsDict's own empty_no_contracts ("no contracts
  // visible for your role" -- an RLS framing, not "this client has none").
  contracts_heading: { en: "Contracts ({{count}})", ro: "Contracte ({{count}})" },
  empty_no_contracts_on_file: { en: "No contracts on file.", ro: "Niciun contract înregistrat." },
};
