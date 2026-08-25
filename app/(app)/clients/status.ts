// The only place clients.status may move (see actions.ts's
// changeClientStatus). Nothing transitions TO prospect -- a client that
// has been active was converted; it does not become a lead again.
// churned -> active is reactivation, not a special case: SAD Sec4 says a
// returning client keeps its record and its full operational history, so
// it's just another edge in this same table.
export const CLIENT_STATUS_TRANSITIONS: Record<string, string[]> = {
  prospect: ["active"],
  active: ["paused", "churned"],
  paused: ["active", "churned"],
  churned: ["active"],
};
