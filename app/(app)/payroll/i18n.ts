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
  summary_sessions_count: { en: "{{n}} workshops this month", ro: "{{n}} ateliere în această lună" },
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
  unpriceable_heading: {
    en: "{{n}} workshop(s) in {{month}} cannot be priced yet",
    ro: "{{n}} atelier(e) din {{month}} nu pot fi încă plătite",
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
};
