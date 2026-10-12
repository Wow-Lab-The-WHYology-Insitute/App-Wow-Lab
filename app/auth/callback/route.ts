import { type EmailOtpType } from "@supabase/supabase-js";
import { type NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { resolveLandingPath } from "@/lib/landing";

// Handles both magic-link sign-in and the first click of an invite email —
// both use the same token_hash + type confirmation mechanism.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const token_hash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;
  // "Phase 1 will change this once there's a real post-login destination" --
  // which is now. With no `next` param the destination is resolved per account
  // by resolveLandingPath() (lib/landing.ts): /my-work for an account whose
  // work is only its own work, /profile for anyone who also answers for other
  // people's. An explicit `next` still wins, unchanged.
  //
  // THIS is the file that matters, not app/page.tsx: sign-in is magic-link
  // only (app/login/actions.ts calls signInWithOtp with emailRedirectTo
  // pointing here and no `next`), so every real sign-in lands through this
  // default.
  const next = searchParams.get("next");

  if (token_hash && type) {
    const supabase = await createClient();
    const { error } = await supabase.auth.verifyOtp({ token_hash, type });

    if (!error) {
      if (next) {
        return NextResponse.redirect(`${origin}${next}`);
      }
      const {
        data: { user },
      } = await supabase.auth.getUser();
      const destination = user ? await resolveLandingPath(supabase, user.id) : "/profile";
      return NextResponse.redirect(`${origin}${destination}`);
    }
  }

  const redirectUrl = new URL("/login", origin);
  redirectUrl.searchParams.set("error", "auth-callback-failed");
  return NextResponse.redirect(redirectUrl);
}
