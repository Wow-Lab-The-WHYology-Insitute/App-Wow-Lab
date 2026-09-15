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
  confirm_close_button: { en: "Yes, close it", ro: "Da, închide" },
  cancel: { en: "Cancel", ro: "Anulează" },
  already_closed_notice: { en: "{{month}} is already closed.", ro: "{{month}} este deja închisă." },
  already_closed_error: { en: "This month is already closed.", ro: "Această lună este deja închisă." },
  network_error: {
    en: "The change was not saved. Check your connection and try again.",
    ro: "Modificarea nu a fost salvată. Verifică conexiunea și încearcă din nou.",
  },
  history_heading: { en: "Closed months", ro: "Luni închise" },
  history_empty: { en: "No months closed yet.", ro: "Nicio lună închisă încă." },
  closed_by_prefix: { en: "Closed by ", ro: "Închisă de " },
};
