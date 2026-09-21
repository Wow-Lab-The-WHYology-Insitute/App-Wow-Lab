// The only place clients.status_override may move (see actions.ts's
// changeClientStatus). Keys are EFFECTIVE status (public.
// client_effective_status(), item 78), not the raw stored column --
// changeClientStatus looks transitions up by the derived value, not
// current.status_override directly.
//
// The VALUES below describe override targets, not statuses (item 83) --
// status_override only ever holds 'paused', 'churned', or NULL. "paused"
// and "churned" as a target write that literal value. "active" as a
// target does NOT write the word 'active' anywhere -- status_override has
// no such value since item 83 (illegal under clients_status_override_check)
// -- it means "clear the override," i.e. write NULL, letting
// client_effective_status() derive prospect/active fresh from whether a
// signed contract exists.
//
// No prospect key: since item 78 (Anca, 2026-09-21 -- a client is active
// once it has a signed contract), prospect -> active is automatic
// (derived from contract-signed, not a button), so there is no manual
// transition out of prospect at all. A true prospect (no signed contract,
// not paused/churned) shows zero action buttons -- ClientStatusControl's
// existing "empty list -> render nothing" behavior covers this without a
// component change.
//
// "active" -> paused/churned unchanged. paused/churned -> "active"
// ("reactivate") is the one non-obvious edge: it writes NULL to
// status_override (item 83 removed the earlier 'prospect'-as-sentinel
// indirection entirely -- NULL now means exactly what it says). This is
// always correct on every reachable path: paused/churned can only be
// reached FROM derived-active, which required a signed contract, and
// nothing in this system ever un-signs one -- so "reactivate" always
// re-derives to Active in practice.
export const CLIENT_STATUS_TRANSITIONS: Record<string, string[]> = {
  active: ["paused", "churned"],
  paused: ["active", "churned"],
  churned: ["active"],
};
