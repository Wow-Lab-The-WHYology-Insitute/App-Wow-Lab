export { formatDate, entityShortCode } from "@/lib/format";

export function formatMoney(value: string | number, locale: "en" | "ro") {
  const n = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(n)) return String(value);
  const formatted = new Intl.NumberFormat(locale === "ro" ? "ro-RO" : "en-US").format(n);
  return `${formatted} lei`;
}

// The exact marker text seed migrations write into a demo contract's
// notes. Used to be reinforced visually by contract_number's own
// "DEMO-2026-" prefix in every list row; now that contract_number is gone
// (202608180002, replaced by entry_number/exit_number), this substring
// check is the only signal left, so it drives a visible badge instead of
// a sentence buried in the expanded detail panel.
const DEMO_RECORD_MARKER = "Example seed record";

export function isDemoRecord(notes: string | null) {
  return notes != null && notes.includes(DEMO_RECORD_MARKER);
}
