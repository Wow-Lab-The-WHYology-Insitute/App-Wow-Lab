// Stable error string for addClient/updateClient's 23505 handling.
// Pulled into its own module, not exported from actions.ts directly --
// a "use server" file may only export async functions, so a plain
// string constant needed a home outside it. clients-client.tsx and
// client-info-client.tsx import this to show the translated (RO/EN)
// message instead of the raw English fallback; actions.ts imports it to
// return the same string it's matched against, so the two can never
// drift apart.
export const DUPLICATE_CUI_ERROR = "A client with this CUI already exists.";
