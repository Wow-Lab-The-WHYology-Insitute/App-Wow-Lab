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
    en: "Your own workshops, groups and grade. Nobody else's.",
    // "gradul tău", not "gradul tale": the possessive agrees with the last
    // term of the list, and that term is a masculine singular. Wrong since
    // 33126a3, i.e. before the session->workshop rename, so this one is not
    // rename residue.
    ro: "Atelierele, grupele și gradul tău. Ale nimănui altcuiva.",
  },

  // The unconfirmed statement -- one sentence, never two figures. The
  // month's close state changes what the person can still DO, so it
  // changes the sentence, not just a number beside it.
  unconfirmed_open: {
    en: "{{count}} of your workshops aren't confirmed yet. {{month}} is still open — confirm them and the pay for them stands.",
    ro: "{{count}} dintre atelierele tale nu sunt confirmate. {{month}} este încă deschisă — confirmă-le și plata pentru ele rămâne.",
  },
  unconfirmed_closed: {
    en: "{{count}} of your workshops aren't confirmed, and {{month}} is already closed — you can no longer confirm them yourself. Ask Operations to correct them.",
    ro: "{{count}} dintre atelierele tale nu sunt confirmate, iar {{month}} este deja închisă — nu le mai poți confirma singur. Cere-i Operațiunilor să le corecteze.",
  },
  unconfirmed_none: {
    en: "Every workshop you've delivered is confirmed.",
    ro: "Toate atelierele pe care le-ai livrat sunt confirmate.",
  },

  confirmed_this_month: { en: "Workshops confirmed this month", ro: "Ateliere confirmate luna aceasta" },
  // Counted by the viewer's own confirmed_at, never sessions.status --
  // see page.tsx's own comment for why.
  confirmed_hint: {
    en: "Counted from your own confirmation, not the workshop's status.",
    ro: "Numărate după confirmarea ta, nu după statusul atelierului.",
  },

  // Bounded to the current school year (1 Sep - 31 Aug, convention §16). It
  // used to count every group the viewer had ever been on, with no date bound
  // -- a figure that only ever grows and would still name a school somebody
  // left two years ago. The label says the bound, because a number whose
  // scope is invisible gets read as "all time" by default.
  groups_assigned: { en: "Groups this school year", ro: "Grupe în anul școlar curent" },

  // The figure most likely to be misread, so the caveat sits under the
  // number at normal size, not as a footnote.
  hours_this_month: { en: "Hours in front of a class this month", ro: "Ore la clasă luna aceasta" },
  // The read-only list of what is next. It is not called "Schedule" -- it is
  // five rows, not a calendar, and naming it one would promise a surface that
  // does not exist.
  upcoming_label: { en: "What's next", ro: "Ce urmează" },
  upcoming_today: { en: "· today", ro: "· azi" },
  upcoming_confirmed: { en: "Confirmed", ro: "Confirmat" },
  // Not "Not confirmed": on a workshop that has not happened, that reads as a
  // failure when it is the ordinary state. "To confirm" names the next step.
  upcoming_open: { en: "To confirm", ro: "De confirmat" },
  upcoming_confirm_hint: {
    en: "Open a workshop to confirm you taught it.",
    ro: "Deschide un atelier pentru a confirma că l-ai ținut.",
  },
  // Reworded with the figure itself: it now counts only workshops that have
  // HAPPENED and were not cancelled, where before it summed everything dated
  // in the month -- October's total was counting 28 October days before it
  // ran. The caveat about pay stays, because that part was always true.
  hours_caveat: {
    en: "Workshops already taught this month — not your pay. Pay counts a two-hour workshop as 1.5×, and your grade counts it as one workshop.",
    ro: "Ateliere deja ținute luna aceasta — nu este plata ta. Plata socotește un atelier de două ore ca 1,5×, iar gradul îl numără ca un singur atelier.",
  },
  // Shown only when at least one counted session has no recorded length,
  // so the total is never silently short.
  hours_incomplete: {
    en: "{{count}} workshop(s) this month have no recorded length and aren't included.",
    ro: "{{count}} atelier/ateliere din luna aceasta nu au durata înregistrată și nu sunt incluse.",
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
    en: "You have no workshops allocated yet. When Operations schedules you onto a workshop, it will show up here.",
    ro: "Nu ai încă niciun atelier alocat. Când Operațiunile te programează la un atelier, va apărea aici.",
  },

  // Lesson-plan decisions (item 117). The notification a trainer meets on
  // entering: Anca asked for more than a line on this page, and for something
  // that can be marked seen.
  decisions_title: { en: "Experiment decisions", ro: "Decizii privind experimentele" },
  decisions_validated: { en: "Validated", ro: "Validat" },
  decisions_changes_requested: { en: "Changes requested", ro: "Modificări cerute" },
  decisions_mark_seen: { en: "Mark seen", ro: "Am văzut" },
  decisions_marking: { en: "Saving…", ro: "Se salvează…" },
  decisions_open_group: { en: "Open group", ro: "Deschide grupa" },
};
