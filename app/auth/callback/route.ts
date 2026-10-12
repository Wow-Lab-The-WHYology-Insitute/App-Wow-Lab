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
    // verifyOtp already returns the user it just authenticated. The first
    // version of this called getUser() straight afterwards to get the same
    // person back -- a second network round trip, on the sign-in path, for an
    // answer already in hand.
    const { data: verified, error } = await supabase.auth.verifyOtp({ token_hash, type });

    if (!error) {
      if (next) {
        return NextResponse.redirect(`${origin}${next}`);
      }
      // resolveLandingPath needs no user id: the function behind it is
      // SECURITY DEFINER and always answers about the current session. The
      // user object is still checked, because a verifyOtp that somehow
      // returned no user should land on /profile rather than ask the database
      // who nobody is.
      const destination = verified.user ? await resolveLandingPath(supabase) : "/profile";
      return NextResponse.redirect(`${origin}${destination}`);
    }
  }

  const redirectUrl = new URL("/login", origin);
  redirectUrl.searchParams.set("error", "auth-callback-failed");
  return NextResponse.redirect(redirectUrl);
}
