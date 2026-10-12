import { createClient } from "@/lib/supabase/server";

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
const MY_OWN_WORK_CAPABILITY = "mywork.*";

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
): Promise<string> {
  // ONE round trip, for both answers, across every organization the caller
  // belongs to. It replaced a memberships lookup plus up to nine sequential
  // has_capability calls -- measured before the change at a warm median of
  // 660 ms for a trainer, who is the one account that cannot short-circuit:
  // mywork.* matches, then all eight "beyond own work" keys have to come back
  // false before /my-work is the answer.
  //
  // The capability list still lives HERE and is passed in. Keeping it in the
  // app rather than inside the function is deliberate: it belongs beside the
  // comment above explaining that it must grow when a nav group is added, and
  // a copy in SQL would be a second place to forget.
  //
  // No user id is passed, because app.resolve_landing_flags takes none -- it
  // is SECURITY DEFINER and always answers about app.current_user_id().
  const { data, error } = await supabase.rpc("resolve_landing_flags", {
    p_mywork_cap: MY_OWN_WORK_CAPABILITY,
    p_beyond_caps: BEYOND_OWN_WORK_CAPABILITIES,
  });

  if (error) {
    // Fail closed, loudly, and in the direction that is never wrong for
    // anybody: /profile is reachable by every signed-in account, while
    // /my-work renders nothing for someone with no allocated work. Same
    // reasoning as checkCapability's own default-to-false, and the same place
    // it leaves a trace -- Vercel's function logs.
    console.error(
      "resolve_landing_flags RPC failed — landing on /profile (the destination that is correct for every account):",
      error,
    );
    return "/profile";
  }

  // `returns table` arrives as an array of rows through PostgREST.
  const flags = (Array.isArray(data) ? data[0] : data) as
    | { has_mywork?: boolean; has_beyond?: boolean }
    | undefined;

  if (!flags?.has_mywork) return "/profile";
  return flags.has_beyond ? "/profile" : "/my-work";
}
