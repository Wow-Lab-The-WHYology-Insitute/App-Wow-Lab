// Stable error strings for confirmSessionAttendance (actions.ts).
// Pulled into their own module, not exported from actions.ts directly --
// a "use server" file may only export async functions, so a plain
// string constant needed a home outside it. group-detail-client.tsx
// imports these to show the translated (RO/EN) message instead of the
// raw English fallback; actions.ts imports them to return the same
// string it's matched against, so the two can never drift apart.
export const SESSION_CONFIRMATION_MONTH_CLOSED_ERROR =
  "This month is closed. You can no longer change your confirmation.";
export const SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR =
  "Not permitted (requires being the assigned trainer for this session).";
