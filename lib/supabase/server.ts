import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { cookies } from "next/headers";

type CookieToSet = { name: string; value: string; options: CookieOptions };

// Server Component / Server Action client. Anon key + the caller's own
// session (via cookies) — every query through this client is subject to
// RLS exactly as if it came from the browser. This is the client every
// admin server action must use for its capability check, before ever
// touching lib/supabase-admin.ts.
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Called from a Server Component (can't set cookies there).
            // Safe to ignore — middleware.ts refreshes the session on
            // every request.
          }
        },
      },
    },
  );
}
