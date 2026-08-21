import type { Dictionary } from "@/lib/i18n";
import { groupsDict } from "../../groups/i18n";

// A single, minimal entry — this page isn't otherwise converted to i18n
// (still hardcoded English throughout, matching the earlier locale-coverage
// finding), but this one string can't be hardcoded English without
// reintroducing the exact anti-pattern users field-masking prep exists to
// remove: falling back to a raw value (there, email; here, nothing safe at
// all) where a name belongs. unnamed_user is not redeclared here — a
// placeholder for "no safe name available" has exactly one home
// (groups/i18n.ts, since it was defined there first); this page borrows it
// rather than risking two copies drifting apart, same pattern as
// app/(app)/i18n.ts borrowing page names from clients/contracts/groups.
export const adminUsersDict: Dictionary = {
  unnamed_user: groupsDict.unnamed_user,
};
