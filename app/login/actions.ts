"use server";

import { createClient } from "@/lib/supabase/server";

export type SendMagicLinkState = {
  status: "idle" | "sent" | "error";
  message?: string;
};

export async function sendMagicLink(
  _prevState: SendMagicLinkState,
  formData: FormData,
): Promise<SendMagicLinkState> {
  const email = String(formData.get("email") ?? "").trim();

  if (!email) {
    return { status: "error", message: "Enter an email address." };
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
    },
  });

  if (error) {
    // Deliberately generic: don't reveal whether an email is invited.
    return {
      status: "error",
      message:
        "Couldn't send a link. Check the address and try again or contact us at info@wowlab.ro.",
    };
  }

  return { status: "sent" };
}
