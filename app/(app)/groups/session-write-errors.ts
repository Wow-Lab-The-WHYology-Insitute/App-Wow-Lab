// Stable error strings for confirmSessionAttendance/updateSessionAttendance
// (actions.ts). Pulled into their own module, not exported from actions.ts
// directly -- a "use server" file may only export async functions, so a
// plain string constant needed a home outside it. group-detail-client.tsx
// imports these to show the translated (RO/EN) message instead of the raw
// English fallback; actions.ts imports them to return the same string it's
// matched against, so the two can never drift apart.
//
// Renamed from session-confirmation-errors.ts: SESSION_CONFIRMATION_
// NOT_ASSIGNED_ERROR's wording ("requires being the assigned trainer for
// this session") is generic enough to be correct for either write, so
// updateSessionAttendance reuses it rather than duplicating an identical
// string -- only the month-closed case needed its own wording per write,
// since "your confirmation" doesn't fit attendance.
export const SESSION_CONFIRMATION_MONTH_CLOSED_ERROR =
  "This month is closed. You can no longer change your confirmation.";
export const SESSION_ATTENDANCE_MONTH_CLOSED_ERROR =
  "This month is closed. You can no longer change attendance for this session.";
export const SESSION_CONFIRMATION_NOT_ASSIGNED_ERROR =
  "Not permitted (requires being the assigned trainer for this session).";
