import type { Dictionary } from "@/lib/i18n";

// Shared between suppliers-client.tsx and the [id] detail/edit client —
// one dictionary, not two, same convention as clientsDict/contractsDict.
export const suppliersDict: Dictionary = {
  page_title: { en: "Suppliers", ro: "Furnizori" },
  access_denied_heading: { en: "Access denied", ro: "Acces interzis" },
  access_denied_not_signed_in: { en: "Not signed in.", ro: "Nu ești autentificat." },
  access_denied_not_found: {
    en: "Supplier not found, or not visible to your role.",
    ro: "Furnizorul nu a fost găsit sau nu este vizibil pentru rolul tău.",
  },
  page_subtitle: {
    en: "External vendors under contract — accounting, IT, marketing, and similar services.",
    ro: "Furnizori externi sub contract — contabilitate, IT, marketing și servicii similare.",
  },
  search_placeholder: { en: "Search by name, legal name, or CUI…", ro: "Caută după nume, denumire legală sau CUI…" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },
  new_supplier: { en: "+ New supplier", ro: "+ Furnizor nou" },
  clear_all: { en: "Clear all", ro: "Șterge tot" },
  showing_count: { en: "Showing {{shown}} of {{total}} suppliers", ro: "Afișare {{shown}} din {{total}} furnizori" },
  empty_no_suppliers: { en: "No suppliers visible for your role.", ro: "Niciun furnizor vizibil pentru rolul tău." },
  empty_no_match: { en: "No suppliers match your search or filters.", ro: "Niciun furnizor nu corespunde căutării sau filtrelor." },

  col_supplier: { en: "Supplier", ro: "Furnizor" },
  col_service_type: { en: "Service type", ro: "Tip serviciu" },
  col_status: { en: "Status", ro: "Status" },

  status_active: { en: "active", ro: "activ" },
  status_inactive: { en: "inactive", ro: "inactiv" },

  detail_legal_name: { en: "Legal name", ro: "Denumire legală" },
  detail_cui: { en: "CUI", ro: "CUI" },
  detail_service_type: { en: "Service type", ro: "Tip serviciu" },
  detail_notes: { en: "Notes", ro: "Note" },
  edit: { en: "Edit", ro: "Editează" },

  name_placeholder: { en: "Name", ro: "Nume" },
  legal_name_placeholder: { en: "Legal name (optional)", ro: "Denumire legală (opțional)" },
  cui_placeholder: { en: "CUI (optional)", ro: "CUI (opțional)" },
  service_type_placeholder: { en: "Service type (e.g. SEO, accounting, IT)", ro: "Tip serviciu (ex. SEO, contabilitate, IT)" },
  notes_placeholder: { en: "Notes (optional)", ro: "Note (opțional)" },
  new_supplier_form_title: { en: "New supplier", ro: "Furnizor nou" },
  create_supplier: { en: "Create supplier", ro: "Creează furnizorul" },
  save: { en: "Save", ro: "Salvează" },
  cancel: { en: "Cancel", ro: "Anulează" },
};
