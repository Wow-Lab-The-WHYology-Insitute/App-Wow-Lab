import { type EmailOtpType } from "@supabase/supabase-js";
import { type NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Handles both magic-link sign-in and the first click of an invite email —
// both use the same token_hash + type confirmation mechanism.
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const token_hash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;
  // No `next` param yet defaults to /whoami (S2's diagnostic landing spot) —
  // Phase 1 will change this once there's a real post-login destination.
  const next = searchParams.get("next") ?? "/whoami";

  if (token_hash && type) {
    const supabase = await createClient();
    const { error } = await supabase.auth.verifyOtp({ token_hash, type });

    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  const redirectUrl = new URL("/login", origin);
  redirectUrl.searchParams.set("error", "auth-callback-failed");
  return NextResponse.redirect(redirectUrl);
}
