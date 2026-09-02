"use server";

import { createClient } from "@/lib/supabase/server";

// errorKey, not a message string -- this action runs server-side and has
// no way to know the caller's locale (it's client-only state, see
// lib/i18n.tsx); the client resolves the actual text via loginDict
// (app/login/i18n.ts), the same way login-form.tsx already renders
// every other string on this page.
export type SendMagicLinkErrorKey = "missing_email" | "send_failed";

export type SendMagicLinkState = {
  status: "idle" | "sent" | "error";
  errorKey?: SendMagicLinkErrorKey;
};

export async function sendMagicLink(
  _prevState: SendMagicLinkState,
  formData: FormData,
): Promise<SendMagicLinkState> {
  const email = String(formData.get("email") ?? "").trim();
  const captchaToken = String(formData.get("captchaToken") ?? "");

  if (!email) {
    return { status: "error", errorKey: "missing_email" };
  }

  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      // Belt-and-suspenders on top of the project-level enable_signup=false:
      // this call site never creates a new auth user, only signs in an
      // already-invited one.
      shouldCreateUser: false,
      emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      captchaToken,
    },
  });

  if (error) {
    // Deliberately generic: don't reveal whether an email is invited.
    return { status: "error", errorKey: "send_failed" };
  }

  return { status: "sent" };
}
