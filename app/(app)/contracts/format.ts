export function formatMoney(value: string | number, locale: "en" | "ro") {
  const n = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(n)) return String(value);
  const formatted = new Intl.NumberFormat(locale === "ro" ? "ro-RO" : "en-US").format(n);
  return `${formatted} lei`;
}

export function formatDate(iso: string, locale: "en" | "ro") {
  const d = new Date(iso);
  return d.toLocaleDateString(locale === "ro" ? "ro-RO" : "en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "2-digit",
  });
}

// Real names as of the entity roster today (post the Bradine ->
// Brandine correction) — mapped explicitly rather than derived from
// initials, since neither "Brandine Advertising SRL" nor "Asociatia
// STEMplicity" reduces to a sensible code by a mechanical first-letter
// rule (STEM is pulled from inside the name, not initials). Falls back to
// a truncated-uppercase guess for any future entity so this never renders
// blank.
const ENTITY_SHORT_CODES: Record<string, string> = {
  "Experimente Wow SRL": "EWS",
  "Brandine Advertising SRL": "BADV",
  "Asociatia STEMplicity": "STEM",
};

export function entityShortCode(fullName: string) {
  return ENTITY_SHORT_CODES[fullName] ?? fullName.replace(/[^A-Za-z]/g, "").slice(0, 4).toUpperCase();
}
