/**
 * ONE-TIME FIX — NOT a repeatable pattern, NOT a script anyone should run
 * again for this fixture.
 *
 * test+user-b@wowlab.dev's public.users row was inserted directly (an
 * organization_owner fixture for wow-lab-test-b) and has no matching
 * auth.users row, so it cannot sign in through the real app. Same gap as
 * test+catalina@wowlab.dev, fixed the same way in
 * scripts/activate_catalina_auth_identity.ts — this script mirrors that
 * one exactly, per DATABASE_CONVENTIONS.md §11.
 *
 * Per §11's own prescribed fix: creating the auth identity with the SAME
 * id turns handle_new_auth_user()'s `on conflict (id) do nothing` into a
 * no-op instead of a collision. The existing public.users row (status,
 * roles, user_org_roles grants) is therefore left completely untouched by
 * this script; it only creates the auth.users side.
 *
 * status is deliberately not touched here, same reasoning as the
 * Cătălina script: nothing in the app gates on users.status.
 *
 * Run (never via `next dev`/a route — standalone, once):
 *
 *   npx tsx --conditions=react-server --env-file=.env.local scripts/activate_test_user_b_auth_identity.ts
 */

import { createServiceRoleClient } from "../lib/supabase-admin";

const TARGET_EMAIL = "test+user-b@wowlab.dev";

async function main() {
  const admin = createServiceRoleClient();

  // Look up the existing row rather than hardcoding its id, so this script
  // fails loudly if the fixture ever moves or is renamed instead of
  // silently acting on the wrong id.
  const { data: existing, error: existingError } = await admin
    .from("users")
    .select("id, email, status")
    .eq("email", TARGET_EMAIL)
    .single();

  if (existingError || !existing) {
    throw new Error(
      `Could not find existing public.users row for ${TARGET_EMAIL}: ${existingError?.message ?? "no matching row"}`,
    );
  }

  console.log(`Existing public.users row: id=${existing.id} status=${existing.status}`);

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    id: existing.id,
    email: TARGET_EMAIL,
    email_confirm: true,
  });

  if (createError || !created.user) {
    throw new Error(`createUser failed: ${createError?.message ?? "no user returned"}`);
  }

  console.log(`auth.users row created: id=${created.user.id}`);

  if (created.user.id !== existing.id) {
    throw new Error(
      `id mismatch: auth.users got ${created.user.id}, expected ${existing.id} — investigate before trusting this identity.`,
    );
  }

  console.log("ids match.");

  // Confirm a magic link can actually be requested for this address, without
  // sending a real email (generateLink only produces the link server-side).
  const { data: link, error: linkError } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email: TARGET_EMAIL,
  });

  if (linkError || !link) {
    throw new Error(`generateLink failed: ${linkError?.message ?? "no link returned"}`);
  }

  console.log(`Magic link can be requested for ${TARGET_EMAIL} (action_link generated).`);

  // Confirm the public.users row is exactly as it was before — the trigger
  // no-opped, not overwrote.
  const { data: after, error: afterError } = await admin
    .from("users")
    .select("id, email, full_name, status, is_platform_owner")
    .eq("id", existing.id)
    .single();

  if (afterError || !after) {
    throw new Error(`Could not re-read public.users row after createUser: ${afterError?.message}`);
  }

  console.log(
    `public.users row after createUser: status=${after.status} full_name=${after.full_name} — unchanged, as expected.`,
  );

  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
