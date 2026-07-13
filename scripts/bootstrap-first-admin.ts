/**
 * ONE-TIME BOOTSTRAP — NOT a repeatable feature, NOT a script anyone should
 * ever need to run again.
 *
 * Invite-only auth has a chicken-and-egg problem: /admin/users itself
 * requires being already logged in with org.members.manage, but nobody has
 * ever logged in yet, so nobody can reach /admin/users to invite the first
 * person. This script exists solely to break that cycle exactly once, for
 * exactly one real user, using the SAME admin client and the SAME
 * inviteUserByEmail call app/admin/users/actions.ts uses — not a parallel
 * mechanism.
 *
 * The SECOND user, and every user after that, goes through /admin/users
 * once this first admin exists and logs in. Do not run this script again.
 * Do not add a "reset"/"re-run" mode to it. If it needs to run twice,
 * something else is wrong and that should be investigated, not papered
 * over here.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/bootstrap-first-admin.ts <email>
 *
 * Both flags matter and are not optional:
 *   --env-file=.env.local   loads real NEXT_PUBLIC_SUPABASE_URL /
 *                           SUPABASE_SERVICE_ROLE_KEY — this script has no
 *                           other way to see them outside the Next.js
 *                           process.
 *   --conditions=react-server
 *                           lib/supabase-admin.ts starts with
 *                           `import "server-only"`. That package throws
 *                           unconditionally UNLESS the "react-server"
 *                           export condition is active (verified directly:
 *                           without this flag the import throws "This
 *                           module cannot be imported from a Client
 *                           Component module" before main() ever runs).
 *                           Next.js's own bundler sets that condition
 *                           automatically when compiling Server Component
 *                           code; a plain tsx/node process does not, so it
 *                           must be requested explicitly here. This is the
 *                           standard Node.js mechanism for opting into a
 *                           package's alternate conditional export — not a
 *                           workaround, and not a change to
 *                           lib/supabase-admin.ts itself.
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const BOOTSTRAP_ORG_SLUG = "wow-lab";
const BOOTSTRAP_ROLE_KEY = "organization_owner";

async function main() {
  const email = process.argv[2];
  if (!email || !email.includes("@")) {
    console.error(
      "Usage: npx tsx --conditions=react-server --env-file=.env.local scripts/bootstrap-first-admin.ts <email>",
    );
    process.exit(1);
  }

  const admin = createServiceRoleClient();

  // Look up the real, currently-seeded org and role ids — never hardcode a
  // uuid here, seed data is not guaranteed stable across environments.
  const { data: org, error: orgError } = await admin
    .from("organizations")
    .select("id, slug")
    .eq("slug", BOOTSTRAP_ORG_SLUG)
    .single();

  if (orgError || !org) {
    throw new Error(
      `Could not find organization '${BOOTSTRAP_ORG_SLUG}': ${orgError?.message ?? "no matching row"}`,
    );
  }

  const { data: role, error: roleError } = await admin
    .from("roles")
    .select("id, key")
    .eq("key", BOOTSTRAP_ROLE_KEY)
    .single();

  if (roleError || !role) {
    throw new Error(
      `Could not find role '${BOOTSTRAP_ROLE_KEY}': ${roleError?.message ?? "no matching row"}`,
    );
  }

  console.log(`Organization '${org.slug}' = ${org.id}`);
  console.log(`Role '${role.key}' = ${role.id}`);
  console.log(`Inviting ${email} ...`);

  // Same call app/admin/users/actions.ts's inviteUser() makes.
  const { data: inviteData, error: inviteError } =
    await admin.auth.admin.inviteUserByEmail(email, {
      redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
    });

  if (inviteError || !inviteData.user) {
    throw new Error(`Invite failed: ${inviteError?.message ?? "no user returned"}`);
  }

  console.log(`Invited. auth.users id = ${inviteData.user.id}`);

  // public.handle_new_auth_user() (202607130004) is an AFTER INSERT trigger
  // on auth.users — by the time inviteUserByEmail's API call above
  // returned, the matching public.users row must already exist in the same
  // committed transaction, or the invite itself would have failed (a
  // trigger exception rolls back the triggering insert too — verified
  // separately, not assumed). This check is a defensive confirmation, not
  // the thing making it happen.
  const { data: profile, error: profileError } = await admin
    .from("users")
    .select("id, email")
    .eq("id", inviteData.user.id)
    .single();

  if (profileError || !profile) {
    throw new Error(
      `Expected a public.users row for ${inviteData.user.id} (created by the on_auth_user_created trigger) but found none: ${profileError?.message ?? "no matching row"}`,
    );
  }

  console.log(`Confirmed matching public.users row: ${profile.email}`);

  const { error: roleAssignError } = await admin
    .from("user_org_roles")
    .insert({
      organization_id: org.id,
      user_id: inviteData.user.id,
      role_id: role.id,
      // assigned_by intentionally left null — no human admin performed
      // this; it was the bootstrap script.
    });

  if (roleAssignError) {
    throw new Error(`Failed to assign role: ${roleAssignError.message}`);
  }

  console.log(
    `Done. ${email} is now ${BOOTSTRAP_ROLE_KEY} in ${BOOTSTRAP_ORG_SLUG}. ` +
      `They can log in via /login (magic link) and should be able to reach /admin/users.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
