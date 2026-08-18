import type { Dictionary } from "@/lib/i18n";

// Deliberately minimal — just the page heading, per the explicit scope of
// the /whoami -> /profile rename. The rest of this page (diagnostic copy,
// profile form, technical details) stays hardcoded English along with
// every other page outside /contracts, /clients, /groups; converting it
// wasn't asked for here.
export const profileDict: Dictionary = {
  page_title: { en: "Profile", ro: "Profil" },
};
