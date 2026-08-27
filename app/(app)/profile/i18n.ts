import type { Dictionary } from "@/lib/i18n";

// Shared across page.tsx's client leaves (profile-heading.tsx,
// access-summary.tsx), profile-section.tsx, and technical-details.tsx —
// one dictionary for the whole /profile route, same as every other
// domain's single i18n.ts.
export const profileDict: Dictionary = {
  page_title: { en: "Profile", ro: "Profil" },

  diagnostic_intro: {
    en: "Diagnostic view: every value below came through your own session (anon key + your JWT), never service_role — proof the auth → RLS loop works, not yet a real Phase 1 dashboard.",
    ro: "Vizualizare de diagnostic: fiecare valoare de mai jos a venit prin propria ta sesiune (cheie anon + JWT-ul tău), niciodată service_role — dovadă că bucla auth → RLS funcționează, nu încă un dashboard real de Faza 1.",
  },
  you_are_prefix: { en: "You are ", ro: "Ești " },
  unassigned_role_label: { en: "an unassigned user", ro: "un utilizator neasignat" },
  access_to_prefix: { en: "You have access to: ", ro: "Ai acces la: " },
  no_additional_access: {
    en: "You don't have access to any additional sections yet.",
    ro: "Nu ai încă acces la nicio secțiune suplimentară.",
  },

  your_profile_heading: { en: "Your profile", ro: "Profilul tău" },
  change_overlay: { en: "Change", ro: "Schimbă" },
  uploading_ellipsis: { en: "Uploading…", ro: "Se încarcă…" },
  change_photo: { en: "Change photo", ro: "Schimbă poza" },
  avatar_type_error: {
    en: "Only JPEG, PNG, or WebP images are allowed.",
    ro: "Sunt permise doar imagini JPEG, PNG sau WebP.",
  },
  avatar_size_error: { en: "Image must be 2MB or smaller.", ro: "Imaginea trebuie să fie de cel mult 2MB." },
  first_name_placeholder: { en: "First name", ro: "Prenume" },
  last_name_placeholder: { en: "Last name", ro: "Nume" },
  phone_placeholder: { en: "Phone", ro: "Telefon" },
  save: { en: "Save", ro: "Salvează" },
  saved: { en: "Saved.", ro: "Salvat." },

  hide_technical_details: { en: "Hide technical details", ro: "Ascunde detaliile tehnice" },
  show_technical_details: { en: "Show technical details", ro: "Arată detaliile tehnice" },
  section_signed_in_as: { en: "Signed in as", ro: "Autentificat ca" },
  section_orgs_visible: { en: "Organizations visible via RLS", ro: "Organizații vizibile prin RLS" },
  section_roles_per_org: { en: "Your role(s) per organization", ro: "Rolul (rolurile) tale pe organizație" },
  section_capabilities_per_org: {
    en: "Resolved capabilities per organization",
    ro: "Capabilități rezolvate pe organizație",
  },
  section_spot_check: {
    en: "Spot-check via app.has_capability() RPC",
    ro: "Verificare punctuală prin RPC app.has_capability()",
  },
  label_email: { en: "Email", ro: "Email" },
  label_user_id: { en: "User ID", ro: "ID utilizator" },
  label_platform_owner: { en: "Platform owner", ro: "Owner platformă" },
  label_status: { en: "Status", ro: "Status" },
  empty_none: { en: "None", ro: "Niciunul" },
  empty_no_membership: {
    en: "No user_org_roles row for this user",
    ro: "Nicio înregistrare user_org_roles pentru acest utilizator",
  },
};
