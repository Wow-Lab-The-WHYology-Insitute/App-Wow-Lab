import type { Dictionary } from "@/lib/i18n";
import { clientsDict } from "./clients/i18n";
import { contractsDict } from "./contracts/i18n";
import { groupsDict } from "./groups/i18n";
import { profileDict } from "./profile/i18n";

// App chrome (nav/sidebar/header) — the one dictionary shared by every
// authenticated screen, since layout.tsx/shell-chrome.tsx render on top of
// all of them. Deliberately excludes anything page-specific (that's each
// route's own i18n.ts, e.g. contracts/i18n.ts).
//
// nav_profile/nav_clients/nav_contracts/nav_groups_enrollment intentionally
// reuse each page's own page_title pair rather than redeclaring the same
// string here — a page's name has exactly one home (its own i18n.ts); the
// nav borrows it, it doesn't own a second copy that could drift out of sync.
// nav_profile specifically was "Dashboard" until this pass — the item has
// always linked to /profile (no separate dashboard route or feature exists),
// so the label was simply wrong; it now takes profileDict's actual name.
export const chromeDict: Dictionary = {
  nav_profile: profileDict.page_title,
  nav_users_roles: { en: "Users & Roles", ro: "Utilizatori și roluri" },
  nav_group_clients_contracts: { en: "Clients & Contracts", ro: "Clienți și contracte" },
  nav_clients: clientsDict.page_title,
  nav_contracts: contractsDict.page_title,
  nav_group_operational: { en: "Operational", ro: "Operațional" },
  nav_groups_enrollment: groupsDict.page_title,
  aria_open_menu: { en: "Open menu", ro: "Deschide meniul" },
  aria_close_menu: { en: "Close menu", ro: "Închide meniul" },
  sign_out: { en: "Sign out", ro: "Ieșire" },
  signing_out: { en: "Signing out…", ro: "Se iese…" },
};
