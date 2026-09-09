// Diacritic-insensitive matching for the app's free-text search boxes.
// Romanian names get typed both with and without diacritics (ă/â/î/ș/ț)
// depending on habit or keyboard, and a plain toLowerCase().includes()
// treats e.g. "ș" and "s" as different characters — it misses the match
// in whichever direction the query and the stored value disagree.
// Folding both sides through this before comparing makes the match
// direction-independent.
export function normalizeForSearch(value: string): string {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();
}
