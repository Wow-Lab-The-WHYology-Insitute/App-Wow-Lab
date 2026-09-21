// The only place clients.status may move (see actions.ts's
// changeClientStatus). Keys are EFFECTIVE status (public.
// client_effective_status(), item 78), not the raw stored column --
// changeClientStatus looks transitions up by the derived value, not
// current.status directly.
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
// ("reactivate") is the one non-obvious edge: it writes 'prospect' to the
// stored column (the sentinel changeClientStatus/client_effective_status
// treat as "no override"), not literally 'active' -- see actions.ts. This
// is always correct on every reachable path: paused/churned can only be
// reached FROM derived-active, which required a signed contract, and
// nothing in this system ever un-signs one -- so "reactivate" always
// re-derives to Active in practice, even though the literal write is
// 'prospect'.
export const CLIENT_STATUS_TRANSITIONS: Record<string, string[]> = {
  active: ["paused", "churned"],
  paused: ["active", "churned"],
  churned: ["active"],
};
