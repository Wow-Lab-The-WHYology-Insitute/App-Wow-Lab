import "server-only";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

// SERVICE_ROLE — privileged, dev-review-required, only reached after a
// capability check above.
//
// This is the ONLY file in the repo allowed to instantiate a service_role
// client. `import "server-only"` makes it a Next.js BUILD ERROR (not just a
// convention) for this module to end up in a client bundle. Grep rule for
// review: `createServiceRoleClient` / `SUPABASE_SERVICE_ROLE_KEY` must never
// appear outside this file, and this file must never be imported from
// anything marked `"use client"`.
//
// service_role bypasses RLS entirely. Every caller of this function MUST
// have already checked the current user's own session-scoped capability
// (via lib/supabase/server.ts, anon key + session) BEFORE calling this —
// this client performs no authorization of its own.
export function createServiceRoleClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    throw new Error(
      "createServiceRoleClient: NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must both be set.",
    );
  }

  return createSupabaseClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
