import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";

// Where a signed-in account lands. Used by BOTH /auth/callback (the path every
// real sign-in takes, since this app is magic-link only) and app/page.tsx (the
// path someone typing "/" takes). Changing one without the other changes
// nothing for real users -- see app/auth/callback/route.ts.
//
// THE RULE, in words: /my-work is the landing page for an account whose work is
// only its own work. Anyone who also answers for other people's work lands on
// /profile, because for them /my-work is a subset of their job rather than
// their job.
//
// WHY NOT `hasMyWork ? "/my-work" : "/profile"`. mywork.* is held by FOUR
// roles -- trainer, senior_trainer, organization_owner AND platform_owner -- so
// the naive check sends Anka (12 roles), Anca (platform_owner) and Mihai
// (organization_owner) to the trainer's screen. It happens to get Catalina
// right, but only by accident: she holds no mywork.* at all.
//
// MAINTENANCE COUPLING, stated because it is the shape of OPEN_ITEMS item 114
// (a list that goes stale when a screen is added). The capabilities below are
// the gates of the non-trainer screens in app/(app)/layout.tsx's navGroups.
// ADDING A NAV GROUP THERE MEANS ADDING ITS CAPABILITY HERE, or an account that
// gains a new screen keeps landing on /my-work. The two cannot be collapsed
// into one list today because layout.tsx needs each flag separately to decide
// individual nav items (clients vs contracts are gated independently), while
// this only needs "any of them".
//
// Deliberately NOT in the list: inventory.* (inventory_custodian -- Teodora),
// community.* (community_people -- Alexandra), evaluations.assigned.*
// (evaluator) and candidate.portal.access. Each gates no screen that exists, so
// an account holding one alongside `trainer` is still a trainer as far as this
// app has any surface for. When an evaluations or inventory screen ships, those
// accounts' landing changes -- correct under this rule, and it will look like a
// regression to them, so it is written down rather than discovered.
const BEYOND_OWN_WORK_CAPABILITIES = [
  "clients.read", // /clients
  "contracts.read", // /contracts
  "groups.read", // /groups, org-wide (a trainer reaches it via mywork.*)
  "finance.operations.*", // /payroll, /payment-config
  "finance.reporting.*", // /suppliers, /payment-config
  "org.members.manage", // /admin/users
  "org.settings.manage", // everything
  "curriculum.validate", // the approval surface on the group screen
] as const;

export async function resolveLandingPath(
  supabase: Awaited<ReturnType<typeof createClient>>,
  userId: string,
): Promise<string> {
  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", userId)
    .returns<{ organization_id: string }[]>();

  const orgs = [...new Set((memberships ?? []).map((m) => m.organization_id))];
  if (orgs.length === 0) return "/profile";

  // mywork.* first, and return early when it is absent: that skips eight RPC
  // calls on the sign-in path for everyone who is not a trainer at all
  // (Catalina, Laura, a role-less account).
  let hasMyWork = false;
  for (const org of orgs) {
    if (await checkCapability(supabase, "mywork.*", org)) {
      hasMyWork = true;
      break;
    }
  }
  if (!hasMyWork) return "/profile";

  for (const org of orgs) {
    for (const cap of BEYOND_OWN_WORK_CAPABILITIES) {
      if (await checkCapability(supabase, cap, org)) return "/profile";
    }
  }

  return "/my-work";
}
