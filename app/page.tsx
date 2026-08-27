import { redirect } from "next/navigation";

// Nothing in the app links here, and unauthenticated requests never reach
// it (middleware redirects to /login first) -- this only ever runs for an
// authenticated visitor who typed / directly. /profile is the real landing
// surface (see app/auth/callback/route.ts's own default), so this sends
// them there instead of the old S0/S1 placeholder it used to render.
export default function Home() {
  redirect("/profile");
}
