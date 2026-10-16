import type { Dictionary } from "@/lib/i18n";

// app/(app)/payroll -- the only screen in this app for closing a month
// (payroll_periods, 202609150001). Gated on finance.operations.*, the
// capability that identifies "the person who closes payroll" -- see that
// migration's own comment for why not contracts.*, which Anka and Laura
// also happen to hold, coincidentally, for an unrelated reason.
export const payrollDict: Dictionary = {
  page_title: { en: "Payroll", ro: "Salarizare" },
  month_label: { en: "Month", ro: "Lună" },
  close_section_heading: { en: "Close a month", ro: "Închide o lună" },
  close_month_button: { en: "Close {{month}}", ro: "Închide {{month}}" },
  confirm_prompt: {
    en: "Close {{month}}? Trainers will no longer be able to change attendance or confirmation for workshops in this month.",
    ro: "Închizi {{month}}? Trainerii nu vor mai putea modifica prezența sau confirmarea pentru atelierele din această lună.",
  },
  // Shown instead of confirm_prompt when at least one trainer slot this
  // month is unconfirmed -- states the pay consequence directly, not just
  // the write-access one, per the payroll walkthrough finding that the
  // generic prompt said nothing about what closing does to an unconfirmed
  // trainer's pay.
  confirm_prompt_with_unconfirmed: {
    en: "{{n}} trainer slots for {{month}} are not confirmed. Per policy, a trainer is not paid for a workshop they haven't confirmed — closing {{month}} locks that in, and also removes trainers' ability to confirm or change attendance.",
    ro: "{{n}} sloturi de trainer pentru {{month}} nu sunt confirmate. Conform politicii, un trainer nu este plătit pentru un atelier neconfirmat — închiderea lunii {{month}} blochează această situație și le ia trainerilor posibilitatea de a confirma sau modifica prezența.",
  },
  confirm_close_button: { en: "Yes, close it", ro: "Da, închide" },
  cancel: { en: "Cancel", ro: "Anulează" },
  already_closed_notice: { en: "{{month}} is already closed.", ro: "{{month}} este deja închisă." },
  // Dead-zone cover for the close button: shown from the moment the close
  // action succeeds until the revalidated `periods` prop actually
  // contains it -- isPending ending is not that signal (it resolves a
  // microtask before Next applies the refreshed tree), so without this
  // the button would flash back to "Close {{month}}" for a real window
  // while the month might not be reliably closed yet from here.
  closing_month: { en: "Closing {{month}}…", ro: "Se închide {{month}}…" },
  already_closed_error: { en: "This month is already closed.", ro: "Această lună este deja închisă." },
  network_error: {
    en: "The change was not saved. Check your connection and try again.",
    ro: "Modificarea nu a fost salvată. Verifică conexiunea și încearcă din nou.",
  },
  history_heading: { en: "Closed months", ro: "Luni închise" },
  history_empty: { en: "No months closed yet.", ro: "Nicio lună închisă încă." },
  closed_by_prefix: { en: "Closed by ", ro: "Închisă de " },

  // Pre-close summary. The two "nothing to flag" states (no sessions /
  // all confirmed) are plain text, deliberately not a colored box of any
  // kind -- a suppressed copy of the warning box would just become the
  // box people learn to click past. Only the has-unconfirmed state gets
  // the orange treatment, and it's the only one anyone needs to act on.
  summary_no_sessions: { en: "No workshops in {{month}}.", ro: "Niciun atelier în {{month}}." },
  summary_all_confirmed: {
    en: "{{n}} workshops this month. All {{total}} trainer slots are confirmed.",
    ro: "{{n}} ateliere în această lună. Toate cele {{total}} sloturi de trainer sunt confirmate.",
  },
  // Count in parentheses rather than in the sentence. Romanian has three
  // plural forms (1 / 2-19 / 20+ with "de"), so "{{n}} ateliere" was wrong at
  // n=1 ("1 ateliere") and at n>=20 ("20 ateliere", missing "de"). A label with
  // a bracketed count sidesteps all three without Intl.PluralRules, and it is
  // the pattern "Ateliere ({{count}})" already uses elsewhere. The sentences
  // that genuinely need the number inline are left for a later pass.
  summary_sessions_count: {
    en: "Workshops this month ({{n}})",
    ro: "Ateliere în această lună ({{n}})",
  },
  summary_unconfirmed_heading: {
    en: "{{n}} of {{total}} trainer slots are not confirmed",
    ro: "{{n}} din {{total}} sloturi de trainer nu sunt confirmate",
  },
  summary_unconfirmed_list_heading: { en: "Not confirmed:", ro: "Neconfirmate:" },

  // The pre-close completeness check (item 121). Wording follows
  // app.calculate_session_pay's own five raise messages, so the closer reads
  // the same sentence the calculation would produce -- translated, and with
  // the trainer NAMED rather than the column, because the trainer is the
  // actionable half. Luiza Mirt is the live instance: she has no grade by
  // Anca's own conditional answer ("grade 3 if she returns", item 95), so the
  // message has to say "Luiza Mirt has no grade on this date", not
  // "trainer_grade_assignments is missing a row".
  // Was "{{n}} workshop(s)" / "{{n}} atelier(e)" — the parenthesised-suffix
  // dodge, which avoids being wrong but reads as machine output and is STILL
  // wrong in Romanian at 20+ (needs "de"). As a heading the count belongs in
  // brackets anyway.
  unpriceable_heading: {
    en: "Workshops in {{month}} that cannot be priced yet ({{n}})",
    ro: "Ateliere din {{month}} care nu pot fi încă plătite ({{n}})",
  },
  unpriceable_hint: {
    en: "Closing the month is still possible — but pay cannot be computed for these until the gaps are filled, and a trainer can no longer fix them afterwards.",
    ro: "Luna poate fi închisă oricum — dar plata nu poate fi calculată pentru acestea până nu se completează, iar după închidere trainerul nu le mai poate corecta.",
  },
  unpriceable_list_heading: { en: "What is missing", ro: "Ce lipsește" },
  unpriceable_no_duration: {
    en: "no length recorded on the workshop",
    ro: "atelierul nu are durata înregistrată",
  },
  unpriceable_no_location: {
    en: "no location tier recorded on the workshop",
    ro: "atelierul nu are nivelul de locație înregistrat",
  },
  unpriceable_no_language: {
    en: "the group has no language recorded",
    ro: "grupa nu are limba înregistrată",
  },
  unpriceable_no_trainer: {
    en: "no trainer in either slot — there is nobody to pay",
    ro: "niciun trainer în niciunul din sloturi — nu e cine să fie plătit",
  },
  unpriceable_no_grade: {
    en: "{{name}} has no grade effective on this date",
    ro: "{{name}} nu are un grad valabil la această dată",
  },
  // The same fact when the viewer cannot read that person's name. Not
  // "Unknown has no grade" -- that sentence names nobody and is less
  // actionable than naming the column it was written to avoid naming.
  unpriceable_no_grade_unnamed: {
    en: "someone allocated to this workshop has no grade effective on this date, and their name is not visible to your role",
    ro: "o persoană alocată acestui atelier nu are un grad valabil la această dată, iar numele ei nu este vizibil pentru rolul tău",
  },

  // ---- The sums, per trainer ----
  // The unit is the trainer because the unit of payment is the trainer:
  // "timesheet-ul se închide la sfârșit de lună și factura se emite din el"
  // (Anca, 2026-09-11), and the invoice is issued per person (PFA/SRL).
  sums_heading: {
    en: "What each trainer is owed — {{month}}",
    ro: "Cât i se cuvine fiecărui trainer — {{month}}",
  },
  sums_hint: {
    en: "Each workshop is rounded to the ban; a trainer's total is the sum of those rounded rows, so adding them up by hand gives the same figure. Unconfirmed workshops are listed but not included.",
    ro: "Fiecare atelier este rotunjit la ban; totalul unui trainer este suma rândurilor rotunjite, deci adunarea lor de mână dă aceeași cifră. Atelierele neconfirmate sunt listate, dar nu sunt incluse.",
  },
  // "lei" after the number, as every Romanian invoice writes it. Kept as a
  // key rather than hardcoded so the currency is in one place if a second
  // one ever appears (the supplier register already carries euro rows).
  sums_amount: { en: "{{amount}} lei", ro: "{{amount}} lei" },
  sums_pending: {
    en: "{{amount}} lei more, not confirmed — not payable yet",
    ro: "încă {{amount}} lei, neconfirmați — încă nu sunt de plată",
  },
  sums_row_unconfirmed: { en: "not confirmed", ro: "neconfirmat" },
  // Grouped by trainer id, so an unreadable name still gets its own row and
  // its own correct total instead of being merged with another unnamed
  // person under the word "Unknown" (item 122's rule, applied to a sum).
  sums_trainer_unnamed: {
    en: "A person whose name is not visible to your role",
    ro: "O persoană al cărei nume nu este vizibil pentru rolul tău",
  },
  sums_total_label: { en: "Total payable this month", ro: "Total de plată luna aceasta" },
  sums_total_pending: {
    en: "Plus {{amount}} lei not confirmed, excluded from the total above.",
    ro: "Plus {{amount}} lei neconfirmați, excluși din totalul de mai sus.",
  },
  // Count in brackets would read oddly mid-sentence here, and this sentence
  // genuinely needs the number inline. Romanian's three plural forms are
  // sidestepped by "de ateliere", which is correct for 20+ and reads
  // acceptably below it -- the alternative ("1 ateliere") is simply wrong.
  sums_total_excludes: {
    en: "Excludes {{n}} workshop(s) that cannot be calculated — see the reasons above.",
    ro: "Exclude {{n}} ateliere care nu pot fi calculate — vezi motivele mai sus.",
  },

  // ---- Why a row has no amount ----
  // One key per reason_code from app.calculate_org_session_pay
  // (202610150003), which classifies the fourteen shapes
  // app.calculate_session_pay and its five resolvers can raise. Deliberately
  // a separate set from the unpriceable_* keys above: that block answers
  // "what can a human still fix before closing?", this one answers "why is
  // there no number here?", and the second is a superset — it includes gaps
  // in the pay grid itself, which nobody can fix from this screen.
  pay_reason_no_duration: {
    en: "no length recorded",
    ro: "durata nu este înregistrată",
  },
  pay_reason_no_location: {
    en: "no location tier recorded",
    ro: "nivelul de locație nu este înregistrat",
  },
  pay_reason_no_language: {
    en: "the group has no language recorded",
    ro: "grupa nu are limba înregistrată",
  },
  pay_reason_no_grade: {
    en: "no grade effective on this date",
    ro: "nu are un grad valabil la această dată",
  },
  // Should be unreachable: the function is only ever asked about a trainer
  // who holds one of the two slots on that workshop. Worded plainly anyway
  // rather than left to the 'unknown' fallback.
  pay_reason_not_on_session: {
    en: "not allocated to this workshop",
    ro: "nu este alocat acestui atelier",
  },
  // The grid gaps. These are not data entry errors — they are holes in the
  // pay grid, and the sentence says who can close them, because /payroll is
  // not where they get fixed.
  pay_reason_no_grade_version: {
    en: "no rate grid in effect on this date — set one in Payment configuration",
    ro: "nicio grilă de tarife valabilă la această dată — se setează în Configurare plăți",
  },
  pay_reason_no_grade_rate_row: {
    en: "the rate grid in effect has no rate for this trainer's grade",
    ro: "grila de tarife valabilă nu are tarif pentru gradul acestui trainer",
  },
  pay_reason_no_duration_version: {
    en: "no duration grid in effect on this date — set one in Payment configuration",
    ro: "nicio grilă de durate valabilă la această dată — se setează în Configurare plăți",
  },
  // The live one: 30 minutes exists for standard workshops and not for
  // Școala Altfel / Săptămâna Verde, and the workshop form offers 30.
  pay_reason_no_duration_row: {
    en: "the duration grid has no entry for this length and workshop type",
    ro: "grila de durate nu are un rând pentru această durată și acest tip de atelier",
  },
  pay_reason_no_location_version: {
    en: "no location grid in effect on this date — set one in Payment configuration",
    ro: "nicio grilă de locații valabilă la această dată — se setează în Configurare plăți",
  },
  pay_reason_no_location_row: {
    en: "the location grid has no entry for this tier",
    ro: "grila de locații nu are un rând pentru acest nivel",
  },
  pay_reason_no_language_version: {
    en: "no language grid in effect on this date — set one in Payment configuration",
    ro: "nicio grilă de limbi valabilă la această dată — se setează în Configurare plăți",
  },
  pay_reason_no_language_row: {
    en: "the language grid has no entry for this group's language",
    ro: "grila de limbi nu are un rând pentru limba acestei grupe",
  },
  // Only reachable if a resolver's message is reworded without the
  // classifier being updated. Shows the raw message: ugly and technical,
  // but a failure nobody can see is worse than one that looks wrong.
  // db/tests/payroll_org_session_pay.sql asserts no real case lands here.
  pay_reason_unknown: {
    en: "could not be calculated: {{message}}",
    ro: "nu a putut fi calculat: {{message}}",
  },
};
