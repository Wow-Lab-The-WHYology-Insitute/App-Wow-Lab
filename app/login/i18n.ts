import type { Dictionary } from "@/lib/i18n";

// Shared between login-content.tsx and login-form.tsx -- one dictionary,
// not two, matching contractsDict's own reasoning (a string can't drift
// out of sync between the two halves of one page). "WOW LAB"/"WOW LAB OS"
// and the you@wowlab.ro placeholder are left as literal JSX/attribute
// values, not dictionary entries -- proper nouns and an example address
// format, identical in both locales, same convention as SmartBill/SAGA
// staying untranslated elsewhere in this app.
export const loginDict: Dictionary = {
  subtitle: {
    en: "Invite-only. Enter your email to get a sign-in link.",
    ro: "Doar pe bază de invitație. Introdu adresa de email pentru un link de conectare.",
  },
  callback_error: {
    en: "That link didn't work — it may have expired or already been used. Enter your email below to request a new one.",
    ro: "Linkul nu a funcționat — poate a expirat sau a fost deja folosit. Introdu adresa de email mai jos pentru unul nou.",
  },
  sent_message: {
    en: "Check your email for a sign-in link.",
    ro: "Verifică-ți emailul pentru linkul de conectare.",
  },
  email_label: { en: "Email", ro: "Email" },
  sending: { en: "Sending…", ro: "Se trimite…" },
  submit: { en: "Send magic link", ro: "Trimite link de conectare" },
  // Keyed, not free text -- the server action can't know the caller's
  // locale (it's client-only, lib/i18n.tsx), so it returns a stable key
  // and the client (already inside LocaleProvider) resolves the string.
  // Same principle as the payment-config resolvers keeping their own
  // RAISE EXCEPTION text developer-facing and letting the caller
  // translate -- moved here to the server-action boundary instead.
  error_missing_email: { en: "Enter an email address.", ro: "Introdu o adresă de email." },
  error_send_failed: {
    en: "Couldn't send a link. Check the address and try again or contact us at info@wowlab.ro.",
    ro: "Nu am putut trimite linkul. Verifică adresa și încearcă din nou sau contactează-ne la info@wowlab.ro.",
  },
};
