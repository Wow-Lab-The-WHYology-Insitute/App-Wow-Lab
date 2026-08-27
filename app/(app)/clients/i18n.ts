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
};
