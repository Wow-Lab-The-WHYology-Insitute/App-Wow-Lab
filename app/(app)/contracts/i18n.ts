import type { Dictionary } from "@/lib/i18n";

// Shared between contracts-client.tsx and contract-detail-panel.tsx — one
// dictionary, not two, so a string can't drift out of sync between the
// list row and the expanded detail that shows the same field.
export const contractsDict: Dictionary = {
  page_title: { en: "Contracts", ro: "Contracte" },
  page_subtitle: {
    en: "Contract lifecycle by legal entity. Fiscal invoicing stays in SmartBill/SAGA.",
    ro: "Ciclul de viață al contractelor, pe entitate juridică. Facturarea fiscală rămâne în SmartBill/SAGA.",
  },
  search_placeholder: { en: "Search by client, entry or exit number…", ro: "Caută după client, nr. intrare sau ieșire…" },
  filter_type_all: { en: "All types", ro: "Toate tipurile" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },
  filter_entity_all: { en: "All entities", ro: "Toate entitățile" },
  new_contract: { en: "+ New contract", ro: "+ Contract nou" },
  columns: { en: "Columns", ro: "Coloane" },
  clear_all: { en: "Clear all", ro: "Șterge tot" },
  showing_count: { en: "Showing {{shown}} of {{total}} contracts", ro: "Afișare {{shown}} din {{total}} contracte" },
  empty_no_contracts: { en: "No contracts visible for your role.", ro: "Niciun contract vizibil pentru rolul tău." },
  empty_no_match: { en: "No contracts match your search or filters.", ro: "Niciun contract nu corespunde căutării sau filtrelor." },

  col_contract: { en: "Contract", ro: "Contract" },
  col_client: { en: "Client", ro: "Client" },
  col_type: { en: "Type", ro: "Tip" },
  col_term: { en: "Term", ro: "Perioadă" },
  col_entity: { en: "Entity", ro: "Entitate" },
  col_value: { en: "Value", ro: "Valoare" },

  term_ends_in: { en: "ends in {{n}} days", ro: "se termină în {{n}} zile" },
  term_ended_ago: { en: "ended {{n}} months ago", ro: "s-a terminat acum {{n}} luni" },
  term_starts_in: { en: "starts in {{n}} days", ro: "începe în {{n}} zile" },

  masked_label: { en: "Finance only", ro: "Doar Finance" },
  masked_title: { en: "Visible to Finance and the Owner", ro: "Vizibil pentru Finance și Owner" },

  // exit_number is the primary identifier (202608180002); a contract not
  // yet formally dispatched legitimately has none. {{client}} keeps the
  // fallback self-explanatory even out of the row's own context (a card
  // title, a detail page heading).
  no_exit_number: { en: "No exit number yet — {{client}}", ro: "Fără număr de ieșire — {{client}}" },

  demo_badge_label: { en: "Demo data", ro: "Date demo" },
  demo_badge_title: {
    en: "Example seed record — not a verified real contract.",
    ro: "Înregistrare demonstrativă — nu este un contract real, verificat.",
  },

  contract_type_recurring_annual: { en: "recurring annual", ro: "recurent anual" },
  contract_type_one_off_event: { en: "one-off event", ro: "eveniment unic" },
  contract_type_framework: { en: "framework", ro: "contract-cadru" },

  status_draft: { en: "draft", ro: "ciornă" },
  status_sent: { en: "sent", ro: "trimis" },
  status_signed: { en: "signed", ro: "semnat" },
  status_expired: { en: "expired", ro: "expirat" },
  status_renewed: { en: "renewed", ro: "reînnoit" },

  detail_legal_name: { en: "Legal name", ro: "Denumire legală" },
  detail_cui: { en: "CUI", ro: "CUI" },
  detail_entry_number: { en: "Entry number", ro: "Număr intrare" },
  detail_exit_number: { en: "Exit number", ro: "Număr ieșire" },
  detail_billing_rule: { en: "Billing rule", ro: "Regulă de facturare" },
  detail_signed_date: { en: "Signed date", ro: "Data semnării" },
  detail_estimated_value: { en: "Estimated value", ro: "Valoare estimată" },
  detail_previous_year_value: { en: "Previous year value", ro: "Valoare an anterior" },
  detail_legal_entity: { en: "Legal entity", ro: "Entitate juridică" },
  detail_drive_link: { en: "Drive archive", ro: "Arhivă Drive" },
  detail_notes: { en: "Notes", ro: "Note" },
  open_link: { en: "Open link", ro: "Deschide link" },
  open_contract: { en: "Open contract", ro: "Deschide contractul" },
  edit: { en: "Edit", ro: "Editează" },

  new_contract_form_title: { en: "New contract", ro: "Contract nou" },
  select_client: { en: "Select client…", ro: "Alege clientul…" },
  select_entity: { en: "Select legal entity…", ro: "Alege entitatea juridică…" },
  entry_number_placeholder: { en: "Entry number (optional)", ro: "Număr intrare (opțional)" },
  exit_number_placeholder: { en: "Exit number (optional)", ro: "Număr ieșire (opțional)" },
  start_date: { en: "Start Date", ro: "Data început" },
  end_date: { en: "End Date", ro: "Data sfârșit" },
  billing_rule_placeholder: {
    en: "Billing rule (e.g. 95 lei/child/session)",
    ro: "Regulă de facturare (ex. 95 lei/copil/ședință)",
  },
  signed_date_label: { en: "Signed Date", ro: "Data semnării" },
  estimated_value_placeholder: { en: "Estimated value (optional)", ro: "Valoare estimată (opțional)" },
  previous_year_value_placeholder: { en: "Previous year value (optional)", ro: "Valoare an anterior (opțional)" },
  create_contract: { en: "Create contract", ro: "Creează contractul" },
};
