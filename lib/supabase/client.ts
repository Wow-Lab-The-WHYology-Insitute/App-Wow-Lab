import { createBrowserClient } from "@supabase/ssr";

// Browser-side client. Uses only the public anon key — RLS is what keeps
// this safe, exactly like any other authenticated client. Never import
// lib/supabase-admin.ts (service_role) from anything reachable here.
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
