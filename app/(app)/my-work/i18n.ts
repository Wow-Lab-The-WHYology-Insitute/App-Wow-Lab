import type { Dictionary } from "@/lib/i18n";

// One dictionary for /my-work, same one-per-domain convention as
// groups/i18n.ts. page_title is re-exposed as chromeDict.nav_my_work
// rather than the nav owning a second copy.
//
// Deliberately NOT called "Dashboard": item 1 declined an org-wide
// dashboard, and reusing that word for a trainer-scoped page would make
// a future reader think that decision was reversed. "My work" also
// matches the capability that gates it (mywork.*).
export const myWorkDict: Dictionary = {
  page_title: { en: "My work", ro: "Munca mea" },
  page_subtitle: {
    en: "Your own sessions, groups and grade. Nobody else's.",
    ro: "Sesiunile, grupele și gradul tale. Ale nimănui altcuiva.",
  },

  // The unconfirmed statement -- one sentence, never two figures. The
  // month's close state changes what the person can still DO, so it
  // changes the sentence, not just a number beside it.
  unconfirmed_open: {
    en: "{{count}} of your sessions aren't confirmed yet. {{month}} is still open — confirm them and the pay for them stands.",
    ro: "{{count}} dintre sesiunile tale nu sunt confirmate. {{month}} este încă deschisă — confirmă-le și plata pentru ele rămâne.",
  },
  unconfirmed_closed: {
    en: "{{count}} of your sessions aren't confirmed, and {{month}} is already closed — you can no longer confirm them yourself. Ask Operations to correct them.",
    ro: "{{count}} dintre sesiunile tale nu sunt confirmate, iar {{month}} este deja închisă — nu le mai poți confirma singur. Cere-i Operațiunilor să le corecteze.",
  },
  unconfirmed_none: {
    en: "Every session you've delivered is confirmed.",
    ro: "Toate sesiunile pe care le-ai livrat sunt confirmate.",
  },

  confirmed_this_month: { en: "Sessions confirmed this month", ro: "Sesiuni confirmate luna aceasta" },
  // Counted by the viewer's own confirmed_at, never sessions.status --
  // see page.tsx's own comment for why.
  confirmed_hint: {
    en: "Counted from your own confirmation, not the session's status.",
    ro: "Numărate după confirmarea ta, nu după statusul sesiunii.",
  },

  groups_assigned: { en: "Groups you're assigned to", ro: "Grupe la care ești alocat" },

  // The figure most likely to be misread, so the caveat sits under the
  // number at normal size, not as a footnote.
  hours_this_month: { en: "Hours in front of a class this month", ro: "Ore la clasă luna aceasta" },
  hours_caveat: {
    en: "Time taught — not your pay. Pay counts a two-hour workshop as 1.5×, and your grade counts it as one workshop.",
    ro: "Timp predat — nu este plata ta. Plata socotește un atelier de două ore ca 1,5×, iar gradul îl numără ca un singur atelier.",
  },
  // Shown only when at least one counted session has no recorded length,
  // so the total is never silently short.
  hours_incomplete: {
    en: "{{count}} session(s) this month have no recorded length and aren't included.",
    ro: "{{count}} sesiune/sesiuni din luna aceasta nu au durata înregistrată și nu sunt incluse.",
  },

  grade_label: { en: "Your grade", ro: "Gradul tău" },
  grade_level: { en: "Grade {{level}}", ro: "Gradul {{level}}" },
  grade_unset: { en: "Not set yet", ro: "Nestabilit încă" },
  // The six names are Anca's own (2026-09-24). The database stores only
  // the integer -- these labels live here, the same key-to-label shape
  // module_*/format_* already use in groups/i18n.ts.
  grade_name_1: { en: "Junior", ro: "Junior" },
  grade_name_2: { en: "Rising Star", ro: "Rising Star" },
  grade_name_3: { en: "Enthusiastic Mid 1", ro: "Enthusiastic Mid 1" },
  grade_name_4: { en: "Experienced Mid 2", ro: "Experienced Mid 2" },
  grade_name_5: { en: "Magic Senior 1", ro: "Magic Senior 1" },
  grade_name_6: { en: "Glowing Senior 2", ro: "Glowing Senior 2" },

  // The no-allocations case: one plain line, not a grid of five zeros --
  // five zeros read as a broken page, one sentence reads as a true one.
  nothing_allocated: {
    en: "You have no sessions allocated yet. When Operations schedules you onto a workshop, it will show up here.",
    ro: "Nu ai încă nicio sesiune alocată. Când Operațiunile te programează la un atelier, va apărea aici.",
  },
};
