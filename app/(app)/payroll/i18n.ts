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
    en: "Close {{month}}? Trainers will no longer be able to change attendance or confirmation for sessions in this month.",
    ro: "Închizi {{month}}? Trainerii nu vor mai putea modifica prezența sau confirmarea pentru sesiunile din această lună.",
  },
  // Shown instead of confirm_prompt when at least one trainer slot this
  // month is unconfirmed -- states the pay consequence directly, not just
  // the write-access one, per the payroll walkthrough finding that the
  // generic prompt said nothing about what closing does to an unconfirmed
  // trainer's pay.
  confirm_prompt_with_unconfirmed: {
    en: "{{n}} trainer slots for {{month}} are not confirmed. Per policy, a trainer is not paid for a session they haven't confirmed — closing {{month}} locks that in, and also removes trainers' ability to confirm or change attendance.",
    ro: "{{n}} sloturi de trainer pentru {{month}} nu sunt confirmate. Conform politicii, un trainer nu este plătit pentru o sesiune neconfirmată — închiderea lunii {{month}} blochează această situație și le ia trainerilor posibilitatea de a confirma sau modifica prezența.",
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
  summary_no_sessions: { en: "No sessions in {{month}}.", ro: "Nicio sesiune în {{month}}." },
  summary_all_confirmed: {
    en: "{{n}} sessions this month. All {{total}} trainer slots are confirmed.",
    ro: "{{n}} sesiuni în această lună. Toate cele {{total}} sloturi de trainer sunt confirmate.",
  },
  summary_sessions_count: { en: "{{n}} sessions this month", ro: "{{n}} sesiuni în această lună" },
  summary_unconfirmed_heading: {
    en: "{{n}} of {{total}} trainer slots are not confirmed",
    ro: "{{n}} din {{total}} sloturi de trainer nu sunt confirmate",
  },
  summary_unconfirmed_list_heading: { en: "Not confirmed:", ro: "Neconfirmate:" },
};
