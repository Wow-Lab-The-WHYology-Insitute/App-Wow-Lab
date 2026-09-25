// Shared name-resolution rule (OPEN_ITEMS.md item 29). Was duplicated
// verbatim across admin-users-client.tsx, groups/page.tsx, groups/[id]/
// page.tsx, payment-config/page.tsx, and payroll/page.tsx (a sixth call
// site, the trigger item 29 itself set for extracting) -- promoted here
// once that sixth site landed, same "promote on the trigger, not before"
// precedent as lib/format.ts.
//
// full_name is NOT NULL on public.users but can itself be a raw email
// (handle_new_auth_user's invite-metadata default) -- never trusted for
// display just for being non-null, in either function below.

type NameFields = {
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
};

// One display string for read-only rendering. Prefers first+last, falls
// back to full_name unless it looks like an email, else "" (caller decides
// the placeholder -- "Unnamed", "Unknown", etc., which differ by context).
export function displayName(u: NameFields): string {
  const full = [u.first_name, u.last_name].filter(Boolean).join(" ");
  if (full) return full;
  if (u.full_name && !u.full_name.includes("@")) return u.full_name;
  return "";
}

// Two initial values for an editable first-name/last-name form (profile/
// page.tsx) -- a genuinely different shape from displayName above, kept
// separate rather than flattened into it. Only borrows full_name when BOTH
// structured columns are unset, and puts it unsplit into first name --
// there's no reliable rule for where a raw full_name splits.
export function editableNameFields(u: NameFields): { firstName: string | null; lastName: string | null } {
  const bothUnset = !u.first_name && !u.last_name;
  const fullNameFallback = bothUnset && u.full_name && !u.full_name.includes("@") ? u.full_name : null;
  return {
    firstName: u.first_name ?? fullNameFallback,
    lastName: u.last_name ?? null,
  };
}
