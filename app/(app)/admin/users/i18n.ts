import type { Dictionary } from "@/lib/i18n";
import { groupsDict } from "../../groups/i18n";

// Shared between admin-users-header.tsx and admin-users-client.tsx -- one
// dictionary for the whole /admin/users route, same as every other
// domain's single i18n.ts.
export const adminUsersDict: Dictionary = {
  // unnamed_user is not redeclared here -- a placeholder for "no safe name
  // available" has exactly one home (groups/i18n.ts, since it was defined
  // there first); this page borrows it rather than risking two copies
  // drifting apart, same pattern as app/(app)/i18n.ts borrowing page names
  // from clients/contracts/groups.
  unnamed_user: groupsDict.unnamed_user,

  // page.tsx's own heading -- deliberately NOT reusing chromeDict's
  // nav_users_roles ("Users & Roles", capital R): this page's own h1 has
  // always read "Users & roles" (lowercase r), a pre-existing casing
  // difference from the nav label, not unified here.
  page_title: { en: "Users & roles", ro: "Utilizatori și roluri" },
  org_prefix: { en: "Organization: ", ro: "Organizație: " },

  members_heading: { en: "Members ({{count}})", ro: "Membri ({{count}})" },
  members_heading_filtered: {
    en: "Members ({{shown}} of {{total}})",
    ro: "Membri ({{shown}} din {{total}})",
  },
  empty_no_members: { en: "No members in this organization.", ro: "Niciun membru în această organizație." },
  search_placeholder: { en: "Search by name or email…", ro: "Caută după nume sau email…" },
  filter_role_all: { en: "All roles", ro: "Toate rolurile" },

  // Real values this app ever writes to users.status (see
  // admin-users-client.tsx's own STATUS_KEYS comment) -- distinct
  // vocabulary from clientsDict/groupsDict's own status_active etc.
  // (account status, not client/group status), no collision risk since
  // each domain owns its own dict.
  status_invited: { en: "Invited", ro: "Invitat" },
  status_active: { en: "Active", ro: "Activ" },
  status_disabled: { en: "Disabled", ro: "Dezactivat" },
  filter_status_all: { en: "All statuses", ro: "Toate statusurile" },

  filter_account_all: { en: "All accounts", ro: "Toate conturile" },
  filter_account_real: { en: "Real only", ro: "Doar reale" },
  filter_account_test: { en: "Test only", ro: "Doar test" },
  empty_no_match: { en: "No members match your search or filters.", ro: "Niciun membru nu corespunde căutării sau filtrelor." },

  col_email: { en: "Email", ro: "Email" },
  col_roles: { en: "Roles", ro: "Roluri" },
  col_status: { en: "Status", ro: "Status" },
  col_actions: { en: "Actions", ro: "Acțiuni" },

  invite_user_title: { en: "Invite user", ro: "Invită utilizator" },
  // An email-format example, not linguistic content -- identical in both
  // languages on purpose, same reasoning as leaving "30 min" untranslated
  // in group-detail-client.tsx.
  email_placeholder: { en: "email@wowlab.ro", ro: "email@wowlab.ro" },
  first_name_placeholder: { en: "First name (optional)", ro: "Prenume (opțional)" },
  last_name_placeholder: { en: "Last name (optional)", ro: "Nume (opțional)" },
  phone_placeholder: { en: "Phone (optional)", ro: "Telefon (opțional)" },
  invite_button: { en: "Invite", ro: "Invită" },

  badge_test: { en: "Test", ro: "Test" },
  save: { en: "Save", ro: "Salvează" },
  cancel: { en: "Cancel", ro: "Anulează" },
  no_roles: { en: "(no roles)", ro: "(fără roluri)" },
  // Lowercase inline row action, distinct from edit_roles_button's
  // capitalized mobile-card button -- same distinction as
  // groups/[id]/group-detail-client.tsx's reallocate_action/
  // reallocate_button.
  edit_action: { en: "edit", ro: "editează" },
  edit_roles_button: { en: "Edit roles", ro: "Editează rolurile" },
  reenable_button: { en: "Re-enable", ro: "Reactivează" },
  disable_button: { en: "Disable", ro: "Dezactivează" },
};
