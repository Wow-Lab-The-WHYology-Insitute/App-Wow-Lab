import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { resolveLandingPath } from "@/lib/landing";

// Nothing in the app links here, and unauthenticated requests never reach
// it (middleware redirects to /login first) -- this only ever runs for an
// authenticated visitor who typed / directly.
//
// It no longer hardcodes /profile. The destination is resolveLandingPath()'s
// (lib/landing.ts), shared with app/auth/callback/route.ts -- which is the
// path that actually matters, since this app is magic-link only and every
// real sign-in arrives through the callback rather than here. Changing this
// file alone would have changed nothing for anyone.
export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  redirect(await resolveLandingPath(supabase));
}
