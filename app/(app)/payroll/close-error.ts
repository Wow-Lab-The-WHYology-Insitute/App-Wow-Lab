// Stable error string for closePayrollPeriod (actions.ts). Pulled into
// its own module, not exported from actions.ts directly -- a
// "use server" file may only export async functions, so a plain string
// constant needed a home outside it. payroll-client.tsx imports this to
// show the translated (RO/EN) message instead of the raw English
// fallback; actions.ts imports it to return the same string it's
// matched against, so the two can never drift apart.
export const PAYROLL_PERIOD_ALREADY_CLOSED_ERROR = "This month is already closed.";
