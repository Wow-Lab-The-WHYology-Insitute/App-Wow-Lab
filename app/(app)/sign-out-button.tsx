"use client";

import { useTransition } from "react";
import { signOut } from "./actions";
import { useTranslations } from "@/lib/i18n";
import { chromeDict } from "./i18n";

export function SignOutButton() {
  const [isPending, startTransition] = useTransition();
  const t = useTranslations(chromeDict);

  return (
    <button
      type="button"
      disabled={isPending}
      onClick={() => startTransition(() => signOut())}
      className="font-body text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold tracking-wide uppercase transition-colors hover:border-brand-pink hover:text-brand-pink disabled:opacity-50"
    >
      {isPending ? t("signing_out") : t("sign_out")}
    </button>
  );
}
